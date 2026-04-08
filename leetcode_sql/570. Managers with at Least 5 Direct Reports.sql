-- https://leetcode.cn/problems/managers-with-at-least-5-direct-reports/description/?envType=study-plan-v2&envId=sql-free-50

SELECT m.name
FROM Employee e
JOIN Employee m on m.id = e.managerId
GROUP BY m.id
HAVING COUNT(*) >= 5;