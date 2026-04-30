# 

"""
将数据加载Load到 PostgreSQL数据库的动作或逻辑模块

设计的意义: 将“工具utils”与“具体的业务流程pg_load”分离。utils 里的代码是通用的，
而 pg_load 里的脚本是针对特定表,如fact_order_wide_table的定制化流水线。

这个“pg_load”逻辑的意义
你可以把它想象成一个工厂的装配线：
1. etl/utils/：是工厂里的各类通用机器（螺丝刀、清洗机、检测仪）。
2. etl/pg_load/：是针对特定产品（比如订单数据）设计的生产线。
为什么要专门建一个文件夹放 pg_load?
因为你不仅有 fact_order订单表, 以后还会有 产品维度表 、卖家维度表。
你只需要在 pg_load 下为每张表建立一个类似 load_xxx.py 的脚本，并复用 utils 里的机器即可。
"""

import os
from pathlib import Path

# --- 最正规的导入方式：绝对导入 ---
# 注意：运行此脚本需在项目根目录下执行 python -m etl.pg_load.load_fact_orders
from etl.utils.db import DBManager
from etl.utils.file_handler import load_csv_safely
from etl.utils.data_cleaner import validate_data, perform_basic_cleaning

# --- 最正规的路径处理：动态锁定项目根目录 ---
# __file__ 是当前文件路径，.parent.parent.parent 向上推三级到达 MODERN-E-COMMERCE-DATA-PLATFORM
BASE_DIR = Path(__file__).resolve().parent.parent.parent

def run_order_load_pipeline():
    """
    设计的意义：
    这是你的 ETL 流水线控制器。它负责协调各个组件：
    1. 抽取 (Extract): 从 CSV 读取数据
    2. 转换 (Transform): 校验和清洗数据
    3. 加载 (Load): 写入数据库
    """
    
    # 配置区
    # 使用 BASE_DIR 拼接，无论你在哪里启动脚本，路径永远准确
    csv_path = BASE_DIR / "olist_analysis" / "raw_data" / "olist_orders_dataset.csv"
    target_table = "fact_orders_wide"

    # 定义期望的列: 检验用
    expected_cols = ['order_id', 'customer_id', 'order_status', 'order_purchase_timestamp']

    # 定义不能有空值的核心字段
    critical_cols = ['order_id', 'customer_id', 'order_purchase_timestamp']

    # 执行区

    # 1. 抽取: 从 CSV 读取数据
    # 将 Path 对象转为字符串传入函数
    print(f"🔍 开始抽取数据: 从 {csv_path} 读取 CSV 文件")
    df = load_csv_safely(str(csv_path))

    # 2. 校验
    print("🔍 开始校验数据")
    if not validate_data(df, expected_cols, critical_cols):
        print("❌ 数据校验失败，流水线终止")
        return
    
    # 3. 转换: 基础清洗
    print("🔍 开始清洗数据, 去空格、统一大小写")
    df_clean = perform_basic_cleaning(df)

    # 4. 加载: 写入数据库
    print(f"🔍 开始加载数据: 写入 PostgreSQL 表 {target_table}")
    db = DBManager() # 实例化数据库管理类
    db.load_to_postgres(df_clean, 
                        table_name=target_table, 
                        schema="python_etl", 
                        if_exists="replace") # 全量覆盖写入
    

if __name__ == "__main__":
    run_order_load_pipeline()