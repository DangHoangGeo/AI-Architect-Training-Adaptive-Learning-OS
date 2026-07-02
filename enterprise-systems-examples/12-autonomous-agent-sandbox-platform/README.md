# Autonomous Agent Sandbox Platform

## Real-world scenario

**Anvil AI** runs a cloud platform where developers hand an AI agent a coding or research task and it works autonomously — cloning repos, installing dependencies, running builds and tests, browsing the web for documentation, and opening pull requests — for anywhere from a few minutes to several unattended hours. This is the "Devin / Claude Code on the web"-shaped product category: 45,000 daily active users, ~8,000 concurrent agent sessions at peak, each session backed by its own isolated virtual machine so the agent can run arbitrary shell commands freely, the way a human engineer would on their own laptop.

That freedom is also the entire risk surface. During a pilot, a customer's research agent fetched a documentation page that contained a hidden prompt-injection payload; the injected instructions convinced the agent to read an AWS credential left in the workspace and attempt to POST it to an attacker-controlled domain. The attempt was caught — but only because an *outbound network egress proxy* happened to be logging and rate-limiting unrecognized destinations, not because anything in the agent's own reasoning stopped it. That near-miss is the reason this system's security model lives at the network and kernel layer, not in the prompt.

## Why this is architecturally hard

- **The agent has a real shell, not a tool-broker.** Unlike the Enterprise AI Agent Platform example (#11), where every action is mediated by a narrow, permissioned tool-broker, here the entire point of the product is that the agent can run *arbitrary* code — `curl`, `pip install`, `git push`, anything. Authorization can't be enforced per-tool-call because there's no fixed set of tools; it has to be enforced by the sandbox boundary itself.
- **Thousands of untrusted-code VMs at low latency and low cost.** Booting a full VM per session in the tens-of-seconds a user is willing to wait is a hard systems problem, and 8,000 concurrent VMs running 24/7 is a real infrastructure bill — the design has to reconcile "boots fast" with "costs little" with "isolates completely," three goals that normally trade off against each other.
- **Data exfiltration and abuse are the dominant threat, not data corruption.** An agent with shell + internet access is a plausible vector for credential theft, cryptomining, spam, or using the platform's IP reputation to attack third parties — this is closer to hosting-provider abuse prevention than typical application security.
- **Sessions must pause and resume across hours or days.** A long-running research task or an unattended overnight job needs its VM state (filesystem, running processes) to survive being suspended and billed down to near-zero, then resumed exactly where it left off.

## What's in this folder

- `pm_brief.md` — the business case for autonomous agent execution and the abuse/security posture customers are buying into.
- `design.md` — per-session microVM sandboxing, a warm-pool/snapshot strategy for fast boot, an egress-control proxy as the primary security boundary, and pause/resume session state management.
- `architecture_decisions.md` — why isolation is enforced by microVMs instead of containers, why network egress is allowlisted/proxied rather than trusted, why a warm pool trades idle cost for latency, and why destructive/external actions still get a human-approval checkpoint even with full shell access.

## Related training weeks

Week 9 (AI System Design), Week 2 (Networking & Secure Boundaries), Week 7 (Security Architecture), Week 5 (Scalability & Resilience).

## How this compares to the Enterprise AI Agent Platform (#11)

Both are agent systems, but they sit at opposite ends of the autonomy/containment spectrum:

| | #11 Enterprise AI Agent Platform | #12 Autonomous Agent Sandbox Platform |
|---|---|---|
| Agent capability | Fixed set of narrow, brokered tools | Arbitrary shell commands, package installs, network access |
| Security boundary | Application-layer tool-broker authorization | Kernel/network-layer sandbox isolation + egress proxy |
| Failure mode if compromised | Rejected tool call (bounded blast radius by design) | Requires the sandbox boundary itself to hold — no smaller boundary exists |
| Right tool for | Regulated, narrow-purpose automation (claims, payments) | Open-ended coding/research work with no fixed task shape |
