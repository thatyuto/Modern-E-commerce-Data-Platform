
BEGIN;  -- 开启事务，确保新增字段和更新数据要么同时成功，要么同时回滚
-- 1. 新增字段：加长长度+修正默认值（VARCHAR(100)足够存多个异常，默认normal）
ALTER TABLE olist_clean.olist_orders_clean
ADD COLUMN time_status VARCHAR(100) DEFAULT 'normal';  -- 长度改为100，默认正常

-- 2. 更新异常标记：解决空值、多余逗号问题
UPDATE olist_clean.olist_orders_clean
SET time_status = 
  -- 用TRIM去掉末尾多余的“, ”，空字符串时设为“normal”
  CASE 
    -- 先拼接所有异常标记，再去掉末尾逗号
    WHEN TRIM(BOTH ', ' FROM 
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/3600, 2) < 0 THEN 'pay_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/3600, 2) > 24 THEN 'pay_duration_over_24h, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at))/3600, 2) < 0 THEN 'ship_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at))/3600, 2) > 72 THEN 'ship_duration_over_72h, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date))/3600, 2) < 0 THEN 'sign_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date))/3600, 2) > 168 THEN 'sign_duration_over_168h, ' ELSE '' END
    ) = '' THEN 'normal'  -- 无异常时，设为“normal”
    -- 有异常时，返回去掉末尾逗号的标记
    ELSE TRIM(BOTH ', ' FROM 
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/3600, 2) < 0 THEN 'pay_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_approved_at - order_purchase_timestamp))/3600, 2) > 24 THEN 'pay_duration_over_24h, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at))/3600, 2) < 0 THEN 'ship_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_carrier_date - order_approved_at))/3600, 2) > 72 THEN 'ship_duration_over_72h, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date))/3600, 2) < 0 THEN 'sign_duration_negative, ' ELSE '' END ||
      CASE WHEN ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_delivered_carrier_date))/3600, 2) > 168 THEN 'sign_duration_over_168h, ' ELSE '' END
    )
  END;

COMMIT;  -- 确认无误后提交事务，永久生效





