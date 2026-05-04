"""
Module: load_dim_customers
Description: Refined ETL for Customer Dimension Wide Table with Geolocation 
             enrichment and RFM segmentation.
Author: Yuto Wong
Date: 2026-05-04
"""

import logging
import pandas as pd
import numpy as np
from typing import Tuple, Dict
from pathlib import Path
from etl.core.engine import run_pipeline
from etl.utils.file_handler import load_csv_safely

# --- 1. 配置与日志中心 ( 配置外置，避免硬编码) ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# 统一管理路径，方便维护
DATA_PATHS = {
    "customers": BASE_DIR / "olist_analysis/raw_data/olist_customers_dataset.csv",
    "geolocation": BASE_DIR / "olist_analysis/raw_data/olist_geolocation_dataset.csv",
    "orders": BASE_DIR / "olist_analysis/raw_data/olist_orders_dataset.csv",
    "payments": BASE_DIR / "olist_analysis/raw_data/olist_order_payments_dataset.csv"
}

def extract() -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """抽取原材料：用户、地理、订单、支付"""
    logger.info("Extracting raw datasets for customer dimension.")
    df_cust = load_csv_safely(str(DATA_PATHS["customers"]))
    df_geo = load_csv_safely(str(DATA_PATHS["geolocation"]))
    df_orders = load_csv_safely(str(DATA_PATHS["orders"]))
    df_pay = load_csv_safely(str(DATA_PATHS["payments"]))
    return df_cust, df_geo, df_orders, df_pay

def process_geolocation_enrichment(df_cust: pd.DataFrame, df_geo: pd.DataFrame) -> pd.DataFrame:
    """
    设计的意义: 拆分地理增强逻辑，确保 transform 函数简洁。
    """
    logger.info("Enriching customer data with geolocation coordinates.")
    # 聚合经纬度，防止 Merge 时由于重复邮编导致的数据爆炸
    df_geo_agg = df_geo.groupby(["geolocation_zip_code_prefix"]).agg({
        "geolocation_lat": "mean",
        "geolocation_lng": "mean"  
    }).reset_index()

    df_user_geo = pd.merge(
        df_cust, df_geo_agg,
        left_on="customer_zip_code_prefix",
        right_on="geolocation_zip_code_prefix",
        how="left"
    )
    return df_user_geo

def calculate_rfm(df_orders: pd.DataFrame, df_pay: pd.DataFrame, df_cust: pd.DataFrame) -> pd.DataFrame:
    """
    业务逻辑封装: RFM模型核心算法
    对应 image_c187fa.png 的四个阶段
    """
    logger.info("Computing RFM metrics and customer segments.")
    
    # 1. 预处理
    df_merge = pd.merge(df_orders, df_pay, on="order_id", how="left")
    df_merge = pd.merge(df_merge, df_cust, on="customer_id", how="left")
    df_merge['order_purchase_timestamp'] = pd.to_datetime(df_merge['order_purchase_timestamp'])

    # 2.计算 R/F/M 分位数 
    snapshot_date = df_merge['order_purchase_timestamp'].max() + pd.Timedelta(days=1)
    rfm = df_merge.groupby('customer_unique_id').agg({
        'order_purchase_timestamp': lambda x: (snapshot_date - x.max()).days,
        'order_id': 'nunique',
        'payment_value': 'sum'
    }).rename(columns={'order_purchase_timestamp': 'recency', 'order_id': 'frequency', 'payment_value': 'monetary'})

    rfm['R_score'] = pd.qcut(rfm['recency'], 5, labels=[5,4,3,2,1]).astype(int)
    rfm['F_score'] = pd.qcut(rfm['frequency'].rank(method="first"), 5, labels=[1,2,3,4,5]).astype(int)
    rfm['M_score'] = pd.qcut(rfm['monetary'], 5, labels=[1,2,3,4,5]).astype(int)

    # 3: 定义规则并打群体标签 
    r_avg, f_avg, m_avg = rfm['R_score'].mean(), rfm['F_score'].mean(), rfm['M_score'].mean()

    def get_segment(row):
        r = '高' if row['R_score'] >= r_avg else '低'
        f = '高' if row['F_score'] >= f_avg else '低'
        m = '高' if row['M_score'] >= m_avg else '低'

        if r == '高' and f == '高' and m == '高': return '重要价值客户'
        if r == '高' and f == '高' and m == '低': return '重要保持客户'
        if r == '高' and f == '低' and m == '高': return '重要发展客户'
        if r == '低' and f == '高' and m == '高': return '重要挽留客户'
        return '一般客户'

    rfm['user_segment'] = rfm.apply(get_segment, axis=1)

    # 4. 阶段 4: 统计占比 (180-270min)
    stats = rfm['user_segment'].value_counts(normalize=True) * 100
    logger.info(f"RFM Segmentation Stats: \n{stats.round(2).apply(lambda x: f'{x:.2f}%').to_string()}")
    
    return rfm.reset_index()[['customer_unique_id', 'R_score', 'F_score', 'M_score', 'user_segment']]

def transform(data: Tuple) -> pd.DataFrame:
    """
    主转换逻辑：地理增强 + RFM 建模
    """
    df_cust, df_geo, df_orders, df_pay = data
    
    # 1. 地理增强
    df_user_geo = process_geolocation_enrichment(df_cust, df_geo)

    # 2. RFM 建模
    df_rfm_labels = calculate_rfm(df_orders, df_pay, df_cust)
    
    # 3. 合并最终宽表
    logger.info("Merging geolocation data with RFM segments.")
    df_final = pd.merge(df_user_geo, df_rfm_labels, on="customer_unique_id", how="left")
    
    # 4. 清理冗余与缺失值
    df_final = df_final.drop(columns=["geolocation_zip_code_prefix", "customer_zip_code_prefix"], errors='ignore')
    df_final['user_segment'] = df_final['user_segment'].fillna('未知')
    
    logger.info(f"Transformation complete. Total records: {len(df_final)}")
    return df_final

if __name__ == "__main__":
    # 全脚本跑通，形成可复用 ETL 包
    try:
        run_pipeline(extract, transform, target_table="dim_customers_wide", schema="python_etl")
        logger.info("ETL job finished successfully.")
    except Exception as e:
        logger.error(f"ETL job failed: {e}", exc_info=True)