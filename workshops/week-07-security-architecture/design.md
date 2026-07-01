# Design — Secure Enterprise API

## Problem statement
Design secure enterprise api on Azure with secure defaults, measurable operations, cost awareness, and an evolution path.

## Requirements

### Functional
- Protected API boundary
- Secret management
- Threat model

### Non-functional
- Least privilege
- Auditability
- Reduced public exposure

## Proposed architecture
Use the Bicep starter as the initial deployable baseline:

- App Service or Container Apps for compute depending on workshop scope.
- Storage account for durable object or queue storage.
- Log Analytics and Application Insights for observability.
- Virtual network and NSG for network segmentation foundations.
- Key Vault and managed identity for secretless access patterns.
- Optional SQL, queue, container apps, or AI services based on the weekly scenario.

## Trade-offs to analyze
- Managed platform services vs self-managed compute.
- Public endpoint simplicity vs private endpoint security.
- Low-cost development SKUs vs production resilience.
- Synchronous request flow vs asynchronous queue-based processing.
- Single-region simplicity vs multi-region complexity.

## Failure scenarios
- Compute instance fails.
- Storage unavailable or throttled.
- Deployment fails halfway.
- Identity permission misconfigured.
- Traffic exceeds expected capacity.

## Security considerations
- Use managed identity for Azure resource access.
- Avoid secrets in source control.
- Enforce HTTPS and modern TLS.
- Restrict public access where possible.
- Log administrative activity and application failures.

## Cost considerations
- Use smaller SKUs in dev.
- Set log retention intentionally.
- Avoid unused always-on compute when scale-to-zero fits.
- Review storage replication requirements before choosing GRS.

## Evolution plan
- Add private endpoints and private DNS for enterprise production.
- Add CI/CD pipeline with approvals.
- Add policy assignments for governance.
- Add regional resilience when RTO/RPO requires it.
