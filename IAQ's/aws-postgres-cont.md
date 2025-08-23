

### 1. **How do you provision an RDS PostgreSQL instance from the CLI?**

- Use the AWS CLI command:
  ```
  aws rds create-db-instance \
    --db-instance-identifier mydbinstance \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --master-username admin \
    --master-user-password 'StrongP@ssw0rd' \
    --allocated-storage 20
  ```
- This creates a new DB instance with specified resources.

### 2. **How can you enable and verify Multi-AZ deployment for high availability?**

- Provision with:
  ```
  aws rds create-db-instance --multi-az ...
  ```
- To check if enabled:
  ```
  aws rds describe-db-instances --db-instance-identifier mydbinstance --query 'DBInstances[*].MultiAZ'
  ```

### 3. **How do you set up automated backups, and how do you control the backup window?**

- Enable and configure on creation:
  ```
  --backup-retention-period 7 \
  --preferred-backup-window 02:00-02:30
  ```
- To modify later:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --backup-retention-period 14 \
    --preferred-backup-window 03:00-04:00 \
    --apply-immediately
  ```

### 4. **How do you restore an RDS PostgreSQL instance to a specific point in time?**

- Identify restore point and run:
  ```
  aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier mydbinstance \
    --target-db-instance-identifier mydbrestore \
    --restore-time 2025-08-01T08:30:00Z
  ```

### 5. **How do you increase the allocated storage for an active RDS instance?**

- Storage is increased with:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --allocated-storage 100 \
    --apply-immediately
  ```

### 6. **How do you perform major and minor version upgrades on RDS PostgreSQL safely?**

- List eligible versions:
  ```
  aws rds describe-db-engine-versions --engine postgres
  ```
- Run upgrade:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --engine-version 15.4 \
    --apply-immediately
  ```
- Always test upgrades in staging!

### 7. **How do you create, list, and delete DB snapshots for backups?**

- Create:
  ```
  aws rds create-db-snapshot \
    --db-snapshot-identifier mydbsnapshot \
    --db-instance-identifier mydbinstance
  ```
- List:
  ```
  aws rds describe-db-snapshots --db-instance-identifier mydbinstance
  ```
- Delete:
  ```
  aws rds delete-db-snapshot --db-snapshot-identifier mydbsnapshot
  ```

### 8. **How do you create a Read Replica and promote it?**

- Create:
  ```
  aws rds create-db-instance-read-replica \
    --db-instance-identifier mydb-replica \
    --source-db-instance-identifier mydbinstance
  ```
- Promote:
  ```
  aws rds promote-read-replica --db-instance-identifier mydb-replica
  ```

### 9. **How do you encrypt data at rest?**

- Use `--storage-encrypted` when creating the DB:
  ```
  aws rds create-db-instance ... --storage-encrypted --kms-key-id 
  ```
- Encryption cannot be enabled on an existing DB; create a snapshot, copy it with encryption, and restore.

### 10. **How do you manage access using security groups?**

- Attach a VPC security group:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --vpc-security-group-ids sg-12345678
  ```
- Security groups control inbound/outbound TCP/IP.

### 11. **How do you monitor an RDS PostgreSQL instance via CLI and CloudWatch?**

- List available metrics:
  ```
  aws cloudwatch list-metrics --namespace AWS/RDS
  ```
- Get current CPU Utilization:
  ```
  aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name CPUUtilization \
    --dimensions Name=DBInstanceIdentifier,Value=mydbinstance \
    --start-time 2025-08-01T00:00:00Z \
    --end-time 2025-08-01T23:59:59Z \
    --period 300 --statistics Average
  ```

### 12. **How do you log database activity and view logs via CLI?**

- Enable general and slow logs in the parameter group:
  ```sql
  rds.enable_logical_replication=1
  log_statement=all
  log_min_duration_statement=1000
  ```
- Download logs:
  ```
  aws rds download-db-log-file-portion \
    --db-instance-identifier mydbinstance \
    --log-file-name postgresql.log
  ```

### 13. **How do you adjust PostgreSQL parameters in RDS?**

