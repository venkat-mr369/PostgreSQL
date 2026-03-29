# PostgreSQL pg_cron — Complete Setup & Troubleshooting Guide

**Database:** `hrdb`
**PostgreSQL Version:** 18
**OS:** Ubuntu (Debian-based)
**Date:** March 29, 2026

---

## 1. Create Test Table in `hrdb`

```sql
CREATE TABLE test_load (
    id SERIAL PRIMARY KEY,
    name TEXT,
    created_at TIMESTAMP DEFAULT now()
);
```

---

## 2. Insert 1000 Records in One Shot

PostgreSQL best way = `generate_series()`

```sql
INSERT INTO test_load (name)
SELECT 'test_user'
FROM generate_series(1,1000);
```

This inserts 1000 records instantly.

---

## 3. Automate Every 1 Minute

### Option A: Using pg_cron (Best for DBA)

#### Step 1: Install pg_cron (version-specific package)

```bash
psql -V   -- Check your PostgreSQL version first
```

Install the correct package:

```bash
sudo apt update
sudo apt install postgresql-18-cron
```

> Replace `18` with your version: `postgresql-14-cron`, `postgresql-15-cron`, `postgresql-16-cron`, etc.

#### If "Unable to locate package" — Add PostgreSQL Official Repo

```bash
sudo apt install wget gnupg -y
```

```bash
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
```

```bash
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
```

```bash
sudo apt update
sudo apt install postgresql-18-cron
```

#### Step 2: Enable in postgresql.conf

```bash
sudo vi /etc/postgresql/18/main/postgresql.conf
```

Add these lines:

```ini
shared_preload_libraries = 'pg_cron'
cron.database_name = 'hrdb'
```

#### Step 3: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

#### Step 4: Create Extension

```sql
\c hrdb
CREATE EXTENSION pg_cron;
```

#### Step 5: Schedule the Job

```sql
SELECT cron.schedule(
    'insert_every_minute',
    '* * * * *',
    $$INSERT INTO test_load (name)
      SELECT 'test_user'
      FROM generate_series(1,1000);$$
);
```

---

### Option B: Using DO Loop (Quick Testing Only)

```sql
DO $$
BEGIN
    LOOP
        INSERT INTO test_load (name)
        SELECT 'test_user'
        FROM generate_series(1,1000);

        PERFORM pg_sleep(60);
    END LOOP;
END;
$$;
```

> ⚠️ Runs continuously in session — not production safe.

---

### Option C: Linux cron + psql (Real-World Simple)

Create script:

```bash
vi insert.sh
```

```bash
#!/bin/bash
psql -d hrdb -c "
INSERT INTO test_load (name)
SELECT 'test_user'
FROM generate_series(1,1000);"
```

Make executable and schedule:

```bash
chmod +x insert.sh
crontab -e
```

```bash
* * * * * /path/insert.sh
```

---

## 4. Troubleshooting — "connection failed" Error

### Problem

After scheduling the pg_cron job, all runs show:

```
status = failed
return_message = connection failed
```

### Root Cause Analysis

pg_cron creates an **internal TCP connection** to execute jobs. Key details from `cron.job`:

```
nodename  = localhost
nodeport  = 5432
```

This means pg_cron connects via **TCP (host)**, NOT via Unix socket (local).

### Fix Step 1: Add Trust Rules to pg_hba.conf

Find the file:

```sql
SHOW hba_file;
```

Edit it:

```bash
sudo vi /etc/postgresql/18/main/pg_hba.conf
```

Add the `local` trust line at the top:

```ini
local   all             postgres                                trust
```

### Fix Step 2: Check localhost Resolution (Critical)

```bash
getent hosts localhost
```

If output is:

```
::1             localhost
```

Then `localhost` resolves to **IPv6** (`::1`), NOT IPv4 (`127.0.0.1`). This means the IPv4 trust rule won't work — you need an **IPv6 trust rule** as well.

