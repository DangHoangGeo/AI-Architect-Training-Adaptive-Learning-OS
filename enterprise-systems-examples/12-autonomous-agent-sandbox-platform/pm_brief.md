# PM Brief — Autonomous Agent Sandbox Platform

## Customer problem
Developers want to hand off real coding and research work — not just chat — to an AI agent: clone a repo, reproduce a bug, run the test suite, fix it, open a PR, or spend an hour researching an unfamiliar library and write a report. That requires giving the agent a real, freely-executable compute environment, which is a fundamentally different (and larger) risk than a chat assistant. A pilot incident showed that a research task with open internet access could be manipulated via prompt injection into attempting credential exfiltration, and the containment that stopped it was infrastructure, not the model.

## Target users
- **Primary:** Individual developers and engineering teams delegating coding/research tasks.
- **Secondary:** Enterprise security/IT admins who must approve the platform for use with company code and credentials.
- **Operational:** Anvil AI's own platform/infrastructure team operating the sandbox fleet.

## Value proposition
A sandbox architecture where every agent session is provably contained at the VM and network boundary — not just prompted to behave — lets Anvil AI sell into security-conscious enterprise customers who would otherwise never allow an AI agent to run arbitrary code against their systems and credentials.

## Success metrics
- Zero confirmed cross-session data leakage or successful exfiltration incidents.
- P50 session start (cold boot to agent-ready) under 3 seconds; P99 under 10 seconds.
- Idle compute cost per inactive-but-paused session reduced to near-zero within 60 seconds of last activity.
- 100% of flagged/anomalous network egress attempts logged and alertable within 1 minute.

## MVP scope
- Per-session microVM sandbox with a warm pool for fast boot.
- Egress-control proxy enforcing an allowlist (package registries, git hosts, docs sites) with anomaly logging for everything else.
- Pause/resume via VM snapshot for sessions idle beyond a threshold.
- Human-approval checkpoint for destructive or externally-visible actions (force-push, deleting a remote branch, sending external communications).

## Non-goals
- GPU-accelerated workloads (CPU-only sandbox in this phase; ML training use cases are a separate future product line).
- Fully unrestricted network egress even for enterprise/on-prem customers (allowlist model is a fixed platform guarantee, not a per-customer toggle, in this phase).
- Multi-agent collaboration within a single sandbox (one agent, one VM, one task per session for now).

## Risks
- **Product risk:** An overly restrictive egress allowlist frustrates legitimate research tasks (agent can't reach a niche but legitimate documentation site), pushing users to route around the platform's safety controls if the allowlist isn't well curated and easy to extend.
- **Technical risk:** MicroVM cold-start latency at the required P50/P99 targets, combined with true kernel-level isolation, is a genuinely hard systems engineering problem with a narrow margin for error.
- **Delivery risk:** Snapshot/resume for long-running sessions (hours to days) has to handle in-flight processes and open network connections correctly — an incompletely tested resume path risks silent state corruption.
- **Adoption risk:** Enterprise security teams will want to audit the egress-control and isolation model directly before approving the platform; the architecture needs to be independently verifiable, not just described in a sales deck.

## Roadmap
- **V1:** Warm-pool microVM sandboxes, egress-control proxy, pause/resume, human-approval checkpoint for destructive actions — coding use case only.
- **V2:** Extended allowlist curation workflow (self-service requests reviewed against abuse patterns); research/browsing use case fully supported.
- **V3:** Enterprise-managed egress policies (customer-specific allowlist extensions within the platform's fixed security model) and dedicated capacity tiers for regulated customers.
