# Week 03 Day 2 — Azure service mapping: RBAC, least privilege, and Privileged Identity Management

## Goal
Map Azure RBAC roles to real access requirements, understand the difference between built-in and custom roles, and design a just-in-time privileged access model using Entra PIM. Apply this to a consulting firm where junior staff regularly over-provision themselves to "get work done."

## Why this matters
Over-permissioning is the most common identity security failure in professional services firms. When a consultant has Owner on a production subscription "because it was faster than requesting the right role," every project they touch inherits that risk. The aftermath of the Northstar Legal insider incident (from Day 1) revealed that three other former contractors had Contributor on production resource groups — none of them needed it for their original task. Least privilege is not a theory; it is a forensic finding in every breach report.

## Core concept

1. **Azure RBAC operates on four elements: security principal, role definition, scope, and role assignment.** A role assignment is the combination of "who (principal) can do what (role) where (scope)." Scope hierarchy: Management Group > Subscription > Resource Group > Resource. Assignments at a higher scope inherit down. Deny assignments override allow assignments and cannot be set by users — only Azure Blueprints and managed apps set them.

2. **Built-in roles cover 90% of scenarios — know the critical ones.** Owner (full control including role assignment), Contributor (full control except role assignment and deny), Reader (view only), User Access Administrator (manage role assignments only — dangerous if granted broadly). For specific services: Storage Blob Data Contributor, Key Vault Secrets Officer, SQL DB Contributor. Misassigning "Contributor" when "Storage Blob Data Contributor" is sufficient is a least-privilege violation.

3. **Custom roles fill genuine gaps but create maintenance burden.** A custom role is a JSON definition with specific `Actions` and `NotActions`. Use custom roles when built-in roles are either too permissive or too restrictive for a specific task. Example: a custom role for a billing analyst that allows `Microsoft.Consumption/*/read` but nothing else. Every custom role must be reviewed when Azure adds new services/actions that might inadvertently be included via wildcards.

4. **Privileged Identity Management (PIM) provides just-in-time access.** Instead of permanent Owner assignment, PIM makes the role "eligible" — the user must activate it (with MFA, justification, and approval if required) for a time-limited window (e.g., 4 hours). Activation is logged. This limits the blast radius of a compromised admin account. PIM requires Entra ID P2 license.

5. **Role assignment sprawl is operationally dangerous.** A subscription with 400 role assignments across 50 users and 30 service principals becomes unauditable. Use access reviews (Entra ID Governance feature) to automatically flag and remove stale assignments. For the consulting firm scenario, an access review running every 90 days on all Contributor+ assignments is the operational minimum.

## Learn — write notes answering these

- A junior consultant needs to deploy an Azure App Service and configure its application settings, but must not be able to create new resource groups or assign roles to others. Which built-in role, at which scope, satisfies least privilege? Is there a scenario where this is still too permissive?
- What is the difference between "eligible" and "active" in Entra PIM, and what happens to an "eligible" user's access if they never activate the role?
- A security audit finds a service principal with Owner on the production subscription, created 2 years ago with no owner identified. What are the two immediate remediation steps before you can safely remove it?
- Explain why assigning "Contributor" at the Management Group level to a DevOps engineer is worse than assigning "Contributor" at the subscription level, even if they only work in one subscription.

## Micro exercise

**Scenario:**
> **Meridian Consulting Group** has 3 Azure subscriptions: `prod-client-data` (holds client analytics workloads), `nonprod-dev` (developer sandbox), and `shared-services` (monitoring, Key Vault, DNS). Currently, all 12 consultants have Contributor on all three subscriptions permanently. Last month, a consultant accidentally deleted a production resource group while testing a script they intended to run in nonprod — they mixed up the subscription context in their CLI. The Azure practice lead wants a role design that prevents this class of accident while not slowing down development velocity.

Your answer must include:
- A role assignment matrix showing which role each user group (partners/senior consultants, junior consultants, DevOps engineers) gets on each subscription, with justification for each cell
- Which roles should be "permanent" vs. "PIM-eligible" in your design, and the maximum activation duration you recommend for each PIM-eligible assignment
- The specific Entra PIM setting that requires a second person to approve activation of Owner-level roles
- One Azure Policy that enforces subscription-context hygiene to prevent the "wrong subscription" CLI accident

## Reflection question
A senior consultant argues that PIM activation "wastes 5 minutes every time I need to fix a production issue at 2am." You have two options: (a) make their Owner role permanently active, or (b) reduce the PIM activation friction. What is the correct middle ground, and what safeguard do you retain even when reducing friction for that user?

## Prior concept connection
Day 1 established that Northstar Legal's guest accounts lacked lifecycle controls. RBAC and PIM today address the complementary problem: even properly authenticated users should only have access to what they need for as long as they need it. A guest user who authenticates correctly (passing the Day 1 controls) but holds Contributor on a production resource group is still an insider threat risk — PIM eligible roles fix this.

## AI coach instructions
Do not produce the role assignment matrix until the learner writes theirs. Watch for: (1) assigning "Owner" to DevOps engineers when "Contributor + User Access Administrator" is more precise and the exam distinction matters, (2) putting PIM on Reader roles — PIM overhead is only justified for privileged roles (Contributor and above), (3) not identifying that the "wrong subscription" accident is prevented by Azure CLI context confirmation prompts AND by restricting nonprod delete permissions from prod subscription. After review, probe: "If you use PIM for the DevOps engineer's Contributor role on prod, and they activate it, what Azure Monitor alert would tell you within 5 minutes that an unusual resource deletion occurred during the activation window?" Record any least-privilege gaps in `memory/weak_areas.md`.

## Completion criteria
- Role assignment matrix completed with justification for each cell
- PIM eligible vs permanent distinction made for each role with maximum activation duration
- Approval workflow setting named
- Azure Policy for subscription hygiene identified
- AI reviewed from cloud architect, security reviewer, and product manager perspectives
- Mistakes and weak areas recorded, progress updated
