# System Design — Real-Time Supply Chain Tracking & Exception Alerting

## 1. Problem statement
Vertex Global Logistics needs a platform that ingests heterogeneous shipment telemetry (IoT sensors, carrier EDI, manual driver check-ins), detects safety/condition exceptions in near-real-time, and maintains a complete, immutable, disputable event history for every shipment — replacing a batch-report model that already caused a $2M customer loss.

## 2. Users and stakeholders
- Shipper operations teams (monitor shipments, receive alerts)
- Insurance and customs/compliance teams (use event history for disputes)
- Vertex logistics operations (triages real-time alerts)
- IoT sensor hardware vendors (data source, indirect stakeholder)

## 3. Functional requirements
- Ingest telemetry from IoT sensors, carrier EDI feeds, and manual check-ins.
- Unify all sources into a single, ordered shipment event timeline.
- Detect condition/safety exceptions (temperature excursion, shock, route deviation) in near-real-time.
- Notify customers of exceptions via email/SMS/webhook.
- Provide an immutable, queryable event history per shipment.

## 4. Non-functional requirements
- Scale: 250,000 shipments in transit, ~15,000 telemetry events/sec at peak across all sources.
- Availability: 99.9% for ingestion and alerting paths.
- Latency: exception detection and customer notification within 5 minutes of the underlying sensor event.
- Security: telemetry and shipment data scoped per customer; no cross-customer visibility.
- Compliance: event history must be tamper-evident for insurance/customs dispute use.
- Cost: ingestion/processing cost must scale sub-linearly with shipment volume growth (not 1:1).
- Operability: out-of-order/duplicate events must be handled transparently, not surfaced as data-quality incidents to on-call.

## 5. Constraints and assumptions
- IoT sensor hardware varies by container manufacturer, with differing protocols/formats.
- Carrier EDI feeds are third-party and cannot be changed — the platform must adapt to their existing formats.
- Manual check-ins from drivers can arrive hours late due to rural connectivity gaps; the system must handle this as a normal case, not an error.

## 6. High-level architecture
```
IoT Sensors (temp/GPS/shock) --> IoT Protocol Gateway (Azure IoT Hub: handles
  MQTT/AMQP variety across sensor manufacturers, normalizes to a common event schema)
Carrier EDI Feeds --> EDI Ingestion Adapter (Container Apps: parses X12/EDIFACT ->
  common event schema)
Manual Driver Check-ins (mobile app) --> API Management --> Check-in Service
        |                    |                          |
        -------------------------------------------------
                            |
                            v
              Azure Event Hubs (unified event ingestion stream,
              partitioned by shipment ID)
                            |
        -------------------------------------------------
        |                                                |
        v                                                v
  Exception Detection Stream Processor              Event Store (event-sourced,
  (Azure Stream Analytics / Functions:               append-only, Azure Cosmos DB
  windowed rules - temp threshold, shock, route      partitioned by shipment ID)
  deviation - handles out-of-order events via         |
  event-time watermarking, deduplication by            v
  event ID)                                    Shipment Timeline Projection
        |                                       (rebuildable read model)
        v                                              |
  Alert Service (Container Apps)                        v
  -> Notification Hubs (email/SMS/webhook)      Customer/Ops Query API
                                                  (dispute/insurance history)

Cross-cutting: Microsoft Entra ID (customer-scoped access), Azure Monitor
(ingestion lag, exception-detection latency dashboards), Key Vault, Azure Policy
(per-customer data isolation enforcement).
```

## 7. Deep dives
- **Compute:** Exception Detection Stream Processor runs as a continuously scaled streaming job (not a batch job) specifically because the business requirement is minutes-latency detection, directly addressing the failure mode from the vaccine-shipment incident.
- **Network:** IoT Protocol Gateway (Azure IoT Hub) absorbs the protocol heterogeneity across sensor manufacturers at the edge of the system, so every downstream component works with one normalized event schema regardless of source.
- **Identity:** Per-customer scoped access enforced at the Query API and Notification Hubs layer — a shipper only ever sees their own shipments' data, never another customer's.
- **Data:** Event Store is the append-only, immutable source of truth (event-sourced) specifically to satisfy the tamper-evident dispute-history requirement; the Shipment Timeline Projection is a rebuildable read model for fast customer-facing queries, never the authoritative record.
- **Observability:** Ingestion lag and exception-detection latency are tracked as core operational metrics, since the entire value proposition depends on staying within the 5-minute alerting SLA.
- **Business continuity:** Event Hubs' partitioning by shipment ID and the Event Store's append-only design mean a processing failure can always be recovered by replaying events from Event Hubs' retention window, without any risk of losing telemetry.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Exception detection processing model | Real-time stream processing with event-time watermarking | Batch processing on a fixed schedule (e.g., hourly or nightly) | Batch processing is the exact failure mode that caused the $2M vaccine loss — a temperature excursion reported hours late is not meaningfully different from not being reported at all; streaming adds processing complexity (watermarking, late-event handling) in exchange for the minutes-level latency the business actually needs. |
| Shipment state model | Event-sourced, append-only event store with a separate rebuildable projection | Mutable "current shipment status" record with a separate audit log | Insurance and customs disputes require provably complete, tamper-evident history; an event-sourced model makes the history the source of truth by construction rather than a secondary log that could drift from the "real" status field. |
| Out-of-order/duplicate handling | Event-time watermarking + deduplication by event ID at the stream processing layer | Reject or flag late/duplicate events as data-quality errors | Late manual check-ins from drivers with rural connectivity gaps are a normal, expected case, not an error condition; treating them as errors would generate constant false operational noise, so the system is designed to absorb this as routine behavior. |
| IoT ingestion | Dedicated protocol gateway (Azure IoT Hub) normalizing all sensor formats at the edge | Build custom parsers for each sensor manufacturer's format directly in the ingestion service | A dedicated gateway isolates protocol-level variability from the rest of the system, so adding a new container manufacturer's sensor type means configuring the gateway, not modifying core ingestion/processing logic. |

