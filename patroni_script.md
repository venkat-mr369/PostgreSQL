Absolutely! Here’s a set of **four shell scripts**—one for each VM—that automate the entire setup. Each script includes comments to explain what it’s doing. You can **run them as `root` or via sudo**.

---

### 1. `setup-common.sh`

(Common tasks run on **all four VMs**)

```bash
#!/bin/bash
# --------------------------------------------------------
# Common setup for all nodes (oel9-vm1 through vm4)
# - Sets hostname, hosts file, installs common packages,
#   opens firewall ports.
# --------------------------------------------------------

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Auto-detect IP and hostname from parameters
MYNAME="$1"
MYPIP="$2"
if [[ -z "$MYNAME" || -z "$MYPIP" ]]; then
  echo "Usage: $0 <hostname> <my_ip>"
  exit 1
fi

echo "Setting hostname to $MYNAME"
hostnamectl set-hostname "$MYNAME"

# /etc/hosts with all four nodes
cat > /etc/hosts <<EOF
127.0.0.1   localhost
10.10.100.101 oel9-vm1
10.10.100.102 oel9-vm2
10.10.100.103 oel9-vm3
10.10.100.104 oel9-vm4
EOF

echo "Installing base packages"
dnf -y update
dnf -y install vim tmux wget curl jq git python3 python3-pip firewalld

echo "Configuring firewall"
firewall-cmd --permanent --add-port=5432/tcp  # PostgreSQL default
firewall-cmd --permanent --add-port=8008/tcp  # Patroni REST API
firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd
firewall-cmd --permanent --add-port=5000/tcp  # HAProxy
firewall-cmd --reload

echo "Common setup complete on $MYNAME ($MYPIP)"
```

**Copy this file to /scripts folder and execute like below on every VM**:

```bash
# On oel9-vm1 (101)
sudo bash setup-common.sh oel9-vm1 10.10.100.101

# On oel9-vm2 (102)
sudo bash setup-common.sh oel9-vm2 10.10.100.102

# On oel9-vm3 (103)
sudo bash setup-common.sh oel9-vm3 10.10.100.103

# On oel9-vm4 (104)
sudo bash setup-common.sh oel9-vm4 10.10.100.104
```

---

### 2. `setup-etcd-patroni.sh`

(Run on **oel9-vm1**, **oel9-vm2**, **oel9-vm3** — the DB nodes)

```bash
#!/bin/bash
# --------------------------------------------------------
# Sets up etcd and Patroni + PostgreSQL on a DB node
# --------------------------------------------------------

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

NODE_NAME="$1"
MY_IP="$2"
ETCD_NODES="$3"  # e.g. "10.10.100.101,10.10.100.102,10.10.100.103"

if [[ -z "$NODE_NAME" || -z "$MY_IP" || -z "$ETCD_NODES" ]]; then
  echo "Usage: $0 <node_name> <my_ip> <etcd_nodes_comma>"
  exit 1
fi

echo "Installing PostgreSQL 16"
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -y module disable postgresql
dnf -y install postgresql16 postgresql16-server postgresql16-contrib

echo "Installing Patroni with etcd support"
pip3 install --upgrade pip
pip3 install "patroni[etcd]" psycopg2-binary

mkdir -p /var/lib/pgsql/16/data /etc/patroni
chown -R postgres:postgres /var/lib/pgsql /etc/patroni

echo "Installing etcd"
dnf -y install etcd

# Create etcd configuration
cat > /etc/etcd/etcd.conf <<EOF
ETCD_NAME="$NODE_NAME"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$MY_IP:2380"
ETCD_LISTEN_PEER_URLS="http://$MY_IP:2380"
ETCD_LISTEN_CLIENT_URLS="http://$MY_IP:2379,http://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://$MY_IP:2379"
ETCD_INITIAL_CLUSTER=""
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-etcd-cluster"
EOF

# Build initial cluster list
IFS=',' read -ra IPS <<< "$ETCD_NODES"
for ip in "${IPS[@]}"; do
  name="oel9-vm${ip##*.}"
  url="http://$ip:2380"
  if [[ -z "$CLUSTERLIST" ]]; then
    CLUSTERLIST="$name=$url"
  else
    CLUSTERLIST="$CLUSTERLIST,$name=$url"
  fi
done
sed -i "s|ETCD_INITIAL_CLUSTER=\"\"|ETCD_INITIAL_CLUSTER=\"$CLUSTERLIST\"|" /etc/etcd/etcd.conf

echo "Starting etcd service"
systemctl enable --now etcd

echo "Configuring Patroni"
cat > /etc/patroni/patroni.yml <<EOF
scope: pg-ha
name: $NODE_NAME

restapi:
  listen: $MY_IP:8008
  connect_address: $MY_IP:8008

etcd:
  hosts: ${ETCD_NODES//,/:2379,}:2379

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
  listen: $MY_IP:5432
  connect_address: $MY_IP:5432
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

chown postgres:postgres /etc/patroni/patroni.yml

echo "Creating systemd unit for Patroni"
cat > /etc/systemd/system/patroni.service <<EOF
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

systemctl daemon-reload
systemctl enable patroni

echo "etcd + Patroni setup complete on $NODE_NAME"
```

