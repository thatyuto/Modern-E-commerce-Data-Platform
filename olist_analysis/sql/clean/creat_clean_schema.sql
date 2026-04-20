-- 1. 创建清洗模式（不存在则创建）
CREATE SCHEMA IF NOT EXISTS olist_clean;

-- 2. 设置默认搜索路径（方便后续操作）
SET search_path TO olist_clean, olist_raw, public;

-- 3. 赋权（根据实际用户调整，这里用默认用户）
GRANT ALL ON SCHEMA olist_clean TO postgres;
COMMENT ON SCHEMA olist_clean IS 'Olist电商数据清洗后标准层，存储去重、空值处理、格式标准化后的数据';
