Perfect 👍 Let’s make it consistent:

* **Cluster superuser** = `postgres` (not `venkat`)
* **Replication user** = `repuser` (instead of `replicator`)

That means:

* Run `initdb` as `postgres` OS account → DB superuser will be `postgres`.
* Use `repuser` strictly for streaming replication.

---

# 🚀 PostgreSQL 16 Streaming Replication (Oracle Linux 9.5)

**Primary (vm01: 10.166.0.4)** ↔ **Standby (vm02: 10.166.0.5)**

---

## **1. Pre-Requisites (On Both VMs)**

### 1.1 Update System

```bash
sudo dnf update -y
```

### 1.2 Install PostgreSQL 16

```bash
# Install PGDG repo
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Disable built-in module
sudo dnf -qy module disable postgresql

# Install PostgreSQL 16
sudo dnf install -y postgresql16 postgresql16-server postgresql16-contrib
```

### 1.3 Create Directories

```bash
sudo mkdir -p /pgdata/16/data
sudo mkdir -p /pgwal/16/wal
sudo chown -R postgres:postgres /pgdata/16 /pgwal/16
```

---

## **2. Initialize Primary (vm01: 10.166.0.4)**

### 2.1 Initdb

```bash
sudo su - postgres
/usr/pgsql-16/bin/initdb -D /pgdata/16/data
```

Now the **database superuser = postgres**. ✅

---

### 2.2 Edit `postgresql.conf`

```bash
vi /pgdata/16/data/postgresql.conf
```

Set:

```ini
listen_addresses = '*'
wal_level = replica
archive_mode = on
archive_command = 'cp %p /pgwal/16/wal/%f'
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = 512MB
hot_standby = on
```

---

### 2.3 Edit `pg_hba.conf`

```bash
vi /pgdata/16/data/pg_hba.conf
```

Add:

```ini
# Allow replication user from standby
host    replication     repuser     10.166.0.5/32     scram-sha-256
```

---

### 2.4 Start PostgreSQL

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l /pgdata/16/logfile start
```

---

### 2.5 Create Replication User

```bash
psql -U postgres -d postgres
```

Inside psql:

```sql
CREATE ROLE repuser WITH REPLICATION LOGIN PASSWORD 'StrongPass123';
```

---

## **3. Setup Standby (vm02: 10.166.0.5)**

### 3.1 Stop & Clean

```bash
sudo su - postgres
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data stop
rm -rf /pgdata/16/data/*
```

---

### 3.2 Base Backup

```bash
pg_basebackup -h 10.166.0.4 -D /pgdata/16/data -U repuser -P -R
```

Check:

```bash
ls /pgdata/16/data/standby.signal
cat /pgdata/16/data/postgresql.auto.conf
```

Should contain:

```ini
primary_conninfo = 'user=repuser password=StrongPass123 host=10.166.0.4 port=5432 sslmode=prefer'
```

---

### 3.3 Start Standby

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l /pgdata/16/logfile start
```

---

## **4. Verify Replication**

### 4.1 On Primary

```bash
psql -U postgres -d postgres -c "SELECT pid, usename, state, client_addr FROM pg_stat_replication;"
```

Should show `repuser` connected from `10.166.0.5` with `state = streaming`.

---

### 4.2 On Standby

```bash
psql -U postgres -d postgres -c "SELECT pg_is_in_recovery();"
```

Should return:

```
 t
```

---

## **5. Test Replication**

On Primary:

```bash
psql -U postgres -d postgres -c "CREATE DATABASE testdb;"
```

On Standby:

```bash
psql -U postgres -d postgres -c "\l"
```

You should see `testdb` replicated.

---

## **6. Failover (Optional)**

Promote standby:

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data promote
```

Check:

```bash
psql -U postgres -d postgres -c "SELECT pg_is_in_recovery();"
```

Should return:

```
 f
```

---

# ✅ Summary

* **Superuser** = `postgres`
* **Replication user** = `repuser`
* **Primary** (`vm01`) configured with WAL archiving & replication.
* **Standby** (`vm02`) synced via `pg_basebackup -R`.
* Verified replication & tested failover.

---

👉 Do you also want me to add the **systemd service override** so that both primary & standby auto-start PostgreSQL 16 as `postgres` on boot?
