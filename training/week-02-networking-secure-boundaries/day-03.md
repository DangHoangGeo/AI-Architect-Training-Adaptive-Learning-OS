# Week 02 Day 3 — Design exercise: Hub-spoke network topology

## Goal
Design a complete hub-spoke network topology that connects a global manufacturing company's factory sites, shared services, and cloud workloads through a governed, centrally controlled network boundary. Understand when hub-spoke is correct versus alternatives, and what breaks if the hub is misconfigured.

## Why this matters
Manufacturing companies acquiring plants across multiple countries end up with a tangle of peer-to-peer VNet connections unless hub-spoke is established early. Without it, adding the 10th spoke VNet requires 9 new peering connections (n*(n-1)/2 growth). More critically, without a hub there is no single choke point for traffic inspection — any compromised spoke can reach any other spoke directly.

## Core concept

1. **Hub-spoke separates shared services from workload ownership.** The hub VNet contains: Azure Firewall (or NVA), VPN/ExpressRoute Gateway, Azure Bastion, DNS forwarder, monitoring agents. Spokes contain application workloads. The hub is owned by the platform team; spokes are owned by application teams.

2. **Peering is non-transitive by default.** Spoke A and Spoke B cannot communicate through the hub unless you configure Azure Firewall as the next-hop for spoke-to-spoke traffic (via UDR — User Defined Routes). This is the most common misconfiguration: architects assume the hub "routes" traffic automatically.

3. **User Defined Routes (UDRs) force traffic through the hub firewall.** A UDR on the spoke subnet sets the default route (0.0.0.0/0) next-hop to the hub Azure Firewall private IP. Without UDRs, spoke traffic bypasses the firewall and goes directly to the internet.

4. **Azure Virtual WAN (vWAN) is the managed alternative.** vWAN automates the hub routing, provides built-in any-to-any connectivity, and integrates with Azure Firewall Manager. It is preferred when you have 5+ sites or spokes. The trade-off: less configuration flexibility, and you cannot peer a vWAN hub with a classic VNet hub (you must choose one model).

5. **Gateway transit enables spoke-to-on-premises routing.** When you enable "Use remote gateways" on a peering, spoke VNets can use the hub's VPN/ExpressRoute Gateway to reach on-premises without deploying their own gateway. This saves cost but creates a dependency on hub availability.

## Learn — write notes answering these

- What is the maximum number of VNet peering connections per VNet in Azure, and at what scale does this limit force you to choose Azure Virtual WAN over classic hub-spoke?
- Explain spoke-to-spoke traffic flow step-by-step when Azure Firewall is the transit hub, including which UDR table entries are required on each spoke subnet.
- What is the difference between "Allow gateway transit" (set on the hub peering) and "Use remote gateways" (set on the spoke peering), and what breaks if only one side is configured?
- Under what circumstances would you create a second hub VNet in a different region rather than extending the existing hub to that region?

## Product framing (write this first)

> **User pain:** Plant network managers at each factory site manually configure firewall rules with no central visibility. When a new production line is added, it takes 3 weeks to provision network connectivity because each request goes through a central IT ticketing queue. Meanwhile, factory IoT devices have unrestricted internet access because no one owns the routing policy.
>
> **MVP constraint:** Connect 3 existing Azure spoke VNets (ERP workload, IoT ingestion, DevTest) to a new hub within 4 weeks using existing Azure Firewall Standard (already procured). No new ExpressRoute circuits — existing site-to-site VPN from Germany HQ must be preserved. The platform team has 2 engineers.
>
> **Success metric:** 100% of spoke-to-internet traffic passes through Azure Firewall logs within 30 days of go-live. Zero direct internet peerings from spoke subnets verified by Azure Policy compliance report.

## Micro exercise

**Scenario:**
> **Kepler Industrial Group** operates three manufacturing facilities: Frankfurt (existing hub VNet with Azure Firewall Standard, VPN Gateway connecting to Germany HQ on-premises), Bratislava (spoke VNet: SAP S/4HANA on Azure VMs, 150 users), and Warsaw (spoke VNet: quality-control image processing on AKS, needs outbound internet for container image pulls from Docker Hub). A fourth spoke is planned in 6 months for a new Chennai plant. All inter-spoke traffic must pass through the Frankfurt hub firewall. The Germany HQ on-premises network must reach SAP in Bratislava via the existing VPN. The Warsaw AKS cluster must pull images from Docker Hub but no other internet destination.

Your answer must include:
- A topology diagram described in text (hub, spokes, peerings, VPN, UDRs) — list every peering with its "allow gateway transit" and "use remote gateways" settings
- The specific UDR entries required on the Warsaw spoke subnet to force Docker Hub traffic through the hub firewall while keeping AKS pod-to-pod traffic local
- How on-premises HQ reaches SAP in Bratislava step-by-step through your topology
- One design decision you would change if Kepler adds 5 more spokes in year 2 and why

## Reflection question
You configured UDRs on both Bratislava and Warsaw subnets to route 0.0.0.0/0 through the Frankfurt hub firewall. The AKS team in Warsaw reports that their internal Kubernetes service discovery (kube-dns, pod CIDR) is broken after the UDR was applied. What is happening, and how do you fix it without removing the UDR?

## Prior concept connection
Day 2 established that Azure Firewall must have its own /26 subnet in the hub and that NSGs cannot replace it for FQDN-based filtering. Today you are wiring the hub-spoke topology around that same Azure Firewall — the transit routing via UDRs makes the firewall effective. Without the UDRs from Day 2's egress control design, your hub-spoke topology silently fails to inspect spoke traffic.

## AI coach instructions
Do not provide the topology answer until the learner has written their own. Watch for: (1) forgetting to enable "Allow gateway transit" on the hub side of the Bratislava peering — this breaks on-premises HQ access to SAP, (2) applying a UDR to the AzureFirewallSubnet itself (this breaks Azure Firewall asymmetric routing), (3) not realizing that AKS uses internal /16 pod CIDR that must be excluded from the forced-tunnel UDR or kube-dns breaks. After reviewing the answer, ask: "What Azure Policy definition would you assign to enforce that no spoke subnet has a 0.0.0.0/0 route pointing anywhere other than the hub firewall IP?" Record any UDR or peering misconfiguration in `memory/mistakes.md`.

## Completion criteria
- Learner wrote a topology with all peerings, UDR entries, and gateway transit settings explicitly stated
- The Warsaw AKS outbound constraint was addressed specifically
- On-premises HQ → SAP routing was traced step-by-step
- Year-2 scaling decision was discussed
- Product framing (pain, constraint, metric) was written before the design
- AI reviewed from cloud architect, product manager, and security perspectives
- Mistakes recorded and progress updated
