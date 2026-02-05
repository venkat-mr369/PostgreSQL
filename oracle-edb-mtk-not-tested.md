### **EDB Migration Toolkit (MTK) Setup and Migration Steps from Oracle (192.168.17.101) to PostgreSQL (192.168.17.102)**  

This guide provides a **detailed step-by-step** process for migrating an Oracle database running on `192.168.17.101` to a PostgreSQL database on `192.168.17.102` using **EDB Migration Toolkit (MTK)**.

**User Name & Passwords mentioned like Oracle_user and Postgres_user and passwords like Oracle_password and postgres_password. according to your requirements. you can change it as per your company policy & Norms.**
---

## **1. Pre-Migration Assessment**  
Before starting the migration, perform the following checks:  

✅ **Identify Database Objects to Migrate**  
- Tables, indexes, sequences, constraints, stored procedures, views, triggers, functions, synonyms, etc.  

✅ **Check Compatibility**  
- Review data types and functions.  
- Oracle PL/SQL must be converted to PostgreSQL PL/pgSQL.  

✅ **Validate Network Connectivity**  
- Ensure both Oracle (`192.168.17.101`) and PostgreSQL (`192.168.17.102`) can communicate over the network.  
- Use **Telnet** to verify connectivity:
  ```sh
  telnet 192.168.17.102 5432  # Check PostgreSQL connection from Oracle
  telnet 192.168.17.101 1521  # Check Oracle connection from PostgreSQL
  ```
  
---

