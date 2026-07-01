# Real-Time Fraud Detection

## Real-world scenario

**Ledgerline Payments** (the same fintech from the Payment Gateway example) is graduating from rules-based fraud checks to a machine-learning fraud scoring system. The business case: rules-based fraud checks currently catch ~60% of fraud and generate a false-positive rate that blocks 1 in 400 legitimate transactions — angry legitimate customers whose cards get declined are almost as costly as fraud itself, in churn and support load.

The new system must score every transaction against an ML model **inline**, in the same request path as the charge, within a strict latency budget, using features computed from both the current transaction and the customer's recent history — all while the model itself needs regular retraining as fraud patterns evolve and adversaries actively adapt to whatever the current model catches.

## Why this is architecturally hard

- **Feature computation at request time, under a hard latency budget.** "How many transactions has this card made in the last 10 minutes across all merchants?" is a real-time aggregation query that must return in single-digit milliseconds.
- **Training/serving skew.** The model must see, at inference time, features computed the identical way they were computed during training — a subtle mismatch here is one of the most common causes of ML systems silently underperforming in production.
- **Adversarial, non-stationary problem.** Fraud patterns actively evolve to evade whatever the current model catches, unlike a typical ML problem with a stable underlying distribution.
- **False positives have a real cost too.** Unlike a typical recommendation system, an over-aggressive fraud model directly damages revenue and trust by blocking legitimate customers, so the system needs a human-reviewable middle tier, not just allow/block.

## What's in this folder

- `pm_brief.md` — the business case balancing fraud loss reduction against false-positive customer harm.
- `design.md` — real-time feature store architecture, inline model serving with fallback, and the training/monitoring feedback loop.
- `architecture_decisions.md` — why a dedicated feature store is required, why model serving falls back to the rules engine on failure, why a three-tier decision (allow/review/block) is used instead of binary, and how model drift is detected.

## Related training weeks

Week 9 (AI System Design), Week 6 (Observability & Operations), Week 5 (Scalability & Resilience).
