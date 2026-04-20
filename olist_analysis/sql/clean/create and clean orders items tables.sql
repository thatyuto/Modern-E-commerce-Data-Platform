DROP TABLE IF EXISTS olist_clean.olist_order_items_clean;
CREATE TABLE olist_clean.olist_order_items_clean (
    order_id VARCHAR(32) NOT NULL,  -- 关联订单表
    order_item_id INT NOT NULL,  -- 子订单序号（同一订单的多个商品）
    product_id VARCHAR(32) NOT NULL,  -- 关联商品表
    seller_id VARCHAR(32) NOT NULL,  -- 关联卖家表
    shipping_limit_date TIMESTAMP NOT NULL,  -- 发货截止时间（非空）
    price NUMERIC(10,2) NOT NULL CHECK (price > 0),  -- 商品单价（>0，排除异常值）
    freight_value NUMERIC(10,2) NOT NULL CHECK (freight_value >= 0),  -- 运费（≥0）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0',
    -- 联合主键：订单ID+子订单序号（确保唯一）
    PRIMARY KEY (order_id, order_item_id),
    -- 外键约束
    CONSTRAINT fk_items_orders FOREIGN KEY (order_id) 
        REFERENCES olist_clean.olist_orders_clean(order_id),
    CONSTRAINT fk_items_sellers FOREIGN KEY (seller_id) 
        REFERENCES olist_clean.olist_sellers_clean(seller_id)
);
COMMENT ON TABLE olist_clean.olist_order_items_clean IS 'Olist清洗后订单商品表：联合主键、价格异常值过滤、关联订单/卖家表';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_order_items_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_order_items_clean数据', '清洗规则：价格异常值过滤、去重、关联校验');

INSERT INTO olist_clean.olist_order_items_clean (
    order_id, order_item_id, product_id, seller_id, 
    shipping_limit_date, price, freight_value
)
SELECT 
    DISTINCT o.order_id,
    o.order_item_id,
    o.product_id,
    o.seller_id,
    o.shipping_limit_date,
    -- 清洗：价格≤0设为NULL（后续可人工核查）
    CASE WHEN o.price <= 0 THEN NULL ELSE o.price END,
    -- 清洗：运费<0设为0（合理默认值）
    CASE WHEN o.freight_value < 0 THEN 0 ELSE o.freight_value END
FROM olist_raw.order_items o
-- 关联校验：仅保留有效订单
JOIN olist_clean.olist_orders_clean oc 
    ON o.order_id = oc.order_id
-- 关联校验：仅保留有效卖家
JOIN olist_clean.olist_sellers_clean s 
    ON o.seller_id = s.seller_id
WHERE 
    o.order_id IS NOT NULL
    AND o.product_id IS NOT NULL;

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_order_items_clean数据';
COMMIT;