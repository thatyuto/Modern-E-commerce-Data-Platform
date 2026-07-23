# 自动创建Spark ETL专属的GCS暂存桶
resource "google_storage_bucket" "spark_staging_bucket" {
    # GCS桶全局唯一名称
    name = "olist-spark-staging-yuto-2026"
    # 存储地域 US，需要和BigQuery数据集地域保持一致
    location = "US"
    # 执行terraform destroy时，桶内存在文件也允许删除，开发环境适用
    force_destroy = true 
    # 强制禁止公共访问，安全策略，杜绝匿名公网读取
    public_access_prevention = "enforced" # 强制禁止公共访问

    # 启用统一桶级IAM权限，禁用传统ACL，适配Dataproc Spark权限管理
    uniform_bucket_level_access = true
}

# 自动创建用于存放dbt产出(dim/fact)的BigQuery数据集
resource "google_bigquery_dataset" "olist_dbt_marts" {
    # BigQuery数据集ID（项目内唯一）
    dataset_id = "dbt_ywong_terraform"
    # GCP控制台展示的数据集友好名称
    friendly_name = "Olist Analytics Marts"
    # 数据集地域，与上方GCS桶地域对齐，规避跨区域流量费用
    location = "US"
    # terraform销毁资源时，不删除数据集内部数据表，防止误删业务数据
    delete_contents_on_destroy = false #保护生产数据，防止误删
}

# 输出创建成功的资源信息
# Spark临时GCS桶完整访问地址
output "spark_bucket_url" {
    value = google_storage_bucket.spark_staging_bucket.url
    description = "GCS Bucket URL for Spark Staging"
}

# 输出dbt mart层BigQuery数据集ID
output "bq_dataset_id" {
    value = google_bigquery_dataset.olist_dbt_marts.dataset_id
    description = "BigQuery Dataset ID"
}