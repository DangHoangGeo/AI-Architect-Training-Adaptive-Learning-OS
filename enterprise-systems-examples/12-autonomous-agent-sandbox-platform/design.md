# System Design — Autonomous Agent Sandbox Platform

## 1. Problem statement
Anvil AI needs to give each of thousands of concurrent AI agent sessions a real, freely-executable compute environment (shell, package installs, internet access) for coding and research tasks, while guaranteeing that a compromised or manipulated agent — via prompt injection or otherwise — cannot exfiltrate data, attack other tenants, or abuse the platform's network reputation, and while keeping per-session cost and boot latency low enough for an interactive product.

## 2. Users and stakeholders
- Developers/engineering teams (primary users delegating tasks)
- Enterprise security/IT admins (must approve the platform for use)
- Anvil AI platform/infrastructure team (operates the sandbox fleet)
- Third parties on the open internet (indirect stakeholder — the platform must not become an attack launchpad against them)

## 3. Functional requirements
- Provision an isolated sandbox VM per agent session on demand.
- Allow the agent to run arbitrary shell commands, install packages, and access an allowlisted set of external network destinations.
- Pause a session (snapshot VM state) when idle and resume it later with full continuity.
- Require human approval before the agent executes a defined class of destructive or externally-visible actions.
- Provide the user a live view of the agent's actions and terminal output.

## 4. Non-functional requirements
- Scale: 45,000 DAU, ~8,000 concurrent sessions at peak, sessions ranging from minutes to multi-hour unattended runs.
- Availability: 99.9% for session creation; an individual sandbox failure must not affect any other session.
- Latency: P50 session start under 3 seconds, P99 under 10 seconds.
- Security: Complete isolation between sessions (no shared kernel/filesystem access across tenants); all outbound network traffic mediated and logged.
- Compliance: Audit trail of every command executed and every network destination contacted, retained for enterprise customer review.
- Cost: Idle sessions billed down to near-zero within 60 seconds; fleet must not be provisioned at flat peak capacity year-round.
- Operability: Anomalous egress or resource-usage patterns must be detectable and actionable within 1 minute, not discovered after the fact.

## 5. Constraints and assumptions
- The product's core value proposition requires genuinely free code execution — a tool-broker model (as in the Enterprise AI Agent Platform example) is not viable here because there is no fixed set of "tools"; the agent's actions are open-ended shell commands.
- CPU-only workloads in this phase; no GPU sandboxing requirement yet.
- Team has strong Linux/virtualization systems expertise and is willing to operate specialized sandboxing infrastructure rather than relying solely on managed PaaS compute.

## 6. High-level architecture
```
User (submits a task via web/CLI)
        |
        v
Azure Front Door (WAF) -> Session Control Plane (Container Apps)
   -> Session Orchestrator: assigns a sandbox from the Warm Pool,
      tracks session lifecycle (active/idle/paused/terminated)
        |
        v
Warm Pool Manager (Container Apps + Azure VM Scale Sets)
   -> Maintains a pool of pre-booted, golden-image microVMs (Firecracker-based,
      self-managed on Azure VM Scale Set hosts) ready for near-instant assignment
   -> On assignment: microVM is claimed, session workspace volume attached,
      network egress policy applied
        |
        v
Per-Session MicroVM Sandbox (one per active session)
   -> Agent Runtime (LLM orchestration loop, shell execution, file access)
   -> Session Workspace (Azure Disk, per-session, encrypted, snapshot-capable)
   -> ALL outbound network traffic forced through:
        v
Egress Control Proxy (Container Apps, transparent HTTP(S)/DNS proxy)
   -> Allowlist enforcement (package registries, git hosts, docs domains)
   -> Anomaly detection (unrecognized destination, high-volume transfer,
      credential-pattern content inspection)
   -> Full request/response metadata logging -> Azure Monitor
        |
        v
   Internet (allowlisted destinations only; all else blocked + logged)

Human-Approval Gate: destructive/external actions (force-push, branch deletion,
external message send) intercepted by the Agent Runtime and routed through
Session Control Plane -> user notification -> approve/deny before execution.

Pause/Resume: idle-timeout triggers microVM snapshot (memory + disk state) to
Azure Blob Storage; VM host reclaimed back to Warm Pool; resume restores
snapshot to a fresh host and reattaches the session workspace.

Cross-cutting: Microsoft Entra ID (user auth, session ownership), Azure Monitor
(per-session resource/network telemetry, abuse detection dashboards), Key Vault
(golden image signing keys, proxy TLS certs), Azure Policy (network isolation
enforcement between sandbox hosts and the rest of the platform).
```

