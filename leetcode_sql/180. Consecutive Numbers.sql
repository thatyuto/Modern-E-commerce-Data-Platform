-- https://leetcode.cn/problems/consecutive-numbers/description/?envType=study-plan-v2&envId=sql-free-50

SELECT DISTINCT l1.num AS ConsecutiveNums
FROM Logs l1
LEFT JOIN Logs l2 ON l1.id = l2.id-1
LEFT JOIN Logs l3 ON l1.id = l3.id-2
WHERE l1.num = l2.num AND l2.num = l3.num; 