-- https://leetcode.cn/problems/game-play-analysis-iv/description/?envType=study-plan-v2&envId=sql-free-50

# Write your MySQL query statement below

SELECT ROUND(
       SUM(DATEDIFF(a.event_date,first_date)=1) / COUNT(DISTINCT a.player_id)
       ,2) AS fraction
FROM Activity a 
JOIN (SELECT player_id, MIN(event_date) AS first_date
FROM Activity
GROUP BY player_id ) b
ON a.player_id = b.player_id;