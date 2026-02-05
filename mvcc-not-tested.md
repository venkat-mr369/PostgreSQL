## **MVCC (Multi-Version Concurrency Control) in PostgreSQL – Detailed Notes & SQL Queries**  

## **📌 1. What is MVCC in PostgreSQL?**  
**MVCC (Multi-Version Concurrency Control)** is a **concurrency control mechanism** that allows multiple transactions to access the database **without waiting for locks**. Instead of blocking other transactions, MVCC **creates multiple versions of a row** and ensures data consistency using transaction snapshots.  

### **🔹 Key Concepts of MVCC**
- **Readers don’t block writers**: A SELECT query doesn’t wait for UPDATE/DELETE operations.  
- **Writers don’t block readers**: Transactions can read old row versions while updates occur.  
- **Each transaction gets a snapshot** of the database at its start.  

---

## **📌 2. How Does MVCC Work in PostgreSQL?**
When a transaction modifies data, PostgreSQL **doesn’t overwrite the original row** but instead:  
1. **Creates a new version of the row (tuple)** with a new transaction ID.  
2. **Marks the old row as "invisible" to newer transactions** while older transactions can still see it.  
3. **Uses system columns** (`xmin`, `xmax`) to manage row visibility.  

### **🔹 Example: How MVCC Works**
#### **1️⃣ Create a Table**
```sql
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT,
    salary NUMERIC,
    updated_by TEXT
);
```

#### **2️⃣ Insert Initial Data**
```sql
INSERT INTO employees (name, salary, updated_by) VALUES ('Alice', 50000, 'admin');
```

#### **3️⃣ Start Two Transactions**
**Transaction 1 (T1) - Updates Alice's Salary**  
```sql
BEGIN;
UPDATE employees SET salary = 55000, updated_by = 'HR' WHERE name = 'Alice';
-- Do NOT commit yet
```

**Transaction 2 (T2) - Reads the Data**
```sql
BEGIN;
SELECT * FROM employees WHERE name = 'Alice';
```
🔹 **T2 still sees the old salary (50000), even though T1 updated it** because **MVCC keeps a snapshot**.

#### **4️⃣ Commit T1 & Recheck in T2**
```sql
COMMIT; -- T1 commits
```
Now, if **T2 re-runs the SELECT**, it will see the **updated salary (55000)**.

---

## **📌 3. Key Data Structures in MVCC**
MVCC relies on **system columns** stored internally in PostgreSQL.  

| **Column** | **Description** |
|-----------|----------------|
| `xmin` | Stores the transaction ID that created the row |
| `xmax` | Stores the transaction ID that deleted/updated the row |
| `cmin` | Command number inside a transaction |
| `cmax` | Command number when a row is updated/deleted |

### **🔹 Example: Viewing MVCC Metadata**
```sql
SELECT ctid, xmin, xmax, * FROM employees;
```
🔹 **CTID** represents **physical row location**, which changes on updates.

---

## **📌 4. Benefits of MVCC in PostgreSQL**
| **Benefit** | **Description** |
|------------|----------------|
| **Non-Blocking Reads & Writes** | SELECT queries don’t block UPDATE/DELETE operations. |
| **Improved Performance** | Transactions can run concurrently without locking issues. |
| **Snapshot Isolation** | Ensures consistency without affecting ongoing transactions. |
| **No Read Locks Required** | SELECT queries never need to acquire explicit locks. |

---

## **📌 5. Transaction ID Wraparound Issue**
### **🔹 What is Transaction ID Wraparound?**
- PostgreSQL assigns a **32-bit Transaction ID (TXID)**.  
- It can hold **~2 billion transactions** before wraparound occurs.  
- **If not managed, it can cause database corruption** by reusing old TXIDs.

### **🔹 Checking Transaction Age**
```sql
SELECT datname, age(datfrozenxid) FROM pg_database;
```
**If `age(datfrozenxid) > 2 billion`, the database is at risk!**

### **🔹 Preventing Wraparound – VACUUM FREEZE**
```sql
VACUUM FREEZE;
```
This **marks old rows as permanent**, avoiding TXID wraparound.

