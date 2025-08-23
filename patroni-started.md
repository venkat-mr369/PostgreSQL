Great—here’s a clean, copy-paste friendly **Patroni + etcd HA cluster** setup for **4 vms Oracle Linux 9 VMs**:

* **10.10.100.101 – oel9-vm1** → PostgreSQL + Patroni + etcd
* **10.10.100.102 – oel9-vm2** → PostgreSQL + Patroni + etcd
* **10.10.100.103 – oel9-vm3** → PostgreSQL + Patroni + etcd
* **10.10.100.104 – oel9-vm4** → HAProxy (VIP optional with Keepalived)

Patroni manages PostgreSQL HA and needs a **Distributed Configuration Store (DCS)**—we’ll use **etcd** (a supported DCS) and the Patroni REST API for health checks via HAProxy. ([GitHub][1], [Patroni][2])

---

## 1) System prep (run on **all 4 VMs**)

```bash
# Hostnames (run the matching line on each VM)
sudo hostnamectl set-hostname oel9-vm1   # on 101
sudo hostnamectl set-hostname oel9-vm2   # on 102
sudo hostnamectl set-hostname oel9-vm3   # on 103
sudo hostnamectl set-hostname oel9-vm4   # on 104

# Hosts file (same on all VMs)
sudo bash -c 'cat >/etc/hosts' <<'EOF'
127.0.0.1   localhost
10.10.100.101 oel9-vm1
10.10.100.102 oel9-vm2
10.10.100.103 oel9-vm3
10.10.100.104 oel9-vm4
EOF

# Updates + basic tools
sudo dnf -y update
sudo dnf -y install vim tmux wget curl jq git python3 python3-pip

# Firewalld (open only what you need or use your cloud/VPC firewalls)
# Patroni REST 8008, PostgreSQL 5432, etcd 2379/2380, HAProxy 5000
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --permanent --add-port=8008/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

---

## 2) Install PostgreSQL 16 + Patroni (on **101–103 only**)

Patroni can be installed via `pip`; we’ll use PGDG for Postgres 16. ([Patroni][2])

```bash
# PGDG repo
sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
# Disable module to avoid conflicts, then install
sudo dnf -y module disable postgresql
sudo dnf -y install postgresql16 postgresql16-server postgresql16-contrib

# Patroni with etcd support
sudo pip3 install --upgrade pip
sudo pip3 install "patroni[etcd]" psycopg2-binary

# Create postgres user dir structure
sudo mkdir -p /var/lib/pgsql/16/data /etc/patroni
sudo chown -R postgres:postgres /var/lib/pgsql /etc/patroni
```

> Do **not** run `initdb` yourself—Patroni will bootstrap the first primary and replicate others. ([Patroni][3])

---

## 3) Install and configure **etcd** quorum (on **101–103 only**)

Patroni needs a reliable DCS. We’ll run an etcd cluster across the 3 DB nodes. (3 members gives stable quorum.) ([Patroni][2])

```bash
# Install etcd
sudo dnf -y install etcd

# Create a per-node env file (run on each node with its own values)
# === on oel9-vm1 (101) ===
sudo bash -c 'cat >/etc/etcd/etcd.conf' <<'EOF'
ETCD_NAME="oel9-vm1"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.10.100.101:2380"
ETCD_LISTEN_PEER_URLS="http://10.10.100.101:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.10.100.101:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.10.100.101:2379"
ETCD_INITIAL_CLUSTER="oel9-vm1=http://10.10.100.101:2380,oel9-vm2=http://10.10.100.102:2380,oel9-vm3=http://10.10.100.103:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-etcd-cluster"
EOF

# === on oel9-vm2 (102) ===
sudo bash -c 'cat >/etc/etcd/etcd.conf' <<'EOF'
ETCD_NAME="oel9-vm2"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.10.100.102:2380"
ETCD_LISTEN_PEER_URLS="http://10.10.100.102:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.10.100.102:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.10.100.102:2379"
ETCD_INITIAL_CLUSTER="oel9-vm1=http://10.10.100.101:2380,oel9-vm2=http://10.10.100.102:2380,oel9-vm3=http://10.10.100.103:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-etcd-cluster"
EOF

