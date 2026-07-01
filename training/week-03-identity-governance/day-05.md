# Week 03 Day 5 — Communication and refinement: Management groups, subscriptions, Azure Policy, and executive governance summary

## Goal
Design a management group and subscription structure for a professional services firm, assign Azure Policy initiatives to enforce identity and governance standards across the hierarchy, and consolidate Week 3 into a 5-bullet executive summary suitable for presenting to the firm's managing partner and CISO.

## Why this matters
A law firm that manages 12 client-facing workloads across a flat, single-subscription structure will fail its first ISO 27001 or SOC 2 audit — not because the technical controls are wrong, but because there is no demonstrable separation of duties, no governance hierarchy, and no policy enforcement evidence. Management groups and Azure Policy are the organizational skeleton that makes identity and access controls auditable and enforceable at scale.

## Core concept

1. **Management groups organize subscriptions into a governance hierarchy.** The hierarchy: Root Management Group > Management Groups (e.g., "Production", "NonProd", "Sandbox") > Subscriptions > Resource Groups. Azure Policy and RBAC assignments at a higher level inherit to all subscriptions below. A Deny policy at the "Production" management group cannot be overridden by a subscription admin — this is the mechanism for enforcing mandatory controls.

2. **Subscription design follows workload isolation principles.** Common patterns: one subscription per environment (prod/nonprod/sandbox), one subscription per business unit, or one subscription per regulated workload. For Meridian Consulting Group, separate subscriptions for `prod-client-data`, `nonprod-dev`, and `shared-services` (from Day 2) is correct — each subscription has its own RBAC boundary and spending limit, preventing a nonprod accident from affecting prod resources.

3. **Azure Policy has four effects: Audit, AuditIfNotExists, Deny, and DeployIfNotExists.** Audit logs non-compliant resources but does not block them. Deny blocks the deployment at the ARM level. DeployIfNotExists automatically remediates non-compliant resources (e.g., deploy a diagnostic setting if none exists). For governance in a law firm: Deny "creating public storage accounts" on the prod management group, DeployIfNotExists "Key Vault diagnostic settings" across all subscriptions.

4. **Policy initiatives group related policies.** The Microsoft Cloud Security Benchmark (formerly Azure Security Benchmark) initiative is a built-in set of 200+ policies covering identity, networking, data protection, and incident response. Assign it to the root management group in Audit mode first to get a baseline compliance score before switching critical policies to Deny mode.

5. **Governance scorecard for professional services firms.** Regulators and large clients increasingly require Azure Policy compliance reports as part of contract due diligence. A firm that can show "94% compliance with Microsoft Cloud Security Benchmark, with documented exceptions for 3 policies" demonstrates operational maturity. This is a portfolio artifact that wins contracts.

## Learn — write notes answering these

- Draw the management group hierarchy for a firm with two separate legal entities (a UK law firm and its US affiliate), each with prod/nonprod/sandbox subscriptions, under one Microsoft Entra tenant. What policies would you assign at each level versus at the subscription level?
- What is the difference between "built-in" Azure Policy definitions and "custom" policy definitions? When is a custom policy necessary, and what are the governance risks of proliferating custom policies?
- An Azure Policy with `DeployIfNotExists` effect requires a managed identity to perform the remediation. What RBAC role does this managed identity need, and at what scope? What is the security risk if this identity is over-permissioned?
- The firm's CISO asks for a report showing "all Azure resources that were created without the required 'CostCenter' and 'Owner' tags in the last 30 days." Which Azure service and query approach gives this data, and what policy effect would have prevented untagged resources from being created?

## Micro exercise

**Scenario:**
> **Northstar Legal LLP** currently has one Azure subscription for everything. Following the insider incident and the Week 3 remediation work, the IT director is proposing a formal governance structure. The firm has these workloads: (a) client matter management system (confidential client data, must be isolated), (b) internal HR and finance system (sensitive but not client-confidential), (c) a developer sandbox used by 4 IT staff, (d) shared services (Key Vault, monitoring, DNS). The firm must comply with ICO guidance, Solicitors Regulation Authority (SRA) cybersecurity standards, and one US client contractual requirement that prohibits commingling of data with non-US entities. The managing partner has approved a maximum of 4 subscriptions.

Your answer must include:
- A management group hierarchy diagram (text format) with all subscriptions placed correctly
- The 3 Azure Policy assignments you would make at the root management group level — specify effect (Audit/Deny/DeployIfNotExists) for each
- How you handle the US client data residency requirement within this structure (which subscription, which policy, which Azure region constraint)
- A 5-bullet executive summary for the managing partner covering: what governance structure was built, what it automatically enforces, what the compliance posture is now, what the annual governance cost is, and what the next recommended governance investment is

## Reflection question
Your Deny policy at the root management group blocks creation of public storage accounts. The IT team is building a new client portal that legitimately needs a public Azure CDN endpoint backed by Azure Blob Storage. The Deny policy prevents deployment. What is the correct governance response — an exception process, a policy exemption, or a policy redesign — and what documentation does that decision require?

## Prior concept connection
The managed identity that performs Azure Policy `DeployIfNotExists` remediation (e.g., auto-deploying Key Vault diagnostic settings) needs RBAC permissions to do so. This directly connects to Day 2 (RBAC least privilege) and Day 3 (managed identities for automation). Your governance architecture relies on the identity architecture — a Policy remediation identity with Owner-level permissions would violate the Day 2 least-privilege design and create the exact privilege escalation risk identified in Day 4.

## AI coach instructions
Do not write the management group hierarchy or the 5-bullet summary for the learner. After they submit, score the executive summary on: non-technical language, accuracy of what the governance structure actually enforces, inclusion of cost, and whether the "next investment" recommendation is realistic and specific. Watch for: (1) placing the US client data workload in a shared subscription with UK data — this fails the contractual requirement, (2) assigning all policies as Deny without an Audit phase first — this will break existing deployments, (3) the 5-bullet summary using technical jargon that a managing partner at a law firm would not understand. Probe: "The SRA cybersecurity standards require evidence that privileged access is reviewed at least annually. Which of your Azure Policy assignments provides this evidence, and how would you export it for a regulator?" Score overall Week 3 comprehension and update `memory/progress.md`. Assess whether to advance to Week 4 or add a bridge exercise on governance vs. identity gaps.

## Completion criteria
- Management group hierarchy with subscription placement written in text diagram format
- 3 root-level Azure Policy assignments specified with correct effects and justification
- US data residency requirement addressed with specific mechanism
- 5-bullet executive summary written in non-technical language
- AI scored the summary and assessed Week 3 readiness
- Mistakes, weak areas, and progress updated
- Session log created in `memory/session_logs/`
