BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_orders_clean表', '订单主表：存储有效订单数据，关联客户表');

DROP TABLE IF EXISTS olist_clean.olist_orders_clean;
CREATE TABLE olist_clean.olist_orders_clean (
    order_id VARCHAR(32) PRIMARY KEY,  -- 订单唯一ID（主键）
    customer_id VARCHAR(32) NOT NULL,  -- 关联客户表（外键）
    order_status VARCHAR(20) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,  -- 下单时间（非空）
    order_approved_at TIMESTAMP NULL,  -- 订单审核时间（允许空，未审核订单）
    order_delivered_carrier_date TIMESTAMP NULL,  -- 物流揽件时间（允许空）
    order_delivered_customer_date TIMESTAMP NULL,  -- 客户签收时间（允许空）
    order_estimated_delivery_date TIMESTAMP NULL,  -- 预计送达时间（允许空）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0',
    -- 外键约束：确保customer_id在客户表中存在
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) 
        REFERENCES olist_clean.olist_customers_clean(customer_id)
);
COMMENT ON TABLE olist_clean.olist_orders_clean IS 'Olist清洗后订单表：过滤无效状态、时间异常处理、关联客户表校验';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_orders_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_orders_clean数据', '清洗规则：过滤无效状态、时间逻辑校验、关联客户表');

INSERT INTO olist_clean.olist_orders_clean (
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date, order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT 
    DISTINCT o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    -- 清洗：审核时间不能早于下单时间，否则设为NULL
    CASE WHEN o.order_approved_at < o.order_purchase_timestamp THEN NULL ELSE o.order_approved_at END,
    -- 清洗：揽件时间不能早于下单时间，否则设为NULL
    CASE WHEN o.order_delivered_carrier_date < o.order_purchase_timestamp THEN NULL ELSE o.order_delivered_carrier_date END,
    -- 清洗：签收时间不能早于揽件时间，否则设为NULL
    CASE WHEN o.order_delivered_customer_date < o.order_delivered_carrier_date THEN NULL ELSE o.order_delivered_customer_date END,
    o.order_estimated_delivery_date
FROM olist_raw.orders o
-- 关联校验：仅保留客户表中存在的订单（排除无效客户的订单）
JOIN olist_clean.olist_customers_clean c 
    ON o.customer_id = c.customer_id
WHERE 
    o.order_id IS NOT NULL
    -- 过滤无效订单状态：排除取消、不可用的订单
    AND o.order_status NOT IN ('canceled', 'unavailable');

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_orders_clean数据';
COMMIT;