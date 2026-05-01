import pandas as pd
import numpy as np

def check_data_quality(df: pd.DataFrame, primary_key: str) -> dict:
    """"
    检查数据质量: 批量统计缺失值、重复行及重复主键检测
    """

    report = {}

    # 1. 缺失值统计
    report['missing_values'] = df.isnull().sum().to_dict() # 统计每列的缺失值数量，并转换为字典格式

    # 2. 重复行统计
    report['duplicate_rows'] = df.duplicated().sum() # duplicated() 返回一个布尔 Series，sum() 计算 True 的数量，即重复行的数量

    # 3. 重复主键检测
    report['duplicate_primary_keys'] = df.duplicated(subset=[primary_key]).sum()  # 只检查主键列的重复情况

    return report

def log_issue_date(df: pd.DataFrame, primary_key: str, output_file: str):
    """
    设计的意义：记录问题数据清单，将其导出为 CSV 方便后续人工排查。
    """
    # 提取重复主键的数据作为问题数据示例
    issue_df = df[df.duplicated(subset=[primary_key], keep=False)] # keep=False 标记所有重复行为 True

    if not issue_df.empty:
        issue_df.to_csv(output_file, index=False) # 将问题数据导出为 CSV 文件，index=False 表示不导出行索引
        print(f"⚠️ 已记录问题数据到 {output_file}")
    else:
        print("✅ 没有发现重复主键，未生成问题数据文件")


def detect_outliers_3sigma(df: pd.DataFrame, column: str) -> pd.Series:
    """
    设计的意义：使用 3σ原则检测数值型列中的异常值。
    参数:
        df: 待检测的 DataFrame 对象。
        column: 需要检测的数值型列名。
    返回:
        pd.Series: 一个布尔 Series，标记异常值为 True。
    """
    if column not in df.columns:
        return pd.Series([False] * len(df)) # 如果列不存在，返回全 False 的 Series
    
    data = df[column] # 提取指定列的数据，data是Series对象
    mean = data.mean() # 计算均值
    std = data.std() # 计算标准差

    # 3σ原则：如果数据点与均值的差超过 3 倍的标准差，则认为是异常值
    # 计算上下界
    lower_bound = mean - 3 * std
    upper_bound = mean + 3 * std

    # 标记异常值
    return (data < lower_bound) | (data > upper_bound) # 返回一个布尔 Series，标记异常值为True，跟data一一对应

def validate_time_logic(df: pd.DataFrame, start_col: str, end_col: str) -> pd.Series:
    """
    设计的意义：验证时间逻辑关系，例如订单的购买时间必须早于发货时间。
    参数:
        df: 待检测的 DataFrame 对象。
        start_col: 起始时间列名。
        end_col: 结束时间列名。
    如果出现负值，说明源数据存在逻辑矛盾
    """
    if start_col not in df.columns or end_col not in df.columns:
        return pd.Series([False] * len(df)) # 如果列不存在，返回全 False 的 Series
    
    start_time = pd.to_datetime(df[start_col], errors='coerce') # 将起始时间列转换为 datetime 类型，无法解析的值会被设置为 NaT
    end_time = pd.to_datetime(df[end_col], errors='coerce') # 将结束时间列转换为 datetime 类型

    # 验证时间逻辑关系：起始时间必须早于结束时间
    return start_time < end_time # 返回一个布尔 Series，标记逻辑正确的行为 True