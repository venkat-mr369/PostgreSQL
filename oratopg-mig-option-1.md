
Migration Oracle DB to PostgreSQL DB
---

## 🔑 Step 1: Where to Install `ora2pg`?

You have:

* **oraserver1** → Oracle DB
* **pgserver2** → PostgreSQL 17

👉 **Best Practice**:
Install **ora2pg on pgserver2 (PostgreSQL server)**.

* Reason: ora2pg needs to **connect to Oracle remotely (via Oracle client/DBI drivers)** and **generate SQL/DATA** directly usable by PostgreSQL.
* Keeping it on `pgserver2` ensures:

  * SQL dump is local to PostgreSQL
  * Easier to test `psql` imports
  * Centralized control

Alternative: You *could* install ora2pg on a **separate migration/jump server** if you don’t want Oracle/PG software mixing, but 90% of cases → install on **pgserver2**.

---

## 🔑 Step 2: Prerequisites on `pgserver2`

1. **Install PostgreSQL client tools** (already installed with PG17).
   Needed for loading migrated schema/data (`psql`).

2. **Install Oracle Client libraries** (on pgserver2).

   * Install **Oracle Instant Client** (basic + sqlplus recommended).
   * Required for ora2pg to connect using DBI/DBD::Oracle.

   Example (Oracle Linux/RHEL):

   ```bash
   yum install -y oracle-instantclient-basic.x86_64 \
                  oracle-instantclient-sqlplus.x86_64
   ```

3. **Install Perl modules** needed by ora2pg:

   ```bash
   yum install -y perl perl-DBI perl-DBD-Oracle perl-Time-HiRes
   ```

4. **Install ora2pg**

   * EPEL or from source:

   ```bash
   yum install -y ora2pg
   ```

   OR latest from CPAN:

   ```bash
   cpanm ora2pg
   ```

5. **Network connectivity**

   * Ensure `pgserver2` can connect to `oraserver1:1521` (Oracle listener).
   * Example test:

     ```bash
     tnsping oraserver1
     sqlplus user/password@//oraserver1:1521/ORCLPDB1
     ```

---

## 🔑 Step 3: Oracle-side Preparation (on oraserver1)

1. **Create a dedicated migration user** with required privileges:

   ```sql
   CREATE USER ora2pg_user IDENTIFIED BY strong_password;
   GRANT CONNECT, RESOURCE, SELECT_CATALOG_ROLE TO ora2pg_user;
   GRANT SELECT ANY TABLE TO ora2pg_user;
   ```

   * If you need to migrate PL/SQL, sequences, synonyms etc., grant `SELECT ANY DICTIONARY`.

2. **Check character set**

   ```sql
   SELECT value FROM nls_database_parameters WHERE parameter='NLS_CHARACTERSET';
   ```

   → Should be `AL32UTF8` ideally (matches PostgreSQL UTF8).

---

## 🔑 Step 4: Ora2pg Configuration (`ora2pg.conf` on pgserver2)

Typical minimal config file:

```conf
# Oracle connection
ORACLE_DSN   dbi:Oracle:host=oraserver1;sid=ORCLPDB1;port=1521
ORACLE_USER  ora2pg_user
ORACLE_PWD   strong_password

# PostgreSQL output directory
OUTPUT_DIR   /var/tmp/ora2pg_output
LOGFILE      /var/log/ora2pg.log
DEBUG        1

# What to export (schema first, then data)
TYPE         TABLE
SCHEMA       myschema

# Convert data types
DATA_TYPE    NUMBER(1):boolean
DATA_TYPE    NUMBER(10):integer
DATA_TYPE    NUMBER(19):bigint

# Generate file compatible with psql
FILE_PER_CONSTRAINT 1
```

---

## 🔑 Step 5: Pre-Migration Steps (Dry Run)

1. **Check installation**

   ```bash
   ora2pg -v
   ```

2. **Generate migration report** (very important!):

   ```bash
   ora2pg -t SHOW_REPORT -c /etc/ora2pg/ora2pg.conf > migration_report.txt
   ```

   * This shows how many objects can migrate automatically vs manual fixes needed.
   * Example sections: tables, indexes, sequences, invalid datatypes, etc.

3. **Export schema only (no data yet)**

   ```bash
   ora2pg -t TABLE -c /etc/ora2pg/ora2pg.conf -o schema.sql
   ```

4. **Apply schema in PostgreSQL**

   ```bash
   psql -U postgres -d targetdb -f schema.sql
   ```

5. **Export data (after schema ok)**

   ```bash
   ora2pg -t COPY -c /etc/ora2pg/ora2pg.conf -o data.sql
   ```

6. **Load data**

   ```bash
   psql -U postgres -d targetdb -f data.sql
   ```

---

## 🔑 Step 6: Best Practice Workflow

1. **On oraserver1 (Oracle):**

   * Create migration user
   * Validate schema/charset
   * Grant permissions

2. **On pgserver2 (PostgreSQL + ora2pg):**

   * Install instant client + ora2pg
   * Configure `ora2pg.conf`
   * Run `SHOW_REPORT` to analyze
   * Export schema → load into PG
   * Export data → load into PG
   * Export other objects (views, functions, packages) separately, fix manually if needed

