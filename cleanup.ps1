# ========================================
# Azure Resources Cleanup Script
# Module 10 - MLOps Workshop
# ========================================

$RESOURCE_GROUP = "rg-mlops-bank-churn"

Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "Azure Resources Cleanup" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow

Write-Host "`nWARNING: This will delete ALL resources in '$RESOURCE_GROUP'!" -ForegroundColor Red
Write-Host "Resources to be deleted:" -ForegroundColor Cyan
Write-Host "  - Azure Container Registry (mlopslegion)"
Write-Host "  - Azure Container Apps (churn-api)"
Write-Host "  - Application Insights (bank-churn-insights)"
Write-Host "  - Container Apps Environment (env-mlops-workshop)"
Write-Host "  - Log Analytics Workspace"

$confirm = Read-Host "`nAre you sure you want to delete all resources? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "`nOperation cancelled." -ForegroundColor Green
    exit
}

Write-Host "`nListing resources before deletion..." -ForegroundColor Cyan
az resource list --resource-group $RESOURCE_GROUP --output table

Write-Host "`nStarting deletion (this takes 5-10 minutes)..." -ForegroundColor Yellow
az group delete --name $RESOURCE_GROUP --yes --no-wait

Write-Host "`nDeletion initiated!" -ForegroundColor Green
Write-Host "Check status at: https://portal.azure.com" -ForegroundColor Cyan
Write-Host "`nTo verify deletion, run:" -ForegroundColor White
Write-Host "  az group list --output table" -ForegroundColor Gray
