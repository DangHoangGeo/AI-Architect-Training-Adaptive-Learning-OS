# Week 01 Day 2 — Azure regions, availability zones, and resource hierarchy

## Goal
Understand how Azure organizes infrastructure geographically and logically, and use that knowledge to make placement decisions that affect latency, compliance, cost, and resilience.

## Why this matters
Deploying into the wrong region causes compliance violations (data residency), higher latency for end users, and missed SLA targets. Deploying without availability zones means one datacenter outage takes down your service. Architects who understand the resource hierarchy can govern at scale — not just one app, but an entire organization's portfolio.

## Core concept
**Geographic hierarchy:**
- **Region** — a geographic cluster of datacenters. Your primary compliance and latency boundary.
- **Availability Zone (AZ)** — physically separate datacenters within a region. AZ-redundant services survive a single datacenter failure.
- **Region pair** — two regions paired for disaster recovery. Some services replicate automatically across pairs.

**Resource hierarchy (top to bottom):**
- **Management Group** — policy and RBAC scope spanning multiple subscriptions.
- **Subscription** — billing and access isolation boundary.
- **Resource Group** — lifecycle container. Deleting the group deletes everything in it.
- **Resource** — individual service (VM, Storage Account, App Service, etc.).

## Learn — write notes answering these

- What is the operational difference between an Availability Zone and a Region Pair? When do you use each?
- A company operating in Germany has strict GDPR data residency requirements. Which Azure regions apply, and what mechanism enforces data stays there?
- Why would an architect put a web tier and a database in separate resource groups instead of one?
- What is the blast radius of `az group delete --name rg-prod` if everything is in one resource group?

## Micro exercise

**Scenario (product framing — write this first):**
> User pain: A healthcare company lost all test data last month when a developer ran `az group delete` on the wrong resource group. They also just acquired a Japanese clinic and must comply with Japan's APPI data residency law.
> MVP constraint: Must prevent accidental deletion and enforce regional data placement before going live.
> Success metric: Zero cross-border data incidents in the first 6 months; zero unintended resource group deletions.

**Now design:**
> The company runs a patient records system. Japanese patient data must stay in Japan. Australian patient data must stay in Australia. They have one subscription today and two development teams, one per country.

Your answer must include:
- A subscription and resource group structure that prevents the accidental deletion problem.
- Which Azure regions you choose for each country and why.
- Whether you use Availability Zones, and for which components.
- One Azure Policy that enforces the data residency requirement.

## Reflection question
If a developer deploys a storage account to the wrong region despite your Azure Policy, what does the deployment experience look like? At what point does it fail?

## Prior concept connection
Yesterday you chose a service model (IaaS vs PaaS). Today's resource hierarchy determines where that service lives. A PaaS App Service still needs a region with AZ support to achieve high availability. These decisions compound.

## AI coach instructions
Do not give the subscription structure before the learner proposes one. After submission, probe: "If each country team grows to 5 product subscriptions, does your management group hierarchy still work?" Check whether Azure Policy was included — if not, ask how data residency is enforced without it. Update `memory/mistakes.md` if hierarchy shows no isolation thinking.

## Completion criteria
- Learner proposed a concrete subscription, resource group, and region structure.
- AI reviewed it with architect and security perspectives.
- Mistakes added to `memory/mistakes.md`.
- Progress updated.
