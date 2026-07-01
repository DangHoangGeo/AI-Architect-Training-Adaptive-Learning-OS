# Week 12 Day 5 — Final Portfolio Review, AZ-305 Readiness Assessment, and Training Completion

## Goal
Finalize and polish the complete portfolio for real-world use, complete an AZ-305 readiness self-assessment to identify any remaining exam preparation gaps, record your architecture growth narrative, and close out the 12-week training with an honest capability statement that you can use verbatim in job applications and interview introductions.

## Why this matters
Twelve weeks of training has no value if it stays in this folder. The portfolio must exist in a shareable format, the AZ-305 must be scheduled, and the capability statement must be written before you talk to a recruiter. Architects who say "I've been doing a lot of Azure training" in interviews are forgotten. Architects who say "Over 12 weeks I designed a legal AI system on Azure that satisfies UK data residency requirements, a multi-tenant HR platform serving enterprise banks, and a payment processor with a 15-minute regulatory RTO — I can walk you through any of them in detail" are memorable. Today you write that sentence.

## Core concept

1. **A portfolio is a living document, not a one-time artifact.** After today, it needs a maintenance protocol: which sections to update after each new project, how to version it (use Git), and when to refresh it (before each job search, after each major architecture decision). A portfolio that is 2 years old when you next interview will show growth up to 2 years ago — which is not the impression you want.

2. **AZ-305 readiness has three dimensions.** Knowledge (do you know the Azure services?), judgment (can you select the right service for a given requirement?), and speed (can you work through a case study in the time allocated?). Twelve weeks of training has primarily built judgment and speed — which are the hardest dimensions to develop and the most valuable. Knowledge gaps identified in the mock interview must be addressed in the week before the exam.

3. **The capability statement is the most valuable single paragraph you will write.** It answers "tell me about yourself" in a technical interview. It must: name a specific problem domain you can architect for (not just "cloud systems"), name a specific constraint you can work under (compliance, cost, RTO), name a specific skill you have demonstrated (AZ-305 frameworks, multi-region design, RAG pipelines), and invite a specific question (to control the interview's direction).

4. **Portfolio gaps are expected and should be named.** No portfolio is complete. The areas where you know you are weakest — perhaps networking deep-dives, or IaC tooling beyond basic Bicep, or advanced Kubernetes — should be named explicitly in your portfolio introduction under "current learning focus." This demonstrates self-awareness and prevents interviewers from discovering gaps you have not acknowledged.

5. **The 12-week growth narrative is interview gold.** "I started this training not knowing how to structure a trade-off discussion" or "I consistently missed observability as an architectural concern until Week 9 Day 4 forced me to stress-test my own designs" — these statements, supported by specific examples from the portfolio, tell an interviewer that you learn from structured practice, which is exactly what they want in a senior hire.

6. **Scheduling AZ-305 is the commitment device.** The exam is not optional — it is the external validation that makes the portfolio credible. Book the exam within 2 weeks of completing this training. The Pearson VUE exam center or online proctored option is available in Japan. The exam costs ¥20,000-25,000. Do not delay.

## Learn — write notes answering these

- Looking at your `memory/weak_areas.md` file: which three areas appear most frequently? How does each one map to an AZ-305 exam domain, and what is your study plan for each in the week before the exam?
- What is the AZ-305 exam domain breakdown (name the four domains and their approximate weightings)? Which domain aligns most closely with your strongest training week, and which aligns with your weakest?
- How do you convert a portfolio document into a LinkedIn post format — what are the three elements that make a technical portfolio post perform well on LinkedIn?
- What is the difference between a "capability statement" (for interviews) and a "professional summary" (for a CV/resume) in the context of Azure architect roles in Japan?

## Final portfolio completion exercise

**This is not a scenario exercise. It is a real deliverable.**

Complete each of the following sections of your portfolio document. Each section must be written in full — no placeholders.

**Section 1: Architecture capability statement (150 words maximum)**
Write the paragraph you would say in response to "tell me about yourself" in a senior Azure architect interview. It must name: three specific problem domains you can architect for, two specific Azure constraint types you work under (regulatory, cost, or SLA), and one invitation for a specific question.

**Section 2: Training growth narrative (200 words maximum)**
Write an honest account of how your architectural thinking changed across 12 weeks. Name one specific assumption you held at Week 1 that Week 9, 10, or 11 proved wrong. Name one architectural pattern you now apply reflexively that you did not know existed at Week 1.

**Section 3: Current learning focus (50 words maximum)**
Name two architecture areas not covered in this training that are relevant to Azure architect roles and that you will study next. Be specific (not "learn more about networking" — "study Azure Virtual WAN hub-and-spoke topology and its cost model vs. traditional peering").

**Section 4: AZ-305 readiness assessment**
Score yourself 1-5 on each of the four AZ-305 domains:
- Design identity, governance, and monitoring solutions
- Design data storage solutions
- Design business continuity solutions
- Design infrastructure solutions

For any domain scored 3 or below: name one specific topic within that domain and one Microsoft Learn module that covers it.

**Section 5: Portfolio maintenance protocol**
Write three rules for maintaining this portfolio: when you update it, how you version it, and what triggers a full refresh.

## Reflection question (the final reflection of the training)
Looking back at all 12 weeks: which single architectural decision across any week produced the most learning? Not the most correct decision — the one that taught you the most about how to think. Write 3 sentences about it. This reflection will be the opening anecdote of your next architecture interview.

## Prior concept connection
Every prior week connects to this day. Before writing the capability statement, re-read your `memory/progress.md`, `memory/mistakes.md`, `memory/weak_areas.md`, and `memory/achievements.md`. The capability statement should be grounded in what these files actually show — not what you wish they showed.

## AI coach instructions
This is the final session. The learner must complete all five portfolio sections — not as draft but as final text. Evaluate the capability statement for: specificity (no generic statements), credibility (backed by portfolio content), and conversational naturalness (it must sound like something a real person would say). Evaluate the growth narrative for honesty — a narrative that claims no weaknesses or no changes in thinking is not credible. For the AZ-305 assessment: if any domain is rated 1 or 2, the learner should not schedule the exam within 2 weeks — recommend targeted study first. Run the final `/run-weekly-review` for Week 12. Update `memory/progress.md` with the final training completion status. Update `memory/achievements.md` with all portfolio artifacts completed. Update `memory/weak_areas.md` with final remaining gaps. Produce a final training summary: overall score across 12 weeks, three strongest capabilities demonstrated, three areas for continued development, and a recommendation on AZ-305 exam readiness.

## Completion criteria
- All five portfolio sections written in full (no placeholders).
- Capability statement is under 150 words and contains three problem domains.
- Growth narrative names a specific incorrect assumption corrected by training.
- AZ-305 readiness scored across all four domains with study plan for any domain <= 3.
- Portfolio maintenance protocol written with three specific rules.
- Final reflection written (3 sentences minimum).
- AI coach ran `/run-weekly-review` for Week 12.
- `memory/progress.md` updated with training completion.
- `memory/achievements.md` updated with portfolio completion.
- Final training summary produced by AI coach.
