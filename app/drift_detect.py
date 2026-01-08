import pandas as pd
import numpy as np
from scipy import stats
import os
from typing import Union, List, Dict, Any


def detect_drift_from_dataframes(
    df_ref: pd.DataFrame, 
    df_prod: pd.DataFrame, 
    threshold: float = 0.05
) -> Dict[str, Any]:
    """
    Detecte le data drift entre deux DataFrames
    
    Args:
        df_ref: DataFrame de reference
        df_prod: DataFrame de production
        threshold: Seuil de p-value pour detecter le drift (defaut: 0.05)
    
    Returns:
        dict: Resultats du test de drift pour chaque feature
    """
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
        
        if len(prod_data) == 0:
            continue
        
        # Test de Kolmogorov-Smirnov pour les variables continues
        if df_ref[column].dtype in ['float64', 'int64']:
            statistic, p_value = stats.ks_2samp(ref_data, prod_data)
            
            results[column] = {
                "drift_detected": bool(p_value < threshold),
                "p_value": float(round(p_value, 6)),
                "statistic": float(round(statistic, 6)),
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
            
            # Avoid division by zero
            if ref_aligned.sum() == 0:
                continue
                
            statistic, p_value = stats.chisquare(prod_aligned, ref_aligned)
            
            results[column] = {
                "drift_detected": bool(p_value < threshold),
                "p_value": float(round(p_value, 6)),
                "statistic": float(round(statistic, 6)),
                "type": "categorical"
            }
    
    return results


def detect_drift(
    reference_file: str, 
    production_file: str = None,
    production_data: List[Dict] = None,
    threshold: float = 0.05
) -> Dict[str, Any]:
    """
    Detecte le data drift entre un dataset de reference et un dataset de production
    
    Args:
        reference_file: Chemin vers le fichier de reference (train data)
        production_file: Chemin vers le fichier de production (optionnel)
        production_data: Liste de dictionnaires avec les donnees de production (optionnel)
        threshold: Seuil de p-value pour detecter le drift (defaut: 0.05)
    
    Returns:
        dict: Resultats du test de drift pour chaque feature
    """
    
    # Charger le fichier de reference
    if not os.path.exists(reference_file):
        raise FileNotFoundError(f"Reference file not found: {reference_file}")
    
    df_ref = pd.read_csv(reference_file)
    
    # Obtenir le DataFrame de production
    if production_data is not None and len(production_data) > 0:
        # Utiliser les donnees fournies dans la requete
        df_prod = pd.DataFrame(production_data)
    elif production_file is not None:
        if not os.path.exists(production_file):
            raise FileNotFoundError(f"Production file not found: {production_file}")
        df_prod = pd.read_csv(production_file)
    else:
        raise ValueError("Either production_file or production_data must be provided")
    
    return detect_drift_from_dataframes(df_ref, df_prod, threshold)
