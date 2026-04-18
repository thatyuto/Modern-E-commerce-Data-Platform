--  calculate the number of Budget, Regular and Premium ranges
--  version 2

SELECT SUM(CASE WHEN price<49.9 THEN 1 ELSE 0 END) AS Budget_num,
	   SUM(CASE WHEN price BETWEEN 49.9 AND 109 THEN 1 ELSE 0 END) AS Regular,
	   SUM(CASE WHEN price>109 THEN 1 ELSE 0 END) AS Premium
FROM olist_raw.order_items;
