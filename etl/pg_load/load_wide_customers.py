from etl.core.engine import run_pipeline
from etl.utils.file_handler import load_csv_safely
from pathlib import Path # 用于动态路径处理

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
    return df_cust, df_geo

def transform(data):
    df_cust, df_geo = data
    
    print("📍 正在处理地理坐标信息...")  # 防止fan-out
    df_geo_agg = df_geo.groupby(["geolocation_zip_code_prefix"]).agg({
        "geolocation_lat": "mean", # 取平均经纬度
        "geolocation_lng": "mean"  
    }).reset_index()

    # 多表merge, 构建包含经纬度的用户宽表
    df_user_wide = pd.merge(
        df_cust,
        df_geo_agg,
        left_on = "customer_zip_code_prefix",
        right_on = "geolocation_zip_code_prefix",
        how = "left" # 保留所有用户，即使没有匹配的地理信息
    )

    # 填充缺失值与清理
    df_user_wide = df_user_wide.drop(columns= ["geolocation_zip_code_prefix", "customer_zip_code_prefix"]) # 删除冗余列
    df_user_wide = df_user_wide.fillna({'geolocation_lat': 0, 'geolocation_lng': 0})
    return df_user_wide

if __name__ == "__main__":
    run_pipeline(extract, transform, target_table="dim_customers_wide", schema="python_etl")

