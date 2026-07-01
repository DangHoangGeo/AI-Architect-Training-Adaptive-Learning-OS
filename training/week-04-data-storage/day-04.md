# Week 04 Day 4 — Failure, security, and cost review: Backup, retention, lifecycle policies, and data loss scenarios

## Goal
Stress-test the data and storage architecture from Days 1–3 against realistic failure scenarios: accidental deletion, ransomware encryption, storage account misconfiguration, and regulatory audit requests for data that should have been retained but was not. Identify which failures are recoverable, at what cost, and within what time window.

## Why this matters
In 2024, a European healthcare analytics company discovered that their Azure SQL Managed Instance had point-in-time restore (PITR) enabled but the retention period was left at the default 7 days. A ransomware attack encrypted the database, and the backup that preceded the encryption by 10 days was outside the retention window — unrecoverable. The company had to rebuild the database from raw audit logs, taking 3 weeks and costing €800,000. Default backup retention is not a disaster recovery strategy; it is a disaster waiting to happen.

## Core concept

1. **Azure SQL backup types and their retention windows.** Automated backups: full (weekly), differential (12–24 hours), transaction log (every 5–12 minutes). PITR (Point-In-Time Restore): default 7 days, configurable up to 35 days for SQL Database, 35 days for SQL MI. Long-Term Retention (LTR): weekly/monthly/yearly backups stored in RA-GRS Blob Storage, configurable to 10 years. LTR is separate from PITR and must be explicitly configured. For healthcare: PITR 35 days + LTR 7 years is the regulatory baseline.

2. **Blob Storage soft delete and versioning are independent features.** Soft delete (container and blob level): deleted blobs are retained for a configurable period (1–365 days) and can be undeleted. Blob versioning: every overwrite creates a new version; previous versions are retained. Both must be explicitly enabled — they are not on by default. For the DICOM archive: enable blob versioning + immutability policy. Soft delete alone does not protect against immutability-violating deletions.

3. **Azure Backup vault vs. Recovery Services vault.** Recovery Services vault: used for VMs, Azure SQL, Azure Files, SAP HANA. Azure Backup vault: newer service for Azure Disks, Azure Blobs (operational backup), Azure Database for PostgreSQL. Both support cross-region restore (CRR) but require specific configuration. For healthcare SQL MI: Recovery Services vault with PITR policy + LTR policy + geo-redundant backup storage.

4. **The cost of not doing backup correctly vs. the cost of doing it right.** LTR for one SQL MI database (100 GB/week full, retained 7 years): approximately €180/month in RA-GRS storage. Compare to: €800,000 data recovery incident. The ROI of correct backup configuration is immediate. The AZ-305 exam frequently presents scenarios where the cheapest backup option fails to meet the stated RPO/RTO — know the gaps.

5. **Ransomware recovery requires immutable backup.** Ransomware encrypts data including backups if backups are stored in the same storage account as the data. Azure Backup immutable vault (available since 2023) prevents deletion or modification of backup data for a configured retention period — even by subscription admins. Enabling immutable vault requires planning: once enabled with locked mode, the policy cannot be shortened or disabled.

## Learn — write notes answering these

- MedInsight's `hospital-registry-db` (SQL MI) has PITR set to 7 days and no LTR configured. At 11pm on day 8, the team discovers that data corruption was introduced 10 days ago by a faulty ETL job. What is the recovery options analysis, and what should have been configured to make this recoverable?
- A Cosmos DB container has 500 million documents. A developer accidentally runs `db.collection.deleteMany({})` against the production endpoint. What is the recovery path, and what is the maximum data loss (RPO) with default Cosmos DB configuration?
- Blob Storage versioning is enabled. An attacker with Storage Blob Data Contributor access encrypts all blobs by overwriting them with encrypted versions, then attempts to delete all previous versions. Walk through exactly what the attacker can and cannot do, and what Azure control prevents the version deletion step.
- What is the difference between "operational backup" and "vault backup" for Azure Blob Storage, and which one is appropriate for the DICOM archive container at MedInsight?

## Micro exercise

**Scenario:**
> **MedInsight Analytics** conducts a disaster recovery audit and finds five gaps in their current backup configuration: (a) SQL MI PITR retention is 7 days (default), no LTR configured — the NHS mandates 7-year retention of clinical records, (b) Blob Storage for DICOM archive has soft delete disabled, no versioning, and no immutability policy, (c) Cosmos DB has no backup policy review — default is continuous backup mode with 30-day retention, (d) the Recovery Services vault storing SQL MI backups is in the same Azure region as the SQL MI (UK South) with no geo-redundant backup storage configured, (e) there is no documented and tested recovery runbook — no one has ever performed a test restore.

Your answer must include:
- For each of the five gaps: the specific remediation configuration (not just "enable it" — state the exact retention periods, redundancy options, and Azure portal/CLI settings involved)
- A recovery time objective (RTO) and recovery point objective (RPO) for the SQL MI after remediation, assuming a ransomware attack as the worst-case scenario
- The total incremental monthly cost of all five remediations combined (use approximate Azure pricing)
- The single change from the five that provides the highest risk reduction per euro spent, with reasoning

## Reflection question
You enable immutable vault on the Recovery Services vault with locked policy (cannot be disabled). Three months later, a compliance requirement changes and a 2-year backup retention policy must be shortened to 1 year to comply with new UK data minimization rules. What is your recovery from this situation, and what is the lesson about sequencing immutability and compliance policy review?

## Prior concept connection
Day 1 established that lifecycle policies automatically move DICOM data to Archive tier after 365 days. Day 2 established SQL MI as the database for `hospital-registry-db`. Day 3 established Cosmos DB for vital signs and admission records. Today you are stress-testing all three data services against the same adversarial scenario (ransomware) and the same regulatory requirement (7-year retention) — the backup design must cover all three services with a coherent policy, not three unconnected decisions. The network isolation from Week 2 and the RBAC from Week 3 prevent the attacker from reaching the data; backup and immutability protect against the scenario where those controls are breached.

## AI coach instructions
Do not provide the remediation configurations until the learner writes theirs. Watch for: (1) confusing PITR and LTR — PITR at 35 days is NOT the same as 7-year LTR; a common mistake is saying "set PITR to 7 years" which is not a valid configuration, (2) saying "enable geo-redundant backup storage" without acknowledging this requires recreating the Recovery Services vault or changing the vault's storage redundancy setting (which cannot be changed after the first backup is taken in some configurations), (3) not knowing that Cosmos DB continuous backup mode has a 30-day retention ceiling — long-term retention beyond 30 days requires periodic exports to Blob Storage using a custom solution or Azure Data Factory. After reviewing, probe: "Write the Azure CLI command to configure LTR for an SQL MI database with weekly backups retained for 7 years." Record backup misconfiguration patterns in `memory/weak_areas.md`.

## Completion criteria
- All five gaps remediated with specific configuration details (not just "enable X")
- RTO and RPO stated for the post-remediation ransomware scenario
- Monthly cost of all five remediations estimated
- Highest-ROI remediation identified and justified
- Immutability sequencing risk acknowledged in reflection
- AI reviewed from cloud architect, cost optimizer, and security reviewer perspectives
- Mistakes and weak areas recorded, progress updated
