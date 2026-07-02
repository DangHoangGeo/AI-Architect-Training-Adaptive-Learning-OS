# System Design — Real-Time ML Fraud Detection

## 1. Problem statement
Ledgerline Payments needs to replace its rules-based fraud check with an ML-based inline scoring system that improves both fraud capture and false-positive rate, computing real-time features and serving a model prediction within the existing 40ms latency budget in the charge path, with safe fallback behavior and a feedback loop for retraining.

## 2. Users and stakeholders
- Fraud operations team (reviews flagged transactions)
- ML/data engineering team (owns model lifecycle)
- Merchants and their customers (experience the outcome)
- Charge Orchestration Service (the caller, from the Payment Gateway design)

## 3. Functional requirements
- Compute real-time behavioral/velocity features for a transaction at request time.
- Serve a model prediction inline within the charge path.
- Classify each transaction into allow / hold-for-review / block.
- Route hold-for-review transactions to a fraud ops queue with feature-level context.
- Feed reviewed outcomes back into the training data pipeline.

## 4. Non-functional requirements
- Scale: same transaction volume as the Payment Gateway (~450/sec average, ~3,000/sec peak).
- Availability: fraud scoring must never block the charge path even if it is unavailable (fail-safe to rules engine).
- Latency: feature computation + model inference under 40ms P99 combined.
- Security: feature store may contain sensitive behavioral data; access scoped to fraud/ML systems only.
- Compliance: model decisions affecting a financial transaction must be explainable enough for dispute resolution and regulatory inquiry.
- Cost: feature store and serving infrastructure cost must be justified against fraud-loss reduction.
- Operability: model drift must be detected automatically, not discovered via a fraud-loss spike weeks later.

## 5. Constraints and assumptions
- Must integrate into the existing Charge Orchestration Service's fraud-check call point from the Payment Gateway design, respecting its hard timeout.
- Feature parity between training and serving is a hard requirement — features must be computed by shared code/logic, not reimplemented separately for batch training vs. real-time serving.
- Rules engine remains available as a fallback and as an additional input signal to the model itself.

## 6. High-level architecture
```
Charge Orchestration Service (from Payment Gateway design)
        |  (transaction event, hard 40ms budget)
        v
Fraud Scoring Service (Container Apps)
   -> Real-Time Feature Store (Azure Cache for Redis: precomputed rolling
      aggregates - velocity counts, recent merchant categories, device/IP
      reputation - updated incrementally via stream processing)
   -> Model Serving Endpoint (Azure Machine Learning managed online endpoint,
      or Container Apps hosting a lightweight model runtime for lowest latency)
   -> Decision Engine: combines model score + rules engine signals ->
      allow / hold-for-review / block
        |
        |-- allow/block -> immediate response to Charge Orchestration Service
        |-- hold-for-review -> Service Bus -> Fraud Ops Review Queue (internal app)
        v
Feature Computation Pipeline (Azure Stream Analytics / Event Hubs consumer)
   reads transaction event stream -> updates Redis rolling aggregates in real time
   -> also writes to Data Lake for offline training feature parity

Offline: Training Pipeline (Azure Machine Learning) reads Data Lake features +
fraud ops labeled outcomes -> retrains model -> Model Registry -> deployed to
Model Serving Endpoint via a canary rollout.

Cross-cutting: Azure Monitor (model drift metrics, latency budget dashboard),
Microsoft Entra ID (fraud ops access), Key Vault, Azure Policy.
```

## 7. Deep dives
- **Compute:** Model Serving Endpoint is deliberately chosen for lowest-latency inference (a lightweight model architecture, e.g., gradient-boosted trees rather than a large deep model) — model complexity is explicitly traded against the hard latency budget rather than maximizing offline accuracy metrics alone.
- **Network:** Fraud Scoring Service sits entirely within the internal network path already used by the Payment Gateway; no new external exposure is introduced.
- **Identity:** Fraud ops review queue access scoped via Entra ID roles distinct from general merchant-facing access; feature store data is not accessible outside the fraud/ML service boundary.
- **Data:** The same feature computation logic is used for both real-time serving (via the streaming pipeline updating Redis) and offline training (via the same logic applied to historical Data Lake data) — this shared-logic requirement is the direct mitigation for training/serving skew, the most common cause of ML systems underperforming in production relative to offline metrics.
- **Observability:** Model drift is monitored via both prediction-distribution shift (is the model suddenly scoring very differently than its historical baseline?) and outcome-based metrics (fraud ops override rate, confirmed-fraud rate on allowed transactions) — a distribution-shift alert can fire before actual fraud losses are seen.
- **Business continuity:** If the Model Serving Endpoint is unavailable or exceeds its latency budget, the Decision Engine falls back to rules-engine-only scoring automatically — fraud detection degrades in quality but the charge path is never blocked by an ML system failure.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Model complexity | Lightweight, low-latency model (gradient-boosted trees) | Larger deep-learning model with potentially higher offline accuracy | Inference latency is a hard constraint in this system (40ms budget shared with feature lookup); a marginally more accurate but too-slow model provides no value if it can't run inline, so latency-appropriate model selection takes priority over maximizing offline accuracy. |
| Decision output | Three-tier (allow/hold-for-review/block) | Binary allow/block | Fraud models have inherent uncertainty; a binary decision forces either too many false declines (angry legitimate customers) or too much missed fraud, whereas a middle "review" tier routes genuinely ambiguous cases to a human, directly addressing the false-positive cost identified in the business case. |
| Feature computation | Shared feature logic across real-time serving and offline training pipelines | Separately implemented feature logic optimized independently for each pipeline | Separate implementations are the classic source of training/serving skew, where a model performs well offline but poorly in production because the features it sees at inference don't match what it was trained on; shared logic costs more upfront engineering discipline but removes an entire class of silent production bugs. |
| Failure handling | Automatic fallback to rules-engine-only scoring on any ML system failure | Block or queue all transactions if the ML system is unavailable | The charge path's availability guarantee (from the Payment Gateway design) takes priority — degraded fraud detection during an ML system outage is an acceptable trade-off against blocking all payments platform-wide. |

