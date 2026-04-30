import pandas as pd

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


