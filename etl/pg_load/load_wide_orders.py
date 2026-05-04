"""
Module: load_wide_orders
Description: Engineering-grade ETL for Order Fact Wide Table, including 
             data quality auditing and RFM computation.
Author: Yuto Wong
Date: 2026-05-04
"""

import logging
import pandas as pd
from typing import Tuple
from pathlib import Path
from etl.core.engine import run_pipeline
from etl.utils.file_handler import load_csv_safely
from etl.utils.data_cleaner import perform_basic_cleaning
from etl.utils.data_quality import (
    check_data_quality, 
    log_issue_data, 
    detect_outliers_3sigma, 
    validate_time_logic
)

# --- 1. 配置与日志中心 (image_b5dc37.png: 配置外置，避免硬编码) ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_FILE_PATH = BASE_DIR / "olist_analysis/notes/issue_orders_time_logic.csv"

def extract() -> pd.DataFrame:
    """
    设计的意义：
    从原始 CSV 抽取数据。采用类型注解明确返回为 DataFrame。
    """
    logger.info("Starting data extraction from Olist datasets.")
    df_orders = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_orders_dataset.csv"))
    df_payments = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_order_payments_dataset.csv"))
    
    # 初始合并
    return pd.merge(df_orders, df_payments, on="order_id", how="left")

def apply_quality_auditing(df: pd.DataFrame) -> pd.DataFrame:
    """
    设计的意义 (函数拆分，单一职责): 
    专注于数据质量标记与异常记录，不干扰主转换流程。
    """
    logger.info("Executing data quality auditing...")
    df['is_normal'] = 0  # 默认正常

    # 1. 数值异常标记 (3-Sigma)
    for col in ['payment_value', 'payment_sequential']:
        outlier_mask = detect_outliers_3sigma(df, col)
        df.loc[outlier_mask, 'is_normal'] = 1
        if outlier_mask.any():
            logger.warning(f"Detected {outlier_mask.sum()} outliers in column: {col}")

    # 2. 时间逻辑校验
    time_error_mask = validate_time_logic(df, 'order_purchase_timestamp', 'order_delivered_customer_date')
    df.loc[time_error_mask, 'is_normal'] = 1
    
    if time_error_mask.any():
        logger.warning(f"Detected {time_error_mask.sum()} time logic errors. Logging to CSV.")
        # 调用你之前写的审计函数
        log_issue_data(df[time_error_mask], primary_key='order_id', output_file=str(LOG_FILE_PATH))
        
    return df

def calculate_rfm_segments(df: pd.DataFrame) -> pd.DataFrame:
    """
    设计的意义 (image_c187fa.png): 
    在订单宽表基础上计算 RFM 指标。注意：此逻辑通常应合并至用户维度表。
    """
    logger.info("Computing RFM metrics and segments...")
    # 转换时间格式
    df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
    snapshot_date = df['order_purchase_timestamp'].max() + pd.Timedelta(days=1)

    # 聚合得到用户级的 RFM
    # 注意：在订单宽表中保留这些值会导致冗余，通常仅用于生成标签
    rfm = df.groupby('customer_id').agg({
        'order_purchase_timestamp': lambda x: (snapshot_date - x.max()).days,
        'order_id': 'count',
        'payment_value': 'sum'
    }).rename(columns={'order_purchase_timestamp': 'R', 'order_id': 'F', 'payment_value': 'M'})
    
    # 记录群体统计占比
    logger.info("RFM computation complete.")
    return df

def transform(df: pd.DataFrame) -> pd.DataFrame:
    """
    设计的意义: 
    作为 transform 的总入口，通过调用子函数实现流水线作业。
    """
    # 0-60min: 质量自检报告
    quality_report = check_data_quality(df, "order_id")
    logger.info(f"Initial Quality Check - Duplicates: {quality_report['duplicate_rows']}")

    # 60-120min: 质量审计与标记
    df = apply_quality_auditing(df)

    # 120-180min: 基础清洗
    logger.info("Performing basic string cleaning.")
    df = perform_basic_cleaning(df)

    # 180-240min: 缺失值填充
    df = df.fillna({'payment_value': 0, 'order_status': 'delivered'})
    
    logger.info(f"Transformation workflow finished. Total records: {len(df)}")
    return df

if __name__ == "__main__":
    # 240-300min: 全脚本跑通，形成可复用 ETL 包
    try:
        run_pipeline(extract, transform, "fact_orders_wide_2", schema="python_etl")
        logger.info("Pipeline execution successful.")
    except Exception as e:
        logger.critical(f"Pipeline crashed! Error: {str(e)}", exc_info=True)