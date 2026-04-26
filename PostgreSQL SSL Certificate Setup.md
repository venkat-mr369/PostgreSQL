### 🔐 PostgreSQL SSL Certificate Setup (Node-wise Example) for Cluster like Patroni, Streaming or repmgr

### 🧠 Cluster Setup

Assume a 3-node cluster:

```
rep-primary
rep-standby1
rep-standby2
```

---

### 📦 Certificate Structure Overview

### Certificate Authority (CA)

```
ca.crt
ca.key   (keep this secure; do NOT copy to nodes)
```

👉 `ca.crt` must be present on **all nodes**
👉 `ca.key` should remain only with the administrator

---

### 🟢 Node 1: rep-primary

### Directory: `/etc/ssl/`

```
/etc/ssl/
 ├── ca.crt
 ├── server.crt   (CN=rep-primary)
 ├── server.key
 ├── client.crt   (CN=repmgr)
 ├── client.key
```

---

### 🟡 Node 2: rep-standby1

### Directory: `/etc/ssl/`

```
/etc/ssl/
 ├── ca.crt
 ├── server.crt   (CN=rep-standby1)  # unique per node
 ├── server.key
 ├── client.crt   (CN=repmgr)
 ├── client.key
```

---

### 🔵 Node 3: rep-standby2

### Directory: `/etc/ssl/`

```
/etc/ssl/
 ├── ca.crt
 ├── server.crt   (CN=rep-standby2)  # unique per node
 ├── server.key
 ├── client.crt   (CN=repmgr)
 ├── client.key
```

---

### ⚠️ Key Differences

| File         | Same / Different       |
| ------------ | ---------------------- |
| `ca.crt`     | ✅ Same (all nodes)     |
| `client.crt` | ✅ Same                 |
| `client.key` | ✅ Same                 |
| `server.crt` | ❌ Different (per node) |
| `server.key` | ❌ Different (per node) |

---

### 🔍 Certificate Generation (Per Node)

### 🟢 For rep-primary

```bash
openssl req -new -key server.key \
  -out server.csr \
  -subj "/CN=rep-primary"
```

---

### 🟡 For rep-standby1

```bash
openssl req -new -key server.key \
  -out server.csr \
  -subj "/CN=rep-standby1"
```

---

### 🔵 For rep-standby2

```bash
openssl req -new -key server.key \
  -out server.csr \
  -subj "/CN=rep-standby2"
```

---

### 🧪 repmgr Connection Configuration

Example **repmgr** config:

```ini
conninfo='host=rep-primary user=repmgr dbname=repmgr sslmode=verify-full sslcert=/etc/ssl/client.crt sslkey=/etc/ssl/client.key sslrootcert=/etc/ssl/ca.crt'
```

👉 Same configuration can be used across all nodes

---

# 🎯 Key Concept (Interview Ready)

> Each node must have its own unique server certificate with a Common Name (CN) matching its hostname, while the CA certificate and client certificates are shared across all nodes for mutual SSL authentication.

---

# 💡 Architecture Visualization

```
          CA (trusted by all nodes)
                 ↓
   -----------------------------------
   |              |                 |
Primary       Standby1         Standby2
 CN=primary    CN=standby1     CN=standby2
```

---

#### 🚀 Final Summary

* All nodes trust the same CA (`ca.crt`)
* All nodes use the same client certificate (for authentication)
* Each node has its own server certificate (identity)

---
