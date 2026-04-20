BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('创建olist_geolocation_clean表', '地理信息表：联合主键，存储经纬度信息');

DROP TABLE IF EXISTS olist_clean.olist_geolocation_clean;
CREATE TABLE olist_clean.olist_geolocation_clean (
    geolocation_zip_code_prefix INT NOT NULL,  -- 邮编前缀
    geolocation_lat NUMERIC(16,6) NOT NULL CHECK (geolocation_lat BETWEEN -90 AND 90),  -- 纬度（-90~90）
    geolocation_lng NUMERIC(16,6) NOT NULL CHECK (geolocation_lng BETWEEN -180 AND 180),  -- 经度（-180~180）
    geolocation_city VARCHAR(100) NOT NULL,  -- 城市
    geolocation_state VARCHAR(2) NOT NULL,  -- 州
    create_time TIMESTAMP DEFAULT NOW(),
    etl_version VARCHAR(20) DEFAULT 'V1.0',
    
    -- 联合主键：邮编+纬度+经度（确保唯一）
    PRIMARY KEY (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng)
);
COMMENT ON TABLE olist_clean.olist_geolocation_clean IS 'Olist清洗后地理表：经纬度范围约束、去重、格式标准化';

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='创建olist_geolocation_clean表';
COMMIT;


BEGIN;
INSERT INTO olist_clean.etl_log(step_name, remark) 
VALUES ('插入olist_geolocation_clean数据', '清洗规则：经纬度范围校验、去重、城市标准化');

INSERT INTO olist_clean.olist_geolocation_clean (
    geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
    geolocation_city, geolocation_state
)
SELECT 
    DISTINCT o.geolocation_zip_code_prefix,
    -- 清洗：纬度超出范围设为NULL
    CASE WHEN o.geolocation_lat NOT BETWEEN -90 AND 90 THEN NULL ELSE o.geolocation_lat END,
    -- 清洗：经度超出范围设为NULL
    CASE WHEN o.geolocation_lng NOT BETWEEN -180 AND 180 THEN NULL ELSE o.geolocation_lng END,
    INITCAP(TRIM(o.geolocation_city)),  -- 标准化：城市首字母大写
    UPPER(TRIM(o.geolocation_state))  -- 标准化：州缩写大写
FROM olist_raw.geolocation o
WHERE 
    o.geolocation_zip_code_prefix IS NOT NULL
-- 跳过已存在的主键组合，避免冲突
ON CONFLICT (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng) DO NOTHING;

UPDATE olist_clean.etl_log SET status='完成', end_time=NOW() 
WHERE step_name='插入olist_geolocation_clean数据';
COMMIT;