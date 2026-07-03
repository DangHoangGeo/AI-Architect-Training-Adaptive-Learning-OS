## 30-day plan, designed for your specific path: basic cloud → system architect → PM for AI systems.

**Daily loop (fixed, ~75 min every day, all 30 days)**

- 25 min: learn (course/docs for that week's theme)
- 25 min: build (hands-on in a free-tier cloud account)
- 15 min: design on paper (one small architecture sketch)
- 10 min: decision journal (what I decided/learned today + why)

**Week 1 — Cloud foundations + the thinking process**

- Learn: pick ONE cloud (AWS is safest for jobs). Cover: compute (EC2), storage (S3), networking basics (VPC), IAM. Use AWS Skill Builder or the free Cloud Practitioner course.
- Build: create a free-tier account, deploy a static website on S3, launch one EC2 instance, then tear it down.
- Framework to internalize this week: **understand → constrain → options → trade-offs → decide → checkpoint**. Apply it to every exercise, even tiny ones.
- Paper designs: Day 1: a personal blog. Day 3: a photo-sharing app. Day 6: redraw the blog assuming 1M users.
- Milestone: you can explain compute/storage/network/identity in plain words.

**Week 2 — How real systems are shaped**

- Learn: load balancers, autoscaling, managed databases (RDS vs DynamoDB), caching (Redis), queues (SQS). One concept per day.
- Build: deploy a simple app (even a tutorial to-do app) behind a load balancer with a managed database.
- Framework: **"what breaks at 10x?"** — end every design by finding the bottleneck.
- Read: one AWS architecture case study per day (aws.amazon.com/architecture) — 10 min, sketch what you read from memory after.
- Milestone: you can draw a standard 3-tier web architecture without looking anything up.

**Week 3 — Reliability, security, and AI-specific architecture**

- Learn (days 15–17): failure design — multi-AZ, backups, health checks; security — least privilege, secrets management, encryption.
- Learn (days 18–21): AI system basics — what an inference endpoint is (SageMaker/Bedrock), why GPUs change cost math, RAG architecture (app → embedding → vector DB → LLM), token costs.
- Build: call an LLM API from a small script, then sketch (not build) a full RAG system on your cloud.
- Framework: **pre-mortem** — before each design, write "this failed in 6 months because…"
- Milestone: you can draw an AI app architecture end-to-end and name where it breaks and what it costs.

**Week 4 — PM thinking + putting it together**

- Learn: write one-page design docs. Structure: problem, users, constraints, 2–3 options, trade-offs, recommendation, risks, success metrics. This exact skill is the architect→PM bridge.
- Build (days 22–27): your capstone — design and partially build a small AI product (e.g., "chatbot that answers questions about uploaded PDFs"). Write the design doc FIRST, then build the skeleton.
- PM practice: for your capstone, answer customer questions yourself — who is this for, what's the workaround today, what's the success metric, what would make someone pay?
- Days 28–30: review your entire decision journal. Write one page: "what I believed on day 1 that was wrong." Then redo your Day 1 blog design — the gap you'll see is your proof of progress.

**Weekly review (Sundays, 30 min)**: reread the journal, mark wrong predictions, pick next week's weakest area.

**After day 30**, the loop continues but shifts: 1 real project per month, 1 design doc per week, 1 postmortem read per day. Aim at the AWS Solutions Architect Associate cert around month 3–4 — not for the paper, but because it forces breadth.

Two honest warnings: 30 days makes you *dangerous*, not the best — the best-of-the-best is this loop sustained for years. And don't rush to PM; your PM value later comes precisely from the architecture depth you build now.

---

**1. Networking fundamentals (before any cloud)**

- **OSI/TCP-IP model**: what happens at each layer — you need this to debug anything.
- **IP addressing & CIDR**: subnets, public vs private IPs, IPv4/IPv6. You must be able to read `10.0.0.0/16` fluently — every cloud network design starts with CIDR math.
- **DNS**: records (A, CNAME, TXT, MX), resolution flow, TTL, why DNS is behind half of all outages.
- **TCP vs UDP**: handshakes, ports, connection state.
- **HTTP/HTTPS**: request lifecycle, status codes, headers, HTTP/2 vs 3, keep-alive.
- **TLS**: certificates, handshake, termination points, mTLS.
- **Routing & NAT**: route tables, gateways, how a packet gets from a private server to the internet.
- **Load balancing**: L4 vs L7, algorithms, health checks, sticky sessions.

**2. Cloud networking (the same concepts on every platform)**

- **Virtual network**: VPC (AWS/GCP) = VNet (Azure) — the foundational container.
- **Subnet design**: public vs private subnets, per-AZ layout, sizing for growth.
- **Gateways**: internet gateway, NAT gateway (and its cost trap), VPN gateway.
- **Network security layers**: security groups (stateful, instance-level) vs NACLs (stateless, subnet-level).
- **Private connectivity**: VPC peering, transit gateway/hub-spoke, private endpoints/PrivateLink — how services talk *without* touching the internet.
- **Hybrid connectivity**: site-to-site VPN vs dedicated lines (Direct Connect/ExpressRoute).
- **Edge**: CDN (CloudFront/Cloud CDN/Front Door), global vs regional load balancers, Anycast.
- **Service-to-service**: service discovery, service mesh basics (when you get to Kubernetes).

**3. Security fundamentals**

- **CIA triad**: confidentiality, integrity, availability — the lens for every decision.
- **AuthN vs AuthZ**: who you are vs what you're allowed to do — never confuse them.
- **Cryptography basics**: symmetric vs asymmetric, hashing vs encryption, key exchange — conceptually, not the math.
- **Encryption in transit and at rest**: where each applies and who holds the keys.
- **OWASP Top 10**: injection, broken auth, SSRF, etc. — the standard attack catalog.
- **Threat modeling**: STRIDE framework — spoofing, tampering, repudiation, info disclosure, DoS, elevation of privilege.
- **Principle of least privilege** and **defense in depth** — the two ideas behind everything else.

**4. Cloud security (where projects are won or lost)**

- **IAM deeply**: users, roles, policies, temporary credentials, role assumption. This is THE most important cloud security topic — most breaches are IAM mistakes, not exotic hacks.
- **Shared responsibility model**: what the cloud secures vs what you must.
- **Secrets management**: vaults (Secrets Manager/Key Vault), rotation, why secrets never go in code or env files in repos.
- **Key management**: KMS, customer-managed vs provider-managed keys, envelope encryption.
- **Identity federation & SSO**: SAML/OIDC, workload identity (how a server proves who it is without passwords).
- **Network security services**: WAF, DDoS protection (Shield/Armor), firewall services.
- **Data security**: bucket policies (public S3 buckets are the classic breach), data classification, tokenization/masking.
- **Logging & detection**: audit logs (CloudTrail), flow logs, centralized logging, alerting on anomalies.
- **Compliance basics**: awareness of SOC 2, GDPR, HIPAA — as a future PM you'll need to speak this language.

**5. Application-level security**

- **OAuth 2.0 & OIDC flows**: authorization code flow, tokens, refresh — powers virtually all modern app auth.
- **JWT**: structure, validation, common mistakes (no expiry, weak signing).
- **API security**: rate limiting, API keys vs tokens, input validation, CORS.
- **Session management**, CSRF, XSS defenses.
- **Supply chain**: dependency scanning, image scanning, signed artifacts.

**6. AI-specific security (your differentiator)**

- Prompt injection and jailbreaks, data leakage via model outputs, securing RAG pipelines (who can query which documents), API key/token cost abuse, and model access controls.

**How to learn it**: fold this into your daily loop over roughly 8–10 weeks — weeks 1–2 on section 1, weeks 3–4 on section 2, and so on. For every concept, do three things: explain it in one sentence in your journal, find it in a real architecture diagram, and answer "how would an attacker abuse this if misconfigured?" That third question is what turns knowledge into architect judgment.

The self-test that tells you you're ready: you can draw a multi-tier app with correct subnet placement, security group rules, IAM roles, TLS termination point, and secrets flow — from memory, on any cloud. Want a set of practice scenarios to test yourself against as you go?