# Architecture Decision Records — Video Streaming Platform

## ADR-001: Multi-CDN with real-time health-based steering

### Status
Accepted

### Context
A day-and-date premiere causes an instantaneous, globally simultaneous demand spike. The last major premiere caused an 8% rebuffer rate traced to a single CDN provider's regional capacity limits.

### Options considered
- Option A: Consolidate on a single CDN provider with the highest available committed capacity.
- Option B: Multi-CDN architecture with real-time health/latency-based steering across providers.

### Decision
Option B.

### Consequences
Positive: no single CDN provider's regional issue can take down playback platform-wide; steering can also optimize for cost when providers are comparably healthy. Negative: meaningfully more operational complexity (multiple provider contracts, consistent cache-warming across all of them, steering logic to build and maintain) than a single-CDN approach.

### Review date
After each major premiere, reviewing per-CDN performance data.

---

## ADR-002: Scheduled pre-warming of edge caches ahead of known premiere times

### Status
Accepted

### Context
A cold-cache scenario at the exact moment of a globally simultaneous spike would cause an origin-fetch stampede that no origin infrastructure could realistically absorb.

### Options considered
- Option A: Reactive cache population — edge caches fill naturally as the first requests per region arrive.
- Option B: Scheduled pre-warming of edge caches across all CDN providers ahead of the known release time.

### Decision
Option B.

### Consequences
Positive: eliminates the origin-fetch-stampede failure mode entirely for scheduled, known-in-advance events. Negative: costs bandwidth warming regions that may see lower-than-forecast actual demand, and requires an accurate demand forecast per region to warm the right amount of capacity.

### Review date
After each premiere, comparing forecast vs. actual regional demand to refine the pre-warming model.

---

## ADR-003: Priority-deadline transcoding queue

### Status
Accepted

### Context
All required bitrate/codec/subtitle variants must be ready before a fixed, non-negotiable release time — a missed transcoding deadline is a hard product failure, not a delay.

### Options considered
- Option A: Best-effort, first-in-first-out transcoding queue processing.
- Option B: Priority-deadline queue that allocates burst compute capacity to guarantee completion by a fixed checkpoint ahead of release.

### Decision
Option B.

### Consequences
Positive: transcoding readiness becomes a guarantee content operations can plan a release around, not a hope. Negative: requires provisioning and testing genuine burst compute capacity well ahead of any real premiere, which is itself a cost and validation effort content operations must budget for.

### Review date
After the pilot premiere — validate the deadline-checkpoint model against real transcoding job durations.

---

## ADR-004: Layered geo-restriction enforcement at both CDN edge and DRM license service

### Status
Accepted

### Context
Regional content licensing restrictions are a legal requirement. Enforcing them only at the DRM license service means every blocked request still consumes CDN bandwidth and adds latency before rejection.

### Options considered
- Option A: Enforce geo-restriction only at the authoritative DRM license service.
- Option B: Enforce coarse geo-restriction at the CDN edge (fast, cheap rejection) plus authoritative fine-grained enforcement at the DRM license service.

### Decision
Option B.

### Consequences
Positive: reduces wasted bandwidth and latency for clearly out-of-region requests, while keeping the DRM service as the authoritative, harder-to-evade enforcement layer for edge cases (e.g., VPN evasion attempts). Negative: two enforcement layers must stay consistent with the same licensing rules, requiring a shared, centrally managed region-rules configuration rather than independently maintained logic in each layer.

### Review date
Annually, alongside content licensing agreement renewals.
