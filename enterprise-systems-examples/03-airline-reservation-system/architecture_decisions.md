# Architecture Decision Records — Airline Booking Orchestration Layer

## ADR-001: Cache-first search with mainframe re-check only at booking confirmation

### Status
Accepted

### Context
Search volume (20,000 req/sec at peak) is roughly 40x the mainframe's safe transaction ceiling (~500 tx/sec). Every search cannot hit the mainframe directly.

### Options considered
- Option A: Query the mainframe live for every search request.
- Option B: Serve search from a periodically reconciled Redis cache, and only hit the mainframe for the definitive check at booking confirmation.

### Decision
Option B.

### Consequences
Positive: protects the mainframe from load it cannot handle; search stays fast even during fare-sale spikes. Negative: search results can show a seat as available for a few seconds after it was actually sold; this is mitigated (not eliminated) by fast reconciliation, and fully closed by the mandatory mainframe re-check at confirmation.

### Review date
If mainframe replacement becomes a real roadmap item — revisit whether caching is still needed.

---

## ADR-002: TTL-based seat-hold saga instead of long-lived pessimistic locks

### Status
Accepted

### Context
A booking flow (search → seat select → ancillaries → payment) can take several minutes, and customers frequently abandon it partway through.

### Options considered
- Option A: Acquire a pessimistic lock on the mainframe seat record for the duration of the booking flow.
- Option B: Durable Functions state machine implementing Hold (with TTL) → Confirm or Expire.

### Decision
Option B.

### Consequences
Positive: bounded worst-case seat unavailability (10-minute industry-standard hold), automatic cleanup of abandoned sessions, no risk of a stuck lock consuming scarce mainframe capacity indefinitely. Negative: requires careful handling of the edge case where payment completes right at the expiry boundary (handled via a short grace-period re-check, see Failure scenarios in design.md).

### Review date
After 3 months of production data on hold-expiry vs. completed-booking timing.

---

## ADR-003: Event-driven codeshare sync over continued partner polling

### Status
Accepted

### Context
Codeshare partners currently poll availability every 60 seconds, which is too stale for fare-sale conditions and risks cross-airline overselling on shared inventory.

### Options considered
- Option A: Keep the existing 60-second polling interface.
- Option B: Event Grid-based push notifications to partner webhooks on every availability change.

### Decision
Option B, with Option A retained as a fallback for partners who haven't migrated yet.

### Consequences
Positive: sync lag drops from up to 60s to single-digit seconds, directly reducing cross-airline oversell risk. Negative: requires each of 12 partner airlines to build and test a webhook receiver — an external dependency and coordination cost outside the airline's direct control, hence the fallback path.

### Review date
6 months post-launch, or when partner migration reaches 80%, whichever comes first.

---

## ADR-004: Explicit bulkhead + circuit breaker around the mainframe

### Status
Accepted

### Context
The legacy mainframe has no graceful degradation behavior under overload — per vendor documentation, it hard-crashes and requires manual restart, which previously caused a full reservation outage.

### Options considered
- Option A: Let the mainframe's own connection limits naturally throttle traffic.
- Option B: Build an explicit Mainframe Gateway service with a fixed connection pool and circuit breaker, fronting all mainframe access.

### Decision
Option B.

### Consequences
Positive: overload is now a fast, predictable, monitored failure (circuit trips, requests queue or fail fast with clear messaging) instead of an unplanned mainframe crash. Negative: adds a service and operational surface area (the gateway itself) that must be highly available, since it becomes a single chokepoint for all booking confirmations.

### Review date
After the first fare-sale event under the new architecture.
