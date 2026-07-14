> **“Airflow是将零散、异构的计算任务（如 Python 脚本、SQL 批处理、Spark 作业），编排为具有确定拓扑执行顺序的有向无环图（DAG），并提供全局的状态听诊、失败重试与时间触发机制，解决大规模流水线在分布式环境下的无序性与不可控性。”**

---

## 一、 Airflow 的物理架构与核心组件作用

Airflow 并不是一个单一的计算引擎，它是一个分布式调度框架。电流在 Airflow 系统内部的流转依赖以下 4 个核心物理组件：

### 1. 调度器 (Scheduler) —— 系统的“中央大脑”

* **学术定义**：基于时间轮询与事件驱动的常驻进程（Daemon）。
* **工程作用**：它持续扫描用户编写的 DAG 代码，监测当前时间是否触发了定时器（如 Crontab 表达式），并对依赖关系进行拓扑排序。一旦发现某个前置任务执行成功且满足触发条件，它就会将该任务投递到任务队列中。**它不负责干苦力，只负责分发令牌**。

### 2. 执行器 (Executor) —— “运筹与兵力分配中心”

* **学术定义**：任务分发策略的抽象层。
* **工程作用**：它决定了任务以何种物理形式运行。
* `LocalExecutor`：电流直接在本地起多个进程跑任务。
* `CeleryExecutor` / `KubernetesExecutor`：执行器将任务打包发送给分布式的 Worker 节点或动态拉起一个 K8s Pod。**它负责决定把活派给谁、怎么派**。



### 3. 工作节点 (Worker) —— “物理算力车间”

* **学术定义**：实际消耗 CPU 和内存的计算实例。
* **工程作用**：监听任务队列，一旦拿到执行器派发过来的任务令牌，立刻通电起爆对应的业务代码（如跑你的 Olist ETL 容器）。

### 4. 元数据库 (Metadata Database) —— “状态生死簿”

* **学术定义**：系统状态的强一致性持久化层（通常为 PostgreSQL 或 MySQL）。
* **工程作用**：记录所有 DAG 的物理定义、每个任务（Task）历史运行状态（成功、失败、运行中、重试中）、耗时日志路径。**调度器做任何决策前，都必须先用电流读取元数据库，确保状态不错乱**。

---

## 二、 Airflow 的三大核心编程概念

在编写 Airflow 调度代码时，主要通过以下三个核心概念进行逻辑映射：

```
      ┌───────────────── DAG (有向无环图) ─────────────────┐
      │                                                   │
      │   ┌──────────────┐       ┌──────────────┐         │
      │   │ Task A       │──────►│ Task B       │         │
      │   │ (Operator 1) │       │ (Operator 2) │         │
      │   └──────────────┘       └──────────────┘         │
      └───────────────────────────────────────────────────┘

```

### 1. DAG (Directed Acyclic Graph - 有向无环图)

* **概念**：你在 Python 文件里定义的一个图对象。
* **物理映射**：它划定了整条流水线的**物理边界与执行方向**。它规定了任务必须先走 A，再走 B，绝对不允许出现环路（比如 A $\rightarrow$ B $\rightarrow$ A），否则调度器在做拓扑排序时电流会陷入死循环。

### 2. Operator (算子 / 物理驱动器)

* **概念**：Airflow 预先封装好的通用任务模版类。
* **物理映射**：它是具体的“冷兵器”。Airflow 的原则是“调度与计算分离”，Operator 就是连接计算引擎的接口：
* `BashOperator`：通电后，在 Worker 节点直接触发一行 Bash 命令。
* `DockerOperator`：（极其适合你当前阶段的演进）通电后，直接调用宿主机的 Docker Daemon，拉起你烧录好的 `yuto-etl-engine` 镜像，并自动挂载目录跑批。
* `PythonOperator`：直接在本地调用一个 Python 函数。



### 3. Task (任务 / 算子实例)

* **概念**：Operator 被具体实例化后的对象（DAG 中的一个节点）。
* **物理映射**：当 Operator 注入了具体的参数（如 `task_id='run_olist_orders'`），它就变成了一个 Task。

---

## 三、 从按下触发（Trigger）到日志刷屏：电流的生命周期时序

当你在 Web 界面上按下 "Trigger DAG" 按钮时，电流的物理接力过程如下：

