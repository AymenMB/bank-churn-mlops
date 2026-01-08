# 📝 Project Progress & Configuration Log

## 🚀 Module 4: Azure Deployment (Completed)

We have successfully containerized and deployed the Bank Churn Prediction API to Azure Container Apps.

### ✅ **Deployment Summary**

| Resource | Name | Details |
|----------|------|---------|
| **Resource Group** | `rg-mlops-bank-churn` | France Central |
| **Container Registry (ACR)** | `mlopslegion.azurecr.io` | Basic SKU, Admin enabled |
| **Log Analytics** | `law-mlops-legion-84352` | Connected to Container Apps |
| **Container Apps Environment** | `env-mlops-workshop` | Consumption tier |
| **Container App** | `churn-api` | Running with auto-scaling (0-3 replicas) |

### 🔗 **Live Endpoints**

| Endpoint | URL |
|----------|-----|
| **API Base** | `https://churn-api.salmonfield-cb3d4cec.francecentral.azurecontainerapps.io/` |
| **Health Check** | `https://churn-api.salmonfield-cb3d4cec.francecentral.azurecontainerapps.io/health` |
| **Swagger Docs** | `https://churn-api.salmonfield-cb3d4cec.francecentral.azurecontainerapps.io/docs` |

---

## 🧪 Verification Logs

### 1. Root Endpoint Test
**Command:**
```powershell
Invoke-RestMethod -Uri "https://churn-api.salmonfield-cb3d4cec.francecentral.azurecontainerapps.io/" | ConvertTo-Json
```
**Result (Success):**
```json
{
    "message":  "Bank Churn Prediction API",
    "version":  "1.0.0",
    "status":  "running",
    "docs":  "/docs"
}
```

### 2. Prediction Test (Attempt 1 - Failed)
We attempted to send a request without pre-encoded geography features.

**Command:**
```powershell
$body = @{
    CreditScore = 650; Geography = "France"; Gender = "Female"; Age = 35; 
    Tenure = 5; Balance = 50000.0; NumOfProducts = 2; HasCrCard = 1; 
    IsActiveMember = 1; EstimatedSalary = 75000.0
} | ConvertTo-Json
Invoke-RestMethod -Uri ".../predict" -Method POST -Body $body ...
```
**Result (Error):**
```json
{"detail":[{"type":"missing","loc":["body","Geography_Germany"],"msg":"Field required"...
```
*Correction needed:* The model expects One-Hot Encoded features (`Geography_Germany`, `Geography_Spain`), not raw string values.

### 3. Prediction Test (Attempt 2 - Success)
We corrected the payload to match the model's expected schema.

**Command:**
```powershell
$body = @{
    CreditScore = 650; Age = 35; Tenure = 5; Balance = 50000.0; 
    NumOfProducts = 2; HasCrCard = 1; IsActiveMember = 1; 
    EstimatedSalary = 75000.0; Geography_Germany = 0; Geography_Spain = 0
} | ConvertTo-Json
Invoke-RestMethod -Uri ".../predict" -Method POST -Body $body ...
```
**Result (Success):**
```json
{
    "churn_probability":  0.0035,
    "prediction":  0,
    "risk_level":  "Low"
}
```

---

## 🔄 Module 5: CI/CD Pipeline (Completed)

We set up a fully automated CI/CD pipeline using GitHub Actions.

### **Repository Details**
- **URL**: `https://github.com/AymenMB/bank-churn-mlops`
- **Visibility**: Public

### **Authentication & Secrets**
We created a Service Principal and configured the following GitHub Secrets:
1. **AZURE_CREDENTIALS**: Service principal JSON stored securely in GitHub Secrets
2. **ACR_USERNAME**: Container registry admin username
3. **ACR_PASSWORD**: Container registry admin password

> **Note**: Actual credentials are stored securely in GitHub repository secrets and should never be committed to version control.

### **Pipeline Workflow**
The `.github/workflows/ci-cd.yml` pipeline performs the following steps on every push to `main`:
1. **Test**: Runs `pytest` on the codebase.
2. **Build**: Builds the Docker image.
3. **Push**: Pushes the image to ACR (`mlopslegion.azurecr.io`).
4. **Deploy**: Updates the Container App (`churn-api`) with the new image.
5. **Verify**: Runs a health check on the deployed URL.

**Status**: ✅ The pipeline ran successfully (Duration: ~4m 5s).

---

## 💰 Resource & Cost Overview

| Resource | Configuration | Estimated Cost |
|----------|---------------|----------------|
| **ACR** | Basic Tier | ~€0.15 / day |
| **Container App** | Consumption (0.5 vCPU, 1Gi RAM) | Free for first 180k vCPU-seconds/mo (scales to 0) |
| **Log Analytics** | Pay-as-you-go | Based on ingestion (minimal for dev) |

**Estimated Monthly Cost**: ~€5-10 EUR

---

## 🔜 Next Steps: Module 6 (Monitoring)
We are ready to implement Application Insights for production-grade monitoring.

**Goals:**
1. Create Application Insights resource.
2. Inject connection string into Container App.
3. Update code to send logs and drift metircs to Azure.
