import pandas as pd
from sqlalchemy import create_engine, text
import sys

class DBManager:
    def __init__(self):
        # 替换为你本地的真实信息
        self.user = 'postgres'
        self.password = ''
        self.host = 'localhost'
        self.port = '5432'
        self.db_name = 'postgres'
        self.url = f'postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}'
        self.engine = None

    def get_conn(self):
        try:
            if not self.engine:
                self.engine = create_engine(self.url)
            return self.engine.connect()
        except Exception as e:
            print(f"数据库连接失败: {e}")
            sys.exit(1)

    def query(self, sql):
        """执行查询并安全关闭连接"""
        try:
            with self.get_conn() as conn:
                return pd.read_sql(text(sql), conn)
        except Exception as e:
            print(f" SQL执行错误: {e}")
            return None

if __name__ == "__main__":
    db = DBManager()
    # 随便查一个表测试
    res = db.query("SELECT * FROM olist_raw.olist_orders_dataset LIMIT 5")
    print(res)