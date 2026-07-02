# System Design — Multi-Tenant SaaS CRM Isolation Model

## 1. Problem statement
Orbit CRM needs a multi-tenancy architecture that delivers meaningfully different, correctly priced isolation guarantees across its Starter, Business, and Enterprise tiers, prevents noisy-neighbor incidents on shared infrastructure, and provides accurate per-tenant cost data — while handling one outlier tenant roughly 500x the size of a typical tenant.

## 2. Users and stakeholders
- 8,000 customer organizations across 3 pricing tiers
- Orbit sales (sells the isolation guarantee)
- Orbit finance (validates tier pricing against real cost)
- Platform SRE (operates the shared and dedicated infrastructure)

## 3. Functional requirements
- Serve CRM functionality (contacts, deals, automations, reporting) to all tenants regardless of tier.
- Enforce per-tenant data isolation appropriate to that tenant's pricing tier.
- Detect and throttle a tenant's runaway resource usage before it affects other tenants.
- Meter and report actual infrastructure cost per tenant.

## 4. Non-functional requirements
- Scale: 8,000 tenants; one outlier tenant ~500x the median tenant's data volume and query load.
- Availability: 99.9% for Starter/Business, 99.95% for Enterprise (contractual).
- Latency: P99 CRM page load under 500ms regardless of other tenants' activity on shared infrastructure.
- Security: Strict tenant data isolation — a query must be structurally incapable of returning another tenant's data.
- Compliance: Some Enterprise customers require dedicated infrastructure as a contractual/regulatory condition (e.g., data residency, no shared hardware attestation).
- Cost: Per-tenant cost attribution accurate enough to validate gross margin at each pricing tier.
- Operability: Runaway workload detection and throttling must be automatic, not dependent on an SRE noticing a complaint.

## 5. Constraints and assumptions
- Existing product is Azure SQL-based; migrating to a fundamentally different database engine is out of scope.
- Enterprise tier isolation is a signed contractual commitment, not just a technical nice-to-have — it must never be violated even during an incident.
- The single outlier tenant is itself Enterprise tier and already budgeted for dedicated infrastructure.

## 6. High-level architecture
```
Tenants (by tier)
   |
   v
Azure Front Door -> API Management (tenant identification via subdomain/claim, rate limiting)
   |
   |-- Starter/Business tier (shared pool) -----------------------------
   |     Container Apps (shared, autoscaled) -> Application layer enforces tenant_id
   |     on every query via Row-Level Security (RLS) in Azure SQL Elastic Pool
   |     -> Per-tenant resource governance: query timeout budgets, RLS-scoped
   |        connection throttling, automation-engine execution quotas
   |     -> Runaway Workload Detector (Container Apps) watches per-tenant
   |        query cost/duration, auto-throttles offending tenant's automations
   |
   |-- Enterprise tier (dedicated) --------------------------------------
   |     Dedicated Azure SQL instance per Enterprise tenant
   |     Dedicated Container Apps environment per Enterprise tenant (largest ones)
   |     or dedicated node pool for mid-size Enterprise tenants
   |
   v
Cost Metering Pipeline (Azure Monitor metrics per tenant/resource -> Event Hubs ->
Data Lake -> Power BI cost dashboard for finance)

Cross-cutting: Microsoft Entra ID (tenant + user auth), Key Vault, Azure Policy
(tier-appropriate resource tagging enforcement), Azure Monitor (per-tenant dashboards).
```

## 7. Deep dives
- **Compute:** Starter/Business tenants share Container Apps compute with autoscaling; Enterprise tenants (especially the largest outlier) get dedicated Container Apps environments so their load pattern cannot affect anyone else's compute capacity.
- **Network:** Tenant identification happens at APIM via subdomain or JWT claim, routing shared-tier traffic to the shared backend and Enterprise-tier traffic to that tenant's dedicated environment before any shared resource is touched.
- **Identity:** Entra ID external tenants (B2B) map to Orbit's internal tenant model; every token carries a tenant claim validated at every layer, not just at the API gateway.
- **Data:** Row-Level Security in Azure SQL enforces tenant isolation for shared-pool tenants at the database engine level, not just the application layer — a bug in application code cannot leak cross-tenant data because the database itself refuses to return rows outside the session's tenant context. Enterprise tenants get fully separate database instances, removing any shared-database risk entirely.
- **Observability:** Per-tenant resource consumption (query cost, automation execution time, storage) is tracked as a first-class metric, feeding both the Runaway Workload Detector and the finance cost dashboard from the same data pipeline.
- **Business continuity:** Enterprise dedicated instances have independent backup/restore schedules; a restore for one Enterprise tenant never touches another tenant's data, satisfying contractual isolation even during disaster recovery.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Shared-tier isolation model | Row-Level Security (single shared schema, tenant_id enforced by the database) | Schema-per-tenant (one schema per tenant within a shared database) | Schema-per-tenant would require 8,000 schema migrations per feature release, an operational nightmare at this scale; RLS gives strong logical isolation with a single schema to migrate, at the cost of needing rigorous RLS policy testing since a misconfigured policy is a real data-leak risk. |
| Enterprise tier isolation | Fully dedicated Azure SQL instance + dedicated compute per Enterprise tenant | Stronger RLS/resource governance on the same shared infrastructure, marketed as "Enterprise" | Some Enterprise contracts require actual physical/logical separation (data residency, no shared hardware) that no amount of RLS or governance can satisfy on shared infrastructure — this tier must be genuinely separate, not just more strongly governed. |
| Outlier tenant handling | Dedicated infrastructure sized specifically for that tenant, tracked as its own capacity-planning unit | Assume average tenant sizing and let autoscaling absorb the outlier within the shared pool | A tenant 500x the median would either starve shared-pool resources for everyone else or require the shared pool to be provisioned 500x larger than needed for all other tenants combined; treating it as its own capacity-planning unit is the only sustainable approach. |
| Cost visibility | Per-tenant metering pipeline feeding a finance dashboard | Estimate tenant cost from subscription tier averages | Averages hide exactly the cross-subsidization problem the business needs to see — a Starter tenant running heavy automations could cost more to serve than their subscription revenue, and only per-tenant metering surfaces that. |

