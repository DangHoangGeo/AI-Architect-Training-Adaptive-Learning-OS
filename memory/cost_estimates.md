# Cost Estimates Log

This file records rough cost estimates produced during workshops.
Used to build cost estimation intuition across 12 weeks.

## Format

Each entry follows this structure:
```
## YYYY-MM-DD — Week XX [Topic] — [Workshop Name]
**Scale**: [user count / request volume at which this estimate applies]
**Environment**: Dev / Prod

| Service | SKU | Monthly estimate |
|---|---|---|
| [service] | [SKU] | $X–Y/month |

**Top 3 cost drivers:**
1. [service] — $X/month — [why it's expensive]
2. [service] — $X/month — [why it's expensive]
3. [service] — $X/month — [why it's expensive]

**Total rough estimate:** Dev ~$X/month | Prod ~$X/month

**30% reduction option:** [what to change] — Trade-off: [what you give up]

**Key insight:** [one lesson about cost this design taught]
```

---

## Estimates

No estimates recorded yet. First estimate due in Week 4 (Data and Storage Architecture) workshop.

---

## Cost intuition benchmarks

Use these as sanity checks when estimating:

| Service | Typical dev cost | Typical prod cost | Main cost driver |
|---|---|---|---|
| App Service B1 | ~$13/month | — | Compute hours |
| App Service P1v3 | ~$138/month | ~$138–400/month | SKU × instances |
| Azure SQL (Basic) | ~$5/month | — | DTU tier |
| Azure SQL (S3 Standard) | ~$150/month | ~$150–600/month | DTU tier |
| Azure SQL Hyperscale | ~$370/month | $370–1500+/month | vCores |
| Cosmos DB (serverless) | ~$0–5/month (low traffic) | ~$50–500/month | RU consumption |
| Storage (LRS, 1TB) | ~$20/month | — | GB stored |
| Storage (GRS, 1TB) | ~$40/month | — | Geo-replication |
| Log Analytics (10GB/day) | ~$230/month | — | GB ingested |
| Application Insights | ~$0–50/month | ~$50–300/month | Data ingested |
| Azure OpenAI (GPT-4o) | Varies | ~$500–5000+/month | Token volume |
| Container Apps (low traffic) | ~$0–20/month | ~$50–300/month | vCPU + memory seconds |
| AKS (2 nodes B2s) | ~$70/month | ~$300–1000+/month | Node pool VMs |
| Azure Firewall | ~$900/month | ~$900+/month | Fixed + data processed |
| Front Door Standard | ~$35/month | ~$35–200/month | Rules + requests |
| API Management (Developer) | ~$50/month | — | Not for prod |
| API Management (Standard) | ~$700/month | ~$700+/month | Units |
