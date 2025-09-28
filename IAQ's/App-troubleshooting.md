 **PostgreSQL Troubleshooting Checklist** 

---

### 🔎 PostgreSQL Troubleshooting – Interview Points

### **1. Performance Issues**

1. Check active queries in `pg_stat_activity`.
2. Identify long-running or blocked queries.
3. Use `EXPLAIN / EXPLAIN ANALYZE` to see execution plan.
4. Check table statistics → run `ANALYZE` if outdated.
5. Check for dead tuples/bloat → run `VACUUM`.
6. Review indexes (missing/unused).
7. Check system resources (CPU, RAM, I/O).

✅ **Solution:** Index tuning, query optimization, vacuum/analyze, config tuning (`work_mem`, `shared_buffers`).

---

### **2. Replication Issues**

1. On primary, check `pg_stat_replication` (state, write/flush/replay lag).
2. On standby, check `pg_last_xact_replay_timestamp()` for delay.
3. Review logs for WAL streaming/connection errors.
4. Check network and disk performance.

✅ **Solution:** Restart replication, adjust `max_wal_size`, tune `wal_keep_size`, fix network/storage bottlenecks.

---

### **3. Storage / WAL Issues**

1. Check WAL directory size (`du -sh $PGDATA/pg_wal`).
2. Check archiver status in `pg_stat_archiver`.
3. Verify replica is consuming WALs.
4. Check disk space and partitions.

✅ **Solution:** Free space, restart standby, configure `archive_cleanup_command`, increase WAL storage.

---

### **4. Transaction Issues (Wraparound Risk)**

1. Check database age: `SELECT datname, age(datfrozenxid) FROM pg_database;`.
2. Find old tables: `SELECT relname, age(relfrozenxid) FROM pg_class;`.
3. Check autovacuum status.

✅ **Solution:** Run `VACUUM FREEZE`, tune autovacuum (`autovacuum_freeze_max_age`, scale factors), add monitoring for xid age.

---

#### 🧠 Short Interview Answer (Summary Style)

> “My approach is always structured:
> 1️⃣ For performance → check queries, plans, stats, vacuum, indexes, system.
> 2️⃣ For replication → check `pg_stat_replication`, replay lag, logs, network.
> 3️⃣ For WAL/storage → check `pg_wal` size, archiver, replica status.
> 4️⃣ For transaction wraparound → check xid age, run `VACUUM FREEZE`, tune autovacuum.
> This step-by-step process helps me quickly isolate and fix issues.”

---
