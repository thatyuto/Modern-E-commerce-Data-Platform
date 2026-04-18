WITH price_tier AS (
	SELECT COUNT(*) AS total,
		   SUM(price) AS aggregate_amount,
		   SUM(CASE WHEN price < 49.9 THEN 1 ELSE 0 END) AS Budget_num,
		   SUM(CASE WHEN price BETWEEN 49.9 AND 109 THEN 1 ELSE 0 END) AS Regular_num,
		   SUM(CASE WHEN price>109 THEN 1 ELSE 0 END) AS Premium_num,
		   SUM(CASE WHEN price<49.9 THEN price ELSE 0 END) AS Budget_sum_amount,
	       SUM(CASE WHEN price BETWEEN 49.9 AND 109 THEN price ELSE 0 END) AS Regular_sum_amount,
	       SUM(CASE WHEN price>109 THEN price ELSE 0 END) AS Premium_sum_amount
	FROM olist_raw.order_items
)

-- The proportion of orders in each tier

SELECT ROUND(1.0*Budget_num/total,2) AS "The proportion of Budget number",
	   ROUND(1.0*Regular_num/total,2) AS "The proportion of Regular number",
	   ROUND(1.0*Premium_num/total,2) AS "The proportion of Premium number",
	   ROUND(1.0*Budget_sum_amount/aggregate_amount,2) AS "b_s_p",
	   ROUND(1.0*Regular_sum_amount/aggregate_amount,2) AS "r_s_p",
	   ROUND(1.0*Premium_sum_amount/aggregate_amount,2) AS "p_s_p"
FROM price_tier;
