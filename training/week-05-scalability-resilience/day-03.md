# Week 05 Day 3 — Design Exercise: Caching and CDN Strategy

## Goal
Design a multi-layer caching architecture for a ticketing platform that must serve static event pages and seat-map assets at massive scale during burst traffic, while ensuring that inventory data (remaining seats) never serves stale cache to buyers.

## Why this matters
During the 90-second burst of a major on-sale event, a single database query for "remaining seats in section A" could execute 40,000 times per second — an instant database overload. Caching at the right layer reduces database load by 99%, but caching inventory data too aggressively means customers buy seats that were already sold 30 seconds ago, triggering payment reversals and trust damage.

## Core concept

1. **Three-layer caching model for ticketing.**
   - **CDN layer (Azure Front Door):** Static assets — event hero images, venue seat maps (SVG/JSON), CSS/JS bundles. TTL: 24–72 hours. These never change mid-sale.
   - **Application cache (Azure Cache for Redis):** Semi-static reads — event metadata, artist bios, pricing tiers. TTL: 5–30 minutes. Acceptable to be slightly stale.
   - **Inventory cache (Redis with short TTL or no cache):** Seat availability counts. TTL: 2–5 seconds maximum, or serve directly from database with read replicas. Stale inventory is a business liability.

2. **Cache invalidation is the hard part.** "There are only two hard things in computer science: cache invalidation and naming things." For ticketing: when a seat is sold, the inventory count must be invalidated immediately. Strategies: (a) write-through cache — update Redis and database atomically; (b) event-driven invalidation — publish a "seat sold" event that invalidates the Redis key.

3. **Azure Front Door vs Azure CDN (classic).** Front Door provides WAF, global load balancing, and health probes in addition to CDN functionality. For a public-facing ticketing platform, Front Door is preferred. Classic Azure CDN (Verizon/Akamai) is cheaper but lacks WAF integration.

4. **Cache stampede (thundering herd).** When a popular cached item expires, all requests hit the origin simultaneously. For a seat map that expires at 10:00:00 AM (on-sale time), this is catastrophic. Solutions: (a) probabilistic expiry (refresh before exact TTL), (b) Redis `SET NX` lock to allow only one request to refresh, (c) pre-warm the cache before the on-sale time as part of the release checklist.

5. **Vary header and cache key design.** A CDN caches by URL by default. If your seat-map API returns different data based on `Authorization` header, you must ensure the CDN does not cache authenticated responses — or you leak one user's data to another. Use `Cache-Control: private` for authenticated endpoints.

6. **Cost model.** Azure Front Door charges per GB of data transferred outbound and per request. Serving a 500 KB SVG seat map to 80,000 users from CDN costs ~$3 in egress. Serving it from origin costs ~$3 in egress plus 80,000 × database compute units. CDN pays for itself instantly at this scale.

## Product framing (write this first)

> **User pain:** Fans experience slow or broken seat-selection pages at the exact moment tickets go on sale, because origin servers are overwhelmed. The seat map either fails to load or shows incorrect availability — causing checkout abandonment or overselling.
>
> **MVP constraint:** The team has 2 weeks before the next major on-sale. They cannot rewrite the backend but can add a CDN layer and Redis caching without changing the API contract.
>
> **Success metric:** Origin server request rate during peak stays below 5% of total request volume (95% CDN cache hit rate for static assets); zero oversell incidents (inventory cache TTL ≤ 5 seconds).

## Micro exercise

**Scenario:**
> TicketStream's seat map for a stadium show is a 480 KB JSON file listing every seat with its status (available/sold/held). It is served by an API endpoint `GET /events/{eventId}/seatmap`. The endpoint queries the database on every request. During the on-sale event for an 80,000-seat stadium, this endpoint received 120,000 requests in 2 minutes, causing the database to hit 100% CPU and begin dropping connections. The product team says seat status only needs to be accurate within 10 seconds — fans understand slight delays. The CTO says available/sold accuracy must be within 3 seconds at checkout confirmation.

Your answer must include:
- Design the two-tier caching strategy: one tier for the seat map layout (static structure) and one tier for seat status (dynamic inventory). Specify TTL and invalidation approach for each.
- Identify which Azure services handle each tier and explain why you rejected the alternative for each.
- Describe how you prevent the cache stampede when the seat map cache expires exactly at on-sale time.
- Define the cache key structure for the seatmap endpoint to ensure personalized or A/B-tested responses do not bleed across user sessions.

## Reflection question
The product team wants to add a "hold" feature: a seat is reserved for 8 minutes while the buyer completes checkout. This means seat status changes frequently. At what point does a short TTL Redis cache stop being useful, and what pattern replaces it?

## Prior concept connection
Day 1 established stateless compute (App Service instances with no local state). Caching is the read-side complement: externalizing read state (seat maps, inventory counts) to a shared layer the same way Day 1 externalized session state. Both patterns are required together for a coherent scale-out design.

## AI coach instructions
- Ask the learner to write the Product framing section before designing anything. If they skip it, stop them.
- If the learner proposes a single Redis TTL for both seat layout and seat status, probe: "What is the cost of a stale seat layout vs. a stale inventory count? Are they the same risk?"
- Watch for the mistake of caching the entire seatmap including real-time status in the CDN layer (TTL mismatch). Log in `memory/mistakes.md`.
- Probe cache stampede: "Walk me through what happens at exactly 10:00:00 AM when 80,000 users load the seat map simultaneously and the cache has just expired."
- Update `memory/progress.md` with Week 05 Day 3 complete and note whether the learner independently distinguished static structure from dynamic inventory caching.

## Completion criteria
- Product framing section written before the design.
- Two-tier caching strategy designed with different TTLs and invalidation approaches per tier.
- Cache stampede prevention mechanism described.
- Cache key design addressed to prevent cross-user data leakage.
- AI reviewed with cloud architect and product manager perspectives.
