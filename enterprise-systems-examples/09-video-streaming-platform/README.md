# Video Streaming Platform

## Real-world scenario

**Vantage Media** operates a subscription video streaming service (a Netflix/Disney+-style product) with 12 million subscribers globally. Their signature move is simultaneous "day-and-date" releases: a new season premiere drops at midnight local time across every region at once, producing an instantaneous, massive, globally-distributed traffic spike as millions of subscribers start streaming within the same 15-minute window — a fundamentally different scaling problem than gradual traffic growth.

Viewers on a poor mobile connection in a rural area and viewers on gigabit fiber both need a smooth playback experience; a rebuffering event in the first 30 seconds of a premiere is one of the top drivers of subscription cancellation. The platform must also serve content licensed differently per region (geo-restriction is a legal requirement, not a feature choice) while transcoding new content into dozens of bitrate/format variants before each release.

## Why this is architecturally hard

- **Instantaneous global simultaneous demand**, not gradual ramp-up — the CDN and origin infrastructure must be pre-warmed, not reactively scaled.
- **Adaptive bitrate streaming across wildly heterogeneous client network conditions**, requiring per-viewer real-time quality adaptation without visible rebuffering.
- **Legally mandated geo-restriction** enforced correctly and consistently, including for VPN-evasion attempts, without over-blocking legitimate cross-border travelers.
- **Massive transcoding pipeline** that must finish producing every required bitrate/codec/subtitle variant before the scheduled release moment — a hard deadline, not a best-effort batch job.

## What's in this folder

- `pm_brief.md` — the subscriber-retention business case tied to premiere-night playback quality.
- `design.md` — multi-CDN architecture with pre-warming, adaptive bitrate streaming, transcoding pipeline with deadline guarantees, and geo-restriction enforcement.
- `architecture_decisions.md` — why multi-CDN over single-CDN, why transcoding uses a priority-deadline queue, why geo-restriction is enforced at multiple layers, and why playback telemetry drives real-time CDN routing decisions.

## Related training weeks

Week 5 (Scalability & Resilience), Week 6 (Observability & Operations), Week 2 (Networking & Secure Boundaries).
