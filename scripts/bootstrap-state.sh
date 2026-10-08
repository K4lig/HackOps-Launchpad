#!/usr/bin/env bash
set -euo pipefail

LOCATION="eastus2"
RG="rg-hackops-tfstate"
SA="sthackopstf$RANDOM"

az group create -n "$RG" -l "$LOCATION"
az storage account create -n "$SA" -g "$RG" -l "$LOCATION" \
  --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false
az storage account blob-service-properties update \
  --account-name "$SA" -g "$RG" --enable-versioning true

az role assignment create --role "Storage Blob Data Contributor" \
  --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --scope "$(az storage account show -n "$SA" -g "$RG" --query id -o tsv)"

for ns in Microsoft.Network Microsoft.ContainerRegistry Microsoft.KeyVault \
          Microsoft.OperationalInsights Microsoft.Consumption \
          Microsoft.ContainerService Microsoft.Storage; do
  az provider register --namespace "$ns"
done

echo "Espera 1-2 minutos a que el rol se propague y luego ejecuta:"
echo "az storage container create --name tfstate --account-name $SA --auth-mode login"
echo "Storage account: $SA"
