# Healthcare EHR Platform

## Real-world scenario

**Cascade Health Network** operates 14 hospitals and 60 outpatient clinics. It's replacing a patchwork of 6 different Electronic Health Record (EHR) systems (acquired through mergers) with a single unified platform. Clinicians in an ER cannot wait 10 seconds for a patient's allergy list to load — that delay has caused a real near-miss medication error during the pilot rollout. Regulators require the system to support HL7 FHIR interoperability so patients and other providers can access records, and any downtime in the medication-ordering module is a direct patient-safety incident, not just an SLA breach.

This is the archetype of a system where **availability is a life-safety property**, not a business-continuity nice-to-have, and where "move fast" trades directly against patient harm if done carelessly.

## Why this is architecturally hard

- **Life-safety availability.** An ER doctor needs the allergy list now; there is no acceptable "please retry in 30 seconds."
- **Regulatory interoperability mandate.** The system must expose HL7 FHIR APIs so other providers, labs, and patient-facing apps can access records — this is a legal requirement (information blocking rules), not a feature choice.
- **Extreme sensitivity of data.** Protected health information (PHI) requires the strictest access controls, break-glass emergency access procedures, and full audit trails of every access, including by clinicians who are not the patient's assigned care team.
- **Merger-driven data heterogeneity.** Patient records must be reconciled and matched across 6 legacy systems without creating duplicate or merged-incorrectly patient identities (a "wrong patient" data merge is catastrophic).

## What's in this folder

- `pm_brief.md` — the clinical and regulatory business case for unification.
- `design.md` — high-availability architecture for the medication-ordering path, FHIR API layer, patient identity matching, and break-glass access design.
- `architecture_decisions.md` — why an active-active multi-region design for the ordering path, why a dedicated Master Patient Index service, why FHIR is exposed via a dedicated gateway rather than directly from the core database, and why break-glass access is logged but never blocked.

## Related training weeks

Week 7 (Security Architecture), Week 11 (Business Continuity), Week 3 (Identity & Governance).
