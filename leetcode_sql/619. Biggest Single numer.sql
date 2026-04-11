-- https://leetcode.cn/problems/biggest-single-number/description/?envType=study-plan-v2&envId=sql-free-50

SELECT MAX(num) AS num
FROM MyNumbers
WHERE num NOT IN (
    SELECT num
    FROM MyNumbers
    GROUP BY num
    HAVING COUNT(num) > 1
);