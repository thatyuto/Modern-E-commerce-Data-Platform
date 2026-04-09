-- 1. 暴力重置：直接删掉整个房间及其内容（慎用，仅限实验期）
DROP SCHEMA IF EXISTS olist_raw CASCADE;

-- 2. 重新创建房间
CREATE SCHEMA olist_raw;

-- 3. 重新建立带“约束”的表
CREATE TABLE olist_raw.payments (
    order_id TEXT NOT NULL,
    payment_sequential INT,
    payment_type TEXT,
    payment_installments INT,
    payment_value DECIMAL(10, 2) CHECK (payment_value >= 0)
);

CREATE TABLE olist_raw.orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);