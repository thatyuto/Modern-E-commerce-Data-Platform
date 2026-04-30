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