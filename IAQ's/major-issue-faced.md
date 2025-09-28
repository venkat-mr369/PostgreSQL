​***Any major issue you faced ? how to debug and provide the solution.***
Perfect 👌 — this is a **classic interview question**: *“Tell me about a major issue you faced in PostgreSQL, how you debugged it, and how you solved it.”*

Let me give you a **ready-to-use example story** that covers real-world debugging, tools, and resolution.

---

### ✅ Example Answer (Major Issue + Debugging + Solution)

🔹 **Issue:**
We had a production PostgreSQL database where application performance suddenly degraded — queries were taking minutes instead of seconds.

🔹 **Debugging Steps:**

1. **Check system load:**

   * Used `top`, `iostat`, `vmstat` → found high CPU + I/O wait.
2. **Check slow queries:**

   * Looked at `pg_stat_activity` to identify long-running queries.
   * Enabled `log_min_duration_statement` to log slow queries.
3. **Analyze query plan:**

   * Ran `EXPLAIN ANALYZE` → saw sequential scans on a large table instead of using indexes.
4. **Check statistics:**

   * Found table stats were outdated (`ANALYZE employees;`).
   * The planner was misestimating row counts.
5. **Check autovacuum:**

   * Found autovacuum was not running frequently enough → dead tuples were piling up, indexes were bloated.

🔹 **Solution:**

* Manually ran `VACUUM ANALYZE employees;` to clean up and refresh stats.
* Tuned `autovacuum` parameters (`autovacuum_vacuum_scale_factor`, `autovacuum_analyze_scale_factor`) to run more aggressively on large, high-write tables.
* Added missing indexes on frequently queried columns.
* After changes, queries that took minutes dropped back to milliseconds.

---

### 🧠 Short Interview-Friendly Version

👉 “One major issue I faced was severe query slowdown in production. I debugged by checking `pg_stat_activity`, slow query logs, and `EXPLAIN ANALYZE`. I found autovacuum was not keeping up, causing table bloat and bad planner estimates. I fixed it by running manual VACUUM/ANALYZE, tuning autovacuum, and adding proper indexes. This restored performance immediately.”

---

⚡Tip: Always structure your answer as:
**Issue → Debugging Steps → Solution → Outcome.**

---
Perfect 👍 Let’s build a **bank of real-world PostgreSQL issue scenarios** that you can reuse in interviews.
I’ll cover **3 major issues** with:

* **Problem**
* **Debugging steps** (tools, SQL queries, system checks)
* **Solution**
* **Outcome**

---

# 📝 Scenario 1: Replication Lag in Streaming Replication

**Problem:**

* We had a primary + replica setup. Application read queries on replica started showing stale data with a **15–20 min lag**.

**Debugging:**

1. Checked lag with SQL:

   ```sql
   SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;
   ```

   → Showed ~1200 seconds delay.

2. Checked `pg_stat_replication` on primary:

   ```sql
   SELECT client_addr, state, write_lag, flush_lag, replay_lag
   FROM pg_stat_replication;
   ```

   → Replica had large write/flush lag.

3. Checked replica logs: saw errors like `could not receive data from WAL stream`.

4. Used `iostat` / `sar` → confirmed replica disk was slow (I/O bottleneck).

**Solution:**

* Increased `wal_sender_timeout` and `wal_receiver_timeout` to avoid disconnects.
* Moved WAL archive to faster SSD storage.
* Tuned `max_wal_size` to reduce checkpoints.

**Outcome:**

* Replication delay dropped from 20 min → <5 seconds.
* Application reads were consistent again.

---

# 📝 Scenario 2: Transaction ID Wraparound Risk

**Problem:**

* Monitoring alerted:

  ```
  database is not accepting commands to avoid wraparound data loss
  ```
* Autovacuum couldn’t keep up → risk of XID wraparound.

**Debugging:**

1. Checked age of tables:

   ```sql
   SELECT relname, age(datfrozenxid) 
   FROM pg_class c 
   JOIN pg_database d ON d.oid = c.relnamespace
   ORDER BY age(datfrozenxid) DESC LIMIT 10;
   ```

2. Found large table `transactions` with ~2 billion XID age.

3. Checked autovacuum logs → it was not running due to misconfigured thresholds (`autovacuum_freeze_max_age`).

**Solution:**

* Ran manual freeze vacuum:

  ```sql
  VACUUM FREEZE transactions;
  ```
* Tuned config:

  ```conf
  autovacuum_freeze_max_age = 200000000
  autovacuum_vacuum_scale_factor = 0.1
  ```
* Scheduled `pgbackrest` backups with `--recovery-option` to ensure WAL archiving kept up.

**Outcome:**

* Cleared wraparound risk.
* No downtime.
* Added monitoring for `age(datfrozenxid)` across all DBs.

---

# 📝 Scenario 3: WAL Archive Full (Disk Pressure)

**Problem:**

* Primary DB stopped accepting new writes. Error:

  ```
  FATAL: could not write to file "pg_wal/000000010000000A000000FF": No space left on device
  ```

**Debugging:**

1. Checked WAL directory size:

   ```bash
   du -sh $PGDATA/pg_wal
   ```

   → 95% disk full.

2. Checked replication → replica was **down**, so WAL files were piling up.

3. Checked archiving status:

   ```sql
   SELECT * FROM pg_stat_archiver;
   ```

   → `failed_count` increasing.

**Solution:**

* Brought replica back online to consume WALs.
* Temporarily moved old WALs to external storage.
* Increased WAL partition size (dedicated disk).
* Tuned retention:

  ```conf
  max_wal_size = 4GB
  archive_cleanup_command = 'pg_archivecleanup ...'
  ```
* Implemented monitoring: alert if WAL >70% disk.

**Outcome:**

* Database recovered.
* Prevented future outages with proper archiving & monitoring.

---

# ✅ Interview-Ready Summary (All 3 in 2 Lines Each)

* **Replication Lag:** Debugged with `pg_stat_replication` + logs → fixed I/O + tuned WAL → lag dropped from 20 min to 5s.
* **XID Wraparound:** Found old table with high age → ran `VACUUM FREEZE` + tuned autovacuum → avoided data corruption.
* **WAL Full:** Primary stopped due to pg_wal disk full → restarted replica, cleaned old WALs, resized disk → restored service.

---

