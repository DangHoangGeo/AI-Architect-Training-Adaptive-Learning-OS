# Week 11 Day 1 — Concept foundation: RTO, RPO, and Business Impact Analysis for Payment Processing

## Goal
Understand RTO (Recovery Time Objective) and RPO (Recovery Point Objective) as contractual and regulatory obligations — not just technical targets — and learn how to derive them from a Business Impact Analysis (BIA) for a payment processor operating under regulatory scrutiny. By the end of this session you can translate a regulator's "15-minute downtime" requirement into a specific architectural constraint at each layer of the stack.

## Why this matters
NovaPay is a national payment processor. Their regulator (the financial services authority) has issued a directive: any outage exceeding 15 minutes must be reported, and outages exceeding 60 minutes trigger a supervisory review that can result in license suspension. A developer who does not understand that "RTO = 15 minutes" means every layer of the stack — DNS failover, database promotion, application restart, health check — must complete in under 15 minutes will build a system that looks fine until the regulator calls.

## Core concept

1. **RTO is the maximum acceptable downtime from the moment an incident is declared.** For NovaPay, RTO = 15 minutes means the system must be serving transactions again within 15 minutes of a declared incident. This includes: automated failure detection (0-2 min), failover trigger (1-3 min), infrastructure promotion (3-8 min), application health check and traffic routing (8-13 min), and manual verification (13-15 min). If any one step exceeds its time budget, the RTO is breached.

2. **RPO is the maximum acceptable data loss.** For a payment processor, RPO is defined in transactions, not time. "RPO = 0" means no committed transaction can be lost under any failure scenario. "RPO = 30 seconds" means at most 30 seconds of transactions are acceptable to re-process. For NovaPay, the regulator requires RPO = 0 for all settled transactions.

3. **Business Impact Analysis (BIA) produces the numbers.** A BIA asks: "What is the financial cost of 1 minute, 5 minutes, 15 minutes, and 60 minutes of downtime?" For NovaPay: 1 minute = $45,000 in lost transaction fees; 15 minutes = $675,000 + regulatory report obligation; 60 minutes = $2.7M + supervisory review + potential license action. The BIA is why the CTO approves an active-active multi-region architecture that costs $800K/year — because 60 minutes of downtime costs more than 3 years of that infrastructure.

4. **Tier classification maps services to RTO/RPO requirements.** Not all components have the same criticality. Transaction processing: RTO 15 min, RPO 0. Merchant portal: RTO 4 hours, RPO 15 minutes. Analytics dashboard: RTO 24 hours, RPO 24 hours. This tiering avoids the mistake of designing everything for the most demanding requirement.

5. **RTO and RPO must be tested, not assumed.** A documented RTO of 15 minutes that has never been tested in production (or a near-production environment) is not an RTO — it is a guess. NovaPay must run quarterly failover drills that simulate a primary region failure and measure actual recovery time against the 15-minute target.

6. **The gap between RTO and MTTR is the design problem.** MTTR (Mean Time to Recovery) is what you currently achieve. RTO is what you must achieve. If your current MTTR is 45 minutes (one region goes down, team investigates, manually promotes a replica, updates DNS), your design has a 30-minute gap to close through automation.

## Learn — write notes answering these

- What is the difference between RTO and MTTR? If NovaPay's current MTTR is 45 minutes and their regulatory RTO is 15 minutes, what specific automation is required to close the 30-minute gap?
- Why is "RPO = 0" for payment transactions technically impossible with asynchronous database replication, and what Azure configuration is required to achieve synchronous replication?
- What is a Business Impact Analysis and who in the organization must sign off on the RTO/RPO values — why is this not a decision the architecture team makes alone?
- How does Azure Service Level Agreements (SLAs) relate to RTO? If Azure SQL Database has a 99.99% SLA, what is the maximum expected monthly downtime, and is that compatible with NovaPay's RTO?

## Micro exercise

**Scenario:**
> NovaPay processes 8,000 transactions per minute during peak hours (9am-6pm weekdays). Their current architecture runs in a single Azure region (UK South) with an Azure SQL Database (Business Critical tier) and two App Service instances behind an Azure Load Balancer. Last month, a database update script ran incorrectly and took the system down for 52 minutes. The financial services authority has written a formal warning letter requiring NovaPay to demonstrate compliance with a 15-minute RTO within 90 days.

Your answer must include:
- A BIA summary: financial impact of 15 minutes of downtime for NovaPay at 8,000 transactions/minute (assume average transaction value of £42 and NovaPay's fee is 0.3%).
- A tier classification for NovaPay's four systems: transaction processing, merchant portal, settlement reporting, analytics dashboard — with an RTO and RPO for each, justified.
- The specific gap between NovaPay's current single-region architecture and the 15-minute RTO requirement — name each component that would cause a failover delay.
- The one highest-priority architectural change that closes the most significant gap (do not design the full solution — that is Day 3).

## Reflection question
The regulatory letter requires a 15-minute RTO. Your BIA shows that a multi-region active-active architecture to achieve this RTO costs £1.2M per year. NovaPay's annual revenue is £18M. The CFO says "prove the investment is justified." Write a 3-sentence business case using numbers from the BIA.

## Prior concept connection
In Week 5 you studied Azure SQL Database tiers and replication. Today you need to state specifically: does Azure SQL Database Business Critical tier provide synchronous or asynchronous replication to its secondary replicas, and what is the implication for NovaPay's RPO = 0 requirement?

## AI coach instructions
Ask the learner to compute the BIA numbers before designing anything. Watch for: (1) treating RTO and MTTR as synonyms, (2) assigning RTO 15 minutes to all systems including analytics (tier classification is required), (3) proposing "add a second region" without naming which components within a single-region failover are already slow. Probe: "Your current architecture takes 52 minutes to recover. Walk me through each minute from failure detection to transaction processing resuming, and identify which specific step took the longest." Update `memory/weak_areas.md` if the learner cannot state the current single-region failure mode.

## Completion criteria
- Learner computed the BIA financial impact with correct arithmetic.
- Learner produced a four-tier classification with RTO and RPO values and justifications.
- Learner named specific architectural components that cause failover delays in the current single-region design.
- Learner identified the single highest-priority architectural change.
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
