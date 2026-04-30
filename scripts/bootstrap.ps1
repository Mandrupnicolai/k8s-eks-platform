#Requires -Version 7.0
<#
.SYNOPSIS
    Bootstrap script for initialising the k8s-eks-platform environment.

.DESCRIPTION
    Validates required tooling, configures AWS credentials, initialises Terraform,
    and installs cluster-level add-ons (AWS Load Balancer Controller, Secrets Store
    CSI Driver, Metrics Server) needed before any application Helm release.

.PARAMETER ClusterName
    Name of the EKS cluster to bootstrap against.

.PARAMETER AwsRegion
    AWS region where the EKS cluster lives.

.PARAMETER TerraformDir
    Path to the Terraform root module. Defaults to <repo-root>/terraform.

.PARAMETER SkipToolCheck
    Skip pre-flight tool validation (useful in CI where tools are guaranteed present).

.EXAMPLE
    ./scripts/bootstrap.ps1 -ClusterName my-eks -AwsRegion eu-west-1
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ClusterName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$AwsRegion,

    [string]$TerraformDir = (Join-Path $PSScriptRoot '..' 'terraform'),

    [switch]$SkipToolCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region ── Helpers ─────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Message)
    Write-Host "`n▶  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   ✔  $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "   ⚠  $Message" -ForegroundColor Yellow
}

function Assert-Tool {
    param([string]$Name, [string]$HintUrl)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required tool '$Name' not found. Install from: $HintUrl"
    }
    Write-Success "$Name found at $(Get-Command $Name | Select-Object -ExpandProperty Source)"
}

#endregion

#region ── Pre-flight checks ───────────────────────────────────────────────────

if (-not $SkipToolCheck) {
    Write-Step 'Validating required tooling'
    Assert-Tool 'aws'       'https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html'
    Assert-Tool 'terraform' 'https://developer.hashicorp.com/terraform/install'
    Assert-Tool 'kubectl'   'https://kubernetes.io/docs/tasks/tools/'
    Assert-Tool 'helm'      'https://helm.sh/docs/intro/install/'
    Assert-Tool 'eksctl'    'https://eksctl.io/installation/'
}

#endregion

#region ── AWS identity check ──────────────────────────────────────────────────

Write-Step 'Verifying AWS credentials'
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
Write-Success "Authenticated as: $($identity.Arn)"

#endregion

#region ── Terraform init ──────────────────────────────────────────────────────

Write-Step 'Initialising Terraform'
$tfDir = Resolve-Path $TerraformDir
Push-Location $tfDir
try {
    terraform init -upgrade
    Write-Success 'Terraform initialised'
} finally {
    Pop-Location
}

#endregion

#region ── kubeconfig ──────────────────────────────────────────────────────────

Write-Step "Updating kubeconfig for cluster '$ClusterName'"
aws eks update-kubeconfig `
    --name   $ClusterName `
    --region $AwsRegion
Write-Success 'kubeconfig updated'

#endregion

#region ── Helm repos ──────────────────────────────────────────────────────────

Write-Step 'Adding & updating Helm repositories'

$repos = @(
    @{ Name = 'eks';         Url = 'https://aws.github.io/eks-charts' },
    @{ Name = 'secrets-csi'; Url = 'https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts' },
    @{ Name = 'metrics-server'; Url = 'https://kubernetes-sigs.github.io/metrics-server/' }
)

foreach ($repo in $repos) {
    helm repo add $repo.Name $repo.Url --force-update | Out-Null
    Write-Success "Repo '$($repo.Name)' configured"
}

helm repo update | Out-Null

#endregion

#region ── Cluster add-ons ─────────────────────────────────────────────────────

Write-Step 'Installing Metrics Server'
helm upgrade --install metrics-server metrics-server/metrics-server `
    --namespace kube-system `
    --set args[0]='--kubelet-insecure-tls' `
    --wait
Write-Success 'Metrics Server installed'

Write-Step 'Installing Secrets Store CSI Driver'
helm upgrade --install csi-secrets-store secrets-csi/secrets-store-csi-driver `
    --namespace kube-system `
    --set syncSecret.enabled=true `
    --set enableSecretRotation=true `
    --wait
Write-Success 'Secrets Store CSI Driver installed'

Write-Step 'Installing AWS Secrets & Config Provider (ASCP)'
kubectl apply -f 'https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml'
Write-Success 'ASCP installed'

#endregion

Write-Host "`n🎉  Bootstrap complete. Cluster '$ClusterName' is ready for deployments.`n" -ForegroundColor Green
