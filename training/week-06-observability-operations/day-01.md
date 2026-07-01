# Week 06 Day 1 — Concept Foundation: Azure Monitor and Log Analytics

## Goal
Understand how Azure Monitor and Log Analytics form the foundation of observability for a multi-service SaaS platform, learn the data model that underpins them (metrics vs. logs vs. traces), and diagnose why a team with no dashboards was the last to know about their own 4-hour outage.

## Why this matters
NovaBridge is a B2B SaaS platform serving 120 enterprise clients. On March 14th, the platform experienced a 4-hour degradation where API calls began returning HTTP 500 errors. NovaBridge's engineering team learned about the outage at hour 3 when a client's head of operations sent an angry email with screenshots. Three clients had already activated their incident escalation process with their own management. The team had logs — they were just not watching them. Azure Monitor was provisioned; no alerts were configured.

## Core concept

1. **Three pillars of observability: metrics, logs, traces.**
   - **Metrics:** Numeric time-series data (CPU %, requests/second, error rate). Fast to query, cheap to store, ideal for alerting thresholds. Source: Azure Monitor metrics.
   - **Logs:** Structured or unstructured text records of events. Rich context, slower to query, more expensive to store at scale. Source: Log Analytics Workspace.
   - **Traces:** End-to-end correlated records of a single request across multiple services. Required to debug distributed systems. Source: Application Insights (covered Day 2).
   You need all three. A metric alert fires; logs explain why; traces show where in the call chain it broke.

2. **Azure Monitor is the umbrella; Log Analytics is the query engine.** Azure Monitor collects and routes telemetry. Log Analytics Workspace is where logs land and where you write Kusto (KQL) queries to analyze them. They are separate resources but work together. Do not confuse "configuring Azure Monitor" with "having alerts" — they require separate setup.

3. **Diagnostic settings must be explicitly enabled.** By default, Azure resources do not send logs to Log Analytics. For each resource (App Service, SQL Database, API Management, Key Vault), you must create a Diagnostic Setting that routes log categories to a target workspace. A common mistake: the workspace exists but no diagnostic settings are configured, so the workspace is empty.

4. **KQL (Kusto Query Language) is the essential skill.** All Log Analytics queries use KQL. Core operators: `where`, `summarize`, `project`, `join`, `render`. A minimum viable KQL skill: filter by time range and error code, count by dimension, render as time chart. This is testable on AZ-305.

5. **Platform logs vs application logs.** Platform logs (Activity Log, Resource Logs) come from Azure services automatically once diagnostic settings are configured. Application logs come from your code — you must instrument your app to emit structured logs to Application Insights or directly to Log Analytics via the Azure Monitor SDK.

6. **Workspace design: centralized vs. per-workload.** A single workspace per environment (one for production, one for non-production) is the recommended baseline. Separate workspaces per application team creates a siloed view — you cannot correlate an App Service issue with a downstream SQL timeout if they are in different workspaces. Exceptions: regulatory data isolation, multi-tenant cost chargeback.

## Learn — write notes answering these

1. What is a Diagnostic Setting in Azure, and what happens if you do not configure one for an App Service that is experiencing errors?
2. Explain the difference between Azure Monitor metrics and Log Analytics logs. Which would you use to alert on "error rate above 5% for 3 consecutive minutes" and why?
3. NovaBridge had Azure Monitor provisioned but no alerts. What is the minimum set of resources that must be configured before an alert can fire? List the chain: resource → diagnostic setting → workspace → alert rule → action group.
4. Write a KQL query in pseudo-code that would detect the NovaBridge outage: show request count grouped by HTTP status code over 5-minute intervals for the last 6 hours.

## Micro exercise

**Scenario:**
> NovaBridge's post-incident review revealed that the 4-hour outage was caused by a SQL connection pool exhaustion. The App Service was running, returning HTTP 500 responses. No engineer saw any alert during the 4 hours. Existing infrastructure:
> - Azure App Service (3 instances, P2v3)
> - Azure SQL Database (General Purpose, 8 vCores)
> - Azure Key Vault (for secrets)
> - Log Analytics Workspace (provisioned, empty — no diagnostic settings configured)
>
> The CTO has given the team 1 week to implement a monitoring baseline so this never happens again.

Your answer must include:
- List every Diagnostic Setting that must be created (which resource sends which log categories to which workspace).
- Write the specific Azure Monitor metric alert that would have fired within the first 10 minutes of the outage (name the metric, resource type, threshold, and evaluation window).
- Describe the Action Group: who gets notified, by what channel, and what the escalation path looks like after 15 minutes of no acknowledgment.
- Identify one KQL query the on-call engineer should be able to run immediately on page — describe what it shows and why it directs them to the SQL connection pool issue.

## Reflection question
NovaBridge discovered the outage via a client email, not an alert. What does this reveal about the difference between "having monitoring infrastructure" and "operating a monitored system"? What organizational practice — beyond tooling — is required to close that gap?

## Prior concept connection
Week 5 focused on resilience patterns: circuit breakers, queues, and retry to prevent cascades. Observability is the complementary discipline: resilience prevents failures from spreading; observability ensures you detect failures within minutes, not hours. Without observability, you cannot validate that your Week 5 resilience patterns are actually working.

## AI coach instructions
- Ask the learner to diagnose the NovaBridge outage before explaining Azure Monitor. What was missing — tool, configuration, or process?
- If the learner jumps to "add Application Insights" without configuring Diagnostic Settings first, redirect: "The workspace is empty. Why is it empty even though Monitor is provisioned?"
- Watch for the mistake of treating a single alert on CPU as sufficient monitoring coverage. Log in `memory/mistakes.md`.
- Probe KQL: ask the learner to write at least one real query, even if syntax is imperfect.
- Update `memory/progress.md` with Week 06 Day 1 complete and note whether the learner independently identified the missing Diagnostic Settings as the root cause of the empty workspace.

## Completion criteria
- Diagnostic settings chain explained correctly (resource → workspace).
- Specific Azure Monitor metric alert defined with threshold and evaluation window.
- Action group escalation path described.
- KQL query described or written.
- AI reviewed with cloud architect and product manager perspectives.
