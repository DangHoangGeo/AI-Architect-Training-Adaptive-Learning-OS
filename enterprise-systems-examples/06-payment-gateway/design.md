# System Design — Payment Gateway

## 1. Problem statement
Ledgerline Payments needs a gateway that charges customers exactly once even across network failures with acquiring banks, routes around acquirer degradation transparently, scores transactions for fraud within a strict latency budget, and minimizes PCI DSS scope.

## 2. Users and stakeholders
- Merchant engineering teams (API integrators)
- Merchant finance/operations (reconciliation, disputes)
- Ledgerline risk/fraud team
- Ledgerline platform SRE

## 3. Functional requirements
- Accept a charge request with a merchant-supplied idempotency key.
- Tokenize card data at the earliest possible point.
- Route the charge to a primary acquiring bank, failing over to a backup on degradation.
- Score the transaction for fraud inline, before finalizing.
- Provide transaction status and reconciliation data to merchants.

## 4. Non-functional requirements
- Scale: ~40M/day in volume, ~450 transactions/sec average, ~3,000/sec peak (holiday shopping).
- Availability: 99.99% for the charge API.
- Latency: P99 end-to-end charge (including fraud check) under 600ms.
- Security: PCI DSS Level 1 compliance; card data tokenized before touching general application code.
- Compliance: Full transaction audit trail; regional data residency where required by acquiring bank agreements.
- Cost: Cost per transaction must remain competitive against market-rate processing fees.
- Operability: Any acquirer degradation must be visible and auto-mitigated within 2 seconds, not require manual intervention.

## 5. Constraints and assumptions
- Two acquiring bank relationships exist at launch; both expose REST APIs with different response semantics that must be normalized.
- Idempotency keys are merchant-supplied per the API contract (merchants are told this is mandatory, not optional).
- Fraud scoring must not become the latency bottleneck — a hard timeout applies even to the fraud check itself.

## 6. High-level architecture
```
Merchant systems
        |
        v
Azure Front Door (WAF, DDoS protection) -> API Management (merchant auth, rate limiting)
        |
        v
Tokenization Edge Service (Container Apps, PCI-scoped, isolated network segment)
   -> Azure Key Vault HSM-backed keys for token generation
   -> Card data leaves this boundary only as an opaque token
        |
        v
Charge Orchestration Service (Container Apps, outside PCI card-data scope after tokenization)
   -> Idempotency Store (Azure Cache for Redis: idempotency-key -> in-flight/completed state, short TTL)
   -> Fraud Scoring Service (inline call, hard 40ms timeout, rules engine + cached risk signals)
   -> Acquirer Router (circuit breaker per acquirer)
        -> Primary Acquiring Bank API
        -> Backup Acquiring Bank API (on primary circuit open)
   -> Azure SQL (transaction ledger, system of record, append-only)
        |
        v
Merchant Dashboard / Reconciliation API (Azure API Management -> read replicas)

Cross-cutting: Microsoft Entra ID (merchant API auth), Azure Monitor (acquirer health,
idempotency conflict rate), Azure Policy (PCI-scope network segmentation enforcement),
Key Vault (HSM-backed keys), dedicated PCI-scoped subnet with strict NSG rules.
```

## 7. Deep dives
- **Compute:** Tokenization Edge Service runs in a network-isolated, minimal-footprint deployment specifically to keep the PCI DSS audit boundary as small as possible — every other service in the platform never sees raw card data.
- **Network:** The PCI-scoped subnet has the tightest NSG rules in the platform; only the Tokenization Edge Service and its direct dependencies (Key Vault) sit inside it, everything downstream operates on tokens only.
- **Identity:** Merchant API access via Entra ID-issued OAuth2 client credentials, scoped per merchant with rate limits matching their contracted volume tier.
- **Data:** Redis-backed idempotency store keyed on the merchant-supplied idempotency key, storing in-flight and completed charge state with a TTL long enough to cover realistic retry windows (24 hours); Azure SQL append-only ledger is the definitive system of record for completed transactions, never overwritten.
- **Observability:** Acquirer health (latency, error rate, circuit-breaker state) is tracked per-acquirer in real time — this is the primary signal the routing layer and on-call both depend on.
- **Business continuity:** Backup acquirer relationship exists specifically as an operational continuity mechanism, not just a routing optimization — losing a primary acquirer must not mean losing the ability to process payments.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Double-charge prevention | Mandatory merchant-supplied idempotency key, checked against a Redis-backed store before any acquirer call | Deduplicate server-side based on transaction attributes (amount, merchant, timestamp window) | Server-side heuristic dedup can both miss real duplicates and falsely flag two legitimate similar transactions as duplicates; a mandatory idempotency key makes the guarantee exact and contractually explicit to merchants. |
| PCI scope reduction | Dedicated Tokenization Edge Service as the only component touching raw card data | Tokenize within the main Charge Orchestration Service | A single narrow, network-isolated tokenization boundary means the PCI DSS audit only needs to deeply scrutinize one small service, cutting audit cost and risk dramatically versus a broader scope. |
| Acquirer failover | Circuit breaker per acquirer with automatic failover to backup | Manual failover triggered by on-call during an acquirer incident | Acquirer API degradations can happen at any hour and must be invisible to merchants; automatic circuit-breaker failover removes the multi-minute delay of a human noticing and acting. |
| Fraud scoring placement | Synchronous, inline, hard-timeout-capped rules engine | Asynchronous fraud scoring after the charge is already processed | Blocking a genuinely fraudulent charge before money moves is far more valuable than flagging it afterward for reversal; the hard timeout ensures fraud scoring can never become the latency bottleneck even if the scoring service is unhealthy. |

