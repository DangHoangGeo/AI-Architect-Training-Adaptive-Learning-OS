# Architecture Decision Records — Payment Gateway

## ADR-001: Mandatory merchant-supplied idempotency key for charge deduplication

### Status
Accepted

### Context
Network failures between the gateway and acquiring banks are routine. A naive retry after a timeout risks double-charging; giving up risks silently losing a legitimate payment.

### Options considered
- Option A: Server-side heuristic deduplication based on transaction attributes (merchant, amount, timestamp window).
- Option B: Require merchants to supply an idempotency key per charge attempt, checked against a Redis-backed store before any acquirer call is made.

### Decision
Option B.

### Consequences
Positive: exact, contractually explicit deduplication guarantee with no false positives/negatives from heuristics; industry-standard pattern merchants already expect from a modern payment API. Negative: pushes a correctness requirement onto merchant integrations (they must generate and reuse the key correctly on retry) — requires clear documentation and API-level validation to catch misuse early.

### Review date
After the first 90 days of production traffic — review idempotency-key misuse rate from merchant integrations.

---

## ADR-002: Dedicated, network-isolated Tokenization Edge Service

### Status
Accepted

### Context
PCI DSS compliance cost and audit scope scale with how much of the system touches raw card data. The business needs to minimize both certification cost and breach blast radius.

### Options considered
- Option A: Tokenize card data within the main Charge Orchestration Service alongside other business logic.
- Option B: Dedicated, network-isolated Tokenization Edge Service that is the only component in the entire platform that ever sees raw card data.

### Decision
Option B.

### Consequences
Positive: PCI DSS audit scope is confined to one small, well-understood service; a vulnerability anywhere else in the platform cannot expose raw card data because it was never present there. Negative: adds an internal network hop and a service boundary to maintain, plus stricter change-control process for that one service given its compliance sensitivity.

### Review date
At each annual PCI DSS re-certification.

---

## ADR-003: Circuit-breaker-based automatic acquirer failover

### Status
Accepted

### Context
Acquiring bank API degradations happen periodically and unpredictably; merchants expect payments to keep working regardless.

### Options considered
- Option A: Manual failover triggered by on-call engineers after detecting an acquirer incident.
- Option B: Automatic circuit breaker per acquirer that trips on error-rate/latency thresholds and routes to a backup acquirer without human intervention.

### Decision
Option B.

### Consequences
Positive: failover happens in seconds instead of the minutes a human response would take, directly protecting the merchant-facing reliability guarantee. Negative: requires careful threshold tuning to avoid flapping (rapid open/close cycling) between acquirers, and a backup acquirer relationship must be maintained and kept "warm" (tested regularly) even though it handles a minority of traffic.

### Review date
After the first real acquirer incident post-launch — validate actual failover behavior against the design intent.

---

## ADR-004: Synchronous, hard-timeout-capped inline fraud scoring

### Status
Accepted

### Context
Fraud must be caught before money moves, but fraud scoring cannot be allowed to become the bottleneck or single point of failure for the entire charge path.

### Options considered
- Option A: Asynchronous fraud scoring that flags transactions for reversal after the charge has already been processed.
- Option B: Synchronous fraud check inline in the charge path, with a hard timeout (40ms) after which the charge proceeds using cached/default risk signals and is flagged for review.

### Decision
Option B.

### Consequences
Positive: blocks genuinely fraudulent charges before money moves in the common case, while the hard timeout guarantees fraud scoring can never take down the charge path if the scoring service degrades. Negative: transactions processed during a fraud-service slowdown get a lower-confidence risk assessment, requiring a separate downstream review queue to catch what the timeout-path missed.

### Review date
When ML-based fraud scoring (Phase 2) replaces the rules engine — re-validate the latency budget still holds.
