BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_order_reviews_clean表', '订单评价表：主键为评价ID，关联订单表');

DROP TABLE IF EXISTS olist_clean.olist_order_reviews_clean;
CREATE TABLE olist_clean.olist_order_reviews_clean (
    review_id VARCHAR(32) PRIMARY KEY,  -- 评价唯一ID
    order_id VARCHAR(32) NOT NULL,  -- 关联订单表
    review_score INT NOT NULL CHECK (review_score BETWEEN 1 AND 5),  -- 评分（1-5分）
    review_comment_title VARCHAR(200) NULL,  -- 评价标题（允许空）
    review_comment_message TEXT NULL,  -- 评价内容（允许空）
    review_creation_date TIMESTAMP NOT NULL,  -- 评价创建时间
    review_answer_timestamp TIMESTAMP NULL,  -- 卖家回复时间（允许空）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0',
    CONSTRAINT fk_reviews_orders FOREIGN KEY (order_id) 
        REFERENCES olist_clean.olist_orders_clean(order_id)
);
COMMENT ON TABLE olist_clean.olist_order_reviews_clean IS 'Olist清洗后订单评价表：评分范围约束、关联订单表、去重';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_order_reviews_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_order_reviews_clean数据', '清洗规则：评分1-5分、去重、关联订单');

INSERT INTO olist_clean.olist_order_reviews_clean (
    review_id, order_id, review_score, review_comment_title, 
    review_comment_message, review_creation_date, review_answer_timestamp
)
SELECT 
    DISTINCT o.review_id,
    o.order_id,
    -- 清洗：评分不在1-5分设为3分（默认中等评分）
    CASE WHEN o.review_score NOT BETWEEN 1 AND 5 THEN 3 ELSE o.review_score END,
    TRIM(o.review_comment_title),  -- 清洗：标题去空格
    TRIM(o.review_comment_message),  -- 清洗：内容去空格
    o.review_creation_date,
    -- 清洗：回复时间不能早于创建时间，否则设为NULL
    CASE WHEN o.review_answer_timestamp < o.review_creation_date THEN NULL ELSE o.review_answer_timestamp END
FROM olist_raw.olist_order_reviews o
JOIN olist_clean.olist_orders_clean oc 
    ON o.order_id = oc.order_id
WHERE 
    o.review_id IS NOT NULL;

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_order_reviews_clean数据';
COMMIT;