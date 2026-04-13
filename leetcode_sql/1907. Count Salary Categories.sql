-- https://leetcode.cn/problems/count-salary-categories/description/?envType=study-plan-v2&envId=sql-free-50

# Write your MySQL query statement below

-- create categories
WITH SalaryCategory AS(
    SELECT 'Low Salary' AS category
    UNION ALL
    SELECT 'Average Salary' AS category
    UNION ALL
    SELECT 'High Salary' AS category
    
)

-- count the number of accounts for each category and associate with fixed categories to ensure complete results
SELECT sc.category,
       COUNT(a.account_id) AS accounts_count
FROM SalaryCategory sc
LEFT JOIN Accounts a
ON(
    (sc.category = 'Low Salary' AND a.income < 20000)
    OR (sc.category = 'Average Salary' AND a.income BETWEEN 20000 AND 50000)
    OR (sc.category = 'High Salary' AND a.income > 50000)
)
GROUP BY sc.category;
