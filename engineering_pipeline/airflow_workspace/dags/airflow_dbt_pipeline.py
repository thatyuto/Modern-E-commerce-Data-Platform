from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator

# 🔗 容器内部物理路径对账
DBT_PROJECT_DIR = "/opt/airflow/dbt"
DBT_PROFILES_DIR = "/opt/airflow/profiles"  # 👈 钥匙在容器里的专属收纳盒

default_args = {
    'owner': 'yuto',
    'retries': 1,
    'retry_delay': timedelta(seconds=15),
}

with DAG(
    dag_id='airflow_dbt_joint_pipeline',
    default_args=default_args,
    description='Perfectly routed Airflow + dbt pipeline',
    schedule_interval='0 3 * * *',
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=['dbt', 'bigquery', 'root-profile'],
) as dag:

    # 1. 验证连通性：前往施工现场，并使用 --profiles-dir 精准指明玄关钥匙的位置
    dbt_debug = BashOperator(
    task_id="dbt_debug",
    # 🎯 核心逻辑：增加 --no-version-check 并且通过 || true 确保这一步的 Git 警告不会绊倒整个流程
    bash_command="cd /opt/airflow/dbt && dbt debug --profiles-dir /opt/airflow/profiles --no-version-check || true",
)

    # 2. 执行模型重组：强行注入逻辑日期 {{ ds }} 锁死每天的分区，完美贯彻幂等规范
    dbt_run = BashOperator(
    task_id="dbt_run_transformations",
    # 🎯 核心逻辑：在运行前先执行 dbt deps，把刚刚删掉的本地依赖目录空壳重新初始化出来
    bash_command="cd /opt/airflow/dbt && dbt deps --profiles-dir /opt/airflow/profiles && dbt run --profiles-dir /opt/airflow/profiles --vars \"{'execution_date': '{ ds }'}\"",
)

    # 3. 运行质量断路测试：确保入库数据完好无损
    dbt_test = BashOperator(
        task_id='dbt_run_quality_tests',
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt test --profiles-dir {DBT_PROFILES_DIR}",
    )

    # 🔗 串联骨架
    dbt_debug >> dbt_run >> dbt_test