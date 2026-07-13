# Docker核心概念与工业级实战全手册
## 目录
1. 三大核心概念：Image、Container、Registry
2. 业务生产背景
3. Docker完整落地实战流程
    3.1 第一步：构建镜像（Image）
    3.2 第二步：启动容器（Container）
    3.3 第三步：镜像云端分发（Registry）
4. Docker流程核心公式
5. 工业级Dockerfile模板
    5.1 通用极简模板
    5.2 带完整注释生产模板
6. 镜像构建原理与build命令详解
7. .dockerignore 文件作用与通用模板
8. 多阶段构建 multi-stage builds
9. 容器基础运维命令
    9.1 基于镜像创建容器
    9.2 日志流式观测 docker logs
    9.3 进入容器交互式操作 docker exec
10. 运维排错：logs 与 exec 使用场景区分
11. 容器生命周期管理
    11.1 优雅停止容器 docker stop
    11.2 删除容器 docker rm
    11.3 删除容器使用场景与资源释放逻辑
12. 卷挂载 Volume Mounting 核心作用
13. docker_modular 工程目录6大文件规范
    13.1 文件编写先后顺序
    13.2 文件依赖拓扑关系
    13.3 各文件工程职责

---

# 1. 三大核心概念：Image、Container、Registry
## 1.1 镜像 Image —— 静态只读蓝图/固化系统模板
**存在意义**
镜像是只读静态模板，内置应用完整运行依赖：精简操作系统 + 指定版本运行时 + 业务代码。

**架构师视角**
等价面向对象编程中的 Class（类），如同冷冻封存的模板。存储在磁盘，不占用CPU、内存；文件只读、不可篡改。

## 1.2 容器 Container —— 运行实例/活性进程实体
**存在意义**
容器是镜像运行后的实例。执行 `docker run` 时，Linux内核分配独立隔离运行空间，将静态镜像激活为可运行程序。

**架构师视角**
等价 `new Class()` 实例化后的 Object 对象。支持启动、停止、删除；容器内部所有修改仅存在临时可写层，删除容器后底层镜像完全不受破坏，不会污染宿主机系统。

## 1.3 仓库 Registry / Docker Hub —— 镜像分发云端仓库
**存在意义**
集中存储、托管、分发镜像的云端服务，行业主流官方仓库为 Docker Hub。

**架构师视角**
等同于代码托管平台GitHub、依赖源Maven/PyPI。开发者本地构建镜像推送至仓库，任意服务器可直接拉取镜像快速部署，统一全环境运行底座。

# 2. 业务生产背景
需求：开发Python实时监控脚本，每秒扫描订单目录。
痛点：本地Mac、DTU/Chalmers实验室服务器、AWS云端集群环境不一致，Python版本、第三方库差异导致程序运行异常。
解决方案：使用Docker打包标准化镜像，实现全环境运行环境完全统一。

# 3. Docker完整落地实战流程
## 3.1 第一步：构建镜像 —— Image 生成
### 3.1.1 编写业务代码 app.py
```python
# app.py
import time
print("🛰️ [Yuto Stream Monitor] 订单高频雷达开始通电监听...")
while True:
    print("⚙️ 正在扫描 Volumes 目录，当前未发现欺诈大单，状态：安全。")
    time.sleep(1)
```

### 3.1.2 编写构建配置 Dockerfile
```dockerfile
FROM python:3.10-slim
COPY app.py /app/app.py
WORKDIR /app
CMD ["python", "app.py"]
```

### 3.1.3 执行构建命令生成镜像
```bash
docker build -t yuto-monitor:v1 .
```
**技术原理**
Docker引擎整合精简Linux文件系统、Python3.10运行环境、业务代码，分层压缩固化为约100MB只读二进制文件。
产物 `yuto-monitor:v1` 即为镜像，静态存储在磁盘，不占用内存。

## 3.2 第二步：启动容器 —— Container 实例活化
镜像为静态文件，通过run命令生成运行中的容器进程。
### 3.2.1 后台启动容器
```bash
docker run -d --name live-radar yuto-monitor:v1
```
**技术原理**
Linux内核创建独立Namespace隔离环境，在只读镜像上层新增一层微型可写临时层；容器内部PID=1的Python主进程启动，占用CPU、内存持续执行业务逻辑。

### 3.2.2 查看运行中容器
```bash
docker ps
```
输出可查看 `live-radar` 运行状态、启动时长。

### 3.2.3 查看容器输出日志
```bash
docker logs live-radar
```
实时查看脚本打印监控信息，验证业务逻辑正常运行。

