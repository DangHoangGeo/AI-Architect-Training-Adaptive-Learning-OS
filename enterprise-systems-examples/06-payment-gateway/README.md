# Payment Gateway

## Real-world scenario

**Ledgerline Payments** is a fintech processing card and bank-transfer payments on behalf of 3,000 merchant customers (think a Stripe/Adyen-style processor), handling ~$40M/day in transaction volume. Merchants integrate once and expect the gateway to route to the right acquiring bank, handle retries and network failures without ever double-charging a customer, detect fraud in real time, and stay within a tightly scoped PCI DSS boundary.

A single bug that double-charges customers across even a small fraction of transactions is both a direct financial liability (chargebacks, refunds) and a trust-destroying event for every merchant relying on the platform. Network failures between the gateway and acquiring banks are routine — the system must treat "did that charge actually go through?" as a first-class uncertainty to resolve, not an edge case.

## Why this is architecturally hard

- **Idempotency under network partition.** If a request to the acquiring bank times out, the gateway does not know if the charge succeeded; retrying naively risks a double charge, and giving up risks a lost payment the merchant thinks happened.
- **PCI DSS scope control.** Card data must be tokenized as early as possible so the smallest possible part of the system is in PCI scope, since every system that touches raw card data multiplies audit cost and risk.
- **Multi-acquirer routing with graceful degradation.** If one acquiring bank's API is degraded, transactions should route to a backup acquirer without merchant-visible disruption.
- **Real-time fraud scoring under strict latency budget.** Fraud checks must complete in the same request path as the charge itself, within tens of milliseconds, without becoming the bottleneck.

## What's in this folder

- `pm_brief.md` — the merchant-facing business case and reliability guarantees sold to customers.
- `design.md` — idempotency-key based charge flow, tokenization boundary, multi-acquirer routing with circuit breakers, and inline fraud scoring.
- `architecture_decisions.md` — why idempotency keys are mandatory at the API contract level, why tokenization happens at the edge, why multi-acquirer routing uses a circuit breaker pattern, and why fraud scoring is synchronous but budget-capped.

## Related training weeks

Week 7 (Security Architecture), Week 5 (Scalability & Resilience), Week 9 (AI System Design — fraud scoring).
