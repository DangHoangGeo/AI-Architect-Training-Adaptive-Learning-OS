# Week 01 Day 4 — Trade-off analysis across cost, scale, security, reliability

## Goal
Develop a structured method for evaluating architecture decisions as trade-offs across at least four dimensions: cost, scalability, security, and reliability. Learn to make these trade-offs explicit rather than implicit.

## Why this matters
Every architecture decision is a trade-off. Architects who cannot articulate trade-offs make decisions that seem obvious until they fail. An architecture review board will always ask "why not the alternative?" — and "it was cheaper" or "it was simpler" are not complete answers.

## Core concept
The four primary trade-off axes for cloud architecture:

| Axis | Question it answers |
|---|---|
| **Cost** | What is the monthly/yearly spend? What happens to cost at 10x scale? |
| **Scalability** | Can the system handle more load without architectural change? Where does it break? |
| **Security** | What is the blast radius if this component is compromised? |
| **Reliability** | What is the expected uptime? What is the recovery time if this component fails? |

Additional axes that often appear in real decisions:
- **Operational complexity** — how hard is it to deploy, monitor, and debug?
- **Developer velocity** — how fast can the team ship features?
- **Compliance** — does this choice satisfy regulatory requirements?

A trade-off is not "I chose the best option." A trade-off is "I chose X, which gives me [benefit], at the cost of [downside], because [business reason] makes that trade acceptable."

## Learn — write notes answering these

- Name a real Azure service choice where improving reliability significantly increases cost, and explain the mechanism.
- Why is "most secure" not always the right security decision? Give an example where tightening security reduces developer velocity.
- A team chooses Azure Functions over App Service for cost reasons. What scalability assumption are they making, and when does it break?
- What is the relationship between reliability and operational complexity in a multi-region design?

## Micro exercise

**Scenario:**
> A media company streams live sports events. Each match draws 100,000 concurrent viewers for 2 hours, then drops to near zero. The next event may be 3 days later. The architecture team is debating between: (A) Azure Container Apps with scale-to-zero, or (B) a reserved AKS cluster with pre-scaled node pools.

Your answer must include:
- A trade-off table comparing Option A and Option B across: cost, scalability, reliability, and operational complexity.
- Your recommendation and the one deciding factor.
- The scenario in which your rejected option would have been the right choice.
- One NFR from the business context that you would need confirmed before finalizing the decision.

## Reflection question
A new engineer joins the team and asks "why didn't we just use the cheaper option?" What is your two-sentence answer?

## Prior concept connection
On Day 3, you wrote NFRs with specific measurable values. Today's trade-off framework is how you evaluate whether an architecture meets those NFRs. If your NFR says "99.9% availability," your trade-off table should show whether Option A or Option B achieves that, and at what cost.

## AI coach instructions
After the learner submits the trade-off table, ask: "Which cell in your table did you find hardest to fill in, and why?" This reveals where their analysis is shallow. If the trade-off table is missing operational complexity or has vague cells ("similar cost"), push back before scoring. Update memory if trade-off thinking is shallow.

## Completion criteria
- Learner produced a comparison table across at least 4 dimensions.
- AI reviewed it with architect and cost optimizer perspectives.
- Mistakes added to `memory/mistakes.md`.
- Progress updated.
