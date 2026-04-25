WITH user_order_count AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_cnt
    FROM olist_clean.olist_orders_clean o
    JOIN olist_clean.olist_customers_clean c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp AS curr_order_time,
    LAG(o.order_purchase_timestamp) OVER(
        PARTITION BY c.customer_unique_id 
        ORDER BY o.order_purchase_timestamp ASC
    ) AS prev_order_time,
    -- 计算间隔天数
    CASE WHEN LAG(order_purchase_timestamp) OVER(PARTITION BY c.customer_unique_id ORDER BY order_purchase_timestamp ASC) IS NULL THEN NULL ELSE o.order_purchase_timestamp - LAG(order_purchase_timestamp) OVER(PARTITION BY c.customer_unique_id ORDER BY order_purchase_timestamp ASC) END AS "Interval Time"
FROM olist_clean.olist_orders_clean o
JOIN olist_clean.olist_customers_clean c 
    ON o.customer_id = c.customer_id
JOIN user_order_count uoc 
    ON c.customer_unique_id = uoc.customer_unique_id
-- 只保留复购用户（≥2单）
WHERE uoc.order_cnt >= 2
ORDER BY 
    c.customer_unique_id, 
    o.order_purchase_timestamp;



