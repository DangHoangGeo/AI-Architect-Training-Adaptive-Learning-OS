# System Design — ERP Integration Hub

## 1. Problem statement
Ironclad Manufacturing needs to replace 23 point-to-point integrations around its SAP S/4HANA core with an event-driven hub, so that a change to any one system does not require touching every other system, and new factories can be onboarded through a standard adapter pattern instead of bespoke integration work.

## 2. Users and stakeholders
- Integration/platform engineering team (builds and operates the hub)
- 22 downstream/upstream system owners (warehouse, CRM, MES lines, compliance, supplier portal)
- Factory operations (depend on timely, correct data flow)
- Executive sponsor (funds the multi-year migration against onboarding-time and incident-reduction metrics)

## 3. Functional requirements
- Publish domain events from SAP (purchase order created, inventory level changed, plant/factory master data updated, etc.).
- Allow each downstream system to subscribe only to the events it needs, in the delivery semantics it needs (ordered vs. at-least-once/idempotent).
- Provide adapters for legacy systems that cannot natively publish/consume events (flat-file, OPC-UA).
- Maintain a schema registry so event contracts are versioned and discoverable.

## 4. Non-functional requirements
- Scale: ~2M events/day across all integrations at full migration, bursty around shift changes and month-end close.
- Availability: 99.9% for the hub; individual integrations degrade independently (one MES adapter failing must not affect others).
- Latency: Near-real-time for warehouse/inventory events (seconds), batch-acceptable for reporting/analytics consumers (minutes).
- Security: Per-system-owner scoped access; SAP remains the authoritative source, never overwritten by a downstream event.
- Compliance: Full event audit trail for compliance-relevant data (customs, quality management).
- Cost: Migration cost must be justified per-integration against the maintenance cost of the point-to-point link it replaces.
- Operability: Single dashboard shows event flow health across all 23 integrations, replacing 23 separate monitoring setups.

## 5. Constraints and assumptions
- SAP S/4HANA is not being replaced; the hub integrates with it via its existing event/API capabilities (SAP Event Mesh style outbound events, OData APIs for lookups).
- Legacy MES systems cannot be modified beyond their existing file-export/OPC-UA capability; an adapter must meet them where they are.
- Migration is incremental — old point-to-point links run in parallel with new hub-based flow until each is proven, per system owner's trust requirements.

## 6. High-level architecture
```
SAP S/4HANA (event source + system of record)
   -> SAP Event Mesh / CDC -> Azure Event Hubs (high-throughput event backbone)
                                    |
                                    v
                        Schema Registry (Azure Schema Registry in Event Hubs)
                                    |
        -----------------------------------------------------------
        |                    |                     |               |
        v                    v                     v               v
  Service Bus Topic    Service Bus Topic      Adapter Layer    Analytics Sink
  (ordered, per-      (competing consumers,  (Container Apps: (Event Hubs Capture
  warehouse system)   supplier portal)       flat-file/OPC-UA -> Data Lake)
        |                    |               translation for
        v                    v               legacy MES)
  Warehouse Mgmt        Supplier Portal              |
  System (modern API)  (modern API)                  v
                                              Legacy MES (factory floor)

Cross-cutting: Azure API Management (adapter/API layer for legacy systems needing
request/response, not just events), Azure Monitor (unified event-flow dashboard),
Microsoft Entra ID (per-system-owner scoped access), Key Vault, Azure Policy.
```

## 7. Deep dives
- **Compute:** Adapter Layer runs as independently deployable Container Apps per legacy system, so one MES line's adapter failing doesn't affect the warehouse or supplier portal integrations — this directly addresses the "N-squared blast radius" problem the hub is meant to solve.
- **Network:** Event Hubs and Service Bus are the only integration surface for new consumers; legacy systems still on flat-file/FTP continue using their existing network path into the Adapter Layer, which then normalizes into the event backbone.
- **Identity:** Each of the 22 system owners gets a scoped Entra ID identity with access limited to the specific event topics/subscriptions relevant to their system — no owner has blanket access to every SAP event.
- **Data:** Schema Registry enforces versioned, backward-compatible event contracts; a SAP field change becomes a new schema version that old and new consumers can both handle during a transition window, instead of a breaking change propagated by hand to 14 integrations.
- **Observability:** A single dashboard tracks event lag, dead-letter rates, and adapter health per integration — the direct replacement for today's 23 separate, inconsistent monitoring setups.
- **Business continuity:** Event Hubs Capture archives every event to a data lake, giving replay capability if a downstream system needs to reprocess history (e.g., after a bug fix) without re-querying SAP directly.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Integration pattern | Event-driven hub (pub/sub via Event Hubs + Service Bus) | Commercial iPaaS platform doing point-to-point orchestration under one roof | An iPaaS still tends toward centralized orchestration logic that recreates tight coupling; a true event backbone lets each consumer own its own processing logic and pace, better matching the goal of decoupling, though it requires more in-house platform engineering. |
| Schema management | Mandatory schema registry with versioned, backward-compatible contracts | Ad hoc JSON payloads agreed bilaterally per integration | Ad hoc payloads is exactly the current point-to-point problem in a new format; a registry is what makes "SAP changes a field without notifying 14 teams" impossible by construction. |
| Legacy system integration | Dedicated adapter layer translating flat-file/OPC-UA into events | Require legacy MES systems to be modernized before integrating | Modernizing 8 factories' floor systems is a multi-year, separate capital project; an adapter layer delivers the decoupling benefit now without blocking on unrelated modernization work. |
| Migration approach | Per-integration strangler migration, old and new running in parallel until trust is established | Coordinated cutover of all 23 integrations on one date | 22 independent system owners each need to validate correctness on their own timeline; a single cutover date is both a technical and organizational risk that a phased approach avoids. |

