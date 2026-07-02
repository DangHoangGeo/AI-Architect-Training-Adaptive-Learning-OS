# System Design — Core Banking Ledger

## 1. Problem statement
Meridian Trust needs a modern ledger core that posts financial transactions with mainframe-grade correctness while being fast enough for new API-driven products. It must run in shadow mode alongside the existing mainframe for at least 6 months before becoming the system of record.

## 2. Users and stakeholders
- Product engineering teams (build features on top of the ledger API)
- Compliance/audit teams (query immutable history)
- Ledger operations/SRE (monitor postings, investigate discrepancies)
- Regulators (indirect stakeholder — audit trail must satisfy examination)
- Bank customers (indirect — correctness of their balance)

## 3. Functional requirements
- Post debit/credit entries as atomic, double-entry transactions.
- Reconstruct any account balance as of any point-in-time from history alone.
- Support reversal/correction postings without mutating or deleting history.
- Expose a query API for current balance and transaction history.
- Run in shadow mode: mirror every mainframe posting and flag variances.

## 4. Non-functional requirements
- Scale: 150M postings/day peak (~1,700/sec average, ~10,000/sec burst at month-end).
- Availability: 99.99% for posting path (core banking is Tier-0).
- Latency: P99 posting confirmation < 300ms.
- Security: Full encryption at rest/in transit; least-privilege access to raw ledger tables.
- Compliance: Immutable audit trail, data residency per jurisdiction, 7-year retention.
- Cost: Predictable, workload-isolated cost per jurisdiction (regulatory reporting requires cost attribution).
- Operability: Every posting traceable end-to-end with a correlation ID; on-call team must diagnose a variance in under 15 minutes.

## 5. Constraints and assumptions
- Cannot modify the mainframe's posting logic; the new system observes and mirrors it during shadow mode.
- Must support at least 2 jurisdictions with independent data residency at launch, more later.
- No "big bang" cutover — regulator requires a documented parallel-run with sign-off.
- Existing team has strong C#/.NET skills; the org runs primarily on Azure.

## 6. High-level architecture
```
Mainframe (existing system of record)
     |  (CDC / message replication)
     v
Azure Service Bus (ordered, partitioned by account ID)
     |
     v
Ledger Posting Service (Azure Container Apps, per-jurisdiction deployment)
     |--> Event Store (Azure SQL, append-only ledger_entries table, partitioned by account)
     |--> Projection workers --> Balance snapshots (Azure SQL, read-optimized)
     |--> Variance detector --> compares mainframe balance vs. projected balance
     v
Compliance Query API (Azure API Management -> Container Apps)
     v
Audit/reporting consumers (internal only, Private Endpoint + Managed Identity)

Cross-cutting: Azure Key Vault (secrets/keys), Microsoft Entra ID (workload identity),
Azure Monitor + Log Analytics (posting traces), Azure Policy (region pinning per jurisdiction).
```
Each jurisdiction gets its own resource group and database to satisfy data residency; a shared control-plane (deployment pipeline, monitoring dashboards) spans all of them.

## 7. Deep dives
- **Compute:** Azure Container Apps for the posting service — scales on Service Bus queue depth, and per-jurisdiction isolation is a straightforward deployment-per-region model rather than a shared multi-tenant compute layer.
- **Network:** Private Endpoints for SQL and Service Bus; posting service has no public ingress — it only consumes from Service Bus and serves the Compliance API through APIM over a private VNet integration.
- **Identity:** Managed Identity for all service-to-service calls; no connection strings in code. Compliance API requires Entra ID app roles (`ledger.read`, `ledger.audit`) — no shared API keys.
- **Data:** Azure SQL (not Cosmos DB) for the ledger core — see ADR-002. Append-only `ledger_entries` table is the source of truth; a separate `balance_snapshots` table is a rebuildable projection, never authoritative.
- **Observability:** Every posting carries a correlation ID that threads through Service Bus message properties, SQL row metadata, and Application Insights traces, so a variance can be traced from mainframe event to final balance in one query.
- **Business continuity:** Geo-redundant backup for the ledger database (regulatory requirement: 7-year retention, point-in-time restore to any second in the last 35 days). Active-passive DR to a secondary Azure region within the same jurisdiction's legal boundary.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Data model | Event-sourced, append-only ledger | Mutable "current balance" table with audit log bolted on | Regulators need balance reconstruction from history; append-only makes tampering structurally harder and audit trivial, at the cost of needing projection rebuilds for read performance. |
| Database | Azure SQL (single-region per jurisdiction) | Cosmos DB (global distribution) | Ledger postings need strict ACID transactions across related rows (double-entry debit+credit); Cosmos DB's tunable consistency adds correctness risk here that global distribution doesn't justify — jurisdictions already force per-region data anyway. |
| Migration strategy | Strangler fig with shadow-mode parallel run | Big-bang cutover | Regulatory requirement forces parallel run; strangler fig also lets the team validate posting-rule parity incrementally instead of one high-stakes cutover night. |
| Compute | Container Apps (per-jurisdiction deployment) | Shared multi-tenant AKS cluster | Regulatory data residency makes shared infrastructure a compliance and blast-radius risk; per-jurisdiction deployment costs more in fixed overhead but keeps audits and incident response scoped. |

