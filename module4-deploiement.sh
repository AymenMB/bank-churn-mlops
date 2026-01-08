#!/usr/bin/env bash
set -euo pipefail

#################################
# VARIABLES DEFINITIVES
#################################
RESOURCE_GROUP="rg-mlops-bank-churn"  
LOCATION="westeurope"
FALLBACK_LOCATION="northeurope"
ACR_NAME="mlops$(whoami | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')"
CONTAINER_APP_NAME="bank-churn" 
CONTAINERAPPS_ENV="env-mlops-workshop"
IMAGE_NAME="churn-api"
IMAGE_TAG="v1"
TARGET_PORT=8000

echo "=========================================="
echo "MODULE 4: Deploiement Azure Container Apps"
echo "=========================================="

#################################
# 0) Contexte Azure + Verification Extensions
#################################
echo ""
echo "[ETAPE 0] Verification du contexte Azure..."
az account show --query "{name:name, cloudName:cloudName}" -o json >/dev/null
echo "OK - Connecte a Azure"

echo "[ETAPE 0.1] Verification/installation extension containerapp..."
if ! az extension show --name containerapp >/dev/null 2>&1; then
    echo "Installation de l'extension containerapp..."
    az extension add --name containerapp --upgrade -y --only-show-errors
    echo "Extension containerapp installee"
else
    echo "Extension containerapp deja installee"
    az extension update --name containerapp -y --only-show-errors 2>/dev/null || true
fi

#################################
# 1) Providers necessaires
#################################
echo ""
echo "[ETAPE 1] Register providers (cela peut prendre quelques minutes)..."
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
echo "Providers enregistres"

#################################
# 2) Resource Group
#################################
echo ""
echo "[ETAPE 2] Creation/validation du groupe de ressources..."
az group create -n "$RESOURCE_GROUP" -l "$LOCATION" >/dev/null || true
echo "RG OK: $RESOURCE_GROUP"

#################################
# 3) Creation ACR (avec verification)
#################################
echo ""
echo "[ETAPE 3] Creation du Container Registry (ACR) en $LOCATION..."

# Verification prealable du nom
if [[ ! "$ACR_NAME" =~ ^[a-z0-9]{5,50}$ ]]; then
    echo "ERREUR: Nom ACR invalide: $ACR_NAME"
    echo "   Doit contenir 5-50 caracteres alphanumeriques en minuscules"
    exit 1
fi

echo "Nom ACR valide: $ACR_NAME (${#ACR_NAME} caracteres)"

set +e
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --location "$LOCATION" >/dev/null 2>&1
ACR_RC=$?
set -e

if [ $ACR_RC -ne 0 ]; then
  echo "ACR bloque en $LOCATION. Fallback => $FALLBACK_LOCATION"
  LOCATION="$FALLBACK_LOCATION"
  az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACR_NAME" \
    --sku Basic \
    --admin-enabled true \
    --location "$LOCATION" >/dev/null
fi

sleep 5
echo "ACR cree : $ACR_NAME (region=$LOCATION)"

#################################
# 4) Login ACR + Push image
#################################
echo ""
echo "[ETAPE 4] Connexion au registry et push de l'image..."
az acr login --name "$ACR_NAME" >/dev/null

ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv | tr -d '\r')
echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"

# Recuperation des credentials
ACR_USER=$(az acr credential show -n "$ACR_NAME" --query username -o tsv | tr -d '\r')
ACR_PASS=$(az acr credential show -n "$ACR_NAME" --query "passwords[0].value" -o tsv | tr -d '\r')
IMAGE="$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"

echo "Build + Tag + Push..."

# Verifier si l'image locale existe, sinon utiliser bank-churn-api
LOCAL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"
if ! docker images -q "$LOCAL_IMAGE" | grep -q .; then
    echo "Image $LOCAL_IMAGE non trouvee, utilisation de bank-churn-api:v1"
    LOCAL_IMAGE="bank-churn-api:v1"
fi

docker tag "$LOCAL_IMAGE" "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
docker tag "$LOCAL_IMAGE" "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
docker push "$ACR_LOGIN_SERVER/$IMAGE_NAME:latest"
echo "Image pushee dans ACR"

#################################
# 5) Log Analytics
#################################
echo ""
echo "[ETAPE 5] Creation Log Analytics Workspace..."
LAW_NAME="law-mlops-$(whoami)-$RANDOM"
echo "Creation: $LAW_NAME"
az monitor log-analytics workspace create -g "$RESOURCE_GROUP" -n "$LAW_NAME" -l "$LOCATION" >/dev/null

echo "Attente de 10 secondes..."
sleep 10

LAW_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LAW_NAME" \
    --query customerId -o tsv | tr -d '\r')

LAW_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LAW_NAME" \
    --query primarySharedKey -o tsv | tr -d '\r')
echo "Log Analytics OK"

#################################
# 6) Container Apps Environment
#################################
echo ""
echo "[ETAPE 6] Creation Container Apps Environment: $CONTAINERAPPS_ENV"
if ! az containerapp env show -n "$CONTAINERAPPS_ENV" -g "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Creation de l'environnement (2-3 minutes)..."
  az containerapp env create \
    -n "$CONTAINERAPPS_ENV" \
    -g "$RESOURCE_GROUP" \
    -l "$LOCATION" \
    --logs-workspace-id "$LAW_ID" \
    --logs-workspace-key "$LAW_KEY" >/dev/null
fi
echo "Environment OK"

#################################
# 7) Deploiement Container App
#################################
echo ""
echo "[ETAPE 7] Deploiement Container App: $CONTAINER_APP_NAME"
if az containerapp show -n "$CONTAINER_APP_NAME" -g "$RESOURCE_GROUP" >/dev/null 2>&1; then
  echo "Mise a jour de l'application..."
  az containerapp update \
    -n "$CONTAINER_APP_NAME" \
    -g "$RESOURCE_GROUP" \
    --image "$IMAGE" \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-username "$ACR_USER" \
    --registry-password "$ACR_PASS" >/dev/null
else
  echo "Creation de l'application (2-3 minutes)..."
  az containerapp create \
    -n "$CONTAINER_APP_NAME" \
    -g "$RESOURCE_GROUP" \
    --environment "$CONTAINERAPPS_ENV" \
    --image "$IMAGE" \
    --ingress external \
    --target-port "$TARGET_PORT" \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-username "$ACR_USER" \
    --registry-password "$ACR_PASS" \
    --min-replicas 1 \
    --max-replicas 1 >/dev/null
fi
echo "Container App OK"

#################################
# 8) URL API
#################################
echo ""
echo "[ETAPE 8] Recuperation de l'URL..."
sleep 30
APP_URL=$(az containerapp show -n "$CONTAINER_APP_NAME" -g "$RESOURCE_GROUP" --query properties.configuration.ingress.fqdn -o tsv | tr -d '\r')

# Sauvegarder l'URL
echo "$APP_URL" > azure_url.txt

echo ""
echo "=========================================="
echo "DEPLOIEMENT REUSSI"
echo "=========================================="
echo "ACR      : $ACR_NAME"
echo "Region   : $LOCATION"
echo "Resource Group: $RESOURCE_GROUP"
echo ""
echo "URLs de l'application :"
echo "  API      : https://$APP_URL"
echo "  Health   : https://$APP_URL/health"
echo "  Docs     : https://$APP_URL/docs"
echo ""
echo "Pour supprimer toutes les ressources :"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo "=========================================="
