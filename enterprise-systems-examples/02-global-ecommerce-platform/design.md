# System Design — Global E-Commerce Platform

## 1. Problem statement
Northstar Retail needs a platform that handles 60x traffic spikes during scheduled flash sales without cascading failure, while preventing inventory overselling on limited-stock items and keeping checkout latency low under load.

## 2. Users and stakeholders
- Shoppers (browsing, checkout)
- Merchandising (schedules sales, manages inventory/pricing)
- Platform engineering / SRE (operates the system)
- Finance (cares about lost-revenue exposure during outages)

## 3. Functional requirements
- Browse product catalog with search and filtering.
- Add to cart, checkout, and pay.
- Reserve limited-stock inventory atomically at checkout start, release on cart abandonment/timeout.
- Merchandising dashboard showing live inventory levels during a sale.

## 4. Non-functional requirements
- Scale: 8,000 req/sec baseline, 480,000 req/sec peak (60x) for a 4-hour window.
- Availability: 99.95% overall, with checkout treated as the highest-priority path.
- Latency: P99 catalog read < 150ms (cached), P99 checkout < 800ms under peak load.
- Security: PCI DSS scope minimized (tokenized payments, no card data stored).
- Compliance: GDPR for EU customers (data residency + right to erasure).
- Cost: Elastic — pay for peak only during the 4-hour windows, not provisioned year-round.
- Operability: No manual war-room intervention required during a scheduled flash sale.

## 5. Constraints and assumptions
- Flash sale timing is known in advance (scheduled by merchandising), enabling pre-warming.
- Existing payment provider integration is retained as-is.
- Current monolith remains for non-critical paths (account management, order history) in this phase.
- Team has Azure and .NET/Node.js experience; no appetite for a full microservices rewrite in one phase.

## 6. High-level architecture
```
Shoppers
   |
   v
Azure Front Door (global entry, WAF, routing) + Azure CDN (static assets, product images)
   |
   |-- Catalog read path -----------------------------------------
   |     Azure Front Door -> API Management -> Catalog Service (Container Apps)
   |          -> Azure Cache for Redis (hot product data, TTL'd)
   |          -> Cosmos DB (product catalog, read replicas per region)
   |
   |-- Checkout / inventory path -----------------------------------
   |     Azure Front Door -> API Management -> Checkout Service (Container Apps)
   |          -> Inventory Reservation Service (Container Apps)
   |               -> Azure Cache for Redis (atomic decrement via Lua script / RedLock pattern)
   |               -> Service Bus (reservation-confirmed / reservation-expired events)
   |          -> Existing Payment Provider (tokenized, out of PCI scope for platform)
   |          -> Azure SQL (order system of record)
   v
Merchandising Dashboard (Power BI / internal app) <- Event Hubs (inventory + sales telemetry)

Cross-cutting: Azure Monitor + Application Insights, Azure Policy (autoscale + WAF rules),
Microsoft Entra ID (internal + merchandising auth), Key Vault (secrets).
```

## 7. Deep dives
- **Compute:** Container Apps with KEDA autoscaling on HTTP concurrency and Service Bus queue depth for checkout/inventory; catalog service scales independently on request rate since its profile is entirely different (read-heavy, cacheable).
- **Network:** Azure Front Door for global anycast entry + WAF (rate limiting, bot mitigation during sales — flash sales are also bot/scalper magnets); CDN caches static assets and cacheable catalog responses at the edge.
- **Identity:** Customer auth remains in the existing identity provider; internal merchandising dashboard uses Entra ID with a `merchandising.view` role.
- **Data:** Cosmos DB for the product catalog (read-heavy, needs horizontal scale and multi-region read replicas); Azure SQL retained for orders (needs strong consistency for financial records); Redis for the inventory counter because atomic decrement-and-check must be sub-millisecond under extreme concurrency.
- **Observability:** Real-time Event Hubs stream feeds both the merchandising dashboard and an SRE "flash sale cockpit" dashboard — the same telemetry serves both a business and an operational audience.
- **Business continuity:** Circuit breakers between checkout and the existing monolith's remaining responsibilities (e.g., loyalty points) so a slow non-critical dependency cannot take down checkout.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Inventory concurrency control | Redis atomic decrement (reservation model) with TTL-based release | Pessimistic row-locking in Azure SQL | Row-locking under 480K req/sec would serialize on hot rows for doorbuster items and become the bottleneck; Redis's atomic operations handle the extreme concurrency, accepting slightly more operational complexity (needs careful TTL/expiry design) for massive throughput headroom. |
| Catalog database | Cosmos DB with regional read replicas | Scaling out Azure SQL read replicas | Catalog reads are the dominant traffic and need horizontal, multi-region scale-out with flexible schema for product variants; Cosmos DB fits that shape natively, whereas SQL read-replica fan-out doesn't scale as elastically for this pattern. |
| Scaling strategy | Scheduled pre-warming + reactive autoscaling combined | Pure reactive autoscaling only | Cold-start latency on scale-up events would still cause a visible blip at the exact moment of sale launch; pre-warming known events removes that risk while reactive autoscaling still covers unplanned spikes. |
| Checkout decoupling | Extract checkout + inventory into separate services now | Full monolith decomposition in one phase | Checkout is the highest-revenue, highest-risk path — isolating it first delivers the reliability win fastest; a full rewrite would delay the fix the business actually needs and add unnecessary risk to lower-priority paths. |

