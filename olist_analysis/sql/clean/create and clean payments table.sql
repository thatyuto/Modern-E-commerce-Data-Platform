BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_order_payments_clean表', '订单支付表：联合主键，关联订单表');

DROP TABLE IF EXISTS olist_clean.olist_order_payments_clean;
CREATE TABLE olist_clean.olist_order_payments_clean (
    order_id VARCHAR(32) NOT NULL,  -- 关联订单表
    payment_sequential INT NOT NULL,  -- 支付序号（同一订单多次支付）
    payment_type VARCHAR(20) NOT NULL,  -- 支付方式（信用卡、 boleto等）
    payment_installments INT NOT NULL CHECK (payment_installments >= 1),  -- 分期数（≥1）
    payment_value NUMERIC(10,2) NOT NULL CHECK (payment_value > 0),  -- 支付金额（>0）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0',
    PRIMARY KEY (order_id, payment_sequential),  -- 联合主键
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id) 
        REFERENCES olist_clean.olist_orders_clean(order_id)
);
COMMENT ON TABLE olist_clean.olist_order_payments_clean IS 'Olist清洗后订单支付表：联合主键、支付金额异常过滤、关联订单表';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_order_payments_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_order_payments_clean数据', '清洗规则：支付金额>0、分期数≥1、关联订单');

INSERT INTO olist_clean.olist_order_payments_clean (
    order_id, payment_sequential, payment_type, 
    payment_installments, payment_value
)
SELECT 
    DISTINCT o.order_id,
    o.payment_sequential,
    TRIM(UPPER(o.payment_type)),  -- 标准化：支付方式大写（如'credit card'→'CREDIT CARD'）
    -- 清洗：分期数<1设为1（默认1期）
    CASE WHEN o.payment_installments < 1 THEN 1 ELSE o.payment_installments END,
    o.payment_value
FROM olist_raw.payments o
JOIN olist_clean.olist_orders_clean oc 
    ON o.order_id = oc.order_id
WHERE 
    o.order_id IS NOT NULL
    AND o.payment_value > 0;  -- 过滤：支付金额必须>0

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_order_payments_clean数据';
COMMIT;
