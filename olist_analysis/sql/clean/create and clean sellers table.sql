BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_sellers_clean表', '卖家表：主键为卖家ID，关联订单商品表');

DROP TABLE IF EXISTS olist_clean.olist_sellers_clean;
CREATE TABLE olist_clean.olist_sellers_clean (
    seller_id VARCHAR(32) PRIMARY KEY,  -- 卖家唯一ID
    seller_zip_code_prefix VARCHAR(10) NOT NULL,  -- 卖家邮编前缀（非空）
    seller_city VARCHAR(100) NOT NULL,  -- 卖家城市（标准化）
    seller_state VARCHAR(2) NOT NULL,  -- 卖家所在州（2位缩写）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0'
);
COMMENT ON TABLE olist_clean.olist_sellers_clean IS 'Olist清洗后卖家表：去重、城市/州格式标准化、非空约束';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_sellers_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_sellers_clean数据', '清洗规则：去重、邮编/城市去空格、州大写');

INSERT INTO olist_clean.olist_sellers_clean (
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
SELECT 
    DISTINCT o.seller_id,
    o.seller_zip_code_prefix,  
    INITCAP(TRIM(o.seller_city)),  -- 标准化：城市首字母大写
    UPPER(TRIM(o.seller_state))  -- 标准化：州缩写大写
FROM olist_raw.sellers o
WHERE 
    o.seller_id IS NOT NULL
    AND LENGTH(o.seller_state) = 2;  -- 过滤：州缩写必须为2位

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_sellers_clean数据';
COMMIT;
