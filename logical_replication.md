

- **Publisher:** 10.0.0.4, Database: logicadb
- **Subscriber:** 10.0.1.4, Database: repdb
- **Replication User:** repuser / Password: rep123

This includes: 
- Verified `pg_hba.conf` for both nodes (copy and paste ready)
- Core replication SQL commands
- PostgreSQL config tuning
- Key connection test steps

***

# Logical Replication Complete Setup

## 1. PostgreSQL Configuration (`postgresql.conf`)

**On BOTH Publisher & Subscriber**, set:
```conf
listen_addresses = '*'
wal_level = logical
max_replication_slots = 10
max_wal_senders = 10
```
- Save and reload PostgreSQL after editing (`sudo systemctl reload postgresql`).

***

## 2. Authentication (`pg_hba.conf`)

### Publisher: `10.0.0.4` (**logicadb**)

```conf
# Local connections
local   all             all                                   trust
host    all             all            127.0.0.1/32            trust
host    all             all            ::1/128                 trust

# Logical replication and DB access
host    logicadb        repuser        10.0.0.4/32             md5
host    logicadb        repuser        10.0.1.4/32             md5

host    replication     repuser        10.0.0.4/32             md5
host    replication     repuser        10.0.1.4/32             md5

# Local replication
local   replication     all                                   trust
host    replication     all            127.0.0.1/32            trust
host    replication     all            ::1/128                 trust
```

### Subscriber: `10.0.1.4` (**repdb**)

```conf
# Local connections
local   all             all                                   trust
host    all             all            127.0.0.1/32            trust
host    all             all            ::1/128                 trust

# Logical replication and DB access
host    repdb           repuser        10.0.0.4/32             md5
host    repdb           repuser        10.0.1.4/32             md5

host    replication     repuser        10.0.0.4/32             md5
host    replication     repuser        10.0.1.4/32             md5

# Local replication
local   replication     all                                   trust
host    replication     all            127.0.0.1/32            trust
host    replication     all            ::1/128                 trust
```
- **Always** reload PostgreSQL after editing (`sudo systemctl reload postgresql`).

***

## 3. User & Database Setup (run on both nodes)

### Create Replication User

Connect as superuser:
```sql
CREATE ROLE repuser WITH REPLICATION LOGIN ENCRYPTED PASSWORD 'rep123';
```

### On Publisher (`10.0.0.4`)
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

### On Subscriber (`10.0.1.4`)
```sql
CREATE DATABASE repdb OWNER repuser;
\c repdb

CREATE TABLE emp(id INT PRIMARY KEY, ename VARCHAR(30), desg VARCHAR(20));
CREATE TABLE dept(id INT, dept VARCHAR(30), company VARCHAR(20));
```

***

## 4. Set Up Replication

### On Publisher (`10.0.0.4`)
```sql
CREATE PUBLICATION mypub FOR ALL TABLES;
```

### On Subscriber (`10.0.1.4`)
```sql
CREATE SUBSCRIPTION mysub
  CONNECTION 'host=10.0.0.4 port=5432 dbname=logicadb user=repuser password=rep123'
  PUBLICATION mypub;
```

***

## 5. Testing

- Insert a row on Publisher, check on Subscriber:
```sql
-- Publisher
INSERT INTO emp VALUES (4, 'Santhosh', 'Cloud Manager');
-- Subscriber
SELECT * FROM emp; -- should see new rows
```

***

## 6. Schema Changes & Failover Ready

- Always create new tables and columns on **both** nodes.
- On Publisher:
  ```sql
  ALTER PUBLICATION mypub ADD TABLE newtable;
  ```
- On Subscriber:
  ```sql
  CREATE TABLE newtable(...);
  ALTER SUBSCRIPTION mysub REFRESH PUBLICATION;
  ```

Your configs allow either node to switch roles instantly for failover — promoting `repdb` to the new publisher if needed.

***

## 7. Monitor/Debug

- **On Publisher:**
  ```sql
  SELECT * FROM pg_replication_slots;
  SELECT * FROM pg_stat_replication;
  ```
- **On Subscriber:**
  ```sql
  SELECT * FROM pg_stat_subscription;
  SELECT * FROM pg_subscription;
  ```

***


