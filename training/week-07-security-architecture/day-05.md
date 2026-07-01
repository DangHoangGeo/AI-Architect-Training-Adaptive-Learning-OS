# Week 07 Day 5 — Communication and Refinement: Audit Logs, Compliance, and Incident Evidence

## Goal
Design the audit logging architecture for VaultBridge's financial API platform to satisfy PCI-DSS adjacent compliance requirements, produce the documentation artifacts an auditor will request, and write a 5-bullet executive summary that explains the security architecture investment to a board-level audience.

## Why this matters
PCI-DSS Requirement 10 mandates that all access to system components be logged and reviewed daily. When VaultBridge had an unauthorized data access event, the security team could not reconstruct what the attacker accessed because audit logs were not enabled on Azure Key Vault and APIM. The regulator required VaultBridge to notify affected partners and conduct a forensic investigation costing $180,000. The cost of the audit logging infrastructure that would have prevented this: $400/month.

## Core concept

1. **The three audit log categories for a financial API platform.**
   - **Control-plane logs:** Who changed what in the Azure infrastructure — resource creation, deletion, permission changes. Source: Azure Activity Log (automatically available, 90-day retention in the subscription). Route to Log Analytics for long-term retention.
   - **Data-plane logs:** Who accessed what data — API calls with partner identity, operation, timestamp, response code, and data accessed. Source: APIM gateway logs + Application Insights. This is the PCI audit trail.
   - **Authentication/authorization logs:** Who authenticated, from where, and whether they were granted access. Source: Azure AD Sign-in Logs + Conditional Access audit logs.

2. **Non-repudiation requirements for financial transactions.** A transaction log entry must be: (a) tamper-evident — if it is altered, the alteration is detectable; (b) tied to a specific authenticated identity — not just an IP address; (c) retained for the legally required period — PCI-DSS requires 12 months minimum, with 3 months immediately available. 

   Tamper-evidence: store audit logs in a Storage Account with immutable storage (WORM policy — Write Once, Read Many) and versioning enabled. Even a storage administrator cannot delete or modify a log entry within the retention period.

3. **Azure Key Vault audit logs.** Every read of a secret or key from Key Vault generates an `AuditEvent` log. For VaultBridge, this means: every time the App Service reads the SQL connection string or a signing key, it is logged with the managed identity that read it. This is evidence that secrets were accessed by authorized identities only. Must be explicitly enabled via Diagnostic Settings.

4. **Log integrity and chain of custody.** For forensic admissibility, audit logs must have: (a) a documented collection process (who configured it, when, and what it covers); (b) a checksum or hash of log batches to prove completeness; (c) restricted access — only security team can read audit logs, not application developers. Azure Storage immutable storage provides (a) and (b); RBAC provides (c).

5. **Incident evidence packaging.** When a regulatory investigation occurs, the security team must produce: all API calls made by a specific partner during a time window, all authentication events for a specific identity, all Key Vault access events for a specific secret, and all changes to the APIM configuration during the investigation period. This requires that the query for each of these is pre-written and tested before an incident occurs — not figured out during a forensic investigation.

6. **GDPR and data minimization tension.** PCI requires keeping logs for 12 months. GDPR requires minimizing retention of personal data. If your API logs contain customer names or account holder data (which is personal data under GDPR), you have a conflict. Resolution: log request metadata (partner ID, operation, timestamp, response code) but not request payloads. The APIM policy must actively strip or mask PII from logs.

## Micro exercise

**Scenario:**
> It is 9:15 PM on a Wednesday. VaultBridge's security monitoring system fires an alert: "Partner D's account has made 847 calls to `GET /transactions/{accountId}` in the last 10 minutes — 40x their normal rate. 312 unique account IDs were queried." This pattern is consistent with a compromised partner credential being used to bulk-exfiltrate transaction histories.
>
> VaultBridge's CISO has declared a security incident. Your role: architect the evidence collection and communication.

Your answer must include:
- List the four Azure log sources you must query immediately to establish the incident timeline, and for each: what query you run (plain English or KQL pseudocode), what you expect to find, and what evidence gap exists if that log source was not configured.
- Describe the partner isolation action: how do you immediately revoke Partner D's access without affecting the other 14 partners, and which Azure service(s) are involved?
- Write the client notification for Partner D (who must be notified that their credential was compromised). Include: what happened, what data may have been accessed, what VaultBridge has done, and what Partner D must do. Do not include anything you cannot confirm from logs.
- Write the 5-bullet executive summary for the VaultBridge board, covering the full Week 7 security architecture investment.

## 5-bullet executive summary format

Write exactly this structure:
- **Threat landscape:** [the specific threats the platform faces — use the STRIDE categories from Day 1, named for a board audience]
- **Controls deployed:** [the three-layer architecture in non-technical language: authentication, gateway, network]
- **Compliance posture:** [which PCI-DSS requirements the architecture addresses, and audit evidence available]
- **Incident capability:** [how fast the team can detect, isolate, and respond to a partner credential compromise]
- **Residual risk and investment required:** [the one remaining gap and what it would cost to close]

## Reflection question
The forensic investigation reveals that Partner D's credential was compromised because a VaultBridge developer accidentally committed Partner D's `client_secret` to a public GitHub repository 3 weeks ago and did not notice. The secret had never been rotated. What two architectural controls would have prevented this incident — and which one is a process control vs. a technical control?

## Prior concept connection
The entire Week 7 arc — STRIDE modeling (Day 1), Zero Trust controls (Day 2), APIM/WAF (Day 3), Private Link hardening (Day 4) — is only defensible to a regulator if audit logs prove the controls were in place and working. Without audit logs, the architecture is unauditable. Today's audit logging is the compliance evidence layer that makes all previous controls auditable and legally defensible.

## AI coach instructions
- Ask the learner to write the 5-bullet executive summary for a board audience. The quality of their language (technical vs. accessible) reveals audience awareness.
- If the learner's incident response action is "delete Partner D's account," probe: "Deleting the account destroys the evidence trail. What is the correct isolation action that preserves the audit log?"
- Watch for the mistake of not mentioning Key Vault audit logs as a source — this is a common gap. Log in `memory/mistakes.md`.
- Probe GDPR vs. PCI tension: "Your logs retained for 12 months include customer account IDs. Are those personal data under GDPR? What is your legal basis for retaining them?"
- Probe the GitHub secret exposure: "What technical control would have detected the secret commit before it reached the public repository?"
- Update `memory/progress.md` with Week 07 Day 5 complete.
- Update `memory/achievements.md` if the learner produced a complete incident evidence package and board-level summary.

## Completion criteria
- Four log sources identified with specific queries and evidence gaps if absent.
- Partner isolation action described using correct Azure service (APIM subscription disable or Azure AD token revocation).
- Client notification written with factual scope of impact (not speculative).
- 5-bullet executive summary written in board-accessible language with compliance references.
- AI reviewed with cloud architect, security reviewer, and compliance perspectives.
