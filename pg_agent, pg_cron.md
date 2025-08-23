Detailed steps with sample scripts and notes for implementing both **pgAgent** and **pg_cron** in PostgreSQL 17:

***

## 1. Installing and Using pgAgent in PostgreSQL 17

### Installation

- On RHEL/CentOS or similar, install pgAgent via package manager or from source if unavailable:

```bash
sudo yum install pgagent
```

- On Debian/Ubuntu (if available):

```bash
sudo apt install pgagent
```

- Alternatively, build from source from https://github.com/postgres/pgagent.

### Setup

- Enable the extension in your database:

```sql
CREATE EXTENSION IF NOT EXISTS pgagent;
```

- Start the pgAgent daemon with proper DB connection:

```bash
pgagent hostaddr=127.0.0.1 port=5432 dbname=postgres user=postgres password=yourpassword -s /var/log/pgagent/pgagent.log
```

### Sample Job Creation (via SQL or pgAdmin)

Example SQL to create a job that runs a vacuum analyze every day at 1 AM:

```sql
-- Insert job
INSERT INTO pgagent.pga_job(jobjclid, jobname, jobdesc, jobenabled)
VALUES (1, 'Daily Vacuum', 'Run vacuum analyze every night', true);

-- Insert step
INSERT INTO pgagent.pga_jobstep(jstjobid, jstname, jstdesc, jstkind, jstcode, jstenabled)
VALUES (currval('pgagent.pga_job_jobid_seq'), 'Vacuum Step', 'Vacuum analyze step', 'sql', 'VACUUM ANALYZE;', true);

-- Insert schedule (every day at 1 am)
INSERT INTO pgagent.pga_schedule(schname, schdesc, schenabl, schstart, schminutes, schhours, schweekdays, schmonthdays, schmonthlies, schjmenables)
VALUES ('Daily 1AM', 'Daily schedule at 1 AM', true, now()::timestamp, '0', '1', '*', '*', '*', true);
```

***

## 2. Installing and Using pg_cron in PostgreSQL 17

### Installation

- On RHEL/CentOS:

```bash
sudo yum install pg_cron_17
```

- On Debian/Ubuntu:

```bash
sudo apt install postgresql-17-cron
```

- Or build from source: https://github.com/citusdata/pg_cron

### Configuration

Edit `postgresql.conf`:

```conf
shared_preload_libraries = 'pg_cron'

# Set this to your application database name instead of 'postgres'
cron.database_name = 'your_application_db'

# Optional: set timezone for cron jobs (e.g., IST timezone)
cron.timezone = 'Asia/Kolkata'

```

Restart PostgreSQL server afterward.

### Enable Extension

Connect to the chosen database and enable extension:

```sql
CREATE EXTENSION pg_cron;
```

### Sample pg_cron Job Script

Schedule a daily vacuum analyze job at 2 AM IST:

```sql
SELECT cron.schedule('daily_vacuum', '0 2 * * *', 'VACUUM ANALYZE;');
```

Schedule a job with a custom SQL query:

```sql
SELECT cron.schedule('log_cleanup', '0 3 * * 0', 'DELETE FROM logs WHERE log_date < NOW() - INTERVAL ''30 days'';');
```

### Notes on pg_cron

- Runs inside PostgreSQL as a background worker.
- Jobs are scheduled using standard cron syntax.
- Runs only one instance of a job at a time; subsequent runs are queued.
- Good for scheduling SQL commands and stored procedures inside PostgreSQL.

***

## Summary Table

| Feature         | pgAgent                                          | pg_cron                                           |
|-----------------|-------------------------------------------------|--------------------------------------------------|
| Installation    | External agent daemon, package or source install| Extension running inside PostgreSQL               |
| Scheduling      | Jobs, steps, schedules via tables or pgAdmin    | Uses cron syntax inside SQL, scheduled via extension|
| OS Support     | Good support on Linux and Windows                | Mostly Linux, Windows installation more complex   |
| Use cases      | Complex workflows, multi-step jobs                | Simple scheduled SQL commands                      |
| Integration    | pgAdmin integration                               | Runs as PostgreSQL background worker              |

***

