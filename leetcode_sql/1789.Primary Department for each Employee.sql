-- https://leetcode.cn/problems/primary-department-for-each-employee/?envType=study-plan-v2&envId=sql-free-50

# Write your MySQL query statement below

SELECT employee_id, 
       CASE
            WHEN COUNT(*) = 1 then MIN(department_id)
            ELSE MAX(CASE WHEN primary_flag = 'Y' THEN department_id END)
        END AS department_id 
FROM Employee
GROUP BY employee_id;

-- Method 2: Using Subquery and Having
-- SELECT employee_id,department_id
-- FROM Employee
-- WHERE primary_flag = 'Y' OR
-- employee_id IN (
--     SELECT employee_id 
--     FROM Employee
--     GROUP BY employee_id
--     HAVING COUNT(1) = 1
-- )

-- Method 3: Using Window Functions

