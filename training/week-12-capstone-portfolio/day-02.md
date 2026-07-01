# Week 12 Day 2 — Architecture storytelling: Building the Technical Deep-Dive Section

## Goal
Construct the technical deep-dive section of your portfolio by selecting your three strongest architectural designs from Weeks 1-11, writing an architecture story for each, and creating the visual and written artifacts that demonstrate production-grade thinking to a technical interviewer. Each story must cover decision, trade-off, and what you would change.

## Why this matters
Technical interviews for senior architect roles follow a predictable pattern: the interviewer picks an artifact from your portfolio and asks "walk me through why you made this decision." Architects who say "because it was the best option" or "because it scales" fail immediately. Architects who say "I chose Azure SQL Failover Groups over Cosmos DB because my RPO = 0 requirement had a write consistency constraint that Cosmos DB's multi-region write modes cannot fully satisfy at low latency — here is the trade-off I accepted" get the offer. The technical deep-dive section is where you demonstrate this level of reasoning.

## Core concept

1. **Architecture storytelling has four beats.** (1) The constraint that shaped the decision: the business requirement or technical limitation that eliminated most options. (2) The options considered: at least two real alternatives that were seriously evaluated. (3) The decision and its mechanism: exactly which Azure service, which tier, which configuration setting, and why. (4) The known compromise: what the chosen option does not do well, and how the architecture compensates.

2. **A "Rejected Alternative" section is as important as the "Chosen Solution" section.** Interviewers specifically probe rejected alternatives because they reveal whether you explored the space or went straight to the first answer. "I considered Azure Cosmos DB but rejected it because..." demonstrates search and judgment. "I didn't really consider anything else" is a failing answer at senior architect level.

3. **Architecture diagrams must tell a story, not just document topology.** A diagram with boxes and arrows explains what exists. A narrative diagram — with annotations like "this is the security boundary," "this is where cross-tenant data leakage would occur," "this queue absorbs burst load up to X messages" — explains why it exists this way. The written portfolio document must contain at least one annotated diagram description per deep-dive.

4. **Numbers make architecture stories credible.** "We process high transaction volume" is a story without evidence. "We process 8,000 transactions per minute at peak, requiring a PTU allocation of 50 for Azure OpenAI to meet the 3-second SLA" is a credible architectural claim. Every deep-dive story must contain at least two quantitative constraints that drove the design.

5. **The "I would change this" reflection demonstrates senior-level maturity.** Junior architects defend their work without acknowledging its weaknesses. Senior architects identify the known compromises they accepted and explain under what conditions they would revisit those choices. This is the difference between an architect who finished a project and one who learned from it.

6. **Cross-referencing between designs demonstrates system thinking.** Your LexAI design (Week 9) and your NovaPay design (Week 11) both use Azure Front Door. The fact that you used the same service for two different purposes — global AI API routing versus payment processor failover — and configured it differently for each — demonstrates breadth. Your portfolio should explicitly call out these cross-cutting patterns.

## Learn — write notes answering these

- How do you decide which three architectural designs from your 11 weeks to feature in the deep-dive section? What criteria differentiate a "showcase-worthy" design from a "technically correct but unremarkable" one?
- What is the "situation, complication, resolution" narrative structure from McKinsey's communication framework, and how does it map to the four-beat architecture story format?
- How do you describe an Azure architecture diagram in text for a portfolio document when you cannot include actual images — what conventions make text-based architecture descriptions readable?
- What is the difference between "I would change X" and "X was wrong" in a portfolio context — why does the framing matter, and what does each reveal about your professional maturity?

## Micro exercise

**Scenario:**
> You are writing the technical deep-dive section of your portfolio. You have selected three designs: (1) the LexAI AI contract review system from Week 9, (2) the PeopleOS multi-tenant HR platform from Week 10, (3) the NovaPay multi-region payment processor from Week 11. The panel's Cloud Engineering Director has 15 minutes to review the written section before the interview. The document must be readable in 15 minutes and leave the interviewer with at least three specific, challenging questions to ask during the 40-minute Q&A.

Your answer must include:
- For each of the three designs: a four-beat architecture story (constraint, options, decision, compromise) in approximately 200 words.
- For one design of your choice: an annotated architecture description naming at least 6 Azure services with their roles, configuration notes, and the security or reliability annotation for each connection.
- A "cross-cutting patterns" section (maximum 100 words) that identifies two architectural patterns used in multiple designs and explains what this demonstrates about your approach.
- Three "hard questions" the interviewer is likely to ask based on your designs, with your 30-second prepared answer for each.

## Reflection question
After writing the three architecture stories, you notice that every one of them has the same "known compromise": you accepted eventual consistency at the data layer to reduce cost or complexity. Is this a design pattern or a blind spot? How do you distinguish between a principled, recurring trade-off and a systematic gap in your architectural thinking?

## Prior concept connection
In Week 12 Day 1 you wrote your architecture philosophy statement. Each of the three architecture stories in today's exercise should connect back to that philosophy. If your philosophy claims you "prioritize operational simplicity," at least one story should show a moment where you chose simplicity over a more sophisticated option — and explain the consequence.

## AI coach instructions
The learner must write three four-beat stories — not one detailed story and two summaries. Evaluate each story for: presence of at least two quantitative constraints, a genuine rejected alternative (not a strawman), and an honest "known compromise" section. Watch for: (1) architecture stories that are just feature lists ("it uses Azure SQL, Front Door, and Key Vault"), (2) rejected alternatives that are not actually credible options (e.g., "I rejected running on-premises" — not a real comparison at this level), (3) "hard questions" that are easy to answer. Probe: "Your PeopleOS story says the compromise is 'operational complexity of managing 500 tenant databases.' A panel member asks: at what tenant count would you recommend migrating to a different architecture? What is your answer?" Update `memory/weak_areas.md` if the learner's stories lack quantitative constraints.

## Completion criteria
- Learner wrote three four-beat architecture stories of approximately 200 words each.
- Learner wrote an annotated architecture description for one design with 6 Azure services.
- Learner wrote a cross-cutting patterns section identifying two patterns across designs.
- Learner prepared three hard questions with 30-second answers.
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
