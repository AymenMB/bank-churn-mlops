# ⚡ MODULE 4 - DÉMARRAGE RAPIDE

## 🎯 Déploiement Azure en 3 commandes

### 1️⃣ Se connecter à Azure (30 secondes)

```powershell
az login
```

### 2️⃣ Déployer automatiquement (15-20 minutes)

```powershell
cd "d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops"
. .\commands.ps1
Deploy-ToAzure
```

### 3️⃣ Tester l'API déployée

```powershell
Test-AzureAPI
```

---

## ✅ CE QUI EST FAIT AUTOMATIQUEMENT

Le script `Deploy-ToAzure` exécute automatiquement :

1. ✅ Installation extension Azure CLI `containerapp`
2. ✅ Enregistrement des providers Azure
3. ✅ Création Resource Group `rg-mlops-bank-churn`
4. ✅ Création Container Registry (ACR) avec nom unique
5. ✅ Build et push image Docker vers ACR
6. ✅ Création Log Analytics Workspace
7. ✅ Création Container Apps Environment
8. ✅ Déploiement Container App `bank-churn`
9. ✅ Récupération URL publique (sauvegardée dans `azure_url.txt`)

**Durée totale** : 15-20 minutes

---

## 🧪 TESTS ET VALIDATION

### Tester avec PowerShell

```powershell
Test-AzureAPI  # Test automatique complet
```

### Tester avec le navigateur

Ouvrez l'URL affichée dans le terminal :

- **Health** : `https://[URL]/health`
- **Swagger UI** : `https://[URL]/docs`
- **Redoc** : `https://[URL]/redoc`

### Voir les logs

```powershell
Get-AzureLogs  # 50 dernières lignes
```

---

## 📋 COMMANDES UTILES

| Commande | Description |
|----------|-------------|
| `Deploy-ToAzure` | Déployer sur Azure (ou mettre à jour) |
| `Test-AzureAPI` | Tester l'API déployée |
| `Get-AzureLogs` | Voir les logs de l'application |
| `Remove-AzureResources` | Supprimer toutes les ressources |

---

## 🔧 DÉPANNAGE RAPIDE

### Problème : "Non connecté à Azure"

```powershell
az logout
az login
```

### Problème : "Docker n'est pas accessible"

1. Démarrer Docker Desktop
2. Ouvrir un nouveau terminal PowerShell
3. Relancer `Deploy-ToAzure`

### Problème : Voir les logs d'erreur

```powershell
Get-AzureLogs
# Ou en temps réel
az containerapp logs show --name bank-churn --resource-group rg-mlops-bank-churn --tail 100 --follow
```

---

## 💰 COÛTS

**Estimation mensuelle** : 3-6€
- Container Registry Basic : 0.50€
- Container Apps (1 réplica) : 2-5€
- Log Analytics : Gratuit (5GB/mois)

**Supprimer pour éviter les frais** :

```powershell
Remove-AzureResources
```

---

## ✅ CHECKPOINT

Avant de passer au Module 5, vérifiez :

- [ ] `Deploy-ToAzure` a réussi sans erreurs
- [ ] URL affichée dans le terminal
- [ ] Health check : `https://[URL]/health` retourne 200 OK
- [ ] Swagger UI accessible : `https://[URL]/docs`
- [ ] `Test-AzureAPI` réussit les 2 tests
- [ ] Logs visibles avec `Get-AzureLogs`

---

## 📚 DOCUMENTATION COMPLÈTE

Pour plus de détails : [MODULE4_GUIDE.md](MODULE4_GUIDE.md)

---

## ➡️ PROCHAINE ÉTAPE

**Module 5 : GitHub Actions CI/CD**

Automatiser le déploiement avec chaque commit Git.

Voir : [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)
