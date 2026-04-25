--

### 🐘 pg_rewind — Real Scenario (Interview Question)

## 🧠 Situation

```text
Primary (A)  →  Standby (B)
```

Everything working fine.

---

## 🔥 Problem (Failover happened)

1. Primary A crashes ❌
2. You promote standby B:

```bash
pg_ctl promote -D /var/lib/postgresql/data
```

Now:

```text
B = NEW PRIMARY ✅
A = OLD PRIMARY (outdated ❌)
```

---

## ❗ Now issue

When A comes back:

👉 It has **old WAL history (timeline mismatch)**

```text
A timeline ≠ B timeline
```

👉 So it CANNOT join as standby ❌

---

# 🎯 Solution → pg_rewind

👉 We “rewind” A to match B

---

# 🧪 Step-by-Step (Real Flow)

---

## 🔹 Step 1: Stop OLD primary (A)

👉 On OLD PRIMARY (A):

```bash
pg_ctl stop -D /var/lib/postgresql/data
```

---

## 🔹 Step 2: Run pg_rewind

👉 On OLD PRIMARY (A):

```bash
pg_rewind \
  --target-pgdata=/var/lib/postgresql/data \
  --source-server="host=NEW_PRIMARY_B user=replicator password=replica123 dbname=postgres"
```

---

## 🧠 What pg_rewind does

👉 It:

* compares data between A and B
* copies only changed blocks
* fixes timeline

```text
Fast sync (minutes instead of hours)
```

---

## 🔹 Step 3: Convert A to standby

After rewind:

👉 Create standby mode:

```bash
touch /var/lib/postgresql/data/standby.signal
```

---

👉 Add connection (if not present):

```conf
primary_conninfo='host=NEW_PRIMARY_B user=replicator password=replica123'
```

---

## 🔹 Step 4: Start A

```bash
pg_ctl start -D /var/lib/postgresql/data
```

---

## 🔍 Step 5: Verify

👉 On new primary (B):

```sql
SELECT client_addr, state FROM pg_stat_replication;
```

👉 You should see A connected:

```text
state = streaming
```

---

# 🧠 Visual Understanding

```text
Before failover:
A (Primary) → B (Standby)

After failover:
B (Primary)
A (old, broken)

After pg_rewind:
B (Primary) → A (Standby again)
```

---

# 🔥 Why not base backup?

| Method        | Time              |
| ------------- | ----------------- |
| pg_basebackup | Hours (TB data) ❌ |
| pg_rewind     | Minutes ✅         |

---

# ⚠️ Requirements (very important)

pg_rewind works only if:

```conf
wal_log_hints = on
```

OR

```conf
data_checksums = on
```

---

# 🎯 Interview Answer (Perfect)

👉 *“pg_rewind is used after failover to resynchronize an old primary with the new primary by copying only changed data blocks instead of taking a full base backup.”*

---

# 💡 One-line memory trick

```text
Failover happened → timelines diverged → use pg_rewind
```

---

# 🔥 Bonus (real DBA tip)

👉 If pg_rewind fails:

* WAL missing
* or config not enabled

👉 Then only option:

```text
Full base backup (last option)
```

---