**Cost:** Per-tenant cost metering is what allows Orbit to actually validate that each pricing tier has healthy margin, rather than assuming it based on subscription price alone.
**Security:** Database-enforced Row-Level Security means tenant isolation for shared tiers doesn't rely on every application code path getting a `WHERE tenant_id = ?` clause right — the failure mode of a missed filter is contained by the database itself.
**Scalability:** Separating the outlier/Enterprise tenants from the shared pool means the shared pool's capacity planning is based on genuinely comparable tenant sizes, making autoscaling behavior predictable.
**Reliability:** The Runaway Workload Detector directly targets the noisy-neighbor problem that is today's most common incident type, converting it from a reactive firefight into an automated, structural mitigation.
**Operations:** Automatic throttling of runaway workloads removes the need for SRE to manually identify and mitigate a noisy tenant during business hours.
**Product value:** A technically credible, tiered isolation story is a direct sales enablement tool for the Enterprise upsell, and reducing noisy-neighbor incidents directly reduces churn risk for Business tier.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| RLS policy misconfigured after a schema change | Potential cross-tenant data leak in shared pool | Automated RLS policy regression test suite run in CI on every schema migration | Migration pipeline blocks deploy if RLS test suite fails; additionally, periodic automated audits query as multiple synthetic tenants to verify isolation in production |
| One Business-tier tenant runs a massive export | Shared pool query latency degrades for other tenants in that pool | Runaway Workload Detector flags per-tenant query cost anomaly | Automatic throttling of that tenant's connection/query rate; tenant notified their export is rate-limited to protect shared performance, per terms of service |
| Enterprise dedicated instance under-provisioned for sudden growth | That tenant experiences degraded performance (isolated to them only) | Per-tenant capacity utilization alert | Capacity planning review triggers proactive resize; because it's dedicated, this never becomes a multi-tenant incident |
| Cost metering pipeline lag | Finance dashboard shows stale per-tenant cost data | Pipeline freshness/lag alert | Dashboard displays explicit "as of" timestamp; finance decisions use the most recent complete billing cycle, not real-time data, so lag doesn't cause a wrong decision |

## 10. Security design
- **AuthN:** Entra ID external identities per tenant organization, with tenant claim embedded in every issued token.
- **AuthZ:** Row-Level Security enforced at the database engine for shared tiers; dedicated instances provide full logical/physical separation for Enterprise tier by construction.
- **Network exposure:** Shared-tier backend has no tenant-specific network path (isolation is data-layer, not network-layer); Enterprise dedicated environments can additionally offer private networking/VNet peering as a contractual option.
- **Secrets:** Per-tenant encryption keys for Enterprise dedicated instances in Key Vault, supporting customer-managed key requirements some Enterprise contracts require.
- **Encryption:** TDE at rest for all tiers; Enterprise tier supports customer-managed keys as an add-on.
- **Audit:** Automated periodic isolation audits (synthetic cross-tenant query attempts) are themselves logged and reviewed as a continuous compliance control, not a one-time test.

## 11. Cost model
- Main drivers: Azure SQL Elastic Pool for shared tiers, dedicated Azure SQL + Container Apps environments for Enterprise tier, cost-metering pipeline infrastructure (Event Hubs + Data Lake + Power BI).
- Reduction levers: Elastic Pool sharing across right-sized, genuinely comparable shared-tier tenants maximizes utilization; per-tenant metering lets Orbit identify and either upsell or re-price consistently unprofitable Starter/Business tenants.
- Enterprise tier's dedicated infrastructure cost is directly passed through in its higher price point, validated against actual per-tenant cost data rather than assumed margin.

## 12. Evolution plan
- **10x scale (80,000 tenants):** Shared pool sharding strategy (multiple Elastic Pools, tenants distributed by size/activity profile) to keep any single pool's blast radius bounded as tenant count grows.
- **Enterprise adoption (more Enterprise contracts):** The dedicated-instance pattern is already the template; onboarding a new Enterprise tenant becomes a standardized Bicep-deployed unit rather than a bespoke setup.
- **Multi-region:** Enterprise tenants requiring specific data residency can be placed in region-specific dedicated instances using the same isolation pattern, without redesigning the shared-tier architecture.
