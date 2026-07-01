# Week 05 Day 5 — Communication and Refinement: Availability Targets and Dependency Failure

## Goal
Translate the TicketStream architecture from this week into a clear executive communication: define a composite availability target, identify the weakest availability link in the dependency chain, and produce a 5-bullet summary that a non-technical product VP can use to make an investment decision.

## Why this matters
An architect who cannot communicate availability risk to business stakeholders will have critical resilience investments rejected at budget review. If you cannot explain in one sentence why "99.9% uptime" for the checkout flow is actually 44 minutes of downtime per month — and that three consecutive 15-minute outages during on-sale events is a career event — the investment in circuit breakers, pre-scaling, and Redis redundancy will be cut.

## Core concept

1. **Composite availability math.** If three services are in the critical path and each has 99.9% availability, the composite availability is 0.999 × 0.999 × 0.999 = 99.7% — which is 2.6 hours of downtime per month, not 44 minutes. Architects must calculate and communicate the composite SLA, not just quote individual service SLAs.

2. **Azure SLA reference numbers (key ones to memorize).**
   - App Service (Standard+): 99.95%
   - Azure Cache for Redis (Standard with replica): 99.9%
   - Azure Service Bus (Standard): 99.9%
   - Azure Front Door: 99.99%
   - Azure SQL (General Purpose, zone-redundant): 99.99%
   - Stripe (external payment provider): not an Azure SLA — check their status page

3. **Dependency tiers: synchronous vs asynchronous.** Synchronous dependencies (e.g., Stripe payment on the checkout path) directly lower your composite SLA. Asynchronous dependencies (e.g., email confirmation via SendGrid) do not affect the checkout SLA if they are decoupled. Identify which dependencies are on the synchronous critical path and which are not.

4. **The "weakest link" rule.** Your composite SLA can never exceed the lowest SLA in your synchronous call chain. If Stripe's published availability is 99.95%, your checkout SLA is at most 99.95% even if every Azure service is 99.99%. This is the argument for payment queue buffering (Day 2): it moves payment from synchronous to asynchronous, removing Stripe from the critical path.

5. **Availability target vs reliability target.** Availability = uptime percentage. Reliability = probability that a transaction completes correctly when the system is up. A system can be "up" (returning HTTP 200) but failing 15% of payment charges due to a bug — that is a reliability problem, not an availability problem. Both need SLOs.

6. **On-sale event windows need event-specific SLAs.** A 99.9% monthly SLA means nothing to a fan who could not buy tickets in the 10-minute window when their preferred acts went on sale. Define an "event window SLA" separately: e.g., "99.99% availability during the 30-minute on-sale window" and design to that, not the monthly average.

## Micro exercise

**Scenario:**
> You are presenting the Week 5 TicketStream architecture to the VP of Product and the CFO before the next major on-sale event. They have three questions:
> 1. "What is our uptime commitment for the on-sale window?"
> 2. "Which single component failure would cause the biggest user impact?"
> 3. "We spent $40K this week on Redis, pre-scaling, and circuit breaker work. Was that worth it?"
>
> You must answer all three questions using the architecture built this week (stateless App Service + Redis session store + Service Bus queue + Front Door CDN + circuit breakers to Stripe).

Your answer must include:
- Calculate the composite SLA for the synchronous checkout path using realistic Azure SLA numbers. Show your math.
- Identify the single highest-risk dependency (hint: it is external to Azure) and explain what the architecture does to reduce its blast radius.
- Write the 5-bullet executive summary (no more than 2 lines per bullet) that answers the CFO's question about whether the investment was worth it. Use numbers wherever possible.
- State one remaining availability risk that was not fully addressed this week and what the next investment should be.

## 5-bullet executive summary format

Write exactly this structure:
- **What we built:** [one sentence]
- **What it protects against:** [the specific failure mode and the business consequence it avoids]
- **Measured improvement:** [composite SLA before vs after, or estimated downtime reduction]
- **Cost of the solution:** [ballpark monthly cost in USD]
- **Remaining risk and next step:** [the one thing still unresolved]

## Reflection question
A stakeholder says: "99.97% sounds great. That is basically always up." How do you reframe that number in terms they will understand — specifically for a platform where 80% of annual revenue comes from 12 on-sale event windows, each lasting 30 minutes?

## Prior concept connection
Days 1–4 this week built stateless scale, queue buffering, multi-layer caching, and circuit breakers. Today synthesizes those technical decisions into a business availability argument. The connection is direct: each of those patterns adds a decimal point to the composite SLA. If you cannot explain that chain, the architectural work cannot be defended in a budget meeting.

## AI coach instructions
- Ask the learner to write the 5-bullet summary before doing any calculation. Their natural language framing reveals how well they understand the business impact.
- If the learner gives an SLA number without showing the multiplication, ask them to show the math — it is a common AZ-305 exam question.
- Watch for the mistake of quoting individual component SLAs as the system SLA. Log in `memory/mistakes.md`.
- Probe: "Your CFO says the $40K investment saved the company money. What number would you use to prove that claim quantitatively?"
- Probe the event-window SLA concept: "Is a monthly SLA the right measure for a ticketing platform? What would a better measure look like?"
- Update `memory/progress.md` with Week 05 Day 5 complete and note whether the learner independently raised the external dependency (Stripe) as the weakest link.
- Update `memory/achievements.md` if the learner produced a clean 5-bullet executive summary.

## Completion criteria
- Composite SLA calculated correctly with math shown.
- External dependency (Stripe/payment provider) identified as highest-risk and its blast-radius reduction explained.
- 5-bullet executive summary written in the specified format with at least two numerical data points.
- One remaining risk identified with a concrete next investment.
- AI reviewed with cloud architect and product manager perspectives.
