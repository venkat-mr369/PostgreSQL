**PostgreSQL DBA scenario-based interview questions with detailed solutions and reasoning** to demonstrate both practical knowledge and best practices for real-world administration tasks.

## 1. **Critical Query Performance Issue**

**Scenario:**  
A SELECT query that was previously fast is now taking a long time to execute, and users are complaining.

**Solution/Approach:**  
- **Step 1: Diagnose with EXPLAIN ANALYZE** to view the actual execution plan.
- **Step 2: Check Indexes** – See if key columns are indexed and being utilized. A missing or unused index could cause slowness.
- **Step 3: Inspect Table Bloat** – Excessive dead tuples from heavy DML activity can slow queries. Check `pg_stat_user_tables` and consider a VACUUM or REINDEX if needed.
- **Step 4: Review Statistics** – If statistics are outdated, run ANALYZE to refresh them for the optimizer.
- **Step 5: Monitor Current Activity** – Observe other running queries using `pg_stat_activity` and system load.
- **Step 6: Check Autovacuum** – Ensure autovacuum is running and not lagging.
- **Step 7: Simplify or Rewrite Queries** – Sometimes rewriting joins, using proper WHERE conditions, or breaking queries up can help.

**Why:**  
Performance regressions are usually caused by execution plan changes, missing indexes, table bloat, or high concurrent load. A systematic, data-driven approach ensures you target the real issue, not just symptoms[1][2].

## 2. **Database Corruption Recovery**

**Scenario:**  
One of your PostgreSQL databases fails to start, and you see evidence of corruption in log files.

**Solution/Approach:**  
- **Step 1: Stop the PostgreSQL Service** immediately to avoid overwriting WAL logs needed for recovery.
- **Step 2: Analyze Logs** to locate the corrupted table, file, or block.
- **Step 3: Use Backups** – Restore from the most recent base backup, then apply WAL files (if point-in-time recovery is possible).
- **Step 4: Use `pg_resetwal`/`pg_resetxlog`** ONLY for severe meta-data corruption and as a last resort—this can cause data loss or inconsistency.
- **Step 5: For Minor Corruption** – Dump unaffected tables and reload them into a new cluster.
- **Step 6: After Recovery, Investigate the Root Cause** – Disk failure, hardware, OS, or application bug.

**Why:**  
Stopping the system prevents further data loss. Using proper restores and WAL replay ensures consistent recovery. Direct repairs risk data loss and should only be attempted with caution[1].

## 3. **Row-Level Security Implementation**

**Scenario:**  
The application requires that users only see records related to their organization.

**Solution/Approach:**  
- **Step 1:** Enable RLS with  
  `ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;`
- **Step 2:** Define policies, e.g.:
  ```
  CREATE POLICY org_access
    ON your_table
    USING (organization_id = current_setting('myapp.current_org')::int);
  ```
- **Step 3:** Set the context through PostgreSQL session variables.

**Why:**  
Built-in RLS is safer, avoids complex application-side filtering, and is ideal for multi-tenant environments or regulatory compliance[1][3].

## 4. **Planning a Zero-Downtime Schema Migration**

**Scenario:**  
A large table requires a new column with a default value, but the system cannot be taken offline.

**Solution/Approach:**  
- **Step 1:** Add the column without a default:  
  `ALTER TABLE orders ADD COLUMN new_col INT;` (fast, no table rewrite).
- **Step 2:** Backfill the column in small batches to avoid long locks:
  ```
  UPDATE orders SET new_col = 0 WHERE ... LIMIT 10000;
  ```
- **Step 3:** Once backfilled, set the default:
  `ALTER TABLE orders ALTER COLUMN new_col SET DEFAULT 0;`
- **Step 4:** Make the column NOT NULL if required, after backfill.

**Why:**  
Avoiding a full-table lock prevents downtime. Batch updates plus deferred constraints allow for continuous service for mission-critical systems[1].

## 5. **Large Database Migration**

**Scenario:**  
Tasked to migrate a 1TB MySQL database to PostgreSQL with minimal downtime.

**Solution/Approach:**  
- **Step 1:** Use tools like pgloader or Ora2PG for schema/data conversion and transfer.
- **Step 2:** Run full migration on a staging server for validation.
- **Step 3:** Implement CDC (change data capture) or replication tools to sync changes after initial migration.
- **Step 4:** Schedule a final short downtime window ("cutover") to apply the last deltas and switch applications.

**Why:**  
Minimizes downtime, ensures accuracy, allows dry runs, and provides rollback options in case of failure[1].

## 6. **PostgreSQL Replication & HA Setup**

**Scenario:**  
How do you design for high-availability and failover for an e-commerce production database?

**Solution/Approach:**  
- **Step 1:** Set up streaming replication (primary/standby). Standby servers receive WAL files in real time.
- **Step 2:** Use Patroni, pg_auto_failover, or similar automation tools for leader election and auto-failover.
- **Step 3:** Direct application reads to replicas and all writes to primary.
- **Step 4:** Schedule and verify backups, ideally using logical and physical techniques.

**Why:**  
Protects data against hardware failures, allows zero or minimal downtime, and improves read scalability[1].

## 7. **Resolving Increased Disk Usage After Batch Job**

**Scenario:**  
A nightly batch job causes a dangerous spike in disk consumption.

**Solution/Approach:**  
- **Step 1:** Determine which tables/indexes grew. Use `pg_class` and `pg_stat_user_tables` to compare table and index size before/after.
- **Step 2:** Check for dead tuples indicating insufficient autovacuum.
- **Step 3:** Tune autovacuum to be more aggressive, or trigger a manual VACUUM.
- **Step 4:** Optimize the batch job to avoid mass updates/deletes, or break it into smaller chunks.

**Why:**  
Prevents database bloating, maintains performance and storage predictability[2][1].

## 8. **Common Command-Based Scenarios (Quick Reference)**

| Scenario                            | Command Example / Solution                                             |
|--------------------------------------|-----------------------------------------------------------------------|
| Check running queries                | `SELECT * FROM pg_stat_activity;`                                     |
| Find database size                   | `SELECT pg_size_pretty(pg_database_size('mydb'));`                    |
| Start/stop DB server                 | `sudo systemctl start/stop postgresql`                                |
| Backup database                      | `pg_dump mydb > mydb.sql`                                             |
| Restore backup                       | `psql mydb < mydb.sql`                                                |
| List all tablespaces                 | `\db` in psql or query `pg_tablespace`                                |
| Add index on column                  | `CREATE INDEX idx_name ON tablename(column);`                         |
| Analyze query performance            | `EXPLAIN ANALYZE SELECT ...;`                                         |
| Enable row-level security            | `ALTER TABLE t ENABLE ROW LEVEL SECURITY;`                            |

