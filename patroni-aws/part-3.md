### Part 3 – Install PostgreSQL 17, Patroni, and etcd (Run on pg1, pg2, and pg3)

> Execute all commands on **pg1**, **pg2**, and **pg3**.

---

### Step 1 – Update Packages

```bash
sudo apt update
sudo apt upgrade -y
```

---

### Step 2 – Install Required Packages

```bash
sudo apt install -y \
curl \
wget \
vim \
git \
jq \
net-tools \
python3 \
python3-pip \
python3-venv \
python3-psycopg2 \
gnupg \
ca-certificates
```

Verify:

```bash
python3 --version
pip3 --version
```

---

## Step 3 – Add PostgreSQL Repository

```bash
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
```

```bash
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
http://apt.postgresql.org/pub/repos/apt \
$(lsb_release -cs)-pgdg main" | \
sudo tee /etc/apt/sources.list.d/pgdg.list
```

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

---

## Step 5 – Stop PostgreSQL

Patroni manages PostgreSQL.

```bash
sudo systemctl stop postgresql
```

```bash
sudo systemctl disable postgresql
```

Verify:

```bash
systemctl status postgresql
```

---

### Step 6 – Download Official etcd

Move to `/tmp`:

```bash
cd /tmp
```

Download the latest stable release (replace the version if you want a newer 3.5.x release):

```bash
ETCD_VERSION=v3.5.16
```

```bash
wget https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
```

Extract:

```bash
tar -xzf etcd-${ETCD_VERSION}-linux-amd64.tar.gz
```

---

### Step 7 – Install etcd

```bash
cd etcd-${ETCD_VERSION}-linux-amd64
```

Copy binaries:

```bash
sudo cp etcd /usr/local/bin/
sudo cp etcdctl /usr/local/bin/
```

Verify:

```bash
etcd --version
```

```bash
etcdctl version
```

---

### Step 8 – Create etcd Directories

```bash
sudo mkdir -p /etc/etcd
```

```bash
sudo mkdir -p /var/lib/etcd
```

---

### Step 9 – Create etcd User

```bash
sudo useradd --system --home /var/lib/etcd --shell /bin/false etcd
```

If it already exists:

```bash
id etcd
```

---

### Step 10 – Set Ownership

```bash
sudo chown -R etcd:etcd /etc/etcd
```

```bash
sudo chown -R etcd:etcd /var/lib/etcd
```

---

### Step 11 – Create Python Virtual Environment

```bash
sudo mkdir -p /opt/patroni
```

```bash
cd /opt/patroni
```

```bash
sudo python3 -m venv venv
```

Activate:

```bash
source /opt/patroni/venv/bin/activate
```

---

### Step 12 – Install Patroni

```bash
pip install --upgrade pip
```

```bash
pip install patroni[etcd] psycopg[binary]
```

Verify:

```bash
patroni --version
```

Deactivate:

```bash
deactivate
```

---

### Step 13 – Create Patroni Directory

```bash
sudo mkdir -p /etc/patroni
```

---

## Step 14 – Create PostgreSQL Data Directory

```bash
sudo mkdir -p /data/postgresql
```

```bash
sudo chown postgres:postgres /data/postgresql
```

```bash
sudo chmod 700 /data/postgresql
```

---

## Step 15 – Verify PostgreSQL Binaries

```bash
which psql
```

```bash
find /usr/lib/postgresql -name postgres
```

Expected:

```text
/usr/lib/postgresql/17/bin/postgres
```

---

## Step 16 – Verify initdb

```bash
/usr/lib/postgresql/17/bin/initdb --version
```

---

## Step 17 – Verify pg_basebackup

```bash
/usr/lib/postgresql/17/bin/pg_basebackup --version
```

---

## Step 18 – Verify etcd

```bash
etcd --version
```

```bash
etcdctl version
```

---

## Step 19 – Verify Patroni

```bash
source /opt/patroni/venv/bin/activate
```

```bash
patroni --version
```

```bash
python -c "import patroni; print('Patroni Installed Successfully')"
```

```bash
deactivate
```

---

## Step 20 – Verify Nothing Is Running

```bash
ps -ef | grep postgres
```

```bash
ps -ef | grep etcd
```

Only the `grep` processes should appear.

---

## Final Validation

```bash
psql --version
```

```bash
etcd --version
```

```bash
etcdctl version
```

```bash
python3 --version
```

```bash
pip3 --version
```

---

## Expected Status

| Component                 | Status               |
| ------------------------- | -------------------- |
| PostgreSQL 17             | ✅ Installed, stopped |
| Patroni                   | ✅ Installed          |
| etcd                      | ✅ Installed          |
| etcdctl                   | ✅ Installed          |
| PostgreSQL Data Directory | ✅ Created            |
| Patroni Config Directory  | ✅ Created            |
| etcd Config Directory     | ✅ Created            |

---

### Recommendation

Here's a simpler version you can include in your guide:

> **Note:** For this lab, we will use the **official etcd binary downloaded from the etcd GitHub releases** instead of installing etcd from the Ubuntu package repository (`apt install etcd`). This ensures that everyone uses the same etcd version regardless of the Ubuntu release, making the installation and configuration consistent throughout the course. It also reflects how many production Patroni deployments are built, where administrators prefer the official etcd release for better compatibility and easier version management.

