# Week 08 Day 3 — Design Exercise: CI/CD Stages and Approvals

## Goal
Design a CI/CD pipeline architecture for CorePlatform's module deployment system that gives product teams fast dev deployments, requires human approval before production, and prevents a single misconfigured deployment from cascading across all 8 product teams' production environments simultaneously.

## Why this matters
Meridian Technologies' Payments team pushed a Bicep change that deleted and recreated their production Azure Service Bus namespace — because the pipeline had no staging stage and deployed directly to production with no approval gate. The team used `az deployment group create --mode Complete` which removed resources not in the template. Three other teams lost their payment event subscriptions instantly. A properly staged pipeline with approval gates would have caught this in staging before production was touched.

## Core concept

1. **The three-stage pipeline for infrastructure.** Every infrastructure change must pass through: (1) **Validate** — run `az bicep build` and `az deployment group what-if` to show what will change without deploying. (2) **Deploy to staging** — deploy to the staging environment and run integration tests. (3) **Deploy to production** — requires a human approval and deploys only if staging succeeded.

2. **`what-if` is mandatory before production.** Azure Deployment `what-if` mode shows: resources to be created, modified, or deleted — before any change is made. For infrastructure pipelines, the `what-if` output must be reviewed (automatically or by a human) before the actual deployment runs. If `what-if` shows a deletion of a resource not expected to be deleted, the pipeline halts and alerts.

3. **GitHub Actions / Azure Pipelines approval environments.** In GitHub Actions, a deployment `environment` can require a reviewer before the job runs. In Azure Pipelines, stage approvals require a specific user or group to approve before the stage executes. This is the gate between staging deployment success and production deployment start.

4. **Pipeline permissions: principle of least privilege per stage.** The service principal used to deploy to dev should not have permission to deploy to production. Use separate service principals (or Managed Identities) per environment:
   - Dev pipeline identity: Contributor on dev resource groups only
   - Staging pipeline identity: Contributor on staging resource groups only
   - Production pipeline identity: Contributor on prod resource groups, requires approval to acquire

5. **Module deployment vs. product team deployment pipelines.** CorePlatform has two pipeline types:
   - **Module publish pipeline:** runs when CorePlatform merges a module change, publishes a new version to the Bicep Registry. No direct resource deployment.
   - **Infrastructure deployment pipeline:** runs when a product team's infrastructure repo changes, deploys a specific environment using the approved module version. Product teams own this pipeline; CorePlatform owns the approval gate for production.

6. **Canary deployment for infrastructure.** When CorePlatform releases a new module version, do not deploy all 8 product teams simultaneously. Deploy to the lowest-risk product team's dev environment first, wait 24 hours, then roll out to others. If a bug in the module causes a failure, it affects one team's dev, not 8 teams' production.

## Product framing (write this first)

> **User pain:** Product teams wait 3–5 days for CorePlatform to manually review and deploy their infrastructure changes to production. This blocks feature releases and creates a platform engineering bottleneck. The Payments team lead said in the last all-hands: "We can't ship fast because infrastructure takes forever."
>
> **MVP constraint:** CorePlatform has 3 engineers and cannot manually review every infrastructure PR. The solution must automate the validation and staging steps, requiring human approval only for production. The pipeline must complete staging → production in under 30 minutes when approved.
>
> **Success metric:** Mean time from infrastructure PR merge to production deployment under 45 minutes (vs. current 3–5 days); zero production incidents caused by infrastructure pipeline failures for 90 days.

## Micro exercise

**Scenario:**
> The Payments team at Meridian wants to add a new Azure Service Bus topic to their production environment. They submit a Bicep change to their infrastructure repository. Currently, there is no pipeline — they would do a manual CLI deployment. CorePlatform is implementing the new pipeline system.
>
> The Payments team's production environment is shared: it already contains a Service Bus namespace, 3 queues, an App Service, and a SQL database. The Bicep template for the namespace uses `--mode Incremental` (you must verify this is enforced). The new topic is the only change.

Your answer must include:
- Design the pipeline stages: list each stage name, what it does, whether it is automated or requires human approval, and what causes it to fail and halt the pipeline.
- Write the `what-if` stage in pseudocode: what command runs, what output is checked, and what automatic check determines whether the pipeline can proceed to staging (hint: check for unexpected deletions).
- Define the approval gate for production: who can approve (role/team, not individual names), what information they must review before approving, and what the maximum approval wait time is before the pipeline auto-cancels.
- Identify one misconfiguration in the scenario that could cause resource deletion (hint: deployment mode) and show how the pipeline prevents it.

## Reflection question
The Payments team's staging deployment succeeds and all tests pass. The approver reviews the `what-if` output and clicks "Approve." Thirty seconds into the production deployment, a different team (the Billing team) has simultaneously started a production deployment that modifies the same shared Service Bus namespace. Both deployments are now running concurrently against the same resource. What is the risk, and what pipeline mechanism prevents concurrent deployments to the same environment?

## Prior concept connection
Day 1 established module design with parameter validation. Day 2 established environment parameterization with separate secrets per environment and separate service principals per stage. Today's pipeline design uses those service principals (Day 2) to deploy those modules (Day 1) with separate credentials per stage — the pipeline is the orchestration layer that connects module design, parameterization, and deployment sequencing.

## AI coach instructions
- Ask the learner to write the Product framing section before designing the pipeline.
- If the learner's pipeline has no `what-if` check or treats it as optional, probe: "What happened to the Payments team because there was no `what-if` step? What specifically would `what-if` have shown before the deletion?"
- Watch for the mistake of using the same service principal for all three pipeline stages. Log in `memory/mistakes.md`.
- Probe the concurrent deployment risk: "What Azure resource lock mechanism, or what pipeline concurrency control, prevents two teams from deploying to the same resource simultaneously?"
- Update `memory/progress.md` with Week 08 Day 3 complete and note whether the learner independently identified the deployment mode (`--mode Complete`) as the root cause of the Service Bus deletion.

## Completion criteria
- Product framing written before the design.
- Pipeline stages defined with automation/approval status and failure conditions.
- `what-if` stage described with automatic deletion check.
- Approval gate defined with reviewer role, review scope, and timeout.
- Deployment mode misconfiguration identified and prevented.
- AI reviewed with cloud architect and product manager perspectives.
