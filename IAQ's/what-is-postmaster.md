***“What is postmaster and what does it do?”***

---

### 🔑 What is Postmaster?

* The **postmaster** is the **main PostgreSQL server process** (also called the **parent** or **master daemon**).
* When you start PostgreSQL (`pg_ctl start` or `systemctl start postgresql`), the **postmaster process is launched first**.
* Its job is to **initialize, listen for connections, and manage child processes**.

---

### 🔎 What does Postmaster do?

1. **Initialization**

   * Reads `postgresql.conf`, `pg_hba.conf`.
   * Sets up shared memory + semaphores.
   * Starts essential background processes (checkpointer, wal writer, background writer, autovacuum, stats collector, etc.).

2. **Connection Handling**

   * Listens on TCP/IP (`5432`) and Unix socket.
   * For every new client connection, it **forks a new backend process** (`postgres` process) to handle that session.

👉 Example:

* You connect with `psql -U postgres`.
* Postmaster accepts the connection.
* It forks a **backend process** to serve your session.

3. **Process Supervision**

   * Monitors child processes (backends, background workers).
   * Restarts critical background processes if they crash.
   * Logs errors.

4. **Crash Recovery**

   * If a backend crashes, postmaster detects it.
   * Restarts database and applies WAL recovery if needed.

---

### 🔎 Example with Employees Table

* **You connect:**

  ```bash
  psql -U postgres -d mydb
  ```

  → Postmaster accepts connection, forks a backend.

* **You run query:**

  ```sql
  SELECT * FROM employees WHERE salary > 20000;
  ```

  → Backend process executes the query (not postmaster itself).

* **You disconnect:**
  → Backend exits, postmaster continues listening for new clients.

---

### 📊 Key Difference: Postmaster vs Postgres Processes

| Component                | Role                                                                                                 |
| ------------------------ | ---------------------------------------------------------------------------------------------------- |
| **Postmaster**           | Parent process → starts PostgreSQL, spawns children, manages resources, listens for new connections. |
| **Backend (postgres)**   | Child process → serves a specific client session.                                                    |
| **Background processes** | (checkpointer, WAL writer, autovacuum, etc.) → handle system-level tasks.                            |

---

### 🧠 Interview-Ready Answer

> “The postmaster is the main PostgreSQL server process. It starts when the database is launched, reads configs, initializes shared memory, and spawns background processes. It listens for client connections on port 5432, and for each connection it forks a backend process to handle that session. Postmaster also supervises child processes and restarts them if they crash. In short, it is the parent process that keeps PostgreSQL alive and orchestrates everything.”

---
 **PostgreSQL process tree diagram** showing the **Postmaster, background processes, and backend processes**.

---

#### 🌳 PostgreSQL Process Tree

```
(postmaster)  ── Main PostgreSQL Server Process
     │
     ├── checkpointer        (flushes dirty pages at checkpoints)
     ├── background writer   (writes dirty pages gradually to avoid spikes{Oracle -DBWriter})
     ├── wal writer          (flushes WAL records to disk)
     ├── autovacuum launcher (spawns workers to vacuum tables)
     ├── stats collector     (collects statistics for planner)
     ├── archiver            (archives WAL segments if archive_mode=on)
     ├── logical replication launcher (for publications/subscriptions)
     │
     ├── (postgres backend 1) ─ handles Client Connection #1
     ├── (postgres backend 2) ─ handles Client Connection #2
     └── (postgres backend N) ─ handles Client Connection #N
```
Here is a comparison of major PostgreSQL background processes and their counterparts in Oracle Database. Both systems use specialized background tasks to guarantee performance, durability, maintenance, and scalability, but names and internals differ slightly.

### PostgreSQL vs. Oracle Background Processes

