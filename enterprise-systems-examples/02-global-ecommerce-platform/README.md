# Global E-Commerce Platform

## Real-world scenario

**Northstar Retail** runs a mid-market e-commerce platform selling home goods across North America, the UK, and the EU, doing ~$1.2B/year in revenue. Normal traffic is ~8,000 requests/sec at peak business hours. On Black Friday and their own annual "Northstar Days" flash sale, traffic spikes to **60x normal** for a 4-hour window, and a single minute of checkout downtime during that window costs an estimated $180,000 in lost sales plus reputational damage that shows up in customer churn for months.

Last year's flash sale caused a cascading failure: the product catalog database saturated, connection pools exhausted across all services, and checkout was down for 22 minutes. The CEO wants a re-architecture with one mandate: **the platform must survive 60x traffic without a war-room fire drill.**

## Why this is architecturally hard

- **Extreme, predictable-timing spikes.** Unlike random viral traffic, the spike is known in advance (marketing schedules it), which changes the trade-off — pre-warming and scheduled scaling become viable, but the system still must not fall over on unplanned spikes.
- **Read-heavy catalog, write-heavy checkout.** Product browsing and checkout have opposite scaling profiles and must be architected (and scaled) independently.
- **Inventory correctness under concurrency.** Two customers cannot both "win" the last unit of a doorbuster item — this is a classic distributed-systems race condition at enterprise stakes.
- **Global customers, regional payment/tax rules.** UK/EU require VAT handling and data residency (GDPR) different from the US.

## What's in this folder

- `pm_brief.md` — the business case for the re-architecture and what "success" means to the CEO and CFO.
- `design.md` — CDN-fronted, cache-heavy read path; event-driven inventory reservation for checkout; autoscaling strategy for planned vs. unplanned spikes.
- `architecture_decisions.md` — why Cosmos DB for the catalog, why a reservation-based inventory model over row-locking, why Azure Front Door + CDN, and why checkout is decoupled from catalog browsing.

## Related training weeks

Week 5 (Scalability & Resilience), Week 6 (Observability), Week 4 (Data & Storage).
