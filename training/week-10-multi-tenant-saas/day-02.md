# Week 10 Day 2 — Azure service mapping: Data Partitioning Strategies for Enterprise HR SaaS

## Goal
Map PeopleOS's data partitioning strategy to specific Azure services, understanding how partitioning decisions affect query performance, backup granularity, compliance reporting, and future tenant migration. You will produce a data architecture diagram (described in text) and a partitioning decision record.

## Why this matters
PeopleOS onboards a 30,000-person manufacturing conglomerate. Their payroll data includes employees in Germany (GDPR, Works Council approval required), the US (FLSA, state-level payroll tax rules), and Brazil (LGPD). If all employee records live in a single Azure SQL database in West Europe, the US and Brazil employees' data is in violation of their data residency requirements from day one. Discovering this after go-live means a re-architecture project under legal pressure — the most expensive kind.

## Core concept

1. **Horizontal partitioning (sharding) distributes rows across databases by a partition key.** For HR SaaS, the natural shard key is `tenant_id`. All rows for a tenant live in the same shard. Azure SQL Elastic Database client library (formerly Elastic Scale) manages shard maps. This enables tenant-level operations (backup, migration, deletion) without touching other tenants' data.

2. **Vertical partitioning separates columns into different tables or stores.** In an HR system, employee PII (name, address, date of birth) might be stored in Azure SQL with encryption, while payroll transaction history is stored in Azure Cosmos DB for high-volume append-only access, and document scans (passports, contracts) are in Azure Blob Storage with per-tenant containers.

3. **Geographic partitioning places data in Azure regions based on residency rules.** For PeopleOS, EU employees → West Europe or North Europe; US employees → East US 2; Brazil employees → Brazil South. This requires a geo-routing layer that inspects the employee's legal entity and routes reads and writes to the correct regional deployment.

4. **Azure Cosmos DB for NoSQL with partition keys** is the correct choice for high-velocity, append-only HR data (time-off requests, clock-in/clock-out events, expense submissions). The partition key must be chosen carefully: `tenant_id` alone causes hot partitions for large tenants; `tenant_id + year_month` distributes load while preserving tenant isolation.

5. **Azure SQL Hyperscale** is the correct choice for large tenants with complex relational queries (payroll calculations, org chart traversal). It scales storage independently of compute and supports up to 100TB per database — sufficient for a 50,000-employee tenant with 10 years of payroll history.

6. **The shard map manager is a single point of failure by design.** PeopleOS needs a global shard map (which tenant is in which database) stored in a highly available, geo-redundant location. Azure SQL with zone-redundant configuration or Azure Cosmos DB with multi-region writes is the correct home for the shard map, not a config file on a VM.

## Learn — write notes answering these

- What is the difference between a "range" partition and a "list" partition in the context of Azure SQL Elastic Database sharding, and which is appropriate for tenant-based sharding?
- How does Azure Cosmos DB's partition key selection affect cross-partition query cost? Give a specific example using PeopleOS's time-off request data.
- What is Azure SQL's "elastic query" feature and how does it enable cross-tenant reporting (e.g., "total headcount across all tenants") without application-level aggregation?
- How do you enforce data residency in Azure at the infrastructure level — i.e., what prevents an engineer from accidentally deploying a new database in the wrong region?

## Micro exercise

**Scenario:**
> PeopleOS has grown to 12 enterprise tenants. The three largest are: (A) a 50,000-employee German automotive manufacturer (EU data residency required, Works Council approval means no data export to non-EU countries), (B) a 15,000-employee US pharmaceutical company (FDA 21 CFR Part 11 requires immutable audit logs for all data changes), (C) a 3,000-employee Australian retail chain (no specific compliance requirements, wants lowest cost). The CTO has asked you to design the data partitioning architecture that serves all three without deploying three completely separate SaaS platforms.

Your answer must include:
- A partitioning architecture with named Azure services, regions, and tiers for each of the three tenants.
- How the application determines which database/region to query for an incoming API request from an employee in Stuttgart, Germany vs. an employee in New Jersey, USA.
- How you satisfy the FDA immutable audit log requirement using an Azure-native service (name the specific service and feature).
- One partitioning decision you would make differently if PeopleOS grew to 500 tenants, and why the current design would not scale.

## Reflection question
The German automotive manufacturer's Works Council invokes their right to data deletion for 500 employees who have left the company. Your partitioning model stores their data across three Azure SQL databases (current, archive, audit log) and one Blob Storage account. Write out the deletion procedure step by step, including what you cannot delete (audit logs may be legally required for 10 years) and how you reconcile GDPR right to erasure with legal retention obligations.

## Prior concept connection
In Week 10 Day 1 you assigned isolation models to three customers. Today you are implementing those models as specific partitioning strategies. Explicitly link: "The bank customer got [isolation model] which maps to [partitioning strategy] implemented with [Azure service]." If the mapping creates inconsistencies with today's new requirements, revise and explain why.

## AI coach instructions
The learner must address all three tenants, not just the most interesting one. Watch for: (1) placing the German tenant's data in West US (wrong region), (2) using Azure Blob Storage versioning as the FDA audit log solution (insufficient — needs immutable storage with legal hold), (3) not describing the geo-routing logic. Probe: "You said tenant routing reads from the shard map. Where is the shard map stored, and what happens to all 12 tenants if that store is unavailable for 5 minutes?" Update `memory/weak_areas.md` if the learner cannot distinguish between Azure SQL geo-replication (for reads) and geo-partitioning (for compliance).

## Completion criteria
- Learner named specific Azure services, regions, and tiers for all three tenants.
- Learner described the geo-routing logic for employee-level request routing.
- Learner named Azure Immutable Blob Storage or a compliant audit log service for FDA requirements.
- Learner identified one scaling limitation of the current design.
- AI reviewed with cloud architect and compliance perspectives.
- Any mistakes added to `memory/mistakes.md`.
