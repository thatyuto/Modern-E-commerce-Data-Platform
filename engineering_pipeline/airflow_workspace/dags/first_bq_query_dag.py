from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
# 引入谷歌驱动
from google.cloud import bigquery
from google.oauth2 import service_account


# 核心业务函数
def run_bq_query():
    KEY_PATH = '/opt/airflow/dags/bq_service_account.json'

    try:
        print("开始执行BigQuery查询任务...")
        # 灌入钥匙文件，生成认证凭证
        credentials = service_account.Credentials.from_service_account_file(KEY_PATH)

        # 实例化BQ客户端实体
        client = bigquery.Client(credentials=credentials, project=credentials.project_id)
        print(f"BigQuery连接成功，当前认证的 GCP 项目 ID 为: {client.project}")
        
        # 锁定你想要执行的真实的SQL算子
        query_sql = "SELECT order_id, order_status FROM `olist_raw.olist_orders_dataset` LIMIT 10;"
        print(f"正在执行SQL查询：{query_sql}")

        # 通电，拉起云端分布式计算引擎
        query_job = client.query(query_sql)
        results = query_job.result()  # 等待查询完成并获取结果
        print("🎉 [BigQuery] 数据回传成功！前几行测试数据如下：")
        for row in results:
            print(f"order_id: {row.order_id}, order_status: {row.order_status}")
    
    except Exception as e:
        print(f"❌ 数据查询失败: {e}")

default_args = {
    'owner': 'yuto',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# 装配流程图大盘
with DAG(
    dag_id='first_bq_query_pipeline',
    default_args=default_args,
    description='A simple DAG to run a BigQuery query',
    schedule_interval='0 1 * * *',
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=['olist','test'],
) as dag:
    # 实例化Task节点
    bq_query_task = PythonOperator(
        task_id='execute_bq_snapshot_query',
        python_callable=run_bq_query,
    )

    bq_query_task  # 设置任务依赖关系（如果有多个任务，可以在这里设置依赖关系）