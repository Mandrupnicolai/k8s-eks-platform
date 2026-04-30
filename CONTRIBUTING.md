# Contributing to k8s-eks-platform

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production. Protected; requires passing CI and one approval. |
| `develop` | Integration branch. |
| `feature/*` | New features — branch from `develop`. |
| `fix/*` | Bug fixes — branch from `develop`. |
| `hotfix/*` | Critical fixes — branch from `main`. |

## Commit Conventions

Follows [Conventional Commits](https://www.conventionalcommits.org/):
<type>(scope): <short description>
Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`

## PR Process

1. Branch from `develop`, make changes, run checks locally
2. Open PR against `develop` with clear description
3. Ensure all CI checks pass and get one approval

## Code Standards

- **PowerShell:** `[CmdletBinding()]`, `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`
- **Terraform:** Run `terraform fmt` before committing. All variables need `description` and `type`
- **Helm:** All values have defaults in `values.yaml`. No hardcoded account IDs or regions
- **Node.js:** All new functions have tests. Maintain >80% coverage
- **Docker:** Multi-stage builds, non-root user, `HEALTHCHECK` required
