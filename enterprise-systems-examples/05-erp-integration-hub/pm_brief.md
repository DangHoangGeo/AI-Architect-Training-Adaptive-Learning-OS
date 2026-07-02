# PM Brief — ERP Integration Hub

## Customer problem
Ironclad Manufacturing's 23 systems are integrated point-to-point around its SAP core, meaning any SAP change requires manually updating up to 14 downstream integrations, taking 6 weeks and routinely causing breakages. Onboarding a new factory takes 4-6 months of integration work alone before it can go live.

## Target users
- **Primary:** Integration/platform engineering team maintaining the connections.
- **Secondary:** The 22 downstream/upstream system owners (warehouse, CRM, MES, compliance, supplier portal teams).
- **Operational:** Factory operations teams who depend on data flowing correctly and quickly between systems.

## Value proposition
An event-driven integration hub decouples every system from SAP directly, cutting the cost and time of SAP changes and new factory onboarding, while giving the business one place to monitor and troubleshoot cross-system data flow instead of 23 fragile point-to-point links.

## Success metrics
- New factory onboarding time reduced from 4-6 months to under 6 weeks.
- SAP field/schema change propagation time reduced from 6 weeks to under 1 week.
- Cross-system data-sync incidents reduced by 80% within a year of full migration.
- Number of point-to-point integrations retired: all 23 by end of program (phased).

## MVP scope
- Event hub infrastructure (Event Hubs + Service Bus) with a schema registry.
- Migrate the 3 highest-incident-rate integrations first (warehouse management, supplier portal, one MES line).
- Monitoring dashboard showing event flow health across all migrated integrations.

## Non-goals
- Replacing SAP itself (out of scope — SAP S/4HANA stays the ERP of record).
- Modernizing the legacy MES systems' own internal software (only their integration point is touched).
- Real-time bidirectional sync for every field — only fields actually consumed downstream are modeled as events initially.

## Risks
- **Product risk:** System owners may resist migrating off working (if fragile) point-to-point integrations without a clear trust-building period running both in parallel.
- **Technical risk:** Legacy MES systems speaking flat-file/OPC-UA protocols need adapter development that is harder to estimate than modern API integrations.
- **Delivery risk:** Migrating 23 integrations is a multi-year program; scope creep risk is high if not strictly phased.
- **Adoption risk:** 22 different team owners with different priorities must all agree to a shared schema registry and event contract discipline — this is as much an organizational challenge as a technical one.

## Roadmap
- **V1:** Hub infrastructure + schema registry + first 3 integrations migrated, running in parallel with existing point-to-point links.
- **V2:** Migrate remaining SAP-adjacent integrations (CRM, compliance systems); retire parallel point-to-point links as each hits a trust threshold.
- **V3:** All 23 integrations on the hub; new factory onboarding fully templated via the hub's standard adapter pattern.
