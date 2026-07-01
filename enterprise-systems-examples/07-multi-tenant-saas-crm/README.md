# Multi-Tenant SaaS CRM

## Real-world scenario

**Orbit CRM** is a B2B SaaS CRM platform (a Salesforce-style product) with 8,000 customer organizations ranging from 3-person startups to a 40,000-employee enterprise customer that alone generates more data volume than the next 500 customers combined. Orbit sells three tiers: Starter (shared infrastructure, lowest price), Business (shared infrastructure with stronger isolation guarantees), and Enterprise (dedicated infrastructure, contractually required, highest price).

The hardest recurring incident type is the **noisy neighbor problem**: one tenant running a massive data export or a runaway automation workflow degrades performance for every other tenant sharing that infrastructure. Enterprise customers pay specifically to never experience this; Starter/Business customers accept some shared-infrastructure risk at a lower price point — the architecture must actually deliver on that pricing/isolation promise, not just claim it in a sales deck.

## Why this is architecturally hard

- **Tiered isolation guarantees mapped to a real cost model.** "Isolation" isn't binary — the system must offer meaningfully different, correctly-priced isolation levels, not fake tiers that all share the same failure domain.
- **Per-tenant cost attribution.** To price tiers sustainably, the platform must know the actual infrastructure cost each tenant generates, not just its subscription revenue.
- **Schema evolution across thousands of tenants.** A platform feature release must roll out safely across 8,000 tenants with different customization/data volumes without a single bad migration taking down a shared database.
- **The single largest tenant can be ~500x the size of a typical tenant** — the data model and scaling strategy must not silently assume "tenants are roughly similar size."

## What's in this folder

- `pm_brief.md` — the tiered pricing/isolation business model and what customers are actually buying at each tier.
- `design.md` — pool-per-tier multi-tenancy model (shared pool with row-level isolation for Starter/Business, dedicated resources for Enterprise), noisy-neighbor mitigation, and per-tenant cost metering.
- `architecture_decisions.md` — why isolation is tiered rather than uniform, why row-level security is used for shared tiers instead of schema-per-tenant, why Enterprise tenants get dedicated database instances, and how the largest outlier tenant is handled.

## Related training weeks

Week 10 (Multi-Tenant SaaS), Week 4 (Data & Storage), Week 6 (Observability & Operations).
