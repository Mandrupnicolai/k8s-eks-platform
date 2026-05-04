# Changelog

All notable changes to this project will be documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Added
- EKS cluster provisioning via Terraform (VPC, managed node groups, IRSA)
- Helm chart with Deployment, Service, HPA, Ingress, SecretProviderClass
- Node.js API microservice with health/readiness probes and Jest tests
- Nginx frontend microservice with hardened nginx config
- AWS Secrets Manager integration via Secrets Store CSI Driver
- HPA for API and Frontend on CPU and memory metrics
- GitHub Actions CI: lint, test, Docker build, Terraform validate
- GitHub Actions CD: ECR push, Terraform apply, Helm upgrade with preflight guard
- OIDC-based AWS authentication, no static credentials
- PowerShell scripts: bootstrap, deploy, teardown
- Dependabot for automated dependency updates
- Branch protection and conventional commit conventions
