# Week 02 Day 2 — Azure service mapping: NSG vs Azure Firewall vs WAF

## Goal
Understand precisely where each traffic-control service operates in the OSI model, what threats each one can and cannot stop, and how to select the right combination for a given network boundary. Apply this to a scenario where factory-to-cloud and internet-to-cloud traffic must be controlled differently.

## Why this matters
A common and costly mistake is buying Azure Firewall Premium for every scenario when NSG rules alone would suffice, or conversely protecting a public-facing API with only NSGs and being surprised when OWASP injection attacks get through. Mismatching the tool to the threat wastes budget and creates false confidence. In regulated industries like manufacturing with OT/IT convergence, a misconfigured boundary can expose industrial control systems to the internet.

## Core concept

1. **NSGs operate at Layer 4 (TCP/UDP/ICMP) on subnets and NICs.** They allow or deny by source/destination IP, port, and protocol. They have no visibility into HTTP headers, DNS names, or TLS payloads. Stateful within a flow. They are free but limited.

2. **Azure Firewall operates at Layer 4–7 and is centrally managed.** Standard tier handles FQDN-based rules and network rules. Premium tier adds IDPS (intrusion detection/prevention), TLS inspection, URL categorization, and web categories. Azure Firewall is a managed, highly available, auto-scaling service — but costs roughly €1,100/month for Standard in West Europe even at zero traffic due to the fixed deployment fee.

3. **Azure Web Application Firewall (WAF) operates at Layer 7 HTTP/HTTPS only.** It is not a network firewall. WAF defends against OWASP Top 10 (SQLi, XSS, path traversal, etc.), bot protection, and custom rules. It runs on Azure Application Gateway (regional) or Azure Front Door (global). It cannot block non-HTTP traffic.

4. **The decision matrix:**
   | Threat | Correct control |
   |--------|----------------|
   | SSH from wrong subnet | NSG |
   | Malware C2 via HTTP to random IPs | Azure Firewall FQDN deny |
   | SQL injection on web API | WAF on App Gateway |
   | Lateral movement between VNets | Azure Firewall + forced tunneling |
   | DDoS volumetric attack | Azure DDoS Protection (separate service) |

5. **Layering is correct and expected.** A request from the internet to a web app passes through: DDoS Protection → WAF (App Gateway) → NSG on App Gateway subnet → App Gateway → NSG on app subnet → app VM/container. Each layer has a distinct responsibility and none fully replaces another.

## Learn — write notes answering these

- At what OSI layer does an NSG operate, and what is the one class of attack it structurally cannot block even with perfect rule configuration?
- What is the minimum Azure Firewall SKU required to perform TLS inspection on outbound traffic from a factory IoT gateway, and what additional component is required to make TLS inspection work?
- When would you deploy WAF on Azure Front Door instead of WAF on Application Gateway, and what capability does Front Door WAF add that regional App Gateway WAF lacks?
- Azure Firewall and Application Gateway can both sit in front of a web app. Describe the "Application Gateway before Firewall" vs "Firewall before Application Gateway" topologies and state when each is correct.

## Micro exercise

**Scenario:**
> **Hofmann Automotive** runs a stamping plant in Pune, India. They are migrating their production reporting portal (an internal web app used by 200 plant managers) from on-premises IIS to Azure App Service. The app is accessed only from the corporate WAN, never from the public internet. Separately, 40 CNC machines push machining telemetry via HTTPS to an Azure API Management endpoint that is internet-accessible. The security team requires: (a) the production reporting portal must not be reachable from the public internet at all, (b) outbound internet traffic from all Azure resources must go through a controlled, logged path, (c) API injection attacks on the APIM endpoint must be blocked. Budget for security services is capped at €3,000/month total.

Your answer must include:
- Which traffic-control service(s) you select for each of the three security requirements, with justification
- One service you explicitly rejected for each requirement and the reason
- A rough monthly cost estimate for your chosen combination
- One configuration mistake in NSG rules that would silently break requirement (a)

## Reflection question
You placed Azure Firewall in the hub VNet to control all east-west traffic. A developer argues that NSGs on each subnet are sufficient and Azure Firewall is wasting €1,100/month. What specific scenario — realistic in this manufacturing environment — would NSGs alone fail to catch that Azure Firewall would have prevented?

## Prior concept connection
Day 1 established the subnet layout including a dedicated AzureFirewallSubnet (/26) and an ApplicationGatewaySubnet. Today you are deciding what to deploy into those reserved subnets and why — the subnet reservation you made yesterday now pays off.

## AI coach instructions
Ask the learner to answer before providing any feedback. Watch for: (1) suggesting WAF for non-HTTP traffic — this shows a misunderstanding of what WAF does, (2) forgetting that Azure Firewall requires a public IP even if only used for egress, (3) not accounting for the fixed €1,100/month Azure Firewall cost against the €3,000 budget. Probe: "If Hofmann adds a third requirement — blocking ransomware C2 traffic from any compromised CNC machine — which service in your design handles that, and does it require a SKU upgrade?" Record any OSI-layer confusion in `memory/mistakes.md`.

## Completion criteria
- Learner mapped each of the three security requirements to a specific Azure service with justification
- At least one rejected alternative was named per requirement
- A cost estimate was provided
- AI reviewed from cloud architect and security reviewer perspectives
- Mistakes recorded and progress updated
