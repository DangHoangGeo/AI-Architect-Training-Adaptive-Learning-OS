# Week 04 Day 3 — Design exercise: Cosmos DB partitioning, consistency, and multi-region write

## Goal
Design a Cosmos DB data model for a healthcare analytics platform that serves real-time patient monitoring data across multiple regions, selecting the correct partition key, consistency level, and multi-region configuration to meet latency, throughput, and data integrity requirements. This is a full design exercise with product framing required before the technical solution.

## Why this matters
Cosmos DB's partition key is the most consequential single design decision in any Cosmos DB deployment, and it cannot be changed after the container is created without rebuilding the entire container. A healthcare platform that partitions patient monitoring data by `hospitalId` will create hot partitions for the largest hospital while leaving smaller hospital partitions cold and wasting provisioned throughput. Correcting a bad partition key in production — with 500 million rows and 50 hospitals connected — requires a live migration with zero downtime, which is an expensive emergency. Getting this right at design time is the difference between a scalable platform and a costly rewrite.

## Why this matters (continued)
Consistency level is equally consequential for healthcare: a "Session" consistency level means one user reading a patient's latest vital signs might see a stale value if they switch devices — in a clinical setting, a nurse on a tablet seeing "heart rate 72" when the monitor shows "heart rate 142" is a patient safety issue. Architects must know when eventual consistency is acceptable and when it is not.

## Core concept

1. **Partition key determines data distribution, throughput, and query efficiency.** A good partition key: high cardinality (many distinct values), even distribution of reads and writes, often included in your most common query filter. For patient monitoring: `patientId` is high cardinality and aligns with queries ("give me all vitals for patient X") but creates uneven distribution (ICU patients generate 100x more data than routine patients). `hospitalId` is lower cardinality (50 hospitals) — logical partitions can reach 20 GB max; a large hospital could hit this limit.

2. **Synthetic partition keys solve hot-partition and size problems.** Combine two fields: `hospitalId + patientId` as a composite key, or `hospitalId + date` to spread data across time-based partitions. Another pattern: append a random suffix (0–9) to the hospitalId to spread writes across 10 logical partitions while accepting that queries must fan out.

3. **Consistency levels trade latency for data accuracy — there are five levels.** Strong → Bounded Staleness → Session → Consistent Prefix → Eventual. For healthcare: patient vitals (life-critical) need at minimum "Session" consistency. Administrative data (appointment schedules) can use "Eventual." Billing records need "Bounded Staleness" or "Strong." Strong consistency in multi-region write is not supported — this is a hard architectural constraint for healthcare platforms with global write requirements.

4. **Multi-region write (multi-master) enables local writes with low latency but requires conflict resolution.** When two hospitals in different regions simultaneously write to the same patient record, Cosmos DB must resolve the conflict. Last-Write-Wins (LWW) using `_ts` (timestamp) is the default — whichever write has the later timestamp wins. For medical records, LWW is dangerous — a stale update from a slow network could overwrite a critical medication change. Custom conflict resolution via a stored procedure is the safe pattern for clinical data.

5. **Request Units (RUs) are the throughput abstraction — and the cost model.** A 1 KB document read costs 1 RU; a write costs 5 RU minimum. A container with 10,000 RU/s provisioned costs ~€0.008/RU/hour regardless of whether you use it. Autoscale provisions 10x the minimum RU (set 1,000 RU autoscale → scales 100–1,000 RU) and costs ~1.5x manual provisioning. For a healthcare platform with bursty ingest (shift changes) and quiet periods, autoscale is the cost-correct choice.

## Learn — write notes answering these

- A patient monitoring container stores vital signs documents. A typical document is 2 KB. A large ICU has 80 patients generating one vital-sign reading every 30 seconds. Calculate the minimum RU/s required for just write operations for this one hospital, and what partition key design ensures this hospital's writes don't hit a single-partition throughput limit.
- Explain the difference between "logical partition" and "physical partition" in Cosmos DB, and what happens when a logical partition exceeds the 20 GB limit.
- A nurse updates a patient's allergy list on a tablet in London while a doctor simultaneously updates the same record on a desktop in Dublin (different Azure regions, both with write enabled). With Last-Write-Wins conflict resolution, what is the risk, and what is the safer alternative?
- When would you use Cosmos DB instead of Azure SQL Database for a healthcare analytics platform? Give two scenarios where Cosmos DB is clearly superior and two where Azure SQL is the better choice.

