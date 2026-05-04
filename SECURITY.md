# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| latest (master) | Yes |

## Reporting a Vulnerability

Do not open a public GitHub issue for security vulnerabilities.

Instead report them via [GitHub private vulnerability reporting](https://github.com/Mandrupnicolai/k8s-eks-platform/security/advisories/new).

Include: description, steps to reproduce, potential impact, and suggested fix.

Expect acknowledgement within 48 hours and a resolution timeline within 7 days for critical issues.

## Security Practices in This Project

- No secrets stored in source control
- AWS credentials use OIDC, no static access keys
- Containers run as non-root with read-only root filesystems
- Secrets injected at runtime via AWS Secrets Manager CSI Driver
- Dependabot enabled for automated dependency updates