## 7. Deep dives
- **Compute:** Each session runs in its own Firecracker microVM — a lightweight VM with a minimal device model that boots in tens of milliseconds and provides true kernel-level isolation, unlike a container which shares the host kernel. This is the deliberate middle ground between "container" (fast but weaker isolation, unsuitable for genuinely untrusted arbitrary code) and "full VM" (strong isolation but too slow/heavy to boot per-session at this scale).
- **Network:** The Egress Control Proxy is the single mandatory path for all outbound traffic from every sandbox — sandboxes have no direct internet route. This is the architecture's actual security boundary, not the agent's own behavior: it's exactly the mechanism that caught the pilot's attempted credential exfiltration, since the destination wasn't on the allowlist and the attempt was logged and blocked rather than silently succeeding.
- **Identity:** Sessions are scoped to the owning user's Entra ID identity; the sandbox itself has no credentials to the platform's own control plane or other users' data — it only has what the user explicitly provides for that task (e.g., a scoped git token for one repo).
- **Data:** Session workspace is a per-session encrypted disk, never shared across sandboxes; snapshots for pause/resume are stored per-session in Blob Storage with the same encryption and access scoping as the live disk, so pausing a session never widens its exposure.
- **Observability:** Every command executed and every network request (allowed or blocked) is logged with a session correlation ID, giving both real-time abuse detection and a complete audit trail for enterprise customers who need to review what an agent actually did on their behalf.
- **Business continuity:** The Warm Pool absorbs demand spikes without live-booting VMs on the critical path; if the pool is depleted, new sessions queue briefly rather than the platform falling over, and the pool auto-scales based on observed demand patterns (time-of-day, day-of-week).

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Isolation mechanism | Firecracker microVMs (kernel-level isolation) per session | Standard containers (namespace/cgroup isolation) per session | Containers share the host kernel, and this platform runs genuinely untrusted, adversarially-manipulable code (per the pilot incident) — a container escape is a materially more realistic and higher-impact risk than for typical multi-tenant SaaS workloads; microVMs cost more in boot complexity and per-session overhead but close that gap. |
| Security enforcement layer | Network egress proxy with allowlisting, applied uniformly regardless of agent behavior | Rely on prompt-level instructions and the model's own judgment not to make unsafe requests | The pilot incident is direct evidence that model-level judgment can be overridden via prompt injection; enforcing the boundary in the network layer (outside the agent's control entirely) means the security guarantee holds even when the model's reasoning is fully compromised. |
| Boot latency strategy | Pre-warmed pool of golden-image microVMs, claimed on session start | Boot a fresh microVM from cold storage for every new session | Cold boot plus OS/runtime initialization would exceed the target latency by an order of magnitude; a warm pool trades idle compute cost (VMs sitting ready but unused) for the interactive-product latency requirement, with pool size tuned against observed demand patterns to bound the waste. |
| Session continuity | VM snapshot-based pause/resume | Require sessions to run to completion in one continuous VM lifetime, no pausing | Real coding/research tasks span hours and users don't want to keep a session (and its cost) running continuously while they're not actively engaged; snapshot/resume lets cost scale down during idle periods while preserving exact state, at the cost of needing carefully tested snapshot/restore correctness for in-flight processes and open connections. |

