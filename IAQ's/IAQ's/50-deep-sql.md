Here are **50 deep-dive SQL join/interview questions and answers** based on your tables (emp, dept, hobbies, salary, entertainment). 


### 1. Get all employees with their department names using INNER JOIN.
```sql
SELECT emp.name, emp.designation, dept.name AS department
FROM emp
INNER JOIN dept ON emp.id = dept.id;
```

### 2. List all employees and their salaries using INNER JOIN.
```sql
SELECT emp.name, salary.salary
FROM emp
INNER JOIN salary ON emp.id = salary.id;
```

### 3. Get all employees and their hobbies including employees without hobbies using LEFT JOIN.
```sql
SELECT emp.name, hobbies.name AS hobby
FROM emp
LEFT JOIN hobbies ON emp.id = hobbies.id;
```

### 4. List all employees and entertainment interests, include employees without entertainment using RIGHT JOIN.
```sql
SELECT emp.name, entertainment.name AS entertainment
FROM emp
RIGHT JOIN entertainment ON emp.id = entertainment.id;
```

### 5. Find employees who have hobbies and salaries using INNER JOIN.
```sql
SELECT emp.name, hobbies.name AS hobby, salary.salary
FROM emp
INNER JOIN hobbies ON emp.id = hobbies.id
INNER JOIN salary ON emp.id = salary.id;
```

### 6. Find employees who do not have any hobbies (LEFT JOIN with NULL check).
```sql
SELECT emp.name
FROM emp
LEFT JOIN hobbies ON emp.id = hobbies.id
WHERE hobbies.id IS NULL;
```

### 7. Get all departments and number of employees in each department.
```sql
SELECT dept.name, COUNT(emp.id) AS num_employees
FROM dept
LEFT JOIN emp ON dept.id = emp.id
GROUP BY dept.name;
```

### 8. Retrieve employees along with their departments and salaries, ordered by salary descending.
```sql
SELECT emp.name, dept.name AS department, salary.salary
FROM emp
INNER JOIN dept ON emp.id = dept.id
INNER JOIN salary ON emp.id = salary.id
ORDER BY salary.salary DESC;
```

### 9. Show employees and their entertainment options (FULL OUTER JOIN).
```sql
SELECT emp.name, entertainment.name AS entertainment
FROM emp
FULL OUTER JOIN entertainment ON emp.id = entertainment.id;
```

### 10. Find employees earning above the average salary.
```sql
SELECT emp.name, salary.salary
FROM emp
INNER JOIN salary ON emp.id = salary.id
WHERE salary.salary > (SELECT AVG(salary) FROM salary);
```

### 11. List employees whose salaries are between 50,000 and 75,000.
```sql
SELECT emp.name, salary.salary
FROM emp
JOIN salary ON emp.id = salary.id
WHERE salary.salary BETWEEN 50000 AND 75000;
```

### 12. Show all hobbies and the names of employees who have those hobbies (join on ID).
```sql
SELECT hobbies.name AS hobby, emp.name
FROM hobbies
JOIN emp ON hobbies.id = emp.id;
```

### 13. Show all employees who do not have a matching department.
```sql
SELECT emp.name
FROM emp
LEFT JOIN dept ON emp.id = dept.id
WHERE dept.id IS NULL;
```

### 14. Find all employees and their birth dates (from salary table).
```sql
SELECT emp.name, salary.dob
FROM emp
JOIN salary ON emp.id = salary.id;
```

### 15. List all entertainment types and the employee names who enjoy them (join on ID).
```sql
SELECT entertainment.name AS entertainment, emp.name
FROM entertainment
JOIN emp ON entertainment.id = emp.id;
```

### 16. List all employees with their designations sorted by department.
```sql
SELECT emp.name, emp.designation, dept.name AS department
FROM emp
LEFT JOIN dept ON emp.id = dept.id
ORDER BY department;
```

