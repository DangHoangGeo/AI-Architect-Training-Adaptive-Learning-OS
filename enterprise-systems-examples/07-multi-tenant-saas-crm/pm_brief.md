# PM Brief — Multi-Tenant SaaS CRM Isolation Model

## Customer problem
Starter and Business tier customers periodically experience performance degradation caused by other tenants' heavy usage (large exports, runaway automations) on shared infrastructure — a recurring support escalation and churn risk. Enterprise customers pay a premium specifically for isolation guarantees that must actually hold under load, or the pricing model itself is misleading.

## Target users
- **Primary:** All 8,000 customer organizations, segmented by pricing tier.
- **Secondary:** Orbit's sales team (needs a credible isolation story to sell Enterprise tier), finance (needs per-tenant cost data to validate tier pricing is sustainable).
- **Operational:** Platform SRE team who currently firefight noisy-neighbor incidents reactively.

## Value proposition
A tiered isolation architecture that structurally guarantees Enterprise customers never share a failure domain with any other tenant, while giving Starter/Business tenants meaningfully better shared-infrastructure behavior than today, directly reduces churn and gives sales a technically credible Enterprise upsell story.

## Success metrics
- Noisy-neighbor-caused support tickets reduced by 90% for Business tier.
- Zero cross-tenant performance incidents reported by Enterprise tier customers.
- Per-tenant cost visibility accurate enough to validate gross margin per pricing tier.
- Platform-wide feature rollout across all 8,000 tenants completes without a shared-database incident.

## MVP scope
- Row-level security based tenant isolation with per-tenant resource governance (query/compute budgets) for Starter/Business pools.
- Dedicated Azure SQL instances for Enterprise tier tenants.
- Per-tenant cost metering pipeline feeding a finance-facing cost dashboard.
- Automated detection and throttling of runaway per-tenant workloads (exports, automations) before they affect other tenants.

## Non-goals
- Migrating existing Enterprise tenants to a different database engine (Azure SQL retained, just given dedicated instances).
- Real-time cost-based dynamic pricing (cost visibility is for margin analysis, not automated billing changes, in this phase).
- Rebuilding the automation/workflow engine itself (only its resource governance is addressed here).

## Risks
- **Product risk:** Sales may oversell "isolation" for Business tier if the messaging isn't precise about what's actually guaranteed vs. Enterprise tier.
- **Technical risk:** The largest single tenant is ~500x the typical tenant's data volume; any solution assuming roughly-uniform tenant size will fail on this outlier and must be explicitly designed around it.
- **Delivery risk:** Migrating Enterprise tenants to dedicated instances while they're live, paying customers requires a zero-downtime migration approach.
- **Adoption risk:** Internal engineering teams building new features need clear guardrails (per-tenant resource budgets) baked into the platform so new features don't reintroduce noisy-neighbor risk by accident.

## Roadmap
- **V1:** Row-level security + per-tenant resource governance for shared pools; runaway-workload detection and throttling.
- **V2:** Dedicated Enterprise tier instances migration; per-tenant cost metering dashboard for finance.
- **V3:** Automated tier-appropriate placement recommendations (e.g., flag a Business tenant outgrowing shared-pool limits as an Enterprise upsell candidate).