## 3.3 第三步：镜像云端分发 —— Registry 跨机器部署
本地Mac测试完成后，将镜像推送至Docker Hub，北欧实验室服务器直接拉取运行，无需U盘传输镜像文件。
### 3.3.1 镜像绑定仓库标签
```bash
docker tag yuto-monitor:v1 yutohuang/datacenter:monitor-v1
```

### 3.3.2 推送镜像至云端仓库
```bash
docker push yutohuang/datacenter:monitor-v1
```
**技术原理**
Docker守护进程将镜像分层Tar压缩包，通过网络上传至Docker Hub分布式存储。

### 3.3.3 远程服务器一键部署
实验室Linux服务器仅安装Docker引擎，直接执行：
```bash
docker run -d yutohuang/datacenter:monitor-v1
```
**最终效果**
服务器本地无对应镜像时自动从仓库拉取镜像，瞬间实例化容器进程；运行环境、代码逻辑与本地完全一致。

# 4. Docker流程核心公式
$$\text{Dockerfile (构建图纸)} \xrightarrow{\text{docker build}} \textbf{Image (只读静态镜像)} \xrightarrow{\text{push/pull}} \textbf{Registry (云端仓库)}$$
$$\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\quad\Downarrow \text{docker run}$$
$$\textbf{Container (内存活性进程 + 临时可写层)}$$

# 5. 工业级Dockerfile模板
## 5.1 通用极简模板
```dockerfile
# 1. 基础镜像层：固定语言+精简镜像
FROM 语言:版本-slim

# 2. 全局工作目录层
WORKDIR /project

# 3. 优先拷贝依赖文件（缓存优化核心）
COPY requirements.txt /project/

# 4. 安装依赖层（无缓存缩小镜像体积）
RUN pip install --no-cache-dir -r requirements.txt

# 5. 拷贝业务代码层（代码变更不重装依赖）
COPY . /project/

# 6. 容器启动入口
CMD ["python", "main.py"]
```

## 5.2 带完整注释生产模板
```dockerfile
# =====================================================================
# Layer 1: 基础镜像底座
# 指令：FROM
# 作用：定义镜像底层系统与Python解释器，所有工具、环境依赖基于该镜像
# 选型 python:3.10-slim 优势：
# 1. slim精简版移除gcc、冗余系统库、文档，体积比完整版小80%
# 2. 官方镜像安全可信，漏洞修复及时，生产标准选型
# 3. 锁定Python3.10版本，杜绝跨环境版本漂移
# 价值：缩小镜像体积、加速推拉、减少攻击面
# =====================================================================
FROM python:3.10-slim

# =====================================================================
# Layer 2: 容器工作目录
# 指令：WORKDIR
# 作用：自动创建/app目录，后续RUN/COPY/CMD默认以此为工作目录，等价自动cd /app
# 优势：统一项目路径，简化指令、方便运维排查文件
# =====================================================================
WORKDIR /app

# =====================================================================
# Layer 3: 拷贝依赖清单与代码
# 指令：COPY
# 分层优化逻辑：单独拷贝requirements.txt，利用Docker分层缓存
# 1. 仅修改业务代码时，依赖层缓存复用，无需重装库
# 2. 仅修改依赖文件时，才执行pip安装
# 工业标准写法，大幅缩短构建耗时
# =====================================================================
COPY app.py requirements.txt /app/

# =====================================================================
# Layer 4: 安装第三方依赖
# 指令：RUN（仅构建镜像阶段执行）
# 参数 --no-cache-dir：关闭pip本地缓存，防止镜像体积膨胀数十MB
# 为什么不在本地装好再拷贝：宿主机与容器环境隔离，本地包无法复用
# 价值：保证容器依赖纯净统一，隔离本地开发环境污染
# =====================================================================
RUN pip install --no-cache-dir -r requirements.txt

# =====================================================================
# Layer 5: 容器启动命令
# 指令：CMD（仅容器run运行时执行，构建阶段不运行）
# 数组格式 ["python", "app.py"] 生产推荐：
# 1. 不经过shell解析，避免环境变量转义、信号丢失
# 2. 容器收到kill信号可直接传递给Python进程，实现优雅关闭
# 区分：RUN=构建执行；CMD=容器启动执行
# =====================================================================
CMD ["python", "app.py"]
```

# 6. 镜像构建原理与build命令详解
## 6.1 基础构建命令
```bash
docker build -t 镜像名称:镜像版本 .
```
末尾 `.` 代表**构建上下文目录**。

