# Architecture Decisions — Production Observability Platform

## ADR-001 — Use managed Azure platform services for baseline

### Status
Accepted

### Context
The learner needs to practice production-minded architecture without spending the workshop on low-level server management.

### Options considered
- App Service / Container Apps managed compute.
- Virtual machines.
- Full AKS cluster.

### Decision
Use managed compute as the default baseline. Introduce AKS only when orchestration complexity is justified.

### Consequences
- Faster deployment and lower operational burden.
- Less control over infrastructure internals.
- Better fit for learning architecture trade-offs.

## ADR-002 — Use modular Bicep

### Status
Accepted

### Context
Workshops should build reusable IaC habits.

### Decision
Use `main.bicep` plus modules for network, monitoring, storage, identity, compute, and optional scenario services.

### Consequences
- More files to understand.
- Better reuse and clearer ownership boundaries.
