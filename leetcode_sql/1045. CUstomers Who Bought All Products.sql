-- https://leetcode.cn/problems/customers-who-bought-all-products/description/?envType=study-plan-v2&envId=sql-free-50

WITH product_count AS (
    SELECT COUNT(product_key) AS total
    FROM Product
)

SELECT customer_id
FROM Customer c
GROUP BY customer_id
HAVING COUNT(DISTINCT c.product_key) = (SELECT total FROM product_count); 