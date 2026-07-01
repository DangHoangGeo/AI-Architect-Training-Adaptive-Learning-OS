# Week 12 Day 4 — Mock Interview Simulation: Defending Your Capstone Architecture

## Goal
Simulate a full 60-minute senior Azure architect technical interview where you present your portfolio and defend your design decisions under adversarial questioning. The AI coach plays three panel members: a Cloud Engineering Director, a CISO, and a Finance Director. You will answer questions in real time, without preparation time, and receive scored feedback at the end.

## Why this matters
Knowing an architecture and being able to defend it under pressure in a live interview are two different skills. The most common architect interview failure is not ignorance — it is losing composure when a panel member says "I disagree with this choice" or "why didn't you consider X?" and responding either by capitulating ("you're right, I should have done that") or becoming defensive ("no, my approach is correct"). Senior architects hold their position when they have a sound technical reason, concede gracefully when they do not, and pivot confidently when they discover a gap. This session trains that skill.

## Interview rules (the learner must follow these)
- Do not ask the AI coach "what do you think I should say?" before answering a question.
- Do not revise a previous answer after seeing the next question — answer each question as if live.
- Do not look at your portfolio documents while answering — treat it as a real interview.
- Each question must be answered within 3 minutes. If you are still going at 3 minutes, the panel interrupts.

## Interview structure

### Opening (5 minutes)
The learner delivers their 5-minute verbal hook from Week 12 Day 1 — the opening of their portfolio presentation. The panel listens without interruption.

### Technical deep-dive (20 minutes)
The panel asks questions about the three designs from Week 12 Day 2. Questions escalate in difficulty across three rounds: clarification, challenge, and adversarial.

**Round 1 — Clarification (the panel wants to understand):**
- "In your LexAI design, you said the vector store enforces per-tenant isolation using security trimming filters. Can you walk me through exactly how that filter is expressed in an Azure AI Search query?"
- "In your PeopleOS design, you set a per-database DTU cap of 200 for standard-tier tenants. How did you arrive at 200 specifically?"

**Round 2 — Challenge (the panel has a different view):**
- "I've seen Azure Cosmos DB used successfully for payment processing with strong consistency. Why are you so certain it cannot meet NovaPay's RPO = 0 requirement?"
- "Your LexAI architecture uses Azure Durable Functions for the human review gate. We tried Durable Functions in production and found the storage account dependency caused us 3 outages in 6 months. What is your response?"

**Round 3 — Adversarial (the panel is stress-testing judgment):**
- "Your PeopleOS onboarding pipeline has 14 steps. I count 3 Azure services that each have a published SLA of 99.9%. The probability that all three are available simultaneously is 99.9% × 99.9% × 99.9% = 99.7%. Over a year, that is 26 hours of expected downtime. How did you account for this in your design?"
- "You've designed three separate systems this quarter. Every one of them uses Azure Key Vault. Is that a pattern or a reflex? Tell me a scenario where Azure Key Vault is the wrong choice."

### AZ-305 rapid-fire (10 minutes)
Five rapid-fire questions in AZ-305 format. The learner must answer in under 60 seconds each.

1. A company needs to process financial transactions with RPO near zero in two Azure regions simultaneously. They cannot use Cosmos DB. Which Azure SQL feature and configuration achieves the closest possible RPO?
2. A startup needs to store 50TB of infrequently accessed cold data with the lowest possible cost. They need to restore data within 12 hours. Which storage tier and rehydration priority?
3. An enterprise customer requires that their encryption keys never leave an HSM that they control. Which Azure Key Vault tier, and what is the key management model called?
4. A SaaS platform needs to enforce rate limits of 100 requests/minute per tenant on all API calls without writing custom code. Which Azure service and which policy type?
5. A team needs to test their Azure infrastructure changes in a temporary environment that matches production exactly and is destroyed after the test. Which Azure service?

### Finance and security cross-examination (10 minutes)

**Finance Director asks:**
- "You've recommended an active-passive multi-region architecture for NovaPay at £28,000/month in standby infrastructure. The last outage cost £1.56M and occurred once in 3 years. The expected value of the outage risk is £520K/year. The DR infrastructure costs £336K/year. The math works. But what if the next outage is caused by a database schema bug — which your active-passive design does not protect against at all? Was the £336K well spent?"

**CISO asks:**
- "Across all three of your designs, you used Azure Active Directory / Entra ID for identity. You never mentioned what happens if Entra ID itself experiences an outage. How do your three systems behave when they cannot authenticate users, and what is your continuity plan for an Entra ID regional outage?"

### Closing (5 minutes)
The panel asks one final question — the hardest of the session: "If you were redesigning all three systems today with the benefit of everything you've learned this quarter, what is the one architectural pattern you would use consistently across all three that you did not use in any of them?"

## Scoring rubric (AI coach completes after the session)

| Category | Max Points | Description |
|---|---|---|
| Opening — impact and clarity | 10 | Did the hook communicate value within 60 seconds? |
| Technical accuracy | 25 | Were Azure service names, configurations, and constraints correct? |
| Decision defense quality | 20 | Did the learner hold positions with technical reasoning or capitulate without cause? |
| AZ-305 rapid-fire | 15 | Correct service + configuration within 60 seconds (3 pts each) |
| Cross-examination | 20 | Finance and security questions answered with honest trade-off acknowledgment? |
| Closing synthesis | 10 | Did the closing answer demonstrate genuine reflection vs. a safe non-answer? |
| **Total** | **100** | **Target: 75+** |

## Reflection question
After the session, the AI coach will reveal its score. Before seeing the score: write down your own score estimate and the two questions where you felt least confident. Compare to the AI coach's assessment. Where your self-assessment is significantly higher than the AI coach's score, that is the gap most likely to hurt you in a real interview.

## Prior concept connection
This session draws on everything from Weeks 1-11. The strongest performers will make explicit connections between questions — "as I mentioned in my NovaPay design, which also used Front Door..." Interviewers reward candidates who can cross-reference their own work rather than treating each design as isolated.

## AI coach instructions
Conduct the interview in character. Do not break character to give hints. Ask clarifying follow-ups if the learner gives a vague answer ("can you be more specific about which Azure service handles that?"). After the session, score against the rubric and record the result in `memory/progress.md`. The score becomes part of the final portfolio. Compare the learner's self-assessment to your score. If the gap is more than 15 points in either direction, update `memory/weak_areas.md` with "self-assessment calibration gap." For the rapid-fire section: acceptable answers for Q1 = Business Critical with zone redundancy + Failover Groups; Q2 = Archive tier, Standard rehydration; Q3 = HSM tier (Premium), Bring Your Own Key (BYOK); Q4 = Azure API Management, rate-limit-by-key policy; Q5 = Azure Deployment Environments.

## Completion criteria
- Learner completed all five interview phases without looking at portfolio documents.
- AI coach scored the session using the rubric.
- Score recorded in `memory/progress.md`.
- Learner completed the self-assessment before seeing the AI coach score.
- Any knowledge gaps from rapid-fire questions added to `memory/weak_areas.md`.
- Any mistakes added to `memory/mistakes.md`.
