# Skill Matrix

Scores are tracked from 0 to 5.

## Score definitions

| Score | Label | What it means in practice |
|---|---|---|
| 0 | Not attempted | No exposure to this skill |
| 1 | Basic awareness | Can name the concept and give a one-sentence definition |
| 2 | Can explain | Can explain simple examples, knows the relevant Azure services |
| 3 | Can design with guidance | Can produce a design when coached; misses edge cases without prompting |
| 4 | Independent designer | Can design correctly under adversarial questioning; names trade-offs unprompted |
| 5 | Can defend and teach | Can defend every decision under pressure; can explain to a non-technical audience; can mentor others |

## Score unlocks

| Level reached | What it enables |
|---|---|
| 3 in any skill | Can propose that skill's architecture component in a workshop without pre-scaffolding |
| 4 in any skill | Can lead a review of that component for another learner or team member |
| 5 in any skill | Can mentor; can write an ADR and defend it in an architecture review board |

## Skills

| Skill | Starting Score | Target Score | Weeks that develop it |
|---|---:|---:|---|
| Requirements discovery | 0 | 5 | W1, W3, W10 |
| Azure service selection | 0 | 5 | W1–W12 (every week) |
| Networking design | 0 | 4 | W2, W7, W11 |
| Identity and access design | 0 | 4 | W3, W7 |
| Security and threat modeling | 0 | 4 | W3, W7, W9 |
| Data architecture | 0 | 4 | W4, W10 |
| Scalability design | 0 | 5 | W5, W10, W11 |
| Business continuity | 0 | 4 | W11 |
| Observability | 0 | 4 | W6, W8 |
| Bicep/IaC | 0 | 4 | W8 (primary), W1–W12 (workshops) |
| AI system design | 0 | 4 | W9 |
| Product thinking | 0 | 5 | W1, W3, W10, W12 |
| Executive communication | 0 | 4 | W5, W12 |
| Multi-cloud awareness | 0 | 3 | W2, W3, W7, W9 |
| Cost estimation | 0 | 4 | W4, W5, W8 |

## Skill progression checkpoints

The coach must explicitly state skill level changes at each `/run-weekly-review`.

Example output:
> "This week your **Networking design** score advanced from 2 → 3.
> Level 3 means you can design hub-spoke with guidance.
> To reach Level 4, you need to design network segmentation independently and explain NSG vs Firewall trade-offs under adversarial questioning. Week 7 (Security Architecture) will push this."

## Target profile by end of Week 12

A learner who completes all 12 weeks at passing quality should reach:
- 5/5 in: Requirements discovery, Azure service selection, Scalability design, Product thinking
- 4/5 in: Networking, Identity, Security, Data, Business continuity, Observability, Bicep/IaC, AI systems, Executive communication, Cost estimation
- 3/5 in: Multi-cloud awareness

This profile is sufficient for the AZ-305 exam and for senior architect interviews at most organizations.
