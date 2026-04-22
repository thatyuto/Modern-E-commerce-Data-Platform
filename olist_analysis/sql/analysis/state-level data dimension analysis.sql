SELECT COUNT(DISTINCT c.customer_id) AS "customers num",
	   COUNT(order_id) AS "orders num",
	   c.customer_state AS "state"
FROM olist_customers_clean c
LEFT JOIN olist_orders_clean o
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY "orders num" DESC;