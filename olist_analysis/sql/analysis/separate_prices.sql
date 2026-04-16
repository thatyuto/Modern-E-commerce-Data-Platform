-- separate the prices datas

SELECT order_id,
	   product_id,
	   price,
	   CASE 
	   		WHEN price<49.9 THEN 'Budget'
	   		WHEN price BETWEEN 49.9 AND 109 THEN 'Regular'
	   		ELSE 'Premium'
	   END AS price_tier
FROM olist_raw.order_items
LIMIT 10;