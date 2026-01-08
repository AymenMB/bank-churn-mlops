"""
ChurnGuard AI - Enterprise Bank Customer Analytics
A clean, professional Streamlit frontend with modern light theme
"""

import streamlit as st
import requests
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import json
import time
from datetime import datetime

# ==================== Configuration ====================
API_BASE_URL = "https://churn-api.salmonfield-cb3d4cec.francecentral.azurecontainerapps.io"

# Page configuration
st.set_page_config(
    page_title="ChurnGuard AI | Enterprise Analytics",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ==================== Professional Light Theme CSS ====================
st.markdown("""
<style>
    /* ============ Import Google Fonts ============ */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');
    
    /* ============ Root Variables ============ */
    :root {
        --primary: #4f46e5;
        --primary-light: #6366f1;
        --primary-dark: #3730a3;
        --secondary: #7c3aed;
        --accent: #0ea5e9;
        --success: #10b981;
        --warning: #f59e0b;
        --danger: #ef4444;
        --bg-primary: #ffffff;
        --bg-secondary: #f8fafc;
        --bg-tertiary: #f1f5f9;
        --bg-card: #ffffff;
        --border-light: #e2e8f0;
        --border-medium: #cbd5e1;
        --text-primary: #0f172a;
        --text-secondary: #475569;
        --text-muted: #64748b;
        --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
        --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }
    
    /* ============ Hide Streamlit Defaults ============ */
    #MainMenu, footer, header {visibility: hidden;}
    .stDeployButton {display: none;}
    
    /* ============ Global Styles ============ */
    .stApp {
        background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
    }
    
    /* ============ Typography ============ */
    h1, h2, h3, h4, h5, h6, p, span, div, label {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif !important;
        color: var(--text-primary);
    }
    
    /* ============ Hero Header ============ */
    .hero-container {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 50%, #0ea5e9 100%);
        border-radius: 20px;
        padding: 2.5rem;
        margin-bottom: 2rem;
        position: relative;
        overflow: hidden;
        box-shadow: 0 20px 40px rgba(79, 70, 229, 0.25);
    }
    
    .hero-container::before {
        content: '';
        position: absolute;
        top: 0;
        right: 0;
        width: 40%;
        height: 100%;
        background: url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E") repeat;
        opacity: 0.5;
    }
    
    .hero-title {
        font-size: 2.5rem;
        font-weight: 800;
        color: #ffffff;
        margin: 0;
        letter-spacing: -0.02em;
        text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }
    
    .hero-subtitle {
        font-size: 1.1rem;
        color: rgba(255, 255, 255, 0.9);
        margin-top: 0.5rem;
        font-weight: 400;
    }
    
    .hero-badge {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        background: rgba(255, 255, 255, 0.2);
        backdrop-filter: blur(10px);
        border: 1px solid rgba(255, 255, 255, 0.3);
        color: #ffffff;
        padding: 0.5rem 1rem;
        border-radius: 50px;
        font-size: 0.85rem;
        font-weight: 500;
        margin-top: 1rem;
    }
    
    .hero-badge-dot {
        width: 8px;
        height: 8px;
        background: #22c55e;
        border-radius: 50%;
        animation: pulse 2s infinite;
        box-shadow: 0 0 10px #22c55e;
    }
    
    @keyframes pulse {
        0%, 100% { opacity: 1; transform: scale(1); }
        50% { opacity: 0.7; transform: scale(1.3); }
    }
    
    /* ============ Card Styles ============ */
    .card {
        background: #ffffff;
        border: 1px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
        transition: all 0.3s ease;
    }
    
    .card:hover {
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        transform: translateY(-2px);
    }
    
    .card-elevated {
        background: #ffffff;
        border: none;
        border-radius: 20px;
        padding: 2rem;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    }
    
    /* ============ Section Headers ============ */
    .section-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        margin-bottom: 1.5rem;
        padding-bottom: 1rem;
        border-bottom: 2px solid #f1f5f9;
    }
    
    .section-icon {
        width: 48px;
        height: 48px;
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.4rem;
        box-shadow: 0 4px 12px rgba(79, 70, 229, 0.3);
    }
    
    .section-title {
        font-size: 1.25rem;
        font-weight: 700;
        color: #0f172a;
        margin: 0;
    }
    
    .section-subtitle {
        font-size: 0.9rem;
        color: #64748b;
        margin-top: 0.25rem;
    }
    
    /* ============ Form Labels ============ */
    .form-label {
        font-size: 0.875rem;
        font-weight: 600;
        color: #374151;
        margin-bottom: 0.5rem;
        display: block;
    }
    
    .form-section-title {
        font-size: 0.75rem;
        font-weight: 700;
        color: #4f46e5;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        margin-bottom: 1rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }
    
    /* ============ Input Styling ============ */
    .stSlider > div > div > div {
        background: linear-gradient(90deg, #4f46e5, #0ea5e9) !important;
    }
    
    .stSlider > div > div > div > div {
        background: #ffffff !important;
        border: 2px solid #4f46e5 !important;
        box-shadow: 0 2px 8px rgba(79, 70, 229, 0.3) !important;
    }
    
    .stSelectbox > div > div {
        background: #ffffff !important;
        border: 2px solid #e2e8f0 !important;
        border-radius: 12px !important;
        transition: border-color 0.2s ease;
    }
    
    .stSelectbox > div > div:hover {
        border-color: #4f46e5 !important;
    }
    
    .stNumberInput > div > div > input {
        background: #ffffff !important;
        border: 2px solid #e2e8f0 !important;
        border-radius: 12px !important;
        color: #0f172a !important;
        font-weight: 500 !important;
    }
    
    .stNumberInput > div > div > input:focus {
        border-color: #4f46e5 !important;
        box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1) !important;
    }
    
    /* ============ Premium Button ============ */
    .stButton > button {
        background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%) !important;
        color: white !important;
        border: none !important;
        padding: 0.875rem 2rem !important;
        border-radius: 12px !important;
        font-weight: 600 !important;
        font-size: 1rem !important;
        letter-spacing: 0.01em !important;
        transition: all 0.3s ease !important;
        box-shadow: 0 4px 14px rgba(79, 70, 229, 0.4) !important;
    }
    
    .stButton > button:hover {
        transform: translateY(-2px) !important;
        box-shadow: 0 8px 20px rgba(79, 70, 229, 0.5) !important;
    }
    
    .stButton > button:active {
        transform: translateY(0) !important;
    }
    
    /* ============ Result Cards ============ */
    .result-card {
        background: #ffffff;
        border-radius: 16px;
        padding: 1.5rem;
        text-align: center;
        border: 2px solid #e2e8f0;
        transition: all 0.3s ease;
    }
    
    .result-card:hover {
        border-color: #4f46e5;
        box-shadow: 0 8px 20px rgba(79, 70, 229, 0.1);
    }
    
    .risk-low { 
        background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
        border-color: #10b981 !important;
    }
    
    .risk-medium { 
        background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
        border-color: #f59e0b !important;
    }
    
    .risk-high { 
        background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
        border-color: #ef4444 !important;
    }
    
    /* ============ Metric Cards ============ */
    .metric-card {
        background: #ffffff;
        border: 2px solid #e2e8f0;
        border-radius: 16px;
        padding: 1.5rem;
        text-align: center;
        transition: all 0.3s ease;
    }
    
    .metric-card:hover {
        border-color: #4f46e5;
        box-shadow: 0 10px 20px rgba(0, 0, 0, 0.08);
        transform: translateY(-4px);
    }
    
    .metric-value {
        font-size: 2.5rem;
        font-weight: 800;
        color: #0f172a;
        line-height: 1;
    }
    
    .metric-label {
        font-size: 0.8rem;
        color: #64748b;
        margin-top: 0.5rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        font-weight: 600;
    }
    
    /* ============ Status Badges ============ */
    .status-online {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        background: #ecfdf5;
        border: 1px solid #10b981;
        color: #059669;
        padding: 0.5rem 1rem;
        border-radius: 50px;
        font-size: 0.85rem;
        font-weight: 600;
    }
    
    .status-offline {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        background: #fef2f2;
        border: 1px solid #ef4444;
        color: #dc2626;
        padding: 0.5rem 1rem;
        border-radius: 50px;
        font-size: 0.85rem;
        font-weight: 600;
    }
    
    /* ============ Sidebar Styling ============ */
    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%) !important;
        border-right: 1px solid #e2e8f0 !important;
    }
    
    [data-testid="stSidebar"] > div:first-child {
        background: transparent !important;
    }
    
    /* ============ Radio Buttons ============ */
    .stRadio > div {
        gap: 0.5rem;
    }
    
    .stRadio > div > label {
        background: #f8fafc;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        padding: 0.5rem 1rem;
        transition: all 0.2s ease;
    }
    
    .stRadio > div > label:hover {
        border-color: #4f46e5;
        background: #f5f3ff;
    }
    
    /* ============ Expander ============ */
    .streamlit-expanderHeader {
        background: #f8fafc !important;
        border: 1px solid #e2e8f0 !important;
        border-radius: 12px !important;
        font-weight: 600 !important;
    }
    
    .streamlit-expanderContent {
        border: 1px solid #e2e8f0 !important;
        border-top: none !important;
        border-radius: 0 0 12px 12px !important;
    }
    
    /* ============ Data Table ============ */
    .stDataFrame {
        border: 1px solid #e2e8f0 !important;
        border-radius: 12px !important;
        overflow: hidden !important;
    }
    
    /* ============ File Uploader ============ */
    [data-testid="stFileUploader"] {
        background: #f8fafc !important;
        border: 2px dashed #cbd5e1 !important;
        border-radius: 16px !important;
        padding: 2rem !important;
        transition: all 0.2s ease;
    }
    
    [data-testid="stFileUploader"]:hover {
        border-color: #4f46e5 !important;
        background: #f5f3ff !important;
    }
    
    /* ============ Progress Bar ============ */
    .stProgress > div > div > div > div {
        background: linear-gradient(90deg, #4f46e5, #7c3aed) !important;
    }
    
    /* ============ Alerts ============ */
    .stAlert {
        border-radius: 12px !important;
    }
    
    /* ============ Scrollbar ============ */
    ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
    }
    
    ::-webkit-scrollbar-track {
        background: #f1f5f9;
    }
    
    ::-webkit-scrollbar-thumb {
        background: linear-gradient(180deg, #4f46e5, #7c3aed);
        border-radius: 4px;
    }
    
    /* ============ Info Box ============ */
    .info-box {
        background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
        border: 1px solid #3b82f6;
        border-radius: 12px;
        padding: 1rem 1.25rem;
        color: #1e40af;
        font-size: 0.9rem;
    }
    
    /* ============ Endpoint Pills ============ */
    .endpoint-pill {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem 1rem;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 10px;
        margin-bottom: 0.5rem;
        font-family: 'Monaco', 'Menlo', monospace;
        font-size: 0.85rem;
    }
    
    .method-get {
        background: #ecfdf5;
        color: #059669;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-weight: 700;
        font-size: 0.7rem;
    }
    
    .method-post {
        background: #fef3c7;
        color: #d97706;
        padding: 0.25rem 0.5rem;
        border-radius: 6px;
        font-weight: 700;
        font-size: 0.7rem;
    }
</style>
""", unsafe_allow_html=True)

# ==================== Helper Functions ====================

def check_api_health():
    """Check API health status"""
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            return True, response.json()
        return False, None
    except Exception as e:
        return False, str(e)

def make_prediction(features: dict):
    """Make a single prediction"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/predict",
            json=features,
            timeout=30
        )
        if response.status_code == 200:
            return True, response.json()
        return False, response.text
    except Exception as e:
        return False, str(e)

def make_batch_prediction(data: list):
    """Make batch predictions"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/predict/batch",
            json={"customers": data},
            timeout=60
        )
        if response.status_code == 200:
            return True, response.json()
        return False, response.text
    except Exception as e:
        return False, str(e)

