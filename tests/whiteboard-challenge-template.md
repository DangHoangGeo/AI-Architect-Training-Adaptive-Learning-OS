# Whiteboard Challenge Test — Template

Use this format for weeks 2, 5, 8, and 11 instead of the standard written test.
This format simulates the whiteboard architecture round in technical interviews.

## Purpose
Assess whether the learner can produce an architecture under pressure, explain it clearly, and defend it against adversarial questioning — skills the standard written test does not measure.

## Instructions to learner
1. Read the scenario below.
2. Produce a written architecture description (treat it as a whiteboard sketch in text form).
   - Name all components.
   - Describe how data flows between them.
   - Identify trust boundaries.
   - Identify failure points.
3. After submitting your architecture, the AI will ask 3 adversarial questions. Answer each one.
4. Do not look at reference materials during the adversarial Q&A phase.

## Scoring (100 points)

| Area | Points |
|---|---|
| Architecture completeness (all key components present) | 20 |
| Data flow accuracy | 15 |
| Security: trust boundaries and access controls named | 15 |
| Failure scenario: at least one identified with mitigation | 15 |
| Azure service choices justified (not just listed) | 15 |
| Adversarial Q&A: defended with correct trade-offs | 20 |

Passing threshold: 75/100

## Week-specific scenario

*(Replace this section with the week-appropriate scenario when using this template.)*

**Week 2 example scenario:**
> A financial services company needs to connect 12 branch offices to a central Azure hub. Each branch runs a legacy Windows app that calls a shared internal API. The API must never be exposed to the internet. One branch has a large data transfer requirement (500 GB/day). Design the network architecture.

**Week 5 example scenario:**
> An e-commerce platform processes 500 orders/minute normally, but spikes to 8,000 orders/minute during flash sales. The checkout service sometimes fails under load and must not lose orders. Design the scalability and resilience architecture.

**Week 8 example scenario:**
> A platform team supports 6 product teams, each deploying to Azure. Each team has its own resource group but shares a central network, monitoring, and Key Vault. The platform team must enforce security baselines without blocking product team velocity. Design the IaC and DevOps delivery architecture.

**Week 11 example scenario:**
> A bank's core banking system has an RPO of 15 minutes and an RTO of 1 hour. It runs in East US. Design the business continuity architecture including what happens during an East US region outage.

## Adversarial question pool

The AI coach selects 3 questions from this pool based on the learner's submitted architecture:

- What happens to your design if [component X] fails completely?
- You said [service Y] handles [function Z]. What is its SLA and how does that affect your RTO?
- Your design puts [service A] and [service B] in the same subnet. Why not isolate them?
- What is the cheapest version of this design that still meets the stated requirements?
- A security team says [control] is insufficient. What would you add and what does it cost?
- How would you deploy a change to [component] with zero downtime?
- You chose [Azure service]. An AWS-first team pushes back. How do you defend the choice?
- If the load is 10x what you designed for, what breaks first?
- What monitoring would tell you this design is degrading before users notice?
- Where in this design does a compromised credential cause the most damage?

## Memory update required
After scoring:
- Update `memory/progress.md`
- Update `memory/mistakes.md`
- Update `memory/weak_areas.md` if patterns appear
- Update `memory/session_logs/YYYY-MM-DD.md`
