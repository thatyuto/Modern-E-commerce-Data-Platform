# Olist Data Warehouse Modeling Blueprint (V1.0)

## 1. Core Architecture: The Bus Matrix

This project implements a **Bus Architecture**. Instead of siloed tables, we build a "Shared Universe" where `fct_orders` and `fct_order_items` leverage **Conformed Dimensions**. This ensures that metrics like "Customer Location" or "Product Weight" are consistent across every report, regardless of the granularity.

---

## 2. Fact Tables (The Transactional Core)

### **fct_order_items (Line-Item Fact)**

* **Purpose**: This is the atomic grain of the warehouse. It is the only place where sales can be sliced by specific products, categories, and sellers.
* **Grain**: One row per item within an order (`order_id` + `order_item_id`).
* **Key Attributes**:
* `order_item_key` (PK): A surrogate key hashed from `order_id` and `order_item_id`.
* `price` & `freight_value`: Individual item revenue and shipping cost for precise margin analysis.
* `shipping_limit_date`: The hard deadline for sellers to ship, used for logistics SLA tracking.



### **fct_orders (Order Header Fact)**

* **Purpose**: Designed for financial and executive reporting. It answers high-level questions: "What was the total revenue today?" or "What is our current conversion rate?"
* **Grain**: One row per unique `order_id`.
* **Key Attributes**:
* `total_payment_value`: Aggregated from payment installments.
* `order_status`: Tracks the lifecycle from "created" to "delivered."
* `purchased_at`: The primary time dimension for YoY/MoM growth analysis.



---

## 3. Dimension Tables (The Descriptive Context)

### **dim_geography (The Foundation)**

* **Role**: The "Anchor" for all location-based data.
* **Logic**: A deduplicated map of `zip_code_prefix` to City and State.
* **Why it matters**: In the raw Olist data, city names are often misspelled or inconsistent. Centralizing geography here ensures **Single Source of Truth (SSOT)**. When a city name is fixed in this table, it correctly updates for both customers and sellers.

### **dim_customers & dim_sellers (Entity Dimensions)**

* **Logic**: Both tables join with `dim_geography`.
* **Analytical Value**: Allows for "Flow Analysis"—e.g., "Are sellers in São Paulo primarily shipping to customers in Rio?"

### **dim_products (Product Catalog)**

* **Logic**: Merges product specs (weight, dimensions) with English category translations.
* **Optimization**: Includes a pre-calculated `weight_class` (e.g., 'Lightweight' for <100g). Analysts can filter by class immediately without writing complex `CASE WHEN` logic in their own queries.

---

## 4. Expected Models (The Output)

You will generate **6 core models** in the `marts` layer:

1. **`dim_geography`**: Independent base dimension (Build this first).
2. **`dim_products`**: Product attributes and category translations.
3. **`dim_customers`**: Buyer profiles, dependent on `dim_geography`.
4. **`dim_sellers`**: Seller profiles, dependent on `dim_geography`.
5. **`fct_orders`**: Financial summary, dependent on `stg_orders` and `stg_payments`.
6. **`fct_order_items`**: Atomic line items, dependent on `stg_order_items`, `fct_orders`, and all dimensions.

---

## 5. Modeling Standards & Best Practices

