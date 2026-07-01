# System Design — Video Streaming Platform for Day-and-Date Premieres

## 1. Problem statement
Vantage Media needs a streaming architecture that handles an instantaneous, globally simultaneous traffic spike at premiere moments without rebuffering, adapts video quality in real time to heterogeneous client network conditions, enforces regional content licensing restrictions, and guarantees all required video variants are transcoded before the scheduled release deadline.

## 2. Users and stakeholders
- Subscribers (streaming content)
- Content/licensing team (regional availability rules)
- Content operations (manages the transcoding/ingestion pipeline)
- Platform engineering/SRE

## 3. Functional requirements
- Stream video with adaptive bitrate selection per client.
- Enforce region-specific content availability.
- Transcode source content into all required bitrate/codec/subtitle variants before a scheduled release time.
- Provide real-time playback telemetry for quality monitoring and CDN routing decisions.

## 4. Non-functional requirements
- Scale: instantaneous spike to ~4M concurrent streams globally within a 15-minute window for a major premiere.
- Availability: 99.95% for playback start; graceful quality degradation preferred over playback failure.
- Latency: video segment fetch P99 under 200ms from nearest edge; adaptive bitrate switch decision within 2 seconds of a detected network condition change.
- Security: DRM-protected content delivery; geo-restriction enforcement is a legal requirement, not optional.
- Compliance: regional content licensing rules enforced consistently, including reasonable anti-VPN-evasion measures.
- Cost: CDN egress is the dominant cost driver and must scale efficiently with actual viewership, not flat-rate over-provisioning.
- Operability: pre-warming schedule must be a repeatable, tested runbook for every scheduled premiere, not ad hoc per event.

## 5. Constraints and assumptions
- Premiere release times are known well in advance (scheduled by content/licensing), enabling pre-warming.
- Multiple CDN provider contracts already exist; this is a multi-CDN routing and failover design, not a single-CDN buildout.
- DRM licensing infrastructure (existing third-party DRM provider) is retained as-is.

## 6. High-level architecture
```
Subscribers (global, heterogeneous network conditions)
        |
        v
Client Player (adaptive bitrate logic: monitors buffer health, switches quality tier)
        |
        v
Multi-CDN Routing Layer (Azure Front Door + DNS-based multi-CDN steering,
informed by real-time CDN health/latency telemetry per region)
        |
   -------------------------------------------------
   |                    |                     |
   v                    v                     v
 CDN Provider A      CDN Provider B      CDN Provider C
 (edge cache)         (edge cache)        (edge cache)
   |                    |                     |
   -------------------------------------------------
                    |  (cache miss)
                    v
        Origin Storage (Azure Blob Storage, geo-replicated,
        pre-warmed to regional edge caches ahead of premiere time)
                    |
                    v
        Geo-Restriction / DRM License Service (Azure Functions ->
        validates region + entitlement before issuing playback license)

Transcoding Pipeline (separate, offline):
Content Ingestion -> Priority-Deadline Transcoding Queue (Azure Batch /
Container Apps Jobs, scaled to burst capacity ahead of known deadlines)
   -> produces all bitrate/codec/subtitle variants -> Origin Storage
   -> Deadline Tracker dashboard (content ops visibility into readiness)

Cross-cutting: Azure Monitor (real-time playback telemetry aggregation,
per-region CDN health), Azure Front Door (WAF, global routing), Key Vault,
Azure Policy (region-tagging enforcement for licensing compliance).
```

## 7. Deep dives
- **Compute:** Transcoding Pipeline uses burst-scaled compute (Azure Batch/Container Apps Jobs) sized specifically against the deadline requirement — the pipeline is designed around "must finish by T-2 hours," not "process as fast as reasonably possible."
- **Network:** Multi-CDN steering routes each viewer's session to whichever CDN has the best real-time health/latency for their region, with automatic rerouting if a CDN degrades mid-stream — this is the core mechanism absorbing the instantaneous global spike without any single CDN becoming a bottleneck.
- **Identity:** DRM license issuance is tied to subscriber entitlement (subscription tier, region) validated at playback-request time, not just at login.
- **Data:** Origin storage is geo-replicated and pre-warmed to regional edge caches ahead of the scheduled premiere time specifically because a cold cache at the exact moment of a global simultaneous spike would cause a origin-fetch stampede that no origin infrastructure could realistically absorb.
- **Observability:** Real-time playback telemetry (buffer health, bitrate switches, rebuffer events) aggregated per-region feeds both the multi-CDN routing decisions and an SRE premiere-night dashboard — the same signal serving both an automated routing function and human monitoring.
- **Business continuity:** If one CDN provider has a regional outage during a premiere, multi-CDN steering reroutes affected viewers to a healthy provider within seconds, since pre-warming has already populated multiple providers' edge caches, not just the primary one.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| CDN strategy | Multi-CDN with real-time health-based steering | Single CDN provider with the highest committed capacity | A single CDN, however large, is a single point of failure for a globally simultaneous spike; multi-CDN adds contract/operational complexity but removes the worst-case scenario of one provider's regional issue taking down playback for millions of viewers at once. |
| Cache warming strategy | Scheduled pre-warming of edge caches ahead of known premiere times | Purely reactive cache population on first request per region | A cold-cache origin-fetch stampede at the exact moment of a simultaneous global spike would overwhelm origin storage; pre-warming trades some wasted bandwidth (warming regions that turn out to have lower-than-expected demand) for eliminating the worst failure mode entirely. |
| Transcoding scheduling | Priority-deadline queue scaled to guarantee completion by a fixed time | Best-effort processing order (first-in-first-out) | A missed transcoding deadline directly means a premiere launches without all required quality/subtitle variants, a hard product failure; deadline-aware scheduling costs more in burst compute but makes the deadline a guarantee, not a hope. |
| Geo-restriction enforcement | Enforced at both CDN edge (coarse, fast) and DRM license service (fine-grained, authoritative) | Enforce only at the DRM license service | Edge-layer enforcement blocks the majority of clearly out-of-region requests cheaply and fast; relying on DRM-service-only enforcement would mean every blocked request still consumes CDN bandwidth and adds latency before the block is applied. |

