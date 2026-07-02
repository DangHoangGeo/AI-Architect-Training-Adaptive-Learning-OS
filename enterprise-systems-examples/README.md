# Enterprise Systems Examples

Eleven real-world, enterprise-grade systems used as reference case studies for architecture practice. Each one models a system that exists in production at real companies, sized and constrained the way an enterprise architect would actually encounter it — not a toy CRUD app.

Use these folders as:

- **Reading material** — see how a full architecture case is reasoned through end-to-end (problem, requirements, design, trade-offs, ADRs).
- **Whiteboard practice** — cover up `design.md`, read only `README.md` and `pm_brief.md`, and design the system yourself before comparing.
- **Interview rehearsal** — defend the decisions in `architecture_decisions.md` against pushback, the way a hiring panel would.
- **Portfolio inspiration** — the file structure mirrors `workshops/`, so a completed workshop can be written in the same style.

## Folder structure

Every system folder contains the same four files:

| File | Purpose |
|---|---|
| `README.md` | The business scenario: company, industry, scale, and why this system is hard. |
| `pm_brief.md` | Product framing: customer problem, users, success metrics, MVP scope, risks. |
| `design.md` | Full architecture design using the repo's `templates/system_design_template.md` structure, with Azure-native services and explicit trade-offs across cost, security, scalability, reliability, operations, and product value. |
| `architecture_decisions.md` | 4–5 ADRs recording the decisions a reviewer would push back on hardest, including rejected alternatives. |

## The 11 systems

| # | System | Industry | Core architectural challenge |
|---|---|---|---|
| 1 | [Core Banking Ledger](01-core-banking-ledger/README.md) | Financial services | Strong consistency and auditability at transaction scale |
| 2 | [Global E-Commerce Platform](02-global-ecommerce-platform/README.md) | Retail | Elastic scale for extreme, predictable traffic spikes |
| 3 | [Airline Reservation System](03-airline-reservation-system/README.md) | Travel | High-concurrency inventory with legacy mainframe integration |
| 4 | [Healthcare EHR Platform](04-healthcare-ehr-platform/README.md) | Healthcare | Regulated data, interoperability, and life-safety availability |
| 5 | [ERP Integration Hub](05-erp-integration-hub/README.md) | Manufacturing | Event-driven integration across dozens of legacy systems |
| 6 | [Payment Gateway](06-payment-gateway/README.md) | Fintech | Idempotency, fraud control, and PCI DSS scope reduction |
| 7 | [Multi-Tenant SaaS CRM](07-multi-tenant-saas-crm/README.md) | B2B SaaS | Tenant isolation, noisy-neighbor control, and per-tenant cost |
| 8 | [Real-Time Fraud Detection](08-real-time-fraud-detection/README.md) | Fintech / AI | Sub-second ML inference on streaming events |
| 9 | [Video Streaming Platform](09-video-streaming-platform/README.md) | Media | Global content delivery and adaptive bitrate at massive scale |
| 10 | [Supply Chain & Logistics Tracking](10-supply-chain-logistics-tracking/README.md) | Logistics | IoT telemetry ingestion and event-sourced shipment state |
| 11 | [Enterprise AI Agent Platform](11-enterprise-ai-agent-platform/README.md) | Insurance / AI | Prompt-injection defense and least-privilege tool authorization for autonomous agents |

## How to use this with the training system

These examples are reference material, not part of the 12-week roadmap sequence. A learner can be pointed at the folder matching the current week's topic for extra worked examples (e.g., Week 4 — Data & Storage → pair with Core Banking Ledger or ERP Integration Hub; Week 9 — AI System Design → pair with Enterprise AI Agent Platform or Real-Time Fraud Detection; Week 10 — Multi-Tenant SaaS → pair with Multi-Tenant SaaS CRM). They are not required reading and do not gate workshop access.