### 17. Find all employees with no entertainment and salary above 60,000.
```sql
SELECT emp.name, salary.salary
FROM emp
LEFT JOIN entertainment ON emp.id = entertainment.id
JOIN salary ON emp.id = salary.id
WHERE entertainment.id IS NULL AND salary.salary > 60000;
```

### 18. Find the names and hobbies of employees who do not have salaries recorded.
```sql
SELECT emp.name, hobbies.name AS hobby
FROM emp
LEFT JOIN salary ON emp.id = salary.id
LEFT JOIN hobbies ON emp.id = hobbies.id
WHERE salary.id IS NULL AND hobbies.id IS NOT NULL;
```

### 19. Find department names with at least one employee having a hobby.
```sql
SELECT DISTINCT dept.name
FROM dept
JOIN emp ON dept.id = emp.id
JOIN hobbies ON emp.id = hobbies.id;
```

### 20. List all employees, show 'No Salary' where salary is missing.
```sql
SELECT emp.name, COALESCE(salary.salary::text, 'No Salary') AS salary
FROM emp
LEFT JOIN salary ON emp.id = salary.id;
```

### 21. Get the total salary of all employees in each department.
```sql
SELECT dept.name, SUM(salary.salary) AS total_salary
FROM dept
JOIN salary ON dept.id = salary.id
GROUP BY dept.name;
```

### 22. Find employees sharing the same hobby name.
```sql
SELECT e1.name AS emp1, e2.name AS emp2, h.name AS hobby
FROM hobbies h
JOIN emp e1 ON h.id = e1.id
JOIN emp e2 ON h.id = e2.id
WHERE e1.id  '1990-01-01';
```

### 29. Show employees with their hobbies and entertainment, even if some are missing.
```sql
SELECT emp.name, hobbies.name AS hobby, entertainment.name AS entertainment
FROM emp
LEFT JOIN hobbies ON emp.id = hobbies.id
LEFT JOIN entertainment ON emp.id = entertainment.id;
```

### 30. Find departments without any employees.
```sql
SELECT dept.name
FROM dept
LEFT JOIN emp ON dept.id = emp.id
WHERE emp.id IS NULL;
```

### 31. Count of employees for each designation in each department.
```sql
SELECT dept.name, emp.designation, COUNT(emp.id) as count
FROM emp
LEFT JOIN dept ON emp.id = dept.id
GROUP BY dept.name, emp.designation;
```

### 32. List the oldest employee(s) in each department.
```sql
SELECT dept.name, emp.name, salary.dob
FROM dept
JOIN emp ON dept.id = emp.id
JOIN salary ON emp.id = salary.id
WHERE (dept.name, salary.dob) IN (
    SELECT d.name, MIN(s.dob)
    FROM dept d
    JOIN salary s ON d.id = s.id
    GROUP BY d.name
);
```

### 33. Find all employees whose department is 'Finance' and who like 'Music'.
```sql
SELECT emp.name
FROM emp
JOIN dept ON emp.id = dept.id
JOIN hobbies ON emp.id = hobbies.id
WHERE dept.name='Finance' AND hobbies.name='Music';
```

### 34. List employees whose salary is above the maximum salary in the IT department.
```sql
SELECT emp.name, salary.salary
FROM emp
JOIN dept ON emp.id = dept.id
JOIN salary ON emp.id = salary.id
WHERE salary.salary >
    (SELECT MAX(salary.salary)
     FROM dept
     JOIN salary ON dept.id = salary.id
     WHERE dept.name = 'IT');
```

### 35. Find employee(s) with the same name but different designations.
```sql
SELECT e1.name
FROM emp e1
JOIN emp e2 ON e1.name = e2.name AND e1.id <> e2.id
WHERE e1.designation <> e2.designation;
```

### 36. List all unique hobbies among employees in 'Admin' department.
```sql
SELECT DISTINCT hobbies.name
FROM emp
JOIN dept ON emp.id = dept.id
JOIN hobbies ON emp.id = hobbies.id
WHERE dept.name = 'Admin';
```

