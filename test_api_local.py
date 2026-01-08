"""
Script de test pour l'API Bank Churn
"""
import requests
import json

# URL de l'API
BASE_URL = "http://localhost:8000"

def test_health():
    """Test du health check"""
    print("Testing /health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
    print("-" * 50)

def test_predict():
    """Test de prediction simple"""
    print("Testing /predict endpoint...")
    
    data = {
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
    }
    
    response = requests.post(f"{BASE_URL}/predict", json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print("-" * 50)

def test_predict_batch():
    """Test de prediction batch"""
    print("Testing /predict/batch endpoint...")
    
    data = [
        {
            "CreditScore": 700,
            "Age": 40,
            "Tenure": 7,
            "Balance": 80000,
            "NumOfProducts": 3,
            "HasCrCard": 1,
            "IsActiveMember": 0,
            "EstimatedSalary": 90000,
            "Geography_Germany": 1,
            "Geography_Spain": 0
        },
        {
            "CreditScore": 500,
            "Age": 25,
            "Tenure": 2,
            "Balance": 10000,
            "NumOfProducts": 1,
            "HasCrCard": 0,
            "IsActiveMember": 1,
            "EstimatedSalary": 40000,
            "Geography_Germany": 0,
            "Geography_Spain": 0
        }
    ]
    
    response = requests.post(f"{BASE_URL}/predict/batch", json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print("-" * 50)

def test_model_info():
    """Test de l'endpoint model info"""
    print("Testing /model/info endpoint...")
    response = requests.get(f"{BASE_URL}/model/info")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print("-" * 50)

if __name__ == "__main__":
    print("="*50)
    print("BANK CHURN API - LOCAL TESTS")
    print("="*50)
    print()
    
    try:
        test_health()
        test_predict()
        test_predict_batch()
        test_model_info()
        
        print("✅ All tests completed!")
    except requests.exceptions.ConnectionError:
        print("❌ Error: Cannot connect to API. Make sure it's running on http://localhost:8000")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
