

# Olist Data Warehouse Bus Architecture & Engineering Delivery Whitepaper 

## 1. Core Architecture: Bus Matrix & Conformed Dimensions

This enterprise data platform implements a rigorous **Bus Architecture** following classical **Kimball Dimensional Modeling**. The system abandons legacy, siloed reporting pipelines in favor of standardized **Conformed Dimensions**.

* **Architecture Style**: Star Schema centered around transaction metrics with radial dimension mappings.
* **Core Value**: Whether slicing data from the aggregate grain of `fct_orders` or the atomic line-item grain of `fct_order_items`, business contexts like "Customer Geography" or "Product Weight Class" remain perfectly consistent across all BI layers, eliminating analytical data silos.

---

## 2. Data Materialization Layers & Architecture Topology

The infrastructure is isolated into two vertically decoupled layers orchestrated via dbt on top of Google BigQuery:

* **Staging Layer**:
* **Materialization**: `+materialized: view` (Virtual Analytical Views)
* **Engineering Rationale**: Eliminates secondary data storage duplication, substantially lowering cloud operational costs. Downstream tables fetch data dynamically through these views, capturing upstream variations inside the BigQuery kernel with zero latency.


* **Data Marts Layer**:
* **Materialization**: `+materialized: table` & `incremental` (Physical & Delta Storage)
* **Engineering Rationale**: Materializes final dimension and fact assets into highly optimized physical tables. This completely eliminates runtime processing bottlenecks for BI visualization layers (e.g., Tableau, Looker), enabling sub-second multi-dimensional analytical response times.



---

## 3. Dimension Model Design & Advanced Feature Engineering

### 3.1 `dim_geography` (The Geolocation Foundation) —— Build First!

* **Role**: Serves as the universal "Anchor" for all location-based analytics, establishing a rigorous **Single Source of Truth (SSOT)**.
* **Problem Solved**: Addresses the severe typo and misspelling mutations present within raw Brazilian ZIP codes. It houses a deduplicated map of `zip_code_prefix` to standardized City and State attributes. Any upstream corrections applied here instantly propagate to both buyer and seller profiles.

### 3.2 `dim_products` (Statistical Quantile Product Catalog)

* **Feature Engineering**: Implements automated cross-lingual Portuguese-to-English translation mapping and computes 3D spatial features via `product_volume_cm3`.
* **Quantile Segmentation**: Rejects arbitrary expert-rule bucketing. Instead, it extracts the **33rd percentile (400g)** and **66th percentile (1250g)** of the catalog's real weight distribution to construct an automated categorical matrix via a deterministic `CASE WHEN` block:
* `light weight`: Weight $< 400\text{g}$ (Low-freight, price-sensitive tier).
* `middle weight`: Weight between $400\text{g} \sim 1250\text{g}$ (Mainstream inventory block).
* `heavy weight`: Weight $> 1250\text{g}$ (Heavy-load storage & premium handling category).



### 3.3 `dim_customers` (RFM Customer Segmentation Asset)

* **Design Strategy**: Adheres to the **SCD Type 1 (Slowly Changing Dimension Type 1)** convention, implementing a production-grade **RFM Customer Value Segmentation Model** natively in SQL.
* **Core Metrics**: Formulates Recency (days elapsed via `date_diff`), Frequency (unique order counts via `count(distinct order_id)`), and Monetary (revenue aggregation via `sum(total_payment_value)`).
* **Quantile Scoring**: Leverages the window function **`ntile(5)` to split the user base into 5 dynamic quantiles** (scores 1-5). By checking metrics against the global arithmetic mean (`avg(score) over()`), the model segregates clients into 5 strategic operational segments: *Core Champions, Core Loyalists, High-Potential VIPs, At-Risk Customers, and Standard Customers*.

### 3.4 `dim_sellers` (Merchant Domain Profile)

* **Role**: Structures supply-side seller profiles, joining directly to `dim_geography` to power advanced downstream "Trade Flow Analysis" against buyer distributions.

---

## 4. Fact Model Engineering & Optimization Patterns

### 4.1 `fct_orders` (Order Header Financial Fact)

* **Granularity**: One row per unique `order_id`. Configured for financial summaries and C-suite KPI metrics.
* **Fan-out Prevention Mechanism**: To mitigate row duplication traps caused by multi-table relations, the query aggregates transactional metrics within CTEs `order_payments` and `order_items_summary` via `SUM` and `GROUP BY` operations before conducting joins. It enforces primary key uniqueness using `row_number()` paired with a strict `QUALIFY` clause.
* **Lifecycle State Tracking**: Employs `coalesce(delivered_to_customer_at, purchased_at)` to derive a dynamic high-water mark `updated_at`, driving the downstream incremental syncing execution layer.

