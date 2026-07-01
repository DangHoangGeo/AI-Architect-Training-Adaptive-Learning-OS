# Week 02 Day 4 — Failure, security, and cost review: Private endpoints and service endpoints

## Goal
Understand the difference between private endpoints and service endpoints, when each one actually eliminates public internet exposure versus merely restricting it, and how to stress-test a network design against data exfiltration, misconfiguration, and unexpected cost scenarios in a manufacturing cloud environment.

## Why this matters
Many architects deploy "service endpoints" believing they have eliminated public exposure of Azure PaaS services, then discover during a security audit that the storage account is still technically reachable from outside Azure if the firewall rule is misconfigured. Private endpoints create a genuinely private IP — service endpoints do not. Getting this wrong in a regulated manufacturing context (export control, industrial secrets) is a compliance failure, not just a security risk.

## Core concept

1. **Service endpoints extend the VNet identity to a PaaS service but do not remove the public endpoint.** A storage account with a service endpoint still has a public FQDN (`storageaccount.blob.core.windows.net`) that resolves to a public IP. The service endpoint just restricts which VNet subnets can use that public path. If you misconfigure the firewall rules, the service is still exposed.

2. **Private endpoints inject a private IP into your VNet via a NIC.** The PaaS service gets a private IP in your subnet (e.g., `10.20.1.5`). Azure Private DNS zones (`privatelink.blob.core.windows.net`) override public DNS resolution inside the VNet. Traffic never leaves the Microsoft backbone. The public endpoint can be fully disabled.

3. **Private endpoints have costs and complexity trade-offs.** Each private endpoint costs ~€7/month plus €0.008/GB processed. For a storage account accessed from 5 different VNets, you need 5 private endpoints (one per VNet). DNS must be configured carefully — incorrect DNS configuration causes the private IP to not resolve, breaking all connectivity silently.

4. **Data exfiltration via private endpoints is still possible.** A compromised compute resource in a spoke VNet with a private endpoint to an attacker-controlled storage account (also using private endpoints) can exfiltrate data. Private endpoints prevent external network paths but do not control what data is sent where. Azure Firewall FQDN rules + Defender for Storage address this gap.

5. **Service endpoints are appropriate for low-sensitivity internal workloads where cost matters.** If a subnet hosts internal batch jobs reading non-sensitive configuration from a storage account, and the storage account has strict firewall rules allowing only that subnet, a service endpoint is simpler and free.

## Learn — write notes answering these

- What DNS record change occurs when you create a private endpoint for an Azure SQL database, and what breaks if the private DNS zone is not linked to the spoke VNet where the application runs?
- A service endpoint for Azure Storage is enabled on subnet A. The storage account firewall allows only subnet A. An attacker compromises a VM in subnet B (same VNet, no service endpoint). Can the attacker reach the storage account? Explain why or why not.
- What is the "private endpoint network policy" setting, and when must you disable it? What security risk does disabling it introduce?
- Compare the total monthly cost of: (a) private endpoint for an Azure SQL database accessed from 3 spoke VNets vs. (b) service endpoint on each spoke's subnet for the same database. What is the cost difference at 500 GB/month data transfer?

## Micro exercise

**Scenario:**
> **Müller Precision GmbH** runs a CNC machining plant in Stuttgart. Their Azure architecture (built last year) uses service endpoints to connect an Azure SQL database (holding production recipes and quality measurements) and an Azure Storage account (CAD file storage, 2 TB active data) to their factory VNet. A security audit flags that the SQL database public endpoint is still enabled and the storage account firewall has a rule allowing "all Azure services" as a legacy workaround for a CI/CD pipeline. The security team gives 30 days to eliminate public PaaS exposure. The CI/CD pipeline runs on Azure DevOps hosted agents (not in the VNet). Monthly budget for the remediation is €200.

Your answer must include:
- A migration plan from service endpoints to private endpoints for both the SQL database and the Storage account, including DNS zone configuration
- How you resolve the CI/CD pipeline connectivity problem without re-enabling public access (name the specific Azure service or approach)
- One failure mode introduced by the DNS migration that could cause a 30-minute production outage and how to prevent it
- Whether the €200 budget is sufficient, with a cost breakdown

## Reflection question
You successfully deployed private endpoints and disabled the SQL database's public endpoint. Three weeks later, a new developer joins and creates an Azure Data Factory pipeline that needs to read from the same SQL database. They report "connection refused" from ADF and ask you to re-enable the public endpoint "just for testing." What is the correct solution, and what would you put in place as a governance control to prevent this request pattern from recurring?

## Prior concept connection
Day 3's hub-spoke design included a dedicated subnet for private endpoints in the hub VNet. Today you are deploying into that subnet. The private DNS zones you configure must be linked to every spoke VNet that needs to resolve the private endpoint — if you only link the hub, spoke VNet workloads will resolve the public IP instead of the private IP, silently bypassing your security control.

## AI coach instructions
Do not reveal answers before the learner writes theirs. Watch for: (1) claiming service endpoints are equivalent to private endpoints for compliance purposes — they are not, (2) forgetting that private DNS zones must be linked to each VNet separately — this is the most common production outage cause during private endpoint migration, (3) not addressing the CI/CD problem (correct answer: use Azure DevOps self-hosted agent in the VNet, or Azure Private Link for Azure DevOps). After review, probe: "Your private endpoint for the Storage account has network policy disabled. What Azure Policy definition would detect this and create a compliance alert?" Record DNS misconfiguration patterns in `memory/weak_areas.md` if this gap appears.

## Completion criteria
- Learner produced a migration plan with DNS zone steps explicitly listed
- CI/CD pipeline connectivity was solved without re-enabling public access
- One specific DNS migration failure mode was named and mitigated
- Cost breakdown was provided and compared to the €200 budget
- AI reviewed from cloud architect, security reviewer, and cost optimizer perspectives
- Mistakes and weak areas recorded, progress updated