**Cost:** Autoscaling to near-zero outside peak windows keeps year-round cost low; the 4-hour flash-sale burst is the only time peak capacity is paid for, which is the core cost argument for this architecture over static over-provisioning.
**Security:** WAF + rate limiting at Front Door protects against bot-driven doorbuster scalping and credential-stuffing during high-visibility events; payment tokenization keeps PCI scope on the existing provider, not the new platform.
**Scalability:** Splitting catalog (read-heavy) from checkout (write-heavy, correctness-sensitive) lets each scale on its own bottleneck instead of one monolith scaling on its worst-case dimension.
**Reliability:** Circuit breakers isolate checkout from non-critical dependencies; the reservation model with TTL release prevents "stuck" inventory from abandoned carts silently reducing available stock.
**Operations:** A scheduled flash sale becomes a runbook-driven pre-warm event instead of an ad hoc war room, directly addressing the CEO's mandate.
**Product value:** Protecting the ~$15M/year flash-sale revenue stream while removing recurring operational firefighting is the entire business case; every technical choice is scoped to that outcome, not chasing a full rewrite.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Redis inventory cache node failure mid-sale | Reservation checks fail, checkout blocked for affected SKUs | Redis health probe + elevated checkout error rate alert | Redis deployed as a clustered, geo-redundant cache with automatic failover; checkout degrades to "reserve pending" queue rather than hard failure |
| Bot traffic spike beyond WAF rate limits | Legitimate shoppers experience slow catalog reads | Front Door WAF metrics, anomalous traffic pattern alert | Pre-configured WAF rules tightened during active sale windows; CAPTCHA challenge escalation for suspicious patterns |
| Payment provider latency spike | Checkout P99 latency breaches SLA | Dependency latency tracked in Application Insights | Async payment confirmation pattern — order is provisionally accepted, payment confirmed via webhook, with clear customer-facing "processing" state |
| Autoscaling fails to trigger in time for an unplanned spike | Elevated latency/errors for a few minutes until scale-out completes | Real-time concurrency + latency alerts | Minimum baseline replica count set above pure-average load as a safety margin; pre-warming for all known events removes this risk for scheduled sales |

## 10. Security design
- **AuthN:** Existing customer identity provider retained; internal dashboards use Entra ID.
- **AuthZ:** Merchandising dashboard scoped by Entra ID app roles; checkout service has no direct customer PII beyond what's needed for order fulfillment.
- **Network exposure:** Only Azure Front Door is internet-facing; all backend services sit behind Private Endpoints / internal ingress.
- **Secrets:** Payment provider credentials and Redis connection details in Key Vault, accessed via Managed Identity.
- **Encryption:** TLS everywhere; Cosmos DB and Azure SQL encryption at rest by default.
- **Audit:** Order and payment events logged immutably in Azure SQL for financial reconciliation and dispute handling.

## 11. Cost model
- Main drivers: Container Apps replica-hours during peak windows, Cosmos DB RU/s provisioned for catalog reads, Front Door/CDN bandwidth.
- Reduction levers: Autoscale-to-near-zero outside peak; Cosmos DB autoscale throughput instead of fixed RU/s; CDN caching reduces origin load (and therefore compute cost) for the vast majority of catalog requests.
- Flash-sale cost is now a known, bounded 4-hour spend instead of an unbounded incident-response cost from lost sales and engineering firefighting.

## 12. Evolution plan
- **10x scale:** Move catalog to multi-region active-active Cosmos DB writes if international expansion requires low-latency local writes, not just reads.
- **Enterprise adoption (more brands/storefronts):** Generalize the catalog and checkout services to be multi-tenant per storefront brand, with per-brand rate limits and dashboards.
- **Multi-region:** Extend Front Door routing and Cosmos DB read replicas to new regions as international expansion continues; inventory reservation logic stays region-agnostic since Redis Enterprise supports active-active geo-replication if needed.