```
[Web UI / CLI 按下 Trigger]
       │
       ▼
 1. 物理写入元数据库 (Metadata DB) ──► (状态被标记为 Queued)
       │
       ▼
 2. Scheduler 扫描察觉           ──► (通过电流读取 DB，发现有任务在排队，进行拓扑排序)
       │
       ▼
 3. Executor 派发令牌           ──► (将 Task 扔进队列，状态变更为 Running)
       │
       ▼
 4. Worker 捕获任务             ──► (开辟独立的内存与进程，激活相应的 Operator)
       │
       ├─► 情况 A: 执行成功 ──► (Worker 回写 DB 状态为 Success ──► 激活下游 Task B)
       │
       └─► 情况 B: 遭遇报错 ──► (Worker 触发异常捕获 ──► 回写 DB 为 Up_For_Retry 或 Failed)

```

1. **第一步：电流写入元数据库**：你的 Trigger 请求首先被转化为一条 SQL 插入语句，死死写入 PostgreSQL 元数据库，将该 DAG 的实例状态标记为 `Queued`（排队中）。
2. **第二步：调度器激活**：`Scheduler` 进程通过电流定期轮询元数据库，发现了这个 `Queued` 实例。CPU 开始计算该 DAG 内部的 Task 依赖拓扑图，确认第一步的任务（Task A）可以执行。
3. **第三步：执行器与队列接力**：`Scheduler` 将 Task A 移交给 `Executor`。`Executor` 把任务信息打入物理队列，并将元数据库中的任务状态改写为 `Running`。
4. **第四步：Worker 物理起爆**：分布式的某个 `Worker` 节点通过网络电流监听到了队列中的任务，立刻将其拉取到本地内存中。Worker 启动一个独立的进程，开始真正执行算子里定义的代码（例如发起系统调用去执行 `docker run` 跑你的 ETL）。
5. **第五步：状态闭环反馈**：
* **若运行成功**：Worker 进程向元数据库发送更新电流，状态置为 `Success`。调度器察觉后，立刻放行下游的 Task B，开始下一轮电流循环。
* **若运行暴毙**：Worker 捕获到 Python 异常，直接将状态回写为 `Failed`（或触发 `retries` 参数进行倒计时重试），并把错误日志物理固化到磁盘上，同时触发报警（如发邮件）。

## 如何理解，编写一个docker-compose.yaml文件？

可copy模版
```bash
version: '3.8'
services:
  # 1. Airflow 数据库 PostgreSQL
  postgres:
    image: postgres:13
    environment:
      - POSTGRES_USER=airflow
      - POSTGRES_PASSWORD=airflow
      - POSTGRES_DB=airflow
      - TZ=Asia/Shanghai  # 统一时区
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  # 2. Airflow Web 控制台服务
  airflow-webserver:
    image: apache/airflow:2.7.2-python3.10
    depends_on:
      - postgres
    environment:
      - TZ=Asia/Shanghai
      - AIRFLOW__CORE__EXECUTOR=LocalExecutor
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
      - AIRFLOW__CORE__LOAD_EXAMPLES=False
      - AIRFLOW__CORE__PARALLELISM=16  # 任务并发上限
      - AIRFLOW__WEBSERVER__EXPOSE_CONFIG=True
    ports:
      - "8080:8080"
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
      - ./plugins:/opt/airflow/plugins  # 补充插件目录
    command: webserver
    restart: always

  # 3. Airflow 调度器（拆分独立进程，稳定可靠）
  airflow-scheduler:
    image: apache/airflow:2.7.2-python3.10
    depends_on:
      - postgres
    environment:
      - TZ=Asia/Shanghai
      - AIRFLOW__CORE__EXECUTOR=LocalExecutor
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
      - AIRFLOW__CORE__LOAD_EXAMPLES=False
      - AIRFLOW__CORE__PARALLELISM=16
    volumes:
      - ./dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
      - ./plugins:/opt/airflow/plugins
    command: scheduler
    restart: always

  # 一次性初始化容器：仅执行一次DB迁移+创建管理员，执行完自动销毁
  airflow-init:
    image: apache/airflow:2.7.2-python3.10
    depends_on:
      - postgres
    environment:
      - TZ=Asia/Shanghai
      - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
      - _AIRFLOW_DB_UPGRADE=true
      - _AIRFLOW_WWW_USER_CREATE=true
      - _AIRFLOW_WWW_USER_USERNAME=admin
      - _AIRFLOW_WWW_USER_PASSWORD=admin
      - _AIRFLOW_WWW_USER_FIRSTNAME=Yuto
      - _AIRFLOW_WWW_USER_LASTNAME=Wong
      - _AIRFLOW_WWW_USER_EMAIL=yuto@example.com
    volumes:
      - ./dags:/opt/airflow/dags
      - ./plugins:/opt/airflow/plugins
    command: version  # 触发官方内置初始化脚本
    restart: "no"

volumes:
  postgres_data:
```
# docker-compose.yml 核心掌握内容分层解析
## 一、基础语法层（必须吃透，写任何compose都通用）
### 1. `version: '3.8'`
- 作用：定义docker-compose配置文件语法规范版本，3.8兼容Docker 20.10+
- 要点：版本号会决定你能使用的配置字段（如restart、volumes挂载、depends_on逻辑），不要随意降低版本。

