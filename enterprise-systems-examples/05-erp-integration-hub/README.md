# ERP Integration Hub

## Real-world scenario

**Ironclad Manufacturing** runs SAP S/4HANA as its core ERP across 8 factories, but also depends on 22 other systems that must stay in sync with it: a warehouse management system, a supplier portal, a quality-management system, regional customs/compliance systems, a CRM, and several factory-floor MES (manufacturing execution systems) that were each integrated point-to-point over 15 years. Today, a single SAP field change (like adding a new plant code) requires manually updating 14 different point-to-point integrations, taking 6 weeks and routinely breaking something.

Ironclad wants an **integration hub** that decouples SAP from every downstream/upstream system through events, so a change on one side doesn't require touching all the others, and so a new factory can be onboarded in weeks instead of months.

## Why this is architecturally hard

- **N-squared integration sprawl.** 23 systems integrated point-to-point means every change has to consider up to 22 other systems; a hub-and-spoke event model must genuinely replace this, not just add a 24th direct integration.
- **Mixed integration maturity.** Some systems (SAP, CRM) have modern APIs; others (30-year-old MES on factory floors) only speak flat-file exports over FTP or OPC-UA industrial protocols.
- **Ordering and idempotency across heterogeneous consumers.** A "purchase order created" event must be processed in order by the warehouse system but can be processed idempotently and out-of-order by the analytics system — one integration layer, different guarantees needed.
- **This is inherently a change-management project as much as a technical one** — 22 system owners each need to trust the new hub before disconnecting their legacy point-to-point link.

## What's in this folder

- `pm_brief.md` — the business case tied to factory onboarding time and integration maintenance cost.
- `design.md` — event-driven hub architecture using Azure Event Hubs/Service Bus, schema registry, and a strangler approach for migrating each point-to-point integration one at a time.
- `architecture_decisions.md` — why an event-driven hub over an iPaaS-only approach, why a schema registry is mandatory, why legacy flat-file systems get an adapter layer instead of being forced to modernize first, and why migration is per-integration rather than a cutover.

## Related training weeks

Week 8 (IaC & DevOps), Week 6 (Observability & Operations), Week 4 (Data & Storage).
