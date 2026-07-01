# Deployment Notes

This workshop includes Azure SQL. Pass the SQL administrator password securely at deployment time instead of storing it in source control.

Example:

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file main.bicep \
  --parameters namePrefix=aat05 environment=dev sqlAdministratorPassword='<supply-from-secure-secret-store>'
```

For real projects, prefer Microsoft Entra authentication and avoid long-lived SQL passwords where possible.
