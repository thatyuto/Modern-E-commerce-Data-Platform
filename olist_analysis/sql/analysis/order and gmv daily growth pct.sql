WITH order_payments AS (
    -- 先按订单聚合支付金额，解决“一对多”导致的重复计算
    SELECT 
        order_id, 
        SUM(payment_value) AS total_order_value
    FROM olist_clean.olist_order_payments_clean
    GROUP BY order_id
),
daily_base AS (
    SELECT
        DATE(o.order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id) AS order_quantity,
        SUM(p.total_order_value) AS gmv  -- 这里的求和现在是安全的
    FROM olist_clean.olist_orders_clean o 
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY 1
),
daily_lag AS (
    SELECT
        order_date,
        order_quantity,
        gmv,
        -- 使用 LAG 获取上一行数据
        LAG(order_quantity) OVER(ORDER BY order_date) AS yesterday_quantity,
        LAG(gmv) OVER(ORDER BY order_date) AS yesterday_gmv
    FROM daily_base
)
SELECT
    order_date,
    order_quantity,
    gmv,
    -- 核心修复：通过 * 100.0 自动将运算提升为浮点数，避免截断
    ROUND(
        (order_quantity - yesterday_quantity)::NUMERIC / NULLIF(yesterday_quantity, 0) * 100, 
        2
    ) AS order_daily_growth_pct,
    ROUND(
        (gmv - yesterday_gmv) / NULLIF(yesterday_gmv, 0) * 100, 
        2
    ) AS gmv_daily_growth_pct
FROM daily_lag
ORDER BY order_date;
