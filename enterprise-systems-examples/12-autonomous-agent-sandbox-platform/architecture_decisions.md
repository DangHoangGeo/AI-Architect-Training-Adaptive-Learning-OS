# Architecture Decision Records — Autonomous Agent Sandbox Platform

## ADR-001: Firecracker microVMs instead of standard containers for per-session isolation

### Status
Accepted

### Context
Each session runs genuinely untrusted, adversarially-manipulable code — the agent executes arbitrary shell commands, and a pilot incident demonstrated that prompt injection can attempt to drive that execution toward malicious ends. Standard containers share the host kernel, which is a materially weaker isolation boundary than this threat model calls for.

### Options considered
- Option A: Standard containers (namespace/cgroup isolation) per session, similar to typical multi-tenant CI/build systems.
- Option B: Firecracker microVMs providing kernel-level isolation per session, with a minimal device model for fast boot.

### Decision
Option B.

### Consequences
Positive: a container-escape-class vulnerability, which is a realistic risk given the platform intentionally runs untrusted arbitrary code, cannot cross a microVM boundary the way it could a shared-kernel container boundary. Negative: requires the team to operate specialized virtualization infrastructure (Firecracker on self-managed VM Scale Set hosts) rather than relying on a fully managed container platform, and adds boot-time engineering complexity that a warm pool (ADR-003) is needed to offset.

### Review date
Annually, or immediately following any publicly disclosed microVM escape vulnerability affecting the platform's virtualization stack.

---

## ADR-002: Network egress proxy with allowlisting as the primary security boundary

### Status
Accepted

### Context
The pilot incident showed that an agent's own reasoning can be manipulated via prompt injection into attempting a genuinely harmful action (credential exfiltration to an attacker-controlled domain). Because this platform's core product requires open-ended shell access rather than a fixed tool set, authorization cannot be enforced per-tool-call the way it is in the Enterprise AI Agent Platform example.

### Options considered
- Option A: Rely on system-prompt instructions and the model's own judgment to avoid unsafe network requests.
- Option B: Force all outbound sandbox traffic through a mandatory Egress Control Proxy enforcing an allowlist, independent of what the agent's reasoning decides to do.

### Decision
Option B.

### Consequences
Positive: the security guarantee holds even when the model's reasoning is fully compromised by injection — this is exactly the mechanism that caught the pilot incident's exfiltration attempt in practice, not in theory. Negative: legitimate but non-allowlisted destinations (a niche documentation site, an uncommon package registry) will be blocked, requiring an allowlist-curation process (see `pm_brief.md` V2 roadmap) to avoid frustrating genuine research tasks.

### Review date
Continuously via allowlist-request volume monitoring; formally reviewed quarterly.

---

## ADR-003: Pre-warmed pool of golden-image microVMs instead of cold-booting per session

### Status
Accepted

### Context
The product requires interactive-grade session start latency (P50 under 3 seconds), but a cold Firecracker microVM boot plus OS/runtime initialization takes materially longer than that budget allows.

### Options considered
- Option A: Boot a fresh microVM from cold storage for every new session request.
- Option B: Maintain a continuously replenished warm pool of pre-booted, golden-image microVMs ready for near-instant assignment.

### Decision
Option B.

### Consequences
Positive: meets the interactive latency target by removing boot time from the session-start critical path entirely. Negative: pays for idle compute capacity sitting in the pool ahead of actual demand; requires demand-forecasting-driven autoscaling of pool size to avoid either excessive idle cost or pool depletion during spikes (see Failure scenarios in design.md).

### Review date
Monthly for the first two quarters post-launch, tuning pool-size-vs-demand-curve accuracy.

---

## ADR-004: VM snapshot-based pause/resume for session continuity

### Status
Accepted

### Context
Real coding/research tasks span minutes to multiple hours, including unattended overnight runs, and users should not have to pay for continuously running compute during idle periods within a task.

### Options considered
- Option A: Require every session to run to completion within one continuous VM lifetime; no pausing.
- Option B: Snapshot VM memory and disk state on idle timeout, reclaim the host back to the warm pool, and restore the snapshot to a fresh host on resume.

### Decision
Option B.

### Consequences
Positive: idle sessions bill down to near-zero while preserving exact state, directly serving the cost model target of near-zero idle cost within 60 seconds. Negative: snapshot/restore correctness for in-flight processes and open network connections is a genuinely hard correctness problem, and an incompletely tested resume path risks presenting silently corrupted state to the user — mitigated by an automated resume-integrity check (see Failure scenarios in design.md) with a safe fallback rather than a silent failure.

### Review date
After the first quarter of production long-running-session data — review resume failure rate and root causes.
