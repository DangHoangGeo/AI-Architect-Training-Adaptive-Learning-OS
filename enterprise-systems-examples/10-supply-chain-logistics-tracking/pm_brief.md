# PM Brief — Real-Time Supply Chain Tracking & Exception Alerting

## Customer problem
Vertex's current tracking platform processes shipment telemetry in next-day batch reports, meaning critical exceptions (like a refrigeration failure) are discovered hours or days too late to act on — a failure mode that directly cost a customer a $2M vaccine shipment. Customers also need a defensible, tamper-evident event history for insurance and customs disputes, which the current system cannot fully guarantee.

## Target users
- **Primary:** Shipper operations teams monitoring shipments in transit.
- **Secondary:** Insurance and customs/compliance teams handling disputes and claims.
- **Operational:** Vertex's own logistics operations team who triage real-time alerts.

## Value proposition
Real-time exception alerting on shipment telemetry, combined with a provably complete and tamper-evident event history, directly prevents the class of incident that already cost a major customer $2M and is the core reason customers choose (or leave) a logistics tracking platform.

## Success metrics
- Temperature/condition excursion alert latency: under 5 minutes from sensor event to customer notification.
- 100% of shipment events retained in an immutable, queryable history for insurance/customs use.
- False-positive exception alert rate: under 2% (to preserve trust in the alerting system).
- Zero data loss from out-of-order or duplicate telemetry across all source types.

## MVP scope
- Real-time stream processing pipeline for IoT sensor telemetry (temperature, GPS, shock) with exception rule detection.
- Event-sourced shipment timeline unifying IoT, carrier EDI, and manual check-in events.
- Customer-facing real-time alert notifications (email/SMS/webhook).
- Immutable event history queryable for dispute resolution.

## Non-goals
- Predictive ETA modeling (existing ETA estimates retained; this project is exception detection and history, not prediction).
- Replacing carrier EDI integrations themselves (only the ingestion/normalization layer is new).
- Customer-facing route optimization recommendations (separate future initiative).

## Risks
- **Product risk:** Over-alerting on minor, non-actionable exceptions could cause customers to tune out or disable alerts entirely, undermining the entire value proposition.
- **Technical risk:** Reliably deduplicating and correctly ordering events from wildly heterogeneous, sometimes hours-delayed sources is a genuinely hard distributed-systems problem.
- **Delivery risk:** IoT sensor hardware/firmware across different container manufacturers varies; the ingestion gateway must handle more protocol variety than initially scoped.
- **Adoption risk:** Vertex's own operations team must trust and act on real-time alerts rather than falling back to familiar batch-report habits.

## Roadmap
- **V1:** Real-time IoT stream processing + exception alerting for temperature-sensitive shipments (highest-value use case, matching the incident that triggered the project).
- **V2:** Full event-sourced timeline unifying all telemetry sources (EDI, manual check-ins) with immutable dispute-ready history.
- **V3:** Expand exception rules beyond temperature (shock/tilt detection, route deviation, customs delay prediction).
