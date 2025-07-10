# PostgreSQL Architecture Fundamentals

## Master Postgres Process

### Process and Memory Architecture

- **Maintenance Work Mem**
- **Background Process**
  - Logical Replication Launcher
  - Auto Vacuum Launcher

## Persistent Storage

- **On Disk**

## Memory Components

| Shared Buffer | Wal Buffer |
|:-------------:|:----------:|
| Determines how much memory is dedicated to PostgreSQL to use for caching data. | Determines the memory used for WAL data that has not yet been written to disk. |
| Primary objective is to minimize DISK IO. | This WAL data is the metadata information about changes to the actual data and is sufficient to reconstruct actual data during database recovery operations. |
| Frequently used blocks must be in the buffer for as long as possible. | Wal buffers are flushed from the buffer area to wal segments by wal writer. |
| Shared Buffers are controlled by parameter named `shared_buffer` located in `postgresql.conf` file. | Wal buffers memory allocation is controlled by the `wal_buffers` parameter. |
| Default Value is 128MB | Default Value is 16MB |

## Local Memory (BackEnd Process)

| Process | Description |
|:-------:|:-----------:|
| Work_Mem | Space used for sorting, bitmap operations, hash joins, and merge joins. The default setting is 4 MB. |
| Temp_buffers | These are session-local buffers used only for access to temporary tables. The default setting is 8 MB. |
| Maintenance_work_mem | Space used for Vacuum and CREATE INDEX. The default setting is 64 MB. |

## Background Processes

| Process | Description |
|:-------:|:-----------:|
| Check pointer | Ensure that all the dirty buffers created up to a certain point are sent to disk so that the WAL up to that point can be recycled. |
| Autovacuum launcher | Responsible for carrying vacuum operations on bloated tables. |
| Archiver | When in Archive log mode, copies the WAL file to the specified directory. |
| Logger | Writes the error message to the log file. |
| Writer | Periodically writes the special dirty buffer to a file. |
| Wal Writer | Writes the WAL buffer to the WAL file. |

## Physical Files

| Physical Files | Description |
|:--------------:|:-----------:|
| Data Files | File used to store data. |
| Wal Files | Write ahead log file, where all transactions are recorded before the data is written to the data files. |
| Log Files | All server messages including stderr, csvlog, and syslog are logged in log files. |
| Archive Logs (Optional) | WAL Files which are copied to the archive location. |

