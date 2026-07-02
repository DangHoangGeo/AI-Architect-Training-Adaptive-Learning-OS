# Architecture Decision Records — Real-Time Fraud Detection

## ADR-001: Lightweight, low-latency model over higher-accuracy deep learning

### Status
Accepted

### Context
Fraud scoring runs inline in the charge path under a hard 40ms latency budget shared with feature lookup. A model that can't run within that budget provides no value regardless of its offline accuracy.

### Options considered
- Option A: Deep-learning model with potentially higher offline accuracy metrics.
- Option B: Gradient-boosted tree model (or similarly lightweight architecture) optimized for low-latency inference.

### Decision
Option B.

### Consequences
Positive: reliably meets the latency budget, keeps serving cost low, and is easier to explain to fraud ops and regulators than a deep model. Negative: may leave some accuracy on the table versus a larger model; mitigated by combining model output with rules-engine signals in the Decision Engine rather than relying on the model alone.

### Review date
When latency budget or infrastructure changes materially (e.g., a lower-latency serving platform becomes available).

---

## ADR-002: Three-tier decision output (allow / hold-for-review / block) instead of binary

### Status
Accepted

### Context
The business case explicitly weighs false-positive cost (blocked legitimate customers) as nearly as damaging as missed fraud. A binary decision forces the model to over- or under-commit on ambiguous cases.

### Options considered
- Option A: Binary allow/block decision based on a single threshold.
- Option B: Three-tier decision with a middle "hold-for-review" band routed to a human fraud ops reviewer.

### Decision
Option B.

### Consequences
Positive: directly reduces false-decline harm by routing ambiguous cases to human judgment instead of an automated guess; reviewed outcomes become high-quality labeled training data. Negative: requires an operational fraud ops review capacity that scales with review-queue volume, and introduces a small latency/delay for the customer on held transactions that must be clearly communicated.

### Review date
Quarterly, based on review-queue volume and reviewer capacity.

---

## ADR-003: Shared feature computation logic across real-time and offline pipelines

### Status
Accepted

### Context
Training/serving skew — where features are computed differently for model training than for live inference — is one of the most common causes of ML systems underperforming in production despite good offline metrics.

### Options considered
- Option A: Implement feature computation independently for the real-time serving pipeline and the offline training pipeline, each optimized for its own context.
- Option B: Shared feature computation logic used by both pipelines, with an automated feature-parity test in CI.

### Decision
Option B.

### Consequences
Positive: structurally prevents the most common silent failure mode in production ML systems; the feature-parity test catches any accidental divergence before deployment. Negative: constrains how independently the real-time and offline teams can optimize their respective pipelines, requiring coordination on any feature-logic change.

### Review date
At any incident where production model performance diverges from offline evaluation metrics.

---

## ADR-004: Automatic fallback to rules-engine-only scoring on ML system failure

### Status
Accepted

### Context
The Fraud Scoring Service sits inline in the Payment Gateway's charge path, which has its own hard availability guarantee (from the Payment Gateway design) that must not be compromised by a new ML system's failure modes.

### Options considered
- Option A: Block or queue transactions if the ML fraud system is unavailable, prioritizing fraud protection over charge-path availability.
- Option B: Automatically fall back to rules-engine-only scoring (degraded but functional fraud detection) if the ML system fails or exceeds its latency budget.

### Decision
Option B.

### Consequences
Positive: the charge path's availability guarantee is preserved regardless of ML system health; fraud detection degrades gracefully rather than the whole payments platform failing. Negative: fraud detection quality temporarily reverts to the pre-ML baseline during an outage, which must be monitored and treated as an incident in its own right, not silently tolerated.

### Review date
After the first real ML system outage post-launch.