### Fix Step 3: Add IPv6 Trust Rule

```bash
sudo vi /etc/postgresql/18/main/pg_hba.conf
```

Add this line **before** the existing `host all all ::1/128 scram-sha-256` line:

```ini
host    all             postgres        ::1/128                 trust
```

### Final pg_hba.conf (Working)

```ini
# Database administrative login by Unix domain socket
local   all             postgres                                trust

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer

# IPv4 local connections:
host    all             postgres        127.0.0.1/32            trust
host    all             all             127.0.0.1/32            scram-sha-256
host    all             algo_user       0.0.0.0/0               md5

# IPv6 local connections:
host    all             postgres        ::1/128                 trust
host    all             all             ::1/128                 scram-sha-256

# Allow replication connections from localhost
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
host    algodb          algo_user       10.160.0.0/20           md5
```

### Fix Step 4: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

### Summary of the Issue

| Check | Detail |
|-------|--------|
| pg_cron installed | ✅ |
| shared_preload_libraries | ✅ `'pg_cron'` |
| cron.database_name | ✅ `'hrdb'` |
| pg_cron connects via | TCP to `localhost:5432` |
| localhost resolves to | `::1` (IPv6) |
| IPv4 trust rule (`127.0.0.1`) | ✅ Added but not used |
| **IPv6 trust rule (`::1`)** | **This was the missing piece** |
| Job scheduled | ✅ |

---

## 5. Verification

### Check Job Status

```sql
SELECT jobid, status, return_message, start_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 5;
```

Expected output after fix:

```
 jobid |  status   | return_message |            start_time
-------+-----------+----------------+----------------------------------
     1 | succeeded | INSERT 0 1000  | 2026-03-29 13:07:00.013444+05:30
     1 | succeeded | INSERT 0 1000  | 2026-03-29 13:06:00.012352+05:30
     1 | succeeded | INSERT 0 1000  | 2026-03-29 13:05:00.012248+05:30
```

### Check Row Count

```sql
SELECT count(*) FROM test_load;
```

### Check Insert Rate Per Minute

```sql
SELECT date_trunc('minute', created_at), count(*)
FROM test_load
GROUP BY 1
ORDER BY 1;
```

### View Scheduled Jobs

```sql
SELECT * FROM cron.job;
```

### Monitor Active Sessions

```sql
SELECT * FROM pg_stat_activity;
```

---

## 6. Managing pg_cron Jobs

### Unschedule a Job

```sql
SELECT cron.unschedule('insert_every_minute');
```

### Clear Job History

```sql
DELETE FROM cron.job_run_details;
```

---

## 7. DBA Best Practices

- `generate_series()` is the fastest method for bulk inserts
- Avoid row-by-row inserts (slow)
- For testing high load, consider using `UNLOGGED` tables
- Disable indexes if only testing insert performance
- For production pg_cron, use `.pgpass` instead of `trust`:
  - Set `md5` or `scram-sha-256` in `pg_hba.conf`
  - Store password in `/var/lib/postgresql/.pgpass`
- Monitor with `pg_stat_activity` during load tests

### Scheduler Comparison

| Method | Best For |
|--------|----------|
| pg_cron | DB-managed scheduled jobs |
| Linux cron | Simple, widely used, production-safe |
| Kubernetes CronJob | Container environments |
| Cloud Scheduler | GCP/AWS managed environments |

---

## 8. Diagnostic Commands Reference

```bash
# Check PostgreSQL version
psql -V

# Check if PostgreSQL is listening
sudo ss -tlnp | grep 5432

# Check listen_addresses
sudo -u postgres psql -c "SHOW listen_addresses;"

# Check localhost resolution (IPv4 vs IPv6)
getent hosts localhost

# Check pg_hba.conf location
sudo -u postgres psql -c "SHOW hba_file;"

# Check postgresql.conf location
sudo -u postgres psql -c "SHOW config_file;"
```
