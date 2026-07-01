# Skill: Multi-Cloud Comparator

## Mission
Ensure the learner understands Azure design choices relative to AWS and GCP so they can defend decisions in any context: interviews, RFPs, architecture review boards, and cross-cloud migrations.

## Mindset
- Cloud-literate architects choose platforms deliberately, not by default.
- Azure, AWS, and GCP solve the same problems differently — the differences reveal the trade-offs.
- Vendor lock-in is a real cost. It must be named, not ignored.
- "We chose Azure because we already use Microsoft products" is a valid business reason but not an architecture reason.

## When to activate
Invoke during or after design exercises in:
- Week 2 (Networking): VNet vs VPC, NSG vs Security Groups, Azure Firewall vs AWS Network Firewall
- Week 3 (Identity): Entra ID vs IAM + Cognito, Managed Identity vs IAM Roles, Key Vault vs AWS Secrets Manager / GCP Secret Manager
- Week 7 (Security): Azure Defender vs AWS GuardDuty / Security Hub, Private Link vs AWS PrivateLink
- Week 9 (AI Systems): Azure OpenAI vs Amazon Bedrock vs Vertex AI, AI Search vs OpenSearch / Vertex Search
- Week 12 (Capstone): Full cross-cloud comparison of the final design

## Comparison framework

For each major service or pattern, answer:

1. **AWS equivalent** — name the service and its key difference in behavior or pricing model.
2. **GCP equivalent** — name the service and any meaningful distinction.
3. **What you gain on Azure** — specific technical or operational advantage.
4. **What you lose on Azure** — specific limitation or missing feature compared to the alternative.
5. **Lock-in surface** — which parts of this design would be hardest to migrate away from?
6. **Honest verdict** — is this Azure choice genuinely best for the requirement, or is it preference/familiarity?

## High-value comparisons to know deeply

| Azure | AWS | GCP | Key difference |
|---|---|---|---|
| Azure Virtual Network | VPC | VPC | Azure VNets are regional; AWS VPCs are regional but span AZs differently |
| NSG | Security Groups + NACLs | Firewall Rules | Azure NSGs apply to NIC or subnet; AWS has both instance and subnet-level |
| Azure Firewall | AWS Network Firewall | Cloud NGFW | Azure Firewall is PaaS; AWS NF is more policy-flexible |
| Azure Front Door | AWS CloudFront + ALB | Cloud CDN + Load Balancer | Azure FD is WAF + CDN + global LB in one; AWS splits these |
| Microsoft Entra ID | IAM + Cognito + SSO | Cloud Identity + IAP | Entra does identity + SSO + governance; AWS requires assembling 3 services |
| Managed Identity | IAM Roles for EC2/Lambda | Workload Identity | All three are secretless; implementation details differ |
| Azure Key Vault | AWS Secrets Manager | GCP Secret Manager | Key Vault combines key management + secrets; AWS Secrets Manager focuses on secrets only |
| Azure SQL | Amazon RDS / Aurora | Cloud SQL / AlloyDB | Aurora Serverless has better cold-start story; Azure SQL Hyperscale is strong for large DBs |
| Cosmos DB | DynamoDB | Firestore / Bigtable | Cosmos offers 5 consistency levels; DynamoDB has 2; Cosmos is multi-model |
| Azure Monitor | CloudWatch | Cloud Monitoring | AWS CloudWatch has broader ecosystem integrations; Azure Monitor has tighter Bicep integration |
| Azure OpenAI | Amazon Bedrock | Vertex AI | Azure OpenAI gives GPT-4 access with Azure SLA; Bedrock is multi-model but not GPT-4 |
| Azure Bicep | CloudFormation / CDK | Deployment Manager / Terraform | Bicep is Azure-only; Terraform is cross-cloud and widely adopted |
| AKS | EKS | GKE | GKE is widely considered most mature; EKS has deepest AWS integrations; AKS improving |

## Review output format
Use: **Azure choice → AWS equivalent → GCP equivalent → Lock-in risk → Honest verdict**

## Questions to always ask
- If this customer's workload moved to AWS tomorrow, what would break first?
- Which service in this design has no equivalent on other clouds?
- Is the Azure advantage here technical, contractual, or organizational?
- What would you architect differently if vendor lock-in was explicitly prohibited?
