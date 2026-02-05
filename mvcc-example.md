use your **employee salary** example so it’s clearer.
We’ll use a simple `employees` table:

| name   | salary |
| ------ | ------ |
| Meena  | 10000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

### 👩‍💻 Transaction A (HR Manager) – wants to update Meena’s salary

1. Transaction A starts.
2. Updates Meena’s salary from **10000 → 12000**.
3. Not committed yet.

---

### 👨‍💻 Transaction B (Auditor) – wants to read salaries at the same time

1. Transaction B starts **while A is still open**.
2. Auditor queries:

```sql
SELECT * FROM employees;
```

👉 He still sees:

| name   | salary |             |
| ------ | ------ | ----------- |
| Meena  | 10000  | ← old value |
| Yasoda | 30000  |             |
| Devi   | 15000  |             |

Even though HR already updated Meena → **he still sees the old snapshot (10000)**.

---

### 🔑 After A commits:

* Now the “current version” of Meena’s row is **12000**.
* Any **new transaction** will see:

| name   | salary |
| ------ | ------ |
| Meena  | 12000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

### ✅ What MVCC did here:

* **Readers don’t block writers**: Auditor’s query wasn’t blocked by HR’s update.
* **Writers don’t block readers**: HR could update while Auditor was reading.
* **Each transaction gets its own snapshot**:

  * Auditor → snapshot of old salaries (Meena = 10000).
  * HR → working on new salary (12000).

---

### 🧠 Analogy:

Think of salaries as **salary slips**:

* Meena’s old slip shows 10000.
* HR writes a new slip with 12000 (not published yet).
* Auditor checking during this time still sees the **old slip**.
* When HR commits → the new slip becomes official, old one is kept for history (until cleaned).

---
Demo **step-by-step MVCC demo with salaries** in PostgreSQL.
You can copy–paste these commands into **two separate sessions** (say, two `psql` terminals).

---

### 📂 Setup table first (run once)

```sql
CREATE TABLE employees (
    name TEXT PRIMARY KEY,
    salary INT
);

INSERT INTO employees VALUES
('Meena', 10000),
('Yasoda', 30000),
('Devi', 15000);
```

---

## 🟢 Session 1 (HR Manager)

```sql
BEGIN;
-- HR starts a transaction

UPDATE employees
SET salary = 12000
WHERE name = 'Meena';
-- HR updates Meena’s salary, but does NOT commit yet
```

---

## 🔵 Session 2 (Auditor)

```sql
BEGIN;
-- Auditor starts a transaction

SELECT * FROM employees;
```

👉 Output Auditor will see (old snapshot):

| name   | salary |             |
| ------ | ------ | ----------- |
| Meena  | 10000  | ← old value |
| Yasoda | 30000  |             |
| Devi   | 15000  |             |

Even though Session 1 already updated Meena to 12000, Auditor still sees 10000.

---

## 🟢 Session 1 (HR commits)

```sql
COMMIT;
```

---

## 🔵 Session 2 (Auditor checks again inside same transaction)

```sql
SELECT * FROM employees;
```

👉 Still sees old snapshot:

| name  | salary |
| ----- | ------ |
| Meena | 10000  |

(because Session 2 is working with the snapshot it had when it started).

---

## 🔵 Session 2 (Auditor starts a NEW transaction)

```sql
COMMIT;  -- end old transaction

BEGIN;
SELECT * FROM employees;
```

👉 Now sees latest data:

| name  | salary |                 |
| ----- | ------ | --------------- |
| Meena | 12000  | ✅ updated value |

---

### 🔑 What you just saw:

* Auditor’s old transaction → always saw **10000** (snapshot).
* New transaction after HR committed → saw **12000**.
* That’s **MVCC**: each transaction gets its own **versioned view** of the data.

---
#### Now what happens if both HR and Auditor try to update Meena’s salary at the same time (to show how MVCC handles conflicts)
Let’s extend our **MVCC demo with conflicts** using the same `employees` table.
This time both **HR (Session 1)** and **Auditor (Session 2)** will try to update **Meena’s salary** at the same time.

---

## 🟢 Session 1 (HR Manager)

```sql
BEGIN;

UPDATE employees
SET salary = 12000
WHERE name = 'Meena';
-- HR updates Meena to 12000, but does not COMMIT yet
```

✅ Now Meena’s row has **two versions**:

* Old: 10000 (still visible to old snapshots)
* New (uncommitted): 12000 (only visible to Session 1)

---

## 🔵 Session 2 (Auditor)

```sql
BEGIN;

UPDATE employees
SET salary = 13000
WHERE name = 'Meena';
```

👉 What happens?

* **Session 2 will block (wait)** because Session 1 is already updating the same row.
* PostgreSQL does this to **prevent conflicting writes**.

