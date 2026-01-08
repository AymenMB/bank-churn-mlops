# Module 4 : Deploiement sur Azure Container Apps
# Workshop MLOps - PowerShell Version (Equivalent du script Bash)
# ================================================================

param(
    [switch]$SkipProviders,
    [switch]$SkipBuild
)

# Arreter en cas d'erreur
$ErrorActionPreference = "Stop"

#################################
# VARIABLES DEFINITIVES
#################################
$RESOURCE_GROUP = "rg-mlops-bank-churn"
$LOCATION = "westeurope"           # Force West Europe (garanti)
$FALLBACK_LOCATION = "northeurope" # Fallback garanti
$USERNAME = $env:USERNAME.ToLower() -replace '[^a-z0-9]', ''
$ACR_NAME = "mlops$USERNAME"
$CONTAINER_APP_NAME = "bank-churn"
$CONTAINERAPPS_ENV = "env-mlops-workshop"
$IMAGE_NAME = "churn-api"
$IMAGE_TAG = "v1"
$TARGET_PORT = 8000

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODULE 4: Deploiement Azure Container Apps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

#################################
# 0) Contexte Azure + Verification Extensions
#################################
Write-Host "[ETAPE 0] Verification du contexte Azure..." -ForegroundColor Yellow
try {
    $account = az account show --query "{name:name, cloudName:cloudName}" -o json 2>$null | ConvertFrom-Json
    if (-not $account) {
        Write-Host "[ERREUR] Non connecte a Azure. Executez: az login" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Connecte a: $($account.name)" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Azure CLI non disponible ou non connecte" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[ETAPE 0.1] Verification/installation des extensions Azure CLI..." -ForegroundColor Yellow

# Verifier et installer containerapp si necessaire
$hasExtension = az extension show --name containerapp 2>$null
if (-not $hasExtension) {
    Write-Host "[INFO] Installation de l'extension containerapp..." -ForegroundColor Yellow
    az extension add --name containerapp --upgrade -y --only-show-errors
    Write-Host "[OK] Extension containerapp installee" -ForegroundColor Green
} else {
    Write-Host "[OK] Extension containerapp deja installee" -ForegroundColor Green
    az extension update --name containerapp -y --only-show-errors 2>$null
}

# Liste des extensions installees
Write-Host ""
Write-Host "Extensions installees :" -ForegroundColor Cyan
az extension list --query "[].{Name:name, Version:version}" -o table

#################################
# 1) Providers necessaires
#################################
if (-not $SkipProviders) {
    Write-Host ""
    Write-Host "[ETAPE 1] Enregistrement des providers (peut prendre 2-3 min)..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.ContainerRegistry --wait
    az provider register --namespace Microsoft.App --wait
    az provider register --namespace Microsoft.Web --wait
    az provider register --namespace Microsoft.OperationalInsights --wait
    Write-Host "[OK] Providers enregistres" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Providers deja enregistres" -ForegroundColor Yellow
}

#################################
# 2) Resource Group
#################################
Write-Host ""
Write-Host "[ETAPE 2] Creation/validation du groupe de ressources..." -ForegroundColor Yellow
az group create -n $RESOURCE_GROUP -l $LOCATION --output none 2>$null
Write-Host "[OK] Resource Group: $RESOURCE_GROUP (region: $LOCATION)" -ForegroundColor Green

#################################
# 3) Creation ACR (avec verification)
#################################
Write-Host ""
Write-Host "[ETAPE 3] Creation du Container Registry (ACR) en $LOCATION..." -ForegroundColor Yellow

# Verification prealable du nom ACR
if ($ACR_NAME.Length -lt 5 -or $ACR_NAME.Length -gt 50) {
    Write-Host "[ERREUR] Nom ACR invalide: $ACR_NAME" -ForegroundColor Red
    Write-Host "   Doit contenir 5-50 caracteres alphanumeriques en minuscules" -ForegroundColor Red
    exit 1
}

if ($ACR_NAME -notmatch '^[a-z0-9]{5,50}$') {
    Write-Host "[ERREUR] Nom ACR invalide: $ACR_NAME" -ForegroundColor Red
    Write-Host "   Doit contenir uniquement des lettres minuscules et chiffres" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Nom ACR valide: $ACR_NAME ($($ACR_NAME.Length) caracteres)" -ForegroundColor Green

# Tentative de creation ACR
$acrCreated = $false
try {
    az acr create `
        --resource-group $RESOURCE_GROUP `
        --name $ACR_NAME `
        --sku Basic `
        --admin-enabled true `
        --location $LOCATION --output none 2>$null
    $acrCreated = $true
} catch {
    $acrCreated = $false
}

if (-not $acrCreated) {
    # Verifier si ACR existe deja
    $existingAcr = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP 2>$null
    if ($existingAcr) {
        Write-Host "[OK] ACR existe deja: $ACR_NAME" -ForegroundColor Green
        $acrCreated = $true
    } else {
        Write-Host "[WARNING] ACR bloque en $LOCATION. Fallback => $FALLBACK_LOCATION" -ForegroundColor Yellow
        $LOCATION = $FALLBACK_LOCATION
        az acr create `
            --resource-group $RESOURCE_GROUP `
            --name $ACR_NAME `
            --sku Basic `
            --admin-enabled true `
            --location $LOCATION --output none
        $acrCreated = $true
    }
}

# Attendre la creation complete
Start-Sleep -Seconds 5
Write-Host "[OK] ACR cree: $ACR_NAME (region=$LOCATION)" -ForegroundColor Green

#################################
# 4) Login ACR + Push image
#################################
Write-Host ""
Write-Host "[ETAPE 4] Connexion au registry et push de l'image..." -ForegroundColor Yellow

Write-Host "Connexion au registry..." -ForegroundColor Cyan
az acr login --name $ACR_NAME --output none

# Recuperation des informations ACR (avec nettoyage des \r)
$ACR_LOGIN_SERVER = (az acr show --name $ACR_NAME --query loginServer -o tsv) -replace "`r", ""
Write-Host "ACR_LOGIN_SERVER = $ACR_LOGIN_SERVER" -ForegroundColor Cyan

# Recuperation des credentials
$ACR_USER = (az acr credential show -n $ACR_NAME --query username -o tsv) -replace "`r", ""
$ACR_PASS = (az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv) -replace "`r", ""
$IMAGE = "$ACR_LOGIN_SERVER/${IMAGE_NAME}:${IMAGE_TAG}"

if (-not $SkipBuild) {
    Write-Host "Build + Tag + Push..." -ForegroundColor Cyan
    
    # Build de l'image
    Write-Host "  -> docker build..." -ForegroundColor Gray
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
    
    # Tag pour ACR
    Write-Host "  -> docker tag..." -ForegroundColor Gray
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
    
    # Push vers ACR
    Write-Host "  -> docker push (peut prendre quelques minutes)..." -ForegroundColor Gray
    docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
    docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
    
    Write-Host "[OK] Image pushee dans ACR" -ForegroundColor Green
} else {
    Write-Host "[SKIP] Build/Push - utilisation de l'image existante" -ForegroundColor Yellow
}

#################################
# 5) Log Analytics
#################################
Write-Host ""
Write-Host "[ETAPE 5] Creation Log Analytics Workspace..." -ForegroundColor Yellow

$LAW_NAME = "law-mlops-$USERNAME-$(Get-Random -Maximum 99999)"
Write-Host "Creation: $LAW_NAME" -ForegroundColor Cyan

az monitor log-analytics workspace create `
    -g $RESOURCE_GROUP `
    -n $LAW_NAME `
    -l $LOCATION --output none

# Attente necessaire
Write-Host "Attente de la creation..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Recuperation des informations (avec nettoyage des \r)
$LAW_ID = (az monitor log-analytics workspace show `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LAW_NAME `
    --query customerId -o tsv) -replace "`r", ""

$LAW_KEY = (az monitor log-analytics workspace get-shared-keys `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LAW_NAME `
    --query primarySharedKey -o tsv) -replace "`r", ""

Write-Host "[OK] Log Analytics OK" -ForegroundColor Green

#################################
# 6) Container Apps Environment
#################################
Write-Host ""
Write-Host "[ETAPE 6] Creation/validation Container Apps Environment: $CONTAINERAPPS_ENV" -ForegroundColor Yellow

$envExists = az containerapp env show -n $CONTAINERAPPS_ENV -g $RESOURCE_GROUP 2>$null
if (-not $envExists) {
    Write-Host "Creation de l'environnement (2-3 minutes)..." -ForegroundColor Cyan
    az containerapp env create `
        -n $CONTAINERAPPS_ENV `
        -g $RESOURCE_GROUP `
        -l $LOCATION `
        --logs-workspace-id $LAW_ID `
        --logs-workspace-key $LAW_KEY --output none
    Write-Host "[OK] Environment cree" -ForegroundColor Green
} else {
    Write-Host "[OK] Environment existe deja" -ForegroundColor Green
}

#################################
# 7) Deploiement Container App
#################################
Write-Host ""
Write-Host "[ETAPE 7] Deploiement Container App: $CONTAINER_APP_NAME" -ForegroundColor Yellow

$appExists = az containerapp show -n $CONTAINER_APP_NAME -g $RESOURCE_GROUP 2>$null
if ($appExists) {
    Write-Host "Mise a jour de l'application..." -ForegroundColor Cyan
    az containerapp update `
        -n $CONTAINER_APP_NAME `
        -g $RESOURCE_GROUP `
        --image $IMAGE `
        --set-env-vars "PYTHONUNBUFFERED=1" `
        --registry-server $ACR_LOGIN_SERVER `
        --registry-username $ACR_USER `
        --registry-password $ACR_PASS --output none
} else {
    Write-Host "Creation de l'application (2-3 minutes)..." -ForegroundColor Cyan
    az containerapp create `
        -n $CONTAINER_APP_NAME `
        -g $RESOURCE_GROUP `
        --environment $CONTAINERAPPS_ENV `
        --image $IMAGE `
        --ingress external `
        --target-port $TARGET_PORT `
        --set-env-vars "PYTHONUNBUFFERED=1" `
        --registry-server $ACR_LOGIN_SERVER `
        --registry-username $ACR_USER `
        --registry-password $ACR_PASS `
        --min-replicas 1 `
        --max-replicas 1 --output none
}
Write-Host "[OK] Container App deploye" -ForegroundColor Green

#################################
# 8) URL API
#################################
Write-Host ""
Write-Host "[ETAPE 8] Recuperation de l'URL..." -ForegroundColor Yellow

# Attente avant test
Write-Host "Attente de 30 secondes pour stabilisation..." -ForegroundColor Gray
Start-Sleep -Seconds 30

$APP_URL = (az containerapp show `
    -n $CONTAINER_APP_NAME `
    -g $RESOURCE_GROUP `
    --query properties.configuration.ingress.fqdn -o tsv) -replace "`r", ""

# Sauvegarder l'URL
$APP_URL | Out-File -FilePath "azure_url.txt" -Encoding utf8 -NoNewline

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "[SUCCESS] DEPLOIEMENT REUSSI" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Ressources creees:" -ForegroundColor Cyan
Write-Host "  ACR           : $ACR_NAME" -ForegroundColor White
Write-Host "  Region        : $LOCATION" -ForegroundColor White
Write-Host "  Resource Group: $RESOURCE_GROUP" -ForegroundColor White
Write-Host ""
Write-Host "URLs de l'application :" -ForegroundColor Cyan
Write-Host "  API    : https://$APP_URL" -ForegroundColor Yellow
Write-Host "  Health : https://$APP_URL/health" -ForegroundColor Yellow
Write-Host "  Docs   : https://$APP_URL/docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour tester l'API :" -ForegroundColor Cyan
Write-Host "  .\test_azure_api_workshop.ps1" -ForegroundColor White
Write-Host ""
Write-Host "Pour supprimer toutes les ressources :" -ForegroundColor Cyan
Write-Host "  az group delete --name $RESOURCE_GROUP --yes --no-wait" -ForegroundColor White
Write-Host "==========================================" -ForegroundColor Green
