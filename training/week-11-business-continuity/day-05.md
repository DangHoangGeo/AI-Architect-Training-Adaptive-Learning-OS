# Week 11 Day 5 — Communication and refinement: Regional Failure Testing and Regulatory Reporting

## Goal
Produce the final communication artifacts for NovaPay's business continuity program: a DR test report suitable for regulatory submission, a non-technical executive summary of the multi-region architecture, and a continuous improvement plan for the resilience program. You will practice translating technical architecture into language that satisfies both regulators and executives.

## Why this matters
NovaPay's CTO has a board presentation in two weeks and a regulator submission deadline in three weeks. Both audiences need to understand the architecture — but they need completely different things. The board needs confidence that the investment is justified and the risk is managed. The regulator needs evidence-based proof that the 15-minute RTO is achievable and tested. Writing technically accurate but audience-inappropriate documentation is the architect's most common communication failure.

## Core concept

1. **A DR test report is a compliance artifact, not a technical document.** It must contain: test scope (what was tested), test date and participants, success criteria (RTO <= 15 min, RPO = 0), actual results (time per step, data loss measurement), deviations from expected behavior, remediation actions, and sign-off by the responsible officer. A report that says "we tested the failover and it worked" fails a regulatory review.

2. **Executive communication uses impact language, not service names.** "We deployed Azure Front Door with priority routing and configured Azure SQL Failover Groups with a 2-minute grace period" is not an executive sentence. "If our primary UK data center fails completely, payment processing will automatically resume in our backup European data center within 10 minutes, without anyone having to make a phone call" is.

3. **A resilience maturity model structures continuous improvement.** Level 1: manual failover, documented. Level 2: automated failover, untested. Level 3: automated failover, tested quarterly. Level 4: automated failover, tested monthly with chaos engineering. Level 5: continuous resilience validation with no scheduled maintenance windows. NovaPay is currently at Level 1 and needs to reach Level 3 in 90 days to satisfy the regulator.

4. **Post-incident reviews drive architecture improvements.** The 52-minute outage that triggered the regulator's warning was caused by a database update script. The post-incident review must answer: why was the script run in production without a backup? Why did it take 52 minutes to detect? Why did it take 52 minutes to restore? Each "why" reveals an architectural or process gap.

5. **The "game day" exercise is the highest-fidelity DR test.** A game day simulates a full regional failure during business hours with the entire engineering team available. It is different from an automated failover test — it exercises human decision-making, runbook accuracy, and communication protocols. The output is a list of "surprises" that become action items.

6. **Cost and risk communicate to different audiences differently.** For the board: "Our DR infrastructure costs £340K/year and protects us from a single outage that could cost £2.7M and a license suspension." For the regulator: "Our Recovery Time Objective of 15 minutes is supported by automated failover, quarterly tested procedures, and immutable audit logs." Both are true; neither is sufficient alone.

## Learn — write notes answering these

- What sections must a DR test report contain to satisfy a UK Financial Conduct Authority (FCA) supervisory review? What is the key difference between a "successful test" and a "compliant test result"?
- How do you measure RPO = 0 during a DR test for a payment processor — what specific data must you capture at the moment of failure and compare after recovery?
- What is an Azure Service Health alert, and how does it integrate into NovaPay's incident response — specifically, how does it trigger the automated DR runbook when Microsoft reports a regional service degradation?
- What is the "recovery narrative" technique for executive communication, and how does it make complex resilience architecture understandable to non-technical board members?

## Micro exercise

**Scenario:**
> NovaPay has successfully completed its first quarterly DR test after the new multi-region architecture was deployed. The test was conducted on a Tuesday at 10am. Results: failover trigger at T+0:00, database promotion completed at T+04:23, Front Door routing updated at T+06:11, application health check passed at T+08:47, first transaction processed in North Europe at T+09:14. One deviation: the application health check required a manual restart of 2 App Service instances because they did not receive the new database connection string from Key Vault within 60 seconds. Total RTO: 9 minutes 14 seconds. Zero transactions lost.

Your answer must include:
- A DR test report in the format required for regulatory submission — include all required sections and fill in the specific data from the test results above.
- An executive summary (maximum 200 words) for NovaPay's board, communicating the test outcome and its meaning without technical jargon.
- A root cause analysis for the App Service Key Vault delay deviation, and the architectural fix (one specific change to prevent this in the next test).
- A 90-day continuous improvement plan to advance NovaPay from resilience maturity Level 3 to Level 4, with specific milestones.

## Reflection question
The regulator reviews your DR test report and accepts the 9-minute RTO result. However, they ask one follow-up question: "Your test was conducted on a Tuesday at 10am with your full team available. Can you demonstrate that the same RTO is achievable at 2am on a Saturday with only one on-call engineer?" How do you respond, and what evidence can you offer?

## Prior concept connection
This day synthesizes all of Week 11. Your DR test report must reference the architecture designed in Days 3 and 4, the failover flow time estimates from Day 3, and the Front Door configuration improvements from Day 4. Before writing the report, check: does your actual test result (9:14) match the time estimates from your Day 3 failover flow? If not, reconcile the difference and update your flow.

## AI coach instructions
The learner must produce all four artifacts: DR test report, executive summary, root cause analysis, and improvement plan. Evaluate the DR test report for completeness (all sections present, all data filled in — not placeholder text). Evaluate the executive summary for audience-appropriateness (no Azure service names, impact language used). Watch for: (1) a root cause analysis that concludes "increase the timeout" without explaining why Key Vault was slow, (2) a 90-day plan that only has one activity, (3) an executive summary that is longer than 200 words. Probe: "Your executive summary says the system is resilient. A board member asks: what is the one thing that could still cause a 15-minute outage despite this architecture? What is your honest answer?" Update `memory/progress.md` with Week 11 completion and add a score. Update `memory/weak_areas.md` if the learner struggles with the regulatory report format.

## Completion criteria
- Learner produced a DR test report with all required sections containing specific data.
- Learner produced an executive summary under 200 words with no Azure service names.
- Learner provided a root cause analysis and a specific architectural fix for the Key Vault delay.
- Learner produced a 90-day improvement plan with specific milestones.
- AI reviewed with cloud architect, DevOps, and compliance perspectives.
- `memory/progress.md` updated with Week 11 completion status.
- Any mistakes added to `memory/mistakes.md`.
