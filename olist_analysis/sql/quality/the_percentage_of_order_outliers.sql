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
SELECT
    -- 总数
    COUNT(DISTINCT CONCAT(order_id, '_', order_item_id)) AS total_items,
    -- 异常数
    SUM(CASE WHEN
        o.price IS NULL OR o.freight_value IS NULL
        OR o.price < pq.q1_price - 1.5 * (pq.q3_price - pq.q1_price)
        OR o.price > pq.q3_price + 1.5 * (pq.q3_price - pq.q1_price)
        OR o.freight_value < pq.q1_freight - 1.5 * (pq.q3_freight - pq.q1_freight)
        OR o.freight_value > pq.q3_freight + 1.5 * (pq.q3_freight - pq.q1_freight)
    THEN 1 ELSE 0 END) AS outlier_items,
    -- 异常率 %
    ROUND(
        SUM(CASE WHEN
            o.price IS NULL OR o.freight_value IS NULL
            OR o.price < pq.q1_price - 1.5 * (pq.q3_price - pq.q1_price)
            OR o.price > pq.q3_price + 1.5 * (pq.q3_price - pq.q1_price)
            OR o.freight_value < pq.q1_freight - 1.5 * (pq.q3_freight - pq.q1_freight)
            OR o.freight_value > pq.q3_freight + 1.5 * (pq.q3_freight - pq.q1_freight)
        THEN 1 ELSE 0 END)
        * 100.0 / COUNT(DISTINCT CONCAT(o.order_id, '_', o.order_item_id)), 2
    ) AS outlier_rate_pct
FROM olist_raw.order_items o
INNER JOIN product_quartiles pq
    ON o.product_id = pq.product_id;