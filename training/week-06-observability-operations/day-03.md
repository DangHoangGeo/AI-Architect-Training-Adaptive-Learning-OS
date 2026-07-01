# Week 06 Day 3 — Design Exercise: SLOs, SLIs, Alerts, and Incident Response

## Goal
Design a complete SLO/SLI framework for NovaBridge's B2B SaaS platform, translate SLOs into actionable Azure Monitor alert rules, and define an incident response workflow that ensures the engineering team detects and acknowledges production issues before clients do.

## Why this matters
NovaBridge's 4-hour outage was not detected internally for 3 hours. The post-incident review found no SLO was defined — no one knew what "good" looked like, so no one noticed when the system went bad. Enterprise B2B clients have contractual SLAs. If NovaBridge cannot measure its own service level, it cannot honor those contracts or defend against SLA credit claims.

## Core concept

1. **SLI (Service Level Indicator) — what you measure.** An SLI is a specific metric that represents user experience. For an API platform: request success rate (non-5xx / total), p99 latency, and availability (health check passing). SLIs must be measurable with existing telemetry — if you cannot compute it from logs/metrics today, it is not an SLI yet.

2. **SLO (Service Level Objective) — the target.** An SLO is a target range for an SLI: "99.5% of requests must complete with HTTP 2xx within 2 seconds, measured over a rolling 28-day window." SLOs are internal targets; they are usually stricter than contractual SLAs to leave buffer. Client SLA: 99.0%. Internal SLO: 99.5%.

3. **Error budget — what you can afford to lose.** If your SLO is 99.5% over 28 days, your error budget is 0.5% × 28 days × 24h = 3.36 hours of downtime. When the error budget is 50% consumed in week 1, you freeze new feature deployments and focus on reliability. This transforms SLOs from monitoring vanity metrics into deployment governance.

4. **Alert on SLO burn rate, not just threshold.** A simple alert "error rate > 5%" fires for every blip. SLO burn rate alerting fires when you are consuming your error budget faster than sustainable. Google's "multiwindow, multi-burn-rate" approach: alert if burn rate over 1 hour is > 14x AND burn rate over 5 minutes is > 14x. This catches slow burns and fast burns differently.

5. **Azure Monitor alert types for SLOs.**
   - **Metric alert:** Fast, cheap, best for infrastructure metrics (CPU, latency percentiles). Fires on aggregated metric values.
   - **Log alert:** Slower (1–5 minute evaluation), more flexible, required for application-level SLIs computed from logs (e.g., error rate from App Insights requests table).
   - **Smart detection (Application Insights):** ML-based anomaly detection, no threshold to configure. Good as a backstop but not a replacement for explicit SLO alerts.

6. **Incident response workflow — the minimum viable process.**
   - Alert fires → Action Group sends notification (email, SMS, Teams webhook)
   - On-call engineer acknowledges within 5 minutes
   - If no acknowledgment in 5 minutes → escalate to secondary
   - Engineer opens investigation using runbook (covered Day 5)
   - Status page updated within 15 minutes of incident declaration
   - Client communication sent within 30 minutes if client-impacting

## Product framing (write this first)

> **User pain:** NovaBridge's enterprise clients manage production workflows on the platform. A 4-hour undetected outage caused three clients to manually re-run overnight batch processes, incurring internal costs. One client's head of operations has asked for "proof that NovaBridge monitors its own uptime."
>
> **MVP constraint:** The team has 2 weeks to implement observable SLOs before the next quarterly business review with clients. No new infrastructure — only Azure Monitor, Application Insights, and a Teams webhook they already have.
>
> **Success metric:** Mean Time to Detect (MTTD) below 5 minutes for any incident that would breach the 99.5% SLO; zero incidents reported by clients before internal detection for the next 90 days.

## Micro exercise

**Scenario:**
> NovaBridge's B2B SaaS API serves three tiers of clients:
> - **Platinum clients (8 clients):** Contractual SLA 99.9%, support response SLA 1 hour
> - **Gold clients (42 clients):** Contractual SLA 99.5%, support response SLA 4 hours
> - **Silver clients (70 clients):** Contractual SLA 99.0%, best-effort support
>
> The API has two critical endpoints: `POST /transactions` (payment processing, must be fast) and `GET /reports` (batch data export, latency-tolerant). The previous 4-hour outage affected all clients equally.

Your answer must include:
- Define two SLIs for the platform: one for the `/transactions` endpoint and one for the `/reports` endpoint. Include what metric, what source (App Insights table or Monitor metric), and what query computes it.
- Define the SLO for each SLI that satisfies the Platinum client contractual SLA with an internal buffer. Calculate the error budget in hours per 28-day period.
- Design the alert rule for each SLO: specify alert type (metric vs. log), evaluation window, threshold or burn rate, and Action Group target.
- Design the escalation ladder: who receives the first notification, what triggers escalation to the next level, and when is the incident declared as client-impacting (requiring a status page update).

## Reflection question
NovaBridge's engineering manager proposes setting the internal SLO equal to the client contractual SLA: "If we hit the SLO, we honor the contract — no need for a buffer." What is wrong with this reasoning — specifically, what happens during a partially-degraded incident where error rate hovers at exactly the SLO boundary for 6 hours?

## Prior concept connection
Days 1 and 2 built the telemetry infrastructure: Diagnostic Settings feeding Log Analytics, Application Insights tracking request and dependency telemetry. Today's SLOs and alerts sit on top of that foundation. You cannot define an SLI based on error rate if Application Insights is not collecting request telemetry — which is why Days 1 and 2 must come first.

## AI coach instructions
- Ask the learner to write the Product framing section before designing the SLOs.
- If the learner defines SLOs without distinguishing the two endpoints, probe: "Should `/reports` (latency-tolerant) have the same latency SLO as `/transactions`? What is the user impact of a slow report vs. a slow payment?"
- Watch for the mistake of setting SLO = contractual SLA with no buffer. Log in `memory/mistakes.md`.
- Probe error budget governance: "Your error budget for Platinum clients is consumed in 3 days. What do you do with the deployment pipeline?"
- Update `memory/progress.md` with Week 06 Day 3 complete and note whether the learner independently differentiated the two endpoint SLIs.

## Completion criteria
- Product framing section written before the design.
- Two SLIs defined with specific metric sources and KQL-like query descriptions.
- SLOs set with client SLA buffer and error budgets calculated in hours.
- Alert rules specified for each SLO with type, window, threshold, and action group.
- Escalation ladder defined with timelines.
- AI reviewed with cloud architect and product manager perspectives.
