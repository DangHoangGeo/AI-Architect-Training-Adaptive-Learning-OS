# Week 11 Day 4 — Failure, security, and cost review: Global Routing, Failover Automation, and DR Audit Evidence

## Goal
Stress-test NovaPay's multi-region architecture by simulating three distinct failure scenarios, reviewing the global routing configuration for security and cost misconfigurations, and producing the specific audit evidence artifacts that the regulator requires to confirm compliance with the 15-minute RTO mandate.

## Why this matters
NovaPay passes their quarterly DR drill on a Tuesday morning. Three months later, the regulator schedules an unannounced audit. They ask for: the last 12 months of DR test results, evidence that automatic failover occurs without human intervention, network diagrams showing no single point of failure, and cost justification for the DR infrastructure. If the architecture has never been tested under realistic failure conditions (not just "shut down a VM"), or if the audit evidence was never captured, NovaPay fails the audit despite having a technically sound architecture.

## Core concept

1. **Azure Front Door health probes must be tuned, not left at defaults.** Default health probe: interval 30 seconds, unhealthy threshold 3 consecutive failures. This means it takes up to 90 seconds to detect a failure before routing changes. For NovaPay's 15-minute RTO, the probe must be: interval 10 seconds, threshold 2 failures (20-second detection). The probe endpoint must test actual transaction processing capability, not just "HTTP 200 from the root path."

2. **DNS TTL is the hidden enemy of fast failover.** Even with Front Door's fast detection, if the client's DNS TTY is 300 seconds (5 minutes), the client's browser or API client will continue using the old IP for up to 5 minutes after the failover. For NovaPay's B2B merchant API clients, you must document and enforce a maximum DNS TTL (recommend 30 seconds) in the client integration guide.

3. **Azure DDoS Protection Standard is required for payment processor Front Door origins.** Standard provides adaptive tuning, attack telemetry, and SLA-backed mitigation. Without it, a volumetric DDoS attack against NovaPay's Front Door origin IP could cause a false failover trigger, routing all traffic to the DR region while the primary region is actually healthy (just flooded).

4. **Chaos engineering validates DR assumptions.** Azure Chaos Studio enables injecting controlled failures: VM shutdown, network latency injection, database failover simulation, and App Service instance kill. Running chaos experiments against a production-equivalent staging environment monthly is the only way to discover that "the database failover group takes 7 minutes, not 3" before the regulator does.

5. **Cost of DR infrastructure vs. cost of downtime.** Active-passive DR with a warm secondary in North Europe costs approximately £28,000/month in idle infrastructure. NovaPay's BIA shows a single 60-minute outage costs £2.7M. The DR infrastructure pays for itself if it prevents one major outage every 8 years. This math must be in the architecture document.

6. **Audit evidence is an architectural output, not a retrospective task.** Every automated failover must produce: a timestamped log of each step, the elapsed time per step, the triggering event, the recovery point (last transaction ID before failover), and the confirmation that no transactions were lost. This log must be stored in Azure Immutable Blob Storage (WORM policy) for regulatory retention.

## Learn — write notes answering these

- What is the difference between Azure Front Door's "priority" routing and "weighted" routing, and which configuration creates an active-passive behavior?
- How does Azure Chaos Studio's "fault injection" differ from a traditional DR drill, and what chaos experiments would you run specifically against a payment processor's database failover group?
- What is Azure DDoS Protection Standard's "adaptive tuning" feature, and how does it prevent legitimate traffic from being blocked during a DDoS mitigation event?
- What is the Azure Policy definition that enforces "no public internet-facing endpoints in production without Front Door" — and why does NovaPay need this as a guardrail?

## Micro exercise

**Scenario:**
> NovaPay's regulator has scheduled an on-site audit for 3 weeks from today. The audit team will examine: (1) evidence that the last 4 quarterly DR tests met the 15-minute RTO, (2) a network diagram proving no single points of failure, (3) evidence that automatic failover occurs without human intervention in a simulated scenario, (4) a DDoS mitigation plan, (5) cost justification for the DR infrastructure. Your architecture team has 3 weeks to prepare.

Your answer must include:
- A 3-week preparation plan with specific deliverables per week (Week 1: what to do, Week 2: what to do, Week 3: final audit preparation).
- The specific Azure service and configuration for each of the five audit requirements — name the service and the evidence artifact it produces.
- A simulated failure scenario for the audit's live demonstration: what failure do you inject (using Azure Chaos Studio), what does the auditor observe, and how do you prove the RTO was met?
- Three Front Door configuration changes that improve reliability and reduce the chance of a false failover during the audit.

## Reflection question
During the live audit demonstration, your Chaos Studio fault injection triggers database failover as planned. Automatic failover completes in 11 minutes — within the 15-minute RTO. However, the auditor notes that 3 transactions that were "in-flight" at the moment of failover were not completed and required manual re-submission by merchants. Does this violate the RPO = 0 requirement, and how do you respond to the auditor's finding?

## Prior concept connection
In Week 11 Day 3 you designed the failover flow with time estimates. Today you are hardening the routing configuration that drives that failover. Review your Day 3 failover flow: does it account for the DNS TTL propagation delay? If not, recalculate the total failover time and confirm it still meets the 15-minute RTO.

## AI coach instructions
The learner must address all five audit requirements with specific Azure service names and evidence artifacts. Watch for: (1) "run a DR test" as a preparation step without specifying what the test measures and how results are captured, (2) not addressing in-flight transactions in the RPO = 0 discussion, (3) proposing DNS TTL of 60 seconds or higher for the Front Door configuration, (4) no mention of Azure Chaos Studio for the live demonstration. Probe: "The auditor asks to see the automated failover log from the last quarterly test. Where is that log stored, who can access it, and how do you prove it has not been tampered with?" Update `memory/weak_areas.md` if the learner cannot distinguish between Front Door priority routing and Traffic Manager failover.

## Completion criteria
- Learner produced a 3-week preparation plan with specific deliverables.
- Learner named an Azure service and evidence artifact for each of the five audit requirements.
- Learner described a specific Chaos Studio experiment for the live audit demonstration.
- Learner identified three Front Door configuration improvements.
- Learner gave a technically correct response to the in-flight transaction / RPO finding.
- AI reviewed with cloud architect, DevOps, security, and compliance perspectives.
- Any mistakes added to `memory/mistakes.md`.
