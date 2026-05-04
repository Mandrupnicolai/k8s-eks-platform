<div align="center">

# k8s-eks-platform

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

- **Zero hardcoded configuration** - all environment-specific values are injected via Helm values overlays or GitHub Actions variables/secrets
- **Secrets at runtime** - application secrets are pulled from AWS Secrets Manager via the Secrets Store CSI Driver; no secrets exist in source control
- **Horizontal Pod Autoscaling** - CPU and memory-based HPA keeps the platform elastic under load
- **GitOps-style CI/CD** - every merge to `master` triggers a full Terraform plan/apply and atomic Helm release
- **OIDC-based AWS auth** - no long-lived AWS access keys; GitHub Actions assumes an IAM role via OIDC

---

## Architecture

```
+------------------------------------------------------------------+
|  GitHub Actions                                                  |
|  +----------+   PR    +--------------------------------------+   |
|  |    CI    | ------> | Lint - Test - Docker build - TF plan|   |
|  +----------+         +--------------------------------------+   |
|  +----------+  merge  +--------------------------------------+   |
|  |    CD    | ------> | ECR push - TF apply - Helm upgrade  |   |
|  +----------+         +--------------------------------------+   |
+------------------------------------+-----------------------------+
                                     | OIDC
                        +------------v------------+
                        |          AWS            |
                        |  +-------------------+  |
                        |  |   ECR (images)    |  |
                        |  +-------------------+  |
                        |  +-------------------+  |
                        |  |   EKS Cluster     |  |
                        |  |  +-------------+  |  |
                        |  |  | Namespace   |  |  |
                        |  |  |    app      |  |  |
                        |  |  |  API + HPA  |  |  |
                        |  |  |  Web + HPA  |  |  |
                        |  |  +-------------+  |  |
                        |  |  +-------------+  |  |
                        |  |  | Secrets Mgr |  |  |
                        |  |  | (CSI Driver)|  |  |
                        |  |  +-------------+  |  |
                        |  +-------------------+  |
                        +-------------------------+
```

---

## Repository Structure

```
k8s-eks-platform/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                   # Lint, test, Docker build, TF validate
│   │   └── cd.yml                   # ECR push, Terraform apply, Helm deploy
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml
├── terraform/
│   ├── main.tf                      # VPC, EKS, IRSA, Cluster Autoscaler
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── environments/
│       └── dev.tfvars.example
├── helm/
│   └── app/
│       ├── Chart.yaml
│       ├── values.yaml              # Base defaults
│       ├── values.dev.yaml
│       ├── values.staging.yaml
│       ├── values.prod.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── hpa.yaml
│           ├── ingress.yaml
│           ├── serviceaccount.yaml
│           └── secretproviderclass.yaml
├── services/
│   ├── api/                         # Node.js REST API
│   │   ├── Dockerfile
│   │   ├── .dockerignore
│   │   ├── package.json
│   │   ├── src/
│   │   └── tests/
│   └── frontend/                    # Nginx static frontend
│       ├── Dockerfile
│       ├── .dockerignore
│       ├── nginx.conf
│       └── html/
├── scripts/
│   ├── bootstrap.ps1                # First-time cluster bootstrap
│   ├── deploy.ps1                   # Manual Helm deploy helper
│   └── teardown.ps1                 # Full infra teardown
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE
└── README.md
```

---

## Prerequisites

| Tool       | Version  | Install |
|------------|----------|---------|
| AWS CLI    | >= 2.15  | [docs](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| Terraform  | >= 1.7   | [docs](https://developer.hashicorp.com/terraform/install) |
| kubectl    | >= 1.29  | [docs](https://kubernetes.io/docs/tasks/tools/) |
| Helm       | >= 3.15  | [docs](https://helm.sh/docs/intro/install/) |
| PowerShell | >= 7.0   | [docs](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| Node.js    | >= 20    | [docs](https://nodejs.org/) |

---

## Quick Start

### 1 - Configure AWS and Terraform state

```bash
aws s3 mb s3://your-tf-state-bucket --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2 - Provision the cluster

```powershell
cd terraform
terraform init `
  -backend-config="bucket=your-tf-state-bucket" `
  -backend-config="key=k8s-eks-platform/terraform.tfstate" `
  -backend-config="region=us-east-1" `
  -backend-config="dynamodb_table=terraform-state-lock"

terraform apply -var-file="environments/dev.tfvars"
```

### 3 - Bootstrap cluster add-ons

```powershell
./scripts/bootstrap.ps1 -ClusterName my-eks-cluster -AwsRegion us-east-1
```

### 4 - Deploy the application

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

| Secret                | Description |
|-----------------------|-------------|
| `AWS_DEPLOY_ROLE_ARN` | IAM role ARN assumed via OIDC during CI/CD |
| `TF_STATE_BUCKET`     | S3 bucket for Terraform state |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking |
| `IRSA_ROLE_ARN`       | IAM role ARN for pod-level Secrets Manager access |
| `CODECOV_TOKEN`       | Token from [codecov.io](https://codecov.io) |

### Required Variables

| Variable           | Example |
|--------------------|---------|
| `AWS_REGION`       | `us-east-1` |
| `ECR_REGISTRY`     | `123456789012.dkr.ecr.us-east-1.amazonaws.com` |
| `EKS_CLUSTER_NAME` | `my-eks-cluster` |
| `APP_HOST`         | `api.example.com` |

### OIDC Trust Policy

Add this to your IAM role trust policy to allow GitHub Actions OIDC authentication:

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
      "token.actions.githubusercontent.com:sub": "repo:Mandrupnicolai/k8s-eks-platform:*"
    }
  }
}
```

---

## Secrets Management

Secrets are never stored in source control or container images. At pod startup the Secrets Store CSI Driver mounts secrets from AWS Secrets Manager into `/mnt/secrets/`.

Secret path convention: `/k8s-eks-platform/{environment}/{secret-name}`

Example: `/k8s-eks-platform/prod/db-credentials`

---

## Horizontal Pod Autoscaling

| Parameter         | Dev  | Staging | Prod |
|-------------------|------|---------|------|
| Min replicas      | 1    | 2       | 3    |
| Max replicas      | 3    | 6       | 10   |
| CPU target        | 70%  | 70%     | 70%  |
| Memory target     | 80%  | 80%     | 80%  |
| Scale-down window | 300s | 300s    | 300s |

---

## Teardown

```powershell
./scripts/teardown.ps1 -ClusterName my-eks-cluster -AwsRegion us-east-1
```

> **Warning:** This is irreversible. The script requires typing the cluster name to confirm.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch strategy, commit conventions, and PR guidelines.

---

## Security

See [SECURITY.md](SECURITY.md) for the responsible disclosure policy.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

---

## License

[MIT](LICENSE) (c) Mandrupnicolai
