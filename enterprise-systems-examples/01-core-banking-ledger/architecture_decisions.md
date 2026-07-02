# Architecture Decision Records — Core Banking Ledger

## ADR-001: Event-sourced, append-only ledger model

### Status
Accepted

### Context
Regulators require that any historical account balance be reconstructable and that the transaction trail be tamper-evident. A traditional "current balance + audit log" model treats the log as secondary, which makes it easy for the authoritative balance to drift from the log during bugs or incidents.

### Options considered
- Option A: Mutable `accounts.balance` column with a separate audit log table.
- Option B: Event-sourced, append-only `ledger_entries` table as the sole source of truth; balances are always derived.
- Option C: Third-party ledger-as-a-service product.

### Decision
Option B. The ledger is append-only; balances are a projection, never a stored fact that can silently diverge from history.

### Consequences
Positive: audit trail is structurally guaranteed to match balances; reversals are new entries, not edits, which regulators strongly prefer. Negative: read performance requires maintained projections/snapshots, adding operational complexity (projection rebuild tooling, snapshot staleness monitoring).

### Review date
After the first full jurisdiction cutover (Phase 2 sign-off).

---

## ADR-002: Azure SQL over Cosmos DB for the ledger core

### Status
Accepted

### Context
The ledger requires atomic, multi-row transactions (a posting always writes a matched debit and credit) with strong consistency, and each jurisdiction already requires data to stay within its own region for legal reasons.

### Options considered
- Option A: Cosmos DB with strong consistency mode and multi-region writes.
- Option B: Azure SQL, single region per jurisdiction, with geo-redundant backup for DR.
- Option C: Self-managed PostgreSQL on VMs for full control over the transaction engine.

### Decision
Option B. Cosmos DB's global distribution is unneeded since data residency forces per-jurisdiction regionality anyway, and Azure SQL's native multi-row ACID transactions are a direct, low-risk fit for double-entry postings. Self-managed Postgres was rejected to avoid taking on OS/patching operational burden the team isn't staffed for.

### Consequences
Positive: simpler transaction semantics, lower operational risk, existing team SQL expertise reused. Negative: horizontal write scaling requires sharding by jurisdiction/account range rather than Cosmos DB's built-in partitioning; revisit if a single jurisdiction's volume exceeds Azure SQL Hyperscale limits.

### Review date
When any single jurisdiction approaches 500M postings/day.

---

## ADR-003: Strangler-fig migration with mandatory shadow mode

### Status
Accepted

### Context
The mainframe cannot be replaced in a single cutover: regulators require evidence of correctness before the new system becomes authoritative, and a ledger error directly affects customer funds.

### Options considered
- Option A: Big-bang cutover on a chosen date after internal testing.
- Option B: Strangler-fig migration — new system runs in shadow mode alongside the mainframe, product-line by product-line, with automated variance detection gating promotion to system-of-record.

### Decision
Option B.

### Consequences
Positive: regulator-acceptable evidence trail; failures are caught in shadow mode with zero customer impact; incremental risk exposure. Negative: significantly longer overall migration timeline and the cost of running both systems in parallel for 6+ months per product line.

### Review date
Per product-line cutover milestone.

---

## ADR-004: Per-jurisdiction deployment instead of shared multi-tenant infrastructure

### Status
Accepted

### Context
Data residency law requires jurisdiction-specific data storage and, in practice, jurisdiction-specific operational boundaries for audit purposes.

### Options considered
- Option A: Single shared AKS cluster / database serving all jurisdictions with logical (row-level) isolation.
- Option B: Separate resource group, database, and Container Apps environment per jurisdiction, sharing only the deployment pipeline and monitoring dashboards.

### Decision
Option B.

### Consequences
Positive: clean audit boundary, no cross-jurisdiction blast radius for incidents or compliance findings, straightforward mapping to legal requirements. Negative: ~2x fixed infrastructure cost versus a shared model, more deployment pipeline complexity to manage N parallel environments consistently.

### Review date
When adding the 4th jurisdiction — re-evaluate whether a templated Bicep module still scales operationally.