---

## 🟢 Session 1 (HR commits)

```sql
COMMIT;
```

* HR’s version (12000) becomes official.

---

## 🔵 Session 2 (Auditor’s update continues)

After Session 1 commits, Session 2 now applies its change:

* It takes HR’s committed value (12000) as base.
* Updates it to **13000**.

Auditor can now:

```sql
COMMIT;
```

---

## ✅ Final state

```sql
SELECT * FROM employees;
```

| name   | salary |
| ------ | ------ |
| Meena  | 13000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

### 🔑 Key takeaways:

* **Reads don’t block writes** (we saw earlier with SELECT).
* **Writes block writes** on the *same row* → Session 2 must wait for Session 1.
* After Session 1 commits, Session 2 re-checks and applies its update.
* PostgreSQL ensures **serializable results** (no two conflicting updates overwrite each other blindly).

---

⚡ Question ? You Can **what happens if Session 1 ROLLBACKS instead of COMMIT** (so you see how MVCC discards the uncommitted version)?

let’s continue with the **ROLLBACK case** so you see how MVCC safely discards uncommitted changes.

We’ll use the same table:

| name   | salary |
| ------ | ------ |
| Meena  | 10000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

## 🟢 Session 1 (HR Manager)

```sql
BEGIN;

UPDATE employees
SET salary = 12000
WHERE name = 'Meena';
-- HR updates Meena’s salary (not committed yet)
```

✅ Right now:

* Old version: 10000
* New (uncommitted): 12000 (only visible to Session 1)

---

## 🔵 Session 2 (Auditor)

```sql
BEGIN;

SELECT * FROM employees;
```

👉 Output Auditor sees (snapshot of committed data only):

| name   | salary |
| ------ | ------ |
| Meena  | 10000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

## 🟢 Session 1 (HR decides to cancel)

```sql
ROLLBACK;
```

👉 The uncommitted version (12000) is **discarded**.
Only the old committed version (10000) remains valid.

---

## 🔵 Session 2 (Auditor checks again)

```sql
SELECT * FROM employees;
```

Output still:

| name   | salary |                                       |
| ------ | ------ | ------------------------------------- |
| Meena  | 10000  | ✅ (unchanged, because HR rolled back) |
| Yasoda | 30000  |                                       |
| Devi   | 15000  |                                       |

---

### 🔑 What MVCC did here:

* While HR was updating, the new version (12000) existed **only inside HR’s transaction**.
* Since HR rolled back, Postgres threw away that new version.
* Other sessions always saw the old value (10000).
* This ensures **isolation + consistency** (no one else ever sees uncommitted data).

---

🧠 Easy analogy:

* HR wrote a new salary slip for Meena (12000), but before publishing it, they tore it up (ROLLBACK).
* Everyone else still sees the old slip (10000).

---

👉 Now **two people update different employees at the same time** (no blocking case) — so you see how MVCC allows true parallelism?

Now check the case where **two people update different employees at the same time**.
This shows how MVCC + row-level locking allow **true parallelism without blocking**.

---

### Initial Table

| name   | salary |
| ------ | ------ |
| Meena  | 10000  |
| Yasoda | 30000  |
| Devi   | 15000  |

---

## 🟢 Session 1 (HR Manager – updating Meena)

```sql
BEGIN;

UPDATE employees
SET salary = 12000
WHERE name = 'Meena';
-- Not committed yet
```

---

## 🔵 Session 2 (Finance Officer – updating Yasoda)

```sql
BEGIN;

UPDATE employees
SET salary = 32000
WHERE name = 'Yasoda';
-- Not committed yet
```

👉 Notice: **no blocking happens** ✅
Because:

* Session 1 is updating **Meena**’s row.
* Session 2 is updating **Yasoda**’s row.
* These are different rows → no conflict.

---

## 🟢 Session 1 (HR commits)

```sql
COMMIT;
```

---

## 🔵 Session 2 (Finance commits)

```sql
COMMIT;
```

---

## ✅ Final Table

```sql
SELECT * FROM employees;
```

| name   | salary |                   |
| ------ | ------ | ----------------- |
| Meena  | 12000  | ✅ HR updated      |
| Yasoda | 32000  | ✅ Finance updated |
| Devi   | 15000  | (unchanged)       |

---

### 🔑 Key takeaway

* **Row-level locks**: Writers only block other writers on the **same row**.
* **Different rows** → no blocking → both can commit independently.
* This is why MVCC + row-level locking scales well in multi-user systems.

---

🧠 Analogy:

* HR is editing **Meena’s salary slip**.
* Finance is editing **Yasoda’s salary slip**.
* They don’t touch each other’s slips, so they can both work in parallel.

---


