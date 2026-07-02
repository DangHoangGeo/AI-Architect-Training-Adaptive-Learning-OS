# PM Brief — Enterprise AI Agent Platform

## Customer problem
Northwind's human-only support model has a 12-minute average resolution time and a 40-person overnight/weekend staffing gap, causing customer complaints and higher operating cost per interaction. A red-teaming exercise on the FNOL intake pilot also surfaced a real prompt-injection vulnerability where crafted customer input could push the agent toward attempting an unauthorized claim payout — the automation opportunity and the new risk surface arrived together.

## Target users
- **Primary:** Customers interacting via chat, email, or phone for policy questions, claims status, and FNOL intake.
- **Secondary:** Human claims agents who handle escalations and approve high-stakes actions the AI agents surface to them.
- **Operational:** AI platform team (prompt/agent engineering, evals), risk/compliance team, SRE.

## Value proposition
A multi-agent system that resolves routine policy and claims-status interactions autonomously, escalates FNOL and high-stakes actions to a human with full context, and closes the overnight staffing gap — while treating tool-calling authorization and prompt-injection defense as non-negotiable, bank-grade controls rather than best-effort mitigations.

## Success metrics
- 60% of policy Q&A and claims-status interactions resolved without human involvement within 6 months.
- Average resolution time for AI-handled interactions under 90 seconds.
- Zero unauthorized financial actions (claim approvals, payment changes) executed without human sign-off.
- Overnight/weekend coverage gap eliminated for policy Q&A and claims-status use cases.

## MVP scope
- Supervisor agent + two specialist agents (Policy Q&A via RAG, Claims Status via tool call) for the two lowest-risk, highest-volume use cases.
- Tool-broker service enforcing least-privilege tool access and mandatory human approval for any state-changing action.
- Prompt-injection defenses and content-safety filtering on all customer input before it reaches agent reasoning.
- Full immutable audit log of every agent decision, tool call, and human approval.

## Non-goals
- Fully autonomous claim payout approval (human approval remains mandatory for the foreseeable future — this is a policy decision, not just a technical limitation).
- FNOL intake automation in this phase (deferred to V2 after the injection-defense pattern is proven on lower-risk use cases).
- Voice-channel agent deployment (chat/email only in this phase; phone requires additional speech-to-text and latency work).

## Risks
- **Product risk:** Over-promising autonomy to the business before guardrails are proven could pressure the team to skip human-approval gates under deadline pressure — the roadmap explicitly sequences low-risk use cases first to prove the pattern before touching financial actions.
- **Technical risk:** Prompt injection defenses are an evolving field with no single "solved" solution; the design must assume defenses will need to keep evolving against new attack patterns, not be treated as a one-time control.
- **Delivery risk:** Eval suites for non-deterministic agent behavior are unfamiliar territory for a team used to deterministic software testing; underinvesting here risks shipping regressions that traditional QA wouldn't catch.
- **Adoption risk:** Human claims agents may distrust or override AI-agent recommendations without real evaluation if the handoff experience doesn't clearly show the AI agent's reasoning and tool-call history.

## Roadmap
- **V1:** Policy Q&A + Claims Status agents (read-only tool access), tool-broker, injection defenses, full audit logging.
- **V2:** FNOL Intake agent with mandatory human-approval gate for any payout-adjacent action; Escalation agent formalized.
- **V3:** Expand tool access incrementally (e.g., low-dollar-threshold automated approvals) only after sustained evidence from V1/V2 audit data justifies raising the autonomy ceiling.
