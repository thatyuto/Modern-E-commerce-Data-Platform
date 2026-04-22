
-- 1. 先给订单表加“数据状态标记”字段（用于区分NULL类型，仅执行一次）
ALTER TABLE olist_clean.olist_orders_clean
ADD COLUMN data_status VARCHAR(20) DEFAULT 'normal';  -- 状态：normal（正常）/unpaid（未支付）/undelivered（未发货）/unreceived（未签收）/error（数据错误）

-- 2. 更新NULL对应的状态标记（根据业务含义分类）
UPDATE olist_clean.olist_orders_clean
SET data_status = 
  CASE 
    WHEN order_purchase_timestamp IS NULL THEN 'error'  -- 下单时间NULL：数据错误
    WHEN order_approved_at IS NULL THEN 'unpaid'       -- 支付时间NULL：未支付
    WHEN order_delivered_carrier_date IS NULL THEN 'undelivered'  -- 发货时间NULL：未发货
    WHEN order_delivered_customer_date IS NULL THEN 'unreceived'  -- 签收时间NULL：未签收
    ELSE 'normal'  -- 无NULL：正常订单
  END;

-- 3. 后续分析时，按需筛选数据（例：计算“支付→发货”时长，仅用“正常已发货”订单）
SELECT * 
FROM olist_clean.olist_orders_clean
WHERE data_status = 'normal'  -- 仅保留无NULL的正常订单
  AND order_delivered_carrier_date IS NOT NULL;  -- 确保已发货（避免未发货订单干扰）

