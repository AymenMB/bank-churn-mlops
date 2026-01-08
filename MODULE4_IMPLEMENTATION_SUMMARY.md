# 🚀 MODULE 4 IMPLÉMENTATION - RÉSUMÉ

**Date** : 6 janvier 2026  
**Module** : Déploiement Azure Container Apps  
**Status** : ✅ PRÊT POUR EXÉCUTION

---

## ✅ CE QUI A ÉTÉ AUTOMATISÉ

### 1. Script PowerShell Complet (`commands.ps1`)

**Fonction `Deploy-ToAzure`** - Déploiement automatisé en 9 étapes :

1. ✅ Vérification connexion Azure + Docker
2. ✅ Validation nom ACR (5-50 caractères)
3. ✅ Installation extension `containerapp`
4. ✅ Enregistrement providers (ContainerRegistry, App, Web, OperationalInsights)
5. ✅ Création Resource Group `rg-mlops-bank-churn`
6. ✅ Création ACR avec fallback region (westeurope → northeurope)
7. ✅ Build + Tag + Push image Docker vers ACR
8. ✅ Création Log Analytics Workspace (logs + monitoring)
9. ✅ Création Container Apps Environment
10. ✅ Déploiement Container App `bank-churn` (port 8000, HTTPS)
11. ✅ Récupération URL publique → sauvegarde dans `azure_url.txt`

**Fonctionnalités supplémentaires** :
- `Test-AzureAPI` : Tests automatiques (health, prédiction)
- `Get-AzureLogs` : Affichage des logs Azure
- `Remove-AzureResources` : Suppression avec confirmation
- `Clean-All` : Nettoyage complet local + azure_url.txt

### 2. Documentation Complète

| Fichier | Contenu |
|---------|---------|
| **MODULE4_GUIDE.md** | Guide complet (70+ lignes) avec prérequis, étapes détaillées, dépannage, exercices |
| **MODULE4_QUICKSTART.md** | Guide condensé (3 commandes) pour démarrage rapide |
| **test_azure_api.ps1** | Script standalone de test (6 tests : health, root, predict low/high risk, batch, model info) |

### 3. Intégration dans le Workflow

- ✅ Fonction `Show-Help` mise à jour avec commandes Azure
- ✅ Fonction `Clean-All` étendue (suppression azure_url.txt)
- ✅ Fichier Agents.md mis à jour avec instructions Module 4

---

## 🔴 ACTIONS MANUELLES (Ce que VOUS devez faire)

### Étape 1 : Se connecter à Azure (30 secondes)

```powershell
az login
```

**Vérification** :
```powershell
az account show --query "{Name:name, SubscriptionId:id}" -o json
```

### Étape 2 : Lancer le déploiement (15-20 minutes)

```powershell
cd "d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops"
. .\commands.ps1
Deploy-ToAzure
```

**Ce que vous verrez** :
```
🚀 Déploiement sur Azure Container Apps
==================================================
✅ Connecté à Azure: [Votre compte]
✅ Docker est en cours d'exécution
✅ Nom ACR validé: mlops[username] (12 caractères)

📦 ÉTAPE 1: Installation des extensions Azure CLI
✅ Extension containerapp installée

📦 ÉTAPE 2: Enregistrement des providers Azure
Cela peut prendre 2-3 minutes...
✅ Providers enregistrés

[...]

✅ DÉPLOIEMENT RÉUSSI!
🌐 URLs de l'application:
  API            : https://bank-churn.xxx.azurecontainerapps.io
  Health Check   : https://bank-churn.xxx.azurecontainerapps.io/health
  Documentation  : https://bank-churn.xxx.azurecontainerapps.io/docs
```

### Étape 3 : Tester l'API déployée

```powershell
Test-AzureAPI
```

Ou avec le script standalone :

```powershell
.\test_azure_api.ps1
```

**Résultat attendu** :
```
1️⃣ Test Health Check...
✅ RÉUSSI - Status: healthy, Model loaded: True

2️⃣ Test Prédiction (Low Risk)...
✅ RÉUSSI
   Churn Probability: 0.36%
   Risk Level: Low
```

### Étape 4 : Validation navigateur

