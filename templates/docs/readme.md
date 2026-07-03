# System Design Document

> **How to use this template:** Fill every section, even if the answer is "N/A — because X". A skipped section is an unexamined risk. For small projects, keep each section to 2–5 sentences (the "one-pager" discipline). For large projects, expand as needed. The checklists at the end are pass/fail gates before build and before launch.

---

## 0. Document Control

| Field | Value |
|---|---|
| Title | |
| Author | |
| Date / Last updated | |
| Status | Draft / In review / Approved / Superseded |
| Reviewers & sign-off | |
| Related docs / tickets | |

---

## 1. Problem Statement

- **What problem are we solving?** (1–3 sentences, in the user's language, not technical language)
- **Why now?** What happens if we do nothing?
- **Who is affected?** (users, teams, systems)

## 2. Goals and Non-Goals

- **Goals:** measurable outcomes (e.g., "reduce claim-processing lookup time from 2h to 5min").
- **Non-goals:** what this design deliberately does NOT solve. (This section prevents scope creep — write at least 2.)

## 3. Users, Scale, and Assumptions

- Who are the users (internal/external), and how many?
- Expected load: requests/sec, data volume, growth over 12 months.
- **10x question:** what changes if usage is 10x the estimate?
- Key assumptions that, if wrong, invalidate this design.

## 4. Requirements

### Functional
- FR-1: …
- FR-2: …

### Non-Functional (the architect's real job)
| Dimension | Target | Notes |
|---|---|---|
| Availability (SLA/SLO) | e.g., 99.9% | Multi-AZ? Multi-region? |
| Latency | e.g., p95 < 300ms | |
| Throughput | | |
| Data durability & backup (RPO/RTO) | e.g., RPO 15min, RTO 1h | |
| Security & compliance | e.g., SOC 2, GDPR, data residency | |
| Cost ceiling | e.g., < $X/month or $/user | |
| Operability | on-call load, deploy frequency | |

## 5. Constraints

- Technical: existing systems, mandated platforms, team skills.
- Organizational: budget, deadline, headcount.
- Legal/compliance: data residency, retention, PII handling.

## 6. Options Considered (minimum 2, ideally 3)

> If there is only one option, the thinking is not done yet.

| | Option A | Option B | Option C |
|---|---|---|---|
| Summary | | | |
| Pros | | | |
| Cons | | | |
| Cost | | | |
| Risk | | | |
| Time to ship | | | |

- **Recommendation:** Option __ because …
- **Trade-off stated plainly:** "We are choosing X over Y, accepting Z."
- **Door type:** one-way (hard to reverse) or two-way (easily reversible)?

## 7. Proposed Architecture

### 7.1 High-Level Diagram
*(Insert diagram: users → edge → app tier → data tier. Show AZ/region boundaries, public vs private subnets.)*

### 7.2 Component Breakdown
For each component: purpose, technology choice (and the managed-service equivalent on AWS/Azure/GCP), scaling model (stateless? autoscaled?), and owner.

| Component | Purpose | Service (AWS / Azure / GCP) | Scaling model |
|---|---|---|---|
| Edge/CDN | | CloudFront / Front Door / Cloud CDN | |
| Load balancer | | ALB / App Gateway / Cloud LB | |
| App compute | | ECS-Lambda / App Service-Functions / Cloud Run | |
| Database | | RDS-DynamoDB / SQL DB-Cosmos / Cloud SQL-Firestore | |
| Cache | | ElastiCache / Azure Cache / Memorystore | |
| Queue/events | | SQS-SNS-EventBridge / Service Bus / PubSub | |
| Object storage | | S3 / Blob / GCS | |
| AI/ML (if any) | | Bedrock-SageMaker / Azure OpenAI / Vertex AI | |

### 7.3 Data Design
- Data model / schema outline, and why (access patterns first, schema second).
- Data classification: which data is public / internal / confidential / PII?
- Data lifecycle: retention, archival, deletion.
- Consistency requirements: strong vs eventual — where and why.

### 7.4 Network Design
- VPC/VNet CIDR plan; subnet layout (public/private, per-AZ).
- What is internet-facing (should be almost nothing) vs private.
- Service-to-service communication: private endpoints, peering, service mesh?
- Ingress path: DNS → CDN/WAF → LB → app. Egress path: NAT? Private endpoints?
- TLS termination point(s).

### 7.5 Identity & Access Design
- Human access: SSO/federation, roles, MFA, break-glass procedure.
- Workload identity: how services authenticate to each other and to cloud APIs (roles, NOT static keys).
- Least-privilege map: which role can touch which resource, and why.

### 7.6 AI-Specific Design (if applicable)
- Model access path (managed endpoint vs API), and fallback if the provider is down.
- RAG pipeline: ingestion → embedding → vector store → retrieval → generation, with authorization at retrieval time (who may retrieve which documents?).
- Token/cost controls: per-user rate limits, max context size, budget alarms.
- Prompt injection surface: which untrusted content reaches the model, and how is it constrained?
- Output handling: is model output treated as untrusted input downstream?

## 8. Failure Modes & Reliability

> For each critical component, answer: How does it fail? What does the user see? How do we detect it? How do we recover?

| Component | Failure mode | Blast radius | User impact | Detection | Recovery (auto/manual) |
|---|---|---|---|---|---|
| | | | | | |

- Single points of failure and what mitigates each.
- Degradation plan: what still works when X is down? (graceful degradation > total outage)
- Backup & restore: tested how often? RPO/RTO actually achievable?
- **Pre-mortem:** "It is 6 months later and this system failed badly. The most likely cause was: …"

## 9. Observability & Operations

- Golden signals per service: latency, traffic, errors, saturation — dashboards & alerts defined **before** launch.
- Logging: what is logged, where it's centralized, retention period, what must NEVER be logged (secrets, PII, tokens).
- Tracing across services (correlation IDs from edge to DB).
- Alerting: every alert must be actionable and have a runbook link.
- On-call & runbooks: top 5 expected incidents documented.

## 10. Cost Estimate

- Monthly estimate per environment (dev/stage/prod), with the 3 biggest line items.
- Unit economics: cost per user / per request / per 1K tokens.
- Cost traps checked: NAT gateway data processing, cross-AZ/region traffic, egress, idle GPUs, over-provisioned databases, log storage growth.
- Budget alarms configured at __% of ceiling.

## 11. Rollout & Migration Plan

- Environments and promotion path (dev → staging → prod).
- Deployment strategy: blue/green, canary, or rolling — and **rollback in under 5 minutes: how?**
- Feature flags for risky paths.
- Migration of existing data/users (if any): plan, dry run, point of no return.

## 12. Risks & Open Questions

| Risk / question | Likelihood | Impact | Mitigation / owner / due date |
|---|---|---|---|
| | | | |

## 13. Success Metrics & Checkpoints

- How we will know this worked (metrics tied to Section 2 goals).
- Checkpoint date to revisit this decision: ____
- "What would change our mind": conditions that trigger a redesign.

## 14. Decision Log

| Date | Decision | Options rejected | Reasoning | Revisit when |
|---|---|---|---|---|
| | | | | |

---
