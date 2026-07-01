# PM Brief — Unified EHR Platform

## Customer problem
Clinicians across Cascade Health Network's 14 hospitals work across 6 disconnected legacy EHR systems inherited through mergers, causing slow record lookups, incomplete patient histories at point of care, and at least one documented near-miss medication error caused by a missing allergy record during a system handoff. Regulators also require FHIR-based interoperability that none of the 6 legacy systems fully support.

## Target users
- **Primary:** Clinicians (physicians, nurses) at point of care.
- **Secondary:** Patients (via patient portal, FHIR-based third-party health apps), external providers/labs.
- **Operational:** Health information management (HIM) / compliance teams, IT operations.

## Value proposition
A unified, highly available EHR platform eliminates cross-system record fragmentation, meets federal interoperability mandates, and directly reduces the risk of the kind of near-miss medication error that triggered this project — while giving IT one platform to secure and operate instead of six.

## Success metrics
- Medication-ordering path availability: 99.999% (life-safety tier).
- Allergy/medication list load time: P99 under 2 seconds at any hospital, any time.
- Zero patient-identity mismatch incidents (wrong-patient data merges).
- 100% FHIR interoperability compliance for required resource types within regulatory deadline.

## MVP scope
- Unified patient record for one flagship hospital, with legacy data migrated and reconciled via Master Patient Index.
- Medication-ordering module on the new high-availability path.
- FHIR API gateway exposing required resource types (Patient, AllergyIntolerance, MedicationRequest, Observation).
- Break-glass emergency access workflow with full audit logging.

## Non-goals
- Billing/revenue-cycle system migration (separate program).
- Full historical data migration for all 6 legacy systems in this phase (flagship hospital first, others phased).
- Patient-facing mobile app redesign (existing portal retained, backed by new FHIR APIs).

## Risks
- **Product risk:** Clinician workflow disruption during rollout could itself cause care delays if training and change management lag the technical migration.
- **Technical risk:** Patient identity matching across 6 legacy systems with inconsistent data quality is the single highest-risk technical component — a false-positive match merges two different patients' records.
- **Delivery risk:** Regulatory FHIR compliance has a hard deadline; scope must not slip on the interoperability layer even under schedule pressure.
- **Adoption risk:** Clinicians have deep muscle memory in legacy systems; insufficient training directly translates to patient-safety risk, not just productivity loss.

## Roadmap
- **V1:** Flagship hospital cutover — unified record, medication ordering on HA path, break-glass access.
- **V2:** FHIR API gateway live for external interoperability; remaining hospitals migrated in waves.
- **V3:** Full network-wide unification; legacy systems decommissioned; expand FHIR resource coverage.
