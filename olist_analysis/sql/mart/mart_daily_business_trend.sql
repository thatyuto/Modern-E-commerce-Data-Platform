CREATE SCHEMA IF NOT EXISTS olist_mart;

CREATE OR REPLACE VIEW olist_mart.mart_daily_business_trend AS
WITH order_payments AS (
    -- 解决 Fan-out 问题，先聚合支付金额
    SELECT 
        order_id, 
        SUM(payment_value) AS total_order_value
    FROM olist_clean.olist_order_payments_clean
    GROUP BY order_id
),
daily_base AS (
    -- 基础聚合：每日订单量与 GMV
    SELECT
        DATE(o.order_purchase_timestamp) AS order_date,
        COUNT(DISTINCT o.order_id) AS order_quantity,
        SUM(p.total_order_value) AS gmv
    FROM olist_clean.olist_orders_clean o 
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY 1
),
daily_lag AS (
    -- 计算环比所需的前置数据
    SELECT
        *,
        LAG(order_quantity) OVER(ORDER BY order_date) AS yesterday_qty,
        LAG(gmv) OVER(ORDER BY order_date) AS yesterday_gmv
    FROM daily_base
),
growth_metrics AS (
    -- 计算增长率并处理整数除法
    SELECT
        *,
        ROUND((order_quantity - yesterday_qty)::NUMERIC / NULLIF(yesterday_qty, 0) * 100, 2) AS qty_growth_pct,
        ROUND((gmv - yesterday_gmv)::NUMERIC / NULLIF(yesterday_gmv, 0) * 100, 2) AS gmv_growth_pct
    FROM daily_lag
),
moving_stats AS (
    -- 计算 30 天滑动统计量用于异常判定
    SELECT
        *,
        AVG(qty_growth_pct) OVER(ORDER BY order_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS avg_growth_30d,
        STDDEV(qty_growth_pct) OVER(ORDER BY order_date ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING) AS std_growth_30d
    FROM growth_metrics
)
-- 最终输出表结构
SELECT
    order_date,
    order_quantity,
    gmv,
    qty_growth_pct,
    gmv_growth_pct,
    CASE 
        WHEN ABS(qty_growth_pct) > (avg_growth_30d + 3 * COALESCE(std_growth_30d, 0)) 
             AND ABS(order_quantity - yesterday_qty) > 10 THEN 'CRITICAL'
        WHEN ABS(qty_growth_pct) > (avg_growth_30d + 2 * COALESCE(std_growth_30d, 0)) THEN 'WARNING'
        ELSE 'NORMAL'
    END AS anomaly_status
FROM moving_stats;