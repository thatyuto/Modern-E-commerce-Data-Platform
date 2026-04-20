BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_products_clean表', '商品表：主键为商品ID，存储标准化商品属性');

DROP TABLE IF EXISTS olist_clean.olist_products_clean;
CREATE TABLE olist_clean.olist_products_clean (
    product_id VARCHAR(32) PRIMARY KEY,  -- 商品唯一ID
    product_category_name VARCHAR(100) NULL,  -- 商品分类（允许空，后续可补全）
    product_name_length INT NULL CHECK (product_name_length >= 0),  -- 商品名长度（≥0）
    product_description_length INT NULL CHECK (product_description_length >= 0),  -- 描述长度（≥0）
    product_photos_qty INT NULL CHECK (product_photos_qty >= 0),  -- 图片数量（≥0）
    product_weight_g INT NULL CHECK (product_weight_g >= 0),  -- 重量（克，≥0）
    product_length_cm INT NULL CHECK (product_length_cm >= 0),  -- 长度（厘米，≥0）
    product_height_cm INT NULL CHECK (product_height_cm >= 0),  -- 高度（厘米，≥0）
    product_width_cm INT NULL CHECK (product_width_cm >= 0),  -- 宽度（厘米，≥0）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0'
);
COMMENT ON TABLE olist_clean.olist_products_clean IS 'Olist清洗后商品表：属性非负约束、去重、格式标准化';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_products_clean表';
COMMIT;

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_products_clean数据', '清洗规则：属性非负、分类去空格、去重');

INSERT INTO olist_clean.olist_products_clean (
    product_id, product_category_name, product_name_length, 
    product_description_length, product_photos_qty, product_weight_g,
    product_length_cm, product_height_cm, product_width_cm
)
SELECT 
    DISTINCT o.product_id,
    TRIM(LOWER(o.product_category_name)),  -- 标准化：分类名小写去空格（如'Electronics'→'electronics'）
    -- 清洗：长度<0设为0
    CASE WHEN o.product_name_length < 0 THEN 0 ELSE o.product_name_length END,
    CASE WHEN o.product_description_length < 0 THEN 0 ELSE o.product_description_length END,
    CASE WHEN o.product_photos_qty < 0 THEN 0 ELSE o.product_photos_qty END,
    CASE WHEN o.product_weight_g < 0 THEN 0 ELSE o.product_weight_g END,
    CASE WHEN o.product_length_cm < 0 THEN 0 ELSE o.product_length_cm END,
    CASE WHEN o.product_height_cm < 0 THEN 0 ELSE o.product_height_cm END,
    CASE WHEN o.product_width_cm < 0 THEN 0 ELSE o.product_width_cm END
FROM olist_raw.products o
WHERE 
    o.product_id IS NOT NULL;

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_products_clean数据';
COMMIT;