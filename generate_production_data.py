"""
Script pour générer des données de production avec drift
Pour tester la détection de drift dans le Module 7
"""
import pandas as pd
import numpy as np

np.random.seed(123)  # Different seed for drift
n_samples = 1000

# Créer des données avec un léger drift par rapport au training set
data = {
    # CreditScore: drift vers des scores plus bas
    'CreditScore': np.random.randint(250, 800, n_samples),  # Plus bas que 300-850
    
    # Age: drift vers des clients plus jeunes
    'Age': np.random.randint(20, 65, n_samples),  # Plus jeunes que 18-80
    
    # Tenure: drift vers moins d'ancienneté
    'Tenure': np.random.randint(0, 8, n_samples),  # Moins que 0-10
    
    # Balance: drift vers des soldes plus élevés
    'Balance': np.random.uniform(10000, 250000, n_samples),  # Plus élevé que 0-200000
    
    # NumOfProducts: drift vers plus de produits
    'NumOfProducts': np.random.randint(2, 5, n_samples),  # Commence à 2 au lieu de 1
    
    # HasCrCard: pas de drift majeur
    'HasCrCard': np.random.choice([0, 1], n_samples),
    
    # IsActiveMember: drift vers plus de membres inactifs
    'IsActiveMember': np.random.choice([0, 1], n_samples, p=[0.6, 0.4]),  # Plus d'inactifs
    
    # EstimatedSalary: drift vers des salaires plus élevés
    'EstimatedSalary': np.random.uniform(30000, 180000, n_samples),  # Plus élevé
    
    # Geography: drift vers plus d'Allemagne
    'Geography_Germany': np.random.choice([0, 1], n_samples, p=[0.3, 0.7]),  # Plus d'Allemagne
    'Geography_Spain': np.random.choice([0, 1], n_samples, p=[0.7, 0.3]),  # Moins d'Espagne
}

df = pd.DataFrame(data)

# Sauvegarder
df.to_csv('data/production_data.csv', index=False)

print(f"Production data created: {len(df)} samples")
print(f"\nStatistics comparison:")
print(f"CreditScore: mean={df['CreditScore'].mean():.1f} (training: ~575)")
print(f"Age: mean={df['Age'].mean():.1f} (training: ~49)")
print(f"Balance: mean={df['Balance'].mean():.1f} (training: ~100k)")
print(f"IsActiveMember: mean={df['IsActiveMember'].mean():.2f} (training: ~0.5)")
print(f"Geography_Germany: mean={df['Geography_Germany'].mean():.2f} (training: ~0.5)")
print(f"\n⚠️ Expected drift in: CreditScore, Age, Balance, IsActiveMember, Geography")
