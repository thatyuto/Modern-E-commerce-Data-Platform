-- https://leetcode.cn/problems/confirmation-rate/description/?envType=study-plan-v2&envId=sql-free-50

SELECT s.user_id,
       ROUND(IFNULL(AVG(c.action = 'confirmed'),0),2) AS confirmation_rate 
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;