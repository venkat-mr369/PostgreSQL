Tuning queries in PostgreSQL is a **core DBA skill** and a hot interview question.

---

# 🧭 Query Tuning Approach in PostgreSQL

### **Step 1: Identify Slow Queries**

* Enable logging:

  ```conf
  log_min_duration_statement = 500ms   # log queries > 500ms (0.5 Sec)
  ```
* Or check currently running queries:

  ```sql
  SELECT pid, query, state, wait_event, now()-query_start AS runtime
  FROM pg_stat_activity
  WHERE state != 'idle';
  ```

---

### **Step 2: Analyze Execution Plan**

* Use `EXPLAIN` (estimated) or `EXPLAIN ANALYZE` (actual).
  Example:

```sql
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 20000;
```

Output:

```
Seq Scan on employees  (cost=0.00..11.40 rows=1 width=36)
  Filter: (salary > 20000)
  Rows Removed by Filter: 2
```

🔍 Shows **sequential scan** (not efficient for large tables).

---

### **Step 3: Common Query Tuning Techniques**

#### 1. **Add Indexes**

* If query uses `WHERE salary > 20000`:

  ```sql
  CREATE INDEX idx_salary ON employees(salary);
  ```
* Now planner will use **Index Scan** instead of Seq Scan.

---

#### 2. **Use Covering Index (INCLUDE)**

If query also needs `name`:

```sql
CREATE INDEX idx_salary_cover ON employees(salary) INCLUDE (name);
```

* Avoids extra heap lookup.

---

#### 3. **Use Partial Index**

If only 10% rows have salary > 20000:

```sql
CREATE INDEX idx_high_salary ON employees(salary)
WHERE salary > 20000;
```

* Saves space + speeds up specific queries.

---

#### 4. **Use Expression Index**

If query has function:

```sql
SELECT * FROM employees WHERE lower(name) = 'meena';
```

Create index:

```sql
CREATE INDEX idx_lower_name ON employees((lower(name)));
```

---

#### 5. **Rewrite Queries**

Bad:

```sql
SELECT * FROM employees WHERE salary + 5000 > 25000;
```

→ Index on `salary` won’t be used.

Good:

```sql
SELECT * FROM employees WHERE salary > 20000;
```

---

#### 6. **JOIN Optimization**

* Ensure join columns are indexed.

```sql
CREATE INDEX idx_deptid ON employees(dept_id);
```

* Use `EXPLAIN ANALYZE` to see if planner picks **Nested Loop**, **Hash Join**, or **Merge Join**.

---

#### 7. **Avoid SELECT ***

Bad:

```sql
SELECT * FROM employees;
```

Good:

```sql
SELECT name, salary FROM employees WHERE salary > 20000;
```

→ Reduces data transfer + speeds up query.

---

#### 8. **Update Statistics**

If planner misestimates rows:

```sql
ANALYZE employees;
```

→ Keeps stats fresh for better plans.

---

#### 9. **Use CTEs/Materialized Views Wisely**

* For complex reports → precompute data.

```sql
CREATE MATERIALIZED VIEW high_salaries AS
SELECT name, salary FROM employees WHERE salary > 20000;
```

---

### **Step 4: System Tuning for Queries**

* Increase `work_mem` for sorts/joins:

  ```conf
  work_mem = 64MB
  ```
* Tune `effective_cache_size` so planner knows cache size:

  ```conf
  effective_cache_size = 8GB
  ```

---

# 🧾 Real Example Walkthrough

Suppose we have table:

```sql
CREATE TABLE employees (
  emp_id serial PRIMARY KEY,
  name text,
  dept_id int,
  salary int
);

INSERT INTO employees (name, dept_id, salary)
SELECT 'emp'||g, (random()*10)::int, (10000 + random()*90000)::int
FROM generate_series(1,1000000) g;
```

---

### Query:

```sql
SELECT name, salary FROM employees WHERE salary > 80000;
```

#### 🔎 Step 1: Check Plan

```sql
EXPLAIN ANALYZE SELECT name, salary FROM employees WHERE salary > 80000;
```

Output:

```
Seq Scan on employees  (cost=0.00..18000.00 rows=10000 width=40)
  Filter: (salary > 80000)
  Actual rows=20000 loops=1
```

→ Full table scan, slow.

---

#### 🔧 Step 2: Add Index

```sql
CREATE INDEX idx_salary ON employees(salary);
```

Re-run:

```sql
EXPLAIN ANALYZE SELECT name, salary FROM employees WHERE salary > 80000;
```

Output:

```
Index Scan using idx_salary on employees  (cost=0.43..5000.00 rows=20000 width=40)
  Index Cond: (salary > 80000)
```

✅ Uses Index Scan → much faster.

---

# 🧠 Interview-Ready Short Answer

> “To tune queries in PostgreSQL, I follow 3 steps:
> 1️⃣ Identify slow queries from logs or `pg_stat_activity`.
> 2️⃣ Run `EXPLAIN ANALYZE` to see execution plan.
> 3️⃣ Apply fixes: add proper indexes (B-Tree, Partial, Expression, Covering), rewrite queries to be sargable, analyze tables for fresh stats, and tune memory settings like `work_mem`.
> For example, a salary filter query on employees was using a seq scan. After adding an index on salary, the planner switched to Index Scan and the query ran 10x faster.”

