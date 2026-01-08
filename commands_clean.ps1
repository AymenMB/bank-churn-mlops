# Bank Churn MLOps - PowerShell Commands
# Raccourcis pour les commandes frquentes

# ============================================================
# ENVIRONMENT SETUP
# ============================================================

function Setup-Environment {
    Write-Host " Setting up environment..." -ForegroundColor Cyan
    python -m venv venv
    .\venv\Scripts\Activate.ps1
    pip install --upgrade pip
    pip install -r requirements.txt
    Write-Host " Environment ready!" -ForegroundColor Green
}

# ============================================================
# DATA & TRAINING
# ============================================================

function Generate-Data {
    Write-Host " Generating dataset..." -ForegroundColor Cyan
    python generate_data.py
}

function Train-Model {
    Write-Host " Training model..." -ForegroundColor Cyan
    python train_model.py
}

function Start-MLflow {
    Write-Host " Starting MLflow UI..." -ForegroundColor Cyan
    mlflow ui --port 5000
}

# ============================================================
# API OPERATIONS
# ============================================================

function Start-API {
    Write-Host " Starting FastAPI..." -ForegroundColor Cyan
    uvicorn app.main:app --reload --port 8000
}

function Test-API {
    Write-Host " Testing API..." -ForegroundColor Cyan
    python test_api_local.py
}

function Open-APIDocs {
    Start-Process "http://localhost:8000/docs"
}

# ============================================================
# DOCKER OPERATIONS
# ============================================================

function Build-DockerImage {
    Write-Host " Building Docker image..." -ForegroundColor Cyan
    docker build -t bank-churn-api:v1 .
}

function Start-Container {
    Write-Host " Starting container..." -ForegroundColor Cyan
    docker run -d -p 8080:8000 --name churn-api bank-churn-api:v1
    Start-Sleep -Seconds 3
    docker logs churn-api
}

function Stop-Container {
    Write-Host " Stopping container..." -ForegroundColor Cyan
    docker stop churn-api
    docker rm churn-api
}

function Show-DockerLogs {
    docker logs churn-api -f
}

function Test-DockerAPI {
    Write-Host " Testing Docker API..." -ForegroundColor Cyan
    curl http://localhost:8080/health
    Start-Process "http://localhost:8080/docs"
}

# ============================================================
# CLEANUP
# ============================================================

function Clean-All {
    Write-Host " Nettoyage complet..." -ForegroundColor Yellow
    
    # Stop containers
    docker stop churn-api 2>$null
    docker rm churn-api 2>$null
    
    # Remove images
    docker rmi bank-churn-api:v1 2>$null
    
    # Remove Python cache
    Get-ChildItem -Recurse -Directory __pycache__ | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Recurse -File *.pyc | Remove-Item -Force -ErrorAction SilentlyContinue
    
    # Remove logs and generated files
    Remove-Item *.log -ErrorAction SilentlyContinue
    Remove-Item azure_url.txt -ErrorAction SilentlyContinue
    Remove-Item data/bank_customers.csv -ErrorAction SilentlyContinue
    Remove-Item model/churn_model.pkl -ErrorAction SilentlyContinue
    Remove-Item -Recurse mlruns -ErrorAction SilentlyContinue
    
    Write-Host " Nettoyage termin" -ForegroundColor Green
}

# ============================================================
# FULL WORKFLOW
# ============================================================

function Run-FullWorkflow {
    Write-Host " Running full workflow..." -ForegroundColor Cyan
    
    # Generate data
    Generate-Data
    
    # Train model
    Train-Model
    
    # Build Docker image
    Build-DockerImage
    
    # Start container
    Start-Container
    
    # Test
    Start-Sleep -Seconds 5
    Test-DockerAPI
    
    Write-Host " Full workflow complete!" -ForegroundColor Green
}

# ============================================================
# AZURE DEPLOYMENT (MODULES 4-7)
# ============================================================

