from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
import joblib
import numpy as np
import logging
import os

from app.models import CustomerFeatures, PredictionResponse, HealthResponse
from app.drift_detect import detect_drift

# ============================================================
# LOGGING SETUP
# ============================================================

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("bank-churn-api")

# Application Insights connection (optional)
APPINSIGHTS_CONN = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
if APPINSIGHTS_CONN:
    try:
        from opencensus.ext.azure.log_exporter import AzureLogHandler
        handler = AzureLogHandler(connection_string=APPINSIGHTS_CONN)
        logger.addHandler(handler)
        logger.info("Application Insights connected")
    except ImportError:
        logger.warning("opencensus-ext-azure not installed, skipping Application Insights")

# ============================================================
# FASTAPI INITIALIZATION
# ============================================================

app = FastAPI(
    title="Bank Churn Prediction API",
    description="API de prediction et monitoring du churn client",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_PATH = os.getenv("MODEL_PATH", "model/churn_model.pkl")
model = None

# ============================================================
# STARTUP EVENT
# ============================================================

@app.on_event("startup")
async def load_model():
    """Charge le modele au demarrage de l'API"""
    global model
    try:
        model = joblib.load(MODEL_PATH)
        logger.info(f"Model loaded successfully from {MODEL_PATH}")
    except Exception as e:
        logger.error(f"Failed to load model: {str(e)}")
        model = None

# ============================================================
# GENERAL ENDPOINTS
# ============================================================

@app.get("/", tags=["General"])
def root():
    """Endpoint racine"""
    return {
        "message": "Bank Churn Prediction API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

@app.get("/health", response_model=HealthResponse, tags=["General"])
def health():
    """Health check endpoint"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "model_loaded": True}

# ============================================================
# PREDICTION ENDPOINTS
# ============================================================

@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(features: CustomerFeatures):
    """
    Prediction de churn pour un seul client
    
    Returns:
        PredictionResponse: Probabilite de churn, prediction binaire, et niveau de risque
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model unavailable")

    try:
        # Preparer les donnees d'entree
        input_data = np.array([[  
            features.CreditScore,
            features.Age,
            features.Tenure,
            features.Balance,
            features.NumOfProducts,
            features.HasCrCard,
            features.IsActiveMember,
            features.EstimatedSalary,
            features.Geography_Germany,
            features.Geography_Spain
        ]])

        # Prediction
        proba = float(model.predict_proba(input_data)[0][1])
        prediction = int(proba > 0.5)

        # Niveau de risque
        risk = "Low" if proba < 0.3 else "Medium" if proba < 0.7 else "High"

        logger.info(f"Prediction made: probability={proba:.4f}, risk={risk}")

        return {
            "churn_probability": round(proba, 4),
            "prediction": prediction,
            "risk_level": risk
        }

    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict/batch", tags=["Prediction"])
def predict_batch(features_list: List[CustomerFeatures]):
    """
    Prediction de churn pour plusieurs clients
    
    Returns:
        dict: Liste des predictions avec compteur
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model unavailable")

    try:
        predictions = []

        for features in features_list:
            input_data = np.array([[  
                features.CreditScore,
                features.Age,
                features.Tenure,
                features.Balance,
                features.NumOfProducts,
                features.HasCrCard,
                features.IsActiveMember,
                features.EstimatedSalary,
                features.Geography_Germany,
                features.Geography_Spain
            ]])

            proba = float(model.predict_proba(input_data)[0][1])
            prediction = int(proba > 0.5)
            risk = "Low" if proba < 0.3 else "Medium" if proba < 0.7 else "High"

            predictions.append({
                "churn_probability": round(proba, 4),
                "prediction": prediction,
                "risk_level": risk
            })

        logger.info(f"Batch prediction: {len(predictions)} predictions made")

        return {
            "predictions": predictions,
            "count": len(predictions)
        }

    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================
# DRIFT DETECTION ENDPOINTS
# ============================================================

@app.post("/drift/check", tags=["Monitoring"])
def check_drift(threshold: float = 0.05):
    """
    Verifie le data drift entre les donnees de reference et de production
    
    Args:
        threshold: Seuil de p-value pour detecter le drift (defaut: 0.05)
    
    Returns:
        dict: Resultats du test de drift
    """
    try:
        results = detect_drift(
            reference_file="data/bank_churn.csv",
            production_file="data/production_data.csv",
            threshold=threshold
        )

        drifted_features = [
            feature for feature, result in results.items() 
            if result["drift_detected"]
        ]

        logger.warning(f"Drift detection: {len(drifted_features)} features drifted")

        return {
            "status": "success",
            "features_analyzed": len(results),
            "features_drifted": len(drifted_features),
            "drifted_features": drifted_features,
            "details": results
        }

    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Drift check error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/model/info", tags=["Model"])
def model_info():
    """Retourne des informations sur le modele charge"""
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return {
        "model_type": type(model).__name__,
        "n_features": model.n_features_in_,
        "n_classes": len(model.classes_),
        "model_path": MODEL_PATH
    }
