# Week 06 Day 5 — Communication and Refinement: Operational Runbooks

## Goal
Synthesize the NovaBridge observability architecture from Days 1–4 into operational runbooks and a 5-bullet executive summary that demonstrates the platform is now monitored, not just instrumented. Understand how runbooks connect alerts to actions and why their absence extends incident duration.

## Why this matters
NovaBridge's 4-hour outage had a 3-hour detection gap and a 1-hour resolution gap. Even if Days 1–4's work closes the detection gap to under 5 minutes, an on-call engineer woken at 2 AM without a runbook will take 45 minutes to diagnose what a runbook makes a 5-minute procedure. The reduction in Mean Time to Resolve (MTTR) is the direct business value of operational runbooks.

## Core concept

1. **A runbook is a decision tree for an on-call engineer.** It starts from the alert that fired and leads to: (a) diagnostic steps (which queries, which dashboards, what to look for), (b) remediation actions (which buttons to press, which commands to run), and (c) escalation criteria (when to wake up the DBA vs. when to wake up the VP of Engineering). A runbook that says "investigate the logs" is not a runbook.

2. **Runbook types.**
   - **Diagnostic runbook:** Tells the on-call engineer how to confirm the scope and root cause of an incident. Uses specific KQL queries, dashboard links, and expected output descriptions.
   - **Remediation runbook:** Step-by-step recovery actions. For SQL connection pool exhaustion: step 1 — identify top connection-consuming queries; step 2 — kill runaway connections; step 3 — restart App Service to reset connection pool; step 4 — verify alert clears within 5 minutes.
   - **Communication runbook:** What to post on the status page, when to send client emails, and what to say. Template-based to avoid writing under pressure.

3. **Runbooks must reference live queries.** A runbook that says "check Application Insights" is not actionable. A runbook that embeds the KQL query to paste into Log Analytics is actionable. Store runbooks in the team's wiki (e.g., Confluence, Azure DevOps Wiki) with links to saved queries in Log Analytics.

4. **Azure Automation for self-healing runbooks.** Some remediation actions can be automated: an Azure Automation Runbook triggered by an alert Action Group can restart an App Service, scale out a Container Apps environment, or flush a Redis cache. This converts human response time (15 min) to automated response time (30 seconds). Requires careful testing — automation that acts incorrectly under ambiguous conditions causes more damage than human judgment.

5. **Post-incident review (PIR) is the runbook improvement loop.** After every incident: update the runbook with what worked, remove steps that were useless, add the diagnostic step that took the longest to figure out. A runbook that is never updated after incidents is stale within 6 months.

6. **Communicating observability status to stakeholders.** Enterprise clients want proof that the platform is monitored. A monthly "operational health report" showing SLO achievement rate, number of incidents, MTTD, and MTTR is a client-retention asset. It also forces the team to review their own observability posture monthly.

## Micro exercise

**Scenario:**
> NovaBridge's new alert fires: "SQL connection pool usage > 85% for 5 consecutive minutes." An on-call engineer is paged at 3:47 AM. They have never handled this alert before. NovaBridge has no existing runbooks. The engineer opens the Azure portal.
>
> The alert is for the exact same failure mode as the 4-hour outage — but now it fires 10 minutes into the degradation instead of 4 hours in.
>
> Your task: write the runbook for this alert.

Your answer must include:
- Write a diagnostic runbook section: list exactly 3 KQL queries (in plain English or pseudocode) the engineer should run, in order, to confirm scope and identify the root cause. State what the expected output of each query looks like.
- Write a remediation runbook section: list step-by-step actions for the two most common root causes of SQL connection pool exhaustion (long-running queries and connection leak in application code). Each step must be a specific Azure action (portal, CLI, or query).
- Write the client communication template for a Platinum client SLA breach: subject line, 3-sentence body, what information to include and what not to include.
- Write the 5-bullet executive summary for the NovaBridge CTO, covering the full Week 6 observability investment.

## 5-bullet executive summary format

Write exactly this structure:
- **Problem we solved:** [what the 4-hour outage revealed — specific and quantified]
- **What we built:** [the observability stack in one sentence, no jargon]
- **How it changes incident response:** [MTTD before vs. after, MTTR before vs. after]
- **Cost and trade-offs:** [monthly cost of observability, what was descoped to hit budget]
- **What clients see differently:** [the external-facing proof point — status page, monthly report, or SLA report]

## Reflection question
The on-call engineer follows the runbook exactly, restarts the App Service, and the alert clears — but 40 minutes later the alert fires again. The runbook's remediation was "treat the symptom," not "fix the root cause." What governance practice ensures runbooks evolve from symptom-treatment to root-cause-prevention?

## Prior concept connection
The entire Week 6 arc — Diagnostic Settings (Day 1), Application Insights tracing (Day 2), SLO alerts (Day 3), retention cost governance (Day 4) — all feed into the runbook. A runbook is only as good as the observability data it references. The SQL connection alert (Day 3) fires; the KQL query in the runbook (today) uses the Application Insights dependency table (Day 2) stored in Log Analytics (Day 1) at the correct retention tier (Day 4).

## AI coach instructions
- Ask the learner to write the diagnostic runbook queries before the remediation steps. The quality of the queries reveals whether they understand the data model from Days 1–2.
- If the learner's remediation runbook says "restart App Service" as the only step, probe: "What if the connection leak is caused by a code bug? Restarting buys 30 minutes — what is the next step?"
- Watch for the mistake of a client communication that reveals too much technical detail (e.g., "our SQL database connection pool was exhausted"). Log in `memory/mistakes.md`.
- Probe the 5-bullet summary: "You said MTTD went from 4 hours to 5 minutes. Can you prove that with a number from the new alert configuration?"
- Update `memory/progress.md` with Week 06 Day 5 complete.
- Update `memory/achievements.md` if the learner produced a complete runbook and client communication template.

## Completion criteria
- Diagnostic runbook with 3 specific KQL queries described.
- Remediation runbook with step-by-step actions for two root cause scenarios.
- Client communication template written for a Platinum client SLA event.
- 5-bullet executive summary in the specified format.
- AI reviewed with cloud architect and product manager perspectives.
