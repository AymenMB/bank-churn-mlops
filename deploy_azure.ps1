# Bank Churn MLOps - Azure Deployment Script
# Simplified version without encoding issues

# Variables
$RESOURCE_GROUP = "rg-mlops-bank-churn"
$LOCATION = "westeurope"
$FALLBACK_LOCATION = "northeurope"
$USERNAME = $env:USERNAME.ToLower() -replace '[^a-z0-9]', ''
$ACR_NAME = "mlops$USERNAME"
$CONTAINER_APP_NAME = "bank-churn"
$CONTAINERAPPS_ENV = "env-mlops-workshop"
$IMAGE_NAME = "churn-api"
$IMAGE_TAG = "v1"
$TARGET_PORT = 8000

Write-Host "[AZURE DEPLOYMENT - STEP 1] Checking Azure Connection..." -ForegroundColor Cyan
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "[ERROR] Not logged in to Azure. Run: az login" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Connected to Azure: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI not available." -ForegroundColor Red
    exit 1
}

Write-Host "`n[AZURE DEPLOYMENT - STEP 2] Checking Docker..." -ForegroundColor Cyan
try {
    docker ps >$null 2>&1
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker is not accessible. Start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Validate ACR name
if ($ACR_NAME.Length -lt 5 -or $ACR_NAME.Length -gt 50) {
    Write-Host "[ERROR] Invalid ACR name: $ACR_NAME (must be 5-50 characters)" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] ACR name validated: $ACR_NAME ($($ACR_NAME.Length) characters)" -ForegroundColor Green

Write-Host "`n[STEP 3] Installing Azure CLI extensions..." -ForegroundColor Cyan
$hasExtension = az extension list --query "[?name=='containerapp'].name" -o tsv 2>$null
if (-not $hasExtension) {
    Write-Host "Installing containerapp extension..." -ForegroundColor Yellow
    az extension add --name containerapp --upgrade -y --only-show-errors 2>$null
    Write-Host "[OK] Extension containerapp installed" -ForegroundColor Green
} else {
    Write-Host "[OK] Extension containerapp already installed" -ForegroundColor Green
    az extension update --name containerapp -y --only-show-errors 2>$null
}

Write-Host "`n[STEP 4] Registering Azure providers (2-3 minutes)..." -ForegroundColor Cyan
az provider register --namespace Microsoft.ContainerRegistry --wait
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.Web --wait
az provider register --namespace Microsoft.OperationalInsights --wait
Write-Host "[OK] Providers registered" -ForegroundColor Green

Write-Host "`n[STEP 5] Creating Resource Group..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION --output none 2>$null
Write-Host "[OK] Resource Group: $RESOURCE_GROUP (region: $LOCATION)" -ForegroundColor Green

Write-Host "`n[STEP 6] Creating Container Registry (ACR)..." -ForegroundColor Cyan
$acrExists = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP 2>$null
if (-not $acrExists) {
    Write-Host "Creating ACR in $LOCATION..." -ForegroundColor Yellow
    $acrResult = az acr create `
        --resource-group $RESOURCE_GROUP `
        --name $ACR_NAME `
        --sku Basic `
        --admin-enabled true `
        --location $LOCATION 2>$null
    
    if (-not $acrResult) {
        Write-Host "[WARNING] Failed in $LOCATION, trying $FALLBACK_LOCATION..." -ForegroundColor Yellow
        $LOCATION = $FALLBACK_LOCATION
        az acr create `
            --resource-group $RESOURCE_GROUP `
            --name $ACR_NAME `
            --sku Basic `
            --admin-enabled true `
            --location $LOCATION --output none
    }
    Start-Sleep -Seconds 5
    Write-Host "[OK] ACR created: $ACR_NAME (region: $LOCATION)" -ForegroundColor Green
} else {
    Write-Host "[OK] ACR already exists: $ACR_NAME" -ForegroundColor Green
}

Write-Host "`n[STEP 7] Login to ACR and Push image..." -ForegroundColor Cyan
Write-Host "Logging in to registry..." -ForegroundColor Yellow
az acr login --name $ACR_NAME --output none

$ACR_LOGIN_SERVER = (az acr show --name $ACR_NAME --query loginServer -o tsv).Trim()
$ACR_USER = (az acr credential show --name $ACR_NAME --query username -o tsv).Trim()
$ACR_PASS = (az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv).Trim()
$IMAGE = "$ACR_LOGIN_SERVER/${IMAGE_NAME}:${IMAGE_TAG}"

Write-Host "ACR Login Server: $ACR_LOGIN_SERVER" -ForegroundColor Yellow
Write-Host "Tag and push image..." -ForegroundColor Yellow

