# Week 04 Day 2 — Azure service mapping: Azure SQL Database vs SQL Managed Instance vs SQL on VM

## Goal
Understand the capability, constraint, and cost differences between Azure SQL Database, SQL Managed Instance (SQL MI), and SQL Server on Azure VM, and apply the decision framework to a healthcare analytics platform with legacy database dependencies, compliance requirements, and mixed workload characteristics.

## Why this matters
A hospital system migrating 15 years of on-premises SQL Server databases to Azure will not succeed if the architect recommends Azure SQL Database without understanding that three of those databases use SQL Agent jobs, linked servers, and CLR assemblies — none of which Azure SQL Database supports. Sending the customer back to SQL on VM because the wrong Azure SQL option was chosen is a credibility and budget failure. The SQL service decision is one of the most frequently tested areas of AZ-305.

## Core concept

1. **Azure SQL Database is a fully managed PaaS with the highest automation but the most constraints.** Features not supported: SQL Agent, linked servers, cross-database queries, CLR assemblies, Service Broker, and some legacy T-SQL syntax. Best for: greenfield applications, modern microservices, apps that can be redesigned. Maximum database size: 4 TB (General Purpose). Serverless compute tier enables auto-pause for dev/test cost savings.

2. **SQL Managed Instance is "SQL Server in Azure" with near-100% compatibility.** It supports SQL Agent, linked servers, CLR, Service Broker, SSAS, and nearly all T-SQL features. It is deployed into a VNet (dedicated subnet, minimum /27) and has no public endpoint by default. Migration path: Azure Database Migration Service with near-zero downtime. Main constraints: no read replicas in the Business Critical tier without significant cost, provisioning takes 4–6 hours, and minimum cost is ~€600/month even at 4 vCores.

3. **SQL Server on Azure VM gives full control at the cost of operational burden.** Full SQL Server features including features not even in MI (e.g., Reporting Services, Analysis Services on same instance). You manage OS patches, SQL patches, HA (Always On AG), backups. Best for: workloads that require SSRS, legacy versions (SQL 2008 R2), or specific OS configuration. Cost model: VM + SQL license (or Azure Hybrid Benefit to reuse existing licenses). Automated patching and backup are available but must be explicitly configured.

4. **Elastic pools and Hyperscale are important variants for healthcare analytics.** Elastic pools: one compute resource shared across many databases — cost-effective for a multi-tenant model where each hospital gets its own database but peak usage is staggered. Hyperscale tier: rapid scale-up to 100 TB, near-instant backup/restore — relevant for the large analytics database but priced at ~3x General Purpose.

5. **The SQL MI "subnet tax" is real and frequently overlooked.** SQL MI requires a dedicated /27 subnet in a VNet, with specific service delegations and NSG rules. The management endpoint (port 9000, 9003, 1438, 1440, 1452) must be accessible from the Azure management plane. Architects often underestimate the network design complexity of SQL MI — it is not a drop-in replacement for an on-premises SQL Server without VNet integration planning.

## Learn — write notes answering these

- A hospital analytics database uses SQL Agent to run nightly ETL jobs, has 3 linked servers to other hospital systems, and uses a CLR assembly for custom statistical functions. Which Azure SQL option is the minimum viable choice? What would need to change if you chose a less capable option?
- Compare the SLA of Azure SQL Database Business Critical tier vs. SQL Managed Instance Business Critical tier vs. SQL Server on Azure VM with Always On Availability Groups. What is the failover time for each in a zone failure scenario?
- A healthcare analytics platform has 50 hospital tenants, each with their own Azure SQL Database (~200 GB each). The databases are idle 70% of the time. What pricing model reduces cost while maintaining the ability to handle peak loads from any single hospital? Estimate the cost saving percentage.
- What is "Azure Hybrid Benefit" for SQL Server, and how does it affect the cost decision for a hospital system that already owns 20 SQL Server Enterprise Edition core licenses?

## Micro exercise

**Scenario:**
> **MedInsight Analytics** needs to migrate four databases from their on-premises SQL Server 2019 datacenter to Azure: (1) `hospital-registry-db`: 800 GB, uses SQL Agent for nightly billing reconciliation, uses linked server to query a legacy Oracle database on-premises, 99.9% uptime required, (2) `analytics-warehouse-db`: 12 TB, read-heavy reporting workload, batch ETL writes nightly, no SQL Agent dependency, 99% uptime acceptable, (3) `per-hospital-tenant-db` (50 identical databases, 50–300 GB each): used by each hospital for local patient records caching, mostly idle except during shift changes, 99% uptime acceptable, (4) `dev-test-db`: 100 GB, used by 3 developers, must be cost-minimized, can tolerate 2-hour downtime.

Your answer must include:
- For each of the four databases: which Azure SQL service tier and service level you recommend, with justification
- The migration approach for `hospital-registry-db` including how to handle the Oracle linked server dependency post-migration
- For `per-hospital-tenant-db`: a specific pricing model that minimizes cost for the idle-heavy usage pattern
- A total monthly cost estimate (approximate) for all four databases combined

## Reflection question
You recommended SQL Managed Instance for `hospital-registry-db` because of the SQL Agent and linked server requirements. Six months after migration, MedInsight's DBA reports that creating new SQL Agent jobs takes "forever" because the SQL MI is in a different VNet subnet with strict NSG rules blocking the SSMS connection. The DBA wants to open port 1433 publicly. What is the correct architecture response, and what is the minimum required network change that maintains security while enabling DBA productivity?

## Prior concept connection
Week 2 Day 4 established that private endpoints bring Azure PaaS services into VNet subnets. SQL Managed Instance is different — it does not use private endpoints; it is natively injected into a dedicated VNet subnet. The network design constraints for SQL MI (dedicated /27 subnet, specific NSG rules, service delegation) must be planned in the VNet design from Week 2 Day 1. If that subnet was not reserved, SQL MI cannot be deployed — this is the cost of not planning subnets correctly at the start.

## AI coach instructions
Ask the learner to complete the service selection table before providing any feedback. Watch for: (1) recommending Azure SQL Database for `hospital-registry-db` without acknowledging the SQL Agent and linked server blockers — this is a hard incompatibility, (2) recommending SQL MI for `per-hospital-tenant-db` (50 databases) without recognizing the cost — 50 SQL MI instances would cost ~€30,000/month minimum, whereas 50 elastic pool databases cost ~€400–800/month, (3) not mentioning Azure Hybrid Benefit when discussing SQL on VM cost. After reviewing, probe: "MedInsight's CISO requires that no SQL database traffic crosses the public internet. For SQL MI, what is the network path for a DBA connecting from their corporate laptop, and what Azure service enables this without opening public endpoints?" Record SQL service selection mistakes in `memory/mistakes.md`.

## Completion criteria
- All four databases assigned to a specific Azure SQL service with justification
- Oracle linked server dependency addressed for `hospital-registry-db`
- Elastic pool recommended for `per-hospital-tenant-db` with cost reasoning
- Total monthly cost estimate provided
- AI reviewed from cloud architect, cost optimizer, and product manager perspectives
- Mistakes recorded and progress updated
