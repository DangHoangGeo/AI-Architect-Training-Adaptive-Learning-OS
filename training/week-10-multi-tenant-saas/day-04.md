# Week 10 Day 4 — Failure, security, and cost review: Noisy Neighbor, Throttling, and SaaS Cost Isolation

## Goal
Stress-test PeopleOS's multi-tenant architecture by identifying noisy neighbor failure modes, designing tenant-level throttling controls, and building a cost attribution model that prevents one enterprise tenant from subsidizing another. You will produce an incident post-mortem for a simulated noisy neighbor event.

## Why this matters
PeopleOS has a shared Azure SQL Elastic Pool containing databases for 80 standard-tier tenants. On the last day of the month, a 5,000-employee tenant runs their monthly payroll calculation — a query that joins 12 tables and takes 45 minutes to complete. During those 45 minutes, every other tenant's HR application slows to a crawl: managers cannot approve time-off requests, employees cannot view pay stubs. Three tenants call support. One sends a legal notice citing SLA breach. The noisy neighbor problem is not a theoretical risk — it is the most common production failure in shared SaaS infrastructure.

## Core concept

1. **The noisy neighbor problem is caused by shared resource contention.** In a shared Azure SQL Elastic Pool, one tenant running a large query consumes DTUs (Data Transaction Units) allocated to the pool, reducing available DTUs for all other tenants. The fix is not more DTUs — it is resource governance at the tenant level.

2. **Azure SQL Database per-database max DTU limits are the correct throttle.** In an Elastic Pool, each database can be assigned a `maxDTU` cap independent of the pool's total. Setting a 200 DTU cap on standard-tier tenants prevents any single tenant from consuming more than their fair share, regardless of pool size.

3. **API-level throttling with Azure API Management (APIM) is the second control layer.** Each tenant's API calls are tracked by tenant ID. APIM policies enforce requests-per-minute limits per tenant tier. When a tenant hits 80% of their limit, APIM returns a `X-RateLimit-Remaining` header. At 100%, it returns HTTP 429.

4. **Background job isolation prevents batch operations from competing with real-time queries.** Payroll calculation, bulk employee imports, and report generation must run on a separate compute tier (a dedicated App Service plan or Azure Container Job) with a separate database connection pool. They must never share connection limits with the real-time application tier.

5. **Cost attribution by tenant requires resource tagging and custom metrics.** Azure Cost Management tags (`tenant_id`, `tier`) on every resource enable per-tenant cost analysis. For shared resources (Elastic Pool), compute cost must be allocated algorithmically (e.g., proportional to DTU consumption per tenant, measured via Azure Monitor).

6. **SLA breach detection requires per-tenant latency tracking.** A global 99th percentile latency metric hides tenant-level SLA violations. An Application Insights query that groups by `tenant_id` and alerts when P95 latency for any single tenant exceeds the SLA threshold is required. Coarse monitoring that averages across tenants is the monitoring anti-pattern that causes surprise SLA breach notifications from customers.

## Learn — write notes answering these

- What is the difference between Azure SQL Elastic Pool min/max DTU per database and reserved DTU per database? Which prevents the noisy neighbor effect?
- How does Azure API Management's "rate limit by key" policy work, and what is the correct `key` expression to isolate throttling by `tenant_id` from the JWT token in the Authorization header?
- What is Azure Container Apps' workload profile, and how does it enable dedicated compute for a single tenant's batch jobs without requiring a fully isolated deployment?
- How do you detect and alert on "partial degradation" — a state where one tenant is slow but the overall system health check returns green?

## Micro exercise

**Scenario:**
> At 23:47 on March 31st, PeopleOS's monitoring fires a P1 alert: "Elastic Pool DTU utilization 98%". The on-call engineer investigates and finds that TenantID `finance-corp-eu`, a 4,500-employee standard-tier tenant, started a batch payroll export at 23:30 that is consuming 340 DTUs continuously. The pool's total is 400 DTUs shared by 65 tenants. 12 tenants are now experiencing query timeouts. Two tenants have called the support line.

Your answer must include:
- An immediate mitigation action (what do you do in the next 5 minutes to restore service for the 12 affected tenants, without terminating `finance-corp-eu`'s payroll job).
- The architectural control that should have prevented this incident (name the specific Azure SQL configuration setting and its value).
- A post-mortem in the format: Timeline | Root Cause | Contributing Factors | Action Items. Action items must include at least one architectural change and one monitoring change.
- A tenant-level throttling policy for batch jobs: describe the APIM or Azure SQL policy, the DTU cap, and the queue-based offloading strategy.

## Reflection question
PeopleOS's largest enterprise tenant (`global-mfg-corp`, 50,000 employees) is on a fully isolated tier and generates 40% of PeopleOS's revenue. Their CTO calls to say their monthly payroll report took 8 hours last month and they are considering moving to a self-hosted solution. The 8-hour report runs on their dedicated Azure SQL Hyperscale database. What are the three most likely causes for the 8-hour query (name database-level causes), and what does PeopleOS owe this tenant in terms of architectural support?

## Prior concept connection
In Week 10 Day 3 you designed the onboarding pipeline. Today you discover that the onboarding pipeline does not set per-database DTU caps — it only creates the database in the pool with default settings. Add this to your post-mortem action items and describe the Bicep change required.

## AI coach instructions
Ask the learner to write the 5-minute mitigation action before designing the long-term fix — they are different problems. Watch for: (1) recommending "increase the pool size" as the fix (treats the symptom), (2) not distinguishing between DTU cap and DTU reservation, (3) a post-mortem with vague action items ("improve monitoring" is not acceptable — must name specific metric and threshold). Probe: "Your monitoring alert fired at 23:47. The incident started at 23:30. Why did you miss 17 minutes, and what alert would have caught it at 23:31?" Update `memory/weak_areas.md` if the learner cannot describe per-database DTU caps as distinct from pool-level limits.

## Completion criteria
- Learner described an immediate mitigation action that does not terminate the payroll job.
- Learner named the specific Azure SQL configuration that should have prevented the incident.
- Learner produced a structured post-mortem with at least one architectural and one monitoring action item.
- Learner described a throttling policy with specific limits.
- AI reviewed with cloud architect, DevOps, and cost optimizer perspectives.
- Any mistakes added to `memory/mistakes.md`.
