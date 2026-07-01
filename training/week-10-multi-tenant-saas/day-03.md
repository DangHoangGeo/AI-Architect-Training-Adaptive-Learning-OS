# Week 10 Day 3 — Design exercise: Per-tenant Configuration and Automated Onboarding

## Goal
Design PeopleOS's tenant onboarding pipeline — the automated process that provisions infrastructure, configures per-tenant settings, and activates a new enterprise customer in under 4 hours with no manual steps. You will define the onboarding state machine, the Azure services involved, and the rollback procedure when provisioning fails.

## Why this matters
PeopleOS signs a contract with a 10,000-employee insurance company. The sales team promises go-live in 2 business days. If tenant onboarding requires a DevOps engineer to manually create databases, configure Key Vault secrets, update DNS records, and set IAM permissions, it takes 3 days minimum and introduces human error. One typo in a connection string and the new tenant's payroll data routes to an existing tenant's database. Automated onboarding is not a nice-to-have — it is the difference between a scalable business and one that cannot grow past 20 customers.

## Product framing (write this first)
> **User pain:** PeopleOS's implementation team spends 12 hours per enterprise onboarding on manual Azure provisioning steps, during which a misconfiguration can silently corrupt another tenant's data. Enterprise customers complain that go-live takes "weeks."
> **MVP constraint:** The onboarding pipeline must provision a new tenant with an isolated database, Key Vault secrets, and a configured application namespace in under 4 hours, with zero manual steps after the sales team fills in a 10-field onboarding form.
> **Success metric:** 100% of new tenant onboardings complete without requiring a DevOps engineer to touch the Azure portal, measured over 90 days.

## Core concept

1. **Tenant onboarding is a multi-step workflow with compensation logic.** If database provisioning succeeds but Key Vault secret creation fails, the system must roll back (delete the database) to avoid orphaned resources. Azure Durable Functions (fan-out/fan-in with compensation) is the correct orchestration pattern for this workflow.

2. **Infrastructure as Code is the enforcement layer.** Each tenant's Azure resources are provisioned by a Bicep template parameterized by `tenant_id`, `region`, `isolation_tier`, and `compliance_profile`. The template is stored in Git and run by a pipeline — never manually. This ensures every tenant's environment is identical except for its parameters.

3. **Azure App Configuration stores per-tenant feature flags and settings.** Each tenant can have different module enablement (e.g., payroll module on/off), UI customization, and integration endpoints (SAML IdP, payroll provider). App Configuration with tenant-scoped labels provides this without per-tenant config files.

4. **Azure Key Vault per tenant vs. shared Key Vault with per-tenant secrets.** For highly isolated tenants (bank, regulated industries), a dedicated Key Vault per tenant provides clear audit boundaries. For standard tenants, a shared Key Vault with `{tenant_id}/db-connection-string` naming convention is sufficient. The choice maps to the isolation tier from Day 1.

5. **The onboarding form is the contract between sales and engineering.** It captures: tenant name, primary region, isolation tier, compliance profile (GDPR, HIPAA, etc.), initial admin user, SSO configuration. Engineering must never start provisioning without a complete, validated form. Azure Logic Apps or Power Automate can trigger the provisioning pipeline on form submission.

6. **DNS and custom domain configuration is always the last step and the most likely to fail.** If PeopleOS supports custom domains (e.g., `hr.acmecorp.com`), Azure Front Door custom domain verification requires DNS propagation which can take hours. The onboarding state machine must handle this asynchronously without blocking the rest of provisioning.

## Learn — write notes answering these

- What is the "compensation transaction" pattern in Azure Durable Functions, and how does it differ from a simple try/catch rollback in a stateless Azure Function?
- How does Azure Deployment Environments (ADE) differ from running Bicep templates directly in a pipeline, and when would you use ADE for tenant provisioning?
- What is an Azure Managed Application and how could PeopleOS use it to deploy a fully isolated tenant into the customer's own Azure subscription?
- How do you validate a new tenant's SSO configuration (SAML 2.0 or OIDC) during onboarding before marking the tenant as "active"?

## Micro exercise

**Scenario:**
> PeopleOS needs to onboard GlobalBank, a 25,000-employee financial institution. GlobalBank's requirements: (1) dedicated Azure SQL database in West Europe with zone redundancy, (2) dedicated Key Vault, (3) SSO via their existing Azure AD (Entra ID) tenant using OIDC, (4) custom domain `hr.globalbank.com` pointing to PeopleOS's application, (5) GDPR data processing mode enabled (all PII encrypted at rest with a customer-managed key). The GlobalBank IT team estimates they can respond to provisioning requests within 2 hours during business hours.

Your answer must include:
- A numbered onboarding workflow (state machine steps) from "form submitted" to "tenant active", identifying which steps are automated, which require GlobalBank IT input, and which can run in parallel.
- The Bicep template parameters you would define for GlobalBank's provisioning (list at least 8 parameters with their types).
- How you handle the failure scenario: database provisioning completed, Key Vault creation completed, SSO validation failed because GlobalBank's IdP was unavailable. What does the system do?
- How the application validates that GlobalBank's employees are routing to GlobalBank's database on first login (not another tenant's).

## Reflection question
GlobalBank's onboarding completes successfully. Six months later, they want to upgrade from "Professional" isolation tier to "Enterprise" isolation tier, which means migrating from a shared application namespace to a dedicated App Service plan. Design the migration path — it must be zero-downtime and produce no data loss. What is the riskiest step?

## Prior concept connection
In Week 10 Day 2 you designed the partitioning strategy, including the shard map that routes tenant requests to the correct database. Today's onboarding pipeline must write a new entry to that shard map during provisioning. Identify exactly which step in your onboarding workflow updates the shard map, and what happens if this step fails after the database has already been created.

## AI coach instructions
The learner must write the Product framing section first — do not proceed without it. Watch for: (1) an onboarding workflow that is entirely sequential (steps that can parallelize should be called out), (2) no rollback/compensation logic, (3) treating SSO configuration as a one-step action rather than a request-response interaction with GlobalBank's IT team. Probe: "Your onboarding workflow marks the tenant as 'active' after all steps complete. But GlobalBank's employees won't log in for another 3 days. How do you charge for tenant infrastructure during this inactive period, and how does that affect your pricing model?" Update `memory/weak_areas.md` if the learner omits the shard map update step.

## Completion criteria
- Learner wrote Product framing before the design.
- Learner produced a numbered onboarding workflow distinguishing automated, human, and parallel steps.
- Learner listed at least 8 Bicep template parameters.
- Learner described a compensation procedure for the SSO failure scenario.
- Learner explained the first-login routing validation.
- AI reviewed with cloud architect and product manager perspectives.
- Any mistakes added to `memory/mistakes.md`.