# === on oel9-vm3 (103) ===
sudo bash -c 'cat >/etc/etcd/etcd.conf' <<'EOF'
ETCD_NAME="oel9-vm3"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.10.100.103:2380"
ETCD_LISTEN_PEER_URLS="http://10.10.100.103:2380"
ETCD_LISTEN_CLIENT_URLS="http://10.10.100.103:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://10.10.100.103:2379"
ETCD_INITIAL_CLUSTER="oel9-vm1=http://10.10.100.101:2380,oel9-vm2=http://10.10.100.102:2380,oel9-vm3=http://10.10.100.103:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-etcd-cluster"
EOF

# Start the cluster (do this on 101, then 102, then 103)
sudo systemctl enable --now etcd
# Health check (on any etcd node)
etcdctl --endpoints="http://10.10.100.101:2379,http://10.10.100.102:2379,http://10.10.100.103:2379" endpoint health
```

---

## 4) Patroni configuration (on **101–103**)

Create a **node-specific** `/etc/patroni/patroni.yml` on each DB node. Patroni will handle `initdb`, replication users, and failover. ([Patroni][3])

> Replace `scope: pg-ha` with your cluster name if you like. REST API listens on 8008.

### oel9-vm1 (10.10.100.101)

```bash
sudo bash -c 'cat >/etc/patroni/patroni.yml' <<'EOF'
scope: pg-ha
name: oel9-vm1

restapi:
  listen: 10.10.100.101:8008
  connect_address: 10.10.100.101:8008

etcd:
  hosts: 10.10.100.101:2379,10.10.100.102:2379,10.10.100.103:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_wal_senders: 10
        max_replication_slots: 10
        wal_keep_size: 512MB
  initdb:
  - encoding: UTF8
  - data-checksums
  - locale: en_US.UTF-8
  users:
    replicator:
      password: repl_pass
      options:
      - replication
    admin:
      password: admin_pass
      options:
      - createrole
      - createdb

postgresql:
  listen: 10.10.100.101:5432
  connect_address: 10.10.100.101:5432
  data_dir: /var/lib/pgsql/16/data
  bin_dir: /usr/pgsql-16/bin
  authentication:
    superuser:
      username: postgres
    replication:
      username: replicator
      password: repl_pass
  parameters:
    shared_buffers: "1GB"
    maintenance_work_mem: "256MB"
    effective_cache_size: "3GB"
tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
EOF
sudo chown postgres:postgres /etc/patroni/patroni.yml
```

### oel9-vm2 (10.10.100.102) — change `name`, IPs

```bash
sudo bash -c 'cat >/etc/patroni/patroni.yml' <<'EOF'
scope: pg-ha
name: oel9-vm2

restapi:
  listen: 10.10.100.102:8008
  connect_address: 10.10.100.102:8008

etcd:
  hosts: 10.10.100.101:2379,10.10.100.102:2379,10.10.100.103:2379

postgresql:
  listen: 10.10.100.102:5432
  connect_address: 10.10.100.102:5432
  data_dir: /var/lib/pgsql/16/data
  bin_dir: /usr/pgsql-16/bin
  authentication:
    superuser:
      username: postgres
    replication:
      username: replicator
      password: repl_pass
  parameters:
    shared_buffers: "1GB"
    maintenance_work_mem: "256MB"
    effective_cache_size: "3GB"
EOF
sudo chown postgres:postgres /etc/patroni/patroni.yml
```

### oel9-vm3 (10.10.100.103)

```bash
sudo bash -c 'cat >/etc/patroni/patroni.yml' <<'EOF'
scope: pg-ha
name: oel9-vm3

restapi:
  listen: 10.10.100.103:8008
  connect_address: 10.10.100.103:8008

etcd:
  hosts: 10.10.100.101:2379,10.10.100.102:2379,10.10.100.103:2379

