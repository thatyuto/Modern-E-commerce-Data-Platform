-- 计算用户复购率
WITH user_cnt AS (
	SELECT customer_unique_id,
		   COUNT(DISTINCT order_id) AS order_frequency,
		   SUM(COUNT(DISTINCT order_id)) OVER() AS SumNumber
	FROM olist_clean.olist_customers_clean c
	LEFT JOIN olist_clean.olist_orders_clean o
	ON o.customer_id = c.customer_id
	GROUP BY customer_unique_id
),
total_user AS (
	SELECT count(*) AS total_num
	FROM user_cnt  
),
repurchase_user AS (
	SELECT count(*) AS repurchase_num
	FROM user_cnt
	WHERE order_frequency > 1
)

SELECT ROUND( repurchase_num * 100.0 / total_num, 2) AS "the percentage of repuchasing"
FROM total_user,repurchase_user;

