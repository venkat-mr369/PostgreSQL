Excellent. In **Part 3**, we'll install **PostgreSQL 17**, **Patroni**, and **etcd** on all three nodes. **Do not start PostgreSQL manually**—Patroni will manage it.

> Run the following commands on **pg1**, **pg2**, and **pg3**.

---

## Part 3 – Install PostgreSQL 17, etcd, and Patroni

### Step 1 – Add the PostgreSQL GPG Key

```bash
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
```

Verify:

```bash
ls -l /usr/share/keyrings/postgresql.gpg
```

---

### Step 2 – Add the PostgreSQL Repository

```bash
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
http://apt.postgresql.org/pub/repos/apt \
$(lsb_release -cs)-pgdg main" | \
sudo tee /etc/apt/sources.list.d/pgdg.list
```

---

### Step 3 – Update Package Index

```bash
sudo apt update
```

---

### Step 4 – Install PostgreSQL 17

```bash
sudo apt install -y \
postgresql-17 \
postgresql-client-17 \
postgresql-contrib-17
```

Verify:

```bash
psql --version
```

Expected:

```text
psql (PostgreSQL) 17.x
```

---

### Step 5 – Stop the PostgreSQL Service

```bash
sudo systemctl stop postgresql
```

Disable automatic startup:

```bash
sudo systemctl disable postgresql
```

Check:

```bash
systemctl status postgresql
```

Expected: **inactive (dead)**

---

### Step 6 – Install etcd

```bash
sudo apt install -y etcd
```

Verify:

```bash
etcd --version
```

---

### Step 7 – Stop etcd (Configuration comes in Part 4)

```bash
sudo systemctl stop etcd
```

```bash
sudo systemctl disable etcd
```

---

### Step 8 – Install Python and pip

```bash
sudo apt install -y python3 python3-pip python3-venv
```

Verify:

```bash
python3 --version
```

```bash
pip3 --version
```

---

### Step 9 – Install Patroni

```bash
sudo pip3 install patroni[etcd] psycopg[binary]
```

Verify:

```bash
patroni --version
```

---

### Step 10 – Create Patroni Configuration Directory

```bash
sudo mkdir -p /etc/patroni
```

---

### Step 11 – Create PostgreSQL Data Directory

```bash
sudo mkdir -p /data/postgresql
```

Change ownership:

```bash
sudo chown -R postgres:postgres /data/postgresql
```

Permissions:

```bash
sudo chmod 700 /data/postgresql
```

Verify:

```bash
ls -ld /data/postgresql
```

---

### Step 12 – Create PostgreSQL Runtime Directory

```bash
sudo mkdir -p /var/run/postgresql
```

```bash
sudo chown postgres:postgres /var/run/postgresql
```

---

### Step 13 – Verify PostgreSQL Binary Location

```bash
which postgres
```

If nothing is returned:

```bash
find /usr/lib/postgresql -name postgres
```

Typical output:

```text
/usr/lib/postgresql/17/bin/postgres
```

---

### Step 14 – Verify initdb

```bash
/usr/lib/postgresql/17/bin/initdb --version
```

---

### Step 15 – Verify pg_basebackup

```bash
/usr/lib/postgresql/17/bin/pg_basebackup --version
```

---

### Step 16 – Verify Patroni Installation

```bash
patroni --version
```

```bash
python3 -c "import patroni; print('Patroni Installed Successfully')"
```

---

### Step 17 – Verify etcd

```bash
etcd --version
```

---

### Step 18 – Check Installed Packages

```bash
dpkg -l | grep postgresql
```

```bash
dpkg -l | grep etcd
```

---

### Step 19 – Verify No PostgreSQL Is Running

```bash
ps -ef | grep postgres
```

Only the `grep` command should appear.

---

### Step 20 – Final Validation

```bash
psql --version
```

```bash
patroni --version
```

```bash
etcd --version
```

```bash
python3 --version
```

```bash
pip3 --version
```

### Expected Status After Part 3

| Component               | Status               |
| ----------------------- | -------------------- |
| PostgreSQL 17           | ✅ Installed, stopped |
| Patroni                 | ✅ Installed          |
| etcd                    | ✅ Installed, stopped |
| Data directory          | ✅ Created            |
| Configuration directory | ✅ Created            |

---

## Next: Part 4

In Part 4, we'll configure the **3-node etcd cluster**, including:

* `/etc/default/etcd` or `etcd.conf.yml` configuration
* Initial cluster configuration for `pg1`, `pg2`, and `pg3`
* Starting etcd on all nodes
* Verifying cluster health with `etcdctl`
* Troubleshooting etcd quorum issues

This is the foundation Patroni uses for leader election and failover.
