
SELECT COUNT(order_id) AS "Number of orders",
	   SUM(payment_value) AS "Aggregate amount",
	   SUM(payment_value)/COUNT(order_id) AS "Average price"
FROM olist_raw.payments;