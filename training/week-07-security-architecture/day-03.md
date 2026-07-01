# Week 07 Day 3 — Design Exercise: API Management and WAF Patterns

## Goal
Design the Azure API Management and Web Application Firewall architecture for VaultBridge's banking API gateway, applying the controls from Days 1–2 and adding rate limiting, request validation, WAF rule sets, and partner-specific policies that a PCI-DSS adjacent audit would require.

## Why this matters
VaultBridge's API is exposed directly on the internet with no gateway layer. When a security researcher performed a basic reconnaissance scan last year, they found: no rate limiting (automated enumeration of account IDs ran successfully for 6 hours), no input validation (SQL injection attempt in the `accountId` field returned a database error message), and no DDoS protection. A single malicious partner could disrupt service for all 15 partners. Azure API Management with Front Door WAF is the architectural response.

## Core concept

1. **Azure API Management (APIM) is the policy enforcement point.** APIM sits between external callers and backend services. It enforces: authentication (validate JWT), authorization (scope checks), rate limiting (per partner, per subscription), request transformation, and protocol translation. All of this happens in APIM policies (XML-based) without changing backend code.

2. **APIM tier selection for financial APIs.**
   | Feature | Developer | Basic | Standard | Premium |
   |---|---|---|---|---|
   | VNet integration | No | No | External only | Internal + External |
   | Zone redundancy | No | No | No | Yes |
   | Multi-region | No | No | No | Yes |
   | SLA | None | 99.95% | 99.95% | 99.99% |
   | Best for | Dev/test | Small API | Production | Enterprise/HA |

   For VaultBridge: Premium tier is required for VNet internal mode (APIM not reachable from public internet — only from Front Door) and zone redundancy.

3. **Azure Front Door with WAF in front of APIM.** Architecture: `Internet → Front Door (WAF) → APIM (Premium, internal VNet) → App Service (Private Endpoint) → SQL (Private Endpoint)`. Front Door provides: global anycast routing, DDoS protection (L3/L4), WAF (L7 rule sets). APIM handles API-specific policies. Never expose APIM directly to the internet if WAF is required.

4. **WAF rule sets for financial APIs.**
   - **OWASP Core Rule Set (CRS):** Protects against OWASP Top 10: SQL injection, XSS, command injection. Enable in Prevention mode after validating no false positives.
   - **Bot protection rule set:** Blocks known malicious bots and scrapers. Important for preventing account ID enumeration.
   - **Custom rules:** Rate-limit by `X-Partner-ID` header (in addition to APIM policies, as a defense-in-depth measure). Block requests that include patterns matching PAN (Primary Account Number) data in non-payment endpoints.

5. **APIM policy layers: global, product, API, operation.** Policies are inherited and can be overridden. For VaultBridge: global policy enforces JWT validation and logs every request. Product policy (per partner tier) enforces rate limits (Premium partners: 1,000/minute; Standard: 100/minute). API policy enforces scope checks. Operation policy for `/payments/initiate` adds extra validation: idempotency key required, amount range check.

6. **Subscription keys vs. OAuth tokens in APIM.** APIM subscription keys are the legacy model. For VaultBridge, the correct flow is: OAuth 2.0 token (from Day 2) passed as `Authorization: Bearer <token>`. The APIM policy `validate-jwt` verifies the token signature, issuer, audience, and required scopes before the request reaches the backend. The subscription key is used only as a secondary tracking mechanism for billing — not as the primary authentication.

## Product framing (write this first)

> **User pain:** Fintech partners experience unpredictable API behavior — sometimes their calls succeed, sometimes they get 500 errors with no explanation. They have no visibility into their own rate limit consumption. During high load from one partner, all partners experience degradation because there is no isolation. Three partners have raised this in quarterly reviews.
>
> **MVP constraint:** The team has 6 weeks and cannot change the backend API code. All controls must be in the API gateway layer. The design must be auditable for the upcoming PCI-DSS adjacent assessment in 8 weeks.
>
> **Success metric:** Zero successful SQL injection attempts detected in WAF logs; per-partner rate limiting implemented such that one partner consuming 100% of their quota has zero impact on other partners' SLAs.

## Micro exercise

**Scenario:**
> VaultBridge is implementing the new API gateway architecture. The platform must support:
> - 15 fintech partners with different tier levels (3 Premium, 7 Standard, 5 Basic)
> - Three API products: Read-only (balance + transactions), Payment initiation, Admin (internal only)
> - Compliance requirement: all requests to `/payments/initiate` must include an idempotency key; requests without it must be rejected at the gateway (not the backend)
> - PCI requirement: no raw PAN (card numbers matching `\d{13-19}` pattern) may appear in API request or response bodies
> - Audit requirement: every API call must be logged with partner ID, operation, timestamp, and response code

Your answer must include:
- Design the APIM product structure: list each product, which partners belong to it, the rate limit policy for each, and the OAuth 2.0 scopes each product grants.
- Write the APIM policy (in pseudo-XML or plain English) for the `POST /payments/initiate` operation that enforces: JWT scope validation, idempotency key presence check, and request logging with partner ID.
- Describe the Front Door WAF configuration: which rule sets, which mode (detection vs. prevention), and one custom rule specific to VaultBridge's PAN protection requirement.
- Identify one operational risk of putting APIM in internal VNet mode and describe how you mitigate it (hint: what happens during APIM maintenance if Front Door cannot reach it?).

## Reflection question
A premium fintech partner complains that the WAF is blocking their legitimate payment requests because their payload contains a field called `card_last4` which the WAF flags as a potential PAN. You must balance PCI compliance (block PAN exposure) with partner usability (allow legitimate partial card data). How do you resolve this tension — and what is the approval process for adding a WAF exclusion in a compliance environment?

## Prior concept connection
Day 1's STRIDE model identified DoS, Elevation of Privilege, and Information Disclosure as threats. Day 2's Zero Trust controls (OAuth 2.0, Private Endpoints) addressed authentication and network exposure. Today's APIM + WAF layer adds rate limiting (DoS mitigation), operation-level scope enforcement (Elevation of Privilege prevention), and PAN detection (Information Disclosure prevention). Each day builds on the previous threat model.

## AI coach instructions
- Ask the learner to write the Product framing section before designing the architecture.
- If the learner selects Standard APIM tier, probe: "Does Standard support internal VNet mode? What is the security implication of APIM being reachable from the public internet?"
- Watch for the mistake of using APIM subscription keys as the primary authentication mechanism in a financial API. Log in `memory/mistakes.md`.
- Probe the WAF exclusion question: "Who approves a WAF exclusion in a PCI environment? What documentation is required and who reviews it annually?"
- Probe the internal VNet operational risk: "If APIM goes into maintenance, Front Door health probe fails. What is the user impact and how long does it last?"
- Update `memory/progress.md` with Week 07 Day 3 complete and note whether the learner independently identified the need for Premium APIM tier.

## Completion criteria
- Product framing written before the design.
- APIM product structure with three products, rate limits, and scopes defined.
- APIM policy for `/payments/initiate` with JWT validation, idempotency key check, and logging.
- Front Door WAF configuration with rule sets and custom PAN rule.
- Internal VNet operational risk identified and mitigated.
- AI reviewed with cloud architect and security reviewer perspectives.