### 2. `services`：所有容器服务都写在这里，同级缩进（YAML缩进致命规则）
YAML语法铁则：
- 同级服务必须对齐（postgres、airflow-webserver、airflow-scheduler、airflow-init 全部同一缩进层级）
- 子配置（environment、ports、volumes）必须比父服务多2空格缩进
- 冒号后必须加空格，字符串不用引号，端口/连接串建议双引号

### 3. 通用公共字段（所有service都能用，重点掌握）
#### (1) `image`
指定容器镜像名称+标签，格式 `仓库/镜像名:版本`
示例：`apache/airflow:2.7.2-python3.10`
- 镜像名写错、标签带空格会直接拉取失败；
- airflow镜像区分python版本，必须和你本地DAG脚本python版本匹配。

#### (2) `depends_on`
容器启动依赖顺序：当前容器**等依赖容器先启动**再启动
例：airflow所有服务都依赖postgres，会等postgres容器拉起后才启动web/scheduler/init
⚠️ 局限：只保证**容器启动顺序**，不保证数据库服务就绪（postgres容器启动不代表数据库能连），复杂场景要加等待脚本。

#### (3) `environment` 环境变量数组
格式 `- KEY=VALUE`，用来注入容器内程序配置，Airflow所有配置都靠环境变量控制，核心重点。

#### (4) `ports: "宿主机端口:容器内部端口"`
端口映射，外部访问宿主机端口转发到容器内部服务
- postgres：`5432:5432` → 本地Navicat用localhost:5432连数据库
- airflow-webserver：`8080:8080` → 浏览器localhost:8080访问后台

#### (5) `volumes` 数据挂载（持久化核心）
两种挂载方式：
1. **命名卷**：`postgres_data:/var/lib/postgresql/data`
   左侧是底部`volumes`定义的命名卷，数据存在docker内部，删除容器数据不丢；
2. **绑定挂载（本地目录映射）**：`./dags:/opt/airflow/dags`
   左侧宿主机相对路径，右侧容器内路径，本地改文件容器实时生效，开发DAG必备。

#### (6) `restart` 重启策略
- `restart: always`：容器退出就自动重启（web、scheduler、数据库常驻服务用）
- `restart: "no"`：退出不重启（一次性初始化容器airflow-init专用，执行完销毁）

#### (7) `command` 覆盖容器默认启动命令
airflow官方镜像默认会启动shell，这里手动指定 `webserver` / `scheduler` 直接拉起对应进程；
airflow-init用`version`只是触发内置初始化脚本，执行完立刻退出。

## 二、Postgres数据库服务（Airflow底层存储，必学）
```yaml
postgres:
  image: postgres:13
  environment:
    - POSTGRES_USER=airflow     # 数据库账号
    - POSTGRES_PASSWORD=airflow  # 密码
    - POSTGRES_DB=airflow        # 自动创建的库名
    - TZ=Asia/Shanghai           # 数据库时区
  ports:
    - "5432:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
  restart: always
```
### 核心知识点
1. 三个内置环境变量：`POSTGRES_USER / PASSWORD / DB`，postgres镜像会自动创建账号和数据库，Airflow连接串必须和这三个值完全对应；
2. `TZ=Asia/Shanghai`：统一北京时间，避免UTC时差导致定时任务错乱；
3. 命名卷`postgres_data`：持久化元数据（DAG执行记录、任务状态、账号、连接配置），删掉容器数据不会丢失；
4. 用途：Airflow 2.x强制替代轻量SQLite，支持多并发任务、稳定存储调度元数据。

