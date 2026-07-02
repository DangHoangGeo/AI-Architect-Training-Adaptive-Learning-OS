# Architecture Decision Records — Enterprise AI Agent Platform

## ADR-001: Dedicated Tool-Broker Service enforcing authorization outside the LLM's control

### Status
Accepted

### Context
A red-teaming exercise showed that a crafted customer message could manipulate an agent's reasoning toward attempting an unauthorized action. Prompt instructions alone are not a reliable security boundary against a sufficiently motivated adversarial input.

### Options considered
- Option A: Grant each agent direct API credentials to backend systems, relying on system-prompt instructions and the model's own judgment to constrain what it does.
- Option B: Route every tool call through a dedicated Tool-Broker Service that independently enforces per-agent least-privilege permission scopes, regardless of what the agent's reasoning concludes it should do.

### Decision
Option B.

### Consequences
Positive: authorization is enforced by deterministic code outside the LLM's reach, so even a fully successful prompt injection cannot exceed the compromised agent's actual granted permissions. Negative: adds an architectural layer and latency to every tool call, and requires the platform team to maintain an explicit permission model per agent rather than letting agent capabilities grow organically through prompt changes.

### Review date
After any confirmed or attempted prompt-injection incident, and at minimum quarterly.

---

## ADR-002: Mandatory human approval for state-changing actions, not confidence-threshold-based autonomy

### Status
Accepted

### Context
The business wants to eventually expand agent autonomy, but LLM confidence scores are not a reliable proxy for correctness and are themselves manipulable via prompt injection.

### Options considered
- Option A: Allow agents to act autonomously above a tuned confidence threshold, escalating only low-confidence cases to a human.
- Option B: Treat human approval for any state-changing/financial action as a fixed policy boundary, independent of model confidence, until sustained audited evidence justifies changing that policy.

### Decision
Option B.

### Consequences
Positive: removes the "the model was very confident and very wrong" failure mode entirely for the highest-stakes actions, and keeps the autonomy boundary a deliberate, auditable business decision rather than an emergent property of a tunable threshold. Negative: slower path to full automation and ongoing human staffing cost for the approval queue, which the business must budget for as a deliberate trade-off against risk, not treat as a temporary inefficiency to optimize away quickly.

### Review date
At each planned autonomy-expansion milestone in the roadmap (V3), backed by audit data review.

---

## ADR-003: Defense-in-depth against prompt injection instead of a single filter

### Status
Accepted

### Context
Prompt injection is an actively evolving attack class with no single reliable, complete defense. The near-miss that triggered this project came from a technique a single content-safety filter did not catch.

### Options considered
- Option A: A single content-safety filtering layer at the input boundary.
- Option B: Layered defenses — input guardrail service, content-safety scanning, structural separation of customer content from system instructions in the prompt template, and independent tool-broker authorization as a final backstop regardless of what earlier layers miss.

### Decision
Option B.

### Consequences
Positive: no single bypass of any one layer translates directly into an unauthorized action, since the tool-broker (ADR-001) still independently enforces authorization even if an injection slips past the input filter; this significantly raises the bar for a successful end-to-end attack. Negative: more components to build, test, and keep current against new injection techniques, and no combination of layers can be claimed as a complete guarantee — this must be communicated honestly to risk/compliance as risk reduction, not risk elimination.

### Review date
Continuously, as new prompt-injection techniques are published in the field; formally reviewed quarterly.

---

## ADR-004: Hard per-conversation step and token budget enforced as a circuit breaker

### Status
Accepted

### Context
An agent stuck in a reasoning loop, whether from a bug or an adversarial input designed to induce one, can burn significant token spend before after-the-fact cost monitoring would catch it.

### Options considered
- Option A: Monitor per-agent token spend on a dashboard and alert if daily/weekly spend exceeds expected bounds.
- Option B: Enforce a hard per-conversation step-count and token budget in the Supervisor Agent itself, force-terminating and escalating to a human once the budget is hit.

### Decision
Option B, with Option A retained as a complementary aggregate-level monitoring practice.

### Consequences
Positive: bounds the worst-case cost and duration of any single conversation structurally, regardless of cause; also functions as a secondary safety mechanism since a conversation exceeding the budget is itself a signal something is wrong, worth routing to a human. Negative: a legitimately complex, multi-step customer interaction could hit the budget and be force-escalated even without any malicious or buggy cause, requiring the budget to be tuned carefully against real usage patterns to avoid excessive false escalations.

### Review date
Monthly for the first quarter post-launch, based on observed budget-exhaustion rate and cause analysis.