---

## **✅ Summary**
✔ **MVCC allows multiple transactions to work concurrently without blocking each other.**  
✔ **Each transaction gets a snapshot of the database and works with row versions.**  
✔ **System columns (`xmin`, `xmax`) track row versions and visibility.**  
✔ **MVCC improves performance but requires `VACUUM FREEZE` to prevent transaction ID wraparound.**  

## **real-world example**
# **MVCC (Multi-Version Concurrency Control) – Real-World Example in PostgreSQL**  

Let’s go through a **real-world example** demonstrating **how MVCC handles concurrent transactions** in PostgreSQL.

---

## **📌 Scenario: Bank Account Balance Update**  
A bank has an `accounts` table that stores **customer balances**. Two transactions occur simultaneously:  
1. **Transaction 1 (T1)** updates the balance.  
2. **Transaction 2 (T2)** checks the balance while T1 is in progress.

---

## **🔹 Step 1: Create the Accounts Table**
```sql
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name TEXT,
    balance NUMERIC,
    updated_by TEXT
);
```
Insert sample data:
```sql
INSERT INTO accounts (name, balance, updated_by) VALUES 
('Alice', 5000, 'Admin'),
('Bob', 7000, 'Admin');
```
Check initial state:
```sql
SELECT * FROM accounts;
```
📌 **Output:**
```
 id | name  | balance | updated_by
----+-------+---------+------------
  1 | Alice |   5000  | Admin
  2 | Bob   |   7000  | Admin
```

---

## **🔹 Step 2: Start Two Transactions**
### **Transaction 1 (T1) - Updates Alice's Balance**
```sql
BEGIN;
UPDATE accounts SET balance = balance - 1000, updated_by = 'ATM' WHERE name = 'Alice';
-- Do NOT commit yet
```
At this point:
- Alice’s **balance is updated to 4000**, but **T1 is not committed yet**.
- **MVCC ensures that this change is not visible** to other transactions yet.

---

### **Transaction 2 (T2) - Reads Alice's Balance**
```sql
BEGIN;
SELECT * FROM accounts WHERE name = 'Alice';
```
📌 **Output (before T1 commits):**
```
 id | name  | balance | updated_by
----+-------+---------+------------
  1 | Alice |   5000  | Admin
```
🔹 **T2 still sees the old balance (5000) because T1’s update is not committed yet.**  

---

### **🔹 Step 3: Commit T1 and Recheck Balance in T2**
Now, **commit T1**:
```sql
COMMIT;
```
If **T2 re-runs the SELECT query**, it will now see the **updated balance**:
```sql
SELECT * FROM accounts WHERE name = 'Alice';
```
📌 **Output (after T1 commits):**
```
 id | name  | balance | updated_by
----+-------+---------+------------
  1 | Alice |   4000  | ATM
```
🔹 **Now T2 can see the new balance!**

---

## **🔹 Step 4: Viewing MVCC Internals**
Let’s check **how MVCC stores multiple row versions**.

```sql
SELECT ctid, xmin, xmax, * FROM accounts WHERE name = 'Alice';
```
📌 **Output:**
```
 ctid  | xmin  | xmax  | id | name  | balance | updated_by
-------+-------+------+----+-------+---------+------------
 (0,1) | 12345 | 12346 |  1 | Alice |   4000  | ATM
```
- `xmin = 12345` → Transaction that inserted this row.  
- `xmax = 12346` → Transaction that **invalidated the previous row version**.  

🔹 **This proves that PostgreSQL does not overwrite data but instead maintains multiple row versions.**

---

## **📌 Key Takeaways from This Real-World Example**
✔ **MVCC ensures that uncommitted transactions don’t affect other queries.**  
✔ **Readers see the old version of the data while updates are in progress.**  
✔ **PostgreSQL tracks row versions using system columns (`xmin`, `xmax`).**  
✔ **Once the transaction commits, other queries can see the new data.**  

---

## **🔹 Performance Tip: Cleanup Old Row Versions**
To remove old row versions and prevent **bloat**, run:
```sql
VACUUM ANALYZE accounts;
```

