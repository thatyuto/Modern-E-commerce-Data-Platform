WITH user_cnt AS (
	SELECT customer_unique_id,
		   COUNT(DISTINCT order_id) AS order_frequency
	FROM olist_clean.olist_customers_clean c
	LEFT JOIN olist_clean.olist_orders_clean o
	ON o.customer_id = c.customer_id
	GROUP BY customer_unique_id
)

SELECT order_frequency,
	   COUNT(customer_unique_id) AS "customers number",
	   ROUND(COUNT(customer_unique_id)*100.0/ SUM(COUNT(customer_unique_id)) OVER(), 2)
FROM user_cnt
GROUP BY order_frequency
ORDER BY order_frequency DESC;