def check_drift(data: list):
    """Check for data drift"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/drift/check",
            json={"samples": data},
            timeout=30
        )
        if response.status_code == 200:
            return True, response.json()
        return False, response.text
    except Exception as e:
        return False, str(e)

def get_risk_colors(risk_level: str):
    """Get colors based on risk level"""
    colors = {
        "Low": ("#10b981", "#ecfdf5", "#059669"),
        "Medium": ("#f59e0b", "#fffbeb", "#d97706"),
        "High": ("#ef4444", "#fef2f2", "#dc2626")
    }
    return colors.get(risk_level, ("#4f46e5", "#eff6ff", "#3730a3"))

def create_gauge_chart(probability: float, risk_level: str):
    """Create a clean gauge chart"""
    main_color, bg_color, dark_color = get_risk_colors(risk_level)
    
    fig = go.Figure(go.Indicator(
        mode="gauge+number",
        value=probability * 100,
        number={
            'suffix': '%',
            'font': {'size': 48, 'color': '#0f172a', 'family': 'Inter'}
        },
        gauge={
            'axis': {
                'range': [0, 100],
                'tickwidth': 2,
                'tickcolor': '#cbd5e1',
                'tickfont': {'color': '#64748b', 'size': 11},
                'tickmode': 'array',
                'tickvals': [0, 25, 50, 75, 100],
                'ticktext': ['0%', '25%', '50%', '75%', '100%']
            },
            'bar': {'color': main_color, 'thickness': 0.8},
            'bgcolor': '#f1f5f9',
            'borderwidth': 0,
            'steps': [
                {'range': [0, 30], 'color': '#ecfdf5'},
                {'range': [30, 60], 'color': '#fffbeb'},
                {'range': [60, 100], 'color': '#fef2f2'}
            ],
            'threshold': {
                'line': {'color': dark_color, 'width': 4},
                'thickness': 0.85,
                'value': probability * 100
            }
        },
        domain={'x': [0, 1], 'y': [0, 1]}
    ))
    
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        height=280,
        margin=dict(l=30, r=30, t=40, b=20),
        font={'family': 'Inter'}
    )
    
    return fig

def create_radar_chart(features: dict):
    """Create a radar chart for customer profile"""
    normalized = {
        'Credit Score': (features['CreditScore'] - 300) / 550 * 100,
        'Age': (features['Age'] - 18) / 62 * 100,
        'Tenure': features['Tenure'] / 10 * 100,
        'Balance': min(features['Balance'] / 200000 * 100, 100),
        'Products': (features['NumOfProducts'] - 1) / 3 * 100,
        'Salary': min(features['EstimatedSalary'] / 150000 * 100, 100)
    }
    
    categories = list(normalized.keys())
    values = list(normalized.values())
    values.append(values[0])
    categories.append(categories[0])
    
    fig = go.Figure()
    
    fig.add_trace(go.Scatterpolar(
        r=values,
        theta=categories,
        fill='toself',
        fillcolor='rgba(79, 70, 229, 0.15)',
        line=dict(color='#4f46e5', width=2),
        marker=dict(size=8, color='#4f46e5'),
        name='Profile'
    ))
    
    fig.update_layout(
        polar=dict(
            radialaxis=dict(
                visible=True,
                range=[0, 100],
                tickfont=dict(color='#64748b', size=10),
                gridcolor='#e2e8f0',
                linecolor='#e2e8f0'
            ),
            angularaxis=dict(
                tickfont=dict(color='#374151', size=11, family='Inter'),
                gridcolor='#e2e8f0',
                linecolor='#e2e8f0'
            ),
            bgcolor='#ffffff'
        ),
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        height=320,
        margin=dict(l=60, r=60, t=30, b=30),
        showlegend=False,
        font={'family': 'Inter'}
    )
    
    return fig

def create_donut_chart(results_df):
    """Create a donut chart for risk distribution"""
    risk_counts = results_df['Risk_Level'].value_counts()
    
    colors = {'Low': '#10b981', 'Medium': '#f59e0b', 'High': '#ef4444'}
    
    fig = go.Figure(data=[go.Pie(
        labels=risk_counts.index,
        values=risk_counts.values,
        hole=0.6,
        marker=dict(
            colors=[colors.get(r, '#4f46e5') for r in risk_counts.index],
            line=dict(color='#ffffff', width=3)
        ),
        textposition='outside',
        textinfo='label+percent',
        textfont=dict(size=12, color='#374151', family='Inter'),
        pull=[0.02] * len(risk_counts)
    )])
    
    fig.add_annotation(
        text=f"<b>{len(results_df)}</b><br><span style='font-size:11px;color:#64748b'>Total</span>",
        x=0.5, y=0.5,
        font=dict(size=24, color='#0f172a', family='Inter'),
        showarrow=False
    )
    
    fig.update_layout(
        paper_bgcolor='rgba(0,0,0,0)',
        plot_bgcolor='rgba(0,0,0,0)',
        height=320,
        margin=dict(l=20, r=20, t=30, b=20),
        showlegend=False,
        font={'family': 'Inter'}
    )
    
    return fig

# ==================== Sidebar ====================
with st.sidebar:
    st.markdown("""
    <div style="text-align: center; padding: 1.5rem 0 1rem 0;">
        <div style="width: 60px; height: 60px; background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); border-radius: 16px; display: flex; align-items: center; justify-content: center; margin: 0 auto; box-shadow: 0 8px 20px rgba(79, 70, 229, 0.3);">
            <span style="font-size: 1.8rem;">🛡️</span>
        </div>
        <div style="font-size: 1.25rem; font-weight: 800; color: #0f172a; margin-top: 1rem; letter-spacing: -0.02em;">ChurnGuard AI</div>
        <div style="font-size: 0.8rem; color: #64748b; margin-top: 0.25rem;">Enterprise Analytics</div>
    </div>
    """, unsafe_allow_html=True)
    
    st.markdown("---")
    
    page = st.radio(
        "Navigation",
        ["🎯 Predict", "📊 Batch Analysis", "📡 Dashboard"],
        label_visibility="collapsed"
    )
    
    st.markdown("---")
    
    # API Status
    is_healthy, health_data = check_api_health()
    
    if is_healthy:
        st.markdown('<div class="status-online"><span style="color: #10b981;">●</span> System Online</div>', unsafe_allow_html=True)
    else:
        st.markdown('<div class="status-offline"><span>●</span> System Offline</div>', unsafe_allow_html=True)
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    # Model Status Card
    if is_healthy:
        st.markdown("""
        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 1rem;">
            <div style="color: #64748b; font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; font-weight: 600;">Model Status</div>
            <div style="color: #10b981; font-weight: 700; margin-top: 0.25rem; font-size: 0.95rem;">✓ Ready</div>
        </div>
        """, unsafe_allow_html=True)
    
    st.markdown("---")
    
    st.markdown("##### 🔗 Quick Links")
    st.markdown(f"[📚 API Documentation]({API_BASE_URL}/docs)")
    st.markdown("[💻 GitHub Repository](https://github.com/AymenMB/bank-churn-mlops)")
    
    st.markdown("---")
    st.caption("Powered by Azure ML • FastAPI")

# ==================== Main Content ====================

# Hero Header
st.markdown("""
<div class="hero-container">
    <div style="display: flex; justify-content: space-between; align-items: center; position: relative; z-index: 1;">
        <div>
            <h1 class="hero-title">🛡️ ChurnGuard AI</h1>
            <p class="hero-subtitle">Enterprise customer churn prediction powered by machine learning</p>
            <div class="hero-badge">
                <div class="hero-badge-dot"></div>
                Live Predictions Active
            </div>
        </div>
        <div style="text-align: right; color: rgba(255,255,255,0.9); font-size: 0.9rem;">
            <div style="font-weight: 700;">Azure Container Apps</div>
            <div style="opacity: 0.8; margin-top: 0.25rem;">Random Forest • ~80% Accuracy</div>
        </div>
    </div>
