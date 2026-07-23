# 面试口述稿 — Modern E-commerce Data Platform

## 30 秒版本（电梯演讲）

> 我基于 Olist 巴西电商数据集，从零搭建了一个现代数据平台。先在 PostgreSQL 做了 60+ 份深度业务分析，验证了物流时效、GMV 趋势、用户复购等核心假设；然后将高价值指标沉淀为 dbt 模型，通过 Airflow 每日调度到 BigQuery，形成了可生产化的指标层。技术栈覆盖 Spark、Delta Lake、Terraform，完整经历了从探索分析到工程化的全流程。

---

## 2 分钟版本（详细展开）

### 开场（15 秒）

> 我最近完成了一个端到端的数据平台项目，基于 Olist 巴西电商数据集。这个项目最大的特点是**Discovery → Production 的演进路径**——不是一开始就搭流水线，而是先在本地做深度业务分析，验证假设，再把有复用价值的指标工程化。

### 阶段一：探索分析（30 秒）

> 第一阶段，我在 PostgreSQL 里做了 60+ 份 ad-hoc 分析。最核心的三个发现：
>
> 1. **物流时效**：我计算了订单从下单到签收各环节的 P25/P50/P75/P90 分位数，发现极快订单（前 25%）的总物流时间比慢的快 3 倍。这个分析后来沉淀为 `mart_logistics_timeliness`。
> 2. **GMV 趋势**：我做了日级 GMV 的环比、周环比，加上 30 天滑动均值和 3σ 异常检测，能自动标记异常波动。这成了 `mart_daily_gmv_trend`。
> 3. **用户行为**：我构建了用户生命周期标签——新客、复购、沉睡、流失，并计算了复购间隔。这是 `mart_user_behavior`。

### 阶段二：工程化（45 秒）

> 第二阶段，我把这三个最有业务价值的分析迁入 dbt，部署到 BigQuery。
>
> 架构是标准的 Kimball 星型模型：staging 层做贴源清洗，marts 层分维度表（dim_customers、dim_products 等）和事实表（fact_orders、fact_order_items），再加上那 3 个业务 mart。
>
> 每个模型都有 dbt test——unique、not_null、relationships、accepted_values，确保数据质量。dbt 不属于湖仓层，它是仓内转换，Spark 把数据 Load 进 BigQuery 后 dbt 才接手。

### 阶段三：编排调度（20 秒）

> 第三阶段，我用 Airflow 做了每日调度。DAG 每天早上 3 点执行：dbt debug → dbt deps → dbt run → dbt test。失败有重试机制，任务依赖也配置好了。
>
> 这样，那 3 个业务 mart 每天自动刷新，BI 可以直接查 `mart_daily_gmv_trend` 看 GMV 趋势，查 `mart_logistics_timeliness` 看物流时效分布。

### 阶段四：扩展与基建（10 秒）

> 此外，我还用 Terraform 声明了 GCS Bucket 和 BigQuery Dataset，用 Spark + Delta Lake 做了 Bronze/Silver/Gold 分层实验，为大规模处理做准备。

### 收尾（10 秒）

> 这个项目让我完整经历了从业务分析到数据工程的转型。我不仅会写复杂 SQL，更重要的是理解了**如何把 ad-hoc 分析转化为可调度、可测试、可复用的生产级指标层**——这是大厂数据团队的标准做法。

---

## 可能被追问的技术细节

### Q1: 为什么选 dbt 而不是纯 Spark SQL？

> dbt 的核心价值是**版本控制、测试、文档、依赖管理**。Spark 适合大规模清洗和 Join，但仓内的维度建模、增量刷新、质量断言，dbt 更成熟。而且 dbt 的 Jinja 模板让 SQL 可复用，team 协作更方便。

### Q2: 物流时效分析中，为什么用 approx_quantiles 而不是精确分位数？

> BigQuery 的 `approx_quantiles` 是近似计算，但对于百万级数据，误差在可接受范围内（通常 <1%），且性能远好于精确分位数。在探索期我用 PostgreSQL 的 `percentile_cont` 做精确计算，工程化时为了性能和成本，切到了近似版本。

### Q3: GMV 异常检测的 3σ 原则，在实际数据中效果如何？

> 我测试过，3σ 能抓到约 0.3% 的极端异常日，2σ 抓到约 5% 的中等异常。实际业务中，我会结合业务日历（如黑五、母亲节）做调整，避免把正常促销日误判为异常。

### Q4: 如果数据量增长 10 倍，你的架构怎么扩展？

> 当前 BigQuery 处理百万级订单没问题。如果增长 10 倍：
> 1. **存储**：Spark 清洗后的数据存 GCS Delta Lake，利用分区和 Z-Order 优化查询。
> 2. **计算**：用 Dataproc 跑 Spark Job，替代本地 Notebook。
> 3. **调度**：Airflow 触发 Dataproc Job → Load to BQ → dbt run，形成完整流水线。
> 4. **成本**：BQ 按需计费，dbt 增量模型只刷新新增分区。

### Q5: 你怎么保证数据质量？

> 三层保障：
> 1. **Staging 层**：过滤逻辑异常（如签收时间早于发货时间）、去重、标准化字段名。
> 2. **dbt tests**：每个模型都有 unique、not_null、relationships 断言，CI/CD 失败即阻断。
> 3. **业务规则**：如 GMV 必须为正、订单状态只能是已知枚举值，用 accepted_values 测试。

---

## 不同岗位的侧重点调整

### Data Engineer 岗位
- 强调 **Airflow + dbt + Terraform** 的工程化能力
- 提及 Spark + Delta Lake 作为扩展能力
- 突出「可调度、可测试、可复用」的生产级思维

### Analytics Engineer 岗位
- 强调 **Kimball 建模 + dbt 测试** 的专业性
- 突出 3 个业务 mart 的**业务价值**（GMV 监控、物流时效优化、用户生命周期管理）
- 提及 olist_analysis 探索过程体现的**业务理解深度**

### DA 转 DE 岗位
- 强调 **从业务分析到工程化** 的完整经历
- 突出「Discovery → Production」的演进故事
- 展示对数据质量、调度、测试的工程化理解

---

## 一句话总结（备用）

> 我做了一个从业务探索到生产落地的完整数据平台，用 dbt + Airflow 把 60+ 份 ad-hoc 分析沉淀为 3 个可调度、可测试的业务 mart，覆盖 GMV 趋势、物流时效、用户行为三大核心场景。