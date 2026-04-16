# READMED
# Olist 表名 + 核心字段 + 表关系

## 一、9张表完整清单
1. **olist_orders_dataset**
2. **olist_customers_dataset**
3. **olist_order_items_dataset**
4. **olist_products_dataset**
5. **olist_sellers_dataset**
6. **olist_order_payments_dataset**
7. **olist_order_reviews_dataset**
8. **olist_geolocation_dataset**
9. **product_category_name_translation**

---

## 二、每张表 **核心字段 + 作用**
### 1. olist_orders_dataset（订单主表）
- `order_id`：订单ID（**主键**）
- `customer_id`：客户ID
- `order_status`：订单状态
- `order_purchase_timestamp`：下单时间
- 所有订单时间节点

### 2. olist_customers_dataset（客户表）
- `customer_id`：客户ID
- `customer_unique_id`：用户唯一ID
- `customer_city`：客户城市
- `customer_state`：客户州

### 3. olist_order_items_dataset（订单商品表）
- `order_id`
- `product_id`
- `seller_id`
- `price`：商品价格
- `freight_value`：运费

### 4. olist_products_dataset（商品表）
- `product_id`（主键）
- `product_category_name`：商品类目
- 商品尺寸、重量、图片数

### 5. olist_sellers_dataset（卖家表）
- `seller_id`（主键）
- `seller_city`
- `seller_state`

### 6. olist_order_payments_dataset（支付表）
- `order_id`
- `payment_type`：支付方式
- `payment_installments`：分期数
- `payment_value`：支付金额

### 7. olist_order_reviews_dataset（评价表）
- `order_id`
- `review_score`：评分1-5
- `review_comment_message`：评价内容

### 8. olist_geolocation_dataset（地理信息表）
- `geolocation_zip_code_prefix`：邮编
- 经纬度、城市、州

### 9. product_category_name_translation（类目翻译表）
- `product_category_name`：葡萄牙语类目
- `product_category_name_english`：英语类目

---

## 三、表之间的关联关系
- **order_id** 连接：
  orders ↔ order_items ↔ order_payments ↔ order_reviews
- **customer_id** 连接：
  orders ↔ customers
- **product_id** 连接：
  order_items ↔ products
- **seller_id** 连接：
  order_items ↔ sellers