</div>
""", unsafe_allow_html=True)

# ==================== Predict Page ====================
if page == "🎯 Predict":
    
    col_left, col_right = st.columns([1.3, 1])
    
    with col_left:
        st.markdown("""
        <div class="card-elevated">
            <div class="section-header">
                <div class="section-icon">👤</div>
                <div>
                    <h3 class="section-title">Customer Profile</h3>
                    <p class="section-subtitle">Enter customer details for analysis</p>
                </div>
            </div>
        """, unsafe_allow_html=True)
        
        # Financial Section
        st.markdown('<div class="form-section-title">💰 Financial Information</div>', unsafe_allow_html=True)
        fin1, fin2, fin3 = st.columns(3)
        
        with fin1:
            credit_score = st.slider("Credit Score", 300, 850, 650)
        with fin2:
            balance = st.number_input("Account Balance ($)", 0.0, 300000.0, 50000.0, step=5000.0, format="%.0f")
        with fin3:
            estimated_salary = st.number_input("Annual Salary ($)", 0.0, 200000.0, 75000.0, step=5000.0, format="%.0f")
        
        st.markdown("<br>", unsafe_allow_html=True)
        
        # Demographics Section
        st.markdown('<div class="form-section-title">🌍 Demographics</div>', unsafe_allow_html=True)
        demo1, demo2, demo3 = st.columns(3)
        
        with demo1:
            age = st.slider("Age", 18, 80, 35)
        with demo2:
            geography = st.selectbox("Country", ["France", "Germany", "Spain"])
        with demo3:
            tenure = st.slider("Years with Bank", 0, 10, 5)
        
        st.markdown("<br>", unsafe_allow_html=True)
        
        # Banking Section
        st.markdown('<div class="form-section-title">🏦 Banking Relationship</div>', unsafe_allow_html=True)
        bank1, bank2, bank3 = st.columns(3)
        
        with bank1:
            num_products = st.selectbox("Number of Products", [1, 2, 3, 4], index=1)
        with bank2:
            has_cr_card = st.radio("Has Credit Card?", ["Yes", "No"], horizontal=True)
        with bank3:
            is_active = st.radio("Active Member?", ["Yes", "No"], horizontal=True)
        
        st.markdown("</div>", unsafe_allow_html=True)
        
        # Prepare features
        features = {
            "CreditScore": credit_score,
            "Age": age,
            "Tenure": tenure,
            "Balance": balance,
            "NumOfProducts": num_products,
            "HasCrCard": 1 if has_cr_card == "Yes" else 0,
            "IsActiveMember": 1 if is_active == "Yes" else 0,
            "EstimatedSalary": estimated_salary,
            "Geography_Germany": 1 if geography == "Germany" else 0,
            "Geography_Spain": 1 if geography == "Spain" else 0
        }
        
        st.markdown("<br>", unsafe_allow_html=True)
        predict_btn = st.button("⚡ Analyze Customer", use_container_width=True, type="primary")
    
    with col_right:
        st.markdown("""
        <div class="card-elevated">
            <div class="section-header">
                <div class="section-icon">📊</div>
                <div>
                    <h3 class="section-title">Profile Overview</h3>
                    <p class="section-subtitle">Visual representation</p>
                </div>
            </div>
        """, unsafe_allow_html=True)
        
        radar = create_radar_chart(features)
        st.plotly_chart(radar, use_container_width=True)
        
        st.markdown("</div>", unsafe_allow_html=True)
    
    # Results
    if predict_btn:
        st.markdown("---")
        
        with st.spinner("Analyzing..."):
            success, result = make_prediction(features)
            time.sleep(0.3)
        
        if success:
            st.markdown('<h2 style="text-align: center; color: #0f172a; margin-bottom: 1.5rem;">📈 Analysis Results</h2>', unsafe_allow_html=True)
            
            r1, r2, r3 = st.columns([1, 1.2, 1])
            
            with r1:
                risk = result['risk_level']
                main_color, bg_color, dark_color = get_risk_colors(risk)
                emoji = "🟢" if risk == "Low" else "🟡" if risk == "Medium" else "🔴"
                
                st.markdown(f"""
                <div class="result-card risk-{risk.lower()}">
                    <div style="color: #64748b; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem; font-weight: 600;">Risk Level</div>
                    <div style="font-size: 2.5rem; margin-bottom: 0.5rem;">{emoji}</div>
                    <div style="font-size: 1.5rem; font-weight: 800; color: {dark_color};">{risk} Risk</div>
                    <div style="margin-top: 0.75rem; color: #64748b; font-size: 0.85rem;">
                        {"Customer stable" if risk == "Low" else "Monitor closely" if risk == "Medium" else "Action required"}
                    </div>
                </div>
                """, unsafe_allow_html=True)
            
            with r2:
                st.markdown("""
                <div class="result-card">
                    <div style="color: #64748b; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.1em; font-weight: 600;">Churn Probability</div>
                """, unsafe_allow_html=True)
                
                gauge = create_gauge_chart(result['churn_probability'], risk)
                st.plotly_chart(gauge, use_container_width=True)
                
                st.markdown("</div>", unsafe_allow_html=True)
            
            with r3:
                pred_text = "WILL CHURN" if result['prediction'] == 1 else "WILL STAY"
                pred_emoji = "🚨" if result['prediction'] == 1 else "✅"
                pred_color = "#ef4444" if result['prediction'] == 1 else "#10b981"
                confidence = abs(result['churn_probability'] - 0.5) * 200
                
                st.markdown(f"""
                <div class="result-card">
                    <div style="color: #64748b; font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem; font-weight: 600;">Prediction</div>
                    <div style="font-size: 2.5rem; margin-bottom: 0.5rem;">{pred_emoji}</div>
                    <div style="font-size: 1.25rem; font-weight: 800; color: {pred_color};">{pred_text}</div>
                    <div style="margin-top: 1.25rem; padding-top: 1rem; border-top: 1px solid #e2e8f0;">
                        <div style="color: #64748b; font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.1em; font-weight: 600;">Confidence</div>
                        <div style="color: #0f172a; font-size: 1.75rem; font-weight: 800; margin-top: 0.25rem;">{confidence:.1f}%</div>
                    </div>
                </div>
                """, unsafe_allow_html=True)
            
            # Recommendations
            st.markdown("<br>", unsafe_allow_html=True)
            with st.expander("💡 **Recommended Actions**", expanded=True):
                if risk == "High":
                    st.error("⚠️ **High Priority** — Immediate attention required")
                    st.markdown("1. **Personal outreach** — Assign a dedicated relationship manager\n2. **Retention offer** — Prepare a personalized package\n3. **Service review** — Investigate recent issues\n4. **Exit prevention** — Schedule a call within 24 hours")
                elif risk == "Medium":
                    st.warning("📋 **Monitor Required** — Keep an eye on this customer")
                    st.markdown("1. **Engagement check** — Review recent activity\n2. **Value addition** — Consider premium benefits\n3. **Feedback request** — Send satisfaction survey\n4. **Cross-sell** — Identify relevant products")
                else:
                    st.success("✅ **Low Risk** — Customer is satisfied")
                    st.markdown("1. **Maintain quality** — Continue excellent service\n2. **Loyalty rewards** — Consider for loyalty tiers\n3. **Referral program** — Invite to referral initiatives\n4. **Upselling** — Target for premium products")
        else:
            st.error(f"❌ Prediction failed: {result}")

# ==================== Batch Analysis Page ====================
elif page == "📊 Batch Analysis":
    st.markdown("""
    <div class="card-elevated">
        <div class="section-header">
            <div class="section-icon">📊</div>
            <div>
                <h3 class="section-title">Batch Customer Analysis</h3>
                <p class="section-subtitle">Upload CSV for bulk predictions</p>
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    c1, c2 = st.columns(2)
    
    with c1:
        with st.container(border=True):
            st.markdown("##### 📝 CSV Template")
            
            template_df = pd.DataFrame({
                'CreditScore': [650, 720, 580],
                'Age': [35, 42, 28],
                'Tenure': [5, 3, 8],
                'Balance': [50000.0, 75000.0, 25000.0],
                'NumOfProducts': [2, 1, 3],
                'HasCrCard': [1, 0, 1],
                'IsActiveMember': [1, 1, 0],
                'EstimatedSalary': [75000.0, 95000.0, 45000.0],
                'Geography_Germany': [0, 1, 0],
                'Geography_Spain': [1, 0, 0]
            })
            
            st.dataframe(template_df, use_container_width=True, height=140)
            st.download_button("📥 Download Template", template_df.to_csv(index=False), "template.csv", "text/csv", use_container_width=True)
    
    with c2:
        with st.container(border=True):
            st.markdown("##### 📤 Upload Data")
            st.markdown("<br>", unsafe_allow_html=True)
            uploaded = st.file_uploader("Drop CSV here", type=['csv'], label_visibility="collapsed")
            if uploaded:
                st.success(f"✓ {uploaded.name}")
    
    if uploaded:
        try:
            df = pd.read_csv(uploaded)
            st.markdown(f'<div class="info-box">📋 Loaded <b>{len(df)}</b> customers</div>', unsafe_allow_html=True)
            st.dataframe(df.head(5), use_container_width=True)
            
            if st.button("⚡ Analyze All", type="primary", use_container_width=True):
                prog = st.progress(0)
                prog.progress(30)
                
                customers = df.to_dict('records')
                success, result = make_batch_prediction(customers)
                prog.progress(100)
                prog.empty()
                
                if success:
                    preds = pd.DataFrame(result['predictions'])
                    df['Probability'] = preds['churn_probability']
                    df['Prediction'] = preds['prediction'].map({0: 'Stay', 1: 'Churn'})
                    df['Risk'] = preds['risk_level']
                    
                    st.success(f"✅ Analyzed {len(df)} customers!")
                    
                    m1, m2, m3, m4 = st.columns(4)
                    with m1:
                        st.markdown(f'<div class="metric-card"><div class="metric-value">{len(df)}</div><div class="metric-label">Total</div></div>', unsafe_allow_html=True)
                    with m2:
                        churn = (df['Prediction'] == 'Churn').sum()
                        st.markdown(f'<div class="metric-card"><div class="metric-value" style="color: #ef4444;">{churn}</div><div class="metric-label">At Risk</div></div>', unsafe_allow_html=True)
                    with m3:
                        high = (df['Risk'] == 'High').sum()
                        st.markdown(f'<div class="metric-card"><div class="metric-value" style="color: #f59e0b;">{high}</div><div class="metric-label">High Risk</div></div>', unsafe_allow_html=True)
                    with m4:
                        avg = df['Probability'].mean() * 100
                        st.markdown(f'<div class="metric-card"><div class="metric-value">{avg:.1f}%</div><div class="metric-label">Avg Prob</div></div>', unsafe_allow_html=True)
                    
                    st.markdown("<br>", unsafe_allow_html=True)
                    
                    ch1, ch2 = st.columns(2)
                    with ch1:
                        with st.container(border=True):
                            st.markdown("##### Risk Distribution")
                            st.plotly_chart(create_donut_chart(df), use_container_width=True)
                    
                    with ch2:
                        with st.container(border=True):
                            st.markdown("##### Probability Spread")
                            hist = px.histogram(df, x='Probability', nbins=15, color_discrete_sequence=['#4f46e5'])
                            hist.update_layout(
                                paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)',
                                xaxis=dict(gridcolor='#e2e8f0', title=''), yaxis=dict(gridcolor='#e2e8f0', title=''),
                                height=320, margin=dict(l=20, r=20, t=20, b=20), font_color='#374151'
                            )
                            st.plotly_chart(hist, use_container_width=True)
                    
                    st.dataframe(df, use_container_width=True, height=300)
                    st.download_button("📥 Download Results", df.to_csv(index=False), "results.csv", "text/csv", type="primary", use_container_width=True)
                else:
                    st.error(f"Failed: {result}")
        except Exception as e:
            st.error(f"Error: {e}")

