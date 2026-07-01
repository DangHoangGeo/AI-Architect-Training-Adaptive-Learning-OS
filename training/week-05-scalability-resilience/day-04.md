# Week 05 Day 4 — Failure, Security, and Cost Review: Retry, Timeout, and Circuit Breaker Patterns

## Goal
Stress-test the TicketStream architecture built across Days 1–3 by applying retry, timeout, and circuit breaker patterns. Identify which service boundaries need which pattern, and understand how missing or misconfigured resilience patterns turn a partial outage into a total platform failure.

## Why this matters
During a high-stakes on-sale event, a payment provider API that starts returning errors in 8% of calls does not just lose 8% of transactions — without a circuit breaker, the checkout API threads pile up waiting for timeouts, the thread pool exhausts, and the entire platform goes down for 100% of buyers. The 8% failure cascades into a 100% outage.

## Core concept

1. **Retry is for transient faults — not for persistent ones.** Retrying a database that is genuinely overloaded adds more load. Retry should be used with exponential backoff and jitter (to avoid synchronized retry storms) only for faults expected to resolve within seconds. Use the Polly library in .NET or built-in retry policies in Azure SDKs.

2. **Timeout is mandatory at every external call.** Without an explicit timeout, a slow dependency holds a thread/connection indefinitely. All HTTP clients, database connections, and external API calls must have explicit timeouts. Azure App Service default HTTP timeout is 230 seconds — far too long for a checkout flow. Set timeouts to match user expectations: payment call timeout = 8 seconds.

3. **Circuit breaker stops the cascade.** When a downstream service failure rate exceeds a threshold (e.g., 20% of calls failing in 30 seconds), the circuit breaker opens and subsequent calls fail fast without attempting the downstream call. This frees resources to serve other requests. After a configured interval, the circuit enters "half-open" state and tests one call. If it succeeds, the circuit closes.

4. **Azure APIM retry and circuit breaker policies.** Azure API Management has built-in `retry` and `forward-request` policies. For circuit breaking at the API gateway level, use APIM's `backends` with circuit breaker configuration (GA since 2024). This centralizes resilience policy without requiring every microservice to implement it independently.

5. **Bulkhead pattern complements circuit breaker.** Isolate resource pools per downstream dependency. If the payment provider call uses a dedicated thread pool of 20 threads, a payment outage exhausts only those 20 threads — not the shared pool that also serves ticket lookup and seat map calls.

6. **Cost of over-retrying.** Each retry is a chargeable API call. If payment provider charges per transaction attempt, an aggressive retry policy (5 retries × 40,000 checkouts) means 200,000 API calls on the payment provider bill. Design retry budgets carefully.

## Micro exercise

**Scenario:**
> During the TicketStream on-sale for a 60,000-capacity stadium show, the following failure sequence occurred:
> - At T+0s: Stripe payment API response time increased from 300ms to 4,200ms (no errors yet, just slow).
> - At T+45s: App Service thread pool reached 95% utilization (threads waiting on Stripe timeouts).
> - At T+60s: App Service began returning HTTP 503 to all checkout attempts — not just payment calls, but also seat map lookups and browsing.
> - At T+90s: The on-sale was effectively dead. 55,000 fans could not reach the site.
> - Stripe recovered at T+4min. Platform was already down.
>
> The team had no retry policy, no circuit breaker, and an HTTP client timeout of 100 seconds (inherited from default HttpClient settings).

Your answer must include:
- Identify the three specific design failures (missing patterns) that caused the cascade. Name each pattern and where in the architecture it should have been placed.
- Define the correct timeout value for the Stripe payment call and justify your number against user experience expectations.
- Design a circuit breaker policy for the Stripe dependency: specify the failure rate threshold, the open-circuit duration, and the half-open test behavior.
- Explain the bulkhead: what resource pool is isolated, what its size should be, and what happens to non-payment calls when the payment bulkhead is fully occupied.

## Reflection question
Your circuit breaker opens because Stripe is failing. The checkout API now fast-fails all payment calls with an error. From a product perspective, is it better to show the user "Payment temporarily unavailable, try again in 2 minutes" or to silently queue the order and confirm by email when payment succeeds? What are the trade-offs of each approach?

## Prior concept connection
Day 2 introduced the Service Bus queue as a buffer between checkout API and order processor. Today's circuit breaker pattern protects the checkout API's outbound calls to payment providers. Together, the queue (Day 2) and circuit breaker (today) form a complete defensive architecture: the queue absorbs inbound burst; the circuit breaker limits outbound cascade.

## AI coach instructions
- Present the failure scenario and ask the learner to diagnose before explaining the patterns.
- If the learner names "retry" as the solution to the cascade, probe: "At what point does retrying a slow Stripe call make things worse rather than better?"
- Watch for the mistake of setting a very long timeout "to be safe" — log in `memory/mistakes.md` if the learner proposes a timeout over 15 seconds for a payment call.
- Probe the product trade-off on queue-vs-fail-fast: "What would you tell the fan who queued their order and found out 30 minutes later they did not actually get tickets?"
- Update `memory/progress.md` with Week 05 Day 4 complete and note whether the bulkhead pattern was independently identified.

## Completion criteria
- Three cascade failure points identified and named correctly.
- Timeout value justified against user experience (not just technically).
- Circuit breaker policy fully specified (threshold, duration, half-open behavior).
- Bulkhead resource isolation described with concrete pool size.
- AI reviewed with cloud architect, product manager, and security/cost perspectives.