**Cost:** A lightweight, latency-appropriate model architecture also tends to be cheaper to serve at scale than a large deep-learning model, aligning cost efficiency with the latency requirement rather than trading one against the other.
**Security:** Feature store data (behavioral/velocity signals) is treated as sensitive and access-scoped separately from general application data, since it could itself be a target for adversaries trying to understand and evade the model.
**Scalability:** Redis-backed rolling aggregates scale with transaction volume the same way the Payment Gateway's own infrastructure does, since it sits in the identical request path.
**Reliability:** The rules-engine fallback is the key reliability mechanism — it converts "the ML system might fail" from a payments-outage risk into a fraud-detection-quality degradation, a much smaller blast radius.
**Operations:** Distribution-shift-based drift monitoring gives the ML team an early warning before a fraud-pattern shift shows up as an actual loss spike, turning model maintenance into a proactive rather than reactive discipline.
**Product value:** Simultaneously improving fraud capture and reducing false positives directly targets both cost lines identified in the business case — fraud loss and false-decline churn — rather than trading one for the other.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Model Serving Endpoint latency exceeds budget | Charge path would be delayed | Real-time latency metric on the Fraud Scoring Service call | Hard timeout triggers automatic fallback to rules-engine-only scoring for that request; endpoint auto-scales based on the same signal |
| Feature Store (Redis) staleness or unavailability | Model receives incomplete/stale features, degrading prediction quality | Feature freshness metric per feature key | Model falls back to using only features it can compute from the current transaction alone (no historical aggregation), a documented degraded mode with a known accuracy impact |
| Model drift (fraud patterns shift) | Fraud capture rate silently declines over weeks | Prediction-distribution shift alert + fraud ops override-rate trend | Triggers expedited retraining cycle; interim rules-engine weighting can be increased in the Decision Engine's combined score while retraining completes |
| Training/serving feature mismatch introduced by a code change | Model underperforms in production despite good offline evaluation | Automated feature-parity test comparing real-time vs. batch feature computation output on a shared test set, run in CI | Deployment pipeline blocks promotion if feature-parity test fails |

## 10. Security design
- **AuthN:** Fraud ops access via Entra ID SSO; internal service-to-service via Managed Identity.
- **AuthZ:** Feature store and model serving endpoint accessible only to the Fraud Scoring Service identity; fraud ops review queue scoped to a dedicated `fraud.reviewer` role.
- **Network exposure:** Entirely internal to the payments platform's network boundary; no new external endpoints introduced.
- **Secrets:** Model registry and feature store connection details in Key Vault via Managed Identity.
- **Encryption:** TLS in transit, encryption at rest for the feature store and Data Lake given the sensitivity of behavioral fraud-signal data.
- **Audit:** Every scoring decision logged with the feature values and model version used, supporting both dispute resolution (why was this transaction blocked?) and regulatory inquiry into automated decision-making.

## 11. Cost model
- Main drivers: Real-time feature computation pipeline (Stream Analytics/Event Hubs), Redis feature store, Model Serving Endpoint compute, offline training pipeline (Azure Machine Learning compute for periodic retraining).
- Reduction levers: Lightweight model architecture keeps serving cost low; feature store TTLs limit Redis memory footprint to only the rolling windows actually needed by the model.
- The business case is funded directly against measured fraud-loss reduction and false-decline reduction, both of which are tracked and reported against this infrastructure cost.

## 12. Evolution plan
- **10x scale:** Feature store sharding by card/account ID if Redis throughput becomes a bottleneck; consider a dedicated low-latency feature-serving product if the feature set grows substantially more complex.
- **Enterprise adoption (more merchants/products):** Extend the feature set to include merchant-category-specific behavioral baselines as Ledgerline's merchant base diversifies.
- **Multi-region:** Regional feature stores with cross-region aggregation for global card-velocity signals, if Ledgerline expands into new geographies with local processing requirements.
