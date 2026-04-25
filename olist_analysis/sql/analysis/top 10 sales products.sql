-- 各品类GMV
SELECT product_id,
	   SUM(payment_value) AS GMV
FROM olist_clean.olist_order_items_clean oi 
LEFT JOIN olist_clean.olist_order_payments_clean p 
ON oi.order_id = p.order_id
GROUP BY product_id
ORDER BY GMV DESC;

-- TOP 10 sales products
SELECT product_id,
	   SUM(payment_value) AS GMV,
	   ROW_NUMBER() OVER(ORDER BY SUM(payment_value) DESC) AS ranking 
FROM olist_clean.olist_order_items_clean oi 
LEFT JOIN olist_clean.olist_order_payments_clean p 
ON oi.order_id = p.order_id
GROUP BY product_id
ORDER BY GMV DESC;
