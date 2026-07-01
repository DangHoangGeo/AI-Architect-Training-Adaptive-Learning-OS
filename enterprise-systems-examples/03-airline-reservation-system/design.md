# System Design — Airline Booking Orchestration Layer

## 1. Problem statement
Skyline Airways needs a modern layer in front of its legacy mainframe reservation system that absorbs search traffic, guarantees no seat is ever double-sold, and keeps codeshare partner availability synchronized — without exceeding the mainframe's fixed capacity ceiling.

## 2. Users and stakeholders
- Travelers (search, book, pay)
- Travel agencies / codeshare partners (query availability via API)
- Revenue management (fare rules, pricing)
- Reservations operations (manual support, exceptions)

## 3. Functional requirements
- Search flights and seat availability across own network and codeshare partners.
- Hold a seat for a bounded time during the booking flow.
- Confirm a booking against the mainframe as the single source of truth for the final "sold" state.
- Sync availability changes to/from codeshare partners.

## 4. Non-functional requirements
- Scale: 20,000 concurrent search requests/sec at peak; mainframe can safely sustain ~500 transactions/sec.
- Availability: 99.99% for search, 99.995% for booking confirmation (booking outage grounds the sales channel).
- Latency: P99 search < 400ms; P99 booking confirmation < 2s (mainframe round-trip included).
- Security: PCI DSS for payment step; partner API access scoped per airline.
- Compliance: Regulatory seat-oversell prevention (DOT/EU261 exposure), audit trail for every booking.
- Cost: Search layer must reduce, not add to, total transaction cost by offloading the mainframe.
- Operability: Circuit breaker and back-pressure visible to on-call before the mainframe itself is at risk.

## 5. Constraints and assumptions
- Mainframe remains the authoritative system of record; it cannot be bypassed for final booking confirmation.
- Mainframe interface is a proprietary message protocol with a hard concurrent-connection limit.
- Codeshare partners currently poll for availability every 60 seconds; moving them to event-driven push requires their cooperation.

## 6. High-level architecture
```
Travelers / Travel Agencies / Codeshare Partners
        |
        v
Azure Front Door (WAF, global entry) -> API Management (partner auth, rate limiting)
        |
        v
Search Service (Container Apps, autoscaled on request rate)
   -> Azure Cache for Redis (near-real-time seat availability snapshot, refreshed via reconciliation)
   -> Cosmos DB (flight/fare metadata, denormalized for fast search)
        |
        v
Booking Orchestration Service (Container Apps)
   -> Seat-Hold State Machine (Durable Functions: Hold -> Confirm/Expire)
   -> Mainframe Gateway (Container Apps, bulkhead: fixed connection pool + circuit breaker + Service Bus queue)
        -> Legacy Mainframe (system of record for confirmed bookings)
        |
        v
Codeshare Sync Service -> Event Grid -> Partner airline webhooks / own reconciliation job

Cross-cutting: Azure Monitor (mainframe transaction budget dashboard), Key Vault, Entra ID
(partner app registrations), Azure Policy (rate-limit enforcement at APIM).
```

## 7. Deep dives
- **Compute:** Mainframe Gateway is a deliberately narrow, bulkheaded service — fixed-size connection pool matching the mainframe's safe capacity, with a circuit breaker that fails fast (returning "try again" to the booking flow) rather than queuing unboundedly and starving other requests.
- **Network:** APIM enforces per-partner rate limits so no single codeshare partner can consume a disproportionate share of mainframe capacity indirectly through search/booking volume.
- **Identity:** Each codeshare partner gets its own Entra ID app registration and APIM subscription key, enabling per-partner quota and audit.
- **Data:** Redis holds a near-real-time availability snapshot for fast search; it is explicitly a cache, not a source of truth — every booking confirmation re-checks against the mainframe via the gateway before finalizing, closing the race-condition window.
- **Observability:** A live "mainframe transaction budget" dashboard shows current usage against the safe ceiling, so on-call can see back-pressure building before an outage, not after.
- **Business continuity:** If the Mainframe Gateway circuit breaker trips, search continues to serve cached results (degraded but available) while booking confirmation queues with clear customer messaging ("confirming your seat") rather than a hard failure.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Search data freshness | Cache-first search with periodic reconciliation, mainframe re-check only at booking confirmation | Always query the mainframe live for every search | Live queries at 20,000 req/sec would instantly exceed the mainframe's ~500 tx/sec ceiling; caching accepts small staleness in search results in exchange for protecting the system of record, with correctness enforced at the one point that matters (confirmation). |
| Seat hold mechanism | TTL-based saga (Durable Functions state machine: Hold → Confirm/Expire) | Long-lived pessimistic lock on the mainframe seat record | Long-lived locks held during a multi-minute booking flow would tie up scarce mainframe capacity and risk deadlocks if a customer abandons the flow; a TTL-based hold with automatic expiry bounds the worst case cleanly. |
| Codeshare sync | Event-driven push (Event Grid + partner webhooks) | Continue partner polling every 60s | Polling means partner-visible availability can be up to 60s stale, causing partner-side overselling risk; event-driven push cuts that to seconds, though it requires partner-side integration work that is a coordination risk. |
| Mainframe protection | Explicit bulkhead + circuit breaker in a dedicated gateway service | Rely on the mainframe's own timeout/rejection behavior | The mainframe's native behavior under overload is a hard crash requiring manual restart (per vendor documentation); an explicit gateway-side bulkhead fails fast and predictably instead of letting the legacy system be the failure point. |

