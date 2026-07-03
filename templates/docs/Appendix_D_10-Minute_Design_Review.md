# Appendix D — 10-Minute Design Review (the short version)

When time is short, answer these nine and you've covered 80% of the risk:

1. What problem, for whom, and how do we measure success?
2. What are the top 2 non-functional requirements (and their numbers)?
3. What are the 2–3 options, and what trade-off does the chosen one accept?
4. What is internet-facing, and why can't it be private?
5. Who/what can access the data, and what's the worst credential to leak?
6. What breaks first at 10x load?
7. What does the user see when the riskiest component fails?
8. How do we roll back in under 5 minutes?
9. What does this cost per month, and which line item explodes at scale?

Great engineers don't chase all four qualities equally — they design for failure first, then optimize. 
The core mindset: assume everything will break, get attacked, and grow 10x.

**Infrastructure**

- **Reliability through redundancy, not perfection**: multiple availability zones, load balancers, automatic failover, and health checks. They design so any single component can die without users noticing.
- **Security in layers (defense in depth)**: private networks by default, least-privilege access (IAM), encryption in transit and at rest, secrets in a vault — never in code — and everything logged and auditable.
- **Scalability via statelessness**: servers hold no local state, so you can add or kill instances freely. State lives in databases, caches, and object storage that scale independently.
- **Infrastructure as Code** (Terraform, etc.): the whole environment is versioned, reviewable, and reproducible. No hand-configured "snowflake" servers.
- **Efficiency through observability**: metrics, tracing, and autoscaling so you pay for what you use and see bottlenecks before users do.

**Application**

- **Simple, modular boundaries**: clear separation of concerns (whether a monolith or services), so parts can be changed, tested, and scaled independently. The best engineers resist premature microservices — complexity is the enemy of all four goals.
- **Design for failure**: timeouts, retries with backoff, circuit breakers, idempotent operations, graceful degradation. Assume every network call can fail.
- **Security at the code level**: validate all input, parameterized queries, authn/authz on every request, dependencies scanned and updated.
- **Performance via data design**: the schema, indexes, and caching strategy matter far more than micro-optimizing code. Measure first, optimize the actual bottleneck.
- **Testing + CI/CD**: automated tests, small frequent deploys, feature flags, and easy rollbacks — reliability comes from making change safe, not rare.

The unifying principle: start simpler than you think you need, but with clean boundaries and good observability — that's what makes a system *expandable* later without a rewrite. Want me to go deeper on any layer, like a concrete architecture example?