Here are 50 key PostgreSQL on-premises DBA interview questions

### PostgreSQL On-Prem DBA Interview Questions and Solutions

#### General Administration & Architecture
1. **How do you install PostgreSQL on Linux?**  
   Use package manager: `sudo apt install postgresql` (Debian/Ubuntu) or `sudo yum install postgresql-server` (RHEL/CentOS), then initialize the DB cluster and start the service.

2. **How do you start and stop a PostgreSQL server?**  
   Use `systemctl start postgresql` and `systemctl stop postgresql`, or `pg_ctl start -D /data_dir` and `pg_ctl stop -D /data_dir`.

3. **How do you check if PostgreSQL server is running?**  
   Try `systemctl status postgresql` or connect using `psql` and run `SELECT version();`.

4. **Explain PostgreSQL process architecture.**  
   One master (postmaster), which spawns one process per client connection. On Linux, each backend is a system process.

5. **Where are the PostgreSQL configuration files kept?**  
   Typically, in the data directory (e.g., `/var/lib/pgsql/data`), including `postgresql.conf`, `pg_hba.conf`, and `pg_ident.conf`.

#### User and Access Management
6. **How do you create a user/role in PostgreSQL?**  
   `CREATE ROLE user1 WITH LOGIN PASSWORD 'pass';`

7. **How do you grant/revoke privileges?**  
   `GRANT SELECT ON tablename TO user1;` / `REVOKE SELECT ON tablename FROM user1;`

8. **Difference between a role and a user?**  
   Both are roles; users have LOGIN privilege while roles may not.

9. **How do you enforce password policies?**  
   Use authentication methods in `pg_hba.conf` and extensions (e.g., passwordcheck).

#### Backup and Recovery
10. **Types of backups in PostgreSQL?**  
    Logical (pg_dump, pg_dumpall), physical (`pg_basebackup`, filesystem copy), Point-In-Time Recovery (PITR) using WALs.

11. **How do you perform a logical backup?**  
    Example: `pg_dump dbname > backup.sql`.

12. **How do you restore a logical backup?**  
    Example: `psql dbname < backup.sql`.

13. **How do you take a physical backup?**  
    Use `pg_basebackup` for hot backup or file-level copy with database shut down.

14. **What is Point-In-Time Recovery (PITR)?**  
    Restore from base backup, then replay archived WALs up to a specific time.

15. **How do you perform PITR?**  
    Restore base backup, add WAL files to pg_wal (pg_xlog), set `recovery_target_time` in recovery config, and start PostgreSQL.

#### Performance Tuning
16. **What are important performance configuration parameters?**  
    `shared_buffers`, `work_mem`, `maintenance_work_mem`, `effective_cache_size`, `max_connections`, `checkpoint_segments`.

17. **How to analyze a slow query?**  
    Use `EXPLAIN ANALYZE` to see the execution plan and timings.

18. **How do you identify slow queries globally?**  
    Enable and query `pg_stat_statements` extension.

19. **How do you improve query performance?**  
    Add appropriate indexes, rewrite inefficient queries, and ensure up-to-date statistics.

20. **Describe autovacuum and why it is important.**  
    Cleans up dead rows, prevents table bloat, and maintains visibility maps and statistics.

21. **How do you manually vacuum and analyze a table?**  
    `VACUUM tablename;` and `ANALYZE tablename;`.

#### Replication and High Availability
22. **Explain streaming replication.**  
    Real-time replication of WAL data from primary to standby server over the network.

23. **Prerequisites for streaming replication?**  
    Both servers must have compatible versions, standby must access WALs, configure `wal_level=replica`, set `max_wal_senders`, etc.

24. **How do you monitor replication lag?**  
    Query `pg_stat_replication` view for `replay_lsn`, `write_lsn`, and `pg_wal_lsn_diff`.

25. **How do you failover to a standby?**  
    Promote standby using `pg_ctl promote`, redirect application traffic, ensure old primary does not accept writes.

26. **How to avoid WAL file loss for standby?**  
    Use `archive_mode=on` and set ample `wal_keep_segments`, or configure WAL archiving.

#### Troubleshooting
27. **How to trace connection problems?**  
    Check logs, confirm listener IP and port, and review `pg_hba.conf` access rules.

28. **What is a common cause of “FATAL: Too many connections”?**  
    `max_connections` exceeded; reduce client connections, use pooling, or increase the parameter.

29. **How to detect database corruption?**  
    Review logs, run `pg_checksums`, or spot unexpectedly failed queries.

30. **How do you recover from data corruption?**  
    Restore from backups, try to salvage individual tables, or reinitialize the database as needed.

#### Maintenance
31. **How to schedule regular maintenance tasks?**  
    Use cron jobs for scripts or tools (VACUUM, backups) and monitoring.

32. **Explain the purpose of the Visibility Map.**  
    Tracks which pages have only frozen tuples, allowing index-only scans and efficient vacuuming.

33. **How do you monitor table and index bloat?**  
    Use queries on `pg_stat_user_tables` and `pg_stat_user_indexes`, third-party tools like `pgstattuple`.

34. **How do you reduce bloat?**  
    Regular vacuuming, `VACUUM FULL`, or recreating tables/indexes.

35. **How to upgrade PostgreSQL in-place?**  
    Use `pg_upgrade` after installing the new version binaries; always test on a copy first.

#### Data Security
36. **How to enforce SSL connections?**  
    Set `ssl=on` in `postgresql.conf`, configure certificates, and enforce SSL in `pg_hba.conf`.

37. **What is row-level security and how to set it up?**  
    Enable via `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`, then create policies with `CREATE POLICY`.

38. **How do you audit data access?**  
    Use logging in `postgresql.conf` (`log_statement`, `log_connections`), or use audit extensions like `pgaudit`.

#### Data Types and Functions
39. **How to store large binary data?**  
    Use `BYTEA` data type or large objects (LO).

40. **How to add a column with a default value to a huge table?**  
    Add the column first, then update in batches, finally set the default.

41. **What is the difference between TEXT and VARCHAR?**  
    Both store variable-length strings; VARCHAR can have a length constraint.

42. **Name functions to convert strings to and from date/time.**  
    `TO_DATE`, `TO_TIMESTAMP`, `TO_CHAR`, `CAST`.

#### SQL Scenarios and Advanced Topics
43. **How to find the size of a database?**  
    `SELECT pg_size_pretty(pg_database_size('dbname'));`

44. **How to find the largest tables?**  
    Query `pg_total_relation_size` on user tables.

45. **How do you kill a long-running query?**  
    Find PID with `pg_stat_activity`, kill it with `SELECT pg_terminate_backend(pid);`

46. **How to perform zero-downtime schema changes?**  
    Use rolling deployment, break changes into additive steps, use feature flags.

47. **How do you migrate a large database from MySQL to PostgreSQL?**  
    Export schema/data from MySQL, convert schema using tools (e.g., `pgloader`), then import into PostgreSQL.

48. **How to mask sensitive data in staging?**  
    Use `UPDATE` queries to replace data, or generate test data for masking columns.

49. **How to benchmark database performance?**  
    Use `pgbench` and monitor system metrics; adjust server parameters accordingly.

50. **How to monitor database health and availability?**  
    Use internal views (`pg_stat_activity`, `pg_stat_replication`), external tools (Nagios, Zabbix), and alerting scripts.


[20] https://www.geeksforgeeks.org/interview-experiences/database-interview-questions/
