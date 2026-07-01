# Week 07 Day 4 — Failure, Security, and Cost Review: Private Link, Endpoint Exposure, and STRIDE Applied

## Goal
Apply STRIDE threat modeling to the Day 3 VaultBridge API gateway design, analyze Private Link and endpoint exposure reduction as the final network layer control, and identify the security gaps that remain after the Week 7 controls are applied — because no architecture is ever fully secure.

## Why this matters
A financial services architecture that has passed a design review and a compliance checklist can still be breached if a developer's shortcut bypassed Private Link ("I enabled the public endpoint temporarily to debug and forgot to turn it off") or if the WAF is in detection mode instead of prevention mode. Stress-testing your own design with STRIDE before an external auditor or attacker does it is the mark of a security-mature architect.

## Core concept

1. **Private Link vs. Service Endpoints — the critical distinction.**
   - **Service Endpoint:** Extends VNet routing to reach an Azure service's *public* IP space via a private route. The service still has a public endpoint. Stops cross-tenant access but does not prevent a misconfigured firewall from re-enabling public access.
   - **Private Endpoint:** Creates a private IP address *inside your VNet* that resolves to the service. The service's public endpoint can (and should) be disabled. Traffic never leaves Microsoft's network backbone. This is the Zero Trust-compliant option.
   
   For VaultBridge's Azure SQL: use Private Endpoint and disable the public endpoint. Service Endpoint alone is not sufficient for PCI-adjacent compliance.

2. **Disabling public endpoints requires DNS coordination.** When you create a Private Endpoint for Azure SQL, the DNS name `vaultbridge-sql.database.windows.net` must resolve to the private IP inside the VNet. Use Azure Private DNS Zone (`privatelink.database.windows.net`) linked to the VNet. Without this, the App Service resolves the FQDN to the public IP and connection fails even though the Private Endpoint exists.

3. **Network Security Groups (NSG) are not a substitute for Private Endpoints.** An NSG rule that blocks all internet traffic to the SQL subnet reduces exposure but does not eliminate the attack surface — the public endpoint still exists and can be accessed if an NSG rule is misconfigured. Defense in depth requires both NSG *and* Private Endpoint *and* disabled public endpoint.

4. **STRIDE applied to the Day 3 architecture — residual threats after controls.**

   | Threat | Category | Current control | Residual risk |
   |---|---|---|---|
   | Stolen OAuth token reused | S | Token expiry (1 hour) | Token valid for 1 hour post-compromise |
   | WAF bypass via encoded payload | T | CRS rule set | Unknown evasion techniques |
   | APIM policy misconfiguration allows over-privileged scope | E | Code review | Human error risk |
   | Application Insights logs partner PII | I | Log sampling | PII may be in sampled logs |
   | APIM DDoS during high-volume partner attack | D | Front Door DDoS protection | Still costs money under attack |
   | Developer enables SQL public endpoint to debug | T/I | Policy (informal) | No automated enforcement |

5. **Azure Policy as a security guardrail.** The "developer enables public endpoint" threat is eliminated by an Azure Policy that denies `Microsoft.Sql/servers/publicNetworkAccess` from being set to `Enabled`. This is policy-as-code security: the control is enforced at the ARM/Azure control plane level, not by trusting developers. This bridges Week 7 (security) to Week 8 (policy-as-code).

6. **Cost of security controls.** Premium APIM: ~$2,800/month. Azure Front Door with WAF: ~$400/month + $0.035/10k requests. Private Endpoints: ~$7.30/month per endpoint. Defender for Cloud (workload protection): ~$15/server/month. Total security layer cost: ~$3,500/month. A CFO asking "can we cut costs?" needs to understand what each component protects against.

## Micro exercise

**Scenario:**
> A security auditor performing a pre-PCI assessment of VaultBridge's architecture (as designed in Days 1–3) has issued the following findings:
> 1. **HIGH:** Azure SQL still has public endpoint enabled. Private Endpoint exists but public endpoint was not disabled.
> 2. **HIGH:** One fintech partner (Partner M) was found to have their OAuth token cached in their application logs, with no expiry set on the token in Azure AD. Token valid for 24 hours.
> 3. **MEDIUM:** WAF is running in Detection mode, not Prevention mode. Attacks are logged but not blocked.
> 4. **MEDIUM:** Application Insights is logging the full `Authorization` header on all requests. Bearer tokens are visible in Log Analytics.
> 5. **LOW:** No Azure Policy prevents developers from re-enabling public network access on Azure SQL.

Your answer must include:
- Apply STRIDE to each finding: identify the primary threat category and the secondary category if applicable.
- For each finding, describe the specific remediation step and the Azure service or configuration change required. Be specific enough that a junior engineer could execute the step.
- Finding 3 (WAF in Detection mode): describe the validation process you must complete before switching to Prevention mode. What is the risk of switching immediately and what false positive rate is acceptable?
- Calculate the blast radius of Finding 1 (public endpoint still enabled): if an attacker discovered valid SQL credentials (e.g., from a leaked environment variable), what data could they access and for how long before detection?

## Reflection question
You switch the WAF from Detection to Prevention mode. The next morning, a premium partner reports that 12% of their payment calls are being blocked with HTTP 403. The WAF rule that is blocking them is a custom rule you wrote yesterday. The partner is threatening to escalate to their contract manager. Walk through your decision process: do you disable the rule, add an exclusion, or hold firm — and what evidence do you need before deciding?

## Prior concept connection
Day 1 identified six STRIDE threats for the `/payments/initiate` endpoint. Day 2 addressed Spoofing with OAuth 2.0 and Elevation of Privilege with Private Endpoints. Day 3 added DoS protection via WAF and Information Disclosure protection via PAN detection. Today's STRIDE re-application reveals what is still unmitigated after three days of controls — demonstrating that threat modeling is iterative, not a one-time exercise.

## AI coach instructions
- Give the learner the five auditor findings first and ask them to apply STRIDE before explaining the remediations.
- If the learner treats "disable public endpoint" and "add Private Endpoint" as the same action, probe: "The Private Endpoint already exists. What specific property on the Azure SQL server resource must change, and what risk exists during the window between Private Endpoint creation and public endpoint disablement?"
- Watch for the mistake of recommending immediate WAF Prevention mode without a validation period. Log in `memory/mistakes.md`.
- Probe the Bearer token in Application Insights logs: "This is STRIDE category I. Under GDPR or PCI-DSS, what are the consequences of retaining auth tokens in logs for 30 days?"
- Update `memory/progress.md` with Week 07 Day 4 complete and note whether the learner independently connected Azure Policy to preventing the public endpoint finding.

## Completion criteria
- STRIDE category applied to all five auditor findings with primary and secondary categories.
- Specific remediation steps described for each finding.
- WAF Detection-to-Prevention validation process described with false positive tolerance.
- Blast radius of SQL public endpoint calculated with detection window.
- AI reviewed with cloud architect, security reviewer, and cost optimizer perspectives.
