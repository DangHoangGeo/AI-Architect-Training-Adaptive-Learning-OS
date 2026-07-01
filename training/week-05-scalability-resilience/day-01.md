# Week 05 Day 1 — Concept Foundation: Horizontal Scale and Stateless Compute

## Goal
Understand why stateless compute is the prerequisite for horizontal scaling, and how to design Azure web tiers that can scale out without sticky sessions, local state, or node-specific secrets. By the end of the day you should be able to identify statefulness bugs in an existing design and propose a remedy.

## Why this matters
If your compute tier stores session data in local memory, a sudden scale-out event splits user sessions across instances — half of authenticated users get logged out mid-transaction. At a major concert ticket sale, this translates directly to lost revenue, support floods, and public embarrassment that trends on social media within minutes of the on-sale time.

## Core concept

1. **Statefulness is the enemy of scale-out.** Any state kept in process memory (sessions, shopping carts, upload progress) prevents you from routing the same user to a different instance. Azure App Service "ARR affinity" (sticky sessions) is a band-aid, not a solution — it defeats the purpose of multiple instances.

2. **The stateless contract.** An instance must be replaceable: identical startup, identical behavior with identical input, no local disk writes that matter. Configuration comes from environment variables or Azure App Configuration; secrets come from Key Vault references at startup.

3. **Session state must move to an external store.** Azure Cache for Redis is the standard choice. It provides sub-millisecond reads, TTL-based expiry, and built-in clustering. Alternatives: Azure SQL (too slow for every request), Cosmos DB (viable but costlier than Redis for pure session use).

4. **VMSS vs App Service vs Container Apps.** App Service Plan auto-scale is rule- or metric-based and takes 2–5 minutes to add an instance. Azure Container Apps scales on HTTP concurrency or KEDA triggers with faster response. VMSS gives full control but adds significant operational overhead. Ticket sales need pre-scaling, not reactive scaling.

5. **Pre-warming is a design decision.** If scale-out takes 3 minutes and your traffic spike lasts 90 seconds (everyone hitting "buy" the moment tickets go live), reactive auto-scale arrives too late. You must pre-scale to a known floor before the announced on-sale time.

6. **Deployment slots and zero-downtime.** Stateless apps can use App Service deployment slots with swap. Because no instance holds unique state, a slot swap during a quiet period is safe. Swapping during peak traffic is still risky due to connection drain delays.

## Learn — write notes answering these

1. What makes an application instance "stateless" and why is that property required before horizontal scaling can work correctly?
2. What specific Azure resources do you use to externalize (a) HTTP session state and (b) ephemeral file uploads that need to be shared across instances?
3. Describe the difference between reactive auto-scale and pre-scaling. In which situations does each approach fail?
4. A developer says "we just enable ARR affinity and sticky sessions solve the problem." What is the architectural risk of accepting that answer long-term?

## Micro exercise

**Scenario:**
> TicketStream is a concert ticketing platform. An artist with 800,000 social-media followers announces a tour. Tickets go on sale at 10:00 AM Saturday. Historical data shows the platform handles 2,000 concurrent users on a normal day. Within the first 60 seconds of an on-sale event, the platform has received 85,000 concurrent connection attempts. The current backend is a single App Service (B3 tier, 1 instance) running an ASP.NET Core API. Sessions are stored in in-process memory.

Your answer must include:
- Identify exactly two stateful components in the current design and explain why each breaks under scale-out.
- Propose the Azure services you would use to externalize that state, with one sentence justifying each choice.
- Describe your pre-scaling strategy: what tier, how many instances, and at what time relative to the 10:00 AM on-sale.
- Identify one deployment or configuration change required on the App Service itself to ensure new instances start cleanly (no stale state).

## Reflection question
Your pre-scaling plan sets a floor of 20 instances at 9:45 AM. The event is so large that 20 instances are also insufficient. What architectural backstop would you add — and what is its cost trade-off?

## Prior concept connection
Week 4 covered Azure App Service networking and deployment patterns. Today's stateless compute concept depends on those deployment fundamentals — specifically, how environment variables and Key Vault references are injected at startup rather than baked into instance images.

## AI coach instructions
- Ask the learner to identify the stateful components before offering any hints.
- If the learner proposes sticky sessions as a solution, push back: "What happens when you need 30 instances and session counts are unevenly distributed?"
- Watch for the mistake of treating Redis as optional ("we can add it later"). This is a common mistake — log it in `memory/mistakes.md` if the learner makes it.
- Probe: "How would you validate that your App Service instances are truly stateless before the on-sale event?"
- Update `memory/progress.md` with Week 05 Day 1 complete and note whether the learner independently identified pre-scaling.

## Completion criteria
- Learner identified both stateful components (session store and any local file/cache).
- Learner proposed Azure Cache for Redis for session externalization with justification.
- Learner described a pre-scaling plan with specific instance counts and timing.
- AI reviewed with cloud architect and product manager perspectives.
- Mistakes and weak areas updated in memory if needed.
