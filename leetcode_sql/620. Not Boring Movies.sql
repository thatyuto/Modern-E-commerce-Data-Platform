-- https://leetcode.cn/problems/not-boring-movies/description/?envType=study-plan-v2&envId=sql-free-50

# Write your MySQL query statement below

SELECT id, movie, description, rating
FROM Cinema
WHERE id%2 != 0
AND description != 'boring'
ORDER BY rating DESC;