# PM Brief — Core Banking Ledger Modernization

## Customer problem
Meridian Trust cannot ship new deposit/payment products in a competitive timeframe because every change requires COBOL changes on a mainframe with a shrinking talent pool and a hard vendor end-of-support date. Regulators also want stronger, faster audit trails than the current nightly batch reconciliation provides.

## Target users
- **Primary:** Internal product engineering teams building new account and payment products on top of the ledger.
- **Secondary:** Compliance and audit teams who query transaction history for regulatory reporting.
- **Operational:** Site reliability and ledger-operations teams who monitor postings and investigate discrepancies.

## Value proposition
A modern, API-driven ledger core cuts new-product lead time from 9 months to under 6 weeks, removes single-vendor mainframe risk, and produces a real-time, immutable audit trail that satisfies same-day regulatory reporting instead of next-day batch reconciliation.

## Success metrics
- 100% ledger posting parity with the mainframe during the 6-month parallel-run period (zero unexplained variance).
- P99 posting latency under 300ms at 150M postings/day.
- New product time-to-ship reduced from 9 months to ≤ 6 weeks.
- Zero regulatory findings related to audit trail completeness.

## MVP scope
- Event-sourced posting engine for a single product line (retail savings accounts) in one jurisdiction.
- Shadow-mode parallel posting against the mainframe with automated variance detection.
- Immutable transaction ledger with point-in-time balance reconstruction.
- Compliance reporting API for the audit team.

## Non-goals
- Replacing the mainframe's card/ATM switch integration (separate workstream).
- Multi-currency FX netting (Phase 3).
- Customer-facing UI changes (the ledger is a backend system of record only).

## Risks
- **Product risk:** Regulators may require an extended parallel-run beyond 6 months if variance is found, delaying the mainframe decommission.
- **Technical risk:** Event-sourced replay performance at 150M events/day is unproven at this organization; requires a load-test milestone before Phase 2 sign-off.
- **Delivery risk:** Mainframe subject-matter experts are scarce; reverse-engineering exact posting rules (fee timing, interest accrual order) is the critical path.
- **Adoption risk:** Internal teams accustomed to mainframe batch jobs may resist real-time event-driven workflows without training.

## Roadmap
- **V1:** Single product, single jurisdiction, shadow-mode parallel run.
- **V2:** Cutover retail savings accounts to the new ledger as system of record; expand to checking accounts.
- **V3:** Multi-jurisdiction rollout with per-region data residency; full mainframe decommission.