---

## **✅ Summary**
- **T2 initially sees Alice’s old balance (5000)** due to MVCC snapshots.  
- **T1 updates Alice’s balance to 4000**, but T2 does not see it until **T1 commits**.  
- **After T1 commits, T2 gets the latest balance (4000).**  
- **MVCC stores multiple row versions instead of using locks.**  

## **deadlock scenario** 

# **🔹 Simulating a Deadlock in PostgreSQL (MVCC & Concurrency Control)**  

Deadlocks occur when **two or more transactions** wait for each other to release locks, causing a **circular dependency**. PostgreSQL detects and resolves deadlocks by **terminating one of the transactions**.

---

## **📌 Scenario: Two Transactions Updating Each Other's Rows**
- **Transaction 1 (T1)** updates Row A and waits to update Row B.  
- **Transaction 2 (T2)** updates Row B and waits to update Row A.  
- **Both transactions are blocked, causing a deadlock.**  

---

## **🔹 Step 1: Create a Sample Table**
```sql
CREATE TABLE bank_accounts (
    id SERIAL PRIMARY KEY,
    name TEXT,
    balance NUMERIC
);
```
Insert initial data:
```sql
INSERT INTO bank_accounts (name, balance) VALUES 
('Alice', 5000),
('Bob', 7000);
```
Check data:
```sql
SELECT * FROM bank_accounts;
```
📌 **Output:**
```
 id | name  | balance
----+-------+---------
  1 | Alice |   5000
  2 | Bob   |   7000
```

---

## **🔹 Step 2: Simulate a Deadlock**
### **1️⃣ Start Transaction 1 (T1) - Lock Alice’s Row**
```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 1000 WHERE name = 'Alice';
-- Do NOT commit yet
```

### **2️⃣ Start Transaction 2 (T2) - Lock Bob’s Row**
Open another session and run:
```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 500 WHERE name = 'Bob';
-- Do NOT commit yet
```

---

### **3️⃣ Now Try to Update the Other Row**
🔹 **In T1, try updating Bob's balance (Row 2)**:
```sql
UPDATE bank_accounts SET balance = balance - 500 WHERE name = 'Bob';
```
🚨 **T1 is now waiting for T2 to release the lock!**  

🔹 **In T2, try updating Alice’s balance (Row 1)**:
```sql
UPDATE bank_accounts SET balance = balance - 1000 WHERE name = 'Alice';
```
🚨 **T2 is now waiting for T1 to release the lock!**

---

## **🔹 Step 3: PostgreSQL Detects the Deadlock**
After a few seconds, PostgreSQL **detects the deadlock and terminates one of the transactions**:

📌 **Output in T2:**
```
ERROR: deadlock detected
DETAIL: Process 1234 waits for ShareLock on transaction 5678;
         Process 5678 waits for ShareLock on transaction 1234.
HINT: Cancel one of the transactions to break the deadlock.
```

---

## **🔹 Step 4: Resolve the Deadlock**
Since **PostgreSQL automatically terminates one transaction**, we must **ROLLBACK** and retry.

### **1️⃣ Rollback the failed transaction**
```sql
ROLLBACK;
```

### **2️⃣ Ensure transactions update rows in a consistent order**
To **avoid deadlocks**, always follow a **consistent locking order**:
```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 1000 WHERE name = 'Alice';
UPDATE bank_accounts SET balance = balance - 500 WHERE name = 'Bob';
COMMIT;
```

---

## **📌 How to Prevent Deadlocks?**
✔ **Use a consistent update order** → Always update `Alice → Bob`, not `Bob → Alice`.  
✔ **Use shorter transactions** → The longer a transaction runs, the higher the chance of a deadlock.  
✔ **Use explicit locking with `FOR UPDATE`** to avoid waiting indefinitely:
```sql
SELECT * FROM bank_accounts WHERE name = 'Alice' FOR UPDATE;
```
✔ **Monitor deadlocks using PostgreSQL logs**:
```sql
SELECT * FROM pg_stat_activity WHERE state = 'active';
```

---

