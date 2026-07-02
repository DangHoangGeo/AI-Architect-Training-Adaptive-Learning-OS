# System Design — Unified EHR Platform

## 1. Problem statement
Cascade Health Network needs a single EHR platform replacing 6 legacy systems, with life-safety-grade availability for medication ordering, regulator-mandated FHIR interoperability, and reliable patient identity matching across merged data sources — all while protecting highly sensitive PHI.

## 2. Users and stakeholders
- Clinicians (physicians, nurses) at point of care
- Patients and external providers/labs (via FHIR APIs)
- Health information management / compliance
- IT operations

## 3. Functional requirements
- Unified patient chart: history, allergies, medications, orders, labs.
- Medication ordering with allergy/interaction checking.
- FHIR-compliant API for external access (Patient, AllergyIntolerance, MedicationRequest, Observation resources).
- Break-glass emergency access for clinicians outside the patient's normal care team.
- Patient identity resolution across records migrated from 6 legacy systems.

## 4. Non-functional requirements
- Scale: 14 hospitals, ~9,000 concurrent clinician sessions at peak, ~2M patient records.
- Availability: 99.999% for medication ordering and allergy lookup (life-safety tier); 99.9% for administrative/reporting functions.
- Latency: P99 allergy/medication list load < 2 seconds under any load condition.
- Security: PHI encryption at rest/in transit, RBAC + break-glass, full access audit trail (HIPAA-equivalent).
- Compliance: HL7 FHIR R4 for required resource types; information-blocking regulation deadline.
- Cost: Predictable per-hospital operating cost for budget planning across the network.
- Operability: Medication-ordering incidents must page on-call within 60 seconds of detection.

## 5. Constraints and assumptions
- Cannot have any planned downtime window for the medication-ordering path — maintenance must be zero-downtime (rolling deploys only).
- Legacy systems have inconsistent patient identifiers (some use SSN, some use MRN-per-facility) requiring probabilistic matching, not simple key joins.
- Regulatory FHIR deadline is fixed and non-negotiable.

## 6. High-level architecture
```
Clinicians (hospital workstations, tablets)
        |
        v
Internal Load Balancer (per-region) -> Clinical App (Container Apps, active-active across 2 Azure regions)
        |
        |-- Medication Ordering Service (HA tier)
        |      -> Azure SQL Business Critical (zone-redundant, active geo-replication to paired region)
        |      -> Allergy/Interaction Check (cached reference data, Azure Cache for Redis)
        |
        |-- Master Patient Index Service (Container Apps)
        |      -> Probabilistic matching engine (deterministic + fuzzy match, human review queue for low-confidence matches)
        |      -> Cosmos DB (cross-system identity graph)
        |
        |-- Break-Glass Access Service
        |      -> Every access logged immutably (Azure SQL audit table + Log Analytics), never blocks access
        v
FHIR API Gateway (Azure API Management, dedicated FHIR-compliant layer) -> external providers, labs, patient portal

Cross-cutting: Microsoft Entra ID (clinician SSO, RBAC), Key Vault (encryption keys),
Azure Monitor (life-safety-tier alerting with 60s page SLA), Azure Policy (region + encryption enforcement),
Azure Backup (geo-redundant, immutable backup vaults for ransomware protection).
```

## 7. Deep dives
- **Compute:** Medication Ordering Service runs active-active across two Azure regions behind a global load balancer, so a full regional outage does not interrupt the life-safety path — this is the one component in the platform justified in paying for true active-active redundancy.
- **Network:** Internal-only access for clinical workstations via hospital private networks + ExpressRoute; FHIR Gateway is the only path exposed to external providers, with mutual TLS and OAuth2 SMART-on-FHIR scopes.
- **Identity:** Entra ID for clinician SSO with role-based scopes (attending, nurse, specialist consult); break-glass access uses a distinct elevated role that any credentialed clinician can invoke, logged with mandatory post-hoc justification, never blocked in the moment.
- **Data:** Azure SQL Business Critical tier for the core clinical record (needs synchronous replication within a region plus geo-replication for DR); Cosmos DB for the Master Patient Index's identity graph, since patient matching is a graph-shaped problem across 6 source systems.
- **Observability:** Medication-ordering path has its own dedicated, highest-priority alert tier with a 60-second page SLA — distinct from standard application alerting, reflecting its life-safety classification.
- **Business continuity:** Immutable, geo-redundant backups specifically to defend against ransomware (a documented, common attack vector against hospital systems); restore drills are run quarterly, not just documented.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Medication-ordering availability | Active-active across 2 regions | Active-passive with automated failover | A life-safety path cannot tolerate even the minutes of failover time active-passive implies; the extra always-on cost of active-active is justified specifically for this one component, not applied platform-wide. |
| Patient identity matching | Master Patient Index with probabilistic matching + human review queue | Fully automatic matching based on best-available identifier | A wrong-patient auto-merge is catastrophic and irreversible; routing low-confidence matches to human review trades some manual effort for eliminating the worst failure mode. |
| FHIR exposure | Dedicated FHIR API Gateway, not direct database access | Expose FHIR resources directly from the clinical database | A dedicated gateway lets the internal data model evolve independently of the external FHIR contract, and concentrates external-facing security controls (OAuth2 scopes, rate limiting) in one auditable layer. |
| Break-glass access | Always allow access, log and require post-hoc justification | Require pre-approval/second-factor confirmation before granting emergency access | In a real emergency, blocking access to save a step is itself a patient-safety risk; the design accepts a small window of potential misuse in exchange for guaranteed access when seconds matter, backed by mandatory audit review. |

