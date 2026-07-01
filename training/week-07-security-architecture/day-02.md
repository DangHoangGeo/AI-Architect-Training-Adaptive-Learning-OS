# Week 07 Day 2 — Azure Service Mapping: Zero Trust Principles

## Goal
Map Zero Trust principles to specific Azure services in the VaultBridge financial API architecture, understand how each principle reduces the blast radius of a compromised partner or a compromised internal service, and explain why perimeter-based security alone is insufficient for a multi-tenant API platform serving external fintech partners.

## Why this matters
VaultBridge's original architecture assumed that traffic from fintech partners that passed API key authentication was trustworthy. When Partner G's API key was stolen via a phishing attack on their developer, the attacker had full access to all 15 partners' client data for 6 hours before the key was manually revoked. A Zero Trust architecture would have limited the blast radius to Partner G's authorized scope only — and behavioral anomaly detection would have flagged the unusual access pattern within minutes.

## Core concept

1. **Zero Trust in one sentence.** Never trust, always verify — even traffic that is already inside your network. Verify explicitly (authenticate and authorize every request), use least-privilege access (grant the minimum permissions needed), and assume breach (design as if the perimeter has already been compromised).

2. **Three Zero Trust principles mapped to Azure.**
   - **Verify explicitly:** Every request must prove identity and be authorized for the specific action. Azure services: Azure AD (Entra ID) for identity, Azure API Management for policy enforcement, Managed Identities for service-to-service authentication (no passwords), Conditional Access for human access.
   - **Least-privilege access:** OAuth 2.0 scopes restrict what each partner can do. A fintech with a "read:balance" scope cannot call payment initiation. Azure RBAC on management plane. Field-level authorization in application code.
   - **Assume breach:** Segment the network so that a compromised component cannot reach everything. Use Private Endpoints so the backend database is never reachable from the internet. Use Azure Defender for Cloud to detect anomalous behavior. Encrypt data at rest and in transit — even internal traffic.

3. **Managed Identity eliminates secrets from code.** Instead of storing a SQL connection string with username and password in an environment variable (where it can be leaked), a Managed Identity allows the App Service to authenticate to Azure SQL using its Azure AD identity. No password to rotate, no secret to steal from source code or logs.

4. **OAuth 2.0 client credentials flow for partner authentication.** The correct pattern for machine-to-machine partner authentication: partner registers an app in Azure AD (Entra ID), receives a `client_id` and `client_secret`, and exchanges credentials for a JWT access token with specific scopes. The API validates the token and enforces scopes on every request. This replaces API keys with auditable, expiring, scope-limited tokens.

5. **Conditional Access for human operators.** Humans accessing the VaultBridge management plane (Azure portal, API Management portal) must satisfy Conditional Access policies: MFA required, compliant device required, access from registered location only. This is the human-facing counterpart to Managed Identity for services.

6. **Network Zero Trust with Private Endpoints.** Even with strong authentication, the attack surface is smaller if the backend SQL database is not reachable from the internet at all. Azure Private Endpoint puts a private IP address for the SQL server inside your VNet. DNS is configured so that the SQL FQDN resolves to the private IP. An attacker who compromises an API key cannot directly attack the database — they can only reach what the API exposes.

## Learn — write notes answering these

1. What is a Managed Identity and how does it eliminate credential exposure risk for the VaultBridge App Service connecting to Azure SQL?
2. Explain the OAuth 2.0 client credentials flow. What does the fintech partner send, what does Azure AD return, and what does the API validate on every request?
3. A fintech partner has a valid access token with scope `read:balance`. They attempt to call `POST /payments/initiate`. Describe the full authorization chain: where is the scope enforced, and what HTTP response does the partner receive?
4. Why is a Private Endpoint for Azure SQL not sufficient on its own as a security control? What must be true about the compute layer (App Service) that connects to it?

## Micro exercise

**Scenario:**
> VaultBridge's current architecture has these security weaknesses identified in the Day 1 threat model:
> 1. API key authentication (no scoping, no expiry, no revocation without manual intervention)
> 2. App Service connects to Azure SQL using a connection string stored in application settings (visible in the portal)
> 3. Azure SQL has a public endpoint enabled (accessible from any IP with correct credentials)
> 4. No MFA required for engineers accessing the Azure portal
> 5. All 15 fintech partners share the same API subscription — no partner-level isolation
>
> The CISO has approved a 4-week security hardening sprint.

Your answer must include:
- Design the new authentication model: specify Azure AD app registration approach, OAuth 2.0 flow, token validation steps, and how partner isolation is enforced (separate subscriptions or separate scopes?).
- Specify the Managed Identity configuration: which identity type (system-assigned or user-assigned), which Azure services it authenticates to, and which Azure RBAC roles it needs.
- Describe the Private Endpoint configuration for Azure SQL: what resources are created, how DNS is updated, and what happens to the existing public endpoint.
- Define the Conditional Access policy for human engineer access: what conditions must be met, and what is the impact if an engineer is traveling and cannot satisfy the policy?

## Reflection question
Your Zero Trust implementation requires every fintech partner to migrate from API keys to OAuth 2.0 client credentials. Partner J (a large enterprise client) says they cannot change their authentication flow for 6 months due to internal change-freeze. What are the security and business trade-offs of granting them an extension?

## Prior concept connection
Day 1's STRIDE threat model identified Spoofing (API key theft), Elevation of Privilege (partner A accessing partner B data), and Information Disclosure as the top three threats. Today's Zero Trust controls are the direct mitigations for those threats: OAuth 2.0 client credentials + scopes mitigate Spoofing and Elevation of Privilege; Private Endpoints reduce Information Disclosure via direct database access.

## AI coach instructions
- Ask the learner to map each Zero Trust control to a specific STRIDE threat from Day 1 before explaining the services.
- If the learner proposes user-assigned Managed Identity without explanation, probe: "When would you use user-assigned over system-assigned, and what operational overhead does each create?"
- Watch for the mistake of treating Private Endpoint as a replacement for authentication — "the database can't be reached from outside, so we don't need strong auth on the API." Log in `memory/mistakes.md`.
- Probe the partner migration scenario: "You give Partner J a 6-month API key extension. What compensating control do you add to reduce the risk during that window?"
- Update `memory/progress.md` with Week 07 Day 2 complete and note whether the learner independently connected OAuth 2.0 scopes to partner isolation.

## Completion criteria
- OAuth 2.0 authentication model designed with partner isolation mechanism.
- Managed Identity type, target services, and RBAC roles specified.
- Private Endpoint configuration described with DNS update.
- Conditional Access policy defined with engineer travel edge case addressed.
- AI reviewed with cloud architect and security reviewer perspectives.
