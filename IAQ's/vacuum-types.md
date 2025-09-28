***PostgreSQL provides several types of vacuum processes to manage database bloat, reclaim space, and maintain transaction integrity. Here are the main vacuum types:***

### List of Vacuum Types

- **Standard VACUUM:** The regular vacuum command removes dead tuples and makes space within a table available for reuse. It does *not* free space for the operating system but keeps the tables lean and performing well. Can run alongside normal read/write operations.

- **VACUUM FULL:** This aggressive vacuum rewrites the entire table, physically compacts it, and frees unused space back to the operating system. It requires an exclusive lock on the table; all other queries are blocked during execution.

- **Autovacuum:** A built-in background process that automatically triggers standard vacuuming and analyzing on tables based on predefined thresholds (number of row updates/deletes). Designed to keep the database healthy without manual intervention.

- **VACUUM FREEZE:** This process ‘freezes’ very old tuples to avoid transaction ID wraparound problems, crucial for long-lived databases. Normally, autovacuum manages freezing, but it can be run manually as well.

- **VACUUM ANALYZE:** Combines vacuuming dead tuples with updating table statistics for the query planner. It can be run alone or with FULL/VERBOSE.

- **Parallel VACUUM:** Introduced in recent PostgreSQL versions, vacuum can now utilize parallel workers (for index cleanups and scanning). This is particularly useful for large tables and indexes, increasing maintenance speed.

### Summary

| Type               | Description                                               | Locks Table?    |
|--------------------|----------------------------------------------------------|-----------------|
| Standard           | Reclaims and cleans space within a table                 | No              |
| FULL               | Rewrites table, returns disk space to OS                 | Yes (Exclusive) |
| Autovacuum         | Background automatic vacuuming of tables                 | No              |
| FREEZE             | Prevents transaction ID wraparound issues                | No              |
| ANALYZE            | Updates statistics during vacuum                         | No              |
| Parallel           | Vacuuming with parallel workers for faster maintenance   | No              |

