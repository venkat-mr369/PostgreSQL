setting up a **Highly Available PostgreSQL 17 Cluster with Patroni** on **Oracle Linux 9** (also applies for modern PostgreSQL on Oracle Linux 8/9)

## Overview: High Availability PostgreSQL Cluster with Patroni

**Components:**
- **PostgreSQL 17**: Highly robust, production-grade, open-source database.
- **Patroni**: Automates PostgreSQL HA, failover, and cluster state management.
- **etcd**: Distributed key-value store for cluster state and leader election.
- **PgBouncer**: Lightweight connection pooler.
- **HAProxy**: Traffic distribution/load balancing to primary/replica databases.
- **Keepalived**: Virtual IP for failover and load balancer redundancy.

## 1. **Virtual Machine and OS Preparation**

- **VM resources:** At least `4 vCPU`, `4GB RAM`, `50GB Disk`.
- **Networking:**  
  - Two NICs: one for VM-to-VM (host-only), one for internet/NAT.

**Time and Host Configuration:**
```bash
sudo timedatectl set-timezone Asia/Riyadh
```
**Set hostnames and `/etc/hosts` on all nodes** to ensure reliable node resolution.
```bash
192.168.56.231 pgsql01.localdomain pgsql01
192.168.56.232 pgsql02.localdomain pgsql02
192.168.56.233 pgsql03.localdomain pgsql03
```

**SELinux:**  
Best practice is to set to `permissive` or configure policies, but for easier lab setup:
```bash
sudo vi /etc/selinux/config
# Set: SELINUX=disabled
```

**Reboot if changed:**
```bash
sudo shutdown -r now
```

## 2. **Firewall Settings**

**Open required ports for PostgreSQL HA:**
```bash
sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent  # PostgreSQL
sudo firewall-cmd --zone=public --add-port=6432/tcp --permanent  # PgBouncer
sudo firewall-cmd --zone=public --add-port=8008/tcp --permanent  # Patroni REST
sudo firewall-cmd --zone=public --add-port=2379/tcp --permanent  # etcd client
sudo firewall-cmd --zone=public --add-port=2380/tcp --permanent  # etcd peer
sudo firewall-cmd --zone=public --add-port=5000/tcp --permanent  # HAProxy write
sudo firewall-cmd --zone=public --add-port=5001/tcp --permanent  # HAProxy read
sudo firewall-cmd --zone=public --add-port=7000/tcp --permanent  # HAProxy stats
sudo firewall-cmd --add-rich-rule='rule protocol value=\"vrrp\" accept' --permanent  # Keepalived
sudo firewall-cmd --reload
```

## 3. **Repository and Dependencies**

**Enable EPEL and utils:**
```bash
sudo dnf install -y epel-release yum-utils
```

## 4. **PostgreSQL 17 Installation**

Use the official repo for the latest release:
```bash
sudo dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -y module disable postgresql
sudo dnf -y install postgresql17-server postgresql17 postgresql17-devel
sudo ln -sf /usr/pgsql-17/bin/* /usr/sbin/
```
**Explanation:**  
- Disables base OS modules to avoid conflicts with the official latest PostgreSQL packages.

## 5. **Install and Configure etcd**

**Install (Use official or trusted third-party repo for EL9):**
```bash
sudo dnf makecache
sudo dnf install -y etcd
```
**Explanation:**  
etcd is a small distributed key-value store used for cluster state and leader election.

**Basic `/etc/etcd/etcd.conf` sample for pgsql01 (update IPs on other nodes):**
```conf
ETCD_NAME=pgsql01
ETCD_DATA_DIR="/var/lib/etcd/pgsql01"
ETCD_LISTEN_PEER_URLS="http://192.168.56.231:2380"
ETCD_LISTEN_CLIENT_URLS="http://192.168.56.231:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.56.231:2380"
ETCD_INITIAL_CLUSTER="pgsql01=http://192.168.56.231:2380,pgsql02=http://192.168.56.232:2380,pgsql03=http://192.168.56.233:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.56.231:2379"
```
**Repeat with the correct node name and IP on each server.**

**Start etcd and validate cluster health on all nodes:**
```bash
sudo systemctl enable --now etcd
etcdctl --write-out=table --endpoints=192.168.56.231:2379,192.168.56.232:2379,192.168.56.233:2379 member list
```
---

