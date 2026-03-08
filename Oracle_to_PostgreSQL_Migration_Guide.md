# Oracle to PostgreSQL — Database Migration Guide

**Schema Conversion | Data Validation | Cutover Planning**
Three Migration Methods: EC2 PostgreSQL | Amazon RDS | Amazon Aurora
PostgreSQL Version 16 Target

| Parameter | Value |
|---|---|
| **Source** | On-Prem Oracle (100.10.1.101) |
| **Schemas** | 10 Database Schemas |
| **Target Version** | PostgreSQL 16 |

---

## Table of Contents

1. [Executive Overview](#1-executive-overview)
2. [Pre-Migration Assessment (All Methods)](#2-pre-migration-assessment-all-methods)
3. [Method 1: Migration to EC2 PostgreSQL (Self-Managed)](#3-method-1-migration-to-ec2-postgresql-self-managed)
4. [Method 2: Migration to Amazon RDS PostgreSQL](#4-method-2-migration-to-amazon-rds-postgresql)
5. [Method 3: Migration to Amazon Aurora PostgreSQL](#5-method-3-migration-to-amazon-aurora-postgresql)
6. [Data Validation (All Methods)](#6-data-validation-all-methods)
7. [Cutover Planning (All Methods)](#7-cutover-planning-all-methods)
8. [Post-Migration Optimization and Monitoring](#8-post-migration-optimization-and-monitoring)
9. [Risk Register and Mitigation](#9-risk-register-and-mitigation)
10. [Appendix A: Tool Versions and References](#appendix-a-tool-versions-and-references)

---

## 1. Executive Overview

This document provides a comprehensive, step-by-step migration guide for migrating 10 Oracle database schemas from an on-premises Oracle server (100.10.1.101) to PostgreSQL 16 across three distinct target architectures. Each method offers unique advantages and trade-offs in terms of operational overhead, scalability, availability, and cost.

### 1.1 Method Comparison Matrix

| Attribute | Method 1: EC2 | Method 2: RDS | Method 3: Aurora |
|---|---|---|---|
| **Target** | EC2 + Self-managed PG16 | Amazon RDS for PG16 | Aurora PostgreSQL 16 |
| **Target IP / Endpoint** | 10.11.12.9 | rds-instance.region.rds.amazonaws.com | aurora-cluster.cluster-xxx.region.rds.amazonaws.com |
| **OS-Level Access** | Full (SSH) | None | None |
| **Patching / Upgrades** | Manual | AWS-managed | AWS-managed |
| **High Availability** | Manual setup | Multi-AZ option | Built-in (6 copies/3 AZs) |
| **Read Replicas** | Manual streaming rep. | Up to 15 | Up to 15 Aurora replicas |
| **Storage Scaling** | Manual EBS resize | Auto-scaling | Auto-scaling (up to 128 TB) |
| **Backup** | Manual pg_dump / scripted | Automated snapshots | Continuous to S3 |
| **Cost Model** | EC2 + EBS | RDS instance hours | ACU + I/O + storage |
| **Best For** | Full control, custom configs | Managed DB, moderate load | High perf, auto-scaling, HA |

---

## 2. Pre-Migration Assessment (All Methods)

Before starting migration for any method, conduct a thorough assessment of the source Oracle environment. This phase is identical across all three methods and is critical for identifying risks, incompatibilities, and sizing requirements.

### 2.1 Source Environment Discovery

#### 2.1.1 Oracle Database Inventory

Connect to the Oracle source (100.10.1.101) and run the following discovery queries to catalog all 10 schemas:

```sql
-- List all schemas and their sizes
SELECT owner, ROUND(SUM(bytes)/1024/1024/1024, 2) AS size_gb
FROM dba_segments GROUP BY owner ORDER BY size_gb DESC;

-- Count objects per schema
SELECT owner, object_type, COUNT(*) AS obj_count
FROM dba_objects WHERE owner IN (<schema_list>)
GROUP BY owner, object_type ORDER BY owner, object_type;

-- Identify Oracle-specific features in use
SELECT * FROM dba_feature_usage_statistics
WHERE currently_used = 'TRUE';
```

#### 2.1.2 Object Inventory Checklist

| Object Category | Oracle Objects | PostgreSQL Equivalent |
|---|---|---|
| Tables | Heap, IOT, Partitioned, Temp | Regular, Partitioned, UNLOGGED/TEMP |
| Indexes | B-tree, Bitmap, Function-based | B-tree, GIN, GiST, Expression |
| Views | Standard, Materialized | Standard, Materialized |
| Sequences | Oracle Sequences | PostgreSQL Sequences / IDENTITY |
| PL/SQL Code | Packages, Procedures, Functions, Triggers | PL/pgSQL Functions, Triggers |
| Synonyms | Public/Private Synonyms | search_path / Views |
| DB Links | Database Links | postgres_fdw / dblink extension |
| Jobs / Scheduler | DBMS_SCHEDULER, DBMS_JOB | pg_cron, pg_timetable |
| Types | User-defined Object Types, VARRAYs, Nested Tables | Composite types, Arrays, JSONB |

### 2.2 Data Type Mapping Reference

| Oracle Type | PostgreSQL Type | Notes |
|---|---|---|
| VARCHAR2(n) | VARCHAR(n) | Semantics shift: Oracle BYTE vs CHAR; PG always character count |
| NUMBER(p,s) | NUMERIC(p,s) | Direct equivalent. NUMBER without precision maps to NUMERIC or DOUBLE PRECISION |
| DATE | TIMESTAMP(0) | Oracle DATE includes time component; PG DATE does not. Use TIMESTAMP. |
| TIMESTAMP WITH TIME ZONE | TIMESTAMPTZ | Direct equivalent |
| CLOB | TEXT | PG TEXT has no practical limit; no LOB locator overhead |
| BLOB | BYTEA | For large objects, consider pg_largeobject or external storage (S3) |
| RAW(n) | BYTEA | Direct mapping |
| LONG / LONG RAW | TEXT / BYTEA | Deprecated in Oracle; migrate to TEXT/BYTEA |
| XMLTYPE | XML | PG has native XML type with XPath support |
| SDO_GEOMETRY | PostGIS geometry | Requires PostGIS extension; functionally equivalent |
| INTERVAL YEAR TO MONTH | INTERVAL | PG INTERVAL is more flexible |
| BINARY_FLOAT / DOUBLE | REAL / DOUBLE PRECISION | IEEE 754 floating point equivalents |

### 2.3 Network Connectivity Requirements

Establish secure network connectivity between the on-premises environment and AWS before proceeding:

- AWS Direct Connect or Site-to-Site VPN between on-prem datacenter and AWS VPC.
- VPC Security Group rules allowing inbound PostgreSQL (TCP 5432) from migration tools/servers.
- Oracle TNS listener (TCP 1521) accessible from AWS DMS replication instance or migration host.
- AWS Transit Gateway if multiple VPCs are involved.
- DNS resolution for both source (Oracle) and target (PostgreSQL) endpoints confirmed.

### 2.4 AWS Schema Conversion Tool (SCT) Assessment

AWS SCT is the primary tool used across all three methods for schema conversion. Install SCT on a Windows/Linux workstation with network access to both source and target.

1. Download and install AWS SCT from the AWS website. Install the required Oracle JDBC driver (ojdbc8.jar) and PostgreSQL JDBC driver.
2. Create a new project in SCT. Add the Oracle source connection: Host: 100.10.1.101, Port: 1521, SID/Service Name: `<your_sid>`, User: system or a dedicated migration user with DBA privileges.
3. Add the target PostgreSQL connection (varies by method — detailed in each method section).
4. Run the Assessment Report for all 10 schemas. SCT generates a detailed report categorizing objects as: Simple (auto-converted), Medium (minor manual edits), Complex (significant rewrite required).
5. Export the Assessment Report as PDF/CSV for stakeholder review and planning.

---

## 3. Method 1: Migration to EC2 PostgreSQL (Self-Managed)

**Target:** EC2 instance at **10.11.12.9** running self-managed PostgreSQL 16. This method provides full OS-level access and maximum configuration flexibility but requires manual administration of backups, HA, patching, and monitoring.

### 3.1 Target Infrastructure Setup

#### 3.1.1 EC2 Instance Preparation

- **Instance type:** r6i.2xlarge or higher (8 vCPU, 64 GB RAM) recommended for 10 schemas.
- **Storage:** gp3 EBS volumes with provisioned IOPS (minimum 3000 IOPS, 125 MB/s throughput). Size at 2× current Oracle data footprint for initial load headroom.
- **OS:** Amazon Linux 2023 or Ubuntu 22.04 LTS.
- **Networking:** Place in a private subnet within your VPC. Ensure Security Group allows inbound TCP 5432 from DMS replication instance subnet and application subnets.

#### 3.1.2 PostgreSQL 16 Installation and Configuration

```bash
# SSH to 10.11.12.9
sudo dnf install -y postgresql16-server postgresql16-contrib
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
sudo systemctl enable --now postgresql-16
```

**Key `postgresql.conf` tuning parameters for migration workload:**

```ini
shared_buffers = 16GB              # 25% of RAM
effective_cache_size = 48GB         # 75% of RAM
work_mem = 256MB                    # For sort/hash during migration
maintenance_work_mem = 2GB          # For CREATE INDEX, VACUUM
wal_level = replica                 # Required for replication
max_wal_size = 4GB                  # Reduce WAL cycling during bulk load
checkpoint_completion_target = 0.9
max_connections = 200
logging_collector = on
log_min_duration_statement = 1000   # Log slow queries > 1s
```

**`pg_hba.conf` — allow DMS and application access:**

```
# DMS replication instance subnet
host  all  all  10.0.0.0/16  scram-sha-256
# Application subnet
host  all  all  10.1.0.0/16  scram-sha-256
```

#### 3.1.3 Create Target Schemas and Roles

```sql
-- Create a database for each schema or a single database with schemas
CREATE DATABASE appdb;
\c appdb

-- Create schemas matching Oracle schemas
CREATE SCHEMA schema1; CREATE SCHEMA schema2; -- ... through schema10

-- Create migration user with full privileges
CREATE ROLE migration_user LOGIN PASSWORD 'StrongP@ss!' SUPERUSER;
GRANT ALL ON SCHEMA schema1, schema2 /*, ... */ TO migration_user;
```

### 3.2 Schema Conversion (EC2)

#### 3.2.1 SCT Conversion Process

1. In AWS SCT, connect to target: Host: 10.11.12.9, Port: 5432, Database: appdb, User: migration_user.
2. Select all 10 source Oracle schemas in the left panel. Right-click and choose **'Convert Schema'**.
3. Review each converted object in the right panel. SCT highlights items needing manual intervention with orange/red indicators.
4. For each schema, apply converted DDL to the target by right-clicking the target schema and selecting **'Apply to database'**.

#### 3.2.2 Manual Conversion Tasks

The following Oracle constructs require manual conversion for PostgreSQL:

| Oracle Construct | PostgreSQL Conversion Approach |
|---|---|
| PL/SQL Packages | Split into individual PL/pgSQL functions. Package-level variables become session variables (SET/SHOW) or table-backed state. |
| CONNECT BY (Hierarchical) | Rewrite using WITH RECURSIVE common table expressions (CTEs). |
| Oracle Sequences (CURRVAL/NEXTVAL) | PostgreSQL sequences with currval()/nextval(). Adjust CACHE, MINVALUE, START WITH values. |
| DECODE() | Replace with CASE WHEN ... THEN ... ELSE ... END. |
| NVL() / NVL2() | Replace with COALESCE() or CASE expressions. |
| SYSDATE | Replace with CURRENT_TIMESTAMP or NOW(). |
| ROWNUM | Replace with LIMIT/OFFSET or ROW_NUMBER() OVER(). |
| Outer Join (+) syntax | Convert to ANSI LEFT/RIGHT JOIN syntax. |
| Bitmap Indexes | Replace with GIN indexes on expressions or use partial indexes. |
| Materialized View Refresh | Use REFRESH MATERIALIZED VIEW CONCURRENTLY; schedule with pg_cron. |
| Global Temporary Tables | Use CREATE TEMP TABLE in functions or ON COMMIT DELETE ROWS/PRESERVE ROWS. |
| DBMS_OUTPUT | Use RAISE NOTICE for debug output. |
| Autonomous Transactions | Use dblink to self for separate transaction context, or redesign logic. |

### 3.3 Data Migration (EC2)

#### 3.3.1 Using AWS DMS

1. Create a DMS Replication Instance (dms.r5.2xlarge recommended) in the same VPC/subnet as the EC2 target.
2. Create Source Endpoint: Engine = Oracle, Server = 100.10.1.101, Port = 1521, User = dms_user (grant SELECT on all source schemas, plus supplemental logging).
3. Create Target Endpoint: Engine = PostgreSQL, Server = 10.11.12.9, Port = 5432, Database = appdb, User = migration_user.
4. Test both endpoint connections from the replication instance.

**Oracle source preparation for DMS:**

```sql
-- Enable supplemental logging (required for CDC)
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- Grant DMS user privileges
GRANT SELECT ANY TABLE TO dms_user;
GRANT SELECT ON ALL_TABLES TO dms_user;
GRANT SELECT ON ALL_VIEWS TO dms_user;
GRANT SELECT_CATALOG_ROLE TO dms_user;
GRANT EXECUTE ON DBMS_LOGMNR TO dms_user;
GRANT SELECT ON V_$LOG TO dms_user;
GRANT SELECT ON V_$LOGFILE TO dms_user;
GRANT SELECT ON V_$ARCHIVED_LOG TO dms_user;
GRANT LOGMINING TO dms_user;  -- Oracle 12c+
```

#### 3.3.2 DMS Task Configuration

Create a DMS Migration Task with the following settings:

| Setting | Value |
|---|---|
| Migration Type | Migrate existing data and replicate ongoing changes (Full Load + CDC) |
| Table Mappings | Include all 10 schemas using selection rules: schema-name = SCHEMA1, SCHEMA2, ..., SCHEMA10 |
| LOB Mode | Limited LOB mode (set max LOB size = 32KB for initial speed; use Full LOB for LOB-heavy schemas) |
| Target Table Prep | Truncate (if SCT already created tables) or Do Nothing |
| Enable Validation | Yes — enable data validation for row count and column-level comparison |
| Parallel Load | Enable parallel load for tables > 1M rows using range partitioning on PK |
| Batch Apply | Enable for CDC phase to improve throughput |

#### 3.3.3 Alternative: ora2pg for Full Control

For teams preferring open-source tooling with maximum control over conversion and data export, ora2pg is an excellent alternative:

```bash
# Install ora2pg on the EC2 instance or a migration bastion host
sudo apt install ora2pg  # or build from source

# Generate configuration
ora2pg --project_base /home/migration --init_project my_migration

# Edit ora2pg.conf:
# ORACLE_DSN=dbi:Oracle:host=100.10.1.101;sid=ORCL;port=1521
# ORACLE_USER=migration_user
# SCHEMA=SCHEMA1 SCHEMA2 ... SCHEMA10
# PG_DSN=dbi:Pg:dbname=appdb;host=10.11.12.9;port=5432
# TYPE=TABLE,VIEW,SEQUENCE,FUNCTION,PROCEDURE,TRIGGER,PACKAGE,DATA

# Export schema (DDL)
ora2pg -t TABLE -o tables.sql -c ora2pg.conf
ora2pg -t FUNCTION -o functions.sql -c ora2pg.conf
ora2pg -t PROCEDURE -o procedures.sql -c ora2pg.conf
ora2pg -t PACKAGE -o packages.sql -c ora2pg.conf
ora2pg -t TRIGGER -o triggers.sql -c ora2pg.conf

# Export data (parallel workers for speed)
ora2pg -t DATA -o data.sql -c ora2pg.conf -j 4 -J 4
```

### 3.4 Post-Migration on EC2

1. **Re-create indexes** that were dropped during load: Run the saved index DDL scripts from SCT or ora2pg.
2. **Re-enable constraints:** `ALTER TABLE ... ENABLE TRIGGER ALL;` re-add foreign keys that were deferred.
3. **Re-create sequences:** Ensure sequence current values match Oracle LAST_NUMBER: `SELECT setval('schema1.seq_name', (SELECT MAX(id) FROM schema1.table_name));`
4. **ANALYZE all tables:** `ANALYZE;` (or run `VACUUM ANALYZE schema1.table_name` for each table).
5. **Set up pg_cron** for materialized view refreshes and maintenance tasks.
6. **Configure streaming replication** to a standby EC2 instance for HA (if required).
7. **Set up monitoring:** Install pg_stat_statements, configure CloudWatch agent for OS metrics, and set up pgBadger for log analysis.

---

## 4. Method 2: Migration to Amazon RDS PostgreSQL

**Target:** Amazon RDS for PostgreSQL 16. This method leverages AWS-managed infrastructure for automated backups, patching, Multi-AZ failover, and read replicas, reducing operational burden significantly compared to self-managed EC2.

### 4.1 RDS Instance Provisioning

#### 4.1.1 Instance Configuration

| Parameter | Recommended Value |
|---|---|
| Engine | PostgreSQL 16.x (latest minor) |
| Instance Class | db.r6g.2xlarge (8 vCPU, 64 GB) or db.r6i.2xlarge for compute-heavy workloads |
| Storage Type | gp3, 1000 GB initial (auto-scaling enabled, max 2000 GB) |
| Provisioned IOPS | 3000 IOPS / 125 MB/s throughput (increase during migration, reduce after) |
| Multi-AZ | Yes (enable after migration for HA; disable during initial load for faster writes) |
| VPC / Subnet Group | Private subnets in your migration VPC; DB subnet group spanning 2+ AZs |
| Security Group | Allow inbound TCP 5432 from DMS replication instance SG and application SG |
| Parameter Group | Custom parameter group (see tuning below) |
| Backup Retention | 7 days (increase to 35 for production) |
| Encryption | Enabled (KMS key) |
| Monitoring | Enhanced Monitoring: 15-second granularity; Performance Insights: Enabled |

#### 4.1.2 Custom Parameter Group for Migration

Create a custom RDS parameter group and set these parameters to optimize for the bulk migration phase:

```ini
shared_buffers = {DBInstanceClassMemory/4}    # 25% of instance memory
effective_cache_size = {DBInstanceClassMemory*3/4}
work_mem = 262144                              # 256MB
maintenance_work_mem = 2097152                 # 2GB
max_wal_size = 4096                            # 4GB
checkpoint_completion_target = 0.9
wal_buffers = 64MB
random_page_cost = 1.1                        # SSD storage
log_min_duration_statement = 1000              # Log slow queries
```

After migration completes, reduce `work_mem` and `maintenance_work_mem` to production values and reboot the instance.

#### 4.1.3 RDS Extensions

Enable required PostgreSQL extensions:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_trgm;            -- If trigram searches needed
CREATE EXTENSION IF NOT EXISTS postgis;             -- If spatial data exists
CREATE EXTENSION IF NOT EXISTS pg_cron;             -- For scheduled jobs
CREATE EXTENSION IF NOT EXISTS pgaudit;             -- For audit logging
CREATE EXTENSION IF NOT EXISTS aws_s3;              -- For S3 import/export
```

### 4.2 Schema Conversion (RDS)

The schema conversion process for RDS is identical to EC2 (Section 3.2), with one key difference: connect SCT to the RDS endpoint instead of the EC2 IP address. In the SCT target connection, use the RDS endpoint hostname (e.g., `mydb.xxxx.us-east-1.rds.amazonaws.com`), port 5432, and the master username.

All manual PL/SQL-to-PL/pgSQL conversion tasks from Section 3.2.2 apply equally to RDS.

### 4.3 Data Migration (RDS)

#### 4.3.1 DMS to RDS — Key Differences from EC2

The DMS setup follows the same pattern as Section 3.3, with these RDS-specific considerations:

- **Target Endpoint:** Use the RDS writer endpoint as the server name, not an IP address.
- **IAM Integration:** DMS can authenticate to RDS using IAM database authentication if preferred over password auth.
- **Enhanced Monitoring:** Enable Performance Insights on the RDS instance to monitor migration workload impact in real-time.
- **Multi-AZ Impact:** Disable Multi-AZ during the full load phase to avoid synchronous replication overhead. Re-enable after full load completes and before cutover.
- **Storage Auto-Scaling:** Ensure auto-scaling is enabled so the instance storage grows automatically during data load.

#### 4.3.2 Alternative: S3 as Staging Area

For very large datasets (> 500 GB), consider exporting Oracle data to CSV files, uploading to S3, and loading into RDS using aws_s3 extension:

```sql
-- On the RDS instance, load from S3
SELECT aws_s3.table_import_from_s3(
   'schema1.customers',          -- target table
   'id, name, email, created_at', -- columns
   '(FORMAT csv, HEADER true)',   -- options
   aws_commons.create_s3_uri(
     'my-migration-bucket',
     'exports/schema1/customers.csv',
     'us-east-1'
   )
);
```

### 4.4 RDS-Specific Post-Migration

1. **Enable Multi-AZ:** Modify the instance to enable Multi-AZ deployment for automatic failover.
2. **Create Read Replicas:** If read scaling is needed, create 1–2 read replicas in different AZs.
3. **Set up RDS Event Subscriptions:** SNS notifications for failover events, maintenance windows, and storage capacity warnings.
4. **Configure Automated Backups:** Increase backup retention to 35 days; set the backup window to a low-traffic period.
5. **Enable RDS Proxy:** If the application has many short-lived connections, RDS Proxy provides connection pooling.
6. **VACUUM ANALYZE:** Run ANALYZE on all tables; configure auto-vacuum thresholds in the parameter group.

---

## 5. Method 3: Migration to Amazon Aurora PostgreSQL

**Target:** Amazon Aurora PostgreSQL-Compatible 16. Aurora provides a cloud-native architecture with distributed storage (6 copies across 3 AZs), automatic failover in under 30 seconds, up to 128 TB auto-scaling storage, and up to 15 low-latency read replicas. It is the highest-availability, highest-performance option.

### 5.1 Aurora Cluster Provisioning

#### 5.1.1 Cluster Configuration

| Parameter | Recommended Value |
|---|---|
| Engine | Aurora PostgreSQL-Compatible, version 16.x |
| Cluster Type | Provisioned (for predictable migration workloads; consider Serverless v2 post-migration) |
| Writer Instance | db.r6g.2xlarge (scale up during migration, scale down after) |
| Reader Instance(s) | Add 1 reader instance post-migration; start with writer only during load |
| Storage | Auto-managed (starts at 10 GB, scales to 128 TB; no provisioning needed) |
| VPC / Subnet Group | DB subnet group spanning 3 AZs for Aurora distributed storage |
| Security Group | Allow TCP 5432 from DMS replication instance SG and application SG |
| Cluster Parameter Group | Custom Aurora PG 16 cluster parameter group |
| Instance Parameter Group | Custom Aurora PG 16 DB parameter group |
| Encryption | Enabled (KMS; must be set at creation, cannot be changed later) |
| Backtrack | Enable with 24-hour window (Aurora-specific feature for point-in-time rewind) |
| Performance Insights | Enabled with 7-day retention |

#### 5.1.2 Aurora-Specific Parameter Tuning

Aurora manages many storage-layer parameters automatically. Focus on these:

```ini
# Cluster parameter group (applies to all instances)
shared_preload_libraries = 'pg_stat_statements,pg_cron'

# Instance parameter group (writer)
work_mem = 262144
maintenance_work_mem = 2097152
random_page_cost = 1.1
effective_cache_size = {DBInstanceClassMemory*3/4}
log_min_duration_statement = 1000
```

> **Note:** Aurora does not use `max_wal_size` or checkpoint settings (storage layer handles WAL). `shared_buffers` is automatically managed based on instance size.

### 5.2 Schema Conversion (Aurora)

The schema conversion process is identical to the EC2 and RDS methods (Sections 3.2 and 4.2). In SCT, connect to the Aurora cluster writer endpoint. Aurora supports the same extensions as RDS, plus Aurora-specific features like Babelfish (if T-SQL compatibility is needed for future SQL Server migrations) and Aurora Machine Learning integration.

### 5.3 Data Migration (Aurora)

#### 5.3.1 DMS to Aurora — Key Differences

- **Target Endpoint:** Use the Aurora cluster writer endpoint (`aurora-cluster.cluster-xxxx.region.rds.amazonaws.com`).
- **Fast Failover Aware:** DMS automatically handles Aurora failover events during CDC phase.
- **No Multi-AZ Toggle:** Aurora storage is always distributed across 3 AZs; no need to disable/enable.
- **Higher Write Throughput:** Aurora distributed storage provides 2× write throughput compared to standard RDS, making full load phase faster.
- **Clone for Testing:** After full load, create an Aurora clone (near-instant, zero-copy) for validation without impacting the migration target.

#### 5.3.2 Aurora-Specific: Snapshot Migration Path

If you first migrate to RDS PostgreSQL and later want to move to Aurora, you can take a snapshot of the RDS instance and restore it as an Aurora cluster. This avoids re-running the full migration:

```bash
aws rds create-db-cluster \
  --db-cluster-identifier my-aurora-cluster \
  --engine aurora-postgresql \
  --engine-version 16.1 \
  --source-db-snapshot-identifier rds-snapshot-id \
  --vpc-security-group-ids sg-xxxxxx \
  --db-subnet-group-name my-db-subnet-group
```

### 5.4 Aurora-Specific Post-Migration

1. **Add Reader Instances:** Add 1–2 Aurora reader instances for read scaling and HA failover.
2. **Configure Custom Endpoints:** Create a reader endpoint for analytics workloads, separate from the writer endpoint.
3. **Enable Aurora Global Database:** If cross-region DR is required, promote the cluster to a global database.
4. **Consider Serverless v2:** For variable workloads, add a Serverless v2 reader that auto-scales ACUs.
5. **Backtrack Testing:** Test Backtrack by intentionally running a destructive query and rewinding to validate recovery.
6. **VACUUM ANALYZE:** Same as RDS — run ANALYZE on all tables and tune auto-vacuum.

---

## 6. Data Validation (All Methods)

Data validation is the most critical phase of any migration. It must be thorough, automated, and repeatable. The following validation framework applies to all three target methods.

### 6.1 Row Count Validation

Compare row counts between Oracle source and PostgreSQL target for every table across all 10 schemas:

```sql
-- Oracle (source): Generate row counts
SELECT owner || '.' || table_name AS table_fqn,
       num_rows FROM dba_tables
WHERE owner IN ('SCHEMA1','SCHEMA2', ..., 'SCHEMA10')
ORDER BY owner, table_name;

-- PostgreSQL (target): Generate row counts
SELECT schemaname || '.' || relname AS table_fqn,
       n_live_tup FROM pg_stat_user_tables
WHERE schemaname IN ('schema1','schema2', ..., 'schema10')
ORDER BY schemaname, relname;
```

Automate comparison with a Python/shell script that queries both databases and flags mismatches. A tolerance of 0 rows difference should be the target for all non-CDC tables.

### 6.2 Data Integrity Validation

#### 6.2.1 Checksum Comparison

For critical tables, compute row-level checksums:

```sql
-- Oracle
SELECT ORA_HASH(col1 || col2 || col3) AS row_hash, id
FROM schema1.critical_table ORDER BY id;

-- PostgreSQL
SELECT md5(col1::text || col2::text || col3::text) AS row_hash, id
FROM schema1.critical_table ORDER BY id;
```

#### 6.2.2 Boundary Value Testing

- **NULL handling:** Oracle treats empty string as NULL; PostgreSQL distinguishes them. Query: `SELECT COUNT(*) WHERE col IS NULL` vs `WHERE col = ''`.
- **Date precision:** Compare TIMESTAMP values to ensure sub-second precision is preserved.
- **CLOB/TEXT fields:** Compare first 4000 characters and total length for CLOB-to-TEXT conversions.
- **Numeric precision:** Compare NUMERIC columns to ensure scale/precision is maintained.
- **Character encoding:** Verify UTF-8 encoding of special characters, accented characters, and emoji.

### 6.3 Schema Validation

- **Constraint Verification:** Compare constraint counts (PRIMARY KEY, UNIQUE, FOREIGN KEY, CHECK) between source and target.
- **Index Verification:** Ensure all functional indexes, partial indexes, and unique indexes exist on the target.
- **Sequence Values:** Verify sequence current values match source LAST_NUMBER values.
- **Trigger Validation:** Verify trigger count and ensure trigger functions compile without errors.
- **View Definitions:** Execute all views and compare result sets with Oracle views.
- **Stored Procedure Testing:** Execute all migrated PL/pgSQL functions with known inputs and compare outputs to Oracle PL/SQL.

### 6.4 Application-Level Validation

Beyond database-level checks, validate the application layer:

- Run the full application test suite against the PostgreSQL target.
- Execute critical business workflows end-to-end (order placement, payment processing, reporting).
- Compare API response payloads between Oracle-backed and PostgreSQL-backed environments.
- Validate report outputs by comparing Oracle-generated vs PostgreSQL-generated reports.
- Performance baseline: Run key queries and compare execution times against Oracle benchmarks.

### 6.5 DMS Validation Reports

AWS DMS provides built-in validation. After the full load phase, review:

- **Table Statistics Tab:** Shows rows loaded, inserts applied, errors encountered per table.
- **Validation Status:** GREEN = all rows match, YELLOW = pending validation, RED = mismatches detected.
- **Error Log:** Check `awsdms_validation_failures` table on the target for specific row-level mismatches.
- **CDC Lag Metrics:** CloudWatch `ChangeProcessingLatency` should be < 5 seconds for cutover readiness.

---

## 7. Cutover Planning (All Methods)

Cutover is the final, highest-risk phase. A well-planned cutover minimizes downtime and provides clear rollback paths. The following plan applies to all three methods with method-specific notes where applicable.

### 7.1 Cutover Prerequisites Checklist

| Prerequisite | Status Required |
|---|---|
| Schema conversion complete (all 10 schemas) | Verified |
| Full load complete with 0 errors | Verified |
| CDC replication active with < 5s latency | Verified |
| Row count validation passed (all tables) | 100% pass |
| Data integrity validation passed (critical tables) | 100% pass |
| Application test suite passed against target | 100% pass |
| Performance benchmarks acceptable | Within 20% of baseline |
| Rollback plan documented and rehearsed | Documented |
| Stakeholder sign-off obtained | Signed |
| Maintenance window communicated to users | Communicated |
| DNS/connection string changes prepared | Ready |
| Monitoring and alerting configured on target | Active |

### 7.2 Cutover Timeline (Sample: 2-Hour Window)

| Time | Action | Owner |
|---|---|---|
| T-24h | Final validation dry run; confirm CDC lag is < 5s; notify stakeholders of go/no-go | DBA / PM |
| T-2h | Disable all application batch jobs and scheduled tasks on Oracle | App Team |
| T-0 (Start) | Stop application servers; confirm zero active transactions on Oracle | App Team |
| T+5 min | Wait for DMS CDC to drain. Verify CDCLatency = 0 in CloudWatch | DBA |
| T+10 min | Stop DMS replication task. Perform final row count validation | DBA |
| T+15 min | Re-enable foreign keys, triggers, and constraints on target | DBA |
| T+20 min | Reset sequences on target to MAX(id) + buffer (100) | DBA |
| T+25 min | Run VACUUM ANALYZE on all target tables | DBA |
| T+35 min | Update application connection strings to point to PostgreSQL target | DevOps |
| T+40 min | Start application servers; begin smoke testing | App/QA |
| T+60 min | Complete smoke tests and critical business workflow validation | QA |
| T+75 min | Declare GO / NO-GO for production traffic. If NO-GO, execute rollback plan | PM / DBA |
| T+90 min | Enable batch jobs and schedulers on PostgreSQL (pg_cron) | DBA |
| T+120 min | Cutover complete. Monitor for 24 hours. Set Oracle to read-only for 7-day fallback | All |

### 7.3 Method-Specific Cutover Notes

#### 7.3.1 EC2 Cutover Specifics

- Connection string update: Change application JDBC/ODBC URLs to `jdbc:postgresql://10.11.12.9:5432/appdb`.
- If using PgBouncer for connection pooling (recommended), point applications to PgBouncer port (6432) and PgBouncer to PostgreSQL (5432).
- No built-in failover — ensure streaming replication standby is in sync before cutover if HA is required.

#### 7.3.2 RDS Cutover Specifics

- Enable Multi-AZ before cutover if not already done.
- Connection string: Use the RDS writer endpoint (`mydb.xxxx.region.rds.amazonaws.com:5432/appdb`).
- Consider enabling RDS Proxy for automatic connection pooling and failover-transparent connection management.
- Take a manual snapshot immediately after cutover for a clean recovery point.

#### 7.3.3 Aurora Cutover Specifics

- Connection strings: Writer endpoint for read-write, Reader endpoint for read-only workloads.
- Aurora failover is automatic (< 30 seconds) — no additional HA setup needed.
- Create an Aurora clone immediately before cutover for instant rollback capability.
- If using Aurora Global Database, ensure secondary region is caught up before declaring success.

### 7.4 Rollback Plan

Every migration must have a documented rollback procedure. The rollback strategy depends on the method:

| Method | Rollback Strategy |
|---|---|
| EC2 PostgreSQL | Reverse DMS task (PG → Oracle) pre-configured and tested. Keep Oracle running read-only for 7 days post-cutover. Revert connection strings to Oracle and re-enable Oracle as primary. |
| RDS PostgreSQL | Same reverse DMS strategy. Additionally, restore from pre-cutover RDS snapshot if data corruption is detected. Oracle remains read-only for 7-day fallback period. |
| Aurora PostgreSQL | Aurora Backtrack: Rewind the cluster to the pre-cutover timestamp (instant, no data loss). Alternatively, promote a pre-cutover Aurora clone. Oracle remains read-only for 7-day fallback. |

---

## 8. Post-Migration Optimization and Monitoring

### 8.1 Performance Tuning

- Run `pg_stat_statements` analysis to identify the top 20 slowest queries. Optimize with `EXPLAIN ANALYZE`.
- Review missing indexes using `pg_stat_user_tables` (seq_scan counts) and create indexes for frequently scanned columns.
- Tune auto-vacuum: Set `autovacuum_vacuum_scale_factor = 0.05` and `autovacuum_analyze_scale_factor = 0.02` for large tables.
- Connection pooling: PgBouncer (EC2) or RDS Proxy (RDS/Aurora) to reduce connection overhead.
- Query plan comparison: Compare Oracle `EXPLAIN PLAN` with PostgreSQL `EXPLAIN ANALYZE` for critical queries.

### 8.2 Monitoring Setup

| Metric | Tool | Alert Threshold |
|---|---|---|
| CPU Utilization | CloudWatch (RDS/Aurora) / CW Agent (EC2) | > 80% sustained for 15 min |
| Free Storage | CloudWatch / OS monitoring | < 20% remaining |
| Replication Lag | CloudWatch ReplicaLag | > 30 seconds |
| Connection Count | pg_stat_activity | > 80% of max_connections |
| Long-Running Queries | pg_stat_activity | > 300 seconds |
| Dead Tuples | pg_stat_user_tables | > 10% of n_live_tup |
| Transaction Wraparound | age(datfrozenxid) | > 500 million |

### 8.3 Decommission Oracle Source

After a successful stabilization period (recommended 7–30 days), decommission the Oracle source:

1. Keep Oracle in read-only mode for the full stabilization period.
2. Take a final Oracle RMAN full backup and archive to cold storage (e.g., AWS S3 Glacier).
3. Export Oracle DDL and configuration for reference using Data Pump: `expdp schemas=SCHEMA1,...,SCHEMA10 dumpfile=final_backup.dmp`.
4. Shut down Oracle listener and database instance.
5. Revoke VPN/Direct Connect firewall rules allowing traffic to 100.10.1.101.
6. Terminate Oracle license subscriptions after contractual obligations are met.
7. Update CMDB, runbooks, and architecture diagrams to reflect the new PostgreSQL environment.

---

## 9. Risk Register and Mitigation

| Risk | Impact | Mitigation | Owner |
|---|---|---|---|
| PL/SQL conversion errors | Application failures | Unit test all converted functions; parallel run Oracle and PG | Dev Team |
| Data type mismatches | Data loss / truncation | Thorough data type mapping review; boundary value testing | DBA |
| Network latency / instability | Slow migration, CDC lag | Direct Connect with redundancy; dedicated migration subnet | Network Team |
| Oracle license audit triggered | Compliance risk | Engage Oracle licensing team early; document decommission timeline | Procurement |
| Performance regression on PG | User experience degradation | Performance benchmarking before cutover; query optimization sprint | DBA / Dev |
| NULL/empty string differences | Application logic errors | Application code audit for NULL handling; add COALESCE where needed | Dev Team |
| Sequence value gaps | Duplicate key errors | Set sequences to MAX(id) + 1000 buffer at cutover | DBA |
| Extended downtime during cutover | Business disruption | Rehearse cutover 3× in staging; maintain rollback plan | PM / DBA |

---

## Appendix A: Tool Versions and References

| Tool | Version | Purpose |
|---|---|---|
| AWS SCT | Latest (update before migration) | Schema assessment and conversion |
| AWS DMS | 3.5.x+ | Data replication (full load + CDC) |
| ora2pg | 24.x+ | Open-source schema/data migration |
| Oracle Instant Client | 21c | Oracle connectivity for DMS/SCT/ora2pg |
| PostgreSQL | 16.x (latest minor) | Target database |
| pgBadger | 12.x | PostgreSQL log analysis |
| PgBouncer | 1.21+ | Connection pooling (EC2 method) |
