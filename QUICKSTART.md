# 🎯 QUICK START - Bank Churn MLOps

## ✅ CE QUI EST FAIT (Automatique)

**Modules 1-3 : COMPLÉTÉS** ✅

```powershell
cd "d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops"

# Tout est prêt ! Charger les commandes :
. .\commands.ps1

# Tester le workflow complet :
Run-FullWorkflow
```

**Résultats** :
- ✅ Modèle entraîné : Accuracy 76.55%
- ✅ API FastAPI : http://localhost:8000/docs
- ✅ Docker : Image `bank-churn-api:v1` fonctionnelle

---

## 📋 CE QU'IL RESTE À FAIRE (Manuel)

### Module 4 : Azure Container Registry (15 min)
```powershell
az login
. .\commands.ps1
Deploy-ToAzure
```

### Module 5 : Container Apps (20 min)
Voir [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md#module-5--azure-container-apps)

### Module 6 : CI/CD GitHub (30 min)
1. Créer repo GitHub
2. Configurer secrets
3. Push le code

Voir [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md#module-6--github-actions-cicd)

### Module 7 : Monitoring (25 min)
```powershell
az monitor app-insights component create ...
```
Voir [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md#module-7--application-insights)

---

## 📚 DOCUMENTATION

| Fichier | Description |
|---------|-------------|
| [README.md](README.md) | Documentation complète |
| [STATUS.md](STATUS.md) | État détaillé du projet |
| [WORKSHOP_RESULTS.md](WORKSHOP_RESULTS.md) | Résultats modules 1-3 |
| [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md) | Guide modules 4-7 |
| [commands.ps1](commands.ps1) | Commandes PowerShell |

---

## 🚀 COMMANDES ESSENTIELLES

```powershell
# Charger les commandes
. .\commands.ps1

# Aide
Show-Help

# Workflow complet (modules 1-3)
Run-FullWorkflow

# Déployer sur Azure (modules 4-5)
Deploy-ToAzure

# Nettoyer
Clean-All
```

---

## 🎯 PROGRESSION

**Total** : 3/7 modules (43%)

- ✅ Module 1 : ML Training
- ✅ Module 2 : FastAPI
- ✅ Module 3 : Docker
- 🔜 Module 4 : ACR
- 🔜 Module 5 : Container Apps
- 🔜 Module 6 : CI/CD
- 🔜 Module 7 : Monitoring

**Temps restant estimé** : 1h30-2h

---

**Prêt pour Azure ! 🚀**
