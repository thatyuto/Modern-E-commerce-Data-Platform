-- https://leetcode.cn/problems/classes-with-at-least-5-students/description/?envType=study-plan-v2&envId=sql-free-50

# Write your MySQL query statement below
select
class
from courses
group by class
having count(student)>=5