# Week 03 Day 4 — Failure, security, and cost review: Key Vault secret lifecycle, threat modeling, and governance gaps

## Goal
Stress-test the identity and secret management architecture from Days 1–3 against realistic failure modes: Key Vault unavailability, leaked managed identity tokens, insider threat via privileged role escalation, and governance drift over time. Identify which failures are design flaws versus operational failures.

## Why this matters
A Key Vault that is not backed up, not zone-redundant, and not monitored is a single point of failure for every application that depends on it. In November 2022, a UK consulting firm's entire production environment went offline for 11 hours because a Key Vault in a single availability zone experienced a transient issue during a planned maintenance window — every application that called the SDK failed open/closed depending on how error handling was implemented. Knowing the failure modes of your own security infrastructure is what separates a senior architect from someone who implemented the happy path.

## Core concept

1. **Key Vault SLA and redundancy have limits.** Azure Key Vault is zone-redundant within a region by default (in regions that support AZs). It does NOT automatically geo-replicate. For disaster recovery, you must use Key Vault backup/restore (per-secret, not automated in bulk) or design application-level caching with appropriate TTLs. Soft-delete protects against accidental deletion (90-day recovery window) but not against region failure.

2. **Managed identity tokens are short-lived but the identity itself can be exploited.** A managed identity token is valid for ~24 hours (varies by service). If an attacker compromises an application running with a managed identity, they can call the IMDS endpoint to get a fresh token as long as they have code execution on the compute resource. The managed identity itself cannot be "stolen" the way a password can — but the application can be abused as a proxy. Defender for Cloud detects anomalous token usage patterns.

3. **Privilege escalation via User Access Administrator is the most dangerous RBAC misconfiguration.** User Access Administrator allows a principal to grant any Azure RBAC role to any principal — including Owner. A compromised service principal with User Access Administrator can make itself Owner. This is how ransomware actors often achieve subscription takeover. Never grant User Access Administrator to managed identities or service principals without extremely tight scope and monitoring.

4. **Governance drift: access reviews and Defender for Cloud recommendations.** After 6 months without governance reviews, most Azure environments develop "access debt": stale role assignments, expired guest accounts that were not removed, Key Vault access policies that were never migrated to RBAC, secrets without expiry dates. Entra ID Access Reviews (Governance feature) and Microsoft Defender for Cloud identity recommendations detect these patterns automatically.

5. **Audit log coverage is a compliance requirement, not optional.** For a professional services firm subject to GDPR or client data agreements, all Key Vault access events (who read which secret, when) must be logged. Enable Key Vault diagnostic settings to send `AuditEvent` logs to Log Analytics. Retention must be at least 90 days. A Key Vault without diagnostic logging is an audit finding in every security review.

## Learn — write notes answering these

- An application caches a Key Vault secret (a database password) in memory for performance. The secret is rotated in Key Vault. How long does the application run with the old password, and what is the correct pattern to handle this without taking the application offline?
- What is the Key Vault throttling limit for secret `GET` operations per 10 seconds, and in what scenario does a well-designed application hit this limit in production? What is the mitigation?
- Describe the exact sequence of events in a privilege escalation attack where a compromised Azure Function with a managed identity gains subscription Owner access — step by step — and identify which Defender for Cloud or Entra ID alert would fire at each step.
- A Key Vault has 47 access policies set over 3 years. Many reference object IDs of deleted users and service principals. What is the operational risk of not cleaning these up, and what tool/query identifies orphaned access policies?

## Micro exercise

**Scenario:**
> **Northstar Legal LLP** (from Day 1) has now implemented the managed identity and Key Vault architecture from Day 3. Six months later, the security team runs a quarterly review and discovers: (a) a former associate's user-assigned managed identity is still assigned to two App Services even though the associate left 3 months ago, (b) the Key Vault has diagnostic logging disabled — it was turned off during a troubleshooting session and never re-enabled, (c) a junior developer created a Key Vault access policy (legacy model) alongside the RBAC model "because they couldn't figure out RBAC," creating a dual-authorization situation, (d) the vendor API key in Key Vault has no expiry date set and has not been rotated in 11 months.

Your answer must include:
- For each of the four findings: severity rating (Critical/High/Medium/Low), the specific remediation step, and how to prevent recurrence
- The Azure Policy definition (built-in or custom) that would have detected finding (b) proactively
- A Key Vault access audit query in KQL that shows all secret reads in the last 30 days grouped by caller identity — write the actual query structure even if you approximate field names
- A cost analysis: the firm is considering "just using Azure Automation to rotate secrets" vs. "buying Entra ID Governance for access reviews." For a 250-person firm, which investment has higher ROI against the identified finding categories?

## Reflection question
The partner in charge of IT security asks: "We've done everything right — managed identities, Key Vault, PIM, access reviews. We are now secure." What is the most significant residual risk that all of these controls do not address, and what single additional control would you recommend as the next investment?

## Prior concept connection
Day 3 designed the managed identity and Key Vault architecture. Today you are stress-testing it — discovering that correct initial design does not mean correct ongoing operation. The governance drift found here (finding a, b, c, d) directly maps to the lifecycle controls discussed in Day 1 (guest account expiry) and Day 2 (access reviews, PIM). Identity architecture and governance are not a one-time deployment; they require operational processes that your design must explicitly include.

## AI coach instructions
Do not give the severity ratings or remediations until the learner produces their own. Watch for: (1) rating the disabled diagnostic logging as "Low" — it is High because it means no audit trail for a potentially 3-month window, which is a GDPR/compliance breach, (2) not knowing that mixing access policies and RBAC on the same Key Vault is supported but confusing and should be resolved by migrating fully to RBAC, (3) writing a KQL query that tries to query `AuditLogs` instead of `AzureDiagnostics` with `ResourceType = "VAULTS"` and `OperationName = "SecretGet"` — the actual log table matters for the exam. Probe: "What is the maximum Key Vault access policy count limit, and why does having orphaned policies consume a finite resource?" Record any audit log/KQL gap in `memory/weak_areas.md`.

## Completion criteria
- Four findings each rated with severity, remediation, and prevention control
- Azure Policy for diagnostic logging identified
- KQL query structure written (even if field names are approximate)
- Cost/ROI comparison between Azure Automation rotation and Entra ID Governance
- Residual risk beyond implemented controls identified
- AI reviewed from cloud architect, security reviewer, and cost optimizer perspectives
- Mistakes and weak areas recorded, progress updated
