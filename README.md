# 🏦 Bank Churn Prediction API - MLOps Workshop

[![Azure](https://img.shields.io/badge/Azure-Container_Apps-0078D4?logo=microsoft-azure)](https://azure.microsoft.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![MLflow](https://img.shields.io/badge/MLflow-0194E2?logo=mlflow&logoColor=white)](https://mlflow.org/)

API de prédiction de churn bancaire avec Machine Learning, déployée sur Azure avec toutes les bonnes pratiques MLOps.

---

## 📋 Table des Matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Utilisation Rapide](#-utilisation-rapide)
- [Modules du Workshop](#-modules-du-workshop)
- [Documentation Complète](#-documentation-complète)
- [Technologies](#-technologies)
- [Résultats](#-résultats)

---

## 🎯 Vue d'ensemble

### Le Problème
Une banque souhaite prédire quels clients risquent de partir (churn) pour proposer des actions de rétention ciblées.

### La Solution
Une API REST ML-powered déployée sur Azure avec :
- ✅ Modèle Random Forest entraîné avec MLflow
- ✅ API FastAPI conteneurisée avec Docker
- ✅ Déploiement automatisé sur Azure Container Apps
- ✅ CI/CD avec GitHub Actions
- ✅ Monitoring et drift detection avec Application Insights

### Dataset
- **10,000 clients** avec 10 features
- **Features** : CreditScore, Age, Tenure, Balance, NumOfProducts, etc.
- **Target** : Exited (0=reste, 1=part)
- **Taux de churn** : ~25%

---

## 🏗️ Architecture

### Architecture Complète
```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│   Dataset   │───▶│  ML Training │───▶│   MLflow    │───▶│  Model   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────┘
                                                                  │
                                                                  ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│   GitHub    │───▶│    Actions   │───▶│   Docker    │───▶│   ACR    │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────┘
                                                                  │
                                                                  ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│  Internet   │◀───│  Container   │◀───│ Application │◀───│  Monitor │
│             │    │     Apps     │    │  Insights   │    │          │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────┘
```

### Flux de Prédiction
```
Client → HTTPS → Container Apps → FastAPI → Model → JSON Response
                       ↓
              Application Insights (Logs, Metrics, Drift)
```

---

## 🚀 Installation

### Prérequis
- Python 3.9+
- Docker Desktop
- Azure CLI
- Git
- Compte Azure (Azure for Students)

### Setup Rapide
```powershell
# Cloner le projet
cd d:\cycleing\5eme\Azure MLOPS\bank-churn-mlops

# Créer l'environnement virtuel
python -m venv venv
.\venv\Scripts\Activate.ps1

# Installer les dépendances
pip install -r requirements.txt

# Utiliser les commandes PowerShell
. .\commands.ps1
Show-Help
```

---

## ⚡ Utilisation Rapide

### Option 1 : Workflow Complet Automatique
```powershell
# Charger les commandes PowerShell
. .\commands.ps1

# Exécuter tout le workflow (data → train → docker → test)
Run-FullWorkflow
```

### Option 2 : Étape par Étape

#### 1. Générer les Données
```powershell
python generate_data.py
# Output: Dataset cree : 10000 lignes, Taux de churn : 24.92%
```

#### 2. Entraîner le Modèle
```powershell
python train_model.py
# Output: Accuracy: 76.55%, ROC AUC: 77.75%

# Visualiser dans MLflow UI
mlflow ui --port 5000
# Ouvrir http://localhost:5000
```

#### 3. Lancer l'API Localement
```powershell
uvicorn app.main:app --reload --port 8000

# Dans un autre terminal
python test_api_local.py

# Ouvrir la doc interactive
# http://localhost:8000/docs
```

#### 4. Docker
```powershell
# Build
docker build -t bank-churn-api:v1 .

# Run
docker run -d -p 8080:8000 --name churn-api bank-churn-api:v1

# Test
curl http://localhost:8080/health

# Logs
docker logs churn-api

# Stop
docker stop churn-api
docker rm churn-api
```

---

## 📚 Modules du Workshop

### ✅ Module 1 : Entraînement du Modèle
- Génération de dataset synthétique
- Entraînement Random Forest avec MLflow
- Sauvegarde du modèle
- **Status** : ✅ Complété

### ✅ Module 2 : API FastAPI
- Création des endpoints REST
- Validation avec Pydantic
- Documentation Swagger automatique
- **Status** : ✅ Complété

### ✅ Module 3 : Conteneurisation Docker
- Dockerfile optimisé
- Build et test de l'image
- **Status** : ✅ Complété

### 🔜 Module 4 : Azure Container Registry
- Création ACR
- Push de l'image Docker
- **Voir** : [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)

### 🔜 Module 5 : Azure Container Apps
- Déploiement sur Azure
- Configuration scaling
- URL publique
- **Voir** : [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)

### 🔜 Module 6 : CI/CD GitHub Actions
- Pipeline de déploiement automatique
- Tests automatisés
- **Voir** : [.github/workflows/deploy.yml](.github/workflows/deploy.yml)

### 🔜 Module 7 : Monitoring & Drift Detection
- Application Insights
- Alertes de drift
- Dashboard de monitoring
- **Voir** : [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)

---

## 📖 Documentation Complète

### Fichiers de Documentation
- **[WORKSHOP_RESULTS.md](WORKSHOP_RESULTS.md)** - Résultats détaillés des modules 1-3
- **[MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)** - Actions manuelles pour modules 4-7
- **[commands.ps1](commands.ps1)** - Commandes PowerShell utiles

### API Endpoints

| Endpoint | Méthode | Description | Exemple |
|----------|---------|-------------|---------|
| `/` | GET | Info API | `curl http://localhost:8000/` |
| `/health` | GET | Health check | `curl http://localhost:8000/health` |
| `/predict` | POST | Prédiction simple | Voir ci-dessous |
| `/predict/batch` | POST | Prédiction batch | Documentation Swagger |
| `/drift/check` | POST | Détection drift | Documentation Swagger |
| `/model/info` | GET | Info modèle | `curl http://localhost:8000/model/info` |

### Exemple de Prédiction
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "CreditScore": 650,
    "Age": 35,
    "Tenure": 5,
    "Balance": 50000,
    "NumOfProducts": 2,
    "HasCrCard": 1,
    "IsActiveMember": 1,
    "EstimatedSalary": 75000,
    "Geography_Germany": 0,
    "Geography_Spain": 1
  }'
```

**Réponse** :
```json
{
  "churn_probability": 0.0036,
  "prediction": 0,
  "risk_level": "Low"
}
```

### Documentation Interactive
- **Swagger UI** : http://localhost:8000/docs
- **ReDoc** : http://localhost:8000/redoc

---

## 🔧 Technologies

### Machine Learning
- **scikit-learn 1.3.2** - Random Forest Classifier
- **MLflow 2.8.1** - Experiment tracking
- **pandas 2.1.3** - Data manipulation
- **numpy 1.26.2** - Numerical computing

### API & Web
- **FastAPI 0.104.1** - Modern web framework
- **Uvicorn 0.24.0** - ASGI server
- **Pydantic 2.5.0** - Data validation

### DevOps & Cloud
- **Docker** - Containerization
- **Azure Container Apps** - Serverless containers
- **Azure Container Registry** - Image registry
- **GitHub Actions** - CI/CD pipeline
- **Application Insights** - Monitoring

### Monitoring & Drift
- **scipy 1.11.4** - Statistical tests (Kolmogorov-Smirnov)
- **opencensus-ext-azure 1.1.9** - Application Insights integration

---

## 📊 Résultats

### Métriques du Modèle
| Métrique | Valeur |
|----------|--------|
| **Accuracy** | **76.55%** ✅ |
| Precision | 57.21% |
| Recall | 23.09% |
| F1 Score | 32.90% |
| ROC AUC | 77.75% |

### Performance API (Local)
- **Temps de réponse** : ~50-100ms
- **Health check** : ✅ Opérationnel
- **Prédictions** : ✅ Fonctionnelles

### Docker
- **Image size** : 1.16 GB
- **Build time** : ~2 minutes
- **Startup time** : ~3 secondes

---

## 🎯 Prochaines Étapes

1. **Déployer sur Azure** - Suivre [MANUAL_ACTIONS.md](MANUAL_ACTIONS.md)
2. **Configurer CI/CD** - GitHub Actions automatique
3. **Activer le monitoring** - Application Insights
4. **Tester le drift** - Générer données de production

---

## 📝 Commandes PowerShell Utiles

```powershell
# Charger les commandes
. .\commands.ps1

# Voir l'aide
Show-Help

# Setup complet
Setup-Environment

# Workflow complet
Run-FullWorkflow

# Déploiement Azure
Deploy-ToAzure

# Nettoyage
Clean-All
```

---

## 🤝 Contribution

Ce projet est un workshop éducatif. Les contributions sont les bienvenues :
1. Fork le projet
2. Créer une branche (`git checkout -b feature/amélioration`)
3. Commit (`git commit -m 'Ajout amélioration'`)
4. Push (`git push origin feature/amélioration`)
5. Créer une Pull Request

---

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

---

## 👨‍💻 Auteur

**Workshop MLOps Azure**
- Date : Janvier 2026
- Framework : MLOps Best Practices

---

## ⚠️ Notes Importantes

### Coûts Azure
- Container Apps : ~2-5€/mois
- Container Registry : ~0.50€/mois
- Application Insights : Gratuit (5GB/mois)
- **Total** : 3-6€/mois

### Nettoyage
```powershell
# Supprimer les ressources Azure
az group delete --name rg-bank-churn-mlops --yes --no-wait

# Supprimer les conteneurs locaux
docker stop churn-api
docker rm churn-api
docker rmi bank-churn-api:v1
```

---

**🚀 Bon workshop MLOps !**
