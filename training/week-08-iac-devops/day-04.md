# Week 08 Day 4 — Failure, Security, and Cost Review: Rollback and Deployment Safety

## Goal
Stress-test the CorePlatform CI/CD pipeline design from Day 3 by analyzing rollback scenarios, identifying what "rollback" actually means for infrastructure (vs. application code), and designing deployment safety mechanisms that reduce the blast radius when a production infrastructure deployment goes wrong.

## Why this matters
A product team deployed a Bicep change that modified the App Service SKU from P2v3 to B1 in production (they accidentally used the dev parameter file). Response time for all end users degraded instantly from 120ms to 4,200ms. The team tried to "roll back" by re-running the previous pipeline — but the previous pipeline's artifact had already been overwritten. It took 47 minutes to restore service. Rollback for infrastructure requires different thinking than rollback for application code.

## Core concept

1. **Infrastructure rollback is not the same as code rollback.** Rolling back application code means deploying the previous Docker image or app artifact. Rolling back infrastructure means redeploying the previous Bicep template with the previous parameter values. This is harder because: (a) some resources cannot be recreated quickly (SQL databases, Service Bus namespaces with existing messages), (b) some changes are non-reversible (deleting a resource group deletes all resources inside it), and (c) the "previous state" must be stored and retrievable.

2. **Immutable artifact strategy for rollback.** Tag every infrastructure deployment with a version number. Store the Bicep template + parameter file used for that deployment in Azure Blob Storage or as a GitHub release artifact. To roll back, retrieve the tagged artifact and redeploy. Never overwrite the previous artifact — always create a new version.

3. **Azure Deployment history as a rollback source.** Azure keeps the last 800 deployments per resource group in its deployment history. You can redeploy a previous deployment using:
   ```bash
   az deployment group create \
     --resource-group payments-prod \
     --name rollback-$(date +%Y%m%d%H%M%S) \
     --template-file <(az deployment group show --name prev-deployment --query properties.template)
   ```
   However, this only works if the previous deployment succeeded and its template is complete. It does not help if the previous deployment was partial or if parameters contained Key Vault references that have since changed.

4. **Blue-green deployment for high-risk infrastructure changes.** For changes to App Service (scale, SKU, configuration), use deployment slots: deploy to the staging slot, test, then swap. The swap is near-instant and reversible within 20 minutes (before DNS TTL propagates). For database changes, blue-green is harder — schema migrations require backward-compatible approach.

5. **Change freeze windows and emergency change process.** Not all infrastructure changes should be allowed at all times. CorePlatform should enforce: no production infrastructure deployments on Fridays (too close to weekend), no deployments during known high-traffic events, emergency change process (bypasses approval gate with post-facto review and mandatory incident ticket).

6. **Deployment safety checklist.** Before any production infrastructure deployment:
   - `what-if` output reviewed and shows only intended changes
   - No resource deletions in `what-if` output (or explicitly approved)
   - Rollback plan documented: what command, what artifact, estimated time to restore
   - On-call engineer standing by for 30 minutes post-deployment
   - Monitoring dashboard open to detect immediate degradation
   - Customer-impacting change window communicated to support team

## Micro exercise

**Scenario:**
> At 2:15 PM on a Tuesday, the Payments team's production infrastructure pipeline deployed successfully. At 2:22 PM, the on-call engineer notices: App Service CPU is at 98% (was 35% before deployment), p99 latency is 4,200ms (was 120ms). Application Insights shows no errors — just slow responses. The deployment changed: (1) App Service SKU from P2v3 to B1 (accidentally used dev `.bicepparam` file), and (2) enabled a new app setting `FEATURE_FLAG_EXPERIMENTAL=true`.
>
> The on-call engineer needs to restore service immediately and understand the root cause.

Your answer must include:
- Design the rollback procedure: what is the fastest path to restore the App Service to P2v3 SKU, and what is the second-fastest path if the first fails? Include the specific Azure CLI command or portal action.
- Identify which of the two changes (SKU change or feature flag) is more likely to be the immediate cause, and how you confirm this hypothesis using Application Insights and Azure Monitor in under 5 minutes.
- Design the pipeline guardrail that would have prevented the `dev` parameter file from being used in the production pipeline stage. Be specific: what check runs, where in the pipeline, and what causes it to fail.
- Define the post-deployment monitoring window: what metrics are watched, for how long, by whom, and what threshold triggers an immediate automatic rollback vs. a human-decision rollback?

## Reflection question
CorePlatform is considering implementing automatic rollback: if CPU rises above 90% within 5 minutes of a deployment, the pipeline automatically redeploys the previous Bicep template. What is the main risk of automatic rollback, and under what conditions would automatic rollback make an incident worse rather than better?

## Prior concept connection
Day 3 designed the pipeline with `what-if` and approval gates. Those controls prevent most deployment errors. Today's rollback and safety mechanisms handle the cases that slip through: a `what-if` that showed correct output but the deployment had an unexpected runtime effect (SKU downgrade causing performance degradation is an example — `what-if` would show the change correctly, but it does not simulate the performance impact). Both layers are required.

## AI coach instructions
- Give the learner the incident scenario first and ask them to design the rollback procedure before explaining the concepts.
- If the learner proposes "just redeploy the old template from Git history," probe: "The Git history has the template, but how do you recover the parameter values that were used for the last good production deployment — specifically the Key Vault secret references?"
- Watch for the mistake of treating App Service slot swap as a universal rollback mechanism for all infrastructure types. Log in `memory/mistakes.md`.
- Probe automatic rollback: "A deployment correctly changes the SQL connection string to a new database. The new database has a schema problem. CPU rises to 95%. The automatic rollback redeploys the old connection string, now pointing to the old database which has stale data. What has the automatic rollback caused?"
- Update `memory/progress.md` with Week 08 Day 4 complete and note whether the learner independently identified the need for artifact immutability.

## Completion criteria
- Rollback procedure defined with primary and secondary paths and specific commands.
- Root cause hypothesis tested using specific monitoring tools with a 5-minute time constraint.
- Pipeline guardrail designed that prevents environment parameter mismatch.
- Post-deployment monitoring window defined with thresholds and escalation criteria.
- AI reviewed with cloud architect, DevOps, and product manager perspectives.
