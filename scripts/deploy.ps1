#Requires -Version 7.0
<#
.SYNOPSIS
    Deploy or upgrade the k8s-eks-platform Helm release on EKS.

.DESCRIPTION
    Authenticates with AWS, refreshes kubeconfig, and performs a Helm upgrade
    (with --install) for all services. Supports environment-specific value
    overrides and dry-run mode for change previewing.

.PARAMETER ClusterName
    Name of the EKS cluster.

.PARAMETER AwsRegion
    AWS region.

.PARAMETER Environment
    Target environment (dev / staging / prod). Controls which values overlay is applied.

.PARAMETER ImageTag
    Docker image tag to deploy. Defaults to 'latest'.

.PARAMETER Namespace
    Kubernetes namespace. Defaults to 'app'.

.PARAMETER DryRun
    Perform a Helm diff / dry-run only — no changes applied.

.PARAMETER HelmDir
    Path to the Helm chart directory. Defaults to <repo-root>/helm/app.

.EXAMPLE
    ./scripts/deploy.ps1 -ClusterName my-eks -AwsRegion eu-west-1 -Environment prod -ImageTag v1.2.3
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$ClusterName,

    [Parameter(Mandatory)]
    [string]$AwsRegion,

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment,

    [string]$ImageTag = 'latest',

    [string]$Namespace = 'app',

    [switch]$DryRun,

    [string]$HelmDir = (Join-Path $PSScriptRoot '..' 'helm' 'app')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Helpers ─────────────────────────────────────────────────────────────

function Write-Step  { param([string]$m) Write-Host "`n▶  $m" -ForegroundColor Cyan    }
function Write-Success { param([string]$m) Write-Host "   ✔  $m" -ForegroundColor Green  }

#endregion

#region ── AWS / kubeconfig ────────────────────────────────────────────────────

Write-Step 'Refreshing kubeconfig'
aws eks update-kubeconfig --name $ClusterName --region $AwsRegion
Write-Success 'kubeconfig refreshed'

#endregion

#region ── Namespace ───────────────────────────────────────────────────────────

Write-Step "Ensuring namespace '$Namespace' exists"
$nsExists = kubectl get namespace $Namespace --ignore-not-found
if (-not $nsExists) {
    kubectl create namespace $Namespace
}
Write-Success "Namespace '$Namespace' ready"

#endregion

#region ── Helm upgrade ────────────────────────────────────────────────────────

Write-Step "Deploying release to '$Environment' (image tag: $ImageTag)"

$helmArgs = @(
    'upgrade', '--install', 'k8s-eks-platform',
    (Resolve-Path $HelmDir),
    '--namespace', $Namespace,
    '--values', (Join-Path $HelmDir "values.yaml"),
    '--set', "global.imageTag=$ImageTag",
    '--set', "global.environment=$Environment",
    '--atomic',        # rollback on failure
    '--cleanup-on-fail',
    '--timeout', '5m',
    '--wait'
)

# Environment-specific overlay
$overlay = Join-Path $HelmDir "values.$Environment.yaml"
if (Test-Path $overlay) {
    $helmArgs += '--values', $overlay
    Write-Host "   ℹ  Applying overlay: values.$Environment.yaml" -ForegroundColor DarkCyan
}

if ($DryRun) {
    $helmArgs += '--dry-run', '--debug'
    Write-Host '   ℹ  DRY-RUN mode — no changes will be applied' -ForegroundColor Yellow
}

helm @helmArgs

if ($DryRun) {
    Write-Host "`n✔  Dry-run complete.`n" -ForegroundColor Yellow
} else {
    Write-Success "Release deployed successfully"
}

#endregion

#region ── Smoke test ──────────────────────────────────────────────────────────

if (-not $DryRun) {
    Write-Step 'Running post-deploy smoke test'
    $retries = 0
    $maxRetries = 12
    $ready = $false

    while ($retries -lt $maxRetries) {
        $pods = kubectl get pods -n $Namespace -l "app.kubernetes.io/instance=k8s-eks-platform" `
            --output json | ConvertFrom-Json
        $allReady = $pods.items | Where-Object {
            $_.status.containerStatuses | Where-Object { -not $_.ready }
        }
        if ($allReady.Count -eq 0 -and $pods.items.Count -gt 0) {
            $ready = $true
            break
        }
        $retries++
        Write-Host "   ⏳  Waiting for pods... ($retries/$maxRetries)" -ForegroundColor DarkYellow
        Start-Sleep -Seconds 10
    }

    if ($ready) {
        Write-Success 'All pods are running and ready'
    } else {
        Write-Host "`n⚠  Some pods did not become ready within the timeout. Check with:" -ForegroundColor Yellow
        Write-Host "   kubectl get pods -n $Namespace`n"
    }
}

#endregion

Write-Host "`n🚀  Deploy script finished.`n" -ForegroundColor Green
