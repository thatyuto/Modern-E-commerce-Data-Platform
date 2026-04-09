-- https://leetcode.cn/problems/percentage-of-users-attended-a-contest/description/?envType=study-plan-v2&envId=sql-free-50

SELECT contest_id,
       ROUND(COUNT(r.user_id) / (SELECT COUNT(*) FROM Users) * 100, 2) AS percentage
FROM Register r
LEFT JOIN Users u
ON u.user_id = r.user_id
GROUP BY r.contest_id
ORDER BY percentage DESC, contest_id ASC;