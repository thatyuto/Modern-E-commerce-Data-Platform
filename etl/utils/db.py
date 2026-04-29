import os
import sys
import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# 1. 加载 .env 配置文件
# 意义：它会扫描项目根目录下的 .env 文件，将其中的键值对加载到系统的环境变量中。
# 这样你就可以用 os.getenv() 获取隐私信息，而不需要在代码里写死。
load_dotenv()

class DBManager:
    """
    数据库管理类：负责所有与 PostgreSQL 的交互。
    使用类的形式是为了封装属性（如 engine），方便在整个项目的不同地方复用。
    """
    def __init__(self):
        # 2. 严格从环境变量中读取配置
        # os.getenv(key) 的逻辑是：如果系统里没设置这个变量，它会返回 None。
        self.user = os.getenv("DB_USER")
        self.password = os.getenv("DB_PASSWORD", "")  # 密码允许为空字符串
        self.host = os.getenv("DB_HOST")
        self.port = os.getenv("DB_PORT", "5432")      # 5432 是 Postgres 默认端口，写死也算安全
        self.db_name = os.getenv("DB_NAME")
        
        # 3. 强制性配置检查 (Fail-fast 机制)
        # 意义：如果 .env 没写对，程序在初始化阶段就应该报错，而不是等运行到一半才崩溃。
        # all([...]) 会检查列表内是否所有元素都非空（即不是 None 或 ""）。
        if not all([self.user, self.host, self.db_name]):
            print("❌ 错误: 关键环境变量 (USER, HOST, 或 DBNAME) 缺失！")
            print("💡 解决: 请检查项目根目录下的 .env 文件是否配置正确。")
            sys.exit(1) # 强行退出程序，避免带错运行
        
        # 4. 动态构建连接 URL (Connection String)
        # f-string 语法：f"..." 允许在大括号 {} 中直接嵌入 Python 变量。
        if self.password:
            self.url = f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.db_name}"
        else:
            # 如果没密码（比如 Mac 本地信任连接），则去掉冒号部分
            self.url = f"postgresql://{self.user}@{self.host}:{self.port}/{self.db_name}"
        
        try:
            # 5. 创建 SQLAlchemy 引擎 (Engine)
            # pool_size: 连接池大小。预先创建 5 个连接待命，提高响应速度。
            # max_overflow: 允许临时额外创建的连接数，超过 5 个时最多再开 10 个。
            self.engine = create_engine(
                self.url,
                pool_size=5,
                max_overflow=10
            )
            print(f"🚀 DBManager: 数据库引擎初始化成功 (用户: {self.user})")
        except Exception as e:
            # 万一 URL 格式错或者驱动没装好，这里会捕获异常
            print(f"❌ 引擎创建失败: {e}")
            sys.exit(1)

    def get_df(self, sql: str):
        """
        核心功能方法：传入 SQL 指令，直接返回 Pandas 的 DataFrame 对象。
        """
        try:
            # 6. 使用上下文管理器 (with 语句)
            # 意义：它保证了无论查询是否报错，在 code block 结束时，连接都会自动归还给池子。
            # 这是防止数据库“连接泄露”的最重要手段。
            with self.engine.connect() as conn:
                # SQLAlchemy 2.0 强制规范：SQL 字符串必须通过 text() 转换
                return pd.read_sql(text(sql), conn)
        except Exception as e:
            print(f"❌ 查询失败: {e}")
            return None

# 测试代码块：只有当你直接运行 python db.py 时才会执行
if __name__ == "__main__":
    # 实例化类
    db = DBManager()
    
    # 编写测试 SQL
    test_query = "SELECT * FROM olist_mart.fact_order_wide_table LIMIT 5;"
    
    # 执行并接收结果
    result = db.get_df(test_query)
    
    # 结果非空则打印
    if result is not None:
        print("✅ 成功抓取数据样例：")
        print(result)

        