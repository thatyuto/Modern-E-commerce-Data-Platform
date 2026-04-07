-- https://leetcode.cn/problems/customer-who-visited-but-did-not-make-any-transactions/?envType=study-plan-v2&envId=sql-free-50

SELECT v.customer_id, COUNT(v.visit_id) AS count_no_trans
FROM Visits v
LEFT JOIN Transactions t
ON v.visit_id = t.visit_id
WHERE t.transaction_id is NULL
GROUP BY v.customer_id;