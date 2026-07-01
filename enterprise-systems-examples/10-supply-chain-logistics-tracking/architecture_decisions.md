# Architecture Decision Records — Supply Chain & Logistics Tracking

## ADR-001: Real-time stream processing over batch processing for exception detection

### Status
Accepted

### Context
A refrigeration failure was detected by an IoT sensor but the alert was buried in a next-day batch report, directly causing a $2M customer loss. Exception detection latency is the central problem this project must solve.

### Options considered
- Option A: Continue batch processing on a fixed schedule (e.g., hourly or nightly reports).
- Option B: Real-time stream processing with windowed exception rules and event-time watermarking.

### Decision
Option B.

### Consequences
Positive: exception alerts reach customers within minutes instead of up to a day late, directly preventing the failure mode that triggered this project. Negative: stream processing is more operationally complex than batch (requires watermarking for late events, careful handling of out-of-order data) and costs more per event processed.

### Review date
After the first quarter of production operation — validate actual alert latency against the 5-minute SLA.

---

## ADR-002: Event-sourced, append-only shipment state model

### Status
Accepted

### Context
Insurance claims and customs disputes require a provably complete, tamper-evident history of every shipment event. A mutable "current status" model cannot guarantee this by construction.

### Options considered
- Option A: Mutable shipment status record with a separate audit log for history.
- Option B: Event-sourced, append-only event store as the sole source of truth; shipment status is always a derived projection.

### Decision
Option B.

### Consequences
Positive: history is guaranteed complete and tamper-evident because it is the only representation of state, not a secondary log that could drift from a "real" status field; directly satisfies the dispute-resolution requirement. Negative: requires maintained, rebuildable projections for fast customer-facing queries, adding operational complexity around projection freshness and rebuild tooling.

### Review date
At the first major insurance/customs dispute handled under the new system — validate the history actually holds up as evidence.

---

## ADR-003: Event-time watermarking and ID-based deduplication instead of treating late/duplicate events as errors

### Status
Accepted

### Context
Manual driver check-ins routinely arrive hours late due to rural connectivity gaps, and duplicate events can arrive from redundant EDI feeds. Both are normal, expected conditions, not data-quality incidents.

### Options considered
- Option A: Flag out-of-order or duplicate events as data-quality errors requiring manual review.
- Option B: Handle late events via event-time watermarking in the stream processor and deduplicate by event ID automatically.

### Decision
Option B.

### Consequences
Positive: the system absorbs the real-world reality of unreliable field connectivity as routine behavior, avoiding constant false operational alerts; on-call is not paged for expected, non-actionable conditions. Negative: watermarking logic adds complexity to the stream processor and requires careful tuning of the lateness window to balance timeliness against completeness.

### Review date
After observing 3 months of real-world late-event patterns — tune the watermarking window based on actual data.

---

## ADR-004: Dedicated IoT protocol gateway for sensor ingestion

### Status
Accepted

### Context
IoT sensor hardware varies across container manufacturers, each with different protocols and message formats. This variability should not leak into the core processing pipeline.

### Options considered
- Option A: Build custom parsing logic for each sensor manufacturer's format directly within the ingestion service.
- Option B: Dedicated IoT Protocol Gateway (Azure IoT Hub) that normalizes all sensor formats into one common event schema at the edge.

### Decision
Option B.

### Consequences
Positive: onboarding a new container manufacturer's sensor type is a gateway configuration change, not a modification to core ingestion/processing logic; isolates protocol churn from the stable parts of the system. Negative: adds a dependency on the gateway's supported protocol set — a genuinely novel sensor protocol not supported by the gateway would still require custom integration work.

### Review date
When onboarding a new sensor hardware vendor not yet supported by the gateway configuration.