**Cost:** CDN egress is the dominant cost line; multi-CDN with real-time steering also enables cost-aware routing (preferring a lower-cost provider when health/latency are comparable), turning a reliability mechanism into a cost lever as well.
**Security:** Layered geo-restriction enforcement (edge + DRM) reduces both compliance risk and wasted bandwidth from requests that were always going to be blocked.
**Scalability:** Pre-warming converts an unscalable "everyone requests at once from a cold cache" problem into a scalable "serve from warm edge caches" problem — this is the single most important architectural decision in the whole design.
**Reliability:** Multi-CDN failover directly targets the documented 8% rebuffer rate from the last major premiere, which was traced to a single CDN's regional capacity limits.
**Operations:** A repeatable, tested pre-warming runbook turns "premiere night" from a one-off fire drill into a standard operating procedure content operations can execute confidently for every release.
**Product value:** Playback quality in the first minutes of a premiere is explicitly identified as a top cancellation driver — this architecture is entirely justified by protecting that moment.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| One CDN provider has a regional capacity issue during premiere | Viewers routed to that CDN experience rebuffering | Real-time per-CDN health/latency telemetry | Multi-CDN steering automatically reroutes affected regions to a healthy provider within seconds |
| Transcoding pipeline falls behind schedule | Risk of missing variants at release time | Deadline Tracker dashboard shows real-time progress against T-2-hour checkpoint | Priority queue reallocates burst compute to the highest-priority unfinished jobs; escalation runbook for content ops if checkpoint is missed |
| Pre-warming traffic forecast is inaccurate (actual demand exceeds prediction in one region) | Under-warmed edge caches in that region cause origin-fetch spike | Real-time cache-hit-ratio monitoring per region during the premiere window | Origin storage sized with headroom above the forecast; multi-CDN steering can shift load to a better-warmed region's CDN capacity if geographically permissible under licensing |
| DRM license service latency spike under load | Playback start delayed for affected users | License-issuance latency metric | License service autoscales independently of the CDN/streaming path; cached entitlement validation for repeat requests within a session reduces load |

## 10. Security design
- **AuthN:** Subscriber authentication via existing identity provider; DRM license tied to authenticated session and entitlement.
- **AuthZ:** Region + subscription-tier entitlement checked at both CDN edge rules and the DRM license service.
- **Network exposure:** CDN edge is the only consumer-facing surface; origin storage has no direct public access, reachable only by CDN providers and the transcoding pipeline via private connectivity.
- **Secrets:** DRM signing keys and CDN provider API credentials in Key Vault.
- **Encryption:** Content encrypted at rest and delivered via DRM-protected streams; TLS for all control-plane and license-issuance traffic.
- **Audit:** Geo-restriction enforcement decisions logged for compliance reporting to content licensors.

## 11. Cost model
- Main drivers: CDN egress bandwidth (by far the largest cost line for a streaming platform at this scale), transcoding burst compute, origin storage.
- Reduction levers: Multi-CDN cost-aware routing shifts traffic toward lower-cost providers when health metrics are comparable; transcoding burst compute is scaled only ahead of scheduled deadlines, not maintained at peak capacity year-round.
- Pre-warming cost (bandwidth spent warming caches that see lower-than-forecast demand in some regions) is accepted as insurance against the much larger cost of a premiere-night reliability failure and subscriber churn.

## 12. Evolution plan
- **10x scale (subscriber growth):** Multi-CDN contracts scale by adding provider capacity/regions; the steering layer's design already assumes N providers, not a fixed 3.
- **Enterprise adoption (live event streaming):** The multi-CDN and pre-warming patterns extend to live streaming, though live content removes the transcoding-pipeline's advance-deadline assumption and would need a real-time transcoding redesign — explicitly out of scope for this system but a natural next system to design.
- **Multi-region:** As new markets are added, origin storage geo-replication and CDN provider coverage expand together, following the same pre-warming and multi-CDN steering pattern already established.