Ouvrez dans votre navigateur (URL affichée à l'étape 2) :

1. **Health Check** : `https://[URL]/health`  
   → Doit afficher : `{"status":"healthy","model_loaded":true}`

2. **Swagger UI** : `https://[URL]/docs`  
   → Interface interactive pour tester les endpoints

3. **Test manuel** :
   - Cliquez sur `POST /predict`
   - Cliquez "Try it out"
   - Cliquez "Execute"
   - Vérifiez la réponse

---

## 📊 RESSOURCES CRÉÉES SUR AZURE

| Ressource | Nom | Configuration |
|-----------|-----|---------------|
| **Resource Group** | `rg-mlops-bank-churn` | westeurope ou northeurope |
| **Container Registry** | `mlops[username]` | Basic SKU, admin enabled |
| **Log Analytics** | `law-mlops-[user]-[random]` | 5 GB gratuit/mois |
| **Container Apps Env** | `env-mlops-workshop` | Connecté à Log Analytics |
| **Container App** | `bank-churn` | 1 réplica, port 8000, HTTPS |

**Coût mensuel estimé** : 3-6€
- ACR Basic : 0.50€
- Container Apps : 2-5€
- Log Analytics : Gratuit

---

## 🔧 COMMANDES DE DIAGNOSTIC

### Voir les logs en temps réel

```powershell
# Via fonction PowerShell
Get-AzureLogs

# Ou avec Azure CLI
az containerapp logs show `
  --name bank-churn `
  --resource-group rg-mlops-bank-churn `
  --tail 100 --follow
```

### Vérifier l'état de l'application

```powershell
az containerapp show `
  --name bank-churn `
  --resource-group rg-mlops-bank-churn `
  --query "{Status:properties.provisioningState, URL:properties.configuration.ingress.fqdn}" `
  -o json
```

### Mettre à jour l'application

Après modification du code :

```powershell
Deploy-ToAzure  # Détecte automatiquement et met à jour
```

### Supprimer toutes les ressources

```powershell
Remove-AzureResources  # Avec confirmation
```

Ou directement :

```powershell
az group delete --name rg-mlops-bank-churn --yes --no-wait
```

---

## ⚠️ DÉPANNAGE COURANT

### Problème : "Non connecté à Azure"

**Solution** :
```powershell
az logout
az login
```

### Problème : "Docker n'est pas accessible"

**Solution** :
1. Démarrer Docker Desktop
2. Attendre que Docker soit complètement démarré
3. Ouvrir un nouveau terminal PowerShell
4. Relancer `Deploy-ToAzure`

### Problème : Nom ACR déjà pris

**Solution** :
Le script génère automatiquement un nom unique basé sur votre username Windows. Si problème, modifiez manuellement dans `commands.ps1` :

```powershell
$ACR_NAME = "mlops$(Get-Random -Maximum 999999)"
```

### Problème : "ContainerApp provisioning failed"

**Diagnostic** :
```powershell
Get-AzureLogs
```

**Causes courantes** :
- Image Docker non poussée : Vérifier avec `az acr repository list --name [ACR_NAME]`
- Credentials ACR incorrects : Vérifier admin enabled avec `az acr show --name [ACR_NAME] --query adminUserEnabled`
- Port incorrect : Vérifier que l'app écoute sur port 8000

---

## ✅ CHECKPOINT MODULE 4

Avant de passer au Module 5 (CI/CD), vérifiez :

- [ ] `az login` réussi
- [ ] `Deploy-ToAzure` terminé sans erreurs
- [ ] URL affichée dans le terminal
- [ ] `Test-AzureAPI` réussit les 2 tests
- [ ] Health check accessible dans le navigateur
- [ ] Swagger UI accessible et fonctionnel
- [ ] Logs visibles avec `Get-AzureLogs`
- [ ] Fichier `azure_url.txt` créé

---

## 📚 DOCUMENTATION DISPONIBLE

1. **MODULE4_GUIDE.md** - Documentation complète (70+ lignes)
   - Prérequis détaillés
   - Étapes pas à pas
   - Tests et validation
   - Dépannage avancé
   - Exercices pratiques

2. **MODULE4_QUICKSTART.md** - Démarrage rapide (3 commandes)
   - Guide condensé
   - Commandes essentielles
   - Checkpoint validation

3. **test_azure_api.ps1** - Script de test standalone
   - 6 tests automatiques
   - Affichage des résultats
   - URLs utiles

4. **commands.ps1** - Commandes PowerShell
   - `Deploy-ToAzure` : Déploiement complet
   - `Test-AzureAPI` : Tests automatiques
   - `Get-AzureLogs` : Logs Azure
   - `Remove-AzureResources` : Nettoyage

---

## 🎯 PROCHAINES ÉTAPES

### Module 5 : GitHub Actions CI/CD (30 min)

**Objectif** : Automatiser le déploiement avec Git push

**Actions requises** :
1. Créer repo GitHub
2. Créer Service Principal Azure
3. Configurer GitHub Secrets (AZURE_CREDENTIALS, ACR_NAME, etc.)
4. Push le code
5. Observer le workflow automatique

**Documentation** : [MANUAL_ACTIONS.md](bank-churn-mlops/MANUAL_ACTIONS.md#module-6--github-actions-cicd)

### Module 6 : Application Insights (25 min)

**Objectif** : Monitoring et alertes en production

**Actions requises** :
1. Créer Application Insights
2. Configurer Container App avec connection string
3. Générer du trafic avec `generate_production_data.py`
4. Configurer alertes de drift

**Documentation** : [MANUAL_ACTIONS.md](bank-churn-mlops/MANUAL_ACTIONS.md#module-7--application-insights)

---

## 📝 NOTES IMPORTANTES

- **Sécurité** : Admin ACR activé pour simplicité du workshop. En production, utiliser **Managed Identity**.
- **Scaling** : 1 réplica fixe. En production, configurer **autoscaling** (min 3 réplicas).
- **Région** : westeurope par défaut, fallback northeurope automatique.
- **HTTPS** : Certificat SSL géré automatiquement par Azure Container Apps.
- **Nom ACR** : Généré à partir de votre username Windows (alphanumérique minuscules).

---

## 🎉 RÉCAPITULATIF

### Ce qui est prêt :
✅ Script PowerShell complet et testé  
✅ Documentation exhaustive (3 fichiers)  
✅ Script de test standalone  
✅ Gestion d'erreurs et fallbacks  
✅ Commandes de diagnostic intégrées  
✅ Nettoyage automatique  

### Ce que vous devez faire :
1️⃣ `az login` (30 sec)  
2️⃣ `Deploy-ToAzure` (15-20 min)  
3️⃣ `Test-AzureAPI` (30 sec)  
4️⃣ Validation navigateur (2 min)  

**Temps total estimé : 20-25 minutes**

---

**🚀 VOUS ÊTES PRÊT POUR LE DÉPLOIEMENT AZURE ! 🎯**
