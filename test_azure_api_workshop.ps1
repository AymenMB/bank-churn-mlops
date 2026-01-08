# Test de l'API Azure - Workshop Module 4
# Section 6.5: Test de l'API en Production
# =========================================

$RESOURCE_GROUP = "rg-mlops-bank-churn"
$CONTAINER_APP_NAME = "bank-churn"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TEST API AZURE - Module 4" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Recuperer l'URL
Write-Host ""
Write-Host "[1] Recuperation de l'URL..." -ForegroundColor Yellow

$APP_URL = (az containerapp show `
    --name $CONTAINER_APP_NAME `
    --resource-group $RESOURCE_GROUP `
    --query properties.configuration.ingress.fqdn -o tsv) -replace "`r", "" -replace "`n", ""

# Nettoyer l'URL
$APP_URL = $APP_URL.Trim()

Write-Host "URL nettoyee: '$APP_URL'" -ForegroundColor Cyan
Write-Host "Longueur: $($APP_URL.Length)" -ForegroundColor Cyan

# 2. Construire l'URL complete
$FULL_URL = "https://$APP_URL"
Write-Host "URL complete: $FULL_URL" -ForegroundColor Cyan

# 3. Test Health Check
Write-Host ""
Write-Host "[2] Test Health Check..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$FULL_URL/health" -Method Get -TimeoutSec 30
    Write-Host "[OK] Health: $($healthResponse | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Health check echoue: $_" -ForegroundColor Red
}

# 4. Test Root Endpoint
Write-Host ""
Write-Host "[3] Test Root Endpoint..." -ForegroundColor Yellow
try {
    $rootResponse = Invoke-RestMethod -Uri "$FULL_URL/" -Method Get -TimeoutSec 30
    Write-Host "[OK] Root: $($rootResponse | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Root endpoint echoue: $_" -ForegroundColor Red
}

# 5. Test de prediction (comme dans le workshop)
Write-Host ""
Write-Host "[4] Test de prediction..." -ForegroundColor Yellow

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
    $predictionResponse = Invoke-RestMethod `
        -Uri "$FULL_URL/predict" `
        -Method Post `
        -Body ($testData | ConvertTo-Json) `
        -ContentType "application/json" `
        -TimeoutSec 30
    
    Write-Host "[OK] Prediction reussie!" -ForegroundColor Green
    Write-Host "Response: $($predictionResponse | ConvertTo-Json)" -ForegroundColor Cyan
    
    if ($predictionResponse.churn_probability) {
        $probability = [math]::Round($predictionResponse.churn_probability * 100, 2)
        Write-Host ""
        Write-Host "  Churn Probability: $probability%" -ForegroundColor Yellow
        Write-Host "  Risk Level: $($predictionResponse.risk_level)" -ForegroundColor Yellow
        Write-Host "  Prediction: $($predictionResponse.prediction)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERREUR] Prediction echouee: $_" -ForegroundColor Red
}

# 6. Test High Risk Customer
Write-Host ""
Write-Host "[5] Test client a haut risque..." -ForegroundColor Yellow

$highRiskData = @{
    CreditScore = 400
    Age = 55
    Tenure = 1
    Balance = 0
    NumOfProducts = 4
    HasCrCard = 0
    IsActiveMember = 0
    EstimatedSalary = 20000
    Geography_Germany = 1
    Geography_Spain = 0
}

try {
    $highRiskResponse = Invoke-RestMethod `
        -Uri "$FULL_URL/predict" `
        -Method Post `
        -Body ($highRiskData | ConvertTo-Json) `
        -ContentType "application/json" `
        -TimeoutSec 30
    
    Write-Host "[OK] Prediction High Risk reussie!" -ForegroundColor Green
    
    if ($highRiskResponse.churn_probability) {
        $probability = [math]::Round($highRiskResponse.churn_probability * 100, 2)
        Write-Host "  Churn Probability: $probability%" -ForegroundColor Yellow
        Write-Host "  Risk Level: $($highRiskResponse.risk_level)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[ERREUR] Prediction echouee: $_" -ForegroundColor Red
}

# Resume
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RESUME DES TESTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "URLs testees:" -ForegroundColor Yellow
Write-Host "  API      : $FULL_URL" -ForegroundColor White
Write-Host "  Health   : $FULL_URL/health" -ForegroundColor White
Write-Host "  Docs     : $FULL_URL/docs" -ForegroundColor White
Write-Host "  Swagger  : $FULL_URL/redoc" -ForegroundColor White
Write-Host ""
Write-Host "Ouvrir dans le navigateur:" -ForegroundColor Yellow
Write-Host "  Start-Process '$FULL_URL/docs'" -ForegroundColor White
Write-Host ""
