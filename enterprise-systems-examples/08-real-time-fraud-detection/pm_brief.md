# PM Brief — Real-Time ML Fraud Detection

## Customer problem
The current rules-based fraud system catches only ~60% of fraud while falsely blocking 1 in 400 legitimate transactions, causing both direct fraud losses and a steady stream of angry customers whose legitimate purchases get declined — a churn driver nearly as costly as the fraud itself.

## Target users
- **Primary:** Ledgerline's risk/fraud operations team who review flagged transactions.
- **Secondary:** Merchants and their customers, who experience the outcome (approved, declined, or held for review) directly.
- **Operational:** ML/data engineering team who own model training, deployment, and monitoring.

## Value proposition
An inline ML fraud model that improves both fraud capture rate and false-positive rate simultaneously — rather than trading one for the other — directly reduces fraud losses and the customer-churn cost of wrongly blocked legitimate transactions.

## Success metrics
- Fraud capture rate improved from ~60% to ≥85%.
- False-positive rate reduced from 1-in-400 to under 1-in-1,500 legitimate transactions.
- Added latency to the charge path: under 40ms P99 (matching the existing budget from the Payment Gateway design).
- Model drift detected and flagged within 24 hours of a significant fraud-pattern shift.

## MVP scope
- Real-time feature store computing velocity/behavioral features within the latency budget.
- Inline model serving with automatic fallback to the existing rules engine on any failure.
- Three-tier decision output: allow, hold-for-review, block.
- Fraud ops review queue for the hold-for-review tier, feeding labeled outcomes back into retraining data.

## Non-goals
- Fully automating fraud ops review (human review remains for the middle tier in this phase).
- Cross-institution fraud data sharing/consortium integration (future consideration).
- Replacing the rules engine entirely (it remains as the fallback and as a complementary signal, not fully retired).

## Risks
- **Product risk:** An early model version that is overly aggressive could spike false positives before fraud ops has enough tuning data — requires a careful, monitored rollout ramp.
- **Technical risk:** Training/serving feature skew is the single most likely cause of the model underperforming in production relative to offline evaluation metrics.
- **Delivery risk:** Real-time feature computation at the required latency is a genuinely hard systems problem, not just a modeling problem — underestimating this risks the launch date.
- **Adoption risk:** Fraud ops team must trust and act on model outputs; a "black box" score with no explanation will get overridden or ignored in practice, so some feature-level explainability is required for the review-queue UI.

## Roadmap
- **V1:** Feature store + inline model serving with rules-engine fallback, three-tier decisioning, fraud ops review queue.
- **V2:** Automated drift detection and retraining pipeline; feature-level explainability in the review UI.
- **V3:** Expand feature set with cross-merchant behavioral signals; explore consortium data sharing for improved detection.
