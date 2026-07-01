# PM Brief — Airline Booking Orchestration Layer

## Customer problem
Customers experience slow, sometimes inconsistent seat search results (especially during fare sales), and the airline's own website/app and its 12 codeshare partners each hit the mainframe directly, pushing it toward its capacity ceiling and risking a full reservation outage — the worst possible failure for an airline.

## Target users
- **Primary:** Travelers searching and booking flights via the website/app.
- **Secondary:** Travel agencies and codeshare partner airlines querying availability via API.
- **Operational:** Revenue management team (fare rules) and reservations operations (manual booking support).

## Value proposition
A booking orchestration layer that absorbs search traffic away from the mainframe protects the airline's only system of record from overload, while giving customers faster, more consistent seat search — directly reducing booking abandonment during high-demand fare sales.

## Success metrics
- Mainframe transaction volume reduced by 70% for search (booking/payment transactions unaffected).
- P99 seat search latency under 400ms during fare-sale traffic.
- Zero oversold-seat incidents post-launch.
- Codeshare availability sync lag under 5 seconds P99.

## MVP scope
- Cache-first search layer for the airline's own website/app (one hub route group as pilot).
- Seat-hold state machine with automatic expiry (industry-standard 10-minute hold).
- Mainframe rate-limiting/bulkhead pattern to guarantee it never receives more than its safe capacity.

## Non-goals
- Replacing the mainframe's fare-rule engine (stays authoritative).
- New partner airline onboarding process changes (existing codeshare contracts unaffected).
- Loyalty program point redemption changes (separate system, out of scope).

## Risks
- **Product risk:** Cached search results could show a seat as available that was just booked elsewhere; must be resolved definitively at hold time, not search time.
- **Technical risk:** Mainframe interface protocols are old (fixed-width message formats over a proprietary transport) and poorly documented; integration risk is the critical path.
- **Delivery risk:** Any bug that oversells a seat has direct regulatory/compensation cost — this demands a higher testing bar than typical features.
- **Adoption risk:** Codeshare partners must agree to consume the new event-driven sync interface instead of their current polling integration; this requires external coordination outside the airline's direct control.

## Roadmap
- **V1:** Cache-first search + seat-hold state machine for one hub route group, own channels only.
- **V2:** Extend to all routes and expose the search API to codeshare partners.
- **V3:** Event-driven real-time codeshare sync replacing partner polling integrations.
