# Week 11 Day 3 — Design exercise: Active-Active vs Active-Passive Multi-Region Architecture

## Goal
Design NovaPay's multi-region architecture, choosing between active-active and active-passive patterns, and produce a complete architecture decision record with cost, complexity, and RTO implications of each. You will make and defend a specific recommendation suitable for presentation to NovaPay's board.

## Why this matters
Active-active and active-passive are not just topology choices — they are business decisions with fundamentally different cost structures, operational complexity, and RTO outcomes. An active-passive design for NovaPay costs £400K/year less than active-active but delivers an RTO of 8-12 minutes versus 30 seconds. Whether that 8-minute gap is acceptable depends on the regulator's interpretation of "15 minutes." Designing without understanding this trade-off will produce a system that either overspends by £400K/year or fails an audit.

## Product framing (write this first)
> **User pain:** NovaPay's 52-minute outage last month directly cost £1.56M in lost transaction fees and triggered a regulatory warning letter. The board needs assurance that a future regional outage will not repeat the same outcome.
> **MVP constraint:** The new multi-region architecture must achieve RTO <= 15 minutes with zero manual intervention, using existing operational headcount (no new site reliability engineers can be hired for this project).
> **Success metric:** In the next quarterly DR drill, automatic failover to the secondary region completes in under 10 minutes with zero transactions lost from the moment the failover is triggered.

## Core concept

1. **Active-active: both regions serve live traffic simultaneously.** Transactions are processed in both UK South and North Europe. If one region fails, Front Door health probes detect the failure in 30-60 seconds and route all traffic to the healthy region. Users experience a brief latency increase, not an outage. The challenge: the database layer must handle concurrent writes from two regions, which requires a globally distributed, multi-write capable store (Azure Cosmos DB) or careful sharding by geography.

2. **Active-passive: the secondary region is provisioned but receives no live traffic.** All traffic goes to UK South. The North Europe secondary is kept warm (infrastructure deployed, database replica current) but idle. On failover, Front Door or Traffic Manager routes traffic to North Europe. The database Failover Group promotes the secondary. RTO depends on how quickly traffic routing and database promotion complete — typically 5-15 minutes.

3. **The database layer is the hardest part of active-active.** For payment processing with RPO = 0: Azure SQL's geo-secondary is asynchronously replicated — writes to UK South are not instantly visible in North Europe. To accept writes in both regions simultaneously, NovaPay would need Azure Cosmos DB with multi-region writes (strong consistency is not available globally at low latency — this is a CAP theorem problem). Most payment processors choose active-passive for this reason.

4. **Azure Front Door Premium is the correct global routing layer** for both patterns. It provides: global anycast routing, sub-30-second health probe failure detection, priority-based routing (active-passive) or weighted routing (active-active), WAF integration, and DDoS protection. Azure Traffic Manager is DNS-based and has TTL-dependent failover that can take 1-2 minutes — potentially not fast enough for NovaPay.

5. **Stateless application tier enables active-active more easily than the data tier.** NovaPay's App Service tier can run active-active today because application instances are stateless — no session state is stored locally. The blocking issue is the database layer. A hybrid pattern — active-active for the application and API tiers, active-passive for the database with a 5-minute failover — is a common practical compromise.

6. **Runbook automation replaces manual DR procedures.** In an active-passive pattern, the failover procedure must be a fully automated runbook (Azure Automation or Azure DevOps pipeline) that: detects the failure, triggers database failover group promotion, updates any DNS overrides, validates application health in the secondary region, and pages the on-call engineer to confirm. No manual steps during the 15-minute window.

## Learn — write notes answering these

- What is "split-brain" in a distributed database context, and why is it the critical risk in active-active multi-region architectures for payment processing?
- Azure Front Door uses anycast routing while Azure Traffic Manager uses DNS-based routing. What is the practical difference in failover time, and which matters more for NovaPay's 15-minute RTO?
- What is Azure Cosmos DB "multi-region writes" with "bounded staleness" consistency, and would it satisfy NovaPay's RPO = 0 requirement? Explain why or why not.
- What is the cost model difference between active-active (two fully loaded regions) and active-passive (one loaded region + one warm standby)? Estimate as a percentage of total infrastructure cost.

## Micro exercise

**Scenario:**
> NovaPay's board has approved investment in a multi-region architecture. The CTO has asked for an Architecture Decision Record (ADR) recommending either active-active or active-passive for their transaction processing system. The constraints are: RTO <= 15 minutes (hard regulatory requirement), RPO = 0 for settled transactions (hard regulatory requirement), no budget for a third region, operational team of 6 engineers (no 24x7 NOC, on-call rotation), and the existing payment processing logic uses Azure SQL Business Critical with no plans to migrate to Cosmos DB.

Your answer must include:
- An ADR with: Context, Options Considered (active-active, active-passive, warm standby), Decision, Rationale, and Consequences (positive and negative).
- A component-level architecture for your chosen pattern: name every Azure service in both regions, the routing layer, and the database replication configuration.
- A failover flow: numbered steps from "UK South becomes unavailable" to "transactions processing in North Europe," with estimated time for each step and cumulative total.
- The monitoring configuration that detects the UK South failure and triggers the automated failover runbook — name the Azure services and the specific health check configuration.

## Reflection question
Your active-passive design passes the regulator's 15-minute RTO test in quarterly drills. But the drill is conducted at 10am on a Tuesday with the full team available. Your real incident occurs at 2:47am on a Sunday. The on-call engineer is asleep. What parts of your architecture depend on a human being awake and responsive — and how do you eliminate those dependencies?

## Prior concept connection
In Week 11 Day 2 you mapped backup and DR services per component. Today you are assembling those components into a complete multi-region design. Your Day 2 service selection table should map directly to the architecture diagram you produce today. If any component was missing from Day 2, add it now and explain why it was missed.

## AI coach instructions
The learner must write the Product framing section before the ADR. Ensure the ADR contains all five sections. Watch for: (1) recommending active-active without addressing the multi-write database problem, (2) using Traffic Manager instead of Front Door and not acknowledging the DNS TTL failover delay, (3) a failover flow that totals more than 15 minutes, (4) human steps in the failover flow without automation alternatives. Probe: "Your failover flow shows 'DBA promotes database failover group' as a manual step taking 3 minutes. Is this manual step eliminable, and if so, what is the risk of fully automating database promotion?" Update `memory/weak_areas.md` if the learner cannot explain the split-brain risk.

## Completion criteria
- Learner wrote Product framing before the ADR.
- Learner produced a complete ADR with all five sections and at least three options considered.
- Learner produced a component-level architecture naming all Azure services in both regions.
- Learner produced a failover flow with time estimates that total <= 15 minutes.
- AI reviewed with cloud architect, DevOps, and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
