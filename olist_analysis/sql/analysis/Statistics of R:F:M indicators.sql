WITH user_order_summary AS (
	SELECT customer_unique_id,
		   MAX(order_purchase_timestamp) AS recent_time,
		   COUNT(o.order_id) AS Frequency,
		   SUM(p.payment_value) AS Monetary
	FROM olist_clean.olist_orders_clean o
	JOIN olist_clean.olist_customers_clean c 
	ON c.customer_id = o.customer_id 
	JOIN olist_clean.olist_order_payments_clean p
	ON o.order_id = p.order_id
	GROUP BY customer_unique_id
)

SELECT customer_unique_id,
	   CURRENT_DATE - recent_time AS Recency,
	   Frequency,
	   Monetary
FROM user_order_summary
ORDER BY FREQUENCY DESC;