* **Prefixing**: Strict use of `fct_` for facts and `dim_` for dimensions to clarify intent at a glance.
* **Naming Convention**: All timestamps must end in `_at` (e.g., `purchased_at`) for intuitive searching.
* **DRY (Don't Repeat Yourself)**: Complex business logic (like tax calculations or weight bucketing) must live in these Marts models, never in the BI tool or ad-hoc scripts.
* **Joins**: Dimensions should only join to Facts. Avoid "Snowflaking" (joining dimensions to other dimensions) unless it is a base table like `dim_geography`.

---


这就为你准备一份完整的 **Olist 电商数据仓库建模文档**。这份文档不仅包含了你刚才看到的架构图逻辑，还详细定义了每个模型的职责、核心字段以及它们在星型模型中的角色。

---

# Olist 电商数据仓库建模文档 (V1.0)

## 1. 项目概述

本建模项目旨在将 Olist 原始的范式化数据重构为**星型模型（Star Schema）**。通过“总线架构”设计，实现两个核心事实表（订单汇总与订单明细）共享一套标准维度表，以支持高效的业务分析和 BI 报表。

---

## 2. 逻辑架构图

---

## 3. 模型详细定义

### 3.1 核心事实表 (Fact Tables)

#### **fct_orders (订单汇总事实表)**

* **设计意义**：作为业务成果的最终衡量，回答“公司整体表现如何”。
* **颗粒度**：每行代表一个独立的 `order_id`。
* **核心字段**：
* `order_id` (PK): 订单唯一标识。
* `customer_id` (FK): 关联 `dim_customers`。
* `purchased_at`: 下单时间。
* `total_item_value`: 订单商品总标价。
* `total_freight_value`: 订单总运费。
* `total_payment_value`: 客户实际支付金额（含优惠抵扣后）。
* `order_status`: 订单生命周期状态。



#### **fct_order_items (订单明细事实表)**

* **设计意义**：最细颗粒度的事实，支持商品、类目、卖家等微观维度的下钻分析。
* **颗粒度**：每行代表一个订单中的具体商品项 (`order_id` + `order_item_id`)。
* **核心字段**：
* `order_item_key` (PK): 代理键。
* `order_id` (FK): 关联 `fct_orders`。
* `product_id` (FK): 关联 `dim_products`。
* `seller_id` (FK): 关联 `dim_sellers`。
* `price`: 单件商品成交价。
* `freight_value`: 单件商品分摊运费。



---

### 3.2 共享维度表 (Dimension Tables)

#### **dim_customers (买家维度)**

* **职责**：刻画消费者特征。
* **关键字段**：`customer_id`, `customer_unique_id`, `zip_code_prefix` (FK)。

#### **dim_products (产品维度)**

* **职责**：存储商品属性，支持按重量、尺寸、类目进行筛选。
* **关键字段**：`product_id`, `category_name_english`, `product_weight_g`, `weight_class` (预处理分组)。

#### **dim_sellers (卖家维度)**

* **职责**：管理平台供货端分布。
* **关键字段**：`seller_id`, `zip_code_prefix` (FK)。

#### **dim_geography (地理基座维度)**

* **职责**：**标准化地理信息**，被买家和卖家表共同引用。
* **关键字段**：`zip_code_prefix` (PK), `city`, `state`。

---

## 4. 数据血缘与层级 (Lineage)

1. **Staging 层**：直接映射 Source，进行字段重命名和类型转换（如 `stg_orders`）。
2. **Marts 层 (Core)**：应用星型模型理论。
* `dim_geography` 为独立节点。
* `dim_customers` 与 `dim_sellers` 向上引用 `dim_geography`。
* `fct_order_items` 引用所有维度表及订单主表。



---

## 5. 建模规范与原则 (Best Practices)

1. **单一真理来源 (SSOT)**：所有关于地理位置的纠错必须在 `dim_geography` 中完成。
2. **代理键使用**：在明细事实表中使用 `surrogate_key` 确保记录唯一性。
3. **命名约定**：
* 事实表以 `fct_` 开头。
* 维度表以 `dim_` 开头。
* 时间字段统一以 `_at` 结尾（如 `purchased_at`）。


4. **Dry 原则**：复杂的计算逻辑（如总收入计算）应在 Marts 层预先处理，避免在 BI 报表层写复杂 SQL。

---

## 6. 后续扩展计划

* **dim_reviews**：引入评分维度，分析商品质量与销量的关系。
* **dim_date**：建立标准的日期维度表，支持同比、环比等高级时间序列分析。

