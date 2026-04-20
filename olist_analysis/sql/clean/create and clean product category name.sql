

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建product_category_name_translation_clean表', '分类翻译表：关联商品表，存储葡语→英语翻译');

DROP TABLE IF EXISTS olist_clean.product_category_name_translation_clean;
CREATE TABLE olist_clean.product_category_name_translation_clean (
    product_category_name VARCHAR(100) PRIMARY KEY,  -- 葡语分类名（主键）
    product_category_name_english VARCHAR(100) NOT NULL,  -- 英语分类名（非空）
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0'
);
COMMENT ON TABLE olist_clean.product_category_name_translation_clean IS 'Olist清洗后分类翻译表：去重、分类名去空格、非空约束';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建product_category_name_translation_clean表';
COMMIT;


BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入product_category_name_translation_clean数据', '清洗规则：分类名去空格、去重、非空过滤');

INSERT INTO olist_clean.product_category_name_translation_clean (
    product_category_name, product_category_name_english
)
SELECT 
    DISTINCT TRIM(LOWER(o.product_category_name)),  -- 标准化：葡语分类名小写去空格
    TRIM(LOWER(o.product_category_name_english))  -- 标准化：英语分类名小写去空格
FROM olist_raw.product_category_name_translation o
WHERE 
    o.product_category_name IS NOT NULL
    AND o.product_category_name_english IS NOT NULL;  -- 过滤：翻译不能为空

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入product_category_name_translation_clean数据';
COMMIT;