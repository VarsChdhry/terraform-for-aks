# terraform-for-aks
# Step for creating AKS cluster via Terraform

Login to Azure
```#login and set tenant id as env variable
az login 
TENTANT_ID=<your-tenant-id>

# view and select your subscription account

az account list -o table
SUBSCRIPTION=<id>
az account set --subscription $SUBSCRIPTION
```

As kubernetes need SP fo managing cluster, create it one 
```

SERVICE_PRINCIPAL_JSON=$(az ad sp create-for-rbac --skip-assignment --name aks-getting-started-sp -o json)

# Keep the `appId` and `password` for later use!

SERVICE_PRINCIPAL=$(echo $SERVICE_PRINCIPAL_JSON | jq -r '.appId')
SERVICE_PRINCIPAL_SECRET=$(echo $SERVICE_PRINCIPAL_JSON | jq -r '.password')

#note: reset the credential if you have any sinlge or double quote on password
az ad sp credential reset --name "aks-getting-started-sp"

# Grant contributor role over the subscription to our service principal

az role assignment create --assignee $SERVICE_PRINCIPAL \
--scope "/subscriptions/$SUBSCRIPTION" \
--role Contributor
```

terraform steps to deploy infra in Azure and passing required ENV vars with it
```
terraform init

terraform plan -var serviceprinciple_id=$SERVICE_PRINCIPAL \
    -var serviceprinciple_key="$SERVICE_PRINCIPAL_SECRET" \
    -var tenant_id=$TENTANT_ID \
    -var subscription_id=$SUBSCRIPTION \
    -var ssh_key="$SSH_KEY"

terraform apply -var serviceprinciple_id=$SERVICE_PRINCIPAL \
    -var serviceprinciple_key="$SERVICE_PRINCIPAL_SECRET" \
    -var tenant_id=$TENTANT_ID \
    -var subscription_id=$SUBSCRIPTION \
    -var ssh_key="$SSH_KEY"
```