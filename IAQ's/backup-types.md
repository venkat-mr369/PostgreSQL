PostgreSQL supports several types of backups, which are broadly categorized as logical and physical methods, each suited for different purposes and environments.

### Main Backup Types

#### Logical Backups
- **pg_dump:** Creates a backup of a single database in the form of SQL statements (or custom formats). It's flexible, portable, and allows selective restore of objects/tables. Ideal for smaller databases or migrations.
- **pg_dumpall:** Backs up all databases in a PostgreSQL cluster, including globals (roles, tablespaces).
- **Pros:** Easy restores to different versions/architectures, supports partial restores.
- **Cons:** Slow for large databases; restore is time-consuming as all data is replayed as SQL.

#### Physical Backups
- **pg_basebackup:** Command-line utility for taking a consistent, binary-level backup of the entire database cluster, suitable for fast, full restores and streaming replication setups.
- **File-system-level backups:** Uses OS tools (like tar, rsync, or LVM snapshots) to copy the PostgreSQL data directory. To be safe, the cluster must be shut down or put into backup mode for a consistent snapshot.
- **Pros:** Fast, necessary for large databases, foundational for Point-In-Time Recovery (PITR).
- **Cons:** Not portable across PostgreSQL versions, cluster-wide only.

#### Continuous Archiving & PITR
- **WAL Archiving:** Archiving Write-Ahead Log (WAL) segments allows replaying all changes since a base backup, enabling Point-In-Time Recovery (restoring your cluster to any specific moment).
- **Pros:** Mission-critical for disaster recovery.
- **Cons:** Requires setup and careful monitoring of archived logs and storage.

#### Advanced/Third-Party Tools
- Tools like **pgBackRest**, **Barman**, **pg_probackup**, and **WAL-G** provide full, differential, incremental, and parallelized backups, as well as backup verification and streamlined PITR support.

### Comparison Table

| Backup Type              | Tool(s)        | Use Case                          | Portability     | PITR Support   |
|--------------------------|----------------|------------------------------------|-----------------|---------------|
| Logical                  | pg_dump, pg_dumpall | Migration, selective restores      | Yes             | No            |
| Physical                 | pg_basebackup, OS tools | Fast, full database restores, replication | No (version)     | Yes           |
| Continuous Archiving     | WAL archiving  | Restore to a specific point in time| No              | Yes           |
| Incremental/Differential | pgBackRest, Barman, WAL-G | Efficient large database backup   | No              | Yes           |

PostgreSQL offers flexible backup types—logical (data dump), physical (full or file-level), and continuous/WAL-based—with a mix of open source and commercial tools to meet various operational and recovery requirements.
