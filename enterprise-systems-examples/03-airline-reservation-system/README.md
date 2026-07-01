# Airline Reservation System

## Real-world scenario

**Skyline Airways** operates 400 flights/day across a hub-and-spoke network. Its seat inventory and fare rules still live on a 25-year-old mainframe reservation system (the same category of system as Sabre/Amadeus-style GDS cores), which it cannot replace outright — travel agencies, its own website, mobile app, and 12 partner airlines (codeshare agreements) all depend on its interfaces today.

The airline wants a modern **booking orchestration layer** in front of the mainframe that can:
- Handle 20,000 concurrent seat-search requests/sec during fare-sale traffic spikes without hammering the mainframe (which has a hard capacity ceiling).
- Guarantee that two customers never get sold the same seat (an oversold seat is a regulatory and PR incident, and involuntary denied-boarding compensation is expensive).
- Support real-time codeshare seat availability with partner airlines' own reservation systems.

## Why this is architecturally hard

- **Legacy system of record with a hard capacity ceiling.** The mainframe cannot simply be scaled horizontally; the new layer must protect it, not just wrap it.
- **True distributed concurrency control.** Seat inventory is the classic "last item in stock" problem, at the scale of an entire airline's daily search volume, and errors have regulatory consequences (DOT/EU261 compensation rules).
- **Multi-party consistency.** Seat state must be synchronized across the airline's own channels AND external partner airline systems in near real time.
- **Long-lived, stateful transactions.** A booking session can span minutes (search → select seat → add bags → pay) and must not leak a "held" seat forever if abandoned.

## What's in this folder

- `pm_brief.md` — business case for the orchestration layer and what changes for customers vs. what stays on the mainframe.
- `design.md` — cache-first search architecture, seat-hold state machine, mainframe protection pattern (bulkheading/rate limiting), and codeshare synchronization.
- `architecture_decisions.md` — why a cache-and-reconcile search model instead of always hitting the mainframe live, why seat holds use a TTL-based saga instead of long-lived locks, and why codeshare sync is event-driven rather than synchronous.

## Related training weeks

Week 5 (Scalability & Resilience), Week 9 (AI System Design — for the search-ranking layer), Week 11 (Business Continuity).