## **✅ Summary**
- **Deadlocks occur when two transactions wait on each other’s locks.**  
- **PostgreSQL automatically detects and terminates one transaction.**  
- **Fix deadlocks by ensuring transactions acquire locks in a consistent order.**  
- **Use `FOR UPDATE` locks and keep transactions short to minimize risk.**  

**Hands-on lab for deadlock monitoring in PostgreSQL**
# **🔹 Hands-on Lab: Deadlock Monitoring in PostgreSQL**  

This hands-on lab will teach you how to **monitor and analyze deadlocks in PostgreSQL** using system views and logs.

---

## **📌 Step 1: Enable Deadlock Logging in PostgreSQL**
By default, PostgreSQL logs deadlocks. To ensure deadlock detection is enabled, update **postgresql.conf**:

```ini
log_lock_waits = on
log_statement = 'all'
```

Restart PostgreSQL to apply changes:
```sh
sudo systemctl restart postgresql
```

---

## **📌 Step 2: Simulate a Deadlock**
### **1️⃣ Start Transaction 1 (T1) - Lock Alice’s Row**
```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 1000 WHERE name = 'Alice';
-- Do NOT commit yet
```

### **2️⃣ Start Transaction 2 (T2) - Lock Bob’s Row**
Open another session and run:
```sql
BEGIN;
UPDATE bank_accounts SET balance = balance - 500 WHERE name = 'Bob';
-- Do NOT commit yet
```

### **3️⃣ Try to Update the Other Row (Trigger Deadlock)**
- **In T1, update Bob’s balance (Row 2):**
```sql
UPDATE bank_accounts SET balance = balance - 500 WHERE name = 'Bob';
```

- **In T2, update Alice’s balance (Row 1):**
```sql
UPDATE bank_accounts SET balance = balance - 1000 WHERE name = 'Alice';
```

🚨 **PostgreSQL detects the deadlock and cancels one transaction.**

---

## **📌 Step 3: View Active Locks and Waiting Queries**
### **🔹 Identify Transactions Holding Locks**
Run this in a new session:
```sql
SELECT pid, usename, state, wait_event, query
FROM pg_stat_activity
WHERE state = 'active';
```

📌 **Output:**
```
 pid  | usename  | state  | wait_event | query
------+----------+--------+------------+-----------------------------------------
 2345 | postgres | active | Lock       | UPDATE bank_accounts SET balance = ...
 6789 | postgres | active | Lock       | UPDATE bank_accounts SET balance = ...
```

---

### **🔹 View Current Locks Held by Transactions**
```sql
SELECT pid, locktype, relation::regclass, mode, granted
FROM pg_locks
WHERE NOT granted;
```

📌 **Output:**
```
 pid  | locktype | relation     | mode           | granted
------+----------+-------------+---------------+---------
 2345 | relation | bank_accounts | RowExclusiveLock | false
 6789 | relation | bank_accounts | RowExclusiveLock | false
```
🚨 **This confirms both transactions are waiting on each other’s locks!**

---

## **📌 Step 4: View Deadlock Information in Logs**
Check the PostgreSQL logs for deadlock errors:
```sh
sudo tail -f /var/log/postgresql/postgresql.log
```
📌 **Sample Log Output:**
```
ERROR:  deadlock detected
DETAIL:  Process 2345 waits for ShareLock on transaction 6789;
         Process 6789 waits for ShareLock on transaction 2345.
HINT:  Cancel one of the transactions to break the deadlock.
```

---

## **📌 Step 5: Resolving the Deadlock**
Since **PostgreSQL cancels one transaction**, the other must **ROLLBACK**:

```sql
ROLLBACK;
```

---

## **📌 Step 6: Preventing Deadlocks**
✔ **Use a consistent update order** → Always update `Alice → Bob`, not `Bob → Alice`.  
✔ **Use shorter transactions** → Minimize the time a transaction holds a lock.  
✔ **Use explicit locking with `FOR UPDATE`** to avoid waiting indefinitely:
```sql
SELECT * FROM bank_accounts WHERE name = 'Alice' FOR UPDATE;
```
✔ **Monitor deadlocks using PostgreSQL logs** and system views.