## 6.2 docker build 核心作用
读取Dockerfile + 上下文目录文件，分层生成镜像；自动分层缓存、拷贝文件、执行命令、配置容器运行参数。

## 6.3 上下文限制说明
dockerd是独立后台进程，与终端隔离；出于安全限制，Dockerfile仅能读取上下文文件夹内文件，无法访问宿主机其他路径。

## 6.4 build完整执行流程
1. Docker客户端扫描上下文目录；
2. 打包目录全部文件（自动排除.dockerignore匹配内容）；
3. 将压缩包传输给后台dockerd；
4. Dockerfile中COPY/ADD仅能读取打包内文件。

# 7. .dockerignore 文件作用与通用模板
## 7.1 核心作用
构建镜像时过滤上下文内无关文件，两大收益：
1. 缩小打包体积，加快构建、推送速度；
2. 避免本地缓存、密钥、IDE配置意外打入镜像，提升容器安全。
仅作用于构建上下文，不影响基础镜像内部文件。

## 7.2 文件存放规范
与Dockerfile放置同一根目录，固定文件名 `.dockerignore`。

## 7.3 通用模板
```bash
# Git相关文件
.git
.gitignore
.gitlab-ci.yml
.github/

# Python/项目缓存与依赖文件夹
node_modules/
venv/
__pycache__/
*.pyc
target/
build/
dist/

# 日志、临时文件
*.log
*.tmp
*.swp
.DS_Store
Thumbs.db

# 本地环境密钥配置（禁止打入镜像）
.env
.env.local
.env.dev
docker-compose.yml
docker-compose.*.yml

# IDE配置文件
.idea/
.vscode/
*.sublime-*

# 本地打包产物（容器内重新生成，无需本地文件）
*.tar
*.zip
```

# 8. 多阶段构建 multi-stage builds
## 8.1 核心价值
拆分构建阶段，剥离编译工具、临时依赖，大幅缩减最终镜像体积。

## 8.2 原理说明
以Python numpy举例：numpy由C语言编译，编译需要gcc编译器。
- 单阶段构建：必须携带gcc完整Python镜像，体积可达1GB；编译完成后gcc不再使用，持续占用空间。
- 多阶段构建：
  Stage1：完整Python镜像（带gcc）编译第三方库；
  Stage2：仅使用slim精简Python镜像，拷贝编译完成的库；
  Stage1为临时镜像，构建完成可直接删除；最终成品镜像仅200MB。

## 8.3 分发逻辑（关键结论）
他人拉取镜像**只会下载最终Stage2成品镜像，不会执行Stage1编译流程**
1. 本地构建：完整执行Stage1临时构建 + Stage2成品镜像；仅最后阶段镜像可打tag推送；Stage1本地临时存储，无标签。
2. push推送：仅上传200MB最终镜像，1G builder镜像不会上传仓库。
3. 他人pull拉取：仅下载成品镜像，本地无编译、无需gcc、不执行Dockerfile，直接run启动。
4. 仅对方拿到完整Dockerfile+源码手动build时，才会完整执行所有构建阶段。

## 8.4 流程示例
1. 本地build：生成临时builder(1G) + 成品镜像app:v1(200MB)
2. docker push app:v1 → 仓库仅存储200MB镜像
3. 同事执行docker pull app:v1，下载200MB镜像，直接运行

# 9. 容器基础运维命令
## 9.1 使用镜像生成容器
```bash
docker run --name 容器实例名 镜像标识:版本
```

## 9.2 流式观测容器实时日志
```bash
docker logs -f 容器实例名
```

## 9.3 进入容器内部交互式操作
```bash
docker exec -it 容器实例名 bash
```

# 10. 运维排错：logs 与 exec 使用场景区分
## 10.1 什么时候使用 docker logs -f
核心场景：仅观测程序输出，无需修改容器、查看内部文件，主打流式可观测。
1. 新服务上线，实时监控启动日志，校验数据库连接、初始化流程；
2. 捕获偶发崩溃，后台持续挂日志，等待报错堆栈输出；
3. 容器异常退出后离线排查，不加 `-f` 读取历史日志，定位崩溃原因。

## 10.2 什么时候使用 docker exec -it
核心场景：日志仅返回报错结果，需要进入容器内部排查根源，侵入式审计。
1. 文件路径报错：进入容器ls/cat核对配置、代码文件存放路径；
2. 网络连通异常：容器内部ping/curl测试数据库、网关连通性；
3. 依赖版本异常：容器内执行pip list校验库版本，定位版本冲突。