**Cost:** The warm pool and snapshot-based idle billing are the two biggest cost levers — together they mean the fleet is sized against actual concurrent active usage, not against total registered users or worst-case simultaneous demand held open indefinitely.
**Security:** Pushing the security boundary to the network/kernel layer instead of the prompt layer is the single most important decision in this design — it's the difference between "the agent was tricked" being a contained, logged, blocked event versus an actual breach.
**Scalability:** MicroVM density per host and warm-pool auto-scaling let the fleet grow horizontally with DAU growth without redesigning the isolation model.
**Reliability:** Per-session isolation means one user's crashed, resource-exhausted, or misbehaving agent session cannot degrade any other session or the control plane.
**Operations:** Full command and network audit logging per session is what makes both abuse investigation and enterprise customer trust possible — without it, "what did the agent actually do" is unanswerable after the fact.
**Product value:** True free code execution (not a restricted tool-broker) is the actual product differentiator versus narrower agent products — the entire architecture exists to make that freedom safe enough to sell to security-conscious customers.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Agent attempts to contact a non-allowlisted destination (e.g., prompt-injection-driven exfiltration attempt) | Blocked at the Egress Control Proxy; no data leaves the sandbox | Real-time proxy deny-log + anomaly alert | Request logged with full context and session ID; security team reviews flagged sessions; user notified their session triggered a security control |
| Warm pool depleted during a demand spike | New session starts queue instead of instant assignment | Pool depth metric vs. demand rate | Autoscaling adds pool capacity proactively based on historical demand curves; brief queuing is an acceptable degraded mode versus over-provisioning fleet-wide |
| Snapshot/resume fails to restore a session's in-flight process state correctly | User resumes to a session in an inconsistent state | Automated resume-integrity check comparing expected vs. actual process/filesystem state post-restore | Failed resume falls back to presenting the last-known-good filesystem snapshot with a clear notice, rather than silently presenting corrupted state |
| A sandbox host is compromised via a novel microVM escape technique | Potential cross-session access on that host | Host-level intrusion detection + anomalous inter-VM traffic monitoring | Affected host immediately drained and reimaged from the golden image; incident response reviews whether the escape technique requires a platform-wide patch before restoring capacity |

## 10. Security design
- **AuthN:** Entra ID for user/session ownership; sandbox hosts have no standing credentials to the control plane beyond what's needed to report health and pull the golden image.
- **AuthZ:** Session workspace and snapshot access scoped strictly to the owning user's identity; the Egress Control Proxy enforces the allowlist regardless of any credential the agent might have obtained inside its own sandbox.
- **Network exposure:** Sandboxes have zero direct internet route — the Egress Control Proxy is architecturally the only path out, and it is itself not reachable from the sandbox network except as the designated gateway.
- **Secrets:** Any credentials a user provides for a task (e.g., a git token) are injected only into that session's sandbox and never persisted in the golden image or shared pool state; Key Vault holds platform-level secrets (image signing keys, proxy certs) only.
- **Encryption:** Session workspace disks and snapshots encrypted at rest; all egress-proxy traffic TLS-inspected for policy enforcement with results logged, not just pass-through.
- **Audit:** Every command execution and network request (allowed or denied) logged with session correlation ID — this log is both the abuse-detection data source and the enterprise-customer-facing audit trail.

## 11. Cost model
- Main drivers: Warm-pool compute (VMs sitting ready), active-session compute, Blob Storage for session snapshots, Egress Control Proxy throughput.
- Reduction levers: Aggressive idle-to-pause transition (60-second target) minimizes paid active-compute time; warm-pool size tuned dynamically against observed demand curves rather than static peak provisioning; snapshot storage tiered to cooler storage classes for long-paused sessions.
- Cost is tracked per session and rolled up per customer, both for internal unit-economics visibility and as the basis for usage-based billing.

## 12. Evolution plan
- **10x scale:** Warm-pool and Egress Control Proxy both need to scale from a single-region design to sharded, regionally-distributed pools; microVM host density per physical node becomes the next capacity-planning lever.
- **Enterprise adoption (GPU workloads, customer-managed egress policies):** GPU-backed sandbox tier follows the same microVM isolation pattern with a separate warm pool; customer-specific egress allowlist extensions are layered on top of the platform-wide baseline allowlist, never replacing it.
- **Multi-region:** Regional sandbox fleets close to each customer base reduce latency and satisfy data-residency requirements, with the Session Control Plane routing new sessions to the nearest healthy region's warm pool.
