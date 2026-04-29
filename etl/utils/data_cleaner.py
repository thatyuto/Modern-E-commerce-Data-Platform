import pandas as pd
import sys


# 检查列是否完整以及是否存在缺失值，如果不满足条件则返回 False，满足条件则返回 True
def validate_data(df: pd.DataFrame, expected_columns: list, critical_columns: list) -> bool:
    """
    数据验证函数：检查 DataFrame 是否包含预期的列，并且关键列没有缺失值。
    参数:
        df: 待验证的 DataFrame 对象。
        expected_columns: 预期应该存在的列名列表。
        critical_columns: 关键列名列表，这些列不能有缺失值。
    返回:
        bool: 如果验证通过返回 True，否则返回 False。
    """ 
    # 1. 检查 DataFrame 是否包含预期的列, 以及是否有缺失的列名。
    actual_columns = set(df.columns) # 获取 DataFrame 的实际列名集合
    missing_columns = set(expected_columns) - actual_columns # 计算缺失的列
    if missing_columns:
        print(f"❌ 数据验证失败: 缺失列 {missing_columns}")
        return False
    
    print(f"✅ 数据验证通过: 列 {actual_columns}")

    # 2. 检查关键列是否有缺失值 (NaN)
    for col in critical_columns:
        if df[col].isnull().any(): # isnull() 返回一个布尔 Series，any() 检查是否有 True
            print(f"❌ 数据验证失败: 关键列 '{col}' 存在缺失值")
            return False
    
    print("✅ 数据验证通过: 关键列没缺失值以及列名完整均匹配")
    return True


# 基础清洗，去除空格，统一大小写
def perform_basic_cleaning(df: pd.DataFrame) -> pd.DataFrame:
    """
    基础清洗函数：对 DataFrame 进行基本的清洗操作，如去除字符串列的前后空格，统一大小写等。
    参数:
        df: 待清洗的 DataFrame 对象。
    返回:
        pd.DataFrame: 清洗后的 DataFrame 对象。
    """
    
    # 1. 清洗列名
    
    df.columns = df.columns.str.strip().str.lower() # 去除列名的前后空格，并转换为小写
    print("✅ 列名清洗完成: 已去除空格并统一为小写")

    # 2. 清洗数据内容，仅对字符串类型的列进行操作
    obj_cols = df.select_dtypes(include=['object']).columns # 获取所有字符串类型的列名
    for col in obj_cols:
        df[col] = df[col].astype(str).str.strip().str.lower() # 去除字符串列的前后空格
    print("✅ 数据内容清洗完成: 已去除字符串列的前后空格并统一为小写")
    return df

if __name__ == "__main__":
    # 测试代码块
    test_file = "olist_analysis/raw_data/olist_customers_dataset.csv" 
    df = pd.read_csv(test_file)
    
    expected_cols = ['customer_id', 'customer_unique_id', 'customer_zip_code_prefix', 'customer_city', 'customer_state']
    critical_cols = ['customer_id', 'customer_unique_id']
    
    if validate_data(df, expected_cols, critical_cols):
        cleaned_df = perform_basic_cleaning(df)
        print(cleaned_df.head())