**Cost:** Migration is prioritized by the highest-incident-rate integrations first, so cost is spent where it displaces the most existing maintenance burden soonest, rather than migrating in an arbitrary order.
**Security:** Per-system-owner scoped access via Entra ID means a compromised or misconfigured downstream system can only affect the event topics it's actually subscribed to, not the whole SAP event stream.
**Scalability:** Event Hubs' partitioned, high-throughput model handles the full 2M events/day with headroom, decoupled entirely from how fast any individual downstream consumer processes them.
**Reliability:** Independent adapter deployments mean one legacy MES integration failing is isolated, not a hub-wide incident — directly solving today's cascading-breakage problem.
**Operations:** A single unified dashboard replacing 23 inconsistent ones is one of the most concrete operational wins driving the business case.
**Product value:** Cutting factory onboarding from 4-6 months to under 6 weeks is the headline metric the executive sponsor is funding this program against.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| SAP schema change breaks an old-version consumer | That consumer fails to process new events | Schema registry compatibility check fails at publish time, or consumer-side deserialization error alert | Registry enforces backward compatibility by default; breaking changes require an explicit new version with a defined consumer migration window |
| Legacy MES adapter goes down | That factory's floor data stops flowing to the hub | Adapter health check + event-lag alert scoped to that integration | Adapter failure is isolated by design; other integrations unaffected; on-call runbook specific to that adapter |
| Event Hubs partition hot-spotting during month-end close | Increased latency for high-volume event types | Per-partition throughput metrics | Partition key strategy revisited for high-volume event types (e.g., partition by plant code instead of a single key) |
| A downstream consumer falls behind and can't keep up with event volume | Growing backlog, stale data for that consumer | Consumer lag metric per subscription | Consumer scales independently (Service Bus/Event Hubs allow independent consumer group scaling); dead-letter queue for poison messages so one bad event doesn't block the whole subscription |

## 10. Security design
- **AuthN:** Entra ID managed identities for all internal service-to-service communication; system owners access monitoring dashboards via Entra ID SSO.
- **AuthZ:** Per-system-owner Entra ID roles scoped to specific Event Hubs consumer groups / Service Bus topics — no shared "read everything" credential.
- **Network exposure:** Event Hubs and Service Bus accessed via Private Endpoints; only the Adapter Layer's inbound file-drop/FTP endpoint (for legacy systems) is exposed, and only to the factory network, not the internet.
- **Secrets:** All connection details in Key Vault; legacy system credentials (FTP, OPC-UA) rotated on the tightest schedule the legacy system supports.
- **Encryption:** TLS in transit for all modern integrations; at-rest encryption on Event Hubs Capture and the data lake.
- **Audit:** Every event captured immutably (Event Hubs Capture to Data Lake) providing a full audit trail for compliance-relevant flows (customs, quality management).

## 11. Cost model
- Main drivers: Event Hubs throughput units (sized for 2M events/day with burst headroom), Service Bus premium tier (needed for ordering guarantees on select topics), Adapter Layer compute per legacy integration.
- Reduction levers: Event Hubs Capture to cool-tier storage for long-term audit retention instead of keeping everything hot; consumer-group-based scaling means each downstream system pays for its own processing compute, not a shared oversized cluster.
- Business case tracks cost per migrated integration against the maintenance hours saved by retiring its point-to-point equivalent, making ROI per-integration explicit to the steering committee.

## 12. Evolution plan
- **10x scale (all 8 factories + acquisitions):** Adapter pattern is the reusable unit — onboarding a newly acquired factory's MES means writing one new adapter, not touching 22 existing systems.
- **Enterprise adoption:** Once trust is established, the schema registry becomes the de facto contract-first design tool for any new system integration, changing how future integration projects are scoped from day one.
- **Multi-region:** If Ironclad expands internationally, per-region Event Hubs namespaces with cross-region replication can be added without redesigning the consumer-side integration pattern, since consumers already interact through the same schema-registry-governed contract.
