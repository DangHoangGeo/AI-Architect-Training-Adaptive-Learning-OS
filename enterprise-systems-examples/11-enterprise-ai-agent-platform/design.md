# System Design — Enterprise AI Agent Platform

## 1. Problem statement
Northwind Insurance needs a multi-agent AI system that autonomously resolves routine policy and claims-status interactions, safely escalates higher-stakes requests to humans, and treats prompt injection and tool-call authorization as bank-grade security concerns — after a red-teaming exercise showed a crafted customer message could push an agent toward an unauthorized financial action.

## 2. Users and stakeholders
- Customers (chat/email interactions)
- Human claims agents (handle escalations, approve high-stakes actions)
- AI platform team (agents, prompts, evals)
- Risk/compliance team (owns the approval-gate policy and audit requirements)
- SRE (operates the platform)

## 3. Functional requirements
- Route each conversation to the correct specialist agent via a supervisor agent.
- Answer policy questions using retrieval over policy documents (RAG).
- Look up claims status via a real-time tool call to the claims system.
- Escalate to a human agent with full conversation and reasoning context when confidence is low or the action requires approval.
- Log every agent decision, tool call, and human approval immutably.

## 4. Non-functional requirements
- Scale: 15,000 interactions/day, ~3-8 LLM calls per interaction (supervisor routing + specialist reasoning + tool-call formatting).
- Availability: 99.9% for the agent platform; graceful degradation to human-only routing on platform failure, never a hard customer-facing outage.
- Latency: P95 response time under 3 seconds per agent turn for chat.
- Security: Prompt-injection defense-in-depth; least-privilege tool access; mandatory human approval for state-changing actions.
- Compliance: Full auditability of every automated decision (who/what approved a claim-adjacent action and why), matching insurance regulatory recordkeeping requirements.
- Cost: Hard per-conversation token/step budget to prevent runaway-loop cost explosions.
- Operability: Eval suite must catch behavioral regressions before deployment, since traditional unit tests can't fully cover non-deterministic LLM output.

## 5. Constraints and assumptions
- Existing policy database, claims system, and payment system are not being replaced — the agent platform integrates with them via a new, deliberately narrow tool-broker layer.
- No agent is granted the ability to autonomously approve a claim payout in this phase; that decision boundary is a compliance policy, not a technical limitation to be optimized away.
- Azure OpenAI Service is the approved LLM provider per Northwind's existing enterprise agreement and data-residency requirements.

## 6. High-level architecture
```
Customer (chat/email)
        |
        v
Azure Front Door (WAF) -> API Management (session auth, rate limiting)
        |
        v
Input Guardrail Service (Container Apps)
   -> Azure AI Content Safety (jailbreak/injection pattern detection)
   -> Input sanitization + structural separation of "customer content" from
      "system instructions" in the prompt template (never concatenated as trusted text)
        |
        v
Supervisor Agent (Container Apps, orchestration framework e.g. Semantic Kernel)
   -> Routes to specialist agent based on intent classification
   -> Enforces per-conversation step count + token budget (hard circuit breaker)
        |
   -------------------------------------------------------
   |                    |                      |
   v                    v                      v
Policy Q&A Agent   Claims Status Agent    Escalation Agent
   -> Azure AI Search    -> Tool-Broker Service    -> Human Agent Queue
      (RAG over policy      (Container Apps)          (Service Bus ->
      documents)               |                       Claims Agent UI,
                                v                       full context handoff)
                        Tool Authorization Layer
                        (per-agent scoped permissions,
                        human-approval gate for any
                        state-changing tool call)
                                |
                                v
                        Backend Systems (Claims DB - read-only for Claims
                        Status Agent; Payment System - no automated agent
                        has write access in this phase)

Cross-cutting: Immutable Audit Log (every prompt, tool call, and decision ->
Azure SQL append-only table + Log Analytics), Azure Monitor (per-agent token
spend, latency, guardrail trigger rate), Microsoft Entra ID (service identity
per agent, scoped tool permissions), Key Vault, Azure Policy.
```

