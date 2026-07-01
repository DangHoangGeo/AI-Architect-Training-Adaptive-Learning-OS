# Architecture Decision Records — Multi-Tenant SaaS CRM

## ADR-001: Row-Level Security over schema-per-tenant for shared tiers

### Status
Accepted

### Context
Starter and Business tiers (the vast majority of 8,000 tenants) need strong logical isolation without the operational burden of managing per-tenant schema migrations at scale.

### Options considered
- Option A: Schema-per-tenant within a shared database.
- Option B: Single shared schema with Row-Level Security enforcing tenant_id filtering at the database engine.

### Decision
Option B.

### Consequences
Positive: a single schema migration deploys to all shared-tier tenants at once instead of 8,000 individual migrations; isolation is enforced by the database engine, not application code discipline. Negative: RLS policies must be rigorously tested — a misconfigured policy is a real cross-tenant data-leak risk, requiring an automated RLS regression suite gating every schema change.

### Review date
At any incident involving RLS policy behavior, or annually as part of the security review.

---

## ADR-002: Dedicated infrastructure (not just stronger governance) for Enterprise tier

### Status
Accepted

### Context
Some Enterprise contracts require actual physical/logical separation (data residency guarantees, no shared-hardware attestation) as a signed condition, not just a performance guarantee.

### Options considered
- Option A: Market Enterprise tier as stronger resource governance and RLS enforcement on the same shared infrastructure as Business tier.
- Option B: Fully dedicated Azure SQL instance and Container Apps environment per Enterprise tenant.

### Decision
Option B.

### Consequences
Positive: satisfies contractual isolation requirements that no amount of governance on shared infrastructure can meet; removes noisy-neighbor risk for this tier entirely by construction. Negative: meaningfully higher per-tenant infrastructure cost, requiring the Enterprise price point to be validated against real cost data (see ADR-004) to remain sustainable.

### Review date
At each new Enterprise contract negotiation — confirm isolation requirements match what's actually built.

---

## ADR-003: Treat the outlier tenant as its own capacity-planning unit

### Status
Accepted

### Context
One tenant is approximately 500x the size of a typical tenant. Any capacity model assuming roughly uniform tenant size fails at this outlier.

### Options considered
- Option A: Rely on shared-pool autoscaling to absorb the outlier's load alongside all other tenants.
- Option B: Give the outlier tenant dedicated infrastructure sized specifically for its own load profile, tracked independently in capacity planning.

### Decision
Option B (this tenant is already Enterprise tier, so this aligns with ADR-002).

### Consequences
Positive: shared-pool capacity planning stays based on genuinely comparable tenant sizes, keeping autoscaling behavior predictable for everyone else. Negative: this tenant's infrastructure must be capacity-planned individually rather than folded into aggregate tenant-growth forecasting, requiring a dedicated account-level capacity review process.

### Review date
Quarterly, tied to this tenant's own growth trajectory review.

---

## ADR-004: Per-tenant cost metering pipeline instead of tier-average cost estimation

### Status
Accepted

### Context
Finance needs to validate that each pricing tier is actually profitable, but subscription-tier averages can hide tenants whose actual infrastructure cost exceeds their subscription revenue.

### Options considered
- Option A: Estimate per-tenant cost using tier-level infrastructure cost averages.
- Option B: Build a per-tenant metering pipeline (Azure Monitor metrics -> Event Hubs -> Data Lake -> Power BI) attributing actual resource consumption to each tenant.

### Decision
Option B.

### Consequences
Positive: surfaces exactly which tenants are unprofitable at their current tier, enabling targeted upsell or re-pricing conversations instead of guessing; the same pipeline feeds the Runaway Workload Detector, so the investment serves two purposes. Negative: adds a data pipeline that must itself be operated and kept accurate; metering data has some inherent lag (see Failure scenarios in design.md), so it supports margin analysis, not real-time billing decisions.

### Review date
Every fiscal quarter, alongside pricing-tier margin review.
