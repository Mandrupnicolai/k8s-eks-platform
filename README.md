<div align="center">

# ☸️ k8s-eks-platform

**Production-grade Kubernetes platform for containerised microservices on AWS EKS.**

[![CI](https://github.com/Mandrupnicolai/k8s-eks-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/Mandrupnicolai/k8s-eks-platform/actions/workflows/ci.yml)
[![CD](https://github.com/Mandrupnicolai/k8s-eks-platform/actions/workflows/cd.yml/badge.svg)](https://github.com/Mandrupnicolai/k8s-eks-platform/actions/workflows/cd.yml)
[![codecov](https://codecov.io/gh/Mandrupnicolai/k8s-eks-platform/branch/master/graph/badge.svg)](https://codecov.io/gh/Mandrupnicolai/k8s-eks-platform)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.7-7B42BC?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Helm](https://img.shields.io/badge/Helm-v3-0F1689?logo=helm&logoColor=white)](https://helm.sh)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/eks/)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)

</div>

---


## Overview

`k8s-eks-platform` is a fully automated, infrastructure-as-code platform that provisions an AWS EKS cluster and deploys a containerised microservices application. It demonstrates production-grade practices including:

- **Zero hardcoded configuration** â€” all environment-specific values are injected via Helm values overlays or GitHub Actions variables/secrets
- **Secrets at runtime** â€” application secrets are pulled from AWS Secrets Manager via the Secrets Store CSI Driver; no secrets exist in source control
- **Horizontal Pod Autoscaling** â€” CPU and memory-based HPA keeps the platform elastic under load
- **GitOps-style CI/CD** â€” every merge to `main` triggers a full Terraform plan/apply and atomic Helm release
- **OIDC-based AWS auth** â€” no long-lived AWS access keys; GitHub Actions assumes an IAM role via OIDC

---

## Architecture

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  GitHub Actions                                                    â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   PR    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚    CI    â”‚ â”€â”€â”€â”€â”€â”€â–¶ â”‚ Lint Â· Test Â· Docker build Â· TF plan â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜         â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  merge  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚
â”‚  â”‚    CD    â”‚ â”€â”€â”€â”€â”€â”€â–¶ â”‚ ECR push Â· TF apply Â· Helm upgrade   â”‚   â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜         â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                                       â”‚ OIDC
                          â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â–¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
                          â”‚         AWS              â”‚
                          â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
                          â”‚  â”‚   ECR (images)    â”‚  â”‚
                          â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
                          â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
                          â”‚  â”‚  EKS Cluster      â”‚  â”‚
                          â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚
                          â”‚  â”‚  â”‚  Namespace  â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  app        â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”‚  API  â”‚  â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”‚  HPA  â”‚  â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â” â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”‚  Web   â”‚ â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â”‚  HPA   â”‚ â”‚  â”‚  â”‚
                          â”‚  â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚  â”‚  â”‚
                          â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚
                          â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â” â”‚  â”‚
                          â”‚  â”‚  â”‚ Secrets Mgr   â”‚ â”‚  â”‚
                          â”‚  â”‚  â”‚ (CSI Driver)  â”‚ â”‚  â”‚
                          â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚  â”‚
                          â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
                          â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## Repository Structure

```
k8s-eks-platform/
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/
â”‚       â”œâ”€â”€ ci.yml              # Lint, test, Docker build, TF validate
â”‚       â””â”€â”€ cd.yml              # ECR push, Terraform apply, Helm deploy
â”œâ”€â”€ terraform/
â”‚   â”œâ”€â”€ main.tf                 # VPC, EKS, IRSA, Cluster Autoscaler
â”‚   â”œâ”€â”€ variables.tf
â”‚   â”œâ”€â”€ outputs.tf
â”‚   â””â”€â”€ providers.tf
â”œâ”€â”€ helm/
â”‚   â””â”€â”€ app/
â”‚       â”œâ”€â”€ Chart.yaml
â”‚       â”œâ”€â”€ values.yaml         # Default values (no env-specific secrets)
â”‚       â””â”€â”€ templates/
â”‚           â”œâ”€â”€ deployment.yaml
â”‚           â”œâ”€â”€ service.yaml
â”‚           â”œâ”€â”€ hpa.yaml
â”‚           â”œâ”€â”€ ingress.yaml
â”‚           â”œâ”€â”€ serviceaccount.yaml
â”‚           â””â”€â”€ secretproviderclass.yaml
â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ api/                    # Node.js REST API
â”‚   â”‚   â”œâ”€â”€ Dockerfile
â”‚   â”‚   â”œâ”€â”€ src/
â”‚   â”‚   â””â”€â”€ tests/
â”‚   â””â”€â”€ frontend/               # Nginx static frontend
â”‚       â”œâ”€â”€ Dockerfile
â”‚       â”œâ”€â”€ nginx.conf
â”‚       â””â”€â”€ html/
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ bootstrap.ps1           # First-time cluster bootstrap
â”‚   â”œâ”€â”€ deploy.ps1              # Manual Helm deploy helper
â”‚   â””â”€â”€ teardown.ps1            # Full infra teardown
â”œâ”€â”€ CONTRIBUTING.md
â”œâ”€â”€ LICENSE
â””â”€â”€ README.md
```

---

## Prerequisites

| Tool        | Version  | Install |
|-------------|----------|---------|
| AWS CLI     | â‰¥ 2.15   | [docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| Terraform   | â‰¥ 1.7    | [docs](https://developer.hashicorp.com/terraform/install) |
| kubectl     | â‰¥ 1.29   | [docs](https://kubernetes.io/docs/tasks/tools/) |
| Helm        | â‰¥ 3.15   | [docs](https://helm.sh/docs/intro/install/) |
| PowerShell  | â‰¥ 7.0    | [docs](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| Node.js     | â‰¥ 20 LTS | [docs](https://nodejs.org/) |

---

## Quick Start

### 1 Â· Configure AWS & Terraform state

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
aws s3 mb s3://your-tf-state-bucket --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2 Â· Provision the cluster

```powershell
cd terraform
terraform init `
  -backend-config="bucket=your-tf-state-bucket" `
  -backend-config="key=k8s-eks-platform/terraform.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="dynamodb_table=terraform-state-lock"

terraform apply -var-file="environments/dev.tfvars"
```

### 3 Â· Bootstrap cluster add-ons

```powershell
./scripts/bootstrap.ps1 -ClusterName my-eks-cluster -AwsRegion us-east-1
```

### 4 Â· Deploy the application

```powershell
./scripts/deploy.ps1 `
  -ClusterName my-eks-cluster `
  -AwsRegion   us-east-1 `
  -Environment dev `
  -ImageTag    latest
```

---

## GitHub Actions Setup

### Required Secrets

| Secret | Description |
|--------|-------------|
| `AWS_DEPLOY_ROLE_ARN` | IAM role ARN assumed via OIDC during CI/CD |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking |
| `IRSA_ROLE_ARN` | IAM role ARN for pod-level Secrets Manager access |
| `CODECOV_TOKEN` | Token from [codecov.io](https://codecov.io) for coverage uploads |

### Required Variables

| Variable | Example |
|----------|---------|
| `AWS_REGION` | `us-east-1` |
| `ECR_REGISTRY` | `123456789012.dkr.ecr.us-east-1.amazonaws.com` |
| `EKS_CLUSTER_NAME` | `my-eks-cluster` |
| `APP_HOST` | `api.example.com` |

### OIDC Trust Policy

Add this to your IAM role's trust policy to allow GitHub Actions OIDC authentication:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:your-org/k8s-eks-platform:*"
    }
  }
}
```

---

## Secrets Management

Application secrets are **never stored in source control or container images**. At pod startup, the Secrets Store CSI Driver mounts secrets directly from AWS Secrets Manager into `/mnt/secrets/`. Secrets are synced to Kubernetes Secrets for environment-variable injection if needed.

Secret path convention:

```
/k8s-eks-platform/{environment}/{secret-name}
```

Example: `/k8s-eks-platform/prod/db-credentials`

---

## Horizontal Pod Autoscaling

HPA is enabled for both the API and Frontend deployments. Default configuration:

| Parameter | Value |
|-----------|-------|
| Min replicas | 2 |
| Max replicas | 10 |
| CPU target | 70% |
| Memory target | 80% |
| Scale-down window | 300s |

Override per environment in `helm/app/values.{env}.yaml`.

---

## Teardown

To destroy all infrastructure:

```powershell
./scripts/teardown.ps1 -ClusterName my-eks-cluster -AwsRegion us-east-1
```

> **Warning:** This is irreversible. The script requires typing the cluster name to confirm.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch strategy, commit conventions, and PR guidelines.

---

## License

[MIT](LICENSE) Â© your-org


