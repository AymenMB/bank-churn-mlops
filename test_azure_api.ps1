# Script de test pour l'API Azure déployée
# Usage: .\test_azure_api.ps1

Write-Host "🧪 Test de l'API Azure Bank Churn" -ForegroundColor Cyan
Write-Host "=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""

# Vérifier si l'URL existe
if (-not (Test-Path "azure_url.txt")) {
    Write-Host "❌ Fichier azure_url.txt non trouvé." -ForegroundColor Red
    Write-Host "Exécutez Deploy-ToAzure d'abord, ou créez le fichier manuellement avec votre URL." -ForegroundColor Yellow
    exit 1
}

$APP_URL = (Get-Content "azure_url.txt").Trim()
$BASE_URL = "https://$APP_URL"

Write-Host "`n📍 URL testée: $BASE_URL" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "1️⃣ Test Health Check..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/health" -Method Get -UseBasicParsing
    $health = $response.Content | ConvertFrom-Json
    
    if ($response.StatusCode -eq 200 -and $health.status -eq "healthy") {
        Write-Host "✅ RÉUSSI - Status: $($health.status), Model loaded: $($health.model_loaded)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ ÉCHEC - Status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Root endpoint
Write-Host "`n2️⃣ Test Root Endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/" -Method Get -UseBasicParsing
    $root = $response.Content | ConvertFrom-Json
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ RÉUSSI - Message: $($root.message)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Prédiction Low Risk
Write-Host "`n3️⃣ Test Prédiction (Low Risk)..." -ForegroundColor Cyan
$testDataLow = @{
    CreditScore = 750
    Age = 35
    Tenure = 5
    Balance = 50000
    NumOfProducts = 2
    HasCrCard = 1
    IsActiveMember = 1
    EstimatedSalary = 75000
    Geography_Germany = 0
    Geography_Spain = 0
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/predict" -Method Post -Body $testDataLow -ContentType "application/json"
    
    Write-Host "✅ RÉUSSI" -ForegroundColor Green
    Write-Host "   Churn Probability: $([math]::Round($response.churn_probability * 100, 2))%" -ForegroundColor White
    Write-Host "   Prediction: $($response.prediction)" -ForegroundColor White
    Write-Host "   Risk Level: $($response.risk_level)" -ForegroundColor $(if ($response.risk_level -eq "Low") { "Green" } elseif ($response.risk_level -eq "Medium") { "Yellow" } else { "Red" })
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Prédiction High Risk
Write-Host "`n4️⃣ Test Prédiction (High Risk)..." -ForegroundColor Cyan
$testDataHigh = @{
    CreditScore = 400
    Age = 60
    Tenure = 1
    Balance = 0
    NumOfProducts = 1
    HasCrCard = 0
    IsActiveMember = 0
    EstimatedSalary = 25000
    Geography_Germany = 1
    Geography_Spain = 0
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/predict" -Method Post -Body $testDataHigh -ContentType "application/json"
    
    Write-Host "✅ RÉUSSI" -ForegroundColor Green
    Write-Host "   Churn Probability: $([math]::Round($response.churn_probability * 100, 2))%" -ForegroundColor White
    Write-Host "   Prediction: $($response.prediction)" -ForegroundColor White
    Write-Host "   Risk Level: $($response.risk_level)" -ForegroundColor $(if ($response.risk_level -eq "Low") { "Green" } elseif ($response.risk_level -eq "Medium") { "Yellow" } else { "Red" })
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Batch Prediction
Write-Host "`n5️⃣ Test Batch Prediction (3 customers)..." -ForegroundColor Cyan
$batchData = @{
    customers = @(
        @{
            CreditScore = 650; Age = 35; Tenure = 5; Balance = 50000
            NumOfProducts = 2; HasCrCard = 1; IsActiveMember = 1
            EstimatedSalary = 75000; Geography_Germany = 0; Geography_Spain = 1
        },
        @{
            CreditScore = 800; Age = 28; Tenure = 3; Balance = 100000
            NumOfProducts = 1; HasCrCard = 1; IsActiveMember = 1
            EstimatedSalary = 90000; Geography_Germany = 0; Geography_Spain = 0
        },
        @{
            CreditScore = 450; Age = 55; Tenure = 1; Balance = 5000
            NumOfProducts = 4; HasCrCard = 0; IsActiveMember = 0
            EstimatedSalary = 30000; Geography_Germany = 1; Geography_Spain = 0
        }
    )
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/predict/batch" -Method Post -Body $batchData -ContentType "application/json"
    
    Write-Host "✅ RÉUSSI - $($response.predictions.Count) prédictions" -ForegroundColor Green
    foreach ($pred in $response.predictions) {
        Write-Host "   Customer $($pred.customer_id): $([math]::Round($pred.churn_probability * 100, 2))% - $($pred.risk_level)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Model Info
Write-Host "`n6️⃣ Test Model Info..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/model/info" -Method Get
    
    Write-Host "✅ RÉUSSI" -ForegroundColor Green
    Write-Host "   Model Type: $($response.model_type)" -ForegroundColor White
    Write-Host "   Accuracy: $([math]::Round($response.metrics.accuracy * 100, 2))%" -ForegroundColor White
    Write-Host "   ROC AUC: $([math]::Round($response.metrics.roc_auc * 100, 2))%" -ForegroundColor White
} catch {
    Write-Host "❌ ERREUR - $($_.Exception.Message)" -ForegroundColor Red
}

# Résumé
Write-Host "`n" -NoNewline
Write-Host "=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
Write-Host "✅ TESTS TERMINÉS" -ForegroundColor Green
Write-Host "=" -NoNewline; 1..50 | ForEach-Object { Write-Host "=" -NoNewline }; Write-Host ""
Write-Host ""
Write-Host "📊 URLs utiles:" -ForegroundColor Cyan
Write-Host "   Swagger UI : $BASE_URL/docs" -ForegroundColor Yellow
Write-Host "   Redoc      : $BASE_URL/redoc" -ForegroundColor Yellow
Write-Host "   Health     : $BASE_URL/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Commandes PowerShell:" -ForegroundColor Cyan
Write-Host "   Get-AzureLogs            # Voir les logs" -ForegroundColor White
Write-Host "   Remove-AzureResources    # Supprimer les ressources" -ForegroundColor White
Write-Host ""