## Product framing (write this first)

> **User pain:** MedInsight Analytics deployed Cosmos DB with `hospitalId` as the partition key 8 months ago. As more hospitals onboard, the largest hospital (King's College Hospital, London, 600-bed ICU) now has a single logical partition receiving 40% of all writes. Throughput is throttled, 429 errors are appearing in monitoring, and the clinical team reports that vital sign dashboards are laggy. A partition key migration is required, but the team is afraid of a multi-hour outtime during migration.
>
> **MVP constraint:** Redesign the partition key and migrate 800 million existing documents to the new schema within a 4-hour Saturday maintenance window. The new design must support multi-region write for EU (West Europe) and UK (UK South) regions. The clinical monitoring team requires that write latency stay below 50ms at P99. Budget for the migration: €5,000 in compute and data transfer costs.
>
> **Success metric:** Zero 429 (throttled) errors in the 48 hours following migration, P99 write latency below 50ms measured in Application Insights, and even partition distribution confirmed via Azure Monitor Cosmos DB metrics (no single partition exceeding 15% of total write RU).

## Micro exercise

**Scenario:**
> **MedInsight Analytics** collects three types of data in Cosmos DB: (1) real-time vital signs (heart rate, BP, SpO2, temperature) — one document per reading, 2 KB, one reading per patient per 30 seconds, 10,000 concurrent patients across 50 hospitals, (2) patient admission records — created once per admission, updated 5–10 times during stay, 10 KB each, 500 new admissions per day, (3) aggregate analytics results — written by AI processing jobs once per hour per hospital, 50 KB each, read by 200 concurrent clinicians. The platform must operate in West Europe (Netherlands) and UK South (London) with writes accepted in both regions. Patient vital signs are life-critical; admission records require strong auditability.

Your answer must include:
- For each of the three data types: recommended partition key with justification, consistency level with clinical reasoning, and whether multi-region write is enabled or single-region write with read replicas
- RU/s estimation for vital signs writes across 10,000 concurrent patients
- The conflict resolution strategy for admission records under multi-region write, and why LWW is insufficient
- One partition key anti-pattern you explicitly avoided and the specific failure mode it would have caused

## Reflection question
You chose Bounded Staleness consistency for admission records to balance auditability with performance. A compliance officer argues that "Bounded Staleness allows stale reads up to K versions — how can we audit which version a clinician saw at a specific time?" What Cosmos DB feature provides the immutable change audit trail that satisfies this compliance requirement, and what is its retention limit?

## Prior concept connection
Day 1 established that healthcare data needs immutability policies for tamper-proof retention. Day 2 established that different database services fit different workload shapes. Cosmos DB sits in the spectrum between Azure SQL (relational, strong consistency by default, complex queries) and Blob Storage (unstructured, no query, lifecycle management). The partition key design you make today directly determines whether the private endpoint from Week 2 Day 4 can be scoped to per-hospital network access — a single shared Cosmos DB account makes network-level hospital isolation harder than separate accounts.

## AI coach instructions
Do not provide the partition key recommendations until the learner writes theirs. Watch for: (1) choosing `patientId` alone without acknowledging that a multi-region write conflict on the same patientId record from two different regions requires conflict resolution — not just a good partition key, (2) choosing "Strong" consistency for vital signs without knowing it is not supported in multi-region write configurations — this is a hard Azure platform constraint, (3) not estimating RU/s (10,000 patients × 2 reads/minute writes × 5 RU/write = 100,000 RU/s minimum — any answer without a calculation is incomplete). After reviewing, probe: "If MedInsight's AI model running in Azure Machine Learning needs to read the last 1,000 vital sign readings for each patient for inference, what query pattern against your partition design minimizes RU cost, and what index would you add?" Record Cosmos DB consistency model gaps in `memory/weak_areas.md`.

## Completion criteria
- Product framing (pain, constraint, metric) written before the technical design
- Partition key chosen for each data type with specific justification
- Consistency level chosen with clinical reasoning for each data type
- Multi-region write vs. read replica decision made per data type
- RU/s estimate calculated (not just stated)
- Conflict resolution strategy for admission records specified
- AI reviewed from cloud architect, product manager, and security reviewer perspectives
- Mistakes and weak areas recorded, progress updated
