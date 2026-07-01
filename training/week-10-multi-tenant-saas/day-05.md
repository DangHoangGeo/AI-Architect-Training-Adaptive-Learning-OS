# Week 10 Day 5 — Communication and refinement: SaaS Governance, Billing Signals, and Tenant Health Reporting

## Goal
Design PeopleOS's SaaS governance layer — the operational systems that give the PeopleOS team visibility into tenant health, consumption, billing signals, and churn risk. You will produce a tenant health dashboard specification and a billing architecture that connects Azure cost data to customer invoices.

## Why this matters
PeopleOS's CFO asks: "Which tenants are growing, which are shrinking, and which are likely to churn in the next 90 days?" Without usage telemetry and billing signals, the only answer is "I don't know." A SaaS platform with no governance layer operates blind. When a tenant cancels, you discover the reason was that they had been hitting API throttle limits every day for three months — a fact that was never surfaced to the customer success team. Governance data is not a reporting feature; it is the early warning system that keeps customers.

## Core concept

1. **Billing signals are usage metrics that map to revenue.** For PeopleOS: active employee count (the billing unit), API call volume, storage consumed, features enabled, and integration usage. These must be metered in real-time and written to a billing event store. Azure Event Hubs with a 90-day retention policy is the correct pipeline for high-volume billing events.

2. **Azure Cost Management is for internal cost attribution, not customer billing.** The distinction matters: Azure Cost Management tells PeopleOS how much it costs to run each tenant. The billing system tells the tenant how much to charge them. The connection between these two is the margin calculation — what PeopleOS charges minus what it costs to serve.

3. **A tenant health score aggregates multiple signals into one actionable number.** Example signals: API error rate in the last 7 days, daily active user trend (growing or shrinking), feature adoption rate, support ticket volume, last login date of admin users. A tenant with a declining DAU trend, rising error rate, and no admin login in 14 days is a churn risk — regardless of whether they are paying their invoices.

4. **Azure Monitor Workbooks can serve as internal tenant health dashboards.** They query Log Analytics, Application Insights, and Azure Cost Management in a single view. Each row represents a tenant, with columns for health signals. Thresholds are color-coded (green/amber/red). Customer Success teams use this to prioritize outreach.

5. **Usage-based billing (metered SaaS) requires an idempotent billing event pipeline.** If a billing event is processed twice, the customer is double-charged. The billing event store must use a deduplication key (event ID + tenant ID + billing period) and the downstream invoice generation must be idempotent. Azure Service Bus with duplicate detection provides this guarantee.

6. **Governance includes the ability to suspend, downgrade, and offboard tenants.** When a tenant fails to pay, the platform must be able to suspend their access without deleting their data (legal hold), downgrade their tier without data loss, and eventually offboard them with a complete data export. Each of these operations must be a tested, automated workflow — not a manual procedure.

## Learn — write notes answering these

- What is the difference between Azure Monitor metrics (time-series), Azure Monitor logs (query-based), and Azure Event Hubs (streaming)? Which does PeopleOS use for real-time billing event ingestion?
- How does the Azure Marketplace SaaS billing model work, and when would PeopleOS use it instead of building their own billing pipeline?
- What is a "feature flag" in the context of SaaS governance, and how does Azure App Configuration's feature management capability enforce tenant-tier access control without code deployments?
- How do you calculate the "margin per tenant" using Azure Cost Management tag-based cost data combined with the billing system's revenue data?

## Micro exercise

**Scenario:**
> PeopleOS has 47 active tenants. The Customer Success team has noticed that three tenants who renewed their contracts 6 months ago have dramatically reduced their usage: `nordic-retail-as` (DAU dropped 60%), `iberian-logistics-sl` (last admin login 32 days ago), `balkans-pharma-doo` (API error rate averaging 12% for the past 3 weeks). None of these tenants have filed a support ticket or indicated dissatisfaction. The CEO asks: "How did we not know this was happening?"

Your answer must include:
- The specific metrics and data sources that PeopleOS should have been monitoring to detect these three signals early, naming the Azure service and the specific metric or log query for each.
- A tenant health score formula — describe the inputs, their weights, and the thresholds that classify a tenant as "healthy," "at risk," or "critical."
- A governance workflow triggered when a tenant is classified as "critical" — what automated actions run, what human actions are required, and what the SLA is for the Customer Success team to respond.
- A billing architecture diagram (described in text): how does a "payroll run" event in the application become a line item on the customer's monthly invoice?

## Reflection question
`Nordic-retail-as` is classified as "critical" by your health score. The Customer Success team reaches out and discovers that the tenant's HR director left the company 5 weeks ago and no one has been assigned to manage PeopleOS. The platform is technically running but no one is actively using it. What does this mean for their renewal probability, and what is the product implication — should PeopleOS have an "unattended tenant" detection feature, and who should it notify?

## Prior concept connection
In Week 10 Day 4 you designed per-tenant throttling. Today you are building the governance visibility layer on top of that. The throttle events (HTTP 429s from APIM) are a billing signal: a tenant that hits their throttle limit 50 times per day is a candidate for an upgrade conversation. Explain how you would surface APIM throttle events in the tenant health dashboard.

## AI coach instructions
The learner must produce both a health score formula and a billing pipeline description. Do not accept vague descriptions. Watch for: (1) using Azure Cost Management as the billing system for customers (wrong — it is internal cost tracking), (2) a health score with only one signal (e.g., "just track DAU"), (3) no idempotency guarantee in the billing pipeline. Probe: "Your billing pipeline processes 10,000 events per day. At month-end, Azure Event Hubs experiences a 15-minute outage. How do you ensure no billing events are lost or double-counted after the service recovers?" Update `memory/progress.md` with Week 10 completion and add a score. Update `memory/weak_areas.md` if the learner cannot distinguish internal cost tracking from customer billing.

## Completion criteria
- Learner identified specific Azure metrics and log queries for each of the three churn signals.
- Learner defined a tenant health score with named inputs, weights, and thresholds.
- Learner described a governance workflow with automated and human steps and an SLA.
- Learner described a billing pipeline from application event to customer invoice with idempotency.
- AI reviewed with cloud architect, product manager, and cost optimizer perspectives.
- `memory/progress.md` updated with Week 10 completion status.
- Any mistakes added to `memory/mistakes.md`.
