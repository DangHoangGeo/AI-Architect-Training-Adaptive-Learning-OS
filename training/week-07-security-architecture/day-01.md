# Week 07 Day 1 — Concept Foundation: Threat Modeling with STRIDE

## Goal
Apply the STRIDE threat modeling framework to a financial services API gateway that exposes banking APIs to third-party fintech partners. Understand each threat category, identify the most dangerous threats for this scenario, and produce a threat model that could satisfy a PCI-DSS adjacent compliance audit.

## Why this matters
VaultBridge is a financial services company that exposes account balance, payment initiation, and transaction history APIs to 15 fintech partner companies. Without formal threat modeling, security controls are added reactively after incidents. In a PCI-DSS adjacent environment, regulators and auditors require evidence that threats were systematically identified and mitigated before go-live. A missed threat in a banking API is not a learning opportunity — it is a regulatory action, client notification requirement, and potential license revocation.

## Core concept

1. **STRIDE categories — what each means for an API gateway.**
   - **S — Spoofing:** An attacker claims to be a legitimate fintech partner. In API context: forged JWT tokens, stolen API keys, or impersonated partner IDs. Mitigation: strong authentication (mTLS or OAuth 2.0 client credentials), not just API keys.
   - **T — Tampering:** Modifying data in transit or at rest. In API context: MITM attack modifying payment amounts; a compromised partner injecting malicious payloads. Mitigation: TLS everywhere, request signing (HMAC), immutable audit logs.
   - **R — Repudiation:** A partner denies performing an action. In API context: "We never initiated that payment transfer." Mitigation: non-repudiation audit logs with digital signatures; transaction IDs logged with partner identity.
   - **I — Information Disclosure:** Exposing sensitive data to unauthorized parties. In API context: error messages that reveal account structure; API responses that include data beyond what the partner is authorized to see. Mitigation: minimal error disclosure, field-level authorization.
   - **D — Denial of Service:** Overwhelming the API to prevent legitimate use. In API context: a partner (malicious or compromised) floods the gateway with requests. Mitigation: rate limiting per partner, quota enforcement, Azure APIM throttling policies.
   - **E — Elevation of Privilege:** A partner gains access beyond their authorized scope. In API context: a read-only fintech partner calling payment initiation endpoints; accessing another partner's client data. Mitigation: OAuth 2.0 scopes, API Management products and subscriptions, ABAC on backend.

2. **The STRIDE process: three steps.**
   - Step 1 — **Draw the data flow diagram (DFD).** Identify: external entities (fintech partners), processes (API gateway, backend services), data stores (database, Key Vault), and trust boundaries (where the network perimeter changes). Every arrow crossing a trust boundary is a threat surface.
   - Step 2 — **Apply STRIDE to each DFD element.** Processes can be spoofed, tampered with, and can repudiate. Data stores can have information disclosure and tampering. Communication links can be intercepted (information disclosure) and disrupted (DoS).
   - Step 3 — **Rate and prioritize threats using DREAD or CVSS.** Not all threats have equal impact. Prioritize by: damage potential × reproducibility × exploitability × affected users × discoverability.

3. **Trust boundaries are the most important concept.** A trust boundary is where you stop trusting inputs implicitly. Between the public internet and your API gateway: zero trust. Between your API gateway and your backend: still verify — a compromised gateway could be the attacker. Between your backend and your database: validate again.

4. **PCI-DSS relevance.** PCI-DSS Requirement 6.3 requires organizations to identify and manage security vulnerabilities in all system components. A STRIDE threat model is direct evidence of compliance with this requirement. It must be reviewed annually and after significant system changes.

5. **What STRIDE does NOT cover.** STRIDE does not address: physical security, social engineering, supply chain attacks, or insider threats. For financial services, a more complete model adds PASTA (Process for Attack Simulation and Threat Analysis) for insider threat scenarios.

6. **Output of a threat model.** A completed threat model produces: (a) a DFD with annotated trust boundaries, (b) a threat register (each threat, STRIDE category, likelihood, impact, current mitigation, residual risk), and (c) a prioritized remediation backlog. This is a portfolio artifact.

## Learn — write notes answering these

1. List the six STRIDE categories and, for each, give one concrete example specific to a banking API gateway (not a generic web app example).
2. What is a trust boundary in a data flow diagram? Give two examples from the VaultBridge architecture (hint: where does data move from an untrusted zone to a trusted zone?).
3. Explain the difference between Spoofing and Elevation of Privilege in the context of a fintech partner accessing VaultBridge APIs. Why are both relevant even if authentication is strong?
4. A VaultBridge API returns HTTP 400 with the message: "Account ID 7829341 not found in database." Which STRIDE category does this violate, and what is the correct response format?

## Micro exercise

**Scenario:**
> VaultBridge exposes three API endpoints to 15 fintech partners:
> - `GET /accounts/{accountId}/balance` — read account balance
> - `POST /payments/initiate` — initiate a bank transfer
> - `GET /transactions/{accountId}` — list transaction history
>
> Authentication: currently API key passed in `X-API-Key` header. No partner-specific scoping. A compromised API key from Partner A could access Partner B's clients' data. The API is exposed directly on the internet (no API gateway in front). The backend connects to an Azure SQL Database using a shared service account.

Your answer must include:
- Draw a text-format data flow diagram with at least 4 elements (external entity, process, data store, trust boundary). Label trust boundaries explicitly.
- Apply STRIDE to the `POST /payments/initiate` endpoint: list at least 4 threats from 4 different STRIDE categories, each with one sentence describing the specific attack.
- Identify the single highest-severity threat and justify your rating using at least two factors (e.g., damage potential, ease of exploitation).
- Propose one mitigation for each of the 4 threats you identified, using an Azure service or pattern where possible.

## Reflection question
A developer says "we use HTTPS, so the Tampering and Information Disclosure risks are covered." What two specific attack surfaces does HTTPS not protect against in a multi-partner API scenario?

## Prior concept connection
Week 6 established observability: audit logs and Application Insights. A STRIDE threat model depends on those controls being present — non-repudiation (STRIDE R) requires immutable audit logs; information disclosure detection (STRIDE I) requires monitoring for anomalous data access patterns. Threat modeling without observability identifies threats you cannot detect.

## AI coach instructions
- Ask the learner to draw the DFD before applying STRIDE. If they skip the DFD, redirect: "STRIDE analysis without a DFD is guesswork. Where are your trust boundaries?"
- If the learner applies all six STRIDE categories to the entire system rather than to specific DFD elements, correct the approach.
- Watch for the mistake of treating API key authentication as sufficient for a banking API. Log in `memory/mistakes.md`.
- Probe the "HTTPS covers tampering" misconception with a specific counter-example: what if the fintech partner's server is compromised and they send a modified payment amount?
- Update `memory/progress.md` with Week 07 Day 1 complete and note whether the learner independently identified partner data isolation as a threat.

## Completion criteria
- DFD drawn with at least 4 elements and explicit trust boundaries.
- STRIDE applied to `POST /payments/initiate` with 4 threats from 4 categories.
- Highest-severity threat rated and justified.
- One mitigation per threat proposed.
- AI reviewed with cloud architect and security reviewer perspectives.