## 7. Deep dives
- **Compute:** Each specialist agent runs as its own Container Apps service with its own Entra ID managed identity and its own scoped tool permissions — the Claims Status Agent's identity simply does not have credentials for anything beyond a read-only claims lookup, so even a fully successful prompt-injection attack against that agent has nothing destructive to reach.
- **Network:** The Tool-Broker Service is the only path from any agent to a backend system; no agent holds direct credentials to the claims, policy, or payment systems, mirroring the Mainframe Gateway bulkhead pattern from the Airline Reservation example but for LLM-originated calls specifically.
- **Identity:** Per-agent Entra ID identities with least-privilege scopes are the primary authorization boundary; the LLM's own "intent" is never trusted as an authorization decision — the Tool Authorization Layer independently enforces what each agent identity is allowed to call, regardless of what the agent claims it needs.
- **Data:** Policy Q&A uses Azure AI Search for retrieval-augmented generation so answers are grounded in actual policy documents rather than model-generated claims about coverage — a hallucinated policy answer is a real liability risk for an insurer.
- **Observability:** Per-agent token spend, tool-call frequency, and guardrail-trigger rate are tracked as first-class operational metrics, not an afterthought — a spike in guardrail triggers is itself a security signal (an active injection attempt), not just a quality metric.
- **Business continuity:** If the agent platform degrades or the guardrail service is unavailable, the Supervisor Agent fails closed — routing directly to the human Escalation Agent queue rather than allowing any agent to operate without its input guardrails active.

## 8. Trade-offs

| Decision | Option chosen | Alternative | Why |
|---|---|---|---|
| Tool access model | Dedicated Tool-Broker Service enforcing per-agent least-privilege scopes, independent of the LLM's own reasoning | Grant each agent direct API credentials to backend systems, relying on prompt instructions to constrain behavior | Prompt instructions are not a security boundary — a sufficiently crafted injection can override them; a tool-broker enforcing authorization outside the LLM's control means even a fully compromised agent reasoning process cannot exceed its identity's actual permissions. |
| High-stakes action authorization | Mandatory human approval for any state-changing action, regardless of model confidence score | Allow autonomous action above a confidence threshold, with human review only for low-confidence cases | Model confidence scores are not a reliable proxy for correctness or safety, and are themselves subject to prompt-injection manipulation; treating the approval gate as a fixed policy boundary (not a tunable threshold) removes an entire class of "the model was very confident and very wrong" failure. |
| Prompt-injection defense | Defense-in-depth: input guardrail service + content safety scanning + structural prompt separation of customer content from system instructions + tool-broker authorization as a final backstop | Rely on a single content-safety filter at the input layer | No single defense layer reliably catches all injection techniques, and this is an actively evolving attack surface; layering defenses means a single bypass doesn't translate directly into an unauthorized action, since the tool-broker still independently enforces authorization even if an injection slips past the input filter. |
| Cost/loop control | Hard per-conversation step count and token budget enforced by the Supervisor Agent as a circuit breaker | Rely on reasonable-seeming agent behavior and monitor cost after the fact | A stuck or adversarially-manipulated agent loop can burn significant token spend before a human notices in a dashboard; a hard, enforced budget bounds the worst case structurally rather than relying on after-the-fact detection. |

**Cost:** Per-conversation budgets directly bound the worst-case cost of a runaway or adversarial interaction, turning an open-ended risk into a known maximum.
**Security:** Least-privilege, broker-enforced tool access is the single most important decision in this design — it's what makes the difference between "an injection attack produces a weird chat response" and "an injection attack produces an unauthorized financial transaction," which is exactly the near-miss that triggered this project.
**Scalability:** Stateless agent services scale independently per specialist type, matching each agent's actual load profile (Policy Q&A is read-heavy against a search index; Claims Status is bursty around business hours).
**Reliability:** Fail-closed behavior (route to human on guardrail service failure) means a platform degradation produces a slower resolution, never an unsafe one.
**Operations:** Guardrail-trigger-rate monitoring gives the security team a real-time signal for active injection attempts, not just a quality metric buried in a dashboard nobody checks.
**Product value:** Closing the overnight staffing gap and cutting resolution time for the two lowest-risk use cases delivers measurable value immediately, while the mandatory-approval policy for high-stakes actions protects the business from the exact risk the red-team exercise surfaced.

