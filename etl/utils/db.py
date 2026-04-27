# import pandas as pd
import os
import sys
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# 1. 加载 .env
load_dotenv()

class DBManager:
    def __init__(self):
        # 2. 严格从环境变量读取，不再提供任何包含个人信息的默认值
        # os.getenv(key) 如果读不到会返回 None
        self.user = os.getenv("DB_USER")
        self.password = os.getenv("DB_PASSWORD", "") # 密码默认为空是安全的，因为不知道用户名和 Host 也没用
        self.host = os.getenv("DB_HOST")
        self.port = os.getenv("DB_PORT", "5432") # 端口 5432 是公认标准
        self.db_name = os.getenv("DB_NAME")
        
        # 3. 强制性检查：只要关键配置缺失，直接中断程序并报错
        # 这样可以强迫你在新环境下必须先配置 .env
        if not all([self.user, self.host, self.db_name]):
            print("❌ 错误: 关键环境变量 (USER, HOST, 或 DBNAME) 缺失！")
            print("💡 解决: 请检查项目根目录下的 .env 文件是否配置正确。")
            sys.exit(1)
        
        # 4. 构建连接 URL
        if self.password:
            self.url = f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}"
        else:
            self.url = f"postgresql://{self.user}@{self.host}:{self.port}/{self.db_name}"
        
        try:
            self.engine = create_engine(
                self.url,
                pool_size=5,
                max_overflow=10
            )
            print(f"🚀 DBManager: 数据库引擎初始化成功 (用户: {self.user})")
        except Exception as e:
            print(f"❌ 引擎创建失败: {e}")
            sys.exit(1)

    def get_df(self, sql: str):
        try:
            with self.engine.connect() as conn:
                return pd.read_sql(text(sql), conn)
        except Exception as e:
            print(f"❌ 查询失败: {e}")
            return None

if __name__ == "__main__":
    db = DBManager()
    test_query = "SELECT * FROM olist_mart.fact_order_wide_table LIMIT 5;"
    result = db.get_df(test_query)
    if result is not None:
        print(result)