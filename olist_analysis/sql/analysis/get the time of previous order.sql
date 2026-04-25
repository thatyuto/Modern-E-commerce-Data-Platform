-- 获取用户上一单的时间

SELECT c.customer_unique_id,
	   o.order_id,
       o.order_purchase_timestamp AS curr_order_time,
	   LAG(order_purchase_timestamp) OVER(PARTITION BY customer_unique_id ORDER BY order_purchase_timestamp ASC)
FROM olist_clean.olist_orders_clean o
JOIN olist_clean.olist_customers_clean c
ON o.customer_id = c.customer_id;