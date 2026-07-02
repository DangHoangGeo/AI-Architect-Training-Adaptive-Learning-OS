# PM Brief — Payment Gateway

## Customer problem
Merchants need a payment processor that guarantees a charge is applied exactly once even across network failures with acquiring banks, routes around acquirer outages without merchant-visible disruption, and blocks fraudulent transactions in real time — all while minimizing the PCI DSS compliance burden merchants themselves must carry.

## Target users
- **Primary:** Merchant engineering teams integrating the payment API.
- **Secondary:** Merchant finance/operations teams reconciling transactions and handling disputes.
- **Operational:** Ledgerline's own risk/fraud team and platform SRE team.

## Value proposition
A gateway that guarantees exactly-once charging semantics, transparent multi-acquirer failover, and inline fraud protection lets merchants integrate once and trust the platform with real money movement — the core value proposition of any payment processor.

## Success metrics
- Zero confirmed double-charge incidents.
- 99.99% gateway availability (merchant-facing).
- Fraud detection latency added to the charge path: under 50ms P99.
- Acquirer failover time (when one acquirer degrades): under 2 seconds, invisible to the merchant's customer.

## MVP scope
- Idempotency-key based charge API with tokenized card handling.
- Two-acquirer routing with automatic failover.
- Inline rules-based fraud scoring (velocity checks, blocklist) as the fraud MVP; ML-based scoring is a later phase.
- Merchant-facing dashboard for transaction status and reconciliation.

## Non-goals
- Supporting cryptocurrency or alternative payment rails (card + bank transfer only for now).
- Full ML-based fraud model (Phase 2 — see the Real-Time Fraud Detection example for the eventual architecture).
- Merchant-facing dispute/chargeback automation tooling (manual process retained initially).

## Risks
- **Product risk:** Merchants assume "it just works" reliability from day one; any early instability disproportionately damages trust in a payments product.
- **Technical risk:** Idempotency correctness under true network partition (not just simulated timeouts) is the hardest thing to test exhaustively before launch.
- **Delivery risk:** PCI DSS certification is a hard gate before processing any real card data — this is a compliance milestone the engineering timeline cannot bypass.
- **Adoption risk:** Merchants integrating from a legacy processor need a clear migration path and confidence in transaction-level parity before cutting over production volume.

## Roadmap
- **V1:** Idempotent charge API, two-acquirer failover, rules-based fraud, PCI DSS certified launch.
- **V2:** ML-based fraud scoring integrated inline (see Real-Time Fraud Detection example).
- **V3:** Additional acquirer relationships for geographic coverage; automated dispute/chargeback workflow.
