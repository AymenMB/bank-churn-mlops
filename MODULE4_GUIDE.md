# 📘 Module 4 : Déploiement sur Azure Container Apps

## 🎯 Objectif

Déployer l'API bank-churn sur Azure Container Apps et la rendre accessible publiquement via HTTPS.

## ⏱️ Durée estimée : 15-20 minutes

---

## 🔴 ACTIONS MANUELLES REQUISES

### 1. Se connecter à Azure (30 secondes)

```powershell
az login
```

Cela ouvrira votre navigateur pour l'authentification.

### 2. Vérifier votre abonnement

```powershell
az account show --query "{Name:name, SubscriptionId:id}" -o json
```

Si vous avez plusieurs abonnements, sélectionnez le bon :

```powershell
az account set --subscription "NOM_OU_ID_ABONNEMENT"
```

### 3. Lancer le déploiement automatisé

```powershell
cd "d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops"
. .\commands.ps1
Deploy-ToAzure
```

**C'est tout !** Le script automatise les 9 étapes suivantes :

---

## ✅ CE QUE LE SCRIPT FAIT AUTOMATIQUEMENT

### Étape 1 : Installation des extensions Azure CLI
- Installe/met à jour l'extension `containerapp`

### Étape 2 : Enregistrement des providers
- `Microsoft.ContainerRegistry`
- `Microsoft.App`
- `Microsoft.Web`
- `Microsoft.OperationalInsights`

### Étape 3 : Création du Resource Group
- Nom : `rg-mlops-bank-churn`
- Région : `westeurope` (ou `northeurope` en fallback)

### Étape 4 : Création du Container Registry (ACR)
- Nom : `mlops[VOTRE_USERNAME]` (ex: `mlopsyasmine`)
- SKU : Basic
- Admin activé pour les tests

### Étape 5 : Build et Push de l'image Docker
- Tag : `[ACR].azurecr.io/churn-api:v1`
- Push automatique vers Azure

### Étape 6 : Création du Log Analytics Workspace
- Pour la surveillance et les logs
- Nom aléatoire : `law-mlops-[USER]-[RANDOM]`

### Étape 7 : Création du Container Apps Environment
- Nom : `env-mlops-workshop`
- Connecté au Log Analytics

### Étape 8 : Déploiement du Container App
- Nom : `bank-churn`
- Port : 8000
- Ingress : External (HTTPS)
- Réplicas : Min=1, Max=1

### Étape 9 : Récupération de l'URL publique
- Sauvegardée dans `azure_url.txt`
- Affichée dans le terminal

---

## 🧪 TESTS APRÈS DÉPLOIEMENT

### Test automatique complet

```powershell
Test-AzureAPI
```

Cela teste :
1. Health check (`/health`)
2. Prédiction (`/predict`)
3. Affiche les URLs Swagger et Redoc

### Tests manuels via navigateur