### 37. List employee(s) whose salary is equal to the average salary of all employees.
```sql
SELECT emp.name, salary.salary
FROM emp
JOIN salary ON emp.id = salary.id
WHERE salary.salary = (SELECT AVG(salary) FROM salary);
```

### 38. Show departments with employees who have neither hobbies nor entertainment.
```sql
SELECT dept.name
FROM dept
JOIN emp ON dept.id = emp.id
LEFT JOIN hobbies ON emp.id = hobbies.id
LEFT JOIN entertainment ON emp.id = entertainment.id
WHERE hobbies.id IS NULL AND entertainment.id IS NULL;
```

### 39. List all employees younger than 30 years.
```sql
SELECT emp.name, salary.dob
FROM emp
JOIN salary ON emp.id = salary.id
WHERE salary.dob > (CURRENT_DATE - INTERVAL '30 years');
```

### 40. Show number of employees per hobby.
```sql
SELECT hobbies.name, COUNT(emp.id) as num_employees
FROM hobbies
LEFT JOIN emp ON hobbies.id = emp.id
GROUP BY hobbies.name;
```

### 41. List designations present in both emp and in employees with salaries above 80,000.
```sql
SELECT DISTINCT emp.designation
FROM emp
INNER JOIN salary ON emp.id = salary.id
WHERE salary.salary > 80000;
```

### 42. Get the department(s) with the most employees.
```sql
SELECT dept.name
FROM dept
JOIN emp ON dept.id = emp.id
GROUP BY dept.name
ORDER BY COUNT(emp.id) DESC
LIMIT 1;
```

### 43. Find employees whose name starts with 'A' and their salary is in the top 10%.
```sql
SELECT emp.name, salary.salary
FROM emp
JOIN salary ON emp.id = salary.id
WHERE emp.name LIKE 'A%'
  AND salary.salary >= (SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) FROM salary);
```

### 44. Get all employee names and all hobby names (CROSS JOIN).
```sql
SELECT emp.name, hobbies.name AS hobby
FROM emp
CROSS JOIN hobbies;
```

### 45. List all employees and indicate if they have a hobby (YES/NO).
```sql
SELECT emp.name,
       CASE WHEN hobbies.id IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_hobby
FROM emp
LEFT JOIN hobbies ON emp.id = hobbies.id;
```

### 46. Find the sum salary per designation for employees with entertainment records.
```sql
SELECT emp.designation, SUM(salary.salary) AS sum_salary
FROM emp
JOIN salary ON emp.id = salary.id
JOIN entertainment ON emp.id = entertainment.id
GROUP BY emp.designation;
```

### 47. Which employee(s) have the same salary as someone else? (self join)
```sql
SELECT e1.name, e1.id, salary1.salary
FROM salary salary1
JOIN salary salary2 ON salary1.salary = salary2.salary AND salary1.id <> salary2.id
JOIN emp e1 ON e1.id = salary1.id;
```

### 48. List employees whose salary is higher than all employees in Sales.
```sql
SELECT emp.name, salary.salary
FROM emp
JOIN dept ON emp.id = dept.id
JOIN salary ON emp.id = salary.id
WHERE salary.salary > ALL (
    SELECT salary.salary
    FROM dept
    JOIN salary ON dept.id = salary.id
    WHERE dept.name = 'Sales'
);
```

### 49. Show a list of employees, their hobby, and entertainment, using only those who have all three.
```sql
SELECT emp.name, hobbies.name AS hobby, entertainment.name
FROM emp
JOIN hobbies ON emp.id = hobbies.id
JOIN entertainment ON emp.id = entertainment.id;
```

### 50. List all departments and, for each, the count of employees, avg salary, and most common designation (mode).
```sql
SELECT dept.name,
       COUNT(emp.id) AS num_employees,
       AVG(salary.salary) AS avg_salary,
       MODE() WITHIN GROUP (ORDER BY emp.designation) AS common_designation
FROM dept
LEFT JOIN emp ON dept.id = emp.id
LEFT JOIN salary ON emp.id = salary.id
GROUP BY dept.name;
```
