# PM Brief — Global E-Commerce Platform Re-Architecture

## Customer problem
Flash-sale traffic spikes (60x normal) cause cascading failures in the current monolithic platform, costing an estimated $180K/minute in lost sales during outages, plus long-tail customer churn. The business cannot keep running high-value promotional events without confidence the platform will hold.

## Target users
- **Primary:** Shoppers browsing and purchasing during normal and peak traffic.
- **Secondary:** Merchandising team scheduling flash sales and managing inventory/pricing.
- **Operational:** Platform engineering and on-call SRE during peak events.

## Value proposition
A re-architected platform that treats flash-sale traffic as an expected, first-class scenario (not an incident) protects an estimated $15M in annual flash-sale revenue and removes the recurring war-room cost of every major promotional event.

## Success metrics
- Zero checkout downtime during the next 3 scheduled flash sales.
- P99 checkout latency under 800ms at 60x peak load.
- Inventory oversell rate: 0% for limited-stock "doorbuster" items.
- Reduce on-call pages during flash sales from ~40/event to under 5/event.

## MVP scope
- CDN + edge caching for product catalog browsing (read path).
- Event-driven inventory reservation service decoupled from the checkout monolith.
- Autoscaling policy with pre-warming ahead of scheduled sales.
- Real-time dashboard for merchandising to watch inventory drain live.

## Non-goals
- Full monolith decomposition into microservices (only checkout and inventory are extracted in this phase).
- New payment provider integration (existing provider is retained).
- International expansion beyond the current 3 regions.

## Risks
- **Product risk:** Merchandising may schedule a flash sale before the new architecture is fully load-tested at 60x.
- **Technical risk:** Inventory reservation service is new; a bug here directly causes overselling, a customer-facing and legally sensitive failure (order cancellations).
- **Delivery risk:** Extracting checkout from the monolith touches the highest-revenue code path in the company; requires a feature-flagged, gradual rollout.
- **Adoption risk:** Merchandising team's current promo-scheduling tools assume the old architecture's behavior (e.g., manual pre-scaling requests) and need a workflow update.

## Roadmap
- **V1:** CDN caching + read-path scaling for catalog browsing only.
- **V2:** Event-driven inventory reservation + decoupled checkout service, flagged rollout.
- **V3:** Full autoscaling automation (no manual pre-warming needed) + predictive scaling from merchandising calendar integration.
