
BEGIN;
SELECT 
  -- 一、下单→支付时长分位数（直接用时间间隔计算，结果为“小时:分钟:秒”格式）
  PERCENTILE_CONT(0.25) WITHIN GROUP (
    ORDER BY order_approved_at - order_purchase_timestamp  -- 原生时间差，无需EPOCH
  ) AS pay_p25,
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY order_approved_at - order_purchase_timestamp
  ) AS pay_p50,
  PERCENTILE_CONT(0.75) WITHIN GROUP (
    ORDER BY order_approved_at - order_purchase_timestamp
  ) AS pay_p75,
  PERCENTILE_CONT(0.9) WITHIN GROUP (
    ORDER BY order_approved_at - order_purchase_timestamp
  ) AS pay_p90,
  
  -- 二、支付→发货时长分位数（同样用原生时间差）
  PERCENTILE_CONT(0.25) WITHIN GROUP (
    ORDER BY order_delivered_carrier_date - order_approved_at
  ) AS ship_p25,
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY order_delivered_carrier_date - order_approved_at
  ) AS ship_p50,
  PERCENTILE_CONT(0.75) WITHIN GROUP (
    ORDER BY order_delivered_carrier_date - order_approved_at
  ) AS ship_p75,
  PERCENTILE_CONT(0.9) WITHIN GROUP (
    ORDER BY order_delivered_carrier_date - order_approved_at
  ) AS ship_p90,
  
  -- 三、发货→签收时长分位数（保持一致逻辑）
  PERCENTILE_CONT(0.25) WITHIN GROUP (
    ORDER BY order_delivered_customer_date - order_delivered_carrier_date
  ) AS sign_p25,
  PERCENTILE_CONT(0.5) WITHIN GROUP (
    ORDER BY order_delivered_customer_date - order_delivered_carrier_date
  ) AS sign_p50,
  PERCENTILE_CONT(0.75) WITHIN GROUP (
    ORDER BY order_delivered_customer_date - order_delivered_carrier_date
  ) AS sign_p75,
  PERCENTILE_CONT(0.9) WITHIN GROUP (
    ORDER BY order_delivered_customer_date - order_delivered_carrier_date
  ) AS sign_p90

FROM olist_clean.olist_orders_clean
WHERE 
  -- 过滤无效数据：确保时间非空且逻辑正确（避免异常值干扰分位数）
  order_purchase_timestamp IS NOT NULL 
  AND order_approved_at IS NOT NULL 
  AND order_delivered_carrier_date IS NOT NULL 
  AND order_delivered_customer_date IS NOT NULL 
  AND order_approved_at > order_purchase_timestamp  -- 支付时间晚于下单
  AND order_delivered_carrier_date > order_approved_at  -- 发货时间晚于支付
  AND order_delivered_customer_date > order_delivered_carrier_date;  -- 签收时间晚于发货
  
  
  -- 生成物流时效宽表（直接运行）
DROP TABLE IF EXISTS olist_clean.olist_logistics_timely_wide;
CREATE TABLE olist_clean.olist_logistics_timely_wide AS
WITH order_time AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_status,
        o.order_purchase_timestamp       AS order_time,
        o.order_approved_at               AS pay_time,
        o.order_delivered_carrier_date    AS ship_time,
        o.order_delivered_customer_date   AS sign_time,
        o.order_estimated_delivery_date   AS expect_sign_time,
        -- 时效计算（小时）
        EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600
            AS hour_order_to_pay,
        EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_approved_at)) / 3600
            AS hour_pay_to_ship,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 3600
            AS hour_ship_to_sign,
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 3600
            AS hour_total_logistics,
        -- 异常标记
        CASE WHEN o.order_approved_at < o.order_purchase_timestamp THEN 1 ELSE 0 END
            AS is_abnormal_time_pay,
        CASE WHEN o.order_delivered_carrier_date < o.order_approved_at THEN 1 ELSE 0 END
            AS is_abnormal_time_ship,
        CASE WHEN o.order_delivered_customer_date < o.order_delivered_carrier_date THEN 1 ELSE 0 END
            AS is_abnormal_time_sign,
        CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END
            AS is_late
    FROM olist_clean.olist_orders_clean o
    WHERE o.order_status = 'delivered' -- 只统计已签收
),
-- 分位数（用于可视化）
quantile_data AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY hour_total_logistics) AS p25_total,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY hour_total_logistics) AS p50_total,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY hour_total_logistics) AS p75_total,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY hour_total_logistics) AS p90_total
    FROM order_time
    WHERE hour_total_logistics > 0 AND hour_total_logistics < 720 -- 过滤极端异常
)
SELECT
    ot.*,
    qd.p25_total,
    qd.p50_total,
    qd.p75_total,
    qd.p90_total,
    -- 时效分级（可视化用）
    CASE
        WHEN hour_total_logistics <= qd.p25_total THEN '极快'
        WHEN hour_total_logistics <= qd.p50_total THEN '较快'
        WHEN hour_total_logistics <= qd.p75_total THEN '一般'
        ELSE '较慢'
    END AS timely_level
FROM order_time ot
CROSS JOIN quantile_data qd
WHERE hour_total_logistics > 0 AND hour_total_logistics < 720; -- 过滤异常

COMMIT;
