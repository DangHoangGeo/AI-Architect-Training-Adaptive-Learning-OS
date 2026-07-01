# Week 04 Day 5 — Communication and refinement: Data classification, encryption, and executive data governance summary

## Goal
Design a data classification and encryption framework for the healthcare analytics platform, map each data asset to its classification tier, select the correct encryption key management approach, and consolidate Week 4 into a 5-bullet executive summary suitable for presenting to a healthcare CTO and Chief Medical Officer who are deciding whether to expand the platform to 100 additional hospitals.

## Why this matters
Healthcare data is the most commercially valuable and most heavily regulated data category in cloud computing. A healthcare analytics platform that cannot demonstrate where each data asset is, how it is classified, who can access it, and how it is encrypted will fail NHS Digital Data Security and Protection Toolkit (DSPT) assessments, HIPAA Business Associate Agreement audits, and GDPR Article 32 compliance reviews. Losing one of these certifications means losing hospital contracts. The ability to communicate data governance in board-level language is the competence that keeps contracts and wins new ones.

## Core concept

1. **Data classification has regulatory and operational dimensions.** For healthcare, the UK classification baseline is: Restricted (general patient data, accessible to authorized clinicians), Confidential (identifiable patient records, MRI/CT scans, psychiatric notes — restricted to treating clinicians), Sensitive (HIV status, mental health, genetic data — additional access controls, logged), Public (anonymized aggregate statistics). Every data asset in the MedInsight platform must be assigned a tier, and the storage, encryption, and access controls must match.

2. **Encryption at rest: Microsoft-managed keys vs. customer-managed keys (CMK).** All Azure storage services encrypt data at rest by default using Microsoft-managed keys (free, automatic). Customer-managed keys (CMK) via Azure Key Vault give the customer control: they can revoke the key to deny Microsoft access, they can audit every key access, and they can rotate keys. CMK is required for: HIPAA BAA compliance in many cases, UK DSPT Tier 3 assessments, any workload where the customer must prove they can independently disable all access to data. CMK adds ~€15/month per Key Vault key plus Key Vault transaction costs.

3. **Encryption in transit requires explicit verification.** All Azure services use TLS 1.2+ by default, but legacy configurations can allow TLS 1.0/1.1. For healthcare: configure Azure Storage "Minimum TLS Version" to TLS 1.2, configure SQL MI to require encrypted connections, verify Application Gateway terminates TLS and re-encrypts to the backend (end-to-end SSL). An audit finding for a healthcare platform that accepts TLS 1.0 connections is a critical remediation.

4. **Microsoft Purview classifies and maps data assets automatically.** Microsoft Purview (Data Governance product) scans Azure Storage, SQL, Cosmos DB, and other sources, automatically identifies sensitive data patterns (NHS numbers, patient IDs, DICOM metadata), and creates a data catalog. This replaces manual classification spreadsheets for large platforms. Purview integration with Azure Policy can enforce classification-based access controls automatically.

5. **Double encryption and confidential computing address nation-state and insider-Microsoft threats.** Azure double encryption (infrastructure encryption layer below storage encryption) and Azure confidential computing (AMD SEV-SNP or Intel SGX — encrypts data in use in memory) are the highest security tier. These are rarely required but asked about in AZ-305. For healthcare research data with genomic sequences or psychiatric records under specific government sensitivity classifications, confidential computing may be contractually required.

## Learn — write notes answering these

- Classify each of the following MedInsight data assets and state the required encryption key management approach: (a) DICOM files (identified MRI scans with patient NHS numbers), (b) aggregate anonymized population health statistics, (c) AI model weights (no patient data), (d) audit logs of who accessed which patient record.
- What is the operational impact of enabling Customer Managed Keys on an Azure SQL Managed Instance, and what happens if the Key Vault key is accidentally deleted (with soft delete enabled)?
- Microsoft Purview scans a Blob Storage container and classifies 15% of files as containing NHS numbers. The CISO asks: "How do we ensure no one can read these files without explicit approval?" Describe the Azure services and policies that enforce this.
- What is "Transparent Data Encryption (TDE)" in Azure SQL, and at what layer does it protect data — does it protect against a DBA who has legitimate SQL access to the database?

