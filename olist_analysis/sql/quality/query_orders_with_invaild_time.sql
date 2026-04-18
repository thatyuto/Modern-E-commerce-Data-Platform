-- Create a table to store data with invalid time in orders table

CREATE TABLE IF NOT EXISTS olist_raw.order_datetime_invalid (
	order_id TEXT,
	error_type TEXT,  -- e.g. The approval time is earlier than the order purchase time
	check_time TIMESTAMP DEFAULT NOW()  
);

-- Query orders with invalid time

/*
 Judgment conditions: 
	1. order_purchase_timestamp > order_approved_at
 	2. order_approved_at > order_delivered_carrier_date
	3. order_delivered_carrier_date > order_delivered_customer_date 
*/

INSERT INTO olist_raw.order_datetime_invalid (order_id, error_type)
SELECT 
    order_id,
    CASE
        WHEN order_approved_at < order_purchase_timestamp THEN '批准时间早于下单时间'
        WHEN order_delivered_carrier_date < order_approved_at THEN '发货时间早于批准时间'
        WHEN order_delivered_customer_date < order_delivered_carrier_date THEN '签收时间早于发货时间'
        WHEN order_purchase_timestamp IS NULL THEN '下单时间为空'
        WHEN order_approved_at IS NULL THEN '批准时间为空'
        WHEN order_delivered_carrier_date IS NULL THEN '发货时间为空'
        WHEN order_delivered_customer_date IS NULL THEN '签收时间为空'
        ELSE '时间顺序异常'
    END AS error_type
FROM olist_raw.orders
WHERE
    (order_approved_at IS NOT NULL AND order_approved_at < order_purchase_timestamp)
    OR (order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date < order_approved_at)
    OR (order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date < order_delivered_carrier_date)
    OR order_purchase_timestamp IS NULL
    OR order_approved_at IS NULL
    OR order_delivered_carrier_date IS NULL
    OR order_delivered_customer_date IS NULL;