---

**list of common bad queries and their tuned versions** (like Top 10 SQL anti-patterns and fixes in PostgreSQL)?
Perfect 👍 Venkat — let’s build a **Top 10 PostgreSQL Query Anti-Patterns (bad queries) and their Tuned Versions (good queries)**.
This will give you a ready set of examples you can use in interviews.

---

# 🚫 10 Common Bad Queries & ✅ Tuned Versions

---

### **1. Using `SELECT *` (fetching all columns)**

🚫 Bad:

```sql
SELECT * FROM employees WHERE salary > 50000;
```

* Pulls unnecessary columns, more I/O.

✅ Good:

```sql
SELECT name, salary FROM employees WHERE salary > 50000;
```

* Fetches only required columns → less I/O, faster execution.

---

### **2. Functions on Indexed Columns (Non-Sargable Query)**

🚫 Bad:

```sql
SELECT * FROM employees WHERE lower(name) = 'meena';
```

* Index on `name` not used.

✅ Good:

```sql
CREATE INDEX idx_lower_name ON employees((lower(name)));
SELECT * FROM employees WHERE lower(name) = 'meena';
```

* Expression index → Index Scan instead of Seq Scan.

---

### **3. Inefficient `OR` Conditions**

🚫 Bad:

```sql
SELECT * FROM employees WHERE dept_id = 5 OR salary > 60000;
```

* Causes Seq Scan.

✅ Good:

```sql
CREATE INDEX idx_dept ON employees(dept_id);
CREATE INDEX idx_salary ON employees(salary);

-- Use UNION instead
SELECT * FROM employees WHERE dept_id = 5
UNION
SELECT * FROM employees WHERE salary > 60000;
```

* Uses indexes separately.

---

### **4. Using `IN` for Large Lists**

🚫 Bad:

```sql
SELECT * FROM employees WHERE dept_id IN (1,2,3,4,5,6,7,8,9,10);
```

* Slow for large IN lists.

✅ Good:

```sql
-- Create a temp table with dept_ids
CREATE TEMP TABLE filter_dept (id int);
INSERT INTO filter_dept VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10);

SELECT e.* FROM employees e
JOIN filter_dept f ON e.dept_id = f.id;
```

* Join with index → faster.

---

### **5. Unnecessary DISTINCT**

🚫 Bad:

```sql
SELECT DISTINCT name FROM employees;
```

* Forces sort/hash.

✅ Good:

```sql
SELECT name FROM employees GROUP BY name;
```

* Sometimes faster with indexes.
  Or better: avoid duplicates at insert level using `UNIQUE`.

---

### **6. Subqueries Instead of JOINs**

🚫 Bad:

```sql
SELECT name FROM employees
WHERE dept_id IN (SELECT id FROM departments WHERE location='HYD');
```

* Executes subquery multiple times.

✅ Good:

```sql
SELECT e.name FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.location = 'HYD';
```

* Single JOIN → better plan.

---

### **7. Wildcard Search without Index**

🚫 Bad:

```sql
SELECT * FROM employees WHERE name LIKE '%meena%';
```

* Can’t use index (leading `%`).

✅ Good:

```sql
CREATE INDEX idx_name_trgm ON employees USING gin (name gin_trgm_ops);
SELECT * FROM employees WHERE name LIKE '%meena%';
```

* Trigram index speeds up text search.

---

### **8. Sorting Large Data Without Index**

🚫 Bad:

```sql
SELECT * FROM employees ORDER BY salary;
```

* Forces full sort each time.

✅ Good:

```sql
CREATE INDEX idx_salary ON employees(salary);
SELECT * FROM employees ORDER BY salary;
```

* Index already sorted → faster.

---

### **9. Updating Without Filter**

🚫 Bad:

```sql
UPDATE employees SET salary = salary + 1000;
```

* Updates entire table (even unchanged rows).

✅ Good:

```sql
UPDATE employees SET salary = salary + 1000 WHERE dept_id = 10;
```

* Updates only relevant rows.

---

### **10. Large Aggregations Without Index**

🚫 Bad:

```sql
SELECT COUNT(*) FROM employees WHERE salary > 50000;
```

* Full table scan.

✅ Good:

```sql
CREATE INDEX idx_salary ON employees(salary);
SELECT COUNT(*) FROM employees WHERE salary > 50000;
```

* Index-only scan possible (Postgres can use visibility map).

---

# 📊 Summary for Interview

👉 If asked *“How do you tune queries in PostgreSQL?”*, you can say:

> “I look for common anti-patterns: `SELECT *`, functions on indexed columns, OR conditions, large IN lists, DISTINCT misuse, subqueries, text searches, and missing indexes. I fix them by adding proper indexes (B-Tree, GIN, Expression, Partial), rewriting queries into sargable form, avoiding unnecessary scans, and updating stats with `ANALYZE`. For example, a query `lower(name)='meena'` was doing a Seq Scan. After adding an expression index, it switched to Index Scan and ran 20x faster.”

---

