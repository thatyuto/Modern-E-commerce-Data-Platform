-- https://leetcode.cn/problems/invalid-tweets/description/?envType=study-plan-v2&envId=sql-free-50

SELECT tweet_id 
FROM Tweets
WHERE LENGTH(content) > 15;