## **2. Install EDB Migration Toolkit (MTK)**  
### **a. Download & Install MTK on the PostgreSQL Server (192.168.17.102)**  
1. **Download MTK** from [EDB's official site](https://www.enterprisedb.com/downloads).  
2. Install it using the `.tar` or `.rpm` package:
   ```sh
   tar -xvf edb-migrationtoolkit*.tar.gz -C /opt/
   cd /opt/edb-migrationtoolkit/
   ```
3. **Install Java** (if not installed):
   ```sh
   sudo yum install java-11-openjdk -y
   ```
### **b. Configure MTK Properties**  
Edit the `migrationtoolkit.properties` file:
```sh
vim /opt/edb-migrationtoolkit/etc/migrationtoolkit.properties
```
Set the following details:
```properties
source.db.type=oracle
target.db.type=postgres
source.db.host=192.168.17.101
source.db.port=1521
source.db.user=oracle_user
source.db.password=oracle_password
target.db.host=192.168.17.102
target.db.port=5432
target.db.user=postgres
target.db.password=postgres_password
```
Save and exit.

---

## **3. Prepare the Oracle Source Database (192.168.17.101)**  
### **a. Grant Necessary Privileges to Migration User**  
Log in to Oracle and run:
```sql
GRANT CONNECT, RESOURCE, DBA TO oracle_user;
GRANT SELECT ANY TABLE TO oracle_user;
GRANT SELECT ANY DICTIONARY TO oracle_user;
GRANT FLASHBACK ANY TABLE TO oracle_user;
```

### **b. Enable Archivelog Mode (If Not Already Enabled)**
```sql
ALTER DATABASE ARCHIVELOG;
```

### **c. Check Table and Index Structure**  
Run:
```sql
SELECT table_name FROM user_tables;
SELECT index_name, table_name FROM user_indexes;
```

---

## **4. Prepare the PostgreSQL Target Database (192.168.17.102)**  
### **a. Create the Database**  
Log in to PostgreSQL and create the database:
```sh
psql -U postgres
```
```sql
CREATE DATABASE mydb;
```

### **b. Allow Remote Connections**  
Edit `pg_hba.conf`:
```sh
vim /var/lib/pgsql/14/data/pg_hba.conf
```
Add:
```
host all all 192.168.17.101/32 md5
```
Restart PostgreSQL:
```sh
systemctl restart postgresql
```

---

## **5. Perform the Migration Using MTK**  
### **a. Schema Migration**
Run:
```sh
/opt/edb-migrationtoolkit/bin/mtk -sourcedbtype oracle -targetdbtype postgres \
-sourcehost 192.168.17.101 -sourceuser oracle_user -sourcedb myoracledb \
-targethost 192.168.17.102 -targetuser postgres -targetdb mydb -table all -schemaonly
```
This will create the tables and schema without data.

### **b. Data Migration**  
Run:
```sh
/opt/edb-migrationtoolkit/bin/mtk -sourcedbtype oracle -targetdbtype postgres \
-sourcehost 192.168.17.101 -sourceuser oracle_user -sourcedb myoracledb \
-targethost 192.168.17.102 -targetuser postgres -targetdb mydb -table all -dataonly
```

### **c. Function & Trigger Migration**
```sh
/opt/edb-migrationtoolkit/bin/mtk -sourcedbtype oracle -targetdbtype postgres \
-sourcehost 192.168.17.101 -sourceuser oracle_user -sourcedb myoracledb \
-targethost 192.168.17.102 -targetuser postgres -targetdb mydb -objecttype function,trigger
```

---

## **6. Validate Migration**
### **a. Check Row Counts**
```sql
SELECT table_name, num_rows FROM user_tables;
SELECT relname, reltuples::bigint FROM pg_class WHERE relkind='r';
```

### **b. Compare Schema Structures**
Run:
```sh
diff oracle_schema.sql postgres_schema.sql
```

---

## **7. Optimize PostgreSQL Performance**
- Run `ANALYZE` and `VACUUM`:
  ```sql
  ANALYZE;
  VACUUM ANALYZE;
  ```
- Tune `postgresql.conf` for performance.

---

## **8. Final Testing and Go-Live**
- Perform UAT testing.  
- Update application connection settings to PostgreSQL.  
- Perform a **final data sync** if required.  
- Decommission the Oracle database if necessary.

---
**Note:-** Test it on Lower Envirnoments first then, take it forward. 
### ** Your migration from Oracle (192.168.17.101) to PostgreSQL (192.168.17.102) is now completed!** 
### Automation
Here is a **bash script** to automate the migration from **Oracle (192.168.17.101)** to **PostgreSQL (192.168.17.102)** using **EDB Migration Toolkit (MTK)**.
```bash
#!/bin/bash

# Set Variables
ORACLE_HOST="192.168.17.101"
ORACLE_PORT="1521"
ORACLE_USER="oracle_user"
ORACLE_PASSWORD="oracle_password"
ORACLE_DB="myoracledb"

POSTGRES_HOST="192.168.17.102"
POSTGRES_PORT="5432"
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres_password"
POSTGRES_DB="mydb"

MTK_PATH="/opt/edb-migrationtoolkit/bin/mtk"

export PGPASSWORD=$POSTGRES_PASSWORD

# Step 1: Schema Migration
echo "Starting schema migration..."
$MTK_PATH -sourcedbtype oracle -targetdbtype postgres \
  -sourcehost $ORACLE_HOST -sourceuser $ORACLE_USER -sourcedb $ORACLE_DB \
  -targethost $POSTGRES_HOST -targetuser $POSTGRES_USER -targetdb $POSTGRES_DB \
  -table all -schemaonly

echo "Schema migration completed."

# Step 2: Data Migration
echo "Starting data migration..."
$MTK_PATH -sourcedbtype oracle -targetdbtype postgres \
  -sourcehost $ORACLE_HOST -sourceuser $ORACLE_USER -sourcedb $ORACLE_DB \
  -targethost $POSTGRES_HOST -targetuser $POSTGRES_USER -targetdb $POSTGRES_DB \
  -table all -dataonly

echo "Data migration completed."

# Step 3: Functions, Triggers, and Procedures Migration
echo "Migrating functions, triggers, and procedures..."
$MTK_PATH -sourcedbtype oracle -targetdbtype postgres \
  -sourcehost $ORACLE_HOST -sourceuser $ORACLE_USER -sourcedb $ORACLE_DB \
  -targethost $POSTGRES_HOST -targetuser $POSTGRES_USER -targetdb $POSTGRES_DB \
  -objecttype function,trigger,procedure

echo "Functions and triggers migrated successfully."

# Step 4: Run ANALYZE and VACUUM
echo "Optimizing PostgreSQL database..."
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "ANALYZE;"
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "VACUUM ANALYZE;"

echo "Migration completed successfully!"
```

### Explanation of the Steps:
1. **Schema Migration**  
   - Copies the table structure, indexes, constraints, and sequences.
   
2. **Data Migration**  
   - Transfers all the data from Oracle to PostgreSQL.

3. **Functions, Triggers, and Procedures Migration**  
   - Converts PL/SQL objects into PL/pgSQL.

4. **Optimization**  
   - Runs `ANALYZE` and `VACUUM ANALYZE` to optimize PostgreSQL performance.


