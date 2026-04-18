--	calculate the aggregate amount of three ranges

SELECT SUM(CASE WHEN price<49.9 THEN 1 ELSE 0 END) AS Budget_num,
	   SUM(CASE WHEN price BETWEEN 49.9 AND 109 THEN 1 ELSE 0 END) AS Regular_num,
	   SUM(CASE WHEN price>109 THEN 1 ELSE 0 END) AS Premium_num,
	   SUM(CASE WHEN price<49.9 THEN price ELSE 0 END) AS Budget_sum_amount,
	   SUM(CASE WHEN price BETWEEN 49.9 AND 109 THEN price ELSE 0 END) AS Regular_sum_amount,
	   SUM(CASE WHEN price>109 THEN price ELSE 0 END) AS Premium_sum_amount
FROM olist_raw.order_items;