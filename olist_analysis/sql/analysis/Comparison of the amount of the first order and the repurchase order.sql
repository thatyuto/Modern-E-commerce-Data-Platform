WITH customer_first_order AS (
    -- 1. 找出每个用户的【首次下单时间】
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_time
    FROM olist_clean.olist_orders_clean o
    JOIN olist_clean.olist_customers_clean c 
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered' -- 只算有效订单
    GROUP BY c.customer_unique_id
),
order_type AS (
    -- 2. 标记每笔订单是【首单】还是【复购】
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        p.payment_value,
        CASE
            WHEN o.order_purchase_timestamp = fo.first_order_time 
            THEN '首次订单'
            ELSE '复购订单'
        END AS order_type
    FROM olist_clean.olist_orders_clean o
    JOIN olist_clean.olist_customers_clean c 
        ON o.customer_id = c.customer_id
    JOIN customer_first_order fo 
        ON c.customer_unique_id = fo.customer_unique_id
    JOIN olist_clean.olist_order_payments_clean p 
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
)
-- 3. 首单 vs 复购 金额对比
SELECT
    order_type,
    COUNT(DISTINCT order_id) AS order_count,      -- 订单数
    SUM(payment_value) AS total_payment,          -- 总金额
    ROUND(AVG(payment_value), 2) AS avg_payment   -- 平均客单价
FROM order_type
GROUP BY order_type
ORDER BY order_type;