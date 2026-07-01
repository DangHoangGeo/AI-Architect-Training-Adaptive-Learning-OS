# Architecture Decision Records — Global E-Commerce Platform

## ADR-001: Redis-based inventory reservation instead of row-locking

### Status
Accepted

### Context
Doorbuster items sell out in seconds during flash sales, with thousands of concurrent checkout attempts against the same SKU. The system must never oversell.

### Options considered
- Option A: Pessimistic row-level locking on the inventory table in Azure SQL.
- Option B: Redis atomic decrement (Lua script) with a reservation TTL, confirmed or released via Service Bus events.
- Option C: Optimistic concurrency (retry-on-conflict) directly against Azure SQL.

### Decision
Option B.

### Consequences
Positive: sub-millisecond atomic checks handle extreme concurrency without lock contention; TTL-based reservation automatically frees abandoned-cart inventory. Negative: introduces eventual consistency between Redis (source of truth for "available now") and Azure SQL (system of record for confirmed orders) that must be reconciled carefully; requires disciplined TTL tuning to avoid both overselling (TTL too long, stock double-counted) and false stockouts (TTL too short, valid carts lose their reservation).

### Review date
After the first flash sale under the new architecture.

---

## ADR-002: Cosmos DB for product catalog over scaled Azure SQL

### Status
Accepted

### Context
Catalog reads dominate traffic (read:write ratio is roughly 50:1) and need horizontal, multi-region scale with a flexible schema for product variants (size, color, bundle configurations).

### Options considered
- Option A: Azure SQL with read-replica fan-out per region.
- Option B: Cosmos DB with regional read replicas and autoscale throughput.

### Decision
Option B.

### Consequences
Positive: near-linear read scaling, flexible document schema fits varied product data better than a rigid relational schema, built-in multi-region replication. Negative: eventual consistency for catalog updates (acceptable — a price change propagating in seconds, not milliseconds, is not customer-visible as a correctness bug); team needs to build Cosmos DB query/indexing expertise.

### Review date
At next major catalog schema change (new product line with materially different attributes).

---

## ADR-003: Scheduled pre-warming combined with reactive autoscaling

### Status
Accepted

### Context
Flash sales are scheduled in advance by merchandising, but the platform must also survive unplanned viral traffic spikes outside those windows.

### Options considered
- Option A: Pure reactive autoscaling (KEDA/HPA-style, scale on live metrics only).
- Option B: Scheduled pre-warm to target capacity ahead of known events, with reactive autoscaling as the mechanism for everything else.

### Decision
Option B.

### Consequences
Positive: eliminates the "cold start blip" exactly at sale-launch time, the single most visible failure mode from last year's incident. Negative: requires merchandising's promo-scheduling tool to feed sale start times into the platform's scaling automation — a new integration point and process dependency.

### Review date
Every quarter, based on observed accuracy of pre-warm timing vs. actual traffic onset.

---

## ADR-004: Extract checkout and inventory first, defer full monolith decomposition

### Status
Accepted

### Context
The existing platform is a monolith. A full microservices rewrite would take 12+ months and delay the reliability fix the business needs before the next flash sale.

### Options considered
- Option A: Full monolith decomposition into microservices across all domains.
- Option B: Extract only checkout and inventory (the highest-revenue, highest-risk path) behind a strangler pattern, leaving other domains (account management, order history) in the monolith for now.

### Decision
Option B.

### Consequences
Positive: delivers the reliability improvement that matters most, fastest, with the smallest blast radius; validates the pattern before extending it further. Negative: the monolith remains a dependency for some checkout-adjacent features (e.g., loyalty points), requiring circuit breakers to prevent it from degrading the newly isolated checkout path.

### Review date
After two successful flash sales on the new architecture — evaluate whether to extract the next domain (order history / account management).
