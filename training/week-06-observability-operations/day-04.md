# Week 06 Day 4 — Failure, Security, and Cost Review: Log Retention and Cost Management

## Goal
Stress-test NovaBridge's observability architecture by analyzing the cost explosion risk of naive Log Analytics configuration, design a retention and tiering strategy that balances compliance requirements with budget reality, and identify the security risks of poorly governed log access.

## Why this matters
NovaBridge configured Diagnostic Settings on Day 1 and Application Insights on Day 2 — but nobody checked the Log Analytics pricing model. Three months after implementation, the monthly Azure bill for Log Analytics has grown to $4,200/month, up from $0. The finance team has asked engineering to explain or cut the cost. Meanwhile, a Platinum client's legal team has requested 12 months of audit logs for a compliance investigation — and the team discovers the default retention is 30 days.

## Core concept

1. **Log Analytics pricing model: pay per GB ingested.** The standard pay-per-use rate is approximately $2.30–$2.76/GB ingested (varies by region). At 50 GB/day, that is $115/day or $3,500/month — just for ingestion. Retention has a separate cost after the free 30-day window. Understanding this model before enabling verbose logging is the architect's responsibility.

2. **The four cost levers.**
   - **Sampling:** Application Insights adaptive sampling reduces telemetry volume by 70–90% for high-traffic apps. Configured per telemetry type.
   - **Daily ingestion cap:** A hard cap on GB/day. When hit, ingestion stops — this means you go blind during the highest-traffic (often highest-incident-probability) period. Use as a budget guardrail, not a primary cost control.
   - **Basic vs. Analytics log tier (2023+ feature):** Log Analytics "Basic Logs" tier costs ~$0.50/GB but only supports simple queries. Use it for verbose diagnostic logs you rarely query (DNS, firewall). Use "Analytics" tier for logs you need to alert on or query with KQL.
   - **Data export and archival:** Export logs older than 30 days to Azure Storage (cool tier: ~$0.01/GB/month) via Data Export rules. Query archived logs with Azure Monitor Log Search using Long-Term Retention.

3. **Retention tiers and their use cases.**
   - **Interactive retention (Log Analytics):** 30–730 days. Full KQL query access. Cost: included up to 30 days, then ~$0.12/GB/month.
   - **Long-term retention (Log Analytics archive):** Up to 12 years. Queries via "Search Jobs" (async). Cost: ~$0.02/GB/month.
   - **Export to Storage:** Cheapest long-term storage. Cannot query in-place — must import or use external tools. Best for compliance archival where read access is rare.

4. **Security: log access governance.** Log Analytics Workspace stores sensitive operational data: request bodies (if logged), user identifiers, connection strings if accidentally logged, and IP addresses. Access must be governed with Azure RBAC. Roles: `Log Analytics Reader` (query only), `Log Analytics Contributor` (manage workspace). Application Insights data can be further restricted by workspace-level RBAC since workspace-based Application Insights (current default) stores data in Log Analytics.

5. **PII in logs is a compliance violation.** If your application logs request payloads and those payloads contain user email addresses, account numbers, or health data, Log Analytics becomes a regulated data store. Ensure application code uses structured logging with explicit field allowlists — never log raw request/response bodies in production.

6. **Diagnostic settings verbose modes.** Many Azure resources have log categories that generate enormous volume. Azure SQL "QueryStore" logs every executed query. Azure APIM "GatewayLogs" logs every API call with full headers. Enable only the log categories you actively alert on or investigate — not all categories for all resources.

## Micro exercise

**Scenario:**
> NovaBridge's observability setup (from Days 1–3) generates the following daily log volume:
> - App Service diagnostic logs: 8 GB/day
> - Azure SQL resource logs (all categories enabled): 22 GB/day
> - Application Insights telemetry: 6 GB/day
> - Azure APIM gateway logs: 14 GB/day
> - Total: 50 GB/day → ~$1,150/month at $2.30/GB
>
> Business requirements:
> - Alerting requires last 30 days of data queryable instantly.
> - Post-incident investigation occasionally needs data up to 90 days old.
> - Compliance (client contracts) requires 12 months of audit-relevant logs.
> - Finance target: monthly observability cost under $800/month.

Your answer must include:
- Redesign the log strategy: for each of the four log sources, decide which tier (Analytics, Basic, Archive, Storage export) and which retention period. Justify each decision.
- Calculate the estimated monthly cost of your redesigned strategy and show your math. You must hit the $800/month target.
- Identify the two SQL log categories that likely generate the 22 GB/day volume and explain which ones to disable without losing incident detection capability.
- Define an RBAC policy for Log Analytics access: which roles get which permissions, and what specific security risk are you preventing?

## Reflection question
The engineering team wants to log every HTTP request body for debugging purposes. The platform handles B2B transactions that include company names, invoice amounts, and internal cost center codes. What is your recommendation — and what technical control enforces it if a developer disagrees?

## Prior concept connection
Day 3 designed SLO alerts that depend on log data being available for query. Today's retention tiering must preserve the data that those alerts query (last 30 days in Analytics tier) while archiving the rest cheaply. If you archive alert-critical data to the Basic tier or Storage, your alert queries break — that is the direct dependency between Day 3 and Day 4.

## AI coach instructions
- Ask the learner to estimate the current cost before showing them the pricing math.
- If the learner enables the daily ingestion cap as the primary cost control, probe: "What happens to your Day 3 alerts when the cap is hit at 2 PM on the day of a major incident?"
- Watch for the mistake of disabling all SQL logs without identifying which categories are needed for alert queries. Log in `memory/mistakes.md`.
- Probe PII: "Does NovaBridge log request payloads? If yes, what regulation applies and what is the remediation?"
- Probe RBAC: "Your on-call developer needs to query logs at 2 AM during an incident. What role do they have, and do they have access to all workspaces or just the production workspace?"
- Update `memory/progress.md` with Week 06 Day 4 complete and note whether the learner independently identified the SQL log volume as the primary cost driver.

## Completion criteria
- Log tiering strategy designed for all four sources with tier, retention, and justification.
- Monthly cost calculated and shown to be under $800/month.
- Specific SQL log categories identified for disabling with impact analysis.
- RBAC policy defined with roles, scope, and security justification.
- AI reviewed with cloud architect, security, and cost optimizer perspectives.