## 9. Failure scenarios
| Failure | Impact | Detection | Mitigation |
|---|---|---|---|
| Prompt injection attempt bypasses input guardrail | Agent reasoning is manipulated, may attempt an unauthorized tool call | Tool-Broker Authorization Layer independently rejects any call outside the agent's scoped permissions; rejection itself logged and alerted | Even a successful injection cannot exceed least-privilege tool scope; security team reviews any rejected-call spike as a potential active attack |
| Agent enters a reasoning loop (repeated tool calls, no resolution) | Escalating token cost, degraded customer experience | Per-conversation step/token budget approaching threshold | Supervisor Agent circuit breaker force-terminates the conversation and routes to human escalation once the budget is hit |
| RAG retrieval returns outdated or incorrect policy document | Policy Q&A Agent gives an inaccurate coverage answer | Automated eval suite comparing agent answers against a curated ground-truth policy Q&A set, run pre-deployment and on a recurring schedule | Retrieval index freshness monitoring; agent responses include a "confirm with your policy documents" disclaimer for coverage-specific answers pending eval suite maturity |
| Human approval queue backs up during a volume spike | Escalated customers wait longer than acceptable | Queue depth/wait-time alert | Staffing runbook for claims agent capacity; Supervisor Agent can deprioritize non-urgent escalations behind FNOL-related ones automatically |

## 10. Security design
- **AuthN:** Customers via existing Northwind identity; each agent service has its own Entra ID managed identity, distinct from every other agent's.
- **AuthZ:** Tool-Broker Service enforces per-agent-identity scoped permissions independently of LLM reasoning; state-changing actions additionally require a human-approval token before the broker executes them.
- **Network exposure:** Only Front Door/APIM and the Input Guardrail Service are reachable from customer traffic; agents and the Tool-Broker Service have no direct external exposure.
- **Secrets:** Backend system credentials live only with the Tool-Broker Service in Key Vault — individual agent identities never hold claims/policy/payment system credentials directly.
- **Encryption:** TLS everywhere; conversation content and audit logs encrypted at rest given the sensitivity of insurance/health-adjacent data discussed in some interactions.
- **Audit:** Every prompt, tool call, guardrail trigger, and human approval decision logged immutably with a conversation correlation ID — this audit trail is the primary artifact both compliance and incident response depend on.

## 11. Cost model
- Main drivers: Azure OpenAI Service token consumption (dominant cost line), Azure AI Search for RAG retrieval, Container Apps compute for agent services, Azure AI Content Safety API calls.
- Reduction levers: Per-conversation step/token budgets bound worst-case spend; caching common Policy Q&A retrieval results; routing straightforward intents to smaller/cheaper models where full reasoning capability isn't needed, reserving the most capable model for ambiguous routing decisions.
- Cost is tracked per-agent-type and per-conversation, letting the platform team see exactly which specialist agent or failure pattern (e.g., loops) is driving spend, not just an aggregate bill.

## 12. Evolution plan
- **10x scale:** Agent services scale horizontally per specialist type; Azure AI Search and the Tool-Broker Service are the components to watch for throughput limits first, given they're shared dependencies across all agent types.
- **Enterprise adoption (raise the autonomy ceiling):** Any expansion of tool-broker permissions (e.g., allowing low-dollar-threshold automated claim approvals) happens as an explicit, audited policy change backed by sustained evidence from V1/V2 audit data — not as a default outcome of the platform getting "better" over time.
- **Multi-region/new business lines:** The supervisor/specialist pattern extends by adding new specialist agents (e.g., a Home Insurance Renewal Agent) behind the same tool-broker and guardrail infrastructure, without re-architecting the security boundary that already exists.
