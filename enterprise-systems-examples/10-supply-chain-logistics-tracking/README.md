# Supply Chain & Logistics Tracking

## Real-world scenario

**Vertex Global Logistics** operates a freight tracking platform for enterprise shippers, tracking 250,000 shipments in transit at any time across ocean, air, rail, and truck. Each shipment reports telemetry from a mix of sources: IoT temperature/GPS sensors on high-value refrigerated containers, carrier EDI (Electronic Data Interchange) status updates, customs clearance events, and manual driver check-ins from truck drivers with spotty rural connectivity.

A pharmaceutical customer lost a $2M shipment of temperature-sensitive vaccines last year because a refrigeration failure wasn't detected until the container was opened at the destination — the IoT sensor had actually reported the excursion 6 hours earlier, but the alert was buried in a batch report processed the next morning. Vertex's customers now demand **real-time exception alerting**, not just historical tracking, and a complete, tamper-evident event history for every shipment for insurance and customs disputes.

## Why this is architecturally hard

- **Heterogeneous, unreliable telemetry sources.** IoT sensors, carrier EDI feeds, and manual check-ins arrive at wildly different frequencies, formats, and reliability levels, and must be unified into one coherent shipment timeline.
- **Real-time exception detection at scale.** A temperature excursion must trigger an alert within minutes, not be discovered in a next-day batch report — this is a streaming, not batch, problem.
- **Out-of-order and duplicate event handling.** A truck driver's check-in might sync hours late after regaining connectivity; the same customs event might arrive twice from redundant data feeds.
- **Immutable, disputable event history.** When an insurance claim or customs dispute arises, the shipment's event history must be provably complete and unaltered.

## What's in this folder

- `pm_brief.md` — the business case tied to the vaccine-shipment incident and customer retention risk.
- `design.md` — event-sourced shipment state architecture, real-time stream processing for exception detection, and IoT/EDI ingestion normalization.
- `architecture_decisions.md` — why shipment state is event-sourced, why exception detection runs on a stream processor rather than batch, how out-of-order/duplicate events are handled, and why IoT ingestion uses a dedicated protocol gateway.

## Related training weeks

Week 9 (AI System Design — anomaly detection), Week 4 (Data & Storage), Week 6 (Observability & Operations).
