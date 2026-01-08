import pandas as pd
import numpy as np
from scipy import stats
import os

def detect_drift(reference_file: str, production_file: str, threshold: float = 0.05):
    """
    Detecte le data drift entre un dataset de reference et un dataset de production
    
    Args:
        reference_file: Chemin vers le fichier de reference (train data)
        production_file: Chemin vers le fichier de production (nouvelles donnees)
        threshold: Seuil de p-value pour detecter le drift (defaut: 0.05)
    
    Returns:
        dict: Resultats du test de drift pour chaque feature
    """
    
    # Charger les datasets
    if not os.path.exists(reference_file):
        raise FileNotFoundError(f"Reference file not found: {reference_file}")
    
    if not os.path.exists(production_file):
        raise FileNotFoundError(f"Production file not found: {production_file}")
    
    df_ref = pd.read_csv(reference_file)
    df_prod = pd.read_csv(production_file)
    
    # Enlever la colonne target si presente
    if 'Exited' in df_ref.columns:
        df_ref = df_ref.drop('Exited', axis=1)
    if 'Exited' in df_prod.columns:
        df_prod = df_prod.drop('Exited', axis=1)
    
    results = {}
    
    for column in df_ref.columns:
        if column not in df_prod.columns:
            continue
        
        ref_data = df_ref[column].dropna()
        prod_data = df_prod[column].dropna()
        
        # Test de Kolmogorov-Smirnov pour les variables continues
        if df_ref[column].dtype in ['float64', 'int64']:
            statistic, p_value = stats.ks_2samp(ref_data, prod_data)
            
            results[column] = {
                "drift_detected": p_value < threshold,
                "p_value": p_value,
                "statistic": statistic,
                "type": "continuous"
            }
        else:
            # Chi-square test pour les variables categorielles
            ref_counts = ref_data.value_counts()
            prod_counts = prod_data.value_counts()
            
            # Aligner les index
            all_categories = set(ref_counts.index) | set(prod_counts.index)
            ref_aligned = pd.Series([ref_counts.get(cat, 0) for cat in all_categories])
            prod_aligned = pd.Series([prod_counts.get(cat, 0) for cat in all_categories])
            
            statistic, p_value = stats.chisquare(prod_aligned, ref_aligned)
            
            results[column] = {
                "drift_detected": p_value < threshold,
                "p_value": p_value,
                "statistic": statistic,
                "type": "categorical"
            }
    
    return results
