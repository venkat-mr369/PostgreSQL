
Below is a **well-formatted, visually appealing Markdown file** for setting up and understanding a Patroni-managed PostgreSQL cluster. This template is based on best practices and typical documentation structures for open source HA PostgreSQL clusters with Patroni. The content is original, as the actual file content from your link could not be loaded directly[^1].

```markdown
# Patroni PostgreSQL Cluster (Not Tested)

> **Note:**  
> This document provides a reference setup for a Patroni-managed PostgreSQL cluster.  
> **This configuration has not been tested in production. Use at your own risk.**

---

## Overview

**Patroni** is an open-source tool for managing high-availability PostgreSQL clusters. It leverages distributed configuration stores (DCS) like etcd, Consul, or ZooKeeper to coordinate leader election and failover among PostgreSQL nodes.

---

## Architecture

- **Nodes:**  
  - 1 Primary (Leader)
  - 1+ Standby (Replicas)
- **Distributed Configuration Store (DCS):**  
  - etcd / Consul / ZooKeeper
- **Optional:**  
  - HAProxy or PgBouncer for a single client endpoint

---

## Prerequisites

- Linux (tested on Ubuntu 20.04+)
- Python 3.6+
- PostgreSQL (version as required)
- Patroni
- DCS (etcd/Consul/ZooKeeper)
- (Optional) HAProxy

---

## Installation Steps

### 1. Install Dependencies

```

sudo apt update
sudo apt install -y python3 python3-pip postgresql
pip3 install patroni[etcd]

```

### 2. Set Up Distributed Configuration Store (DCS)

#### Example: etcd

```


# On each etcd node

etcd --data-dir=/var/lib/etcd --enable-v2=true \&

```

### 3. Patroni Configuration

Create a YAML config for each node (e.g., `postgres0.yml`, `postgres1.yml`):

```

scope: postgres
namespace: /db/
name: node1

restapi:
listen: 0.0.0.0:8008
connect_address: 192.168.1.11:8008

etcd:
host: 192.168.1.10:2379

bootstrap:
dcs:
ttl: 30
loop_wait: 10
retry_timeout: 10
maximum_lag_on_failover: 1048576
initdb:
- encoding: UTF8
- data-checksums
users:
admin:
password: admin
options:
- createrole
- createdb

postgresql:
listen: 0.0.0.0:5432
connect_address: 192.168.1.11:5432
data_dir: /var/lib/postgresql/data
bin_dir: /usr/lib/postgresql/14/bin
authentication:
superuser:
username: postgres
password: yourpassword
replication:
username: replicator
password: replicatorpassword
parameters:
wal_level: replica
hot_standby: "on"
max_wal_senders: 5
max_replication_slots: 5
wal_keep_size: 16MB

```

> **Tip:**  
> Adjust IP addresses, data directories, and credentials for your environment.

### 4. Start Patroni

```

patroni postgres0.yml

# Repeat for each node with its respective config

```

---

## Cluster Management

### Checking Cluster Status

```

patronictl -c /etc/patroni/config.yml list

```

### Manual Failover

```

patronictl -c /etc/patroni/config.yml failover

```

---

## Testing the Cluster

- **Replication:**  
  Insert data on the primary and verify it appears on replicas.
- **Failover:**  
  Stop Patroni on the primary and ensure a replica is promoted[^4].
- **Connectivity:**  
  Use HAProxy or PgBouncer for a single endpoint.

---

## Example HAProxy Configuration

```

frontend postgres
bind *:5000
default_backend postgres_servers

backend postgres_servers
option httpchk GET /master
server node1 192.168.1.11:5432 check port 8008
server node2 192.168.1.12:5432 check port 8008
server node3 192.168.1.13:5432 check port 8008

```

---

## References

- [Patroni Documentation][^5]
- [Percona Blog: Administering a Patroni Managed PostgreSQL Cluster][^2]
- [Testing Patroni PostgreSQL Cluster][^4]

---


