# Week 08 Day 5 — Communication and Refinement: Policy-as-Code and Drift Detection

## Goal
Synthesize the Week 8 CorePlatform architecture by adding Azure Policy and drift detection as the enforcement and verification layers, and produce a 5-bullet executive summary that communicates the platform engineering investment's value to Meridian's leadership team.

## Why this matters
CorePlatform has built modules, parameterization, and a CI/CD pipeline. But a developer can still open the Azure portal and change a resource setting by hand — disabling HTTPS-only, changing a SKU, or enabling a public endpoint — without going through any pipeline. One hour later, the Bicep template and the actual Azure resource are out of sync (drift). Policy-as-code prevents the most dangerous manual changes; drift detection finds everything else.

## Core concept

1. **Azure Policy: deny at the control plane.** Azure Policy evaluates every resource create or update request at the Azure Resource Manager layer — before the change is committed. A `Deny` policy blocks the request entirely. For CorePlatform: a policy that denies `Microsoft.Web/sites/httpsOnly: false` means no one — not even an Owner — can disable HTTPS on an App Service. This is stronger than a pipeline check, which only runs when a deployment happens.

2. **Policy effects and when to use each.**
   | Effect | When it runs | What it does | Use for |
   |---|---|---|---|
   | Deny | On create/update | Blocks the operation | Must-have security controls |
   | Audit | On create/update + compliance scan | Flags non-compliant, allows through | Detection without enforcement |
   | DeployIfNotExists | After create | Adds missing config | Auto-remediation (e.g., enable diagnostics) |
   | Modify | On create/update | Changes the request | Auto-correct a property |

   For CorePlatform: `Deny` for security controls (HTTPS, public endpoints). `DeployIfNotExists` for automatic diagnostic settings (ensures every new App Service sends logs to central workspace without product teams doing anything).

3. **Policy initiatives (policy sets).** Group related policies into an initiative and assign the initiative to a management group or subscription. CorePlatform initiative: `Meridian-Platform-Baseline` includes 12 policies covering HTTPS enforcement, minimum TLS version, required tags, diagnostic settings, and private endpoint requirements. Product teams see one assignment, not 12.

4. **Drift detection.** Even with Policy, some configuration can drift: app settings changed in portal, connection strings updated by hand, scale rules modified. Drift detection compares the current state of Azure resources to the Bicep template that should describe them. Azure has no native "drift detection" tool — but:
   - **`az deployment group what-if` on schedule:** Run `what-if` nightly against all production environments. If it shows changes, resources have drifted.
   - **Azure Resource Graph queries:** Query for resources that do not comply with naming conventions, tag requirements, or SKU standards.
   - **Microsoft Defender for DevOps (GitHub Advanced Security):** Detects secrets in IaC templates and configuration files in connected repositories.

5. **Compliance reporting.** Azure Policy generates a compliance dashboard per initiative, per subscription, per resource group. CorePlatform uses this to produce a monthly "platform compliance report" for Meridian leadership: what percentage of product team environments are compliant with the platform baseline. Non-compliant resources are visible; owners are notified.

6. **The governance model: enabling, not blocking.** Platform engineering at its best makes the "right way" also the "easy way." Product teams who use CorePlatform's modules get compliant infrastructure automatically. Teams who try to deploy outside the module library hit Policy denials. The goal is not to block teams — it is to make bypassing the platform harder than using it.

## Micro exercise

**Scenario:**
> Three months after CorePlatform's platform engineering system is live, a compliance audit finds:
> - 4 of 8 product teams' production App Services have HTTPS-only disabled (changed manually in portal)
> - 6 of 8 product teams' App Services are missing the required `team` and `cost-center` tags (added by portal, later removed)
> - 2 of 8 product teams have App Services pointing to the old Log Analytics workspace (CorePlatform migrated to a new workspace but drift caused some to remain on the old one)
> - 1 of 8 product teams has an Azure SQL server with the public endpoint still enabled (it was supposed to be disabled by Private Endpoint deployment)
>
> All of these could have been prevented. CorePlatform must now fix them and prevent recurrence.

Your answer must include:
- For each of the four finding types, select the correct Azure Policy effect (`Deny`, `Audit`, `DeployIfNotExists`, or `Modify`) and explain why the other effects are insufficient for that finding.
- Describe the `DeployIfNotExists` policy for diagnostic settings: what does it check, what does it deploy when the check fails, and what identity (Managed Identity) runs the deployment?
- Design the drift detection pipeline: what schedule does it run on, what `what-if` command does it run, who receives the report, and what SLA does CorePlatform commit to for remediating drift findings?
- Write the 5-bullet executive summary for Meridian's CTO, covering the full Week 8 platform engineering investment.

## 5-bullet executive summary format

Write exactly this structure:
- **Problem we solved:** [the specific incidents from the week's scenario — quantify the downtime or risk]
- **What we built:** [the platform engineering system in one sentence accessible to a non-technical CTO]
- **How it changes product team velocity:** [deployment time before vs. after, and what product teams no longer have to do]
- **How it protects production:** [the three layers of protection: pipeline, policy, drift detection]
- **Investment and return:** [monthly platform cost, estimated incident cost avoided, and one metric that proves the value]

## Reflection question
A product team lead argues: "Azure Policy slowed down our deployment because the `DeployIfNotExists` policy is creating resources we didn't ask for. It added a diagnostic settings resource after we deployed and our Terraform state is now out of sync." What is the architectural lesson here — and how does CorePlatform's Bicep-native approach avoid this specific problem that Terraform teams hit?

## Prior concept connection
The full Week 8 arc — modules (Day 1), parameterization (Day 2), CI/CD pipeline (Day 3), rollback safety (Day 4) — forms a deployment system. Policy-as-code (today) is the enforcement layer that operates independently of that system: it catches configuration changes that bypass the pipeline entirely. Week 7's STRIDE work identified the threat of "developer enables SQL public endpoint to debug." Azure Policy's `Deny` effect is the technical control that closes that threat permanently.

## AI coach instructions
- Ask the learner to assign Policy effects to all four finding types before explaining the effects.
- If the learner selects `Deny` for the missing tags finding (rather than `Modify` or `Audit`), probe: "If you deny a deployment because a tag is missing, the product team's deployment fails with no good error message. Is that the right user experience? What effect adds the tag automatically?"
- Watch for the mistake of treating Azure Policy as a pipeline replacement rather than a complementary control. Log in `memory/mistakes.md`.
- Probe the `DeployIfNotExists` identity: "Who runs the remediation deployment — the product team's service principal or a dedicated platform identity? What permissions does it need?"
- Probe the Terraform conflict question: "Why does `DeployIfNotExists` cause Terraform state drift but not Bicep deployment drift?"
- Update `memory/progress.md` with Week 08 Day 5 complete.
- Update `memory/achievements.md` if the learner produced a complete policy design and executive summary.

## Completion criteria
- Correct Policy effect selected for all four finding types with justification.
- `DeployIfNotExists` policy for diagnostic settings described with deployment identity.
- Drift detection pipeline designed with schedule, command, reporting, and SLA.
- 5-bullet executive summary in the specified format with quantified before/after comparisons.
- AI reviewed with cloud architect, DevOps, and product manager perspectives.
