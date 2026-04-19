-- 创建异常值表
DROP TABLE IF EXISTS olist_raw.order_item_outliers;
CREATE TABLE olist_raw.order_item_outliers (
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    price NUMERIC,
    freight_value NUMERIC,
    reason TEXT
);

-- 插入异常数据 + 自动标记异常原因
INSERT INTO olist_raw.order_item_outliers
WITH product_quartiles AS (
    SELECT
        product_id,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) AS q1_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) AS q3_price,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY freight_value) AS q1_freight,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight_value) AS q3_freight
    FROM olist_raw.order_items
    GROUP BY product_id
),
product_iqr AS (
    SELECT
        product_id,
        q1_price,
        q3_price,
        q1_freight,
        q3_freight,
        (q3_price - q1_price) AS iqr_p,
        (q3_freight - q1_freight) AS iqr_f
    FROM product_quartiles
)
SELECT
    o.order_id,
    o.order_item_id,
    o.product_id,
    o.price,
    o.freight_value,
    -- 异常原因（自动判断）
    CONCAT_WS(' | ',
        CASE WHEN o.price IS NULL OR o.freight_value IS NULL THEN '存在空值' ELSE NULL END,
        CASE WHEN o.price < pq.q1_price - 1.5 * pq.iqr_p THEN '价格过低' ELSE NULL END,
        CASE WHEN o.price > pq.q3_price + 1.5 * pq.iqr_p THEN '价格过高' ELSE NULL END,
        CASE WHEN o.freight_value < pq.q1_freight - 1.5 * pq.iqr_f THEN '运费过低' ELSE NULL END,
        CASE WHEN o.freight_value > pq.q3_freight + 1.5 * pq.iqr_f THEN '运费过高' ELSE NULL END
    ) AS reason
FROM olist_raw.order_items o
INNER JOIN product_iqr pq
    ON o.product_id = pq.product_id
WHERE
    o.price IS NULL
    OR o.freight_value IS NULL
    OR o.price < pq.q1_price - 1.5 * pq.iqr_p
    OR o.price > pq.q3_price + 1.5 * pq.iqr_p
    OR o.freight_value < pq.q1_freight - 1.5 * pq.iqr_f
    OR o.freight_value > pq.q3_freight + 1.5 * pq.iqr_f;
