-- https://leetcode.cn/problems/average-time-of-process-per-machine/description/?envType=study-plan-v2&envId=sql-free-50

SELECT a.machine_id, ROUND(AVG(a.timestamp - b.timestamp),3) AS processing_time
FROM Activity a
JOIN Activity b
ON a.machine_id = b.machine_id
AND a.process_id = b.process_id
AND a.activity_type = 'end'
And b.activity_type = 'start'
GROUP BY a.machine_id;