3. **Validation**

   * Compare row counts per table
   * Validate numeric precision/scale
   * Test key application queries

---

✅ Summary:

* Install **ora2pg on pgserver2** (with Oracle Instant Client + Perl modules).
* Use an **Oracle migration user** with read/catalog privileges.
* Configure `ora2pg.conf` with DSN pointing to oraserver1.
* Run **SHOW\_REPORT → Schema → Data → Functions** in stages.

---

Steps

Perfect 👍 Let’s make it **hands-on**. Below is a **step-by-step command sequence** you can directly execute on `pgserver2` (PostgreSQL 17 server) to prepare for and run the **first ora2pg migration test** from `oraserver1`.

---

# 🔧 Step 1: Prepare Environment on `pgserver2`

### 1. Update system packages

```bash
sudo yum update -y   # (use dnf if Oracle Linux 9 / RHEL9)
```

### 2. Install required PostgreSQL client tools

(You already installed PG17, so just make sure `psql` is available)

```bash
psql --version
```

### 3. Install Oracle Instant Client (basic + sqlplus)

Download from [Oracle site](https://www.oracle.com/database/technologies/instant-client.html) or use yum repo:

```bash
sudo yum install -y oracle-instantclient-basic.x86_64 \
                    oracle-instantclient-sqlplus.x86_64
```

Test:

```bash
sqlplus system/password@//oraserver1:1521/ORCLPDB1
```

### 4. Install Perl + DBI/DBD

```bash
sudo yum install -y perl perl-DBI perl-DBD-Oracle perl-Time-HiRes
```

### 5. Install ora2pg

```bash
sudo yum install -y ora2pg
```

Verify:

```bash
ora2pg -v
```

---

# 🔧 Step 2: Oracle-side Prep on `oraserver1`

Login as DBA and create a **migration user**:

```sql
CREATE USER ora2pg_user IDENTIFIED BY StrongPass123;
GRANT CONNECT, RESOURCE, SELECT_CATALOG_ROLE TO ora2pg_user;
GRANT SELECT ANY TABLE TO ora2pg_user;
```

---

# 🔧 Step 3: Configure ora2pg on `pgserver2`

Create output/log dirs:

```bash
sudo mkdir -p /var/tmp/ora2pg_output
sudo mkdir -p /var/log/ora2pg
sudo chown postgres:postgres /var/tmp/ora2pg_output /var/log/ora2pg
```

Create config file `/etc/ora2pg/ora2pg.conf`:

```conf
# Oracle connection
ORACLE_DSN   dbi:Oracle:host=oraserver1;sid=ORCLPDB1;port=1521
ORACLE_USER  ora2pg_user
ORACLE_PWD   StrongPass123

# Output
OUTPUT_DIR   /var/tmp/ora2pg_output
LOGFILE      /var/log/ora2pg/ora2pg.log
DEBUG        1

# Migration mode
TYPE         TABLE
SCHEMA       MYSCHEMA

# Datatype adjustments
DATA_TYPE    NUMBER(1):boolean
DATA_TYPE    NUMBER(10):integer
DATA_TYPE    NUMBER(19):bigint
```

---

# 🔧 Step 4: Run Pre-Migration Analysis

1. **Check Oracle connectivity**

```bash
sqlplus ora2pg_user/StrongPass123@//oraserver1:1521/ORCLPDB1
```

2. **Generate migration report**

```bash
ora2pg -t SHOW_REPORT -c /etc/ora2pg/ora2pg.conf > /var/tmp/ora2pg_output/migration_report.txt
```

👉 This report tells you:

* How many tables, views, sequences, triggers, functions exist
* What ora2pg can auto-convert vs manual work

---

# 🔧 Step 5: Export Schema & Load into PostgreSQL

1. **Export schema**

```bash
ora2pg -t TABLE -c /etc/ora2pg/ora2pg.conf -o schema.sql
```

2. **Apply to PostgreSQL**

```bash
psql -U postgres -d targetdb -f /var/tmp/ora2pg_output/schema.sql
```

---

# 🔧 Step 6: Export Data

1. **Export data as COPY**

```bash
ora2pg -t COPY -c /etc/ora2pg/ora2pg.conf -o data.sql
```

2. **Load data**

```bash
psql -U postgres -d targetdb -f /var/tmp/ora2pg_output/data.sql
```

---

# 🔧 Step 7: Validate

1. **Row counts**

```sql
-- On PostgreSQL
SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY relname;

-- On Oracle
SELECT table_name, num_rows FROM all_tables WHERE owner='MYSCHEMA';
```

2. **Data spot-check**

```sql
-- On PostgreSQL
SELECT * FROM mytable LIMIT 10;
```

---

✅ At this point, you have:

* ora2pg installed on `pgserver2`
* Configured to connect Oracle (`oraserver1`)
* Generated report
* Exported schema + data into PostgreSQL

---

👉 Next steps after this dry run:

* Handle **functions, procedures, packages** (Oracle PL/SQL → PL/pgSQL needs manual fixes).
* Handle **partitioned tables, triggers, sequences** separately.
* Test with your application workload.

---