| PostgreSQL Process             | Purpose/Function                                           | Oracle Counterpart & Description                        |
|-------------------------------|-----------------------------------------------------------|---------------------------------------------------------|
| **Checkpointer**              | Flushes dirty pages at checkpoints to disk.| **CKPT (Checkpoint Process):** Signals DB Writer to flush buffers; records synchronization marks in control/datafiles.|
| **Background Writer**         | Gradually writes dirty pages to disk between checkpoints; reduces checkpoint spikes[5][1].| **DBWR (Database Writer):** Writes dirty blocks from buffer cache to disk; aims to avoid I/O spikes and respond to buffer needs.|
| **WAL Writer**                | Flushes WAL changes to the disk for durability and crash recovery.| **LGWR (Log Writer):** Writes redo log buffer to online redo logs to guarantee transaction durability.|
| **Autovacuum Launcher**       | Spawns autovacuum workers to remove dead tuples, freeing space and updating stats[10].| **SMON (System Monitor):** Performs instance recovery, cleans temporary segments, and space management.|
| **Stats Collector**           | Collects table and query statistics for query planner optimization.| **AWR (Automatic Workload Repository)/Statistical Views:** Oracle collects stats via various views, mainly using AWR snapshots, V$ views, and the optimizer’s own statistics.|
| **Archiver**                  | Archives WAL segments when archive_mode is enabled; ensures disaster recovery.| **ARCH (Archiver Process):** Copies filled redo logs to archive destinations for backup and recoverability.|
| **Logical Replication Launcher** | Manages publications and subscriptions for logical replication changes.| **Streams/APPLY/PROPAGATE:** Oracle has Streams (and newer options like GoldenGate) for logical replication, managing publications and subscriptions of changes across databases.|

---

| PostgreSQL Process                | Description                                          | Oracle Counterpart         | Oracle Description                                        |
|-----------------------------------|------------------------------------------------------|----------------------------|-----------------------------------------------------------|
| Checkpointer                      | Flushes dirty pages at checkpoints, syncs WAL/data   | CKPT (Checkpoint)          | Updates data file headers; signals DBWR for disk writes   |
| Background Writer                 | Gradually writes dirty pages, avoids I/O spikes      | DBWR (Database Writer)     | Periodically writes dirty buffers to disk                 |
| WAL Writer                        | Flushes WAL records for durability/recovery          | LGWR (Log Writer)          | Writes redo log buffers to disk for crash recovery        |
| Autovacuum Launcher               | Launches workers to vacuum tables & reclaim space    | SMON (System Monitor)      | Runs instance recovery, cleans temp/persisted segments    |
| Stats Collector                   | Collects planner statistics                          | AWR/Stats Gathering        | Database gathers statistics for optimizer via AWR/snapshots|
| Archiver                          | Archives WAL segments (archive_mode=on)              | ARCH (Archiver)            | Archives redo logs for recovery / backup                  |
| Logical Replication Launcher      | Manages publications/subscriptions for replication   | Streams, Goldengate, etc.  | Handles logical replication, propagates changes           |


---

# 🔎 How it works (Employees Example)

1. **Postmaster** starts when PostgreSQL service is started.

   * Reads configs (`postgresql.conf`, `pg_hba.conf`).
   * Spawns background processes above.

2. **Client connects:**

   ```bash
   psql -U postgres -d mydb
   ```

   * Postmaster accepts it → forks **postgres backend process**.
   * That backend handles all SQL queries for this client.

3. **You run query:**

   ```sql
   SELECT * FROM employees WHERE salary > 20000;
   ```

   * Backend process executes it.
   * May interact with WAL writer, background writer, checkpointer.

4. **You disconnect:**

   * Backend exits, postmaster keeps running.

---

# 🧠 Interview-Ready Explanation

> “In PostgreSQL, the **postmaster** is the parent process. When the database starts, postmaster initializes memory, then spawns background processes like checkpointer, WAL writer, background writer, and autovacuum. It also listens for client connections. For every new connection, postmaster forks a backend process (`postgres`) that handles queries for that session. If any critical background process dies, postmaster restarts it, ensuring stability.”

---

