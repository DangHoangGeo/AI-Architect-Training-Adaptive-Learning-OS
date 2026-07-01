# Week 06 Day 2 — Azure Service Mapping: Application Insights and Distributed Tracing

## Goal
Map Application Insights to its specific observability role (request tracking, dependency telemetry, distributed tracing), understand how correlation IDs connect a single user request across multiple services, and determine which Application Insights features would have surfaced the NovaBridge outage root cause in minutes rather than hours.

## Why this matters
NovaBridge's 4-hour outage was caused by SQL connection pool exhaustion. With Application Insights SDK configured and distributed tracing enabled, an engineer would see: average dependency duration for SQL calls rising from 50ms to 8,000ms, then failing. The dependency failure map would visually show the exact service-to-database edge turning red. This diagnosis takes 3 minutes, not 4 hours.

## Core concept

1. **Application Insights is an APM (Application Performance Monitoring) service.** It collects: requests (HTTP in), dependencies (HTTP out, SQL, queue calls), exceptions, page views, custom events, and performance counters. It lives inside Azure Monitor but has its own SDK, portal blade, and query model.

2. **Connection string vs instrumentation key.** The legacy approach used an instrumentation key (GUID). The current approach uses a connection string that includes the endpoint. Always use the connection string in new deployments. Store it in Key Vault, inject via App Service environment variable `APPLICATIONINSIGHTS_CONNECTION_STRING`.

3. **Auto-instrumentation vs SDK instrumentation.** For .NET on App Service (Windows), you can enable Application Insights without code changes using the portal's "Application Insights" blade (auto-instrumentation). This captures requests and dependencies automatically. For custom events, custom metrics, or structured properties, you need the SDK (`Microsoft.ApplicationInsights` NuGet package or `Microsoft.ApplicationInsights.AspNetCore`). Auto-instrumentation is the fast start; SDK is the production baseline.

4. **Distributed tracing and correlation IDs.** When Service A calls Service B, Application Insights propagates a `traceparent` header (W3C trace context). Each service records its span with the same trace ID. In the Application Insights portal, the "End-to-end transaction details" view reconstructs the full call chain as a Gantt chart — you can see every hop and its duration. Without this, a slow downstream call appears as an unexplained latency spike in the upstream service.

5. **Dependency tracking for SQL.** Application Insights automatically tracks SQL calls made via `System.Data.SqlClient` or Entity Framework. You can see: the SQL command, duration, success/failure, and target database. For NovaBridge's connection pool exhaustion, the dependency view would show: SQL dependency duration rising, then `SqlException: Timeout expired. The timeout period elapsed prior to obtaining a connection from the pool`.

6. **Sampling.** Application Insights does not store every telemetry item by default — adaptive sampling reduces data volume to control cost. For high-traffic services, this means some requests are not recorded. For anomaly detection and alerting, sampling is acceptable. For debugging a specific user's failed transaction, you need to disable sampling for that request or use `TelemetryClient.TrackException` to force-capture exceptions regardless of sampling.

## Learn — write notes answering these

1. What is the difference between auto-instrumentation and SDK instrumentation for Application Insights? When is each sufficient?
2. Explain distributed tracing: what is a "trace ID," what is a "span," and how does Application Insights propagate trace context across service boundaries?
3. NovaBridge's App Service calls Azure SQL. List the specific telemetry items Application Insights would emit for a single checkout request, from HTTP request in to SQL query out. Name each telemetry type.
4. Application Insights adaptive sampling is enabled by default. In a post-incident investigation, a developer says "I cannot find the failed request in Application Insights." What are two reasons this could happen and how do you mitigate each?

## Micro exercise

**Scenario:**
> After Day 1's work, NovaBridge has Diagnostic Settings configured and Log Analytics alerts firing. Now the team wants to add Application Insights to understand *why* requests fail, not just *that* they fail. The platform has three services:
> - **API Gateway** (Azure APIM): receives all external requests
> - **Core API** (App Service, ASP.NET Core): handles business logic, calls SQL Database and a third-party payment API
> - **Worker Service** (Azure Function): processes async jobs from a Service Bus queue
>
> The previous outage involved SQL connection pool exhaustion in the Core API, but it took 4 hours to diagnose because nobody could see SQL dependency durations.

Your answer must include:
- Specify where Application Insights is deployed (one resource per service or shared?) and justify the decision with one architectural reason for each option.
- Describe the auto-instrumentation vs. SDK decision for each of the three services and explain what each option captures vs. misses.
- Describe the distributed trace: if an APIM request triggers a Core API call which triggers a Worker Service message, what does the end-to-end trace look like and what would it have shown during the SQL pool exhaustion?
- Write one Application Insights alert rule that would have fired within 5 minutes of the outage starting: name the signal type, metric name, threshold, and action.

## Reflection question
Application Insights stores 90 days of data by default (on Workspace-based mode with Log Analytics retention settings). After a serious incident, a client's legal team requests logs from 6 months ago to support a breach investigation. What do you tell them — and what should have been configured to avoid this conversation?

## Prior concept connection
Day 1 established Log Analytics Workspace as the log store and platform metrics as the alert signal. Application Insights today adds the application-level layer: request telemetry, dependency tracking, and distributed tracing. Together, they form the full observability stack: infrastructure (Monitor/Log Analytics) + application (Application Insights).

## AI coach instructions
- Ask the learner to identify what telemetry was absent during the NovaBridge outage before explaining Application Insights features.
- If the learner creates one Application Insights resource per service without justification, probe: "What is the correlation impact of separate resources vs. shared workspace? Can you trace a request across service boundaries?"
- Watch for the mistake of assuming auto-instrumentation captures custom business events (it does not). Log in `memory/mistakes.md`.
- Probe the sampling issue: "If sampling is on and only 10% of requests are recorded, what is the false negative rate for your error rate alert?"
- Update `memory/progress.md` with Week 06 Day 2 complete and note whether the learner independently described the dependency telemetry for SQL.

## Completion criteria
- Application Insights deployment topology (shared vs. per-service) decided with justification.
- Auto-instrumentation vs. SDK decision made for each service with explanation of gaps.
- Distributed trace described for the three-service scenario.
- One specific alert rule defined that would have fired during the outage.
- AI reviewed with cloud architect and product manager perspectives.
