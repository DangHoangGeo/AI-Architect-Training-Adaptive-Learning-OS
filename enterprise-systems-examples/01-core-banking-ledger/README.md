# Core Banking Ledger

## Real-world scenario

**Meridian Trust Bank**, a mid-size retail bank with 4 million customers across 3 countries, is replacing its 30-year-old COBOL/mainframe core banking ledger. The mainframe still works, but:

- Every new product (BNPL, instant payments, multi-currency wallets) takes 9+ months to ship because only 6 engineers on staff can read the COBOL.
- The mainframe vendor has announced end-of-support in 4 years.
- Regulators (national central bank + PSD2-equivalent regulator) require same-day auditable transaction trails and real-time fraud holds.
- The bank processes ~40 million ledger postings/day today, growing to a projected 150 million/day after the instant-payments product launches.

The bank cannot do a "big bang" cutover — a ledger error means real money is wrong in real accounts, and regulators require a parallel-run period before the mainframe is decommissioned. This is the hardest kind of enterprise system: **the cost of being wrong is regulatory action and customer funds**, not just downtime.

## Why this is architecturally hard

- **Correctness beats speed.** A double-posted or lost transaction is a regulatory incident, not a bug ticket. The design must favor strong consistency and idempotency over raw throughput.
- **Append-only auditability.** Regulators require that every balance be reconstructable from an immutable transaction history, not just a current-balance table.
- **Strangler migration, not rewrite.** The mainframe stays authoritative for existing accounts during a multi-year migration; the new system must run in shadow/parallel mode first.
- **Multi-currency, multi-jurisdiction.** Data residency rules differ per country; the ledger cannot be a single global database.

## What's in this folder

- `pm_brief.md` — the business case, target users, and phased MVP scope for the migration.
- `design.md` — full architecture: event-sourced ledger core, Azure SQL for the system of record, Service Bus for posting workflows, and the strangler-fig integration with the mainframe.
- `architecture_decisions.md` — why event sourcing over CRUD, why Azure SQL over Cosmos DB for the ledger core, why a strangler migration over lift-and-shift, and how data residency is enforced.

## Related training weeks

Week 4 (Data & Storage), Week 7 (Security Architecture), Week 11 (Business Continuity).