# ==================== Dashboard Page ====================
elif page == "📡 Dashboard":
    st.markdown("""
    <div class="card-elevated">
        <div class="section-header">
            <div class="section-icon">📡</div>
            <div>
                <h3 class="section-title">System Dashboard</h3>
                <p class="section-subtitle">Monitor API health and performance</p>
            </div>
        </div>
    </div>
    """, unsafe_allow_html=True)
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    d1, d2 = st.columns(2)
    
    with d1:
        with st.container(border=True):
            st.markdown("##### 🔄 Health Status")
            
            is_healthy, health = check_api_health()
            if is_healthy:
                st.success("✅ API is healthy")
                if health:
                    st.json(health)
            else:
                st.error("❌ API offline")
            
            if st.button("🔄 Refresh"):
                st.rerun()
    
    with d2:
        with st.container(border=True):
            st.markdown("##### 📍 API Endpoints")
            st.code("GET  /health", language=None)
            st.code("POST /predict", language=None)
            st.code("POST /predict/batch", language=None)
            st.code("POST /drift/check", language=None)
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    with st.container(border=True):
        st.markdown("##### 🔬 Drift Detection")
        st.info("**Note:** Drift detection requires reference data on the server. The Azure deployment may not have the training data file included.")
        
        if st.button("🔍 Run Drift Check", type="primary"):
            # Generate 15 sample customers for drift detection (minimum 10 required)
            import random
            samples = []
            for i in range(15):
                samples.append({
                    "CreditScore": random.randint(350, 800),
                    "Age": random.randint(20, 70),
                    "Tenure": random.randint(0, 10),
                    "Balance": round(random.uniform(0, 200000), 2),
                    "NumOfProducts": random.randint(1, 4),
                    "HasCrCard": random.randint(0, 1),
                    "IsActiveMember": random.randint(0, 1),
                    "EstimatedSalary": round(random.uniform(20000, 150000), 2),
                    "Geography_Germany": 1 if random.random() < 0.25 else 0,
                    "Geography_Spain": 1 if random.random() < 0.25 else 0
                })
            
            with st.spinner("Analyzing drift across 15 sample customers..."):
                ok, res = check_drift(samples)
            
            if ok:
                drifted = res.get('features_drifted', 0)
                if drifted > 0:
                    st.warning(f"⚠️ Drift detected in {drifted} feature(s) — consider retraining")
                else:
                    st.success("✅ No significant drift detected")
                st.markdown(f"**Samples analyzed:** {res.get('samples_analyzed', 'N/A')}")
                st.markdown(f"**Features analyzed:** {res.get('features_analyzed', 'N/A')}")
                with st.expander("Detailed Results"):
                    st.json(res)
            else:
                st.warning("⚠️ Drift check unavailable (reference data not deployed to Azure)")
    
    st.markdown("<br>", unsafe_allow_html=True)
    
    with st.container(border=True):
        st.markdown("##### 🛠️ Technical Stack")
        
        t1, t2, t3 = st.columns(3)
        with t1:
            st.markdown("**🤖 ML Model**\n- Random Forest\n- scikit-learn 1.3.2\n- ~80% accuracy")
        with t2:
            st.markdown("**☁️ Infrastructure**\n- Azure Container Apps\n- Azure Container Registry\n- Application Insights")
        with t3:
            st.markdown("**⚙️ Pipeline**\n- GitHub Actions CI/CD\n- Docker containers\n- FastAPI + LRU cache")
