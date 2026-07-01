# Week 02 Day 1 — Concept foundation: VNet and subnet design

## Goal
Understand how to structure Azure Virtual Networks and subnets to isolate workloads, enforce security boundaries, and support future growth. Learn CIDR planning constraints and why wrong subnet sizing causes irreversible operational pain. Apply these principles to an industrial IoT scenario.

## Why this matters
If you deploy factory-floor IoT devices and your ERP application into the same subnet without isolation, a single compromised PLC can reach your SAP database directly. VNet and subnet design is not networking for its own sake — it is the first line of defense that every other security control depends on. Getting it wrong at deployment is expensive or impossible to fix without downtime.

## Core concept

1. **VNets are address space boundaries, not security boundaries on their own.** Subnets within a VNet can communicate freely unless NSGs or Azure Firewall explicitly block traffic. Design subnets around security zones, not application tiers alone.

2. **CIDR sizing is permanent per subnet.** You cannot resize a subnet after it has resources deployed. A /27 (30 usable addresses) for a subnet that will hold 50 VMs will force a subnet rebuild. Plan for 2–3x growth from day one, and reserve address space for services like Azure Firewall, Application Gateway, and private endpoints — each requiring dedicated subnets.

3. **Azure reserves 5 IP addresses per subnet** (network, gateway, broadcast, and two Azure platform addresses). A /29 has only 3 usable addresses. Know this for AZ-305 exam scenarios.

4. **Subnet delegation restricts who can deploy into it.** When you delegate a subnet to a service like Azure Container Apps or SQL Managed Instance, no other resource type can occupy that subnet. Plan delegated subnets separately from general-purpose subnets.

5. **Separate operational plane from data plane.** Management traffic (Bastion, monitoring agents, patch management) should never share subnets with production application traffic. This limits lateral movement if a workload is compromised.

## Learn — write notes answering these

- What is the difference between a VNet address space and a subnet CIDR, and why does the subnet CIDR matter more for day-to-day operations?
- Which Azure services require a dedicated, delegated subnet? Name at least three and state the minimum subnet size each requires.
- When would you choose multiple small VNets over one large VNet with many subnets?
- What is a common mistake architects make when assigning CIDR ranges to VNets that later causes VNet peering failures?

## Micro exercise

**Scenario:**
> **Fabrikam Steel** operates a rolling mill in Duisburg, Germany. The factory floor has 80 Siemens S7 PLCs that push telemetry via MQTT to an Azure IoT Hub. A data ingestion layer (Azure Functions + Event Hub) processes the telemetry. An on-premises SAP ERP system must query aggregated production data via an Azure SQL database. The IT team expects to add two more production lines within 18 months, doubling IoT device count. All resources must be in Azure West Europe. The factory uses a 10.20.0.0/16 address block assigned to Azure.

Your answer must include:
- A subnet layout with at least 4 subnets, including names, CIDR ranges, and the primary resource type in each
- Which subnet(s) require delegation and to what Azure service
- One addressing mistake you explicitly avoided and why
- Whether you would use a single VNet or multiple VNets, and the reason

## Reflection question
You sized your IoT ingestion subnet at /24 (250 usable addresses) for 80 PLCs. In 18 months the count doubles to 160 devices. What non-obvious Azure resource besides the PLCs themselves will consume addresses in that subnet, and could your /24 actually be too small despite seeming large?

## Prior concept connection
Week 1 established that Azure regions and availability zones define physical fault domains. Your subnet layout here must account for the fact that a single VNet spans one region — if Fabrikam ever needs disaster recovery in North Europe, subnets in both regions must use non-overlapping address space or VNet peering will fail.

## AI coach instructions
Ask the learner to draw or list their subnet layout before showing any feedback. Watch for: (1) forgetting to reserve a dedicated subnet for Azure Bastion (AzureBastionSubnet, minimum /26), (2) using overlapping CIDR ranges with the on-premises 10.x.x.x space, (3) not accounting for Azure Firewall needing its own /26 AzureFirewallSubnet. After reviewing, probe: "What happens when you need to add a private endpoint for your Azure SQL database — does your design have a subnet ready for it, and is there space?" Update `memory/mistakes.md` if CIDR sizing or subnet delegation is missed.

## Completion criteria
- Learner produced a subnet layout with at least 4 named subnets, CIDR ranges, and resource types
- At least one delegated subnet was identified with its minimum size requirement
- A specific addressing conflict was called out and avoided
- AI reviewed from cloud architect and network security perspectives
- Any mistake recorded in `memory/mistakes.md`
- Progress updated in `memory/progress.md`
