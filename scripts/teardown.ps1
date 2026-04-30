#Requires -Version 7.0
<#
.SYNOPSIS
    Tear down the k8s-eks-platform infrastructure and all associated AWS resources.

.DESCRIPTION
    Uninstalls Helm releases, removes Kubernetes namespaces, and runs
    'terraform destroy' to clean up all provisioned AWS resources.
    Requires explicit confirmation unless -Force is supplied.

.PARAMETER ClusterName
    Name of the EKS cluster.

.PARAMETER AwsRegion
    AWS region.

.PARAMETER TerraformDir
    Path to the Terraform root module. Defaults to <repo-root>/terraform.

.PARAMETER Namespace
    Application namespace to purge. Defaults to 'app'.

.PARAMETER Force
    Skip interactive confirmation prompt (for automated / CI teardowns).

.EXAMPLE
    ./scripts/teardown.ps1 -ClusterName my-eks -AwsRegion eu-west-1 -Force
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$ClusterName,

    [Parameter(Mandatory)]
    [string]$AwsRegion,

    [string]$TerraformDir = (Join-Path $PSScriptRoot '..' 'terraform'),

    [string]$Namespace = 'app',

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Helpers ─────────────────────────────────────────────────────────────

function Write-Step    { param([string]$m) Write-Host "`n▶  $m" -ForegroundColor Cyan   }
function Write-Success { param([string]$m) Write-Host "   ✔  $m" -ForegroundColor Green }
function Write-Warn    { param([string]$m) Write-Host "   ⚠  $m" -ForegroundColor Yellow }

#endregion

#region ── Confirmation ────────────────────────────────────────────────────────

if (-not $Force) {
    Write-Host "`n⚠  WARNING: This will PERMANENTLY destroy the EKS cluster '$ClusterName'" `
        -ForegroundColor Red
    Write-Host "   and all associated AWS resources in region '$AwsRegion'.`n" `
        -ForegroundColor Red
    $confirm = Read-Host "   Type the cluster name to confirm"
    if ($confirm -ne $ClusterName) {
        Write-Host "`n   Teardown aborted — name did not match.`n" -ForegroundColor Yellow
        exit 0
    }
}

#endregion

#region ── kubeconfig ──────────────────────────────────────────────────────────

Write-Step 'Refreshing kubeconfig'
aws eks update-kubeconfig --name $ClusterName --region $AwsRegion
Write-Success 'kubeconfig refreshed'

#endregion

#region ── Helm uninstall ──────────────────────────────────────────────────────

Write-Step 'Uninstalling Helm releases'
$releases = helm list --namespace $Namespace --short 2>$null
if ($releases) {
    foreach ($release in $releases) {
        Write-Warn "Uninstalling release: $release"
        helm uninstall $release --namespace $Namespace --wait
        Write-Success "Release '$release' removed"
    }
} else {
    Write-Warn "No Helm releases found in namespace '$Namespace'"
}

# Remove cluster add-ons
foreach ($addon in @('k8s-eks-platform', 'csi-secrets-store', 'metrics-server')) {
    $exists = helm list --namespace kube-system --short | Where-Object { $_ -eq $addon }
    if ($exists) {
        helm uninstall $addon --namespace kube-system --wait
        Write-Success "Add-on '$addon' uninstalled"
    }
}

#endregion

#region ── Namespace cleanup ───────────────────────────────────────────────────

Write-Step "Deleting namespace '$Namespace'"
kubectl delete namespace $Namespace --ignore-not-found
Write-Success "Namespace '$Namespace' deleted"

#endregion

#region ── Terraform destroy ───────────────────────────────────────────────────

Write-Step 'Running Terraform destroy'
$tfDir = Resolve-Path $TerraformDir
Push-Location $tfDir
try {
    $tfArgs = @('destroy', '-auto-approve')
    terraform @tfArgs
    Write-Success 'Terraform destroy complete'
} finally {
    Pop-Location
}

#endregion

Write-Host "`n🗑️  Teardown complete. All resources have been destroyed.`n" -ForegroundColor Green