---

## **✅ Summary**
1️⃣ **Enable deadlock logging in `postgresql.conf`**  
2️⃣ **Simulate a deadlock** by executing conflicting transactions  
3️⃣ **Monitor deadlocks using `pg_stat_activity` and `pg_locks`**  
4️⃣ **Analyze logs for deadlock detection**  
5️⃣ **Prevent deadlocks by using consistent update orders and explicit locks**  

**script to automate deadlock detection and resolution**
# **🔹 PostgreSQL Deadlock Detection & Resolution Script**  

This script **automatically detects deadlocks** in PostgreSQL and **logs blocked queries** for analysis. It also provides **automatic resolution** by terminating the least important transaction.

---

## **📌 Step 1: Create a Deadlock Monitoring Function**
This function **detects deadlocks** and **logs active transactions**.

```sql
CREATE OR REPLACE FUNCTION detect_deadlocks()
RETURNS TABLE(pid INT, usename TEXT, query TEXT, wait_event TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT pid, usename, query, wait_event
    FROM pg_stat_activity
    WHERE wait_event = 'Lock';
END;
$$ LANGUAGE plpgsql;
```

### **Test the Function**
Run the function to check for blocked transactions:
```sql
SELECT * FROM detect_deadlocks();
```

📌 **Output (If Deadlocks Exist):**
```
 pid  | usename  | query                                    | wait_event
------+----------+-----------------------------------------+------------
 2345 | postgres | UPDATE bank_accounts SET balance = ...  | Lock
 6789 | postgres | UPDATE bank_accounts SET balance = ...  | Lock
```

---

## **📌 Step 2: Kill the Least Important Transaction**
🔹 This function **automatically terminates the longest-running deadlocked transaction**.

```sql
CREATE OR REPLACE FUNCTION resolve_deadlocks()
RETURNS VOID AS $$
DECLARE
    victim_pid INT;
BEGIN
    -- Find the longest running blocked transaction
    SELECT pid INTO victim_pid
    FROM pg_stat_activity
    WHERE wait_event = 'Lock'
    ORDER BY state_change ASC
    LIMIT 1;

    -- Kill the selected transaction
    IF victim_pid IS NOT NULL THEN
        RAISE NOTICE 'Terminating transaction % to resolve deadlock', victim_pid;
        PERFORM pg_terminate_backend(victim_pid);
    ELSE
        RAISE NOTICE 'No deadlocks detected';
    END IF;
END;
$$ LANGUAGE plpgsql;
```

### **Run the Resolution Function**
```sql
SELECT resolve_deadlocks();
```
📌 **Output (If Deadlocks Exist):**
```
NOTICE:  Terminating transaction 2345 to resolve deadlock
```

---

## **📌 Step 3: Automate Deadlock Detection**
Create a **cron job** to monitor deadlocks every 10 minutes.

🔹 **Create a Bash Script** (`deadlock_monitor.sh`):
```sh
#!/bin/bash

LOGFILE="/var/log/postgresql/deadlock_monitor.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Run deadlock detection query
DEADLOCKS=$(psql -U postgres -d mydatabase -c "SELECT * FROM detect_deadlocks();" | wc -l)

if [ "$DEADLOCKS" -gt 1 ]; then
  echo "$DATE - Deadlock detected! Running resolution script." >> $LOGFILE
  psql -U postgres -d mydatabase -c "SELECT resolve_deadlocks();"
else
  echo "$DATE - No deadlocks detected." >> $LOGFILE
fi
```

🔹 **Make the script executable**:
```sh
chmod +x deadlock_monitor.sh
```

🔹 **Schedule it in crontab**:
```sh
crontab -e
```
Add the following line to run every **10 minutes**:
```sh
*/10 * * * * /path/to/deadlock_monitor.sh
```

---

## **✅ Summary**
✔ **Detects deadlocks** using `pg_stat_activity`.  
✔ **Logs blocked queries** for analysis.  
✔ **Terminates the least important transaction** to resolve deadlocks.  
✔ **Automates deadlock detection** using a scheduled cron job.  

