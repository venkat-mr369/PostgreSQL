PostgreSQL AWS RDS interview questions

### 1. Explain the difference between AWS RDS PostgreSQL and self-managed PostgreSQL on EC2.

**Answer:**  
AWS RDS PostgreSQL is a managed service, so AWS automates backups, patching, monitoring, scaling, and failover. 
You don’t have OS-level access. With self-managed PostgreSQL on EC2, you control the OS, storage, network, database configuration, extensions, monitoring, and backups, but also bear full operational responsibility, including upgrades, failover, HA, and backups.

### 2. How does RDS handle failover and what is Multi-AZ deployment?

**Answer:**  
In Multi-AZ mode, RDS maintains a synchronous standby in a different Availability Zone. On hardware, storage, or network failure, RDS automatically switches the DNS to the standby, typically within a minute or two. The application must reconnect, but no manual intervention is required. Only the primary is writable; the standby is not accessible for reads.

### 3. What are Read Replicas in RDS PostgreSQL? How do they differ from Multi-AZ?

**Answer:**  
Read Replicas are asynchronous copies of the primary that can serve read-only traffic and support scaling out reads, e.g., reporting or API requests. They can also be promoted to standalone databases for DR or migration. Multi-AZ is for HA of writes, not scaling. Read Replicas can lag behind the primary; Multi-AZ is synchronous.

### 4. How would you migrate on-prem PostgreSQL to AWS RDS with minimal downtime?

**Answer:**  
First, use the AWS Database Migration Service (DMS) or native logical replication to create a replica on AWS. Synchronize until caught up, then cut over during a maintenance window by switching the application to the RDS endpoint. The original must allow replication connections. DMS can handle heterogeneous or homogeneous migrations; logical replication requires version compatibility.

### 5. Can you explain RDS parameter groups and option groups?

**Answer:**  
Parameter groups are collections of PostgreSQL configuration settings (like postgresql.conf) that apply to a DB instance. Modifying a parameter group changes database behavior after a reboot if dynamic parameters are set. Option groups control optional features/extensions, for example, pgAudit or Oracle SQL extensions, and are particularly important for some workloads.

### 6. How does automated backup work in RDS? Where are backups stored?

**Answer:**  
Automated backups capture a daily snapshot and archive transaction logs to Amazon S3, allowing point-in-time recovery (PITR) within the retention window (up to 35 days). Snapshots are incremental after the first full backup. They are stored in S3, managed and encrypted by AWS, invisible to users.

### 7. What options are available for database encryption in RDS PostgreSQL?

**Answer:**  
RDS supports storage-level encryption using AWS KMS (encryption at rest), including data, logs, and automated backups. You can enable this on creation only. In transit, SSL/TLS is supported for client connections. You can also use the pgcrypto extension for column-level encryption inside the database.

### 8. How can you monitor RDS performance and troubleshoot slow queries?

**Answer:**  
AWS provides monitoring via CloudWatch for metrics—CPU, memory, IOPS, connections, latency. Enhanced Monitoring offers OS-level metrics. Performance Insights shows query activity, wait events, and resource bottlenecks. For slow queries, use the pg_stat_statements extension, enable the log_min_duration_statement parameter, and review logs via the RDS Console or CloudWatch Logs.

### 9. Can you enable custom PostgreSQL extensions on RDS? How?

**Answer:**  
RDS supports a subset of extensions natively, managed via the rds.extensions parameter or CREATE EXTENSION in SQL. Examples: PostGIS, pg_trgm, hstore, uuid-ossp. You cannot compile/upload your own binaries due to lack of OS access; only supported extensions listed by AWS are allowed.

### 10. How do you handle database patching and upgrades in RDS?

**Answer:**  
RDS offers two patching methods: immediately or during a specified maintenance window. Minor upgrades are often automatic based on AWS schedule; major upgrades (version upgrades) must be initiated manually. Always test upgrades in a staging environment. Patching includes downtime, so plan accordingly, and always verify application compatibility.

### 11. How does Point in Time Recovery (PITR) work in RDS?

**Answer:**  
PITR allows restoring the database to any second within the backup retention window by replaying archived transaction logs from a full snapshot forward. You select the time, and RDS provisions a new instance with data at that point—ideal for recovering from application errors or partial data loss.

### 12. What mechanisms restrict access to an RDS PostgreSQL instance?

**Answer:**  
Network access is controlled using VPC Security Groups (for IP ranges, ports), subnet groups (for private or public access), and parameter-level controls for SSL. Database-level security uses PostgreSQL roles and privileges. Optionally, IAM authentication can be enabled to eliminate password storage in the app.

### 13. Explain IAM database authentication with PostgreSQL on RDS.