### 4.2 `fct_order_items` (Atomic Line-Item Fact)

* **Granularity**: The absolute atomic grain of the warehouse. One row per item within an order (`order_id` + `order_item_id`).
* **Keys & Measures**: Implements a unique surrogate primary key (`order_item_key`) hashed from business keys. Tracks isolated row measures including product item revenue (`price`) and allocated shipping charges (`freight_value`).
* **Analytical Value**: Generates `freight_ratio` (`freight / total_value`) to flag anomalous shipping fees and measure merchant SLA fulfillment overheads.

---

## 5. Performance Engineering: 7-Day Sliding Window Incremental Refresh

To scale against heavy e-commerce batch volume spikes, the architecture implements a **Sliding Window Incremental Refresh Strategy** across intensive models:

```sql
where purchased_at >= (select timestamp_sub(max(updated_at), interval 7 day) from {{ this }})

```

* **Compute Scan Suppression**: Isolates the data sync layer via optimized subqueries, preventing blind, costly full table scans across historical BigQuery data blocks.
* **7-Day Buffer Resilience**: Order lifecycle attributes fluctuate drastically over a typical 1-week fulfillment period. The 7-day lookback window ensures these changes are securely captured and updated via target `MERGE` actions. Furthermore, if upstream data orchestration systems (e.g., Apache Airflow) go down for up to 3 consecutive days, this sliding buffer automatically recovers and backfills missing delta rows upon pipeline restoration.

---

## 6. Automated Data Quality Guardrails & Test Matrix

Data integrity is rigorously enforced at the pipeline boundary through automated continuous testing layers defined within `schema.yml`:

* **Entity Integrity**: Binds atomic `unique` and `not_null` assertions to model primary keys to eliminate row corruption.
* **Referential Integrity**: Configures cross-table foreign key validation via `relationships` tests inside `fct_order_items`, monitoring `product_id` and `seller_id` relations. Any orphaned records missing a parent entity inside `dim_products` trigger a pipeline `warn` flag immediately.
* **Domain Range Constraints**: Enforces categorical boundary verification via `accepted_values` rules against variables like `weight_class` (strictly checking for `'light weight'`, `'middle weight'`, and `'heavy weight'`) and `customer_segment`, blocking bad data mutations from leaking into user-facing executive dashboards.

---

电子商务数据仓库总线架构与工程交付白皮书 (V1.0)

## 1. 核心数仓架构：总线矩阵与一致性维度 (Bus Architecture)

本数仓全面落地了经典 **Kimball 维度建模理论**，构建了高内聚、低耦合的**总线架构（Bus Architecture）**。项目彻底告别了传统烟囱式的孤立报表开发，设计了标准的**一致性维度（Conformed Dimensions）**。

* **设计架构图**：以事实表为中心，维度表向外辐射的星型模型（Star Schema）。
* **核心价值**：无论是分析 `fct_orders`（订单汇总）还是 `fct_order_items`（明细项），只要涉及到“客户地理位置”或“商品重量分类”，下游 BI 看到的指标口径完全一致，消除了数据孤岛。

---

## 2. 数据仓库分层拓扑与物化策略 (Data Materialization Layers)

整个平台采用垂直解耦的两层经典架构，在 Google BigQuery 之上通过 dbt 进行高效物化：

* **贴源清洗层 (Staging Layer)**：
* **物化配置**：`+materialized: view`（虚拟视图）
* **工程考量**：不进行物理落地。消除底层数据的二次存储拷贝，降低 BigQuery 存储成本；当下游 Marts 运行时通过视图直通原始层，保证清洗无延迟。


* **业务集市层 (Data Marts Layer)**：
* **物化配置**：`+materialized: table`（物理落地表）与 `incremental`（增量合并表）
* **工程考量**：对核心维度与事实表进行物理落盘，彻底消除下游 BI 工具（Tableau/Looker）在频繁切换维度时的运行时计算瓶颈，多维查询体验实现断层式暴涨。



---

## 3. 核心维度表设计与特征工程 (Dimension Models)

### 3.1 `dim_geography`（地理信息基座）—— Build First!

* **职责**：作为全仓地理位置的“黄金锚点”，实现单一真理来源（SSOT）。
* **业务痛点解决**：巴西原始数据中城市名存在大量错漏拼写。在此模型中实现全面去重与标准化（`zip_code_prefix` $\rightarrow$ City/State）。当此表修正后，买家和卖家的地理上下文将同步自动对齐。

