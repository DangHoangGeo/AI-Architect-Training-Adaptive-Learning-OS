# Week 08 Day 2 — Azure Service Mapping: Environment Parameterization

## Goal
Map environment parameterization strategies to Azure-native tools — parameter files, Azure Deployment Environments, and Azure App Configuration — and design a system where the same Bicep module deploys correctly to dev, staging, and production without code changes and without secrets being stored in Git.

## Why this matters
CorePlatform discovered that three product teams stored environment-specific values (including production database connection strings) in their `parameters.json` files committed to Git. One team's production Key Vault name, SQL server FQDN, and resource group ID were visible in their public GitHub repository for 48 hours before being discovered. Environment parameterization is not just a deployment convenience — it is a secrets hygiene control.

## Core concept

1. **The parameterization problem in multi-environment deployments.** The same Bicep template must deploy to dev (small, cheap, relaxed policies), staging (production-like, medium cost), and production (full scale, strict policies, secrets from Key Vault). The template is identical; the environment-specific values differ. Where do those values live?

2. **Three parameterization patterns and their trade-offs.**

   | Pattern | Where values live | Secret safety | Audit trail | Best for |
   |---|---|---|---|---|
   | `.bicepparam` files in Git | Source code repository | Dangerous for secrets | Git history | Non-secret config only |
   | Azure Key Vault reference in parameter files | `reference()` in `parameters.json` | Secrets never in Git | Key Vault access log | Production secrets |
   | Azure Deployment Environments (ADE) | Environment definitions in a catalog | Managed by platform team | ADE activity log | Self-service product team deployments |

3. **`.bicepparam` files (Bicep 0.18+).** The native Bicep parameter file format. Replaces JSON parameter files. Supports Key Vault references with type safety:
   ```bicep
   using './web-api-stack.bicep'

   param environment = 'prod'
   param productName = 'payments'
   param sqlConnectionString = az.getSecret('vault-name', 'vault-rg', 'sql-connection-string')
   ```
   The `az.getSecret()` function resolves at deployment time — the secret value is never stored in the file.

4. **Bicep Registry for module versioning + Azure Container Registry.** CorePlatform publishes modules to an Azure Container Registry (ACR) configured as a Bicep Registry. Product teams reference modules by version:
   ```bicep
   module webApi 'br:coreplat.azurecr.io/modules/web-api-stack:1.2.0' = { ... }
   ```
   This decouples the product team's deployment cadence from CorePlatform's module release cadence.

5. **Azure Deployment Environments (ADE) for self-service.** ADE allows CorePlatform to publish environment definitions (Bicep templates + parameter schemas) as a catalog. Product teams create environments from the catalog via the Azure portal or CLI — they never see the Bicep. ADE enforces that only approved templates can be deployed. This is the highest-abstraction solution for the "give teams flexibility without letting them break things" requirement.

6. **Environment-specific SKU mapping.** Hard-code environment-to-SKU mapping in the module or a central configuration store — do not trust product teams to always pass the correct SKU. Use a Bicep `var` block with an object keyed by environment:
   ```bicep
   var skuMap = {
     dev: { name: 'B1', tier: 'Basic' }
     staging: { name: 'P1v3', tier: 'PremiumV3' }
     prod: { name: 'P2v3', tier: 'PremiumV3' }
   }
   var sku = skuMap[environment]
   ```

## Learn — write notes answering these

1. What is the difference between a `.bicepparam` file and a `.json` parameter file? What specific capability does `.bicepparam` add that solves the secrets-in-Git problem?
2. Azure Key Vault references in parameter files resolve at deployment time. What RBAC permission must the deploying identity (the CI/CD service principal or Managed Identity) have on the Key Vault to resolve secrets during deployment?
3. A product team wants to use a different SQL SKU in production than what the CorePlatform module map specifies. Describe two ways to handle this request — one that maintains platform control and one that delegates control to the product team. What are the risks of each?
4. Explain what Azure Deployment Environments is and why it is a better self-service solution than giving product teams direct Bicep access to CorePlatform's module library.

## Micro exercise

**Scenario:**
> CorePlatform is designing the parameterization strategy for the Meridian module library. Constraints:
> - 8 product teams, 3 environments each (dev, staging, prod) = 24 deployment configurations
> - Production SQL connection strings, Redis connection strings, and third-party API keys must never appear in Git
> - Each product team should be able to deploy their own dev environment without CorePlatform intervention
> - Staging and production deployments must go through a CorePlatform review/approval
> - CorePlatform must be able to update a shared parameter (e.g., the central Log Analytics workspace ID) and have all teams' next deployments pick up the change automatically

Your answer must include:
- Design the parameter file strategy: which parameters go in `.bicepparam` files in Git, which are resolved from Key Vault at deployment time, and which come from a central source managed by CorePlatform (not per-team).
- Describe the Azure RBAC permissions the CI/CD service principal needs for each environment (dev vs. production should have different permissions).
- Explain how the "CorePlatform updates central workspace ID" requirement is satisfied — what does each product team's next deployment do differently?
- Describe the self-service dev environment flow using Azure Deployment Environments: who creates what in the ADE catalog, what does the product team developer do, and what Bicep permissions do they NOT need?

## Reflection question
A product team's staging environment was accidentally deployed using production parameter values (wrong `.bicepparam` file passed to the CI/CD pipeline). The staging environment now points to the production database. How does this happen, and what parameterization guardrail prevents it?

## Prior concept connection
Day 1 established module design: what parameters are exposed, what is hardcoded. Today's parameterization strategy governs the values that flow into those parameters — specifically, how secrets are kept out of Git while still being available at deployment time. The module design (Day 1) and the parameterization strategy (today) must be designed together, not independently.

## AI coach instructions
- Ask the learner to categorize the parameters (Git-safe vs. Key Vault vs. central) before asking them to describe the mechanism.
- If the learner stores connection strings in `.bicepparam` files in Git (even encrypted), probe: "What happens when a developer forks the repository or when the repository is accidentally made public? Is the secret safe?"
- Watch for the mistake of giving the CI/CD service principal Contributor on the subscription (over-privileged). Log in `memory/mistakes.md`.
- Probe the staging-pointing-to-prod scenario: "What is the blast radius if staging runs queries against the production database for 6 hours before discovery?"
- Update `memory/progress.md` with Week 08 Day 2 complete and note whether the learner independently identified the `.bicepparam` Key Vault reference mechanism.

## Completion criteria
- Parameter categorization completed (Git-safe, Key Vault, central).
- CI/CD service principal RBAC scoped per environment.
- Central parameter update mechanism described.
- ADE self-service flow described with permission boundaries.
- AI reviewed with cloud architect and security perspectives.
