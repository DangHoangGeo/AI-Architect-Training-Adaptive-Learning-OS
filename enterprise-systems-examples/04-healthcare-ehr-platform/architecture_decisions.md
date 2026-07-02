# Architecture Decision Records — Unified EHR Platform

## ADR-001: Active-active multi-region deployment for medication ordering only

### Status
Accepted

### Context
Medication ordering (including allergy/interaction checking) is classified as a life-safety path — any downtime directly risks patient harm. The rest of the platform (scheduling, reporting) has normal enterprise availability needs.

### Options considered
- Option A: Active-passive with automated regional failover for the whole platform.
- Option B: Active-active across two Azure regions for medication ordering specifically; active-passive for everything else.

### Decision
Option B.

### Consequences
Positive: eliminates failover time entirely for the one path where minutes of downtime is unacceptable; keeps cost proportional to actual risk rather than applying the most expensive tier everywhere. Negative: active-active requires careful conflict handling for any writes that could occur in both regions simultaneously, adding design and testing complexity specifically to this module.

### Review date
After the first full regional failover drill.

---

## ADR-002: Master Patient Index with probabilistic matching and human review queue

### Status
Accepted

### Context
Patient records must be reconciled across 6 legacy systems with inconsistent identifiers. A false-positive match merges two different patients' clinical histories — a catastrophic, hard-to-reverse error.

### Options considered
- Option A: Fully automated matching using best-available deterministic identifiers (SSN/MRN where present).
- Option B: Master Patient Index service combining deterministic matching for high-confidence cases with a human review queue for ambiguous/low-confidence matches.

### Decision
Option B.

### Consequences
Positive: eliminates the worst failure mode (wrong-patient merge) by routing uncertainty to a human instead of guessing; builds an auditable identity graph that improves over time as more matches are reviewed. Negative: requires ongoing HIM staffing to handle the review queue, and clinicians may temporarily see an incomplete record flagged as "pending verification" rather than a fully merged one.

### Review date
Quarterly, based on review-queue volume and match-accuracy metrics.

---

## ADR-003: Dedicated FHIR API Gateway instead of direct database exposure

### Status
Accepted

### Context
Regulation requires HL7 FHIR R4 interoperability for specific resource types, exposed to external providers, labs, and patient-facing apps.

### Options considered
- Option A: Build FHIR resource mapping directly into the core clinical database's query layer.
- Option B: Dedicated FHIR API Gateway (Azure API Management) that translates between the internal data model and the external FHIR contract.

### Decision
Option B.

### Consequences
Positive: internal clinical data model can evolve independently of the external regulatory contract; all external-facing security controls (OAuth2 SMART-on-FHIR scopes, rate limiting, mutual TLS) are concentrated in one auditable layer, isolated from the core clinical path. Negative: adds a translation/mapping layer that must be kept in sync with both the internal model and evolving FHIR specification versions.

### Review date
At each major FHIR specification version update or new regulatory resource-type requirement.

---

## ADR-004: Break-glass access is never blocked, only logged and reviewed after the fact

### Status
Accepted

### Context
Emergency clinical situations require immediate record access, sometimes by a clinician outside the patient's assigned care team (e.g., a covering physician, an ER team for an unconscious patient).

### Options considered
- Option A: Require pre-approval or a second-factor confirmation step before granting break-glass access.
- Option B: Grant break-glass access immediately to any credentialed clinician, with mandatory justification and full audit logging reviewed within 24 hours.

### Decision
Option B.

### Consequences
Positive: no added friction in a genuine emergency, where seconds matter; every access is still fully attributable and reviewed. Negative: creates a window where access could theoretically be misused before review catches it; mitigated by automated anomaly detection on break-glass logs and firm compliance escalation for unjustified use.

### Review date
Annually, alongside the compliance team's HIPAA-equivalent access control audit.