**Cost:** Per-jurisdiction isolation increases baseline infra cost (~2x a shared-cluster model) but is non-negotiable given residency law; cost is controlled by right-sizing Container Apps min replicas per jurisdiction traffic, not by sharing infrastructure.
**Security:** Append-only ledger + Managed Identity + Private Endpoints reduces the attack surface to "who can write to Service Bus," which is tightly scoped to the CDC replication process.
**Scalability:** Service Bus partitioning by account ID and Container Apps KEDA scaling handle the 10,000/sec month-end burst without over-provisioning for average load.
**Reliability:** Shadow-mode variance detection is itself a reliability mechanism — it turns "silent ledger drift" into an alertable, measurable signal before the new system ever becomes authoritative.
**Operations:** Correlation-ID tracing end-to-end is what makes a 15-minute variance diagnosis achievable; without it, on-call would need to manually correlate mainframe logs with Azure logs.
**Product value:** Faster, API-driven product development is the entire business case — every architectural choice here is justified by removing the mainframe as the bottleneck, not by technical elegance for its own sake.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Service Bus partition lag during month-end burst | Posting confirmations delayed beyond 300ms SLA | Queue depth + latency alerts in Azure Monitor | Auto-scale Container Apps on queue depth; pre-warm capacity ahead of known month-end dates |
| Mainframe CDC feed drops a message | Ledger silently misses a transaction (shadow mode) | Variance detector flags mismatched balance | Replay from mainframe's own audit log; variance detector blocks promotion to system-of-record until resolved |
| Regional Azure SQL outage | Posting halts for that jurisdiction | Availability alert, failed health checks | Geo-redundant failover to paired region within same legal boundary; RPO ≤ 5 min, RTO ≤ 1 hr |
| Bad deploy introduces a posting-rule bug | Incorrect balances for affected accounts | Automated posting-rule regression suite + shadow-mode variance detector as a second safety net | Feature-flagged rollback; because ledger is append-only, corrections are new reversal entries, never edits |

## 10. Security design
- **AuthN:** Microsoft Entra ID for all human and service access; no local SQL logins.
- **AuthZ:** Role-based app roles (`ledger.read`, `ledger.audit`, `ledger.post`) enforced at the API Management and application layer; posting rights restricted to the CDC replication identity only.
- **Network exposure:** No public endpoints on the database or Service Bus; APIM is the only internet-facing surface, and even that requires Entra ID auth plus mTLS for high-privilege compliance queries.
- **Secrets:** All connection details resolved via Managed Identity; any remaining secrets (e.g., mainframe CDC credentials) live in Key Vault with access policies scoped to a single identity.
- **Encryption:** TDE at rest on Azure SQL, TLS 1.2+ in transit everywhere, customer-managed keys in Key Vault for the ledger database given regulatory sensitivity.
- **Audit:** Every read of the compliance API is itself logged immutably — auditors can be audited.

## 11. Cost model
- Main drivers: Azure SQL compute tier (sized for peak burst, not average), Container Apps replica-hours, Service Bus premium tier (needed for ordering guarantees + larger message size).
- Reduction levers: KEDA-based scale-to-near-zero for the posting service outside business hours in that jurisdiction's time zone; Azure SQL serverless tier for lower-traffic jurisdictions at launch, moving to provisioned once volume justifies it.
- Cost is reported per-jurisdiction to finance and compliance, matching the regulatory requirement to demonstrate cost/resource segregation between jurisdictions.

## 12. Evolution plan
- **10x scale (1.5B postings/day):** Move from single-writer-per-partition Service Bus to a sharded ingestion layer (multiple Service Bus namespaces), and consider Azure SQL Hyperscale or a purpose-built ledger database if projection-rebuild time becomes a bottleneck.
- **Enterprise adoption (all product lines):** Extend the event schema to a shared "posting envelope" so new products (BNPL, instant payments) reuse the same ledger core instead of forking it.
- **Multi-region/multi-jurisdiction:** Formalize the per-jurisdiction deployment as a Bicep module parameterized by region and data-residency policy, so onboarding a new country is a configuration change, not a redesign.
