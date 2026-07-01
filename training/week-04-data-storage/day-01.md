# Week 04 Day 1 — Concept foundation: Azure Blob Storage tiers, replication, and healthcare data ingestion

## Goal
Understand Azure Blob Storage access tiers (Hot, Cool, Cold, Archive), replication options (LRS/ZRS/GRS/GZRS/RA-GZRS), and how to select the right combination for healthcare data that has strict retention, access frequency, and regional redundancy requirements. Apply this to a healthcare analytics platform receiving imaging data from 50 hospitals.

## Why this matters
Healthcare organizations routinely store medical imaging data (DICOM files, MRI/CT scans) that starts as frequently accessed active data and transitions to long-term retention for 10+ years (mandated by regulation). An architect who puts all data in Hot tier "for simplicity" generates €40,000/month in unnecessary storage costs for a 50-hospital platform. Choosing the wrong replication model results in either paying for redundancy you do not need or losing data during a regional disaster in a HIPAA/GDPR-regulated environment.

## Core concept

1. **Access tiers determine storage cost vs. retrieval cost trade-off.** Hot tier: highest storage price (~€0.018/GB/month), lowest read/write transaction cost — for data accessed daily. Cool tier: ~50% cheaper storage, higher transaction cost, 30-day minimum retention — for data accessed monthly. Cold tier: ~70% cheaper than Hot, 90-day minimum — for data accessed quarterly. Archive tier: ~95% cheaper storage, but retrieval takes 1–15 hours and costs ~€0.025/GB to rehydrate — for data retained for compliance, never actively accessed. Tiering can be applied per-blob or via lifecycle management policies.

2. **Lifecycle management automates tier transitions.** A policy rule transitions blobs from Hot → Cool after 30 days of no access, Hot → Archive after 365 days. For hospital imaging data: active studies (last 30 days) stay Hot, discharged patient data moves to Cool at 30 days, archive-grade records move to Archive at 365 days. This is the operationally correct pattern for healthcare.

3. **Replication choices balance cost, durability, and RTO.** LRS (3 copies in one datacenter) — cheapest, fails if datacenter burns. ZRS (3 AZs in one region) — survives zone failure, recommended minimum for production. GRS (LRS + async copy to secondary region) — survives regional disaster but secondary is read-only normally. GZRS (ZRS + async geo-replication) — best durability. RA-GZRS adds read access to the secondary. For healthcare: GZRS is the minimum for primary patient data; Archive blobs default to GRS at minimum.

4. **Blob storage has hard limits that affect healthcare platforms.** Single storage account: 5 PB capacity, 20,000 transactions/second. A 50-hospital platform generating 1 TB/day of imaging data will need multiple storage accounts — either by hospital or by data type. Storage account per hospital also simplifies RBAC, billing attribution, and customer-managed key (CMK) rotation.

5. **Immutability policies protect against ransomware and data tampering.** Healthcare archives must be tamper-proof. Blob Storage immutability (WORM — Write Once Read Many) via time-based or legal-hold policies prevents deletion or modification for the retention period. Once set, not even the storage account owner can delete data before the retention period expires. This satisfies HIPAA data integrity requirements.

## Learn — write notes answering these

- A DICOM file (MRI scan, ~500 MB) is uploaded when a patient has imaging done. It is accessed frequently for 60 days while the patient is under treatment, accessed occasionally for 1 year, then must be retained for 10 years but will almost never be accessed. Design the lifecycle policy transitions with specific day thresholds and cost impact estimates.
- What is the difference between GRS and RA-GRS, and in what specific healthcare scenario does the "RA" (read-access) prefix matter for application design?
- A storage account has ZRS replication. The primary datacenter in the region experiences a total failure (fire). What happens to reads and writes in the application, and what is the RTO/RPO for ZRS vs GZRS in this scenario?
- What is a storage account "shared access signature" (SAS), and why should a healthcare platform avoid using account-level SAS tokens in favor of user delegation SAS or managed identity access?

## Micro exercise

**Scenario:**
> **MedInsight Analytics** aggregates and analyzes patient imaging data from 50 hospitals across the UK and Germany. Data types: (1) active DICOM files (uploaded on imaging, accessed by radiologists for up to 90 days) — 2 TB new data per day, (2) processed analytics results (AI model outputs, much smaller — 50 GB/day) — accessed by clinicians for up to 1 year then archived, (3) regulatory archive (all original data retained 10 years by NHS/German BfArM mandate) — never accessed after year 1 unless audit request. Total projected storage at 3 years: 2.2 PB. The platform must survive a single Azure region failure with RPO < 4 hours, and data must be tamper-proof for regulatory compliance.

Your answer must include:
- A storage account design (how many accounts, separated by what criteria) with replication tier for each
- Lifecycle management policy for active DICOM files: tier transitions with day thresholds
- Estimated monthly storage cost at year 1 (roughly 365 TB total active data, 180 TB cool, 50 TB archive — use approximate per-GB prices)
- The specific Azure feature that enforces tamper-proof retention for the regulatory archive tier

## Reflection question
You chose GZRS replication for the active DICOM storage account. A cost-conscious CTO asks: "Why not LRS? Hospitals back up their own data anyway." What is the argument against relying on hospital-side backup for data durability in an Azure-hosted analytics platform, and what specific risk does LRS leave uncovered that GZRS addresses?

## Prior concept connection
Week 3 established that managed identities and RBAC control who can access data. The storage account design you create today must integrate with that identity model: each hospital's application should have its own managed identity with access scoped to only its designated storage container or account — not a shared SAS token. The "storage account per hospital" design pattern from this day directly enables the least-privilege RBAC model from Week 3 Day 2.

## AI coach instructions
Ask the learner to provide their answer before any feedback. Watch for: (1) recommending LRS for healthcare data without acknowledging the compliance implications — healthcare regulations often require geographic redundancy, (2) forgetting that Archive tier blobs cannot be read directly and require rehydration — if a learner says "just put all 10-year archive in Archive and read it when needed" without addressing the rehydration latency for audit requests, this is a design gap, (3) not addressing the tamper-proof requirement with immutability policies. After reviewing, probe: "MedInsight receives a ransomware attack that encrypts all blobs in the active DICOM storage account. Your GZRS replication would also replicate the encrypted blobs to the secondary region. What is your recovery strategy, and which Azure feature makes this scenario recoverable without paying the ransom?" Record any replication model confusion in `memory/mistakes.md`.

## Completion criteria
- Storage account design with replication tier justification provided
- Lifecycle policy with specific day thresholds stated
- Cost estimate with calculation approach shown
- Tamper-proof retention mechanism named
- AI reviewed from cloud architect, cost optimizer, and security reviewer perspectives
- Mistakes recorded and progress updated
