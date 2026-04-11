-- https://leetcode.cn/problems/sales-analysis-iii/description/?envType=study-plan-v2&envId=sql-free-50

SELECT Sales.product_id, Product.product_name
FROM Sales
LEFT JOIN Product
ON Sales.product_id = Product.product_id
WHERE sale_date BETWEEN '2019-01-01' AND '2019-03-31'
AND Product.product_id NOT IN (
    SELECT DISTINCT product_id
    FROM Sales
    WHERE sale_date NOT BETWEEN '2019-01-01' AND '2019-03-31'
)
-- 去重（避免同一产品多条销售记录重复显示）
GROUP BY Product.product_id, Product.product_name;