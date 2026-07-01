# Week 02 Day 5 — Communication and refinement: Ingress and egress control

## Goal
Consolidate Week 2 networking knowledge into a communication artifact: a 5-bullet executive summary of the network security architecture for a manufacturing enterprise. Practice defending design decisions in the face of cost challenges and presenting network topology trade-offs to a non-technical audience.

## Why this matters
Cloud architects who cannot explain their network security decisions to a CFO or plant manager lose budget approval. An overly technical explanation of NSGs and UDRs means nothing to a manufacturing executive. The ability to translate technical controls into business risk language — "without this, a compromised PLC can reach payroll data" — is what separates a senior architect from a configuration specialist.

## Core concept

1. **Executive summaries for network architecture have a standard structure:** (a) What we built and why, (b) what threats it prevents, (c) what it costs, (d) what the residual risk is, (e) what the next recommended action is. Five bullets maximum — anything longer will not be read.

2. **Ingress control = who can reach your workloads from outside.** Layers: DDoS Protection, WAF (App Gateway or Front Door), NSG on inbound, Azure Firewall DNAT rules. Each layer addresses a different attack class. The correct summary is: "Internet traffic hits WAF first, which blocks application-layer attacks; NSGs then restrict which ports reach which subnets."

3. **Egress control = what your workloads can reach on the internet.** Default Azure behavior is unrestricted outbound internet from any VM. This enables malware C2, data exfiltration, and crypto mining on your compute. Forcing egress through Azure Firewall with explicit allow-list FQDN rules is the production baseline. For factory IoT, egress should be severely restricted to only the IoT Hub and update server FQDNs.

4. **Cost is a legitimate architectural concern, not an afterthought.** A complete network security architecture for a mid-size manufacturing company (hub-spoke, Azure Firewall Standard, WAF on App Gateway, private endpoints for key PaaS services) costs approximately €2,500–4,000/month. This must be justified against the cost of a breach: average industrial ransomware recovery is €1.2M+ per incident.

5. **Refinement means removing unnecessary complexity.** Review the design from Day 3: did you add services that overlap in function? A WAF on Application Gateway AND Azure Firewall Premium IDPS for the same web traffic is redundant if the web app is not processing particularly sensitive data. Remove what does not justify its cost.

## Learn — write notes answering these

- Draft a one-sentence description of each of the following controls in non-technical language a plant operations manager would understand: NSG, Azure Firewall, WAF, private endpoint.
- What is the difference between "ingress" and "north-south traffic" in Azure networking context? Are they the same thing?
- When a CISO asks "can our IoT devices exfiltrate data to a rogue server on the internet?", which specific Azure configuration setting is your answer, and how do you prove it is working?
- What is the one metric in Azure Monitor / Azure Firewall logs that most clearly shows whether your egress control is working as intended?

## Micro exercise

**Scenario:**
> You have completed the network architecture for **Kepler Industrial Group** (from Day 3: Frankfurt hub, Bratislava SAP spoke, Warsaw AKS spoke, Germany HQ VPN). The CTO has asked for a 5-bullet executive summary to present to the board before approving the €38,000/year network security budget. The board is non-technical but has seen the news about industrial ransomware attacks on European manufacturers. One board member is the CFO, who will challenge the cost. A second board member is the Head of Manufacturing Operations, who will challenge anything that causes network latency to production PLCs.

Your answer must include:
- A 5-bullet executive summary (written as if you are presenting to the board — no jargon, each bullet max 2 sentences)
- One sentence response to the CFO's likely objection: "Can't we just use the built-in Microsoft security features for free?"
- One sentence response to the Head of Manufacturing's likely concern: "Will this firewall add latency to our PLC telemetry?"
- A table comparing your final architecture (from Days 1–4 this week) against a "do nothing" baseline across 4 dimensions: threat coverage, monthly cost, compliance posture, and operational overhead

## Reflection question
The board approves the budget but asks you to cut 20% of cost within 90 days. Looking at your Week 2 architecture as a whole, which single component would you downgrade or remove first, and what residual risk does that introduce? Is there a component you would absolutely not cut, and why?

## Prior concept connection
This day synthesizes all of Week 2. The subnet design from Day 1 created the structure; Days 2–4 filled it with NSGs, Azure Firewall, WAF, and private endpoints. The executive summary you write today is the communication layer that makes all that technical work fundable and governable. Refer back to specific Day 3 and Day 4 decisions when writing your summary bullets — generic statements without specific design references will be scored lower.

## AI coach instructions
Do not write the executive summary for the learner. After they submit, score the executive summary on: clarity (is it genuinely non-technical?), completeness (does it cover the 5 required elements?), accuracy (does it correctly characterize what the design does?), persuasiveness (would a CFO be convinced?). Check that the cost comparison table uses numbers from actual Azure pricing, not estimates. Probe: "Your summary says 'we secured the network with a firewall.' Rewrite that bullet so a board member understands what specifically would have happened without it." Update `memory/weak_areas.md` if communication is the weakness. Score overall Week 2 comprehension and record in `memory/progress.md`. Recommend whether to proceed to Week 3 or do a targeted bridge exercise.

## Completion criteria
- 5-bullet executive summary written in genuinely non-technical language
- CFO and Head of Manufacturing objection responses written (one sentence each)
- Comparison table completed with at least 4 dimensions and real cost numbers
- AI scored the summary against the 4 dimensions
- Week 2 progress recorded and Week 3 readiness assessed
- Session log created in `memory/session_logs/`
