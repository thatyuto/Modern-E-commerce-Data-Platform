-- https://leetcode.cn/problems/product-price-at-a-given-date/description/?envType=study-plan-v2&envId=sql-free-50

SELECT
    product_id,
    CASE
        WHEN MIN(change_date) > '2019-08-16' THEN 10
        ELSE (
            SELECT new_price
            FROM Products p2
            WHERE p2.product_id = p1.product_id
            AND change_date <= '2019-08-16'
            ORDER BY change_date DESC
            LIMIT 1
        )
    END AS price
FROM Products p1
GROUP BY product_id;