**Cost:** Offloading ~93% of transaction volume (search) from the mainframe to the modern layer reduces load-related mainframe upgrade/support costs, which is the direct financial justification for this project.
**Security:** Per-partner API keys and quotas at APIM contain the blast radius of a compromised or misbehaving partner integration.
**Scalability:** Search and booking are scaled independently; search scales horizontally without limit, while booking throughput is deliberately capped to match the mainframe's real ceiling.
**Reliability:** The bulkhead pattern means a mainframe slowdown degrades gracefully (cached search still works) instead of taking down every channel simultaneously, which is what happened before this design.
**Operations:** The mainframe transaction budget dashboard turns "the mainframe might fall over" from an opaque risk into a monitored, alertable metric.
**Product value:** Faster search directly reduces booking abandonment during fare sales, the single highest-value moment in the customer journey, which is the core business driver for this investment.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Mainframe approaches capacity ceiling | Booking confirmations slow or fail | Mainframe transaction budget dashboard alert at 80% | Circuit breaker trips, booking flow queues with "confirming" state; search continues on cached data |
| Redis cache goes stale (reconciliation job fails) | Search shows seats as available that are already sold | Reconciliation job health check + staleness metric | Booking confirmation always re-verifies against mainframe regardless of cache state, so no seat is ever oversold even with stale search results |
| Codeshare partner webhook endpoint down | That partner's availability data goes stale on their side | Event Grid delivery failure metrics | Dead-letter queue + retry with exponential backoff; fallback to the legacy 60s polling interface for that partner until resolved |
| Seat-hold expiry race (customer completes payment right at 10-minute mark) | Customer charged but seat hold expired | Durable Functions state machine audit log | Grace-period re-check: if payment succeeds within a short grace window past expiry, re-attempt hold before failing; otherwise auto-refund and clear customer messaging |

## 10. Security design
- **AuthN:** Customers via existing airline identity provider; partners via Entra ID app registrations with mutual TLS for high-privilege codeshare endpoints.
- **AuthZ:** APIM subscription keys scoped per partner with quota and product-level access (e.g., search-only vs. search+booking).
- **Network exposure:** Only Front Door and APIM are internet-facing; the Mainframe Gateway has no public endpoint and is reachable only from the Booking Orchestration Service via Private Endpoint.
- **Secrets:** Mainframe connection credentials in Key Vault, rotated on a fixed schedule given the legacy system's limited credential-rotation tooling.
- **Encryption:** TLS 1.2+ for all external traffic; payment data tokenized before it ever reaches the booking orchestration layer.
- **Audit:** Every hold/confirm/expire transition logged with a correlation ID spanning search → hold → mainframe confirmation, for both operational debugging and regulatory audit.

## 11. Cost model
- Main drivers: Container Apps compute for search (highest volume), Redis cache tier, APIM tier (partner API management).
- Reduction levers: Aggressive caching reduces both mainframe load and Cosmos DB read costs; autoscaling search compute to zero during off-peak overnight hours.
- The business case is explicitly cost-avoidance: preventing a mainframe capacity upgrade (a multi-year, high-cost legacy vendor negotiation) by architecturally reducing its load instead.

## 12. Evolution plan
- **10x scale:** If search volume grows 10x, add a CDN layer in front of the search API for cacheable common-route queries (e.g., "cheapest fare next 30 days") to reduce load even further upstream of the Search Service.
- **Enterprise adoption:** Extend the Mainframe Gateway pattern to other mainframe-dependent domains (baggage, check-in) using the same bulkhead approach.
- **Multi-region/long-term:** As mainframe replacement becomes feasible, the Booking Orchestration Service's clean interface boundary (Hold/Confirm/Expire) means the mainframe can eventually be "strangled" the same way as in the Core Banking Ledger example, without changing anything customer-facing.
