from etl.core.engine import run_pipeline
from etl.utils.file_handler import load_csv_safely
from etl.utils.data_cleaner import validate_data, perform_basic_cleaning
from etl.utils.data_quality import check_data_quality, log_issue_data, detect_outliers_3sigma, validate_time_logic
from pathlib import Path # 用于动态路径处理
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent.parent.parent

def extract():
    # 提取订单事实与支付明细表
    df_orders = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_orders_dataset.csv"))
    df_payments = load_csv_safely(str(BASE_DIR / "olist_analysis/raw_data/olist_order_payments_dataset.csv"))
    return pd.merge(df_orders, df_payments, on="order_id", how="left") # 合并订单与支付数据，构建宽表

def transform(df: pd.DataFrame) -> pd.DataFrame:
     # 质量检测
    print("🔍 检测数据质量")
    quality_report = check_data_quality(df, "order_id") 

    # 打印质量报告表格（简化版）
    print("-" * 30)
    print(f"重复行数: {quality_report['duplicate_rows']}")
    print(f"重复主键数: {quality_report['duplicate_primary_keys']}")
    print("缺失值统计:", quality_report['missing_values'])
    print("-" * 30)

    df['is_normal'] = 0
    for col in ['payment_value','payment_sequential']:
        outlier_mask = detect_outliers_3sigma(df, col)
        df.loc[outlier_mask, 'is_normal'] = 1 # 标记异常值，学习如何用.loc进行定位
        if outlier_mask.any():
            print(f"⚠️ 在 [{col}] 中检测到 {outlier_mask.sum()} 条数值异常数据")

    # 时间逻辑合法性校验, 送达时间不能早于下单时间
    time_error_mask = validate_time_logic(df, 'order_purchase_timestamp', 'order_delivered_customer_date')
    df.loc[time_error_mask, 'is_normal'] = 1 # 标记时间逻辑错误数据
    if time_error_mask.any():
        print(f"⚠️ 检测到 {time_error_mask.sum()} 条时间逻辑错误数据")
        # 记录时间逻辑错误数据
        log_issue_data(df[time_error_mask], primary_key='order_id', output_file=str(log_path.parent / "issue_orders_time_logic.csv"))
    
    # 转换: 基础清洗
    print("🔍 开始清洗数据, 去空格、统一大小写")
    df_clean = perform_basic_cleaning(df)

    df = df.fillna({'payment_value': 0, 'order_status': 'delivered'}) # 填充缺失值
    return df

if __name__ == "__main__":
    run_pipeline(extract, transform, "fact_orders_wide_2", schema="python_etl")


