SELECT s.seller_city,
	   COUNT(s.seller_id) AS CNT,
	   ROW_NUMBER() OVER(ORDER BY COUNT(oi.order_id) DESC)
FROM olist_clean.olist_sellers_clean s 
LEFT JOIN olist_clean.olist_order_items_clean oi
ON s.seller_id = oi.seller_id
GROUP BY seller_city
LIMIT 10;
