Perfect 👍 You want a **detailed guide to set up PostgreSQL 16 Streaming Replication** on **Oracle Linux Server 9.5**, using two VMs:

* **Primary (vm01)** → `10.166.0.4`
* **Standby (vm02)** → `10.166.0.5`
* **OS User:** `venkat` (non-root, sudo access)
* **PostgreSQL Version:** 16
* **Replication Type:** Physical (Streaming Replication)

I’ll write this in **step-by-step format** (based on your GitHub installation reference but customized for Oracle Linux 9.5).

---

# 🚀 PostgreSQL 16 Streaming Replication on Oracle Linux 9.5

---

## **1. Pre-Requisites (On Both Servers vm01 & vm02)**

### 1.1 Update System

```bash
sudo dnf update -y
```

### 1.2 Install PostgreSQL 16 Repo & Packages

```bash

# 1. Install PGDG repo
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# 2. Disable the built-in PostgreSQL module
sudo dnf -qy module disable postgresql


# 3. Install PostgreSQL (example: version 17)
sudo dnf install -y postgresql16 postgresql16-server postgresql16-contrib

```

### 1.3 Create Database Directories (as user `venkat`)

```bash
sudo mkdir -p /pgdata/16/data
sudo mkdir -p /pgwal/16/wal
sudo chown -R venkat:venkat /pgdata/16 /pgwal/16
```

### 1.4 Initialize Cluster (Primary only, vm01)

```bash
/usr/pgsql-16/bin/initdb -D /pgdata/16/data
```
--output
```sh
[venkat@vm01 ~]$ /usr/pgsql-16/bin/initdb -D /pgdata/16/data
The files belonging to this database system will be owned by user "venkat".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

fixing permissions on existing directory /pgdata/16/data ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile start

```
---

## **2. Configure Primary (vm01: 10.166.0.4)**

### 2.1 Edit `postgresql.conf`

```bash
vi /pgdata/16/data/postgresql.conf
```

Set:

```ini
#-----------
#Replication Settings
#-----------

listen_addresses = '*'
wal_level = replica
archive_mode = on
archive_command = 'cp %p /pgwal/16/wal/%f'
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = 512MB
hot_standby = on
```

### 2.2 Edit `pg_hba.conf`

```bash
vi /pgdata/16/data/pg_hba.conf
```

Add (to allow replication from standby):

```ini
# Allow replication user from standby
host    replication     replicator     10.166.0.5/32     scram-sha-256
```

### 2.3 Start PostgreSQL

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile start
```

### 2.4 Create Replication User

Login as `postgres`:

[postgres@vm01 ~]$ /usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile start
waiting for server to start.... done
server started

psql -U postgres
```
```bash
sudo chown -R venkat:venkat /pgdata/16 /pgwal/16
```
```bash
[postgres@vm01 ~]$ /usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile start
waiting for server to start.... done
server started

[postgres@vm01 ~]$ /usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile status
pg_ctl: server is running (PID: 2257892)
/usr/pgsql-16/bin/postgres "-D" "/pgdata/16/data"
```

Run:

```sql
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'StrongPass123';
```

---

## **3. Configure Standby (vm02: 10.166.0.5)**

### 3.1 Stop PostgreSQL if running

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data stop
rm -rf /pgdata/16/data/*
```

### 3.2 Take Base Backup from Primary

```bash
pg_basebackup -h 10.166.0.4 -D /pgdata/16/data -U replicator -P -R
```

* `-R` automatically creates `standby.signal` and sets replication config.
* Enter password for `replicator` when prompted.

### 3.3 Verify Files

Check if these exist:

```bash
ls /pgdata/16/data/standby.signal
cat /pgdata/16/data/postgresql.auto.conf
```

You should see:

```ini
primary_conninfo = 'user=replicator password=StrongPass123 host=10.166.0.4 port=5432 sslmode=prefer sslcompression=0'
```

### 3.4 Start Standby

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data -l logfile start
```

---

## **4. Verify Streaming Replication**

### 4.1 On Primary (vm01)

```sql
psql -U postgres -c "SELECT * FROM pg_stat_replication;"
```

Output should show `10.166.0.5` connected with `state = streaming`.

### 4.2 On Standby (vm02)

```sql
psql -U postgres -c "SELECT pg_is_in_recovery();"
```

Should return:

```text
 t
```

---

## **5. Test Replication**

On Primary (vm01):

```sql
psql -U postgres -c "CREATE DATABASE testdb;"
```

On Standby (vm02):

```sql
psql -U postgres -c "\l"
```

You should see `testdb` replicated automatically.

---

## **6. Optional: Promote Standby (Failover Test)**

If primary goes down, promote standby:

```bash
/usr/pgsql-16/bin/pg_ctl -D /pgdata/16/data promote
```

Now `pg_is_in_recovery()` will return `f`.

---

# ✅ Summary

* **vm01 (10.166.0.4)** = Primary with WAL archiving.
* **vm02 (10.166.0.5)** = Standby via `pg_basebackup`.
* **Replication user** = `replicator`.
* Verified with `pg_stat_replication` and failover test.

---

👉 Do you want me to also prepare a **systemd service file setup** (so that PostgreSQL auto-starts with `venkat` user on boot for both primary & standby)?