**Cost:** Active-active redundancy is applied narrowly (medication ordering only), not to the entire platform, keeping the highest cost tier scoped to where the patient-safety justification is clearest.
**Security:** Break-glass logging turns an availability requirement into an auditable control rather than an unmonitored backdoor; FHIR gateway concentrates external attack surface into one hardened, monitored layer.
**Scalability:** Master Patient Index as a separate service means identity resolution scales and evolves independently of the clinical record system, important given 6 source systems' ongoing data quality issues.
**Reliability:** Active-active for the one truly life-safety path, standard HA for everything else, avoids over-engineering (and over-cost) on lower-stakes components while not under-engineering the one that matters most.
**Operations:** A distinct 60-second page SLA for the medication path forces on-call tooling and runbooks to treat it differently from routine incidents.
**Product value:** Directly addresses the near-miss medication error that triggered the project, which is the clearest possible justification for every dollar spent on the high-availability tier.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Regional Azure outage affecting medication ordering | None (if active-active working correctly) | Synthetic transaction monitoring in both regions | Traffic automatically routes to healthy region; quarterly failover drills validate this actually works, not just on paper |
| Master Patient Index low-confidence match backlog grows | Clinicians see incomplete records pending manual review | Review-queue depth alert | Staffing runbook for HIM team scales review capacity; interim partial record shown with a clear "additional records pending verification" flag, never silently merged |
| FHIR Gateway under unexpected external load (e.g., new partner integration) | External API latency/errors, but internal clinical system unaffected | APIM rate-limit and latency metrics | Gateway is isolated from the core clinical path by design; external load cannot cascade into medication-ordering availability |
| Break-glass access misuse | Inappropriate PHI access by a clinician outside their care team | Automated anomaly detection on break-glass audit logs + mandatory HIM review of all break-glass events | Access is never blocked in the moment, but every event is reviewed within 24 hours; repeated unjustified use triggers HR/compliance escalation |

## 10. Security design
- **AuthN:** Entra ID SSO for clinicians with MFA; SMART-on-FHIR OAuth2 for external provider/app access.
- **AuthZ:** Role-based access scoped to care-team assignment by default; break-glass role available to any credentialed clinician, logged and reviewed.
- **Network exposure:** Clinical app reachable only over hospital private network/ExpressRoute; FHIR Gateway is the sole external-facing surface, behind APIM with mutual TLS.
- **Secrets:** All encryption keys and connection strings in Key Vault with customer-managed keys for PHI-containing databases.
- **Encryption:** TDE at rest, TLS 1.2+ in transit, field-level encryption for the most sensitive identifiers in the Master Patient Index.
- **Audit:** Every record access (including break-glass) logged with clinician identity, patient, timestamp, and justification — retained per regulatory record-retention requirements.

## 11. Cost model
- Main drivers: Active-active Azure SQL Business Critical tier for medication ordering, geo-redundant immutable backups, APIM premium tier for FHIR gateway (needed for VNet integration and higher throughput SLAs).
- Reduction levers: Standard (not active-active) tier for non-life-safety modules (scheduling, billing-adjacent reporting); Cosmos DB autoscale for the identity graph rather than fixed provisioned throughput.
- Cost is justified per-module against its availability tier — the CFO sees why medication ordering costs more per transaction than reporting, rather than a single blended infrastructure bill.

## 12. Evolution plan
- **10x scale (network growth via acquisition):** Master Patient Index pattern extends cleanly — onboarding a newly acquired hospital's legacy system means adding another source system to the matching engine, not redesigning it.
- **Enterprise adoption (full network):** Phase remaining hospitals onto the platform in waves, using the flagship hospital's migration runbook as the template, with identity matching quality gates before each wave's cutover.
- **Multi-region/regulatory evolution:** As FHIR resource-type requirements expand, the dedicated gateway pattern means new resource types are additive to the external contract without touching the core clinical data model.
