-- https://leetcode.cn/problems/the-number-of-employees-which-report-to-each-employee/description/?envType=study-plan-v2&envId=sql-free-50

SELECT e1.employee_id AS employee_id,
       e1.name AS name,
       COUNT(*) AS reports_count,
       ROUND(AVG(e2.age)) AS average_age
FROM Employees e1
JOIN Employees e2
WHERE e1.employee_id = e2.reports_to
GROUP BY e1.employee_id
ORDER by e1.employee_id;