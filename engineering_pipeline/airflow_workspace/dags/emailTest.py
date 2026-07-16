from datetime import datetime, timedelta
import time
from airflow import DAG
from airflow.operators.python import PythonOperator
# 💡 核心引入：Airflow 官方内置的邮件发送工具
from airflow.utils.email import send_email

# =====================================================================
# 🚨 物理鸣笛：当任何 Task 彻底宣告暴毙时，Airflow 会自动执行这个回调函数
# =====================================================================
def send_failure_alert_email(context):
    """
    当任务彻底失败（重试次数用光）时，抓取上下文的错误信息，越过 SMTP 协议发射邮件
    """
    task_instance = context['task_instance']
    task_id = task_instance.task_id
    dag_id = task_instance.dag_id
    execution_date = context['execution_date']
    exception = context.get('exception')

    subject = f"❌ [Airflow 生产事故告警] {dag_id} - 任务 {task_id} 彻底暴毙！"
    
    html_content = f"""
    <h3>⚠️ 告警报告详情：</h3>
    <table border="1" cellpadding="5" cellspacing="0">
        <tr><td><b>流水线 ID (DAG)</b></td><td>{dag_id}</td></tr>
        <tr><td><b>失败节点 (Task)</b></td><td>{task_id}</td></tr>
        <tr><td><b>物理执行时间</b></td><td>{execution_date}</td></tr>
        <tr><td><b>最后一次重试报错</b></td><td style="color:red;">{exception}</td></tr>
    </table>
    <br>
    <p>🤖 <i>来自 Yuto 的 Airflow 容器集群自动化审计报告</i></p>
    """
    # 发射给你的接收邮箱
    send_email(to='2993529155@qq.com', subject=subject, html_content=html_content)

# =====================================================================
# ⚙️ 业务逻辑：测试卡死和超时（人为制造故障）
# =====================================================================
def run_heavy_bq_calculation():
    print("[Task] 开始执行繁重计算，进入无限睡眠状态...")
    # 💤 故意让程序物理休眠 60 秒，用来强行触发我们设置的 10 秒超时刹车线！
    time.sleep(60)
    print("[Task] 计算完成（这行日志绝不可能被打印，因为中途就会被超时斩杀）")

# =====================================================================
# ⚡ 核心参数对账：重试、间隔、超时、告警四位一体
# =====================================================================
default_args = {
    'owner': 'yuto',
    'depends_on_past': False,
    'retries': 2,                             # 💡 重试次数：2 次
    'retry_delay': timedelta(seconds=10),     # 💡 重试物理间隔：10 秒
    
    # 🛑 任务超时控制（Execution Timeout）
    # 意思是：任何节点只要通电执行超过 10 秒没干完，Scheduler 直接判定为僵尸进程，物理斩杀！
    'execution_timeout': timedelta(seconds=10),
    
    # 📧 自动邮件开关（如果只想用上面的自定义函数，这两个可以设为 False，这里作为双保险）
    'email': ['2993529155@qq.com'],     # 你的接收邮箱
    'email_on_failure': True,                 # 任务失败时自动发官方标准邮件
    'email_on_retry': False,                   # 重试时不发（免得轰炸邮箱）
    
    # 🔗 挂载自定义的毁灭级回调函数
    'on_failure_callback': send_failure_alert_email,
}

with DAG(
    dag_id='alert_and_timeout_pipeline',
    default_args=default_args,
    description='A highly secure DAG with timeout control and email alerts',
    schedule_interval=None,
    start_date=datetime(2026, 7, 1),
    catchup=False,
    tags=['security', 'test'],
) as dag:

    secure_task = PythonOperator(
        task_id='simulated_timeout_and_alert_task',
        python_callable=run_heavy_bq_calculation,
    )