## 三、Airflow三大服务分工（Airflow核心逻辑，重中之重）
### 1. airflow-webserver：可视化管理后台
- command: `webserver`
- 端口8080，浏览器操作页面：查看DAG、手动触发任务、看日志、配置账号/连接、监控运行状态；
- 只负责前端页面展示，**不执行定时任务**。

### 2. airflow-scheduler：调度核心引擎
- command: `scheduler`
- Airflow心脏：定时扫描`dags`文件夹下调度脚本，根据schedule_interval自动触发任务、分配执行；
- 一旦这个容器挂掉，所有定时任务全部停止；所以配置`restart: always`保障常驻。

### 3. airflow-init：一次性初始化容器（官方标准最佳实践）
不会常驻，仅第一次启动执行，执行完自动退出销毁，解决2个痛点：
1. `_AIRFLOW_DB_UPGRADE=true`：自动执行`airflow db migrate`，创建/升级数据库表结构，不用手动敲命令；
2. 一组`_AIRFLOW_WWW_USER_*`变量：自动创建管理员账号admin/admin，无需手动执行`airflow users create`；
优势：容器重启不会重复执行建表、建用户命令，不会报冲突报错。

## 四、Airflow专属核心环境变量（调优、配置必背）
### 数据库连接串
```
AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@postgres/airflow
```
格式拆解：`数据库驱动://账号:密码@服务名/库名`
- postgres：compose里postgres服务名，docker内部DNS自动解析，不用写IP；
- 账号密码库名必须和postgres环境变量一一对应，写错直接连不上数据库。

### 执行器配置
`AIRFLOW__CORE__EXECUTOR=LocalExecutor`
- LocalExecutor：单机开发专用，任务和调度器在同一台机器运行；
- 生产分布式集群替换为CeleryExecutor/KubernetesExecutor。

### 开发常用开关
1. `AIRFLOW__CORE__LOAD_EXAMPLES=False`：关闭官方自带示例DAG，页面干净，避免干扰；
2. `AIRFLOW__CORE__PARALLELISM=16`：全局最大并发任务数，根据机器CPU内存调大；
3. `AIRFLOW__WEBSERVER__EXPOSE_CONFIG=True`：后台页面显示全部配置参数，调试方便；
4. `TZ=Asia/Shanghai`：全局调度时区，所有DAG定时基于北京时间。

## 五、Volumes 数据持久化体系（本地开发必备）
### 1. 底部顶层配置 volumes: postgres_data
声明命名卷，由Docker管理，存放Postgres数据库文件，生命周期独立于容器。

### 2. 绑定挂载目录（本地 ↔ 容器映射）
1. `./dags:/opt/airflow/dags`
   本地`dags`文件夹存放你的调度Python脚本，Airflow实时读取，本地修改不用重建镜像；
2. `./logs:/opt/airflow/logs`
   所有任务运行日志持久化，本地直接打开查看，不用进容器；
3. `./plugins:/opt/airflow/plugins`
   自定义算子、钩子、工具插件目录，拓展Airflow能力。

### 实操前置要求
启动前必须在yml同级手动创建3个文件夹，否则挂载报错：
```bash
mkdir dags logs plugins
```

## 六、完整启动/运维命令（实操必须掌握）
```bash
# 1. 后台静默启动所有服务（自动执行airflow-init初始化）
docker-compose up -d

# 2. 实时查看全部容器日志（调试报错用）
docker-compose logs -f

# 3. 单独看调度器日志（任务不执行优先查这个）
docker-compose logs -f airflow-scheduler

# 4. 停止服务，保留数据库数据
docker-compose down

# 5. 彻底销毁服务+清空数据库数据（重置环境）
docker-compose down -v
```

## 七、架构逻辑总结（整体认知）
1. Postgres：底层元数据存储；
2. airflow-init：一次性初始化库表、管理员账号；
3. airflow-scheduler：核心调度引擎，自动跑定时任务；
4. airflow-webserver：可视化操作页面；
5. 本地dags/logs/plugins挂载：实现本地开发，不用打包镜像。

## 八、分阶段学习优先级
1. 基础compose语法（version/services/image/ports/volumes/environment/restart）→ 通用能力，所有docker项目通用
2. Postgres容器配置、连接串规则 → Airflow运行基础
3. Airflow四大容器分工、各自作用 → 理解调度底层逻辑
4. Airflow环境变量含义、调优参数 → 开发调试DAG必备
5. 挂载目录作用、启停运维命令 → 日常实操使用

