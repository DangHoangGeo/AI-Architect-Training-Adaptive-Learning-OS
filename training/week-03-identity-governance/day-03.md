# Week 03 Day 3 — Design exercise: Managed identities, Key Vault, and secretless application access

## Goal
Design a secretless credential architecture for a consulting firm's cloud applications using managed identities and Azure Key Vault, eliminating hard-coded connection strings and API keys from application code and CI/CD pipelines. This is a full design exercise with product framing required before the technical solution.

## Why this matters
In 2023, a management consulting firm's breach originated from an API key embedded in a GitHub repository that a junior developer had pushed to a public fork "by mistake." The key had Contributor-level access to a production Azure subscription. The key was 14 months old and had never been rotated. Managed identities and Key Vault eliminate the entire class of "secret in code" vulnerabilities. If there is no secret to steal, the attack vector does not exist.

## Core concept

1. **System-assigned managed identities are tied to the resource lifecycle.** When you enable a system-assigned identity on an Azure App Service or Azure VM, Azure creates a service principal in Entra ID automatically. When the resource is deleted, the identity is deleted. The application authenticates to Azure services using this identity — no password, no certificate, no connection string. The application calls the Azure Instance Metadata Service (IMDS) endpoint to get a short-lived token.

2. **User-assigned managed identities are independent resources that can be shared.** A user-assigned identity is created as a standalone Azure resource and assigned to one or more compute resources. This is useful when multiple App Services need the same permissions to the same Key Vault — assign one user-assigned identity to all of them rather than creating separate access policies for each system-assigned identity.

3. **Key Vault is the centralized secret store, not a replacement for managed identities.** Managed identity is how an application authenticates to Azure. Key Vault is where non-Azure secrets (third-party API keys, database passwords for on-premises systems, TLS certificates) are stored. The application uses its managed identity to authenticate to Key Vault, then retrieves the third-party secret. This two-step pattern eliminates secrets from code while handling secrets that cannot be replaced by managed identity.

4. **Key Vault access has two authorization models: vault access policy and RBAC.** The modern, recommended model is Azure RBAC on Key Vault (roles: Key Vault Secrets Officer, Key Vault Secrets User, Key Vault Crypto Officer, etc.). The legacy model is vault access policy (per-user/per-principal settings). RBAC provides unified audit logs, inheritance through management groups, and PIM integration. New Key Vaults should always use RBAC authorization model.

5. **Secret rotation should be automatic.** Azure Key Vault integrates with Event Grid to fire a `SecretNearExpiry` event, which can trigger an Azure Function to rotate the secret and update dependent services. For SQL connection strings, the rotation function updates the password in both SQL and Key Vault atomically. Without automated rotation, secrets accumulate age and become compliance liabilities.

## Learn — write notes answering these

- An Azure Function needs to read a secret from Key Vault and write to an Azure Blob Storage container. Design the minimum set of managed identity assignments and Key Vault RBAC roles required. State whether you use system-assigned or user-assigned identity and why.
- What is the Azure Instance Metadata Service (IMDS) endpoint, and why does it only work from inside Azure compute? What does the application code do differently when using managed identity vs. a connection string?
- A Key Vault has soft-delete and purge protection enabled. A developer accidentally deletes a secret that an application depends on. Walk through the exact steps to recover the secret, including the maximum time window before recovery is impossible.
- When would you use Key Vault references in Azure App Service configuration rather than having the application code call the Key Vault SDK directly? What is the operational difference?

## Product framing (write this first)

> **User pain:** Meridian Consulting Group's developers store database passwords and third-party API keys in Azure App Service application settings in plaintext. When a developer leaves, there is no process to rotate those credentials. The security team cannot audit which applications use which secrets. An audit finding requires the firm to demonstrate secret rotation within 30 days.
>
> **MVP constraint:** Migrate the 3 most critical applications (client data API, document processing service, reporting dashboard) to secretless access within 4 weeks. The applications are built on Azure App Service and use Azure SQL, Azure Blob Storage, and one third-party payment API (which cannot use managed identity). Existing application code can be changed but not redeployed to a new hosting plan. One developer available part-time.
>
> **Success metric:** Zero plaintext secrets in App Service application settings for the 3 applications within 30 days, verified by Azure Policy compliance report. Secret rotation for the payment API key automated with 90-day rotation period.

## Micro exercise

**Scenario:**
> **Meridian Consulting Group** runs three applications on Azure App Service: (1) a `client-data-api` that reads/writes to Azure SQL Database and reads blobs from Azure Storage, (2) a `document-processor` that calls a third-party contract analysis API (API key required, provided by vendor), and (3) a `reporting-dashboard` that only reads from the same Azure SQL Database as the client-data-api. All three currently store credentials in App Service application settings as plaintext environment variables. The firm has one Key Vault in the `shared-services` subscription. App Services are in the `prod-client-data` subscription (different subscription from the Key Vault).

Your answer must include:
- For each of the three applications: the identity type (system-assigned vs. user-assigned managed identity) and justification
- The RBAC role assignments on Azure SQL, Azure Storage, and Key Vault for each identity
- How the `document-processor` retrieves the vendor API key using Key Vault — including the specific App Service feature that avoids changing application code
- A cross-subscription consideration: the Key Vault is in a different subscription than the App Services — what must be configured to make the RBAC assignments work

## Reflection question
You have eliminated all plaintext secrets from App Service application settings. Three months later, a new contractor joins and, following old documentation, adds a new application setting with a hardcoded SQL connection string. What Azure Policy definition (built-in or custom) would detect this configuration violation, and at which scope would you assign it?

## Prior concept connection
Day 2 established that RBAC scope matters — a role assigned too broadly is a least-privilege violation. The managed identity assignments you design today must follow the same principle: `client-data-api`'s managed identity should have `Key Vault Secrets User` (read-only) not `Key Vault Secrets Officer` (read/write/delete), because the application only needs to read secrets, not manage them. The RBAC design from Day 2 directly constrains the identity design here.

## AI coach instructions
Do not reveal the solution before the learner writes theirs. Watch for: (1) giving the `client-data-api` and `reporting-dashboard` the same managed identity "for simplicity" — this violates least privilege because the reporting-dashboard should not have write permissions to SQL or Storage, (2) forgetting that cross-subscription Key Vault RBAC requires the App Service's managed identity to be granted the role at the Key Vault scope in the `shared-services` subscription directly — it does not inherit from the `prod-client-data` subscription, (3) not using Key Vault references (App Service feature) for the vendor API key, instead writing SDK calls — the MVP constraint says "application code can be changed but not redeployed to a new hosting plan," and Key Vault references require no code change. After review, probe: "If the vendor rotates the payment API key and sends you a new value, how does your design handle updating Key Vault and ensuring the App Service picks up the new value without a restart?" Record any managed identity confusion in `memory/mistakes.md`.

## Completion criteria
- Product framing (pain, constraint, metric) written before the technical design
- Identity type chosen for each application with justification
- All RBAC role assignments listed for all three services
- Key Vault reference feature described for vendor API key
- Cross-subscription RBAC configuration addressed
- AI reviewed from cloud architect, security reviewer, and product manager perspectives
- Mistakes recorded and progress updated
