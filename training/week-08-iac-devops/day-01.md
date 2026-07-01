# Week 08 Day 1 — Concept Foundation: Bicep Modules and Parameters

## Goal
Understand how Bicep modules and parameters enable a platform engineering team to build reusable infrastructure components that product teams can consume without writing raw Bicep, and without having enough access to break shared production resources.

## Why this matters
CorePlatform is the platform engineering team at Meridian Technologies, a 200-person SaaS company with 8 product teams. Currently, each product team writes its own Bicep (or ARM templates, or Terraform) and deploys directly to production with Owner-level permissions. Last quarter, a junior developer on the Payments team accidentally deleted the shared Azure Service Bus namespace because their deployment had `--mode Complete` and the namespace was not in their template. Six teams lost messaging for 4 hours.

## Core concept

1. **Modules are the unit of reuse in Bicep.** A module is a `.bicep` file that encapsulates a set of related resources. Product teams consume modules without seeing or modifying the underlying resource definitions. Example: a `webapi-stack.bicep` module that creates App Service + App Service Plan + Application Insights + Key Vault reference, with parameters for environment, SKU, and app name.

2. **Parameters control what callers can customize.** A module exposes parameters for values that legitimately vary per deployment (environment, app name, size) and keeps implementation details internal (naming conventions, diagnostic settings, private endpoint configuration). The platform team decides which parameters are exposed — not the product team.

3. **Parameter decorators enforce valid inputs.** Bicep decorators validate parameters at deployment time, before any resource is created:
   ```bicep
   @allowed(['dev', 'staging', 'prod'])
   param environment string

   @minValue(1)
   @maxValue(10)
   param instanceCount int = 1

   @secure()
   param connectionString string
   ```
   A product team passing `environment: 'production'` (wrong value) gets a validation error before deployment starts — not a runtime failure.

4. **Outputs connect modules together.** A module that creates an App Service returns its `principalId` (Managed Identity) as an output. The parent template passes that output to a Key Vault module to grant access. This creates a wiring pattern without hardcoding resource IDs.

5. **The module library is the platform team's product.** CorePlatform's job is to maintain a library of blessed modules: `storage-account.bicep`, `sql-database.bicep`, `service-bus-namespace.bicep`, `web-api-stack.bicep`. Product teams compose from this library. They do not write infrastructure from scratch. Versioning: modules live in a Bicep Registry (Azure Container Registry) and are referenced by version — `br:acr.azurecr.io/modules/web-api-stack:1.2.0`.

6. **What modules should NOT expose.** Do not expose parameters for: resource naming (platform team enforces naming conventions), network configuration (product teams do not design VNets), diagnostic settings (all resources must send logs to the central workspace). These are platform concerns that product teams cannot override.

## Learn — write notes answering these

1. What is the difference between a Bicep module and a Bicep file? When does a Bicep file become a module?
2. What are the three parameter decorators most important for security, and what specific attack does each prevent? (Hint: one prevents over-provisioning, one prevents invalid environment names, one prevents secrets from being logged.)
3. A product team says: "We need to be able to change the App Service tier ourselves — sometimes we need P3v3 during peak." How do you design the `webapi-stack.bicep` module parameters to allow this while preventing them from choosing a tier that is not on the approved SKU list?
4. The CorePlatform team wants to ensure all modules always enable diagnostic settings pointing to the central Log Analytics workspace. How do you make this happen without requiring product teams to pass the workspace ID as a parameter every time?

## Micro exercise

**Scenario:**
> CorePlatform has been asked to build the first module for the Meridian module library: a `web-api-stack.bicep` module that product teams use to deploy their API backends. Eight product teams will use this module. Requirements:
> - Must deploy: App Service, App Service Plan, Application Insights (workspace-based)
> - Allowed SKUs: B1 (dev), P1v3 (staging), P2v3 (prod) — product teams cannot choose other SKUs
> - Must always point Application Insights to the central Log Analytics workspace (CorePlatform manages this — product teams should not pass the workspace ID)
> - Must always enable HTTPS-only and minimum TLS 1.2
> - Must enforce naming convention: `{productName}-{environment}-api` (e.g., `payments-prod-api`)
> - Product teams must be able to set: product name, environment, and a map of app settings (key-value pairs)

Your answer must include:
- Write the Bicep module signature (parameters section only): list each parameter with its type, decorators, and a comment explaining why it is or is not exposed to callers.
- Explain how the central Log Analytics workspace ID is passed into the module without the product team providing it. Name the Azure mechanism (hint: it is not a parameter).
- Identify one parameter the product team asked for that you will NOT expose in the module, and explain what risk it prevents.
- Describe the versioning strategy for the module: how does a product team reference version 1.0.0, and what happens to existing deployments when CorePlatform releases version 2.0.0 with a breaking change?

## Reflection question
A product team lead says: "These modules are too restrictive — we need to add a Redis cache and the module doesn't support it." You have two options: (a) add Redis to the `web-api-stack.bicep` module, or (b) create a separate `redis-cache.bicep` module they can compose. Which do you choose and why? What principle guides this decision?

## Prior concept connection
Week 7's Azure Policy work (Day 4) showed how policy-as-code prevents security misconfigurations. Bicep modules enforce the same principle through a different mechanism: instead of blocking bad inputs at the control plane, modules prevent bad inputs from being expressed in the first place. Both are forms of "shift left" security — move the enforcement as early as possible in the deployment lifecycle.

## AI coach instructions
- Ask the learner to write the module parameter signature before anything else. The design of parameters reveals whether they understand the platform/product team boundary.
- If the learner exposes the Log Analytics workspace ID as a parameter (instead of using a central parameter store or subscription-level variable), probe: "What happens if a product team passes the wrong workspace ID? And why should they know this ID at all?"
- Watch for the mistake of exposing network-related parameters (subnet ID, private endpoint config) to product teams. Log in `memory/mistakes.md`.
- Probe the versioning question: "If you publish version 2.0.0 and remove a parameter, what breaks for teams still using 1.0.0 — and what is your migration communication plan?"
- Update `memory/progress.md` with Week 08 Day 1 complete and note whether the learner independently identified the principle of minimum parameter exposure.

## Completion criteria
- Bicep module parameter signature written with decorators and access rationale.
- Mechanism for injecting the central workspace ID without product team input explained.
- One refused parameter identified with risk justification.
- Versioning strategy described with breaking change impact analysis.
- AI reviewed with cloud architect and product manager perspectives.