## 10.3 标准排错组合流程
1. 第一步：`docker logs -f` 监控日志，捕获报错关键词；
2. 第二步：新开终端 `docker exec -it` 进入容器；
3. 第三步：容器内执行ps、ls、网络测试、依赖校验，定位根因并修复。

# 11. 容器生命周期管理
## 11.1 优雅停止容器 docker stop
```bash
docker stop 容器自定义名称
```
逻辑：发送SIGTERM信号，给予程序10秒完成收尾（关闭连接、刷写日志、提交事务）；超时未关闭则强制杀死进程。

## 11.2 删除容器 docker rm
```bash
docker rm 容器自定义名称
```
停止后的容器不会自动清理，持续占用磁盘、容器名称、端口资源；rm彻底清除容器运行层。

## 11.3 删除容器适用场景
1. 版本迭代更新：修改代码/Dockerfile后，删除旧容器，构建新镜像并启动新版；旧容器不删除会出现名称冲突报错。
2. 容器异常故障：内存泄漏、日志打满磁盘、脏数据残留，清理故障实例重建干净容器。
3. 切换配置/环境变量：运行中容器无法修改启动参数，必须删除重建。
4. 本地磁盘清理：批量清理长期闲置停止容器，释放硬盘空间。

# 12. 卷挂载 Volume Mounting 核心作用
## 12.1 数据持久化：穿透容器隔离层
容器默认读写层生命周期与容器绑定，容器删除后内部数据全部丢失。
通过 `-v 宿主机路径:容器内路径` 绑定挂载，容器读写直接落地宿主机硬盘，容器销毁数据不会丢失。

## 12.2 镜像与数据解耦，避免重复构建
禁止在Dockerfile中将大容量原始数据打包进镜像，会导致镜像膨胀、更新数据必须重新build。
工业标准：镜像仅存放计算代码与运行环境，原始数据外置宿主机，启动容器动态挂载；数据更新无需重新构建镜像，实现计算存储分离。

## 12.3 配置热插拔，环境快速切换
遵循12要素应用规范，配置与代码分离。配置文件外置挂载，无需修改镜像即可切换开发/生产环境：
```bash
# 测试环境
docker run -v ./config_dev.yaml:/app/config.yaml xxx
# 生产环境
docker run -v ./config_prod.yaml:/app/config.yaml xxx
```

# 13. docker_modular 工程目录6大文件规范
## 13.1 文件编写先后顺序（依赖前置）
1. `requirements.txt`：定义项目所有第三方依赖，为代码编写提供底层库支撑；
2. `config.yaml`：抽取业务参数、表结构配置，避免代码硬编码；
3. `pipeline.py`：通用ETL清洗引擎，依赖依赖库与配置文件格式；
4. `app.py`：项目总入口，调用pipeline引擎、读取配置执行跑批；
5. `.dockerignore`：定义打包黑名单，编写Dockerfile前划定上下文过滤规则；
6. `Dockerfile`：最终编写，打包上述全部文件构建镜像。

## 13.2 文件依赖拓扑关系
### 代码层依赖
1. `app.py` 强依赖 `pipeline.py`（导入并调用内部ETL类）
2. `pipeline.py` 弱依赖 `config.yaml`（代码结构适配配置输出格式）

### 环境层依赖
`app.py`、`pipeline.py` 强依赖 `requirements.txt`，缺少依赖库会直接导入报错。

### 容器顶层依赖
`Dockerfile` 全量依赖其余5个文件：通过RUN安装requirements依赖，COPY拷贝代码与配置，构建逻辑受.dockerignore过滤规则约束。

## 13.3 各文件工程作用
1. **requirements.txt**
显式声明Python第三方库与固定版本，保证开发环境、容器环境依赖完全一致。

2. **config.yaml**
业务参数中心，存储表名、字段、主键、路径等变量，实现配置代码分离，无状态化程序。

3. **pipeline.py**
通用模块化ETL引擎，拆分extract/transform/load标准数据流程，可复用、不绑定具体业务表。

4. **app.py**
容器唯一启动入口，读取配置、实例化ETL引擎，循环批量执行数据任务。

5. **.dockerignore**
镜像防火墙，过滤缓存、密钥、本地临时文件，缩小镜像体积、规避密钥泄露风险。

6. **Dockerfile**
不可变基础设施编译图纸，支持多阶段构建，封装整套运行环境，输出标准化可分发镜像，支持卷挂载实现数据外置。