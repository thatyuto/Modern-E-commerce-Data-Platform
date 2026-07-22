# What is Terraform? And What is the point of its existence?
“在传统数据工程或云架构搭建中，手动在 GCP 控制台点击鼠标创建 BigQuery 数据集、GCS Bucket 或配置权限被设计出来的最大隐患在于‘难以复现’与‘配置漂移（Configuration Drift）’。Terraform 及其声明式语言 HCL（HashiCorp Configuration Language）被设计出来的核心意义，在于将云端的网络、存储、数据库等硬件资源‘代码化’与‘版本控制化’。通过 main.tf 定义资源形态，Terraform 会自动计算状态差异，实现一键创建、销毁与跨环境（如开发/生产环境）的百分百无缝复制。”

---

## 场景：在GCP上为Olist数据平台搭建基础设施

假设现在你的 Olist 数据平台需要以下 3 个核心 GCP 资源：

1. **1 个 GCS Bucket**：用于 Spark 存放清洗后的临时 Parquet 文件。
2. **2 个 BigQuery Dataset**：`olist_staging`（原始暂存）和 `olist_marts`（dbt 产出的 `dim/fact` 维度表）。
3. **1 个 IAM Service Account**：专门给 Airflow 赋予读写 BigQuery 的权限。

---

### 1. 手动在 GCP 控制台点击鼠标（传统做法）

你打开网页，凭记忆点鼠标：

* 点进 GCS 控制台 $\rightarrow$ 点击“创建桶” $\rightarrow$ 手动输入名称 $\rightarrow$ 勾选区域为 `us-central1` $\rightarrow$ 勾选“阻止公开访问”。
* 点进 BigQuery 控制台 $\rightarrow$ 创建 `olist_staging`，设置数据过期时间为 30 天；创建 `olist_marts`，设置不过期。
* 点进 IAM 控制台 $\rightarrow$ 创建 Service Account $\rightarrow$ 手动勾选 `BigQuery Data Editor` 和 `Storage Object Admin` 角色。

#### 💥 工业生产中的真实痛点：

#### ① 难以复现（无法快速搭建 Dev / Staging / Prod 多套环境）

三个月后，公司业务扩大，要求你搭建一套一模一样的 **`Prod` 生产环境**（之前是 `Dev` 开发环境）。

* **痛点**：你根本记不清三个月前在控制台勾选了哪些属性。`olist_marts` 的加密密钥是什么？GCS 的存储类别选的是 Standard 还是 Nearline？ Service Account 到底赋予了哪 4 个细粒度的权限？
* **后果**：你必须重新花费几个小时在网页里对照、点击，而且极易漏掉某个关键权限设置（比如漏勾了 `BigQuery Job User`），导致生产环境 Airflow 第一次跑批直接报 `403 Access Denied` 崩溃。

#### ② 配置漂移（Configuration Drift / 生产事故安全隐患）

某天夜里，一位运维同事在排查问题时，临时在 GCP 控制台将 `olist_marts` 数据集的权限改为了 `Public`（允许任何人访问），或者把 GCS Bucket 的“阻止公开访问”勾选去掉了，排查完后**忘记改回来**。

* **痛点**：由于这是在网页控制台手动改的，没有任何代码改动记录（Git 记录为 0）。
* **后果**：公司的 Olist 核心商业数据悄悄暴露在公网上，引发重大数据泄露事故，而团队里没有任何人知道这个配置是在什么时间、被谁在网页里改动的。

---

## 2. 用 Terraform (HCL) 的工业级做法

你不再手点网页，而是写了一份 **`main.tf` 基础设施代码** 并提交到 Git：

```hcl
# 1. 声明 GCS 暂存桶
resource "google_storage_bucket" "spark_staging" {
  name                     = "olist-spark-staging-${var.environment}"
  location                 = "US"
  public_access_prevention = "enforced" # 强行禁止公开访问
}

# 2. 声明 dbt Marts 数据集
resource "google_bigquery_dataset" "olist_marts" {
  dataset_id                  = "olist_marts_${var.environment}"
  location                    = "US"
  delete_contents_on_destroy  = false
}

# 3. 声明 Airflow 的专属服务账号
resource "google_service_account" "airflow_sa" {
  account_id   = "airflow-runner-${var.environment}"
  display_name = "Service Account for Airflow Pipeline"
}

```

#### 🛡️ Terraform 如何解决工业痛点：

#### ① 一键跨环境秒级复现

当你需要一套新的 `Prod` 环境时，无需手点控制台。只需要在命令行传入变量 `environment = "prod"`，然后运行：

```bash
terraform apply -var="environment=prod"

```

**结果**：Terraform 会在 10 秒钟内，在 GCP 上精准创建出与 `Dev` 环境物理配置 **100% 完全对齐**的生产级 Bucket、BigQuery Dataset 和 IAM 权限体系。

#### ② 自动纠正“配置漂移”

还是上面的场景：某人悄悄在网页控制台把 GCS 的“阻止公开访问”关掉了。
第二天，当你执行 `terraform plan` 时，Terraform 的引擎会自动对比代码（`main.tf`）与 GCP 云端真实状态（State），并直接弹出一行大红色的告警：

```diff
# google_storage_bucket.spark_staging will be updated in-place
~ public_access_prevention = "inherited" -> "enforced"

```

* **自动修复**：你只需要执行 `terraform apply`，Terraform 会自动调用 GCP API，**强行把被改动的配置推回 `enforced**`，将隐患消灭在萌芽状态。

---

### 💡 工业总结

在真实的 Olist 数据平台项目中：

* **HCL 代码（`main.tf`）** 是基础设施的**唯一真理来源（Single Source of Truth）**。
* 任何对 GCP 资源（GCS、BigQuery、IAM）的修改，都必须通过**修改 `.tf` 代码 $\rightarrow$ Git Commit $\rightarrow$ `terraform apply**` 来完成，彻底杜绝“在网页控制台偷偷点鼠标”带来的不稳定隐患。