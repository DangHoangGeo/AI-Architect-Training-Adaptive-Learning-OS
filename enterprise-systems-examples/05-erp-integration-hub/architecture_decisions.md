# Architecture Decision Records — ERP Integration Hub

## ADR-001: Event-driven hub over commercial iPaaS orchestration

### Status
Accepted

### Context
23 systems are integrated point-to-point around SAP. The goal is genuine decoupling, not just consolidating the same tight coupling under a different vendor's orchestration console.

### Options considered
- Option A: Commercial iPaaS platform providing point-to-point orchestration flows in one tool.
- Option B: Event-driven hub (Azure Event Hubs + Service Bus) where each consumer independently subscribes to and processes events at its own pace.

### Decision
Option B.

### Consequences
Positive: consumers are genuinely decoupled from both SAP and each other; adding or changing a consumer never requires touching SAP or other consumers. Negative: requires more in-house platform engineering investment than buying an iPaaS license, and the organization takes on ongoing operational ownership of the event backbone.

### Review date
After the first 3 integrations are migrated and running in production for one quarter.

---

## ADR-002: Mandatory schema registry with versioned, backward-compatible contracts

### Status
Accepted

### Context
The current failure mode is that a SAP field change breaks downstream integrations because there is no formal, shared contract — every integration has its own bilateral understanding of the data shape.

### Options considered
- Option A: Continue ad hoc, bilaterally-agreed payload formats per integration.
- Option B: Central schema registry enforcing versioned, backward-compatible event contracts for all publishers and consumers.

### Decision
Option B.

### Consequences
Positive: makes "a SAP change silently breaks 14 integrations" structurally impossible — incompatible changes are rejected at publish time, not discovered in production. Negative: requires schema governance discipline and a defined deprecation/migration process for breaking changes, adding process overhead the organization hasn't needed before.

### Review date
At the first attempted breaking schema change — validate the deprecation workflow works as designed.

---

## ADR-003: Dedicated adapter layer for legacy MES systems instead of requiring modernization first

### Status
Accepted

### Context
Several factory-floor MES systems only support flat-file exports or OPC-UA industrial protocols and cannot be modernized on the integration project's timeline.

### Options considered
- Option A: Block hub migration for a legacy system until its own modernization project completes.
- Option B: Build a dedicated Adapter Layer service per legacy system that translates its native protocol into hub events.

### Decision
Option B.

### Consequences
Positive: decoupling benefits reach legacy systems now, without being blocked on unrelated, multi-year modernization capital projects. Negative: adapter development effort is harder to estimate for less-documented legacy protocols, and each adapter is a bespoke piece of code that must be maintained until the underlying legacy system is eventually retired.

### Review date
Per adapter, at the legacy system's own modernization/replacement milestone.

---

## ADR-004: Per-integration strangler migration instead of a coordinated cutover

### Status
Accepted

### Context
22 different system owners each need to validate the new hub-based integration against their own workload and trust threshold before disconnecting their existing point-to-point link.

### Options considered
- Option A: Single coordinated cutover date for all 23 integrations.
- Option B: Migrate and validate one integration at a time, running old and new in parallel until each system owner signs off.

### Decision
Option B.

### Consequences
Positive: dramatically reduces the risk of a single catastrophic cutover; lets the platform team build credibility incrementally with skeptical system owners. Negative: extends the overall program timeline to multiple years and requires maintaining both old and new integration paths simultaneously during each system's transition window, adding temporary operational overhead.

### Review date
At each integration's individual cutover milestone.
