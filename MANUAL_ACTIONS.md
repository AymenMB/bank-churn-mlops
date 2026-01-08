# 📋 Actions Manuelles Requises pour les Modules Suivants

## Module 4 : Azure Container Registry (ACR)

### Actions Manuelles Nécessaires

1. **Connexion à Azure**
   ```powershell
   az login
   # Sélectionner votre abonnement "Azure for Students"
   az account set --subscription "Azure for Students"
   ```

2. **Créer le Resource Group**
   ```powershell
   az group create --name rg-bank-churn-mlops --location westeurope
   ```

3. **Créer Azure Container Registry**
   ```powershell
   # Choisir un nom unique (remplacer XXXX par des chiffres)
   az acr create --resource-group rg-bank-churn-mlops --name acrbankchurnXXXX --sku Basic
   ```

4. **Se connecter à ACR**
   ```powershell
   az acr login --name acrbankchurnXXXX
   ```

5. **Tag et Push l'image**
   ```powershell
   docker tag bank-churn-api:v1 acrbankchurnXXXX.azurecr.io/bank-churn-api:v1
   docker push acrbankchurnXXXX.azurecr.io/bank-churn-api:v1
   ```

---

## Module 5 : Azure Container Apps

### Actions Manuelles Nécessaires

1. **Activer l'admin ACR**
   ```powershell
   az acr update -n acrbankchurnXXXX --admin-enabled true
   ```

2. **Récupérer les credentials ACR**
   ```powershell
   az acr credential show --name acrbankchurnXXXX
   # Noter le username et password
   ```

3. **Créer Container Apps Environment**
   ```powershell
   az containerapp env create `
     --name env-bank-churn `
     --resource-group rg-bank-churn-mlops `
     --location westeurope
   ```

4. **Déployer la Container App**
   ```powershell
   az containerapp create `
     --name app-bank-churn `
     --resource-group rg-bank-churn-mlops `
     --environment env-bank-churn `
     --image acrbankchurnXXXX.azurecr.io/bank-churn-api:v1 `
     --target-port 8000 `
     --ingress external `
     --registry-server acrbankchurnXXXX.azurecr.io `
     --registry-username [USERNAME] `
     --registry-password [PASSWORD] `
     --cpu 0.5 `
     --memory 1.0Gi `
     --min-replicas 1 `
     --max-replicas 3
   ```

5. **Récupérer l'URL publique**
   ```powershell
   az containerapp show `
     --name app-bank-churn `
     --resource-group rg-bank-churn-mlops `
     --query properties.configuration.ingress.fqdn -o tsv
   ```

6. **Tester l'API publique**
   - Ouvrir : `https://[VOTRE-URL]/docs`
   - Tester : `https://[VOTRE-URL]/health`

---

## Module 6 : GitHub Actions CI/CD

### Actions Manuelles Nécessaires

1. **Créer un repository GitHub**
   - Aller sur https://github.com/new
   - Nom : `bank-churn-mlops`
   - Visibilité : Private ou Public

2. **Initialiser Git localement**
   ```powershell
   cd d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops
   git init
   git add .
   git commit -m "Initial commit - MLOps workshop"
   git branch -M main
   git remote add origin https://github.com/VOTRE-USERNAME/bank-churn-mlops.git
   git push -u origin main
   ```

3. **Créer un Service Principal Azure**
   ```powershell
   az ad sp create-for-rbac `
     --name "sp-bank-churn-github" `
     --role contributor `
     --scopes /subscriptions/[SUBSCRIPTION-ID]/resourceGroups/rg-bank-churn-mlops `
     --sdk-auth
   ```
   
   **Noter la sortie JSON complète !**

4. **Configurer les Secrets GitHub**
   - Aller sur : Settings → Secrets and variables → Actions
   - Créer ces secrets :
     - `AZURE_CREDENTIALS` : Le JSON complet du service principal
     - `AZURE_SUBSCRIPTION_ID` : Votre subscription ID
     - `ACR_NAME` : acrbankchurnXXXX
     - `ACR_USERNAME` : Username de l'ACR
     - `ACR_PASSWORD` : Password de l'ACR
     - `RESOURCE_GROUP` : rg-bank-churn-mlops
     - `CONTAINER_APP_NAME` : app-bank-churn

