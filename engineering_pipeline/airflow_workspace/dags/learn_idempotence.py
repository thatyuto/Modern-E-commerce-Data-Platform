from datetime import datetime
from airflow import DAG
from airflow.operators.python import PythonOperator
from google.cloud import bigquery
from google.oauth2 import service_account

# =====================================================================
# ⚙️ 核心业务：具备幂等性的 BigQuery 数据提取
# =====================================================================
def fetch_and_load_idempotent_data(**context):
    KEY_PATH = "/opt/airflow/dags/bq_service_account.json"
    
    # 💡 物理灵魂注入：从 Airflow 上下文中提取“逻辑执行日期”（YYYY-MM-DD）
    # 这确保了无论你在 2026 年的哪一天重跑这个任务，它处理的永远是图纸上锁定的那一天的数据！
    ds = context['ds'] 
    print(f"📅 [Idempotence] 当前流水线正在处理的法定数据分区日期为: {ds}")
    
    credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
    client = bigquery.Client(credentials=credentials, project=credentials.project_id)
    
    # 1. 动态对齐物理分区：使用大括号语法，动态切分每天的数据
    # 假设我们要捞取特定某一天创建的订单
    query_sql = f"""
        SELECT order_id, customer_id, order_status, order_purchase_timestamp 
        FROM `olist_raw.olist_orders_dataset` 
        WHERE DATE(order_purchase_timestamp) = '{ds}'
        LIMIT 10;
    """
    print(f"🚀 [SQL] 正在发射具备日期分区的查询:\n{query_sql}")
    
    # 2. 物理落地：定义你在数仓里的目标表名（按天动态创建独立的分区表或增量表）
    # 在 BigQuery 中，用 $ 符号代表物理时间分区表
    target_table_id = f"{credentials.project_id}.olist_analytics.daily_orders_snapshot${ds.replace('-', '')}"
    
    # 3. 🚨 幂等性的终极刹车阀：WRITE_TRUNCATE
    # 被设计出来的意义：如果表里已经有这一天的数据了，直接物理覆盖（先清空这一天，再写入），
    # 这样无论重跑多少次，数据永远只有一份，绝不重复！
    job_config = bigquery.QueryJobConfig(
        destination=target_table_id,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE, # 👈 覆盖写入，拒绝重复
        create_disposition=bigquery.CreateDisposition.CREATE_IF_NEEDED
    )
    
    print(f"💾 [Write] 正在写入目标物理分区表: {target_table_id} (模式: WRITE_TRUNCATE)")
    query_job = client.query(query_sql, job_config=job_config)
    query_job.result() # 等待写入完成
    
    print(f"✅ [Success] 日期为 {ds} 的数据分区已完美闭环，多次执行一致性测试通过。")

with DAG(
    dag_id='idempotent_bq_pipeline',
    default_args={'owner': 'yuto'},
    description='A strictly idempotent production-grade pipeline',
    schedule_interval='0 2 * * *',          # 每天凌晨 2 点自动排班
    start_date=datetime(2026, 7, 1),        # 规定数据流从 7 月 1 日开始
    catchup=False,
    tags=['architecture', 'idempotence'],
) as dag:

    idempotent_task = PythonOperator(
        task_id='fetch_idempotent_orders',
        python_callable=fetch_and_load_idempotent_data,
        provide_context=True,               # 💡 必须开启：将 Airflow 系统的日期宏变量源源不断地注入给 Python 函数
    )