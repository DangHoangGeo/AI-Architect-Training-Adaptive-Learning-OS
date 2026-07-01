# Deployment Notes

Example:

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters main.dev.bicepparam
```

Review cost and region settings before deploying.
