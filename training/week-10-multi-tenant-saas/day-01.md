# Week 10 Day 1 — Concept foundation: Tenant Isolation Models

## Goal
Understand the three tenant isolation models — shared everything, shared infrastructure / isolated data, and fully isolated — and be able to select the right model for a given enterprise B2B SaaS requirement. By the end of this session you can articulate the cost, security, compliance, and operational trade-offs of each model using a real HR platform scenario.

## Why this matters
A B2B HR platform that puts all tenant data in one database with a `tenant_id` column may work fine for 10 small customers. When the first enterprise customer — a bank with 50,000 employees — signs the contract, their legal team sends a 20-page data processing agreement demanding logical isolation and the right to audit your data store configuration. If your architecture cannot satisfy that requirement, you lose the deal. If it can but you did not design for it from the start, the migration costs more than building it right the first time.

## Core concept

1. **Shared everything (pool model):** All tenants share the same application instances, database, and storage. Isolation is enforced only by application-level filtering (e.g., `WHERE tenant_id = ?`). Cost is lowest; isolation is weakest. A query bug can expose one tenant's data to another. Appropriate for SMB customers with no compliance requirements.

2. **Shared infrastructure, isolated data (silo-per-tenant data model):** Each tenant gets their own database or schema, but shares the application tier and compute. This is the most common enterprise SaaS model. Isolation guarantees are strong at the data layer. Operational complexity increases with tenant count — 500 tenants means 500 databases to patch, back up, and monitor.

3. **Fully isolated (dedicated everything):** Each tenant gets their own application deployment, database, network, and potentially Azure subscription. Maximum isolation. Justifiable for regulated industries (banking, defense) or customers who require geographic isolation. Cost is highest and scales linearly with tenant count. Azure Deployment Environments or Azure Managed Applications can automate this.

4. **The isolation model is a business decision, not just a technical one.** Price tiers map to isolation models. "Enterprise" tier = isolated database. "Professional" tier = shared database, isolated schema. "Starter" tier = shared schema. This tiering must be designed before the first enterprise customer signs.

5. **Cross-tenant data leakage is the catastrophic failure mode.** In a pool model, a missing `tenant_id` filter in one query can expose every tenant's employee records. In a silo model, a misconfigured connection string can route one tenant to another's database. The architecture must make cross-tenant access structurally impossible, not just unlikely.

6. **Azure has native patterns for each model.** Elastic pools for pool model, Azure SQL Database per tenant for silo model, Azure Subscriptions per tenant for fully isolated. Each maps to a different cost model and operational footprint.

## Learn — write notes answering these

- What is the difference between row-level security (RLS) in Azure SQL and schema-per-tenant isolation? Which provides stronger guarantees and why?
- In the silo model with 500 tenant databases, how do you run a schema migration (e.g., adding a column) across all tenants without a 10-hour maintenance window?
- What is an "Azure Elastic Pool" and when does it make more economic sense than provisioning 500 individual Azure SQL databases?
- How does Azure Active Directory B2C or Microsoft Entra External ID support tenant-specific identity namespaces in a multi-tenant SaaS platform?

## Micro exercise

**Scenario:**
> PeopleOS is a startup building a B2B HR platform to compete with Workday. They have three signed customers about to onboard: (1) a 200-person tech startup with no compliance requirements, (2) a 5,000-person regional bank that requires data isolation and has signed a data processing agreement referencing GDPR and the EBA Cloud Outsourcing Guidelines, (3) a 30,000-person manufacturing conglomerate that operates in the EU and US and wants data to remain in the region where each employee is located.

Your answer must include:
- The isolation model you would assign to each of the three customers, with a one-sentence justification.
- The Azure data services you would use for each customer's data store, with SKU.
- One risk if you assign the wrong isolation model to the bank customer.
- How your application tier identifies which database to connect to for an incoming API request (describe the routing logic and where the tenant-to-database mapping lives).

## Reflection question
You designed a perfect tenant isolation model today. In 18 months, PeopleOS has 400 tenants on the silo model. The CTO asks: "Can we merge 50 small tenants who never use their dedicated databases into a shared pool to cut costs?" What are the technical steps, and what is the risk that no amount of engineering can fully eliminate?

## Prior concept connection
In Week 8 you studied data storage patterns and Azure SQL. Today you are applying those storage fundamentals to a multi-tenant context. Specifically: if you used elastic pools in Week 8, explain why they are the preferred choice for the silo model at scale.

## AI coach instructions
Ask the learner to assign isolation models before revealing trade-offs. Watch for: (1) assigning pool model to the bank (wrong — RLS is not sufficient for EBA compliance), (2) not addressing the routing logic (tenant-to-database mapping), (3) ignoring the geographic data residency requirement for the manufacturing conglomerate. Probe: "Your bank customer's auditor asks to see evidence that their employees' payroll data is stored separately from other customers. What Azure-native artifact do you show them?" Update `memory/weak_areas.md` if the learner does not distinguish between row-level security and database-level isolation.

## Completion criteria
- Learner assigned and justified isolation models for all three customers.
- Learner named Azure data services with SKUs.
- Learner described the tenant routing logic.
- Learner identified the correct risk for the bank customer scenario.
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