- Modify a DB parameter group:
  ```
  aws rds modify-db-parameter-group \
    --db-parameter-group-name mypgparamgroup \
    --parameters "ParameterName=work_mem,ParameterValue=16MB,ApplyMethod=pending-reboot"
  ```
- Attach the group and reboot instance.

### 14. **How do you enable logical replication for CDC/migration?**

- Set this parameter:
  ```
  aws rds modify-db-parameter-group \
    --db-parameter-group-name mypgparamgroup \
    --parameters "ParameterName=rds.logical_replication,ParameterValue=1,ApplyMethod=pending-reboot"
  ```
- Attach to the DB, and reboot.

### 15. **How do you perform failover in Multi-AZ manually?**

- In a Multi-AZ setup, use:
  ```
  aws rds reboot-db-instance --db-instance-identifier mydbinstance --force-failover
  ```
- This triggers a failover to the standby.

### 16. **How do you resize instance class during peak traffic?**

- With minimal downtime:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --db-instance-class db.m6g.large \
    --apply-immediately
  ```

### 17. **How do you limit connections and manage idle sessions?**

- Update parameter group:
  ```
  aws rds modify-db-parameter-group \
    --db-parameter-group-name mypgparamgroup \
    --parameters "ParameterName=max_connections,ParameterValue=150,ApplyMethod=immediate"
  ```
- Set connection pool settings at the application level.

### 18. **How do you grant IAM-based authentication for PostgreSQL users?**

- Attach IAM policy (`rds-db:connect`) and generate an authentication token:
  ```
  aws rds generate-db-auth-token \
    --hostname mydb.abcdef1234.us-east-1.rds.amazonaws.com \
    --port 5432 \
    --region us-east-1 \
    --username dbuser
  ```
- Connect to PostgreSQL with this token as password.

### 19. **How would you tune storage performance and monitor IOPS?**

- Apply a higher IOPS value on provisioned storage:
  ```
  aws rds modify-db-instance \
    --db-instance-identifier mydbinstance \
    --iops 12000 \
    --apply-immediately
  ```
- Monitor with CloudWatch metrics: `WriteIOPS`, `ReadIOPS`.

### 20. **How do you migrate a non-RDS PostgreSQL database to RDS with minimal downtime?**

- Use the AWS Database Migration Service (DMS):
  1. Create a replication instance.
  2. Set up source and target endpoints.
  3. Start full load and CDC (change data capture) task.
  4. Cut over by stopping application, apply deltas, point apps to RDS.

### 21. **How do you test the backup and restore process in RDS PostgreSQL?**

- Create a snapshot:
  ```
  aws rds create-db-snapshot ...
  ```
- Restore from that snapshot to a new instance:
  ```
  aws rds restore-db-instance-from-db-snapshot ...
  ```
- Verify the new DB is accessible and contains all data.

### 22. **How do you enable SSL connections for your PostgreSQL RDS instance?**

- Force SSL in the parameter group:
  ```
  rds.force_ssl=1
  ```
- Download RDS root CA and connect using:
  ```
  psql "host=mydb.rds.amazonaws.com port=5432 dbname=mydb user=user sslmode=verify-full"
  ```

### 23. **How do you scale out read workload in RDS PostgreSQL?**

- Setup read replicas (see Q8).
- Use a load balancer, or direct read traffic in your application to the replica endpoint.

### 24. **How do you troubleshoot and terminate long-running queries?**

- List active queries:
  ```sql
  SELECT pid, query, state, now()-query_start AS run_time
  FROM pg_stat_activity
  WHERE state = 'active';
  ```
- Terminate:
  ```sql
  SELECT pg_terminate_backend();
  ```
- Use `psql` via SSL to connect to the RDS instance.

### 25. **How do you audit RDS PostgreSQL for security and compliance?**

- Enable PostgreSQL audit logging:
  ```
  rds.log_statement=all
  rds.log_connections=1
  rds.log_disconnections=1
  log_min_duration_statement=0
  ```
- Use CloudTrail to track RDS API actions:
  ```
  aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventSource,AttributeValue=rds.amazonaws.com
  ```
- Regularly rotate database passwords, update security groups, and enable encryption.

