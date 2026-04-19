-- =============================================
-- 数据清洗  -- order_item table 可重复执行
-- 1. 删除损坏数据
-- 2. 标记异常数据
-- 3. 标准化字符串格式
-- 4. 数据校验
-- =============================================

-- 1. 删除无效数据
DELETE FROM olist_raw.order_items
WHERE
    order_id IS NULL
    OR product_id IS NULL
    OR price < 0
    OR freight_value < 0;

-- 2. 增加异常标记
ALTER TABLE olist_raw.order_items
ADD COLUMN IF NOT EXISTS is_abnormal BOOLEAN DEFAULT FALSE;

-- 3. 计算分位数并标记异常
WITH product_quartiles AS (
    SELECT
        product_id,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS q1_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS q3_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY freight_value) AS q1_freight,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight_value) AS q3_freight
    FROM olist_raw.order_items
    GROUP BY product_id
)
UPDATE olist_raw.order_items o
SET is_abnormal = TRUE
FROM product_quartiles pq
WHERE o.product_id = pq.product_id
AND (
    o.price IS NULL
    OR o.freight_value IS NULL
    OR o.price < pq.q1_price - 1.5*(pq.q3_price-pq.q1_price)
    OR o.price > pq.q3_price + 1.5*(pq.q3_price-pq.q1_price)
    OR o.freight_value < pq.q1_freight -1.5*(pq.q3_freight-pq.q1_freight)
    OR o.freight_value > pq.q3_freight +1.5*(pq.q3_freight-pq.q1_freight)
);

-- 4. 标准化字符串（去空格+小写）
UPDATE olist_raw.order_items
SET order_id = LOWER(TRIM(order_id))
WHERE order_id IS NOT NULL;

UPDATE olist_raw.order_items
SET product_id = LOWER(TRIM(product_id))
WHERE product_id IS NOT NULL;

-- 5. 数据校验
SELECT '总数据量' AS stat, COUNT(*) AS value FROM olist_raw.order_items
UNION ALL
SELECT '异常订单数', COUNT(*) FROM olist_raw.order_items WHERE is_abnormal
UNION ALL
SELECT '空订单ID', COUNT(*) FROM olist_raw.order_items WHERE order_id IS NULL
UNION ALL
SELECT '空商品ID', COUNT(*) FROM olist_raw.order_items WHERE product_id IS NULL;