## 6. **Patroni and Dependencies**

**Install Python dependencies and Patroni:**
```bash
sudo dnf install -y python3 python3-devel python3-pip gcc libpq-devel
sudo pip3 install --upgrade pip setuptools psycopg2 python-etcd
sudo pip3 install patroni[etcd]
```
**Explanation:**  
Patroni is a Python tool that manages PostgreSQL replication, promotion, and HA failovers with etcd.

## 7. **PgBouncer Installation**

**Install:**
```bash
sudo dnf install -y pgbouncer
```
**Explanation:**  
PgBouncer helps scale and manage hundreds or thousands of concurrent client connections to PostgreSQL.

## 8. **HAProxy Installation**

**Install:**
```bash
sudo dnf install -y haproxy
```
**Explanation:**  
HAProxy provides failover and balances database connections to the cluster from applications.

## 9. **Keepalived Installation**

**Install:**
```bash
sudo dnf install -y keepalived
```
**Explanation:**  
Keepalived provides floating virtual IP for load balancer failover, ensuring a single endpoint is always active.

## 10. **Configure Patroni**

Each node (adapt IPs/names as appropriate):
```yaml
# Example: /etc/patroni/patroni.yml for pgsql01
scope: pg_cluster
name: pgsql01
restapi:
  listen: 192.168.56.231:8008
  connect_address: 192.168.56.231:8008
etcd:
  hosts: 192.168.56.231:2379,192.168.56.232:2379,192.168.56.233:2379
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
  initdb:
    - encoding: UTF8
    - data-checksums
  pg_hba:
    - host replication replicator 0.0.0.0/0 md5
    - host all all 0.0.0.0/0 md5
  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb
postgresql:
  listen: 192.168.56.231:5432
  connect_address: 192.168.56.231:5432
  data_dir: /var/lib/pgsql/17/data
  bin_dir: /usr/pgsql-17/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: replicator
    superuser:
      username: postgres
      password: postgres
tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
```
**Repeat for each host with the right IPs and names.**

## 11. **Watchdog Setup (Extra Safety)**
- Load the kernel module and configure `/etc/watchdog.conf`.
- Ensure `/dev/watchdog` exists and is accessible to Patroni.

## 12. **Configure and Start Services**

- Enable all relevant services:
  ```bash
  sudo systemctl enable --now etcd patroni pgbouncer haproxy keepalived
  ```

## 13. **Testing the Cluster**

- Connect via the floating virtual IP (served by keepalived and HAProxy):
  ```bash
  psql -h 192.168.56.200 -p 5000 -U postgres
  ```
  - You should reach the current primary node.

- For HAProxy read tests (replica/standby nodes):
  ```bash
  psql -h 192.168.56.200 -p 5001 -U postgres -t -c "select inet_server_addr()"
  ```

- Test failover by stopping Patroni/HAProxy/Keepalived on master; floating IP and database role should migrate with services.

## 14. **Patroni Cluster Management**

- Use `patronictl` for manual operations and troubleshooting:
  ```bash
  patronictl -c /etc/patroni/patroni.yml list
  patronictl -c /etc/patroni/patroni.yml failover
  patronictl -c /etc/patroni/patroni.yml switchover
  patronictl -c /etc/patroni/patroni.yml pause         # disables auto-failover
  ```

## Explanations and Best Practices

- **Each component** is modular and can be upgraded independently.
- **Patroni + etcd** ensures only one active leader, with automatic and manual failover.
- **PgBouncer** prevents client overload by pooling backend connections.
- **HAProxy + Keepalived** provides unified, failover-safe entry points for apps—virtual IP always directs traffic to the current "master."
- **Oracle Linux 9** brings better security, performance, and up-to-date package versions versus OL8.

**Summary Table: Core Components**

| Component   | Purpose                               |
|-------------|---------------------------------------|
| PostgreSQL  | Database                              |
| Patroni     | HA orchestration/failover             |
| etcd        | Distributed state for cluster control |
| PgBouncer   | Connection pooling                    |
| HAProxy     | Load balancing traffic                |
| Keepalived  | Provides a floating VIP               |

