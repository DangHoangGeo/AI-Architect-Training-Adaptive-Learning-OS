# Appendix B — Application-Layer Best Practices Checklist

## Authentication & Authorization
- [ ] Standard protocols only (OAuth 2.0 / OIDC); never a hand-rolled auth scheme.
- [ ] Authorization enforced server-side on **every** request/object (prevents IDOR/BOLA — the top API vulnerability); never trust IDs from the client.
- [ ] JWTs: signature verified, short expiry, audience/issuer checked, revocation strategy for refresh tokens.
- [ ] Sessions: secure, HttpOnly, SameSite cookies; rotation on privilege change; server-side logout.
- [ ] Password handling (if any): modern hashing (argon2/bcrypt), breach-list checks, rate-limited login, MFA offered.

## Input, Output & API Security
- [ ] All input validated server-side (type, length, range, allow-lists); validation errors don't leak internals.
- [ ] SQL/NoSQL access via parameterized queries / ORM — string-built queries banned.
- [ ] Output encoding per context (HTML/JS/URL) to prevent XSS; CSP headers set.
- [ ] CSRF protection on state-changing browser requests.
- [ ] CORS: explicit allow-list of origins; never `*` with credentials.
- [ ] Rate limiting & quotas per user/key on all public endpoints; pagination caps on list endpoints.
- [ ] File uploads: type/size validated, stored outside web root (object storage), never executed, scanned if user-shared.
- [ ] SSRF defenses on any server-side fetch of user-supplied URLs (allow-lists, block metadata endpoints like 169.254.169.254).
- [ ] API errors: generic messages to clients, detailed logs internally; stack traces never reach users.

## Reliability Patterns in Code
- [ ] Every network call has a timeout (no infinite waits).
- [ ] Retries with exponential backoff + jitter — only on idempotent operations.
- [ ] Idempotency keys on payment-like / at-least-once operations.
- [ ] Circuit breakers on flaky dependencies; graceful degradation paths defined.
- [ ] Health endpoints: liveness and readiness, checking real dependencies.
- [ ] Graceful shutdown: drain in-flight requests on deploy/scale-in.
- [ ] Backpressure: queues bounded; shed load rather than collapse.

## Data Handling in the App
- [ ] PII never written to logs, error messages, analytics, or LLM prompts without policy approval.
- [ ] DB migrations are versioned, backward-compatible, and reversible.
- [ ] Transactions used where multi-step consistency matters; race conditions considered (locks/optimistic concurrency).

## Dependencies & Supply Chain
- [ ] Lockfiles committed; dependency scanning in CI (Dependabot/Snyk/equivalent) with an SLA to patch criticals.
- [ ] Minimal dependency policy — each new library must earn its place.
- [ ] Container images pinned and scanned; artifacts signed where the platform supports it.

## Testing & Delivery
- [ ] Unit tests on core logic; integration tests on critical paths; at least smoke tests post-deploy.
- [ ] Security tests in CI: SAST + secret scanning at minimum.
- [ ] CI/CD: every change via pipeline + review; no manual prod deploys.
- [ ] Small, frequent releases behind feature flags; rollback rehearsed.
- [ ] Load test against the Section 4 targets before launch.

## Observability in Code
- [ ] Structured logs (JSON) with correlation/request IDs propagated across services.
- [ ] Metrics emitted for business + golden signals; traces on cross-service paths.
- [ ] One dashboard per service answering "is it healthy?" in 10 seconds.

---