**Usage on DB nodes**:

```bash
# On oel9-vm1
sudo bash setup-etcd-patroni.sh oel9-vm1 10.10.100.101 10.10.100.101,10.10.100.102,10.10.100.103

# On oel9-vm2
sudo bash setup-etcd-patroni.sh oel9-vm2 10.10.100.102 10.10.100.101,10.10.100.102,10.10.100.103

# On oel9-vm3
sudo bash setup-etcd-patroni.sh oel9-vm3 10.10.100.103 10.10.100.101,10.10.100.102,10.10.100.103
```

Later, you can start Patroni:

```bash
sudo systemctl start patroni   # First on vm1, then vm2 & vm3
patronictl -c /etc/patroni/patroni.yml list
```

---

### 3. `setup-haproxy.sh`

(On **oel9-vm4**, the HAProxy frontend)

```bash
#!/bin/bash
# --------------------------------------------------------
# Sets up HAProxy to route traffic to Patroni primary
# --------------------------------------------------------

set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root"
  exit 1
fi

echo "Installing HAProxy"
dnf -y install haproxy

echo "Configuring HAProxy"
cat > /etc/haproxy/haproxy.cfg <<EOF
global
    daemon
    maxconn 2048
defaults
    mode tcp
    timeout client  30s
    timeout server  30s
    timeout connect 5s

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
EOF

echo "Enabling & starting HAProxy"
systemctl enable --now haproxy

echo "HAProxy setup complete"
```

**Usage on oel9-vm4**:

```bash
sudo bash setup-haproxy.sh
```

---

### 4. `bootstrap-patroni.sh`

(Run manually after all nodes are up to bootstrap and join the cluster)

```bash
#!/bin/bash
# --------------------------------------------------------
# Bootstrap Patroni cluster
# - Run on oel9-vm1 first, then the others.
# --------------------------------------------------------

echo "Starting Patroni on first node (should init primary)"
sudo systemctl start patroni
sleep 10
journalctl -u patroni --no-pager -n 50  # Quick log peek

echo "Now start Patroni on the remaining db nodes (vm2, vm3)"
echo "On each: sudo systemctl start patroni"
echo "Then check cluster status using:"
echo "  patronictl -c /etc/patroni/patroni.yml list"
```

---

## To summarize the flow:

1. Run `setup-common.sh` on **all 4 VMs**.
2. Run `setup-etcd-patroni.sh` **only on vm1, vm2, vm3**.
3. Run `setup-haproxy.sh` on **vm4**.
4. Run `bootstrap-patroni.sh` on **vm1**, then manually start Patroni on vm2 and vm3.
5. Test via `patronictl list` and connect through HAProxy on `10.10.100.104:5000`.

Let me know if you’d like these bundled as a single master script or endured via Ansible Playbook!
