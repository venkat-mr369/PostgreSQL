**PostgreSQL Basic Interview Questions**

---

### 1. Check PostgreSQL (`psql`) Service Status

```bash
# For systemd
sudo systemctl status postgresql

# For specific version
sudo systemctl status postgresql@14-main

# For legacy systems
sudo service postgresql status
```

---

### 2. Check for Blocking Queries

```sql
SELECT
  blocked.pid AS blocked_pid,
  blocked.query AS blocked_query,
  blocking.pid AS blocking_pid,
  blocking.query AS blocking_query
FROM pg_catalog.pg_locks blocked_lock
JOIN pg_catalog.pg_stat_activity blocked ON blocked.pid = blocked_lock.pid
JOIN pg_catalog.pg_locks blocking_lock ON blocking_lock.locktype = blocked_lock.locktype
  AND blocking_lock.database IS NOT DISTINCT FROM blocked_lock.database
  AND blocking_lock.relation IS NOT DISTINCT FROM blocked_lock.relation
  AND blocking_lock.page IS NOT DISTINCT FROM blocked_lock.page
  AND blocking_lock.tuple IS NOT DISTINCT FROM blocked_lock.tuple
  AND blocking_lock.transactionid IS NOT DISTINCT FROM blocked_lock.transactionid
  AND blocking_lock.classid IS NOT DISTINCT FROM blocked_lock.classid
  AND blocking_lock.objid IS NOT DISTINCT FROM blocked_lock.objid
  AND blocking_lock.objsubid IS NOT DISTINCT FROM blocked_lock.objsubid
  AND blocking_lock.pid != blocked_lock.pid
JOIN pg_catalog.pg_stat_activity blocking ON blocking.pid = blocking_lock.pid
WHERE NOT blocked_lock.granted;
```

---

### 3. Start/Stop PostgreSQL Service

```bash
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql
```

---

### 4. Enable PostgreSQL Service on Boot

```bash
sudo systemctl enable postgresql
```

---

### 5. Troubleshooting PostgreSQL Not Starting

* **Step 1:** Check status

```bash
sudo systemctl status postgresql
```

* **Step 2:** Check logs

```bash
journalctl -u postgresql
cat /var/log/postgresql/postgresql-14-main.log
```

* **Step 3:** Check configuration files (`postgresql.conf`, `pg_hba.conf`)

---

### 6. Handling Space Issues - Archive & Data Directory

#### Data Directory Full:

```sql
SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;
```

```sql
VACUUM FULL;
```

* Drop unused tables or partitions.
* Move old WAL logs or dump files.

---

### 7. Steps When Data Directory is Full

```bash
sudo systemctl stop postgresql
rm -f /var/lib/pgsql/14/data/pg_log/*.log
# Cleanup or free space as needed
sudo systemctl start postgresql
```

---

### 8. Steps When Archive Directory is Full

```bash
tar -czf old_archives.tar.gz /archive_dir/*.backup
rm -f /archive_dir/old_files
```

* Set logrotate or cronjob for auto-cleanup.

---

### 9. What is Archiving?

Archiving stores **WAL (Write-Ahead Logs)** externally for point-in-time recovery and replication.

```conf
archive_mode = on
archive_command = 'cp %p /archive_dir/%f'
```

---

### 10. Check Archive Status

```sql
SHOW archive_mode;
SHOW archive_command;
```

* Also check PostgreSQL logs for archive failures.

---

### 11. Why Enable Archiving?

* Supports **Point-in-Time Recovery (PITR)**
* Required for **streaming replication**
* Useful for **disaster recovery**

---

### 12. What is Hot Standby Replication?

A **read-only replica** of the primary PostgreSQL server that replays WALs in real-time.

---

### 13. Prerequisites for Hot Standby

**Primary Node Settings:**

```conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /archivedir/%f'
max_wal_senders = 10
```

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'yourpassword';
```

**Replica Setup:**

```bash
pg_basebackup -h primary_host -D /var/lib/pgsql/14/data -U replicator -P --wal-method=stream
```

```conf
hot_standby = on
```

* Create `standby.signal` file (PostgreSQL 12+)

---

### 14. Check Replication Sync Status

```sql
SELECT * FROM pg_stat_replication;
```

* Columns: `state`, `sync_state`, `sent_lsn`, `replay_lsn`

---

### 15. Check Replication Lag

On Primary:

```sql
SELECT pid, application_name, client_addr, state,
       pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replication_lag
FROM pg_stat_replication;
```

On Replica:

```sql
SELECT now() - pg_last_xact_replay_timestamp() AS replication_lag;
```

---


