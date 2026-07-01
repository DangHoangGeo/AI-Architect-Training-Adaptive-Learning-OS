# Threat Model — AI Document Processing System

## Assets
- Application endpoint.
- Storage data.
- Logs and telemetry.
- Managed identity permissions.
- Secrets in Key Vault.

## Trust boundaries
- Internet to application endpoint.
- Application to Azure platform services.
- Operator workstation to Azure control plane.
- CI/CD system to Azure deployment APIs.

## STRIDE

### Spoofing
Risk: attacker impersonates user or workload identity.
Control: use Entra ID, managed identity, and least-privilege RBAC.

### Tampering
Risk: unauthorized modification of data or deployment templates.
Control: source control reviews, RBAC, storage protections, and deployment logs.

### Repudiation
Risk: inability to prove who changed configuration.
Control: Azure Activity Log, diagnostic settings, and CI/CD audit trails.

### Information disclosure
Risk: public exposure of storage, secrets, or logs.
Control: disable public blob access, Key Vault, HTTPS, and careful log redaction.

### Denial of service
Risk: traffic spike or dependency exhaustion.
Control: autoscale, queues where applicable, rate limiting, and alerts.

### Elevation of privilege
Risk: overly broad roles on managed identities or users.
Control: least privilege, role review, PIM where applicable, and separate environment access.

## Residual risks
- Development baseline may allow public network access for simplicity.
- Private endpoints and WAF should be added for stricter production requirements.
