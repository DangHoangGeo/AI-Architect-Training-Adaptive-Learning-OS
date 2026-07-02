# Enterprise AI Agent Platform

## Real-world scenario

**Northwind Insurance** handles 15,000 customer interactions/day across chat, email, and phone for claims status, policy questions, and first-notice-of-loss (FNOL) intake, across auto, home, and health insurance lines. Human agents currently handle all of it, with average resolution time of 12 minutes and a 40-person overnight/weekend staffing gap that causes customer complaints.

Northwind wants to deploy a multi-agent AI system: a supervisor agent routes each conversation to specialist agents (Policy Q&A, Claims Status, FNOL Intake, Escalation), which call real backend tools (policy database, claims system, payment system) to actually resolve requests, not just answer questions. The pilot for FNOL intake already had a near-miss: a red-teaming exercise found that a crafted customer message could get the agent to attempt approving a claim payout by embedding fake "system instructions" in the claim description field — a live example of prompt injection turning into a real financial action.

This is the system that makes "AI architect" mean something different in 2026 than it did in 2020: **the reasoning engine itself is non-deterministic and adversarially attackable**, and the architecture has to compensate for that with the same rigor a bank applies to a ledger, not with a chatbot's error tolerance.

## Why this is architecturally hard

- **Prompt injection is a first-class threat, not an edge case.** Untrusted customer text flows directly into an LLM's context and can attempt to hijack the agent's tool-calling behavior — this is a new OWASP-recognized attack class with no equivalent in traditional web architecture.
- **Non-deterministic output at an enterprise reliability bar.** The same input can produce different agent behavior on different runs; the system needs evals, guardrails, and human oversight to compensate for what unit tests can't fully cover.
- **Runaway agent loops are a cost and safety risk, not just a bug.** An agent stuck reasoning in a loop burns real token spend and can repeatedly attempt the same disallowed action; the architecture must bound this structurally.
- **Tool access is where AI risk becomes real-world risk.** An agent that can only talk is low-risk; an agent that can call a payment API is a financial system, and needs the same authorization, least-privilege, and audit rigor as the Payment Gateway example in this collection.

## What's in this folder

- `pm_brief.md` — the business case for agent-based automation and where human-in-the-loop stays mandatory.
- `design.md` — supervisor/specialist multi-agent architecture, a tool-broker enforcing least-privilege and human-approval gates, prompt-injection defenses, and per-conversation cost/step budgets.
- `architecture_decisions.md` — why a tool-broker sits between agents and backend systems instead of direct tool access, why high-stakes actions require human approval regardless of model confidence, why prompt injection is defended in depth rather than with a single filter, and why every agent step is logged immutably.

## Related training weeks

Week 9 (AI System Design), Week 7 (Security Architecture), Week 3 (Identity & Governance).