postgresql:
  listen: 10.10.100.103:5432
  connect_address: 10.10.100.103:5432
  data_dir: /var/lib/pgsql/16/data
  bin_dir: /usr/pgsql-16/bin
  authentication:
    superuser:
      username: postgres
    replication:
      username: replicator
      password: repl_pass
  parameters:
    shared_buffers: "1GB"
    maintenance_work_mem: "256MB"
    effective_cache_size: "3GB"
EOF
sudo chown postgres:postgres /etc/patroni/patroni.yml
```

---

## 5) Systemd unit for Patroni (on **101–103**)

```bash
sudo bash -c 'cat >/etc/systemd/system/patroni.service' <<'EOF'
[Unit]
Description=Patroni PostgreSQL HA
After=network-online.target
Wants=network-online.target

[Service]
User=postgres
Group=postgres
Type=simple
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
Restart=on-failure
LimitNOFILE=102400

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable patroni
```

---

## 6) Bootstrap the cluster (on **101–103**)

Start Patroni on the first node; it will **initdb** and become **primary**. Start others to join as replicas. ([Patroni][3])

```bash
# On oel9-vm1 (101)
sudo systemctl start patroni
# Wait ~10–20s, check logs: journalctl -u patroni -f

# On oel9-vm2 (102) & oel9-vm3 (103)
sudo systemctl start patroni
```

Check cluster state:

```bash
# Install patroni CLI helper on any admin box (or each node)
sudo pip3 install patroni

# From any DB node:
patronictl -c /etc/patroni/patroni.yml list
# You should see one "Leader" and two "Replica"
```

---

## 7) HAProxy on **oel9-vm4 (10.10.100.104)**

We’ll point clients to HAProxy (port 5000). HAProxy will health-check Patroni’s REST API **/primary** and send writes to the current primary. (Older checks used `/master`; Patroni REST exposes role endpoints.) ([Patroni][3])

```bash
sudo dnf -y install haproxy
sudo bash -c 'cat >/etc/haproxy/haproxy.cfg' <<'EOF'
global
    daemon
    maxconn 2048
defaults
    mode tcp
    timeout client  30s
    timeout server  30s
    timeout connect 5s

# Writes/read-write traffic to current primary
frontend pg_rw
    bind *:5000
    default_backend patroni_primary

backend patroni_primary
    option httpchk GET /primary
    http-check expect status 200
    default-server inter 2s fall 3 rise 2 on-marked-down shutdown-sessions
    server oel9-vm1 10.10.100.101:5432 check port 8008
    server oel9-vm2 10.10.100.102:5432 check port 8008
    server oel9-vm3 10.10.100.103:5432 check port 8008

# (Optional) separate read-only LB using /replica to pick standbys
# Add another frontend/backend if you want a RO port, e.g., 5001.
EOF

sudo systemctl enable --now haproxy
```

> Optional: add **Keepalived** to float a VIP in front of HAProxy if you plan multiple HAProxy nodes.

---

## 8) Test

```bash
# From any client/VM with psql installed
psql "host=10.10.100.104 port=5000 user=postgres dbname=postgres"

# See who is primary
SELECT pg_is_in_recovery();  -- false on primary

# Patroni view
patronictl -c /etc/patroni/patroni.yml list
```

**Failover test** (simulate primary crash):

```bash
# On current Leader (shown by patronictl list):
sudo systemctl stop patroni

# Within seconds, cluster elects a new Leader (quorum via etcd).
patronictl -c /etc/patroni/patroni.yml list
```

**Controlled switchover**:

```bash
patronictl -c /etc/patroni/patroni.yml switchover
```

Patroni configuration/operations, REST API, and DCS behavior are documented in the official docs; HAProxy health checks commonly target the Patroni REST role endpoints. ([Patroni][3])

---

## Notes & good practices

* Use **3 etcd members** (not 2/4) for stable quorum; put them on the DB nodes. ([Patroni][2])
* Don’t start PostgreSQL directly—**Patroni** starts/stops it and writes configs. ([Patroni][3])
* For production, secure the Patroni REST API and etcd with TLS and auth; open only necessary ports. ([Patroni][3])

---

## (Optional) tie-in with the repo you shared
---

