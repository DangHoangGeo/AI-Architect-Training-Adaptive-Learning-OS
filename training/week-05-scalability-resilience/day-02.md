# Week 05 Day 2 — Azure Service Mapping: Queue-Based Load Leveling

## Goal
Map the queue-based load leveling pattern to specific Azure messaging services, understand when to use Service Bus versus Storage Queue versus Event Hubs, and apply the pattern to decouple a burst-sensitive ticketing checkout flow from its downstream processing.

## Why this matters
Without a queue between the checkout API and the order-processing backend, a 50x traffic spike during an on-sale event causes either: (a) the backend crashes under direct load, (b) you over-provision the backend to handle peak load 24/7 at 50x cost, or (c) you implement back-pressure that returns HTTP 429s to customers trying to buy tickets — all three outcomes are business failures.

## Core concept

1. **The pattern in one sentence.** A queue sits between producer (ticket checkout API) and consumer (order processor), absorbing burst writes while the consumer processes at a steady, sustainable rate. The queue depth is the pressure gauge — high depth means producers are outrunning consumers.

2. **Azure Service Bus vs Azure Storage Queue vs Azure Event Hubs.**

   | Dimension | Storage Queue | Service Bus | Event Hubs |
   |---|---|---|---|
   | Max message size | 64 KB | 256 KB – 100 MB | 1 MB (Standard), 100 MB (Premium) |
   | Ordering | No guarantee | Sessions = FIFO per session | Partition-level ordering |
   | Dead-letter queue | No | Yes (native) | No |
   | Competing consumers | Yes | Yes | Consumer groups, not competing |
   | At-least-once delivery | Yes | Yes | Yes |
   | Best fit for ticketing | Simple fan-out | Ordered checkout per user | High-volume event streaming |

   For ticketing checkout: Service Bus with sessions (one session per order) gives you FIFO per-customer ordering and a dead-letter queue for failed payments.

3. **Consumer scaling.** Azure Functions with Service Bus trigger scales consumers dynamically. Each function instance processes one message at a time by default. Max concurrency is configurable. This is your primary lever for "how fast do we drain the queue."

4. **Poison message handling.** After a configurable delivery count (e.g., 5 retries), Service Bus moves messages to the dead-letter queue. Without this, a single malformed order loops forever and blocks processing. The dead-letter queue needs its own monitoring alert.

5. **Back-pressure signal.** Monitor `ActiveMessageCount` on the queue. If it rises continuously for more than 5 minutes, your consumer fleet is undersized. Wire an Azure Monitor alert to trigger a scale-out of the consumer Function App.

6. **Idempotency requirement.** Because Service Bus guarantees at-least-once delivery (not exactly-once), your order processor must be idempotent — processing the same order ID twice must produce the same result as processing it once. This is a design contract, not an implementation detail.

## Learn — write notes answering these

1. What are the three most important differences between Azure Service Bus and Azure Storage Queue for a transactional checkout scenario?
2. Explain the dead-letter queue. What triggers a message to go there, and what operational process must exist to handle dead-lettered messages?
3. How do you make a Service Bus consumer idempotent? Give a concrete database-level approach.
4. A stakeholder asks: "If we add a queue, how long will it take for a customer to get their ticket confirmation?" How do you answer this — and what SLA commitment is realistic?

## Micro exercise

**Scenario:**
> TicketStream's checkout API currently calls an order-processing microservice synchronously (HTTP). During the Coldplay reunion tour on-sale event, 40,000 checkout attempts arrive in the first 90 seconds. The order processor handles 800 requests per minute at peak. With synchronous calls, 90% of checkouts are timing out. The CTO wants a fix before the next on-sale in 3 weeks.

Your answer must include:
- Draw (in text or ASCII) the new architecture: what sits between the checkout API and order processor, and what Azure services fulfill each role.
- Specify which Azure Service Bus tier (Basic, Standard, Premium) and why, including one feature that rules out a cheaper tier.
- Describe how the checkout API responds to the user immediately (what HTTP status and body) while the order is queued.
- Define the dead-letter alert: what metric, what threshold, and what action it triggers.

## Reflection question
A customer submits the checkout form twice because the browser showed a spinner (the confirmation email was delayed). Both messages arrive on the queue. What happens if your order processor is not idempotent — and what specific check prevents the duplicate order?

## Prior concept connection
Day 1 established that the checkout API must be stateless and horizontally scalable. Today's queue is the downstream counterpart: it decouples the stateless API burst from the stateful order processing backend. Together they form the full scale-out story for the on-sale event.

## AI coach instructions
- Ask the learner to choose a Service Bus tier before explaining tiers. Their first instinct reveals whether they default to the cheapest option without checking feature requirements.
- If the learner skips dead-letter queue handling, probe: "What happens to a checkout where the payment provider returned a malformed response on every retry?"
- Watch for the mistake of using a Storage Queue for transactional ordering — log in `memory/mistakes.md`.
- Probe idempotency: "Show me the SQL or pseudo-code for an idempotent order insert."
- Update `memory/progress.md` with Week 05 Day 2 complete and note whether dead-letter handling was addressed independently.

## Completion criteria
- Learner correctly selected Service Bus over Storage Queue with feature justification.
- Learner described the immediate HTTP response pattern (202 Accepted + correlation ID).
- Dead-letter queue handling and monitoring were addressed.
- Idempotency mechanism was described.
- AI reviewed with cloud architect and product manager perspectives.
