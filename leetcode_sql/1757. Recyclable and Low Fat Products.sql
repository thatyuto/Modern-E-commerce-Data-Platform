-- https://leetcode.cn/problems/recyclable-and-low-fat-products/?envType=study-plan-v2&envId=sql-free-50

SELECT product_id 
FROM Products
WHERE Low_fats = "Y"
and recyclable = "Y";