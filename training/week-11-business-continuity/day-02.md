# Week 11 Day 2 — Azure service mapping: Backup vs Disaster Recovery for Payment Infrastructure

## Goal
Map NovaPay's backup and disaster recovery requirements to specific Azure services, understand the fundamental difference between backup (data protection against corruption/deletion) and disaster recovery (infrastructure availability against regional failure), and produce a service selection table that satisfies both the 15-minute RTO and RPO = 0 requirements.

## Why this matters
Many engineers treat "we have Azure Backup configured" as meaning "we are protected against disasters." Azure Backup restores data after corruption or accidental deletion — restore times are measured in hours. Azure Site Recovery fails over infrastructure after a regional outage — failover times can be under 15 minutes if configured correctly. NovaPay needs both, and they are different products solving different problems. Confusing them in a regulator audit leads to findings.

## Core concept

1. **Azure Backup protects against data corruption, accidental deletion, and ransomware.** It creates point-in-time restore points. For Azure SQL, backup is automatic (full weekly, differential daily, log every 5-15 minutes). Restore time for a 2TB database from backup is 2-6 hours. This is not DR — it is data protection.

2. **Azure Site Recovery (ASR) replicates entire workloads to a secondary region for rapid failover.** For IaaS workloads (VMs), ASR continuously replicates VM disks with RPO of approximately 30 seconds. For PaaS (Azure SQL, App Service), ASR is not the tool — geo-replication and zone redundancy are.

3. **Azure SQL Database geo-replication creates a continuously synchronized secondary in another region.** With the Business Critical tier, the secondary is synchronously replicated within the same region (to zone-redundant replicas) and asynchronously replicated to a geo-secondary. The geo-secondary has an RPO of seconds to minutes — not zero. For RPO = 0, the architecture must use synchronous writes to a secondary before acknowledging the transaction.

4. **Azure SQL Database Failover Groups automate the failover process.** A failover group monitors the primary database and automatically promotes the geo-secondary if the primary is unavailable. Automatic failover with the correct grace period (e.g., 1 minute detection + promotion) is the only way to achieve RTO < 15 minutes without manual intervention.

5. **Azure Blob Storage with geo-zone-redundant storage (GZRS)** is the correct tier for NovaPay's transaction audit logs. GZRS replicates data synchronously across three availability zones in the primary region and asynchronously to a secondary region. For audit log reads after a failover, the secondary is automatically promoted.

6. **Recovery testing differentiates backup types.** Backup is tested by restoring to a test environment and verifying data integrity. DR is tested by failing over to the secondary region and running a production-equivalent transaction load. Both must be tested on a schedule — not just designed on paper.

## Learn — write notes answering these

- What is the difference between Azure SQL Database "Active Geo-Replication" and "Auto-Failover Groups"? Which is required for automatic failover without manual intervention?
- Azure Backup for Azure SQL Database uses automated backups (no additional configuration needed for Business Critical tier). What are the three backup types, their frequency, and the default retention period?
- What is "recovery point" vs "recovery time" in the context of Azure Site Recovery for a VM workload? If ASR replicates with a 30-second RPO, what does that mean for NovaPay's transaction data?
- What is the "failover grace period" in an Azure SQL Failover Group, and why should NovaPay not set it to 0 (immediate failover on any interruption)?

## Micro exercise

**Scenario:**
> NovaPay's architecture team has been asked to produce a Disaster Recovery Plan (DRP) for the regulator. The regulator requires: (1) documented RTO = 15 minutes for transaction processing, (2) RPO = 0 for settled transactions, (3) quarterly DR tests with results submitted to the regulator, (4) a separate backup retention policy of 7 years for transaction audit logs (legal requirement). The current architecture runs entirely in UK South with no secondary region.

Your answer must include:
- A service selection table with columns: Component | Current Service | DR Service | Backup Service | RTO Contribution | Notes. Cover: application tier, database tier, storage tier, API gateway.
- The specific Azure SQL configuration (tier, replication mode, failover group settings) required to achieve RPO = 0 for settled transactions.
- How "quarterly DR tests" are implemented using Azure-native tooling — what is triggered, how is the test scope defined (do you fail over production or a clone?), and how are results captured for the regulator.
- The backup architecture for 7-year audit log retention: service, tier, redundancy level, and lifecycle management policy.

## Reflection question
Your Azure SQL Failover Group is configured with automatic failover and a 5-minute grace period. At 14:23, UK South experiences a partial network degradation — the database is reachable but 30% of queries are timing out. At 14:28, the failover group's health probe triggers and begins promoting the North Europe secondary. NovaPay's application is now split: 40% of App Service instances are still writing to UK South (slow), 60% have been updated by Traffic Manager to write to North Europe. What data consistency problem has occurred, and what should have been in the architecture to prevent it?

## Prior concept connection
In Week 11 Day 1 you tiered NovaPay's systems and assigned RTO/RPO values. Today you are filling in the specific Azure services for each tier. For each tier you defined yesterday, identify whether the correct DR tool is ASR, Failover Groups, or zone-redundant deployment — and justify the choice.

## AI coach instructions
The learner must produce the service selection table before discussing RPO = 0. Watch for: (1) using Azure Site Recovery for Azure SQL databases (wrong — use Failover Groups), (2) setting failover grace period to 0 without addressing the split-brain risk, (3) using standard Azure Blob Storage instead of GZRS for audit logs, (4) proposing to run quarterly DR tests on production without a traffic isolation strategy. Probe: "Your Failover Group promotes the North Europe secondary. How long does it take for the Azure Traffic Manager or Front Door to detect the failover and update DNS to route traffic to North Europe — and does that count toward your 15-minute RTO?" Update `memory/weak_areas.md` if the learner conflates backup and DR tools.

## Completion criteria
- Learner produced a service selection table covering all four components.
- Learner specified Azure SQL configuration for RPO = 0 (synchronous replication within region, failover group).
- Learner described a quarterly DR test process with results capture.
- Learner designed a 7-year audit log backup policy using a named Azure service and lifecycle policy.
- AI reviewed with cloud architect and compliance perspectives.
- Any mistakes added to `memory/mistakes.md`.
