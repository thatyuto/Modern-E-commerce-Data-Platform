-- 插入阶段日志
INSERT INTO olist_clean.etl_log(step_name) VALUES ('创建olist_clean模式');

BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_customers_clean表', '客户信息表：存储去重、格式标准化后的客户数据');

DROP TABLE IF EXISTS olist_clean.olist_customers_clean;
CREATE TABLE olist_clean.olist_customers_clean (
    customer_id VARCHAR(32) PRIMARY KEY,  -- 客户唯一ID（主键，非空）
    customer_unique_id VARCHAR(32) NOT NULL,  -- 客户统一标识（一个客户可能有多个ID）
    customer_zip_code_prefix VARCHAR(10) NOT NULL,  -- 邮编前缀（清洗空格）
    customer_city VARCHAR(100) NOT NULL,  -- 客户城市（首字母大写标准化）
    customer_state VARCHAR(2) NOT NULL,  -- 客户所在州（2位缩写，大写标准化）
    create_time TIMESTAMP DEFAULT NOW(),  -- ETL清洗时间
    etl_version VARCHAR(20) DEFAULT 'V1.0'  -- ETL版本（便于追溯）
);
COMMENT ON TABLE olist_clean.olist_customers_clean IS 'Olist清洗后客户表：去重、州/城市格式标准化、非空约束';

-- 提交事务
UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_customers_clean表';
COMMIT;


BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_customers_clean数据', '清洗规则：去重、空格去除、城市/州格式标准化');

INSERT INTO olist_clean.olist_customers_clean (
    customer_id, customer_unique_id, customer_zip_code_prefix, 
    customer_city, customer_state
)
SELECT 
    DISTINCT customer_id,  -- 去重：删除重复的客户记录
    customer_unique_id,
    TRIM(customer_zip_code_prefix),  -- 清洗：去除邮编前缀的空格
    INITCAP(TRIM(customer_city)),  -- 标准化：城市名首字母大写（如'sao paulo'→'Sao Paulo'）
    UPPER(TRIM(customer_state))  -- 标准化：州缩写大写（如'sp'→'SP'）
FROM olist_raw.olist_customers  -- 从原始表抽取数据
WHERE 
    customer_id IS NOT NULL  -- 过滤：主键不能为空
    AND LENGTH(customer_state) = 2;  -- 过滤：州缩写必须为2位（排除异常数据）

-- 提交事务
UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_customers_clean数据';
COMMIT;