## Micro exercise

**Scenario:**
> **MedInsight Analytics** is preparing for NHS Digital DSPT Tier 3 certification and a HIPAA BAA audit before expanding to 100 hospitals. The auditor's pre-audit questionnaire asks for: (a) a data asset inventory with classification, storage location, and encryption key management, (b) evidence that data in transit is encrypted with TLS 1.2 minimum, (c) evidence that encryption keys are under customer control for Tier 3 classified data, (d) a description of how unauthorized data access would be detected and how fast. The platform has 3 storage accounts, 1 SQL MI, 1 Cosmos DB, and produces 2 TB/day of data.

Your answer must include:
- A data asset classification table with columns: Asset Name, Classification Tier, Storage Service, Key Management (Microsoft-managed vs. CMK), Justification
- One specific Azure configuration you would change to pass the TLS 1.2 minimum requirement (state the Azure portal setting or ARM property name)
- The Key Vault configuration required to enable CMK for the `hospital-registry-db` SQL MI, including which specific Key Vault permission the SQL MI managed identity needs
- A 5-bullet executive summary for the MedInsight CTO and Chief Medical Officer that: explains what data governance means for expanding to 100 hospitals, quantifies the risk of not having it, states the current compliance posture, states the cost of the governance framework, and identifies the one remaining gap before DSPT Tier 3 certification

## Reflection question
The CMO asks: "If we enable Customer Managed Keys and rotate them every 90 days as required, what is the risk that a misconfigured rotation breaks every clinical application on a Saturday night?" Describe the operational safeguard that makes CMK rotation safe in production, and what monitoring alert would give you a 24-hour warning before a key expires.

## Prior concept connection
Week 4 Days 1–4 built the full data storage architecture: storage tiers and replication (Day 1), SQL service selection (Day 2), Cosmos DB design (Day 3), backup and retention (Day 4). The data classification framework you create today applies to every data asset across all of those decisions — it is the governance layer that makes the technical decisions auditable. The Key Vault CMK integration here directly uses the Key Vault RBAC design from Week 3 Day 3 and the managed identity design from Week 3 Day 3. The entire platform's security posture is now end-to-end: network (Week 2) → identity (Week 3) → data (Week 4).

## AI coach instructions
Do not write the data classification table or the executive summary for the learner. After they submit, score the executive summary on: does it address the 100-hospital expansion specifically (not generic), does it include a real cost number, is it genuinely non-technical, does it answer the CMO's implicit question ("is patient data safe?"). Watch for: (1) recommending CMK for all data assets including AI model weights and anonymized statistics — CMK adds operational complexity and cost, and it is not required for non-identified data, (2) not knowing that SQL MI TDE with CMK requires the key to be in a Key Vault in the same region as the SQL MI, (3) stating "all data is encrypted in transit" without specifying TLS 1.2 minimum and showing how to verify it with a specific CLI command or portal setting. Score overall Week 4 comprehension and update `memory/progress.md`. Update `memory/achievements.md` with "Completed Week 4 data architecture with HIPAA/DSPT governance layer." Assess readiness for Week 5 (Scalability and Resilience) and state what data architecture concept is the learner's weakest based on Days 1–5.

## Completion criteria
- Data asset classification table completed with all required columns
- TLS 1.2 configuration change identified with specific setting name
- CMK Key Vault configuration for SQL MI described with correct permission
- 5-bullet executive summary written targeting CTO and CMO (non-technical)
- CMK rotation safeguard and monitoring alert described
- AI scored the summary and assessed Week 4 readiness
- Achievements updated, weak areas recorded, progress updated
- Session log created in `memory/session_logs/`
