import pandas as pd
from etl.utils.db import DBManager
from etl.utils.data_cleaner import perform_basic_cleaning

def run_pipeline(extract_func, transform_func, target_table, schema="python_etl"):   
    """
    设计的意义：
    这是一个通用的 ETL 流水线控制器。它负责协调各个组件：
    1. 抽取 (Extract): 从数据源读取数据
    2. 转换 (Transform): 对数据进行清洗和转换
    3. 加载 (Load): 将数据写入数据库
    参数:
        extract_func: 一个函数，负责抽取数据，返回一个 DataFrame。
        transform_func: 一个函数，负责转换数据，接受一个 DataFrame 作为输入，返回一个清洗后的 DataFrame。
        target_table: 目标数据库表名。
        schema: 数据库模式名，默认为 "python_etl"。
    """
    
    # 1. 抽取: 从数据源读取数据
    print("🔍 开始抽取数据")
    df = extract_func() # 调用抽取函数获取原始数据
    
    # 2. 转换: 清洗和转换数据
    print("🔍 开始转换数据")
    cleaned_df = transform_func(df) # 调用转换函数对数据进行清洗和转换
    
    # 3. 加载: 将数据写入数据库
    print("🔍 开始加载数据到数据库")
    db_manager = DBManager() # 创建数据库管理对象
    # 将清洗后的数据加载到 PostgreSQL 数据库中
    db_manager.load_to_postgres(cleaned_df, target_table, schema, if_exists="replace")
    
    print(f"✅ 数据加载完成: {target_table} 入库成功，共 {len(df)} 行")