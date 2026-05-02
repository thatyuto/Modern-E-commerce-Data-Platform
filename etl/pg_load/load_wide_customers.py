from etl.core.engine import run_pipeline
from etl.utils.file_handler import load_csv_safely
from pathlib import Path # 用于动态路径处理
import pandas as pd
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent.parent

"""
用户宽表应该包含的核心字段
在 Olist 数据集中，用户数据分布在 olist_customers_dataset 和 olist_geolocation_dataset 中。

一个完整的用户宽表应当包含以下维度的信息：
身份维度：customer_id (订单级用户ID), customer_unique_id (唯一标识用户ID)。

地理维度：邮编 (zip_code)、城市 (city)、州 (state)。

增强地理信息（需 Merge）：该邮编对应的经纬度 (latitude, longitude)。这对分析“下单距离”或“物流覆盖”至关重要。
"""

def extract():
    # 抽取用户表和地理位置表
    df_cust = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_customers_dataset.csv"))
    df_geo = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_geolocation_dataset.csv"))
    df_orders = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_orders_dataset.csv"))
    df_pay = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_order_payments_dataset.csv"))
    return df_cust, df_geo, df_orders, df_pay

def calculate_rfm(df_orders, df_pay, df_cust):
    """
    业务逻辑封装: RFM模型核心算法
    """

    # 1. 预处理，合并订单与支付，定位到唯一用户
    df_merge = pd.merge(df_orders, df_pay, on="order_id", how="left")
    df_merge = pd.merge(df_merge, df_cust, on="customer_id", how="left")
    df_merge['order_purchase_timestamp'] = pd.to_datetime(df_merge['order_purchase_timestamp']) # 转换为datetime格式

    # 2. 计算参考日期, 采用所有数据的最后一天 + 1 天
    snapshot_date = df_merge['order_purchase_timestamp'].max() + pd.Timedelta(days=1)

    # 3. 聚合原始 RFM值
    rfm = df_merge.groupby('customer_unique_id').agg({
        'order_purchase_timestamp': lambda x: (snapshot_date - x.max()).days, # 获取最后一次下单时间间隔
        'order_id': 'nunique',
        'payment_value': 'sum'
    }).rename(columns={
        'order_purchase_timestamp': 'recency',
        'order_id': 'frequency',
        'payment_value': 'monetary'
    })

    # R越小，分数越高（1-5），F和M越大，分数越高
    rfm['R_score'] = pd.qcut(rfm['recency'], 5, labels=[5,4,3,2,1]).astype(int) # 最近购买时间越近，分数越高
    rfm['F_score'] = pd.qcut(rfm['frequency'].rank(method="first"), 5, labels=[1,2,3,4,5]).astype(int) # 购买频率越高，分数越高
    rfm['M_score'] = pd.qcut(rfm['monetary'], 5, labels=[1,2,3,4,5]).astype(int) # 购买金额越高，分数越高 

    # 打群体标签
    r_avg, f_avg, m_avg = rfm['R_score'].mean(), rfm['F_score'].mean(), rfm['M_score'].mean()

    def get_segment(row):
        r = '高' if row['R_score'] >= r_avg else '低'
        f = '高' if row['F_score'] >= f_avg else '低'
        m = '高' if row['M_score'] >= m_avg else '低'

        if r == '高' and f == '高' and m == '高':
            return '重要价值客户'
        if r == '高' and f == '高' and m == '低':
            return '重要保持客户'
        if r == '高' and f == '低' and m == '高':
            return '重要发展客户'
        if r == '低' and f == '高' and m == '高': 
            return '重要挽留客户'
        return '一般客户'

    rfm['user_segment'] = rfm.apply(get_segment, axis=1)

    # 统计各群体占比
    stats = rfm['user_segment'].value_counts(normalize=True) * 100
    print("📊 RFM用户分群统计:")
    print(stats.round(2).apply(lambda x: f"{x:.2f}%"))
    return rfm.reset_index()[['customer_unique_id', 'R_score', 'F_score', 'M_score', 'user_segment']]

def transform(data):
    df_cust, df_geo, df_orders, df_pay = data
    
    # 1. 处理地理增强
    print("📍 正在处理地理坐标信息...")
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

    # 2. 执行 RFM 建模 (调用封装函数)
    print("🧠 正在计算 RFM 标签...")
    df_rfm_labels = calculate_rfm(df_orders, df_pay, df_cust)
    
    # 3. 合并最终宽表
    df_final = pd.merge(df_user_geo, df_rfm_labels, on="customer_unique_id", how="left")
    
    # 4. 清理冗余字段
    df_final = df_final.drop(columns=["geolocation_zip_code_prefix", "customer_zip_code_prefix"])
    df_final = df_final.fillna({'user_segment': '未知'})
    
    return df_final

if __name__ == "__main__":
    run_pipeline(extract, transform, target_table="dim_customers_wide", schema="python_etl")

