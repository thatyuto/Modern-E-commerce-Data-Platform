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
