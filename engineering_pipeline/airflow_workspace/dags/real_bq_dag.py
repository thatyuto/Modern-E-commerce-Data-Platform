from datetime import datetime, timedelta
import random
from airflow import DAG
from airflow.operators.python import PythonOperator
from google.cloud import bigquery
from google.oauth2 import service_account

def run_bq_query():
    KEY_PATH = "/opt/airflow/dags/bq_service_account.json" # Update with your service account key path
    try:
        print("Starting BigQuery query execution...")
        credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
        client = bigquery.Client(credentials=credentials, project=credentials.project_id)

        # 模拟暴毙
        if random.random() < 0.5:
            print("Simulating a system crash...")
            raise ConnectionError("GCP BigQuery API Connection Timeout (Simulated)")
        
        query_sql = "SELECT order_id, order_status FROM `olist_raw.olist_orders_dataset` LIMIT 10;"
        print(f"🚀 [Task 1] 正在向谷歌云发射 SQL: {query_sql}")
        query_job = client.query(query_sql)
        results = query_job.result()  # Wait for the job to complete.
        for row in results:
            print(f"Order ID: {row.order_id}, Order Status: {row.order_status}")

    except Exception as e:
        print(f"Error during query execution: {e}")
        raise e


# =====================================================================
# ⚙️ 任务 2 的业务逻辑：本地数据备份（必须等任务 1 成功拿回数据后才能跑）
# =====================================================================
def local_data_backup():
    print("💾 [Task 2] 正在将 Task 1 捞回的 Olist 订单快照写入本地持久化 DB...")
    print("✅ [Task 2] 备份完成，本地 SQLite 数据库已更新。")


default_args = {
    'owner': 'yuto',
    'depends_on_past': False,
    'retries': 3,
    'retry_delay': timedelta(seconds=15),
}

with DAG(
    dag_id='real_bq_dag',
    default_args=default_args,
    description='A linear pipeline with retry and dependency tracking',
    schedule_interval=None,
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=['olist','dependency_test'],
) as dag:
    # 1声明节点A：提取数据
    extract_task = PythonOperator(
        task_id='gcp_extract_bigquery',
        python_callable=run_bq_query,
    )

    # 2声明节点B：备份数据
    backup_task = PythonOperator(
        task_id='local_data_backup',
        python_callable=local_data_backup,
    )

# =====================================================================
# 🔗 核心子任务物理闭环：构建线性依赖
# =====================================================================
# 意思：必须 extract_task 成功，才能触发 backup_task。否则后者直接被 Block
extract_task >> backup_task