-- https://leetcode.cn/problems/rising-temperature/description/?envType=study-plan-v2&envId=sql-free-50

SELECT w1.id
FROM Weather w1
JOIN Weather w2
ON DATEDIFF(w1.recordDate,w2.recordDate) = 1
WHERE w1.temperature > w2.temperature;