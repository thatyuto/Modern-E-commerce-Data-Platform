spark/                              # 你的本地项目根目录（直接对应 GitHub 仓库）
│
├── .gitignore                      # 重点！告诉 Git 忽略哪些本地垃圾文件（如 .DS_Store, __pycache__）
├── README.md                       # 项目的灵魂：架构图、技术栈、运行指南（后续撰写）
│
└── src/                            # 核心大数据管道代码区
    │
    ├── 01_bronze/                  # 【铜牌层：贴源层】对应你计划表 Day1 的任务
    │   └── ingest_csv_to_delta.py  # 作用：无损对接，把原始 CSV 原封不动砸进湖仓换成 Delta 格式
    │
    ├── 02_silver/                  # 【银牌层：清洗与维度建模】对应 Day2、Day3 的高频核心区
    │   ├── dim_products.py         # 商品维度表（包含你 Day2 的三维体积计算、Day3 的多表 Join 翻译）
    │   ├── dim_customers.py        # 用户/地理位置维度表
    │   └── fct_orders.py           # 订单核心事实表
    │
    ├── 03_gold/                    # 【金牌层：业务集市与特征工程】对应 Day4 的大厂复现指标
    │   ├── report_sales_marts.py   # 电商核心业务指标分析（跑订单、用户、商品核心指标）
    │   └── feature_rfm_model.py    # 为后续大模型训练或营销准备的分布式 RFM 客户特征工程表
    │
    └── utils/                      # 【通用工具类】
        └── spark_session_builder.py# 专门用来初始化或管理 Spark 上下文对象的公共脚本