5. **Créer le workflow GitHub Actions**
   Le fichier `.github/workflows/deploy.yml` est déjà créé automatiquement.

6. **Tester le déploiement**
   ```powershell
   git add .
   git commit -m "Test CI/CD deployment"
   git push
   ```
   
   Vérifier l'exécution sur : https://github.com/VOTRE-USERNAME/bank-churn-mlops/actions

---

## Module 7 : Application Insights

### Actions Manuelles Nécessaires

1. **Créer Application Insights**
   ```powershell
   az monitor app-insights component create `
     --app app-insights-bank-churn `
     --location westeurope `
     --resource-group rg-bank-churn-mlops `
     --application-type web
   ```

2. **Récupérer la Connection String**
   ```powershell
   az monitor app-insights component show `
     --app app-insights-bank-churn `
     --resource-group rg-bank-churn-mlops `
     --query connectionString -o tsv
   ```

3. **Configurer la Container App avec Application Insights**
   ```powershell
   az containerapp update `
     --name app-bank-churn `
     --resource-group rg-bank-churn-mlops `
     --set-env-vars APPLICATIONINSIGHTS_CONNECTION_STRING="[CONNECTION-STRING]"
   ```

4. **Créer des données de production pour drift detection**
   Le script `generate_production_data.py` est déjà créé dans le projet.

5. **Créer une alerte de drift dans Azure**
   - Aller dans Application Insights → Alerts
   - Créer une alerte basée sur les logs custom "drift_detection"
   - Configurer une action (email, webhook, etc.)

6. **Créer un Dashboard**
   - Aller dans Application Insights → Workbooks
   - Créer un nouveau workbook avec :
     - Nombre de prédictions
     - Taux d'erreur
     - Latence des requêtes
     - Alertes de drift

---

## 🎯 Commandes Rapides (Script PowerShell)

Pour simplifier, vous pouvez utiliser le script `commands.ps1` :

```powershell
# Charger les commandes
. .\commands.ps1

# Déployer automatiquement sur Azure
Deploy-ToAzure

# Ou utiliser les commandes individuelles
setup              # Setup environment
train              # Train model
docker-build       # Build Docker image
deploy             # Deploy to Azure
```

---

## ⚠️ Points d'Attention

### Coûts Azure
- **Container Apps** : ~2-5€/mois en mode minimal
- **Container Registry** : ~0.50€/mois (Basic SKU)
- **Application Insights** : Gratuit jusqu'à 5GB/mois
- **Total estimé** : 3-6€/mois

### Nettoyage des Ressources
Pour éviter les frais, supprimer le resource group après le workshop :
```powershell
az group delete --name rg-bank-churn-mlops --yes --no-wait
```

### Limites Azure for Students
- 100$ de crédit (suffisant pour plusieurs mois)
- Certaines régions peuvent être limitées
- Préférer `westeurope` ou `northeurope`

---

## 📚 Documentation Utile

- **Azure Container Apps** : https://learn.microsoft.com/azure/container-apps/
- **Azure Container Registry** : https://learn.microsoft.com/azure/container-registry/
- **GitHub Actions** : https://docs.github.com/actions
- **Application Insights** : https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview

---

## ✅ Checklist de Validation

### Avant de passer au Module 4
- [ ] L'image Docker fonctionne localement
- [ ] Le modèle prédit correctement
- [ ] La documentation Swagger est accessible
- [ ] Vous avez un compte Azure actif

### Avant de passer au Module 5
- [ ] L'image est poussée sur ACR
- [ ] ACR admin est activé
- [ ] Vous avez les credentials ACR

### Avant de passer au Module 6
- [ ] Container App est déployée
- [ ] L'URL publique fonctionne
- [ ] Vous avez un compte GitHub

### Avant de passer au Module 7
- [ ] GitHub Actions fonctionne
- [ ] Le déploiement automatique marche
- [ ] Application Insights est créé

---

**Bon courage pour la suite du workshop ! 🚀**
