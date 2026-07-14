Great. **Part 4** is one of the most important sections because **Patroni uses etcd as its Distributed Configuration Store (DCS)** for leader election, cluster state, and failover decisions.

> **Note:** The exact etcd configuration file path varies by Ubuntu package (`/etc/default/etcd`, `/etc/etcd/etcd.conf.yml`, or a systemd unit). We'll use the modern **`/etc/etcd/etcd.conf.yml`** approach. If your package uses a different path, we'll adjust it during verification.

---

# Part 4 – Configure the 3-Node etcd Cluster

## Cluster Information

| Node  | Hostname | IP         |
| ----- | -------- | ---------- |
| Node1 | pg1      | 10.10.1.11 |
| Node2 | pg2      | 10.10.1.12 |
| Node3 | pg3      | 10.10.1.13 |

Cluster Name:

```text
patroni-etcd
```

---

# Step 1 – Stop etcd

Run on **all nodes**:

```bash
sudo systemctl stop etcd
```

---

# Step 2 – Create Configuration Directory

```bash
sudo mkdir -p /etc/etcd
```

---

# Step 3 – Backup Existing Configuration

```bash
sudo cp /etc/etcd/etcd.conf.yml \
/etc/etcd/etcd.conf.yml.bak 2>/dev/null
```

---

# Step 4 – Configure pg1

On **pg1**:

```bash
sudo vi /etc/etcd/etcd.conf.yml
```

Paste:

```yaml
name: pg1

data-dir: /var/lib/etcd

initial-advertise-peer-urls: http://10.10.1.11:2380

listen-peer-urls: http://10.10.1.11:2380

listen-client-urls: http://10.10.1.11:2379,http://127.0.0.1:2379

advertise-client-urls: http://10.10.1.11:2379

initial-cluster-token: patroni-etcd

initial-cluster: pg1=http://10.10.1.11:2380,pg2=http://10.10.1.12:2380,pg3=http://10.10.1.13:2380

initial-cluster-state: new
```

Save and exit.

---

# Step 5 – Configure pg2

```bash
sudo vi /etc/etcd/etcd.conf.yml
```

```yaml
name: pg2

data-dir: /var/lib/etcd

initial-advertise-peer-urls: http://10.10.1.12:2380

listen-peer-urls: http://10.10.1.12:2380

listen-client-urls: http://10.10.1.12:2379,http://127.0.0.1:2379

advertise-client-urls: http://10.10.1.12:2379

initial-cluster-token: patroni-etcd

initial-cluster: pg1=http://10.10.1.11:2380,pg2=http://10.10.1.12:2380,pg3=http://10.10.1.13:2380

initial-cluster-state: new
```

---

# Step 6 – Configure pg3

```bash
sudo vi /etc/etcd/etcd.conf.yml
```

```yaml
name: pg3

data-dir: /var/lib/etcd

initial-advertise-peer-urls: http://10.10.1.13:2380

listen-peer-urls: http://10.10.1.13:2380

listen-client-urls: http://10.10.1.13:2379,http://127.0.0.1:2379

advertise-client-urls: http://10.10.1.13:2379

initial-cluster-token: patroni-etcd

initial-cluster: pg1=http://10.10.1.11:2380,pg2=http://10.10.1.12:2380,pg3=http://10.10.1.13:2380

initial-cluster-state: new
```

---

# Step 7 – Enable etcd

Run on all nodes:

```bash
sudo systemctl daemon-reload
```

```bash
sudo systemctl enable etcd
```

---

# Step 8 – Start etcd

Start **pg1** first:

```bash
sudo systemctl start etcd
```

Then **pg2**:

```bash
sudo systemctl start etcd
```

Then **pg3**:

```bash
sudo systemctl start etcd
```

---

# Step 9 – Verify Service

```bash
sudo systemctl status etcd
```

Expected:

```text
active (running)
```

---

# Step 10 – Verify Listening Ports

```bash
ss -tulnp | grep etcd
```

Expected:

```text
2379

2380
```

---

# Step 11 – Install etcdctl (if not already available)

```bash
sudo apt install etcd-client -y
```

---

# Step 12 – Verify Cluster Health

Run from **pg1**:

```bash
export ETCDCTL_API=3
```

```bash
etcdctl \
--endpoints=http://10.10.1.11:2379,http://10.10.1.12:2379,http://10.10.1.13:2379 \
endpoint health
```

Expected:

```text
10.10.1.11 healthy

10.10.1.12 healthy

10.10.1.13 healthy
```

---

# Step 13 – View Cluster Members

```bash
etcdctl \
--endpoints=http://10.10.1.11:2379 \
member list
```

Expected:

```text
pg1

pg2

pg3
```

---

# Step 14 – Check Endpoint Status

```bash
etcdctl \
--endpoints=http://10.10.1.11:2379,http://10.10.1.12:2379,http://10.10.1.13:2379 \
endpoint status --write-out=table
```

---

# Step 15 – Test Key-Value Storage

```bash
etcdctl put test "Patroni Cluster"
```

Read it back:

```bash
etcdctl get test
```

Expected:

```text
test

Patroni Cluster
```

Delete it:

```bash
etcdctl del test
```

---

# Step 16 – Verify Logs

```bash
sudo journalctl -u etcd -f
```

You should see peer connections and heartbeat messages without errors.

---

# Step 17 – Final Validation

Run:

```bash
systemctl status etcd
```

```bash
etcdctl endpoint health
```

```bash
etcdctl member list
```

### Expected Status

| Component          | Status       |
| ------------------ | ------------ |
| pg1                | etcd Running |
| pg2                | etcd Running |
| pg3                | etcd Running |
| Quorum             | Healthy      |
| Client Port (2379) | Reachable    |
| Peer Port (2380)   | Reachable    |

---

## Important Note

The **Ubuntu `etcd` package differs between releases**, and the configuration file location and systemd service can vary. For **Ubuntu 24.04**, I recommend **installing the official upstream etcd binary (v3.5.x)** instead of the distribution package. It is the approach most production Patroni deployments use and avoids packaging inconsistencies.

For the remainder of this Patroni lab, I'll use the **official upstream etcd installation**, so your environment matches current production best practices. That will make the Patroni configuration and troubleshooting much more consistent.