function Deploy-ToAzure {
    Write-Host " Dploiement sur Azure Container Apps" -ForegroundColor Cyan
    Write-Host "=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
    
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
    
    # Vrification Azure CLI
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        if (-not $account) {
            Write-Host " Non connect  Azure. Excutez: az login" -ForegroundColor Red
            return
        }
        Write-Host " Connect  Azure: $($account.name)" -ForegroundColor Green
    } catch {
        Write-Host " Azure CLI non disponible. Installez-le d'abord." -ForegroundColor Red
        return
    }
    
    # Vrifier Docker
    try {
        docker ps >$null 2>&1
        Write-Host " Docker est en cours d'excution" -ForegroundColor Green
    } catch {
        Write-Host " Docker n'est pas accessible. Dmarrez Docker Desktop." -ForegroundColor Red
        return
    }
    
    # Validation nom ACR
    if ($ACR_NAME.Length -lt 5 -or $ACR_NAME.Length -gt 50) {
        Write-Host " Nom ACR invalide: $ACR_NAME (doit tre 5-50 caractres)" -ForegroundColor Red
        return
    }
    Write-Host " Nom ACR valid: $ACR_NAME ($($ACR_NAME.Length) caractres)" -ForegroundColor Green
    
    Write-Host "`n TAPE 1: Installation des extensions Azure CLI" -ForegroundColor Cyan
    # Vrifier et installer containerapp
    $hasExtension = az extension list --query "[?name=='containerapp'].name" -o tsv 2>$null
    if (-not $hasExtension) {
        Write-Host "Installation de l'extension containerapp..." -ForegroundColor Yellow
        az extension add --name containerapp --upgrade -y --only-show-errors 2>$null
        Write-Host " Extension containerapp installe" -ForegroundColor Green
    } else {
        Write-Host " Extension containerapp dj installe" -ForegroundColor Green
        az extension update --name containerapp -y --only-show-errors 2>$null
    }
    
    Write-Host "`n TAPE 2: Enregistrement des providers Azure" -ForegroundColor Cyan
    Write-Host "Cela peut prendre 2-3 minutes..." -ForegroundColor Yellow
    az provider register --namespace Microsoft.ContainerRegistry --wait
    az provider register --namespace Microsoft.App --wait
    az provider register --namespace Microsoft.Web --wait
    az provider register --namespace Microsoft.OperationalInsights --wait
    Write-Host " Providers enregistrs" -ForegroundColor Green
    
    Write-Host "`n TAPE 3: Cration du Resource Group" -ForegroundColor Cyan
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none 2>$null
    Write-Host " Resource Group: $RESOURCE_GROUP (rgion: $LOCATION)" -ForegroundColor Green
    
    Write-Host "`n TAPE 4: Cration du Container Registry (ACR)" -ForegroundColor Cyan
    $acrExists = az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP 2>$null
    if (-not $acrExists) {
        Write-Host "Cration de l'ACR en $LOCATION..." -ForegroundColor Yellow
        $acrResult = az acr create `
            --resource-group $RESOURCE_GROUP `
            --name $ACR_NAME `
            --sku Basic `
            --admin-enabled true `
            --location $LOCATION 2>$null
        
        if (-not $acrResult) {
            Write-Host " chec en $LOCATION, tentative en $FALLBACK_LOCATION..." -ForegroundColor Yellow
            $LOCATION = $FALLBACK_LOCATION
            az acr create `
                --resource-group $RESOURCE_GROUP `
                --name $ACR_NAME `
                --sku Basic `
                --admin-enabled true `
                --location $LOCATION --output none
        }
        Start-Sleep -Seconds 5
        Write-Host " ACR cr: $ACR_NAME (rgion: $LOCATION)" -ForegroundColor Green
    } else {
        Write-Host " ACR existe dj: $ACR_NAME" -ForegroundColor Green
    }
    
    Write-Host "`n TAPE 5: Login ACR et Push de l'image" -ForegroundColor Cyan
    Write-Host "Login au registry..." -ForegroundColor Yellow
    az acr login --name $ACR_NAME --output none
    
    $ACR_LOGIN_SERVER = (az acr show --name $ACR_NAME --query loginServer -o tsv).Trim()
    $ACR_USER = (az acr credential show --name $ACR_NAME --query username -o tsv).Trim()
    $ACR_PASS = (az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv).Trim()
    $IMAGE = "$ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
    
    Write-Host "ACR Login Server: $ACR_LOGIN_SERVER" -ForegroundColor Yellow
    Write-Host "Tag et push de l'image..." -ForegroundColor Yellow
    
    # Vrifier si l'image locale existe
    $localImage = docker images -q "${IMAGE_NAME}:${IMAGE_TAG}"
    if (-not $localImage) {
        Write-Host "Image locale non trouve, build en cours..." -ForegroundColor Yellow
        docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" . | Out-Null
    }
    
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest"
    docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}" | Out-Null
    docker push "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:latest" | Out-Null
    Write-Host " Images pushes dans ACR" -ForegroundColor Green
    
    Write-Host "`n TAPE 6: Cration du Log Analytics Workspace" -ForegroundColor Cyan
    $LAW_NAME = "law-mlops-$USERNAME-$(Get-Random -Maximum 99999)"
    Write-Host "Cration: $LAW_NAME" -ForegroundColor Yellow
    
    $lawExists = az monitor log-analytics workspace show `
        --resource-group $RESOURCE_GROUP `
        --workspace-name $LAW_NAME 2>$null
    
    if (-not $lawExists) {
        az monitor log-analytics workspace create `
            --resource-group $RESOURCE_GROUP `
            --workspace-name $LAW_NAME `
            --location $LOCATION --output none
        Start-Sleep -Seconds 10
    }
    
    $LAW_ID = (az monitor log-analytics workspace show `
        --resource-group $RESOURCE_GROUP `
        --workspace-name $LAW_NAME `
        --query customerId -o tsv).Trim()
    
    $LAW_KEY = (az monitor log-analytics workspace get-shared-keys `
        --resource-group $RESOURCE_GROUP `
        --workspace-name $LAW_NAME `
        --query primarySharedKey -o tsv).Trim()
    
    Write-Host " Log Analytics cr" -ForegroundColor Green
    
    Write-Host "`n TAPE 7: Cration du Container Apps Environment" -ForegroundColor Cyan
    $envExists = az containerapp env show `
        --name $CONTAINERAPPS_ENV `
        --resource-group $RESOURCE_GROUP 2>$null
    
    if (-not $envExists) {
        Write-Host "Cration de l'environnement (cela prend 2-3 minutes)..." -ForegroundColor Yellow
        az containerapp env create `
            --name $CONTAINERAPPS_ENV `
            --resource-group $RESOURCE_GROUP `
            --location $LOCATION `
            --logs-workspace-id $LAW_ID `
            --logs-workspace-key $LAW_KEY --output none
        Write-Host " Environment cr: $CONTAINERAPPS_ENV" -ForegroundColor Green
    } else {
        Write-Host " Environment existe dj: $CONTAINERAPPS_ENV" -ForegroundColor Green
    }
    
    Write-Host "`n TAPE 8: Dploiement du Container App" -ForegroundColor Cyan
    $appExists = az containerapp show `
        --name $CONTAINER_APP_NAME `
        --resource-group $RESOURCE_GROUP 2>$null
    
    if ($appExists) {
        Write-Host "Mise  jour de l'application..." -ForegroundColor Yellow
        az containerapp update `
            --name $CONTAINER_APP_NAME `
            --resource-group $RESOURCE_GROUP `
            --image $IMAGE `
            --registry-server $ACR_LOGIN_SERVER `
            --registry-username $ACR_USER `
            --registry-password $ACR_PASS --output none
    } else {
        Write-Host "Cration de l'application (cela prend 2-3 minutes)..." -ForegroundColor Yellow
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
    Write-Host " Container App dploy: $CONTAINER_APP_NAME" -ForegroundColor Green
    
    Write-Host "`n TAPE 9: Rcupration de l'URL" -ForegroundColor Cyan
    $APP_URL = (az containerapp show `
        --name $CONTAINER_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --query properties.configuration.ingress.fqdn -o tsv).Trim()
    
    Write-Host "`n" -NoNewline
    Write-Host "=" -NoNewline; 1..60 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
    Write-Host " DPLOIEMENT RUSSI!" -ForegroundColor Green
    Write-Host "=" -NoNewline; 1..60 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
    Write-Host ""
    Write-Host " Ressources cres:" -ForegroundColor Cyan
    Write-Host "  Resource Group : $RESOURCE_GROUP" -ForegroundColor White
    Write-Host "  ACR            : $ACR_NAME" -ForegroundColor White
    Write-Host "  Rgion         : $LOCATION" -ForegroundColor White
    Write-Host "  Container App  : $CONTAINER_APP_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host " URLs de l'application:" -ForegroundColor Cyan
    Write-Host "  API            : https://$APP_URL" -ForegroundColor Yellow
    Write-Host "  Health Check   : https://$APP_URL/health" -ForegroundColor Yellow
    Write-Host "  Documentation  : https://$APP_URL/docs" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Test rapide:" -ForegroundColor Cyan
    Write-Host "  Test-AzureAPI" -ForegroundColor White
    Write-Host ""
    Write-Host " Pour supprimer toutes les ressources:" -ForegroundColor Cyan
    Write-Host "  az group delete --name $RESOURCE_GROUP --yes --no-wait" -ForegroundColor White
    Write-Host ""
    Write-Host " Cot estim: 3-6/mois" -ForegroundColor Yellow
    Write-Host "=" -NoNewline; 1..60 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
    
    # Sauvegarder l'URL pour les tests
    $APP_URL | Out-File -FilePath "azure_url.txt" -Encoding utf8
    Write-Host " URL sauvegarde dans azure_url.txt" -ForegroundColor Green
}

function Test-AzureAPI {
    Write-Host " Test de l'API Azure" -ForegroundColor Cyan
    
    if (-not (Test-Path "azure_url.txt")) {
        Write-Host " Fichier azure_url.txt non trouv. Excutez Deploy-ToAzure d'abord." -ForegroundColor Red
        return
    }
    
    $APP_URL = (Get-Content "azure_url.txt").Trim()
    Write-Host "URL teste: https://$APP_URL" -ForegroundColor Yellow
    
    Write-Host "`n1 Test Health Check..." -ForegroundColor Cyan
    try {
        $health = Invoke-RestMethod -Uri "https://$APP_URL/health" -Method Get
        Write-Host " Health: $($health | ConvertTo-Json -Compress)" -ForegroundColor Green
    } catch {
        Write-Host " chec health check: $_" -ForegroundColor Red
    }
    
    Write-Host "`n2 Test Prdiction..." -ForegroundColor Cyan
    $testData = @{
        CreditScore = 650
        Age = 35
        Tenure = 5
        Balance = 50000
        NumOfProducts = 2
        HasCrCard = 1
        IsActiveMember = 1
        EstimatedSalary = 75000
        Geography_Germany = 0
        Geography_Spain = 1
    }
    
    try {
        $prediction = Invoke-RestMethod -Uri "https://$APP_URL/predict" -Method Post -Body ($testData | ConvertTo-Json) -ContentType "application/json"
        Write-Host " Prdiction: $($prediction | ConvertTo-Json)" -ForegroundColor Green
        Write-Host "   Churn Probability: $($prediction.churn_probability * 100)%" -ForegroundColor Yellow
        Write-Host "   Risk Level: $($prediction.risk_level)" -ForegroundColor Yellow
    } catch {
        Write-Host " chec prdiction: $_" -ForegroundColor Red
    }
    
    Write-Host "`n3 URLs utiles:" -ForegroundColor Cyan
    Write-Host "  Swagger UI : https://$APP_URL/docs" -ForegroundColor Yellow
    Write-Host "  Redoc      : https://$APP_URL/redoc" -ForegroundColor Yellow
}

function Get-AzureLogs {
    param(
        [int]$Lines = 50
    )
    
    Write-Host " Rcupration des logs Azure..." -ForegroundColor Cyan
    $RESOURCE_GROUP = "rg-mlops-bank-churn"
    $CONTAINER_APP_NAME = "bank-churn"
    
    az containerapp logs show `
        --name $CONTAINER_APP_NAME `
        --resource-group $RESOURCE_GROUP `
        --tail $Lines
}

function Remove-AzureResources {
    Write-Host " Suppression des ressources Azure" -ForegroundColor Yellow
    Write-Host " ATTENTION: Cela supprimera TOUTES les ressources du groupe!" -ForegroundColor Red
    
    $confirmation = Read-Host "tes-vous sr? (tapez 'oui' pour confirmer)"
    if ($confirmation -ne "oui") {
        Write-Host " Annul" -ForegroundColor Yellow
        return
    }
    
    $RESOURCE_GROUP = "rg-mlops-bank-churn"
    Write-Host "Suppression en cours..." -ForegroundColor Yellow
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    
    Write-Host " Suppression lance (asynchrone)" -ForegroundColor Green
    Write-Host "Vrifiez le portail Azure dans quelques minutes." -ForegroundColor Yellow
}

function Show-Help {
    Write-Host "`n[COMMANDS AVAILABLE]" -ForegroundColor Cyan
    Write-Host "=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
    
    Write-Host "`n[Setup & Configuration]" -ForegroundColor Yellow
    Write-Host "  Setup-Environment      : Create virtual environment"
    
    Write-Host "`n[Machine Learning]" -ForegroundColor Yellow
    Write-Host "  Generate-Data          : Generate dataset"
    Write-Host "  Train-Model            : Train model"
    Write-Host "  Start-MLflow           : Start MLflow UI (port 5000)"
    
    Write-Host "`n[API & Tests]" -ForegroundColor Yellow
    Write-Host "  Start-API              : Start local API (port 8000)"
    Write-Host "  Test-API               : Test local API"
    Write-Host "  Open-APIDocs           : Open Swagger UI"
    
    Write-Host "`n[Docker]" -ForegroundColor Yellow
    Write-Host "  Build-DockerImage      : Build Docker image"
    Write-Host "  Start-Container        : Start container (port 8080)"
    Write-Host "  Stop-Container         : Stop container"
    Write-Host "  Show-DockerLogs        : View Docker logs"
    Write-Host "  Test-DockerAPI         : Test Docker API"
    
    Write-Host "`n[Azure - Module 4]" -ForegroundColor Yellow
    Write-Host "  Deploy-ToAzure         : Deploy to Azure Container Apps"
    Write-Host "  Test-AzureAPI          : Test deployed Azure API"
    Write-Host "  Get-AzureLogs          : View Azure logs (50 lines)"
    Write-Host "  Remove-AzureResources  : Delete all Azure resources"
    
    Write-Host "`n[Workflows]" -ForegroundColor Yellow
    Write-Host "  Run-FullWorkflow       : Full workflow (data -> train -> docker -> test)"
    
    Write-Host "`n[Maintenance]" -ForegroundColor Yellow
    Write-Host "  Clean-All              : Clean all generated files"
    
    Write-Host "`n[Usage Example - Module 4:]" -ForegroundColor Cyan
    Write-Host "  1. az login                # Log in to Azure"
    Write-Host "  2. Deploy-ToAzure          # Deploy (15-20 min)"
    Write-Host "  3. Test-AzureAPI           # Test API"
    Write-Host "  4. Get-AzureLogs           # View logs"
    
    Write-Host "`n=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
}

# Show help on load
Show-Help

# Aliases
Set-Alias -Name setup -Value Setup-Environment
Set-Alias -Name train -Value Train-Model
Set-Alias -Name api -Value Start-API
Set-Alias -Name docker-build -Value Build-DockerImage
Set-Alias -Name docker-start -Value Start-Container
Set-Alias -Name docker-stop -Value Stop-Container
Set-Alias -Name deploy -Value Deploy-ToAzure
Set-Alias -Name clean -Value Clean-All
Set-Alias -Name help -Value Show-Help

Write-Host "`n PowerShell commands loaded! Type 'Show-Help' for available commands.`n" -ForegroundColor Green

