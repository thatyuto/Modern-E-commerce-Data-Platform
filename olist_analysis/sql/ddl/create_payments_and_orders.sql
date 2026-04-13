-- 创建 Schema
CREATE SCHEMA IF NOT EXISTS olist_raw;

-- 创建 orders 表
CREATE TABLE olist_raw.orders (
    order_id VARCHAR(50) PRIMARY KEY NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    
    CONSTRAINT chk_order_status 
        CHECK (order_status IN (
            'approved', 'canceled', 'delivered', 
            'invoiced', 'processing', 'shipped'
        ))
);

-- 创建 order_payments 表
CREATE TABLE olist_raw.order_payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value FLOAT NOT NULL,
    
    PRIMARY KEY (order_id, payment_sequential),
    CONSTRAINT chk_payment_value CHECK (payment_value > 0)
);