SELECT DATE(order_purchase_timestamp) AS order_date,
	   COUNT(o.order_id) AS order_quantity,
	   SUM(payment_value) AS GMV
FROM olist_clean.olist_orders_clean o 
JOIN olist_clean.olist_order_payments_clean p 
ON o.order_id = p.order_id
GROUP BY DATE(order_purchase_timestamp);