Ouvrez ces URLs (remplacez `[VOTRE_URL]` par l'URL affichée) :

1. **Health Check** :  
   `https://[VOTRE_URL]/health`

2. **Documentation interactive (Swagger UI)** :  
   `https://[VOTRE_URL]/docs`

3. **Documentation alternative (Redoc)** :  
   `https://[VOTRE_URL]/redoc`

### Test avec curl/PowerShell

```powershell
$url = Get-Content azure_url.txt
$body = @{
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
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://$url/predict" -Method Post -Body $body -ContentType "application/json"
```

---

## 📋 COMMANDES UTILES

### Voir les logs en temps réel

```powershell
Get-AzureLogs
# Ou avec plus de lignes
az containerapp logs show --name bank-churn --resource-group rg-mlops-bank-churn --tail 100 --follow
```

### Voir l'état de l'application

```powershell
az containerapp show --name bank-churn --resource-group rg-mlops-bank-churn --query "{Status:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" -o json
```

### Voir les révisions

```powershell
az containerapp revision list --name bank-churn --resource-group rg-mlops-bank-churn --output table
```

### Mettre à jour l'application

Si vous modifiez le code :

```powershell
# 1. Rebuild et push
docker build -t bank-churn-api:v2 .
docker tag bank-churn-api:v2 [ACR].azurecr.io/churn-api:v2
docker push [ACR].azurecr.io/churn-api:v2

# 2. Update Container App
az containerapp update --name bank-churn --resource-group rg-mlops-bank-churn --image [ACR].azurecr.io/churn-api:v2
```

Ou simplement :

```powershell
Deploy-ToAzure  # Met à jour automatiquement si déjà déployé
```

---

## 🔧 DÉPANNAGE

### Problème : "DNS ou cloudName: null"

**Solution** :
```powershell
az logout
az login
```

### Problème : "ContainerApp provisioning failed"

**Diagnostic** :
```powershell
Get-AzureLogs
```

Vérifiez :
- Les credentials ACR sont corrects
- L'image a été poussée dans ACR
- Le port 8000 est correct

### Problème : "Image pull failed"

**Solution** :
```powershell
# Re-push l'image
az acr login --name [VOTRE_ACR]
docker push [ACR].azurecr.io/churn-api:v1
```

### Problème : Docker non accessible

**Solution** :
1. Démarrer Docker Desktop
2. Ouvrir un nouveau terminal PowerShell
3. Relancer `Deploy-ToAzure`

### Problème : Erreur de permissions Azure

**Solution** :
```powershell
# Vérifier vos permissions
az account show
az role assignment list --assignee [VOTRE_EMAIL] --output table
```

Vous devez avoir au minimum le rôle "Contributor" sur l'abonnement.

---

## 💰 ESTIMATION DES COÛTS

| Service | Configuration | Coût mensuel |
|---------|---------------|--------------|
| **Container Registry** | Basic SKU | 0.50€ |
| **Container Apps** | 1 réplica, usage standard | 2-5€ |
| **Log Analytics** | 5 GB gratuit/mois | 0€ |
| **TOTAL** | | **3-6€/mois** |

### Optimisation des coûts

Pour éviter les coûts en développement :
- Arrêtez l'app quand vous ne l'utilisez pas
- Ou supprimez complètement les ressources

```powershell
Remove-AzureResources  # Supprime tout
```

---

## 🗑️ NETTOYAGE

### Supprimer toutes les ressources

```powershell
Remove-AzureResources
```

Ou manuellement :

```powershell
az group delete --name rg-mlops-bank-churn --yes --no-wait
```

### Vérifier la suppression

```powershell
az group exists --name rg-mlops-bank-churn
# Devrait retourner "false" après quelques minutes
```

---

## ✅ CHECKPOINT MODULE 4

Avant de passer au Module 5 (CI/CD), vérifiez :

- [ ] L'application est accessible via HTTPS
- [ ] Le health check retourne `{"status":"healthy","model_loaded":true}`
- [ ] Les prédictions fonctionnent via `/docs`
- [ ] Vous avez noté l'URL publique de votre API
- [ ] Test-AzureAPI réussit sans erreurs
- [ ] Les logs sont visibles avec `Get-AzureLogs`

---

## 🎓 EXERCICE PRATIQUE

### Exercice 1 : Test de charge

Envoyez 10 prédictions à votre API et observez les logs :

```powershell
1..10 | ForEach-Object {
    Test-AzureAPI
    Start-Sleep -Seconds 1
}

# Voir les logs
Get-AzureLogs
```

### Exercice 2 : Partage avec un camarade

1. Partagez votre URL d'API avec un camarade
2. Faites 10 prédictions sur son API
3. Comparez les résultats avec votre modèle
4. Observez vos propres logs pour voir ses requêtes

### Exercice 3 : Modification et redéploiement

1. Modifiez le message de welcome dans `app/main.py`
2. Relancez `Deploy-ToAzure`
3. Vérifiez que le changement est visible sur l'URL Azure

---

## 📚 RESSOURCES COMPLÉMENTAIRES

- [Azure Container Apps - Documentation officielle](https://learn.microsoft.com/azure/container-apps/)
- [Azure CLI - Container Apps commands](https://learn.microsoft.com/cli/azure/containerapp)
- [Docker - Best practices](https://docs.docker.com/develop/dev-best-practices/)
- [FastAPI - Deployment](https://fastapi.tiangolo.com/deployment/)

---

## 📝 NOTES

- **Région par défaut** : `westeurope` (fallback : `northeurope`)
- **Nom ACR** : Automatiquement généré à partir de votre username Windows
- **Sécurité** : Admin ACR activé pour simplicité (production : utiliser Managed Identity)
- **Scaling** : 1 réplica fixe (production : configurer autoscaling)
- **HTTPS** : Automatique via Container Apps ingress

---

## ➡️ PROCHAINE ÉTAPE

**Module 5 : GitHub Actions CI/CD**

Automatiser le déploiement avec chaque commit Git.

Voir : [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md#module-6--github-actions-cicd)
