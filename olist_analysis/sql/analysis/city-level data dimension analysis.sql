SELECT COUNT(DISTINCT c.customer_id) AS "customers num",
	   COUNT(order_id) AS "orders num",
	   c.customer_city AS "city"
FROM olist_customers_clean c
LEFT JOIN olist_orders_clean o
ON c.customer_id = o.customer_id
GROUP BY c.customer_city
ORDER BY "orders num" DESC;