### 3.2 `dim_products`（动态统计学商品维度）

* **特征工程实现**：完成了跨语种语义对齐与三维空间衍生特征计算。
* **重量等级判定**：拒绝主观硬编码，采用 Olist 商品库的 **33% 分位数（400g）** 与 **66% 分位数（1250g）** 作为动态统计学切片边界，通过 `CASE WHEN` 预处理：
* `light weight`：重量 $< 400\text{g}$（低物流成本敏感区间）
* `middle weight`：重量 $400\text{g} \sim 1250\text{g}$（主流标准件区间）
* `heavy weight`：重量 $> 1250\text{g}$（重载仓储监控区间）



### 3.3 `dim_customers`（硬核客户价值模型）

* **模型落地**：基于 **SCD Type1 (渐变维度第一型)**，利用纯物理 SQL 完整实现了 **RFM 客户价值分群模型**。
* **核心口径**：R（最近消费间隔 `date_diff`）、F（独立订单去重总数 `count(distinct order_id)`）、M（实付总金额 `sum(total_payment_value)`）。
* **动态切片**：利用窗口函数 **`ntile(5)` 对全体客群进行动态等分五分位切片**，计算出 1-5 分的评分矩阵，并利用全局平均分（`avg(score) over()`）进行二元判定，将客群精准划分为：*重要价值客户、重要保持客户、重要发展客户、重要挽留客户、一般客户*。

### 3.4 `dim_sellers`（卖家特征维度）

* **职责**：管理供货端分布，向上关联 `dim_geography`，与买家维度协同支持跨州/跨城市的“贸易流向分析（Flow Analysis）”。

---

## 4. 核心事实表设计与大数据工程优化 (Fact Models)

### 4.1 `fct_orders`（订单汇总事实表）

* **业务粒度**：一行代表一个独立的 `order_id`。面向财务与高管看板。
* **多对多扇出防御机制 (Fan-out Prevention)**：在主表关联前，首先在 CTE `order_payments` 和 `order_items_summary` 中以 `order_id` 为粒度执行 `SUM` 和 `GROUP BY` 预聚合，将 One-to-Many 陷阱收拢为 One-to-One 关系。利用窗口函数 `row_number()` 配合 `QUALIFY` 强制执行唯一性校验。
* **生命周期时间戳构造**：通过 `coalesce(delivered_to_customer_at, purchased_at)` 动态构造 `updated_at`，作为增量合并的高效索引键。

### 4.2 `fct_order_items`（订单明细项事实表）

* **业务粒度**：数仓最细原子颗粒度，一行代表一个订单内的具体商品项（`order_id` + `order_item_id`）。
* **工程设计**：使用 `surrogate_key`（基于订单ID与项ID哈希）作为主键。记录单件商品成交价 `price` 与分摊运费 `freight_value`。
* **业务增值**：衍生出 `freight_ratio`（运费占总价值比率），专门用于监控高运费异常商品与卖家物流 SLA 履约率。

---

## 5. 极致性能演进：7天滑动窗口增量合并 (Incremental Logic)

为应对海量电商交易爆发，项目抛弃了低效的“全量覆盖”，在事实表与核心维表中落地了基于**滑动时间窗口的增量运行逻辑**：

```sql
where purchased_at >= (select timestamp_sub(max(updated_at), interval 7 day) from {{ this }})

```

* **防扫描设计**：通过子查询动态定位到当前目标表中已存在的最大更新时间，避免 blind 扫描 BigQuery 历史全表。
* **7天容错设计**：电商场景中，过去 7 天内下的订单其物流状态依然在剧烈波动。7天缓冲区确保了这些状态变更能以 `MERGE` 的形式完美覆盖历史记录；同时，若上游系统（Airflow）发生 2-3 天的意外断流，系统恢复后滑动窗口能自动无缝吞噬并补齐断层数据。

---

## 6. 自动化数据质量防御体系 (Data Quality Guardrails)

在 `schema.yml` 中，项目为关键模型构建了全自动的断言与质量测试矩阵：

* **实体完整性**：主键强制绑定 `unique` 和 `not_null` 双重原子断言。
* **参照完整性**：在 `fct_order_items` 中配置了跨表外键关联测试（`relationships`）。一旦发现游离于维度表 `dim_products` 之外的孤儿事实数据，系统立即抛出 `warn` 警告，保障数仓拓扑的逻辑闭环。
* **业务域值边界**：对商品重量等级 `weight_class` 和客户标签 `customer_segment` 绑定了严格的 `accepted_values` 枚举值测试，从源头彻底拒绝脏数据向下游看板扩散。

---