**Cost:** Narrow PCI scope directly reduces both the initial certification cost and the ongoing annual audit cost, which is a material line item for a payments business at this volume.
**Security:** Card data existing in only one small, tightly controlled service is the single biggest security decision in the whole design — it bounds the blast radius of any future vulnerability to the smallest possible surface.
**Scalability:** Redis-backed idempotency checks and stateless Charge Orchestration Service instances scale horizontally with transaction volume without contention.
**Reliability:** Circuit-breaker-based acquirer failover is what actually delivers on "your payments keep working even when a bank's API doesn't," the core reliability promise sold to merchants.
**Operations:** Per-acquirer health dashboards mean on-call diagnoses an acquirer-side incident versus a Ledgerline-side incident in seconds, not by process of elimination.
**Product value:** Exactly-once charging and transparent failover are the two guarantees merchants actually pay for; every architectural investment here maps directly to a sellable reliability claim.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Acquiring bank API times out mid-charge | Ambiguous charge state (did it go through?) | Timeout on acquirer call, idempotency store shows "in-flight" | On retry (same idempotency key), the system queries the acquirer's own status API before resubmitting, never blindly retries the charge itself |
| Redis idempotency store unavailable | Cannot safely process new charges (risk of double-charge if bypassed) | Redis health check | Charge Orchestration Service fails closed — rejects new charge attempts with a clear retryable error rather than risking an unguarded double-charge |
| Fraud scoring service slow/unhealthy | Charges would be delayed past latency SLA | Fraud service latency metric approaching the 40ms budget | Hard timeout enforced; charge proceeds with a "review flagged" status using cached/default risk signals rather than blocking the transaction indefinitely |
| Both acquirers degraded simultaneously | Cannot process any charges | Dual circuit-breaker open state | Rare, but covered by an explicit incident-response runbook; merchant-facing status page updated automatically from the same health signal used internally |

## 10. Security design
- **AuthN:** Merchant OAuth2 client credentials via Entra ID; internal services via Managed Identity.
- **AuthZ:** Per-merchant scoped API access with contracted rate limits enforced at APIM.
- **Network exposure:** Only Front Door/APIM internet-facing; Tokenization Edge Service in an isolated subnet reachable only from APIM and only for tokenization calls.
- **Secrets:** HSM-backed keys in Key Vault for token generation; no raw card data or keys ever logged.
- **Encryption:** TLS 1.2+ everywhere; tokens are the only card-data representation outside the Tokenization Edge Service; full encryption at rest for the transaction ledger.
- **Audit:** Every charge, retry, and fraud decision logged immutably with the idempotency key as the correlation anchor, satisfying both PCI DSS and merchant dispute-resolution needs.

## 11. Cost model
- Main drivers: PCI-scoped infrastructure (kept intentionally small), Redis for idempotency store, Azure SQL for the transaction ledger, per-transaction acquirer fees (external, not infrastructure, but the dominant total cost).
- Reduction levers: Minimizing PCI scope directly reduces both infrastructure footprint and audit cost; autoscaling Charge Orchestration Service on transaction volume rather than static provisioning for peak.
- Cost per transaction is the key competitive metric — infrastructure efficiency directly funds competitive processing rates offered to merchants.

## 12. Evolution plan
- **10x scale:** Add acquirer relationships beyond 2 for geographic/currency coverage, extending the same circuit-breaker router pattern; consider regional Redis clusters if idempotency-store latency becomes geography-sensitive.
- **Enterprise adoption:** Replace rules-based fraud scoring with the ML-based inline scoring architecture from the Real-Time Fraud Detection example, keeping the same hard-timeout-capped integration point.
- **Multi-region:** Active-active charge processing across regions for merchants requiring in-region data residency, reusing the same tokenization-boundary and idempotency-store design per region.