# Check if local image exists, if not build it
$localImage = docker images -q "${IMAGE_NAME}:${IMAGE_TAG}"
if (-not $localImage) {
    Write-Host "Local image not found, building..." -ForegroundColor Yellow
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . | Out-Null
}

docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}" | Out-Null
docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest" | Out-Null
Write-Host "[OK] Images pushed to ACR" -ForegroundColor Green

Write-Host "`n[STEP 8] Creating Log Analytics Workspace..." -ForegroundColor Cyan
$LAW_NAME = "law-mlops-$USERNAME-$(Get-Random -Maximum 99999)"
Write-Host "Creating: $LAW_NAME" -ForegroundColor Yellow

az monitor log-analytics workspace create `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LAW_NAME `
    --location $LOCATION --output none

Start-Sleep -Seconds 10

$LAW_ID = (az monitor log-analytics workspace show `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LAW_NAME `
    --query customerId -o tsv).Trim()

$LAW_KEY = (az monitor log-analytics workspace get-shared-keys `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LAW_NAME `
    --query primarySharedKey -o tsv).Trim()

Write-Host "[OK] Log Analytics created" -ForegroundColor Green

Write-Host "`n[STEP 9] Creating Container Apps Environment (2-3 minutes)..." -ForegroundColor Cyan
$envExists = az containerapp env show `
    --name $CONTAINERAPPS_ENV `
    --resource-group $RESOURCE_GROUP 2>$null

if (-not $envExists) {
    Write-Host "Creating environment..." -ForegroundColor Yellow
    az containerapp env create `
        --name $CONTAINERAPPS_ENV `
        --resource-group $RESOURCE_GROUP `
        --location $LOCATION `
        --logs-workspace-id $LAW_ID `
        --logs-workspace-key $LAW_KEY --output none
    Write-Host "[OK] Environment created: $CONTAINERAPPS_ENV" -ForegroundColor Green
} else {
    Write-Host "[OK] Environment already exists: $CONTAINERAPPS_ENV" -ForegroundColor Green
}

Write-Host "`n[STEP 10] Deploying Container App (2-3 minutes)..." -ForegroundColor Cyan
$appExists = az containerapp show `
    --name $CONTAINER_APP_NAME `
    --resource-group $RESOURCE_GROUP 2>$null

if ($appExists) {
    Write-Host "Updating application..." -ForegroundColor Yellow
    az containerapp update `
        --name $CONTAINER_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --image $IMAGE `
        --registry-server $ACR_LOGIN_SERVER `
        --registry-username $ACR_USER `
        --registry-password $ACR_PASS --output none
} else {
    Write-Host "Creating application..." -ForegroundColor Yellow
    az containerapp create `
        --name $CONTAINER_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --environment $CONTAINERAPPS_ENV `
        --image $IMAGE `
        --ingress external `
        --target-port $TARGET_PORT `
        --registry-server $ACR_LOGIN_SERVER `
        --registry-username $ACR_USER `
        --registry-password $ACR_PASS `
        --min-replicas 1 `
        --max-replicas 1 --output none
}
Write-Host "[OK] Container App deployed: $CONTAINER_APP_NAME" -ForegroundColor Green

Write-Host "`n[STEP 11] Getting URL..." -ForegroundColor Cyan
$APP_URL = (az containerapp show `
    --name $CONTAINER_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query properties.configuration.ingress.fqdn -o tsv).Trim()

Write-Host "`n" -NoNewline
Write-Host "============================================================" -ForegroundColor Green
Write-Host "[SUCCESS] DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Resources created:" -ForegroundColor Cyan
Write-Host "  Resource Group : $RESOURCE_GROUP" -ForegroundColor White
Write-Host "  ACR            : $ACR_NAME" -ForegroundColor White
Write-Host "  Region         : $LOCATION" -ForegroundColor White
Write-Host "  Container App  : $CONTAINER_APP_NAME" -ForegroundColor White
Write-Host ""
Write-Host "Application URLs:" -ForegroundColor Cyan
Write-Host "  API            : https://$APP_URL" -ForegroundColor Yellow
Write-Host "  Health Check   : https://$APP_URL/health" -ForegroundColor Yellow
Write-Host "  Documentation  : https://$APP_URL/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "Quick Test:" -ForegroundColor Cyan
Write-Host "  Invoke-RestMethod -Uri 'https://$APP_URL/health'" -ForegroundColor White
Write-Host ""
Write-Host "To delete all resources:" -ForegroundColor Cyan
Write-Host "  az group delete --name $RESOURCE_GROUP --yes --no-wait" -ForegroundColor White
Write-Host ""
Write-Host "Estimated cost: 3-6 EUR/month" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green

# Save URL for tests
$APP_URL | Out-File -FilePath "azure_url.txt" -Encoding utf8
Write-Host "[OK] URL saved to azure_url.txt" -ForegroundColor Green