**Answer:**  
IAM authentication allows applications/users to connect to RDS PostgreSQL using temporary AWS IAM credentials (token-based) instead of static passwords. This requires enabling in the parameter group and configuring PostgreSQL users with the rds_iam role. Auth tokens expire in 15 minutes, so the app must refresh and reconnect accordingly.

### 14. What is the maximum storage supported by RDS PostgreSQL? How does storage autoscaling work?

**Answer:**  
As of mid-2025, individual RDS PostgreSQL instances support up to 64TB (depending on the instance class/region). Storage autoscaling, when enabled, automatically increases allocated storage if free space drops below a threshold, without downtime. Scaling down is not supported; a new upsize provisioned disk is attached internally.

### 15. How do you enable logical replication for RDS PostgreSQL?

**Answer:**  
Set the rds.logical_replication parameter to 1 in the parameter group and restart the instance. Create a replication user with REPLICATION privilege. Set up a publication using CREATE PUBLICATION on RDS and create subscriptions on downstream systems. Note only supported versions and extensions work; some replication slots limitations apply.

### 16. How does RDS ensure durability during failures?

**Answer:**  
RDS stores data on SSD-backed EBS volumes, with Multi-AZ deployments synchronously replicating writes to standby. Backups and logs are stored redundantly in S3. In-region snapshots and cross-region copies enhance durability against regional failures. Automated monitoring and failover reduce risk of data loss.

### 17. How do you manage database logs in RDS?

**Answer:**  
You can view/stream logs (postgresql.log, error, slow query logs) from the RDS console, download them, or export to CloudWatch Logs for retention, analysis, and alerting. Parameters in the parameter group control log verbosity, rotation, and destination. There’s no OS-level access to raw log files.

### 18. How does RDS PostgreSQL handle maintenance windows?

**Answer:**  
A maintenance window specifies when RDS can perform disruptive operations (e.g., patching, upgrades, some storage changes). Outside this window, no automatic restarts occur. You can set maintenance windows to least-trafficked hours to minimize production impact.

### 19. How do you automate backups beyond the retention window?

**Answer:**  
Automate snapshot exports using AWS Lambda (scheduled by EventBridge) or the AWS CLI to copy snapshots to S3 (or cross-region). Manually exported snapshots can be retained indefinitely and restored like regular automated backups. Snapshots can be shared across accounts for DR.

### 20. What options exist for scaling RDS PostgreSQL horizontally and vertically?

**Answer:**  
**Vertically:** Modify the instance class for more CPU/memory/storage.
**Horizontally:** Add Read Replicas for scaling reads, promote read replica for DR. For sharding/partitioning, application-level partitioning is needed, since RDS does not natively shard. Aurora PostgreSQL offers more advanced horizontal scaling features like Aurora Replicas.

### 21. How do you perform major version upgrades on an RDS PostgreSQL instance?

**Answer:**  
Snapshot the database, verify application compatibility (ideally in a test RDS instance). Modify the instance to upgrade, either via console or CLI. Monitor logs for errors post-upgrade. Some extensions/functions may not be compatible; manual review is recommended. Major upgrades can cause downtime; plan during low-traffic periods.

### 22. How do you handle orphaned replication slots in RDS?

**Answer:**  
List replication slots using `pg_replication_slots`. If a slot is inactive/unused and nearing max slot limits, drop the slot (using `SELECT pg_drop_replication_slot('slot_name');`). Failure to manage slots can result in WAL buildup and disk exhaustion—set up alarms for slot count and old WAL segments.

### 23. How do you secure RDS snapshots?

**Answer:**  
Ensure snapshots are encrypted (either on creation or by copying an unencrypted snapshot to an encrypted one). Restrict snapshot sharing to approved AWS accounts only. Use tags for monitoring and lifecycle management, and configure IAM roles/policies to restrict who can create, delete, and restore snapshots.

### 24. What auditing options are available in RDS PostgreSQL?

**Answer:**  
Enable rds.pgAudit in the parameter group to audit SELECT, INSERT, UPDATE, DELETE operations by user/table. You can also use PostgreSQL’s native logging for statement-level auditing, though less granular. Logs are written to the PostgreSQL log stream, which can be exported and analyzed in CloudWatch.

### 25. Can you explain RDS Event Subscriptions?

**Answer:**  
Event subscriptions allow notifications (via SNS topic) for specific RDS events (failover, backup/snapshot completion, failover, errors, parameter changes, maintenance). Useful for alerting devops teams of critical incidents or automated workflows, ensuring immediate response to issues or changes.

These questions and answers should challenge and evaluate a candidate deeply on both their PostgreSQL administration skills and their AWS operational expertise, ensuring they understand cloud-native patterns in the context of managed PostgreSQL deployments.
