### Implementing Postgres Logical Replication

# PostgreSQL Logical Replication: Clean Guide

- **Master/Publisher:** 10.0.0.4  
- **Standby/Subscriber:** 10.0.1.4  
- **Replication User:** repuser / rep123  
- **Source DB:** logicadb  
- **Target DB:** repdb

***

## 1. Master/Publisher Setup (10.0.0.4)

### 1.1 Edit `postgresql.conf`
Set these values:
```conf
listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
```

### 1.2 Edit `pg_hba.conf`
Add the subscriber’s IP:
```
host    all            repuser    10.0.1.4/32     md5
host    replication    repuser    10.0.1.4/32     md5
```

### 1.3 Create/Modify Replication User
Connect to PostgreSQL (as superuser):
```sql
CREATE ROLE repuser WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep123';
-- or, if already exists:
ALTER ROLE repuser WITH SUPERUSER ENCRYPTED PASSWORD 'rep123';
\du  -- View user privileges
```

### 1.4 Restart PostgreSQL
```bash
sudo systemctl restart postgresql
```

### 1.5 Create Database and Tables
```sql
CREATE DATABASE logicadb OWNER repuser;
\c logicadb

CREATE TABLE emp(id INT PRIMARY KEY, ename VARCHAR(30), desg VARCHAR(20));
INSERT INTO emp VALUES
    (1,'venkat','Sr DBA'),
    (2,'Sreenu Bro','Assoc Director'),
    (3,'Durgapathi','Assoc Ops Manager');

CREATE TABLE dept(id INT, dept VARCHAR(30), company VARCHAR(20));
INSERT INTO dept VALUES (1,'CIS','Cognizant');
```

### 1.6 Create Publication
```sql
CREATE PUBLICATION mypub FOR ALL TABLES;
-- or for certain tables only:
-- CREATE PUBLICATION mypub FOR TABLE emp, dept;
\dRp  -- View publications
```

***

## 2. Standby/Subscriber Setup (10.0.1.4)

### 2.1 (OPTIONAL) Edit config for future cascading replication

#### `postgresql.conf`
```conf
listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
```

#### `pg_hba.conf`
(Only if you expect future subscribers):
```
host    all            repuser    /32     md5
host    replication    repuser    /32     md5
```

#### Reload PostgreSQL
```bash
sudo systemctl restart postgresql
```

### 2.2 Create Target Database and Matching Schema
```sql
CREATE DATABASE repdb OWNER repuser;
\c repdb

CREATE TABLE emp(id INT PRIMARY KEY, ename VARCHAR(30), desg VARCHAR(20));
CREATE TABLE dept(id INT, dept VARCHAR(30), company VARCHAR(20));
```

### 2.3 Create Subscription
```sql
CREATE SUBSCRIPTION mysub
  CONNECTION 'host=10.0.0.4 port=5432 dbname=logicadb user=repuser password=rep123'
  PUBLICATION mypub;
\dRs  -- View subscriptions
```

***

## 3. Test Replication

- Add/changing records on master, confirm on subscriber.

**Example:**
```sql
-- On master (10.0.0.4):
INSERT INTO emp VALUES (4, 'Santhosh', 'Cloud Manager');

-- On standby (10.0.1.4):
SELECT * FROM emp;
```

***

## 4. Replicating Schema Changes

- Schema changes (new tables) must be created on both, then add to publication and refresh.

**On Master:**
```sql
ALTER PUBLICATION mypub ADD TABLE skills;
CREATE TABLE skills(id INT PRIMARY KEY, name VARCHAR(30), status VARCHAR(20));
INSERT INTO skills VALUES (1,'java','technical'), (2,'dba','infrastructure');
```
**On Standby:**
```sql
CREATE TABLE skills(id INT PRIMARY KEY, name VARCHAR(30), status VARCHAR(20));
ALTER SUBSCRIPTION mysub REFRESH PUBLICATION;
SELECT * FROM skills;
```

***

## 5. Monitoring and Maintenance

- **Master:**
    ```sql
    SELECT * FROM pg_replication_slots;
    SELECT * FROM pg_stat_replication;
    SELECT * FROM pg_publication;
    ```
- **Standby:**
    ```sql
    SELECT * FROM pg_stat_subscription;
    SELECT * FROM pg_subscription;
    ```

- Recreate publications/subscriptions if issues arise.

***

## 6. Best Practices & Tips

- DDL (structure) changes are NOT replicated—always apply on both sides.
- After changes to what’s published, always run `ALTER SUBSCRIPTION ... REFRESH PUBLICATION`.
- Logical replication works between different platforms and can be cascaded.
- Monitor logs and stats for troubleshooting.

***