**Cost:** Stream processing costs more per-event than batch processing, but is justified directly against the $2M incident it's designed to prevent — a clear, quantifiable ROI case for the more expensive architecture.
**Security:** Per-customer data isolation enforced at the query and notification layers prevents any cross-customer shipment visibility, important given competing shippers may use the same platform.
**Scalability:** Partitioning by shipment ID across Event Hubs and the Event Store means processing scales horizontally with shipment volume without a shared bottleneck.
**Reliability:** Event Hubs retention plus the event-sourced store means no telemetry is ever lost even if a downstream processor fails and needs to replay — a direct structural answer to "what if the alerting pipeline itself has an outage."
**Operations:** Treating late/duplicate events as routine (not error) behavior means on-call isn't paged for the normal, expected reality of unreliable field connectivity.
**Product value:** Minutes-level exception alerting directly targets the exact scenario that lost a customer $2M, making this the clearest possible business justification in the whole platform.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| IoT sensor goes silent (battery/connectivity failure) | No telemetry for that shipment for an extended period | Absence-of-heartbeat detection (no event received within expected interval) | Absence itself is treated as an exception condition and alerted, distinct from an active excursion reading |
| Stream processor falls behind during a telemetry volume spike | Exception detection latency exceeds the 5-minute SLA | Processing lag metric on the Exception Detection Stream Processor | Autoscaling on Event Hubs consumer lag; alerting SLA dashboard flags any approach toward the 5-minute threshold before it's breached |
| Duplicate event from redundant EDI feed | Risk of double-counting or conflicting shipment status | Deduplication check by event ID at ingestion | Event ID-based deduplication at the stream processing layer discards confirmed duplicates before they reach the Event Store |
| Late manual check-in arrives after shipment marked "delivered" | Apparent inconsistency in shipment timeline | Timeline projection rebuild logic detects late events against already-finalized timelines | Late events are appended to the immutable history with their true event timestamp; the projection is recalculated to reflect the corrected timeline, and any affected alert logic is re-evaluated retroactively for audit purposes |

## 10. Security design
- **AuthN:** Entra ID for customer and internal operations access; device identities for IoT sensors via IoT Hub's device authentication.
- **AuthZ:** Per-customer scoped access enforced at the API layer; no shared visibility across shipper customers.
- **Network exposure:** IoT Hub and API Management are the only external-facing surfaces; Event Store and internal processing services are not directly reachable.
- **Secrets:** Device credentials and API keys in Key Vault; IoT Hub manages per-device certificate-based authentication at scale.
- **Encryption:** TLS for all telemetry in transit; encryption at rest for the Event Store, particularly given the sensitivity of high-value shipment contents and routes.
- **Audit:** The event-sourced store is itself the audit trail — every event is retained with its original timestamp and source, supporting insurance and customs dispute resolution.

## 11. Cost model
- Main drivers: Event Hubs throughput units, stream processing compute, Cosmos DB Event Store RU/s, IoT Hub device connections.
- Reduction levers: IoT Hub tier selection matched to actual device count and message volume; Cosmos DB autoscale throughput rather than fixed provisioning; Event Hubs Capture to cool storage for long-term history retention beyond the active processing window.
- Cost is explicitly weighed against incident-prevention value — the business case treats this as risk-mitigation spend, not just an operating expense.

## 12. Evolution plan
- **10x scale:** Event Hubs and Cosmos DB both scale by adding partitions/throughput units; the shipment-ID partitioning strategy holds without redesign as shipment volume grows.
- **Enterprise adoption (expand exception rule types):** The stream processor's windowed-rules architecture is designed to add new exception types (shock/tilt, route deviation, customs delay) as additional rule definitions, not new pipeline architecture.
- **Multi-region:** As Vertex expands into new geographies with different carrier/EDI landscapes, the EDI Ingestion Adapter pattern extends by adding new format parsers, while the core event-sourced architecture remains unchanged.
