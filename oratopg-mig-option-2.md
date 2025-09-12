Nice — using **three servers** (Oracle, PostgreSQL, and a separate migration server running `ora2pg`) is a very common and *recommended* pattern for production migrations because it isolates heavy migration work from both source and target DBs. Below I’ll give you a **detailed, ready-to-run plan** (commands + config snippets + explanations) for:

* installing PostgreSQL 17 on `pgserver2`, and
* installing & configuring `ora2pg` on a separate `ora2pgserver` that connects to `oraserver1` and `pgserver2`.

I’ll also explain **why this architecture is recommended for production** and give a short *cutover / risk* checklist.

---

# Overview / recommendation

* `oraserver1` — Oracle (production source).
* `pgserver2` — PostgreSQL 17 (final target). Keep this dedicated to Postgres (HA/copies if production).
* `ora2pgserver` — Migration server (runs Oracle Instant Client, `ora2pg`, and performs exports/imports).
  **Why separate migration server?** avoids resource contention on source/target, gives a place to tune/perf-test migration, lets you resume/parallelize exports, and isolates credentials and tooling.

---

# 1 — Network & prechecks (do first on all servers)

1. Sync time on all hosts (important for logs/replication)

```bash
sudo timedatectl set-ntp yes
```

2. Ensure DNS/hosts resolve each other or add /etc/hosts entries.
3. Open ports only as needed:

   * Oracle listener (1521) allowed only from `ora2pgserver`.
   * PostgreSQL (5432) allowed only from `ora2pgserver` and app servers.
   * Use firewall/iptables/firewalld or cloud security groups.
4. Make sure you have sudo access and that `ssh` between servers works (use key auth).
5. Backups: take a recent backup of Oracle before starting real migration steps.

---

# 2 — Install PostgreSQL 17 on `pgserver2` (Oracle Linux / RHEL 9 style)

> Replace placeholders (`PG_VER`, hostnames, etc.) with your values.

```bash
# add PGDG repository (EL-9)
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# disable distro module (avoid conflicts)
sudo dnf -qy module disable postgresql

# install server + contrib
sudo dnf install -y postgresql17-server postgresql17-contrib

# initialize database
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb

# start and enable
sudo systemctl enable --now postgresql-17

# check
sudo systemctl status postgresql-17
```

## Basic PostgreSQL config (production starter tuning)

Open `/var/lib/pgsql/17/data/postgresql.conf` and set at least:

```conf
listen_addresses = '*'                 # (or restrict to specific IPs)
port = 5432
# memory tuning (example for 32GB RAM)
shared_buffers = 8GB                   # ~25% RAM
effective_cache_size = 24GB            # ~75% RAM
work_mem = 64MB                        # per-sort; tune per workload
maintenance_work_mem = 2GB
wal_level = replica
max_wal_size = 2GB
checkpoint_timeout = 15min
default_statistics_target = 100
```

Adjust numbers for your machine size (I can calculate tuned numbers if you tell me RAM & cores).

## Create import role and DB

```bash
sudo -u postgres psql -c "CREATE ROLE migrate_user WITH LOGIN PASSWORD 'ChangeMe!';"
sudo -u postgres createdb -O migrate_user targetdb
```

## Allow `ora2pgserver` to connect (pg\_hba.conf)

Edit `/var/lib/pgsql/17/data/pg_hba.conf` and add:

```
# allow migration server
host    targetdb    migrate_user    <ORA2PG_IP>/32    scram-sha-256
```

Reload:

```bash
sudo systemctl reload postgresql-17
```

## Firewall

```bash
sudo firewall-cmd --add-port=5432/tcp --permanent
sudo firewall-cmd --reload
```

---

# 3 — Prepare Oracle (`oraserver1`)

Create a migration user (run as DBA):

```sql
CREATE USER ora2pg_user IDENTIFIED BY "Ora2PgPass!";
GRANT CONNECT TO ora2pg_user;
GRANT SELECT_CATALOG_ROLE TO ora2pg_user;
GRANT SELECT ANY TABLE TO ora2pg_user;
-- optionally grant SELECT ANY DICTIONARY for dictionary access if needed
```

Check character set of Oracle:

```sql
SELECT value FROM nls_database_parameters WHERE parameter='NLS_CHARACTERSET';
```

Ideally should be `AL32UTF8` (Postgres uses UTF8).

---

# 4 — Install Oracle Instant Client + ora2pg on `ora2pgserver` (migration server)

You need Oracle Instant Client (basic + devel) and Perl/DBI/DBD::Oracle plus `ora2pg`.

### 4.1 Obtain & install Oracle Instant Client

* Download the RPMs for *Instant Client Basic* and *Instant Client SDK/Devel* from Oracle’s site (choose matching architecture).
* Then install:

```bash
sudo dnf localinstall -y oracle-instantclient-basicXX.rpm oracle-instantclient-develXX.rpm
```

(If a distro package is available via your repos, you can `dnf install` instead.)

Create env file `/etc/profile.d/oracle-client.sh`:

```bash
export LD_LIBRARY_PATH=/usr/lib/oracle/<version>/client64/lib:$LD_LIBRARY_PATH
export PATH=/usr/lib/oracle/<version>/client64/bin:$PATH
```

`source /etc/profile.d/oracle-client.sh` or re-login.

Test:

```bash
sqlplus ora2pg_user/Ora2PgPass!@//oraserver1:1521/ORCLPDB1
```

### 4.2 Install Perl + DBD::Oracle + ora2pg

Option A — package manager (if `ora2pg` available):

```bash
sudo dnf install -y perl perl-DBI perl-DBD-Oracle ora2pg
```

Option B — CPAN (if package not available):

```bash
sudo dnf install -y perl gcc make perl-App-cpanminus
sudo cpanm DBI
# DBD::Oracle needs Instant Client devel libs set (LD_LIBRARY_PATH)
sudo cpanm DBD::Oracle
sudo cpanm Ora2pg
```

Confirm:

```bash
ora2pg -v
```

---

# 5 — ora2pg configuration on `ora2pgserver`

Create directory and a config file, e.g. `/etc/ora2pg/ora2pg.conf` or `~/ora2pg.conf`.

Example minimal config (replace placeholders):

```conf
# Oracle connection (use service_name or sid style as needed)
ORACLE_DSN   dbi:Oracle:host=oraserver1;port=1521;sid=ORCLPDB1
ORACLE_USER  ora2pg_user
ORACLE_PWD   Ora2PgPass!

# Output files
OUTPUT_DIR   /var/tmp/ora2pg_output
LOGFILE      /var/log/ora2pg/ora2pg.log
DEBUG        1

# What to export
TYPE         TABLE        # first run schema export
SCHEMA       MYSCHEMA     # or leave blank for all user schemas

# Data type overrides (examples)
DATA_TYPE    NUMBER(1):boolean
DATA_TYPE    NUMBER(10):integer
DATA_TYPE    NUMBER(19):bigint

# Export data as COPY (faster), or use INSERT
DATA_EXPORT  COPY
```

Create output dir & set permissions:

```bash
sudo mkdir -p /var/tmp/ora2pg_output
sudo chown $(whoami):$(whoami) /var/tmp/ora2pg_output
```

---

# 6 — Run analysis, export schema & data (from `ora2pgserver`)

1. **Report**

```bash
ora2pg -c /etc/ora2pg/ora2pg.conf -t SHOW_REPORT > /var/tmp/ora2pg_output/migration_report.txt
```

Read this report carefully — it lists objects that need manual attention (PL/SQL, packages, unsupported datatypes, etc.)

2. **Export schema**

```bash
ora2pg -c /etc/ora2pg/ora2pg.conf -t TABLE -o /var/tmp/ora2pg_output/schema.sql
# you can also include INDEX, CONSTRAINT types afterwards or in one run
```

3. **Transfer & apply schema to pgserver2**
   Either push with `psql` from `ora2pgserver` directly to `pgserver2`, or scp the file to `pgserver2`.

Direct (from ora2pgserver):

```bash
psql -h pgserver2 -U postgres -d targetdb -f /var/tmp/ora2pg_output/schema.sql
```

Or scp & apply:

```bash
scp /var/tmp/ora2pg_output/schema.sql postgres@pgserver2:/tmp/
# on pgserver2
psql -U postgres -d targetdb -f /tmp/schema.sql
```

4. **Export data**

```bash
ora2pg -c /etc/ora2pg/ora2pg.conf -t COPY -o /var/tmp/ora2pg_output/data.sql
# For large datasets, you may get one .copy file per table or large split files
```

5. **Load data into Postgres**

```bash
psql -h pgserver2 -U migrate_user -d targetdb -f /var/tmp/ora2pg_output/data.sql
```

Or use `psql` COPY commands to load per-table files — this is usually fastest.

---

# 7 — Validation & sanity checks

* Row counts: compare oracle `select count(*)` vs Postgres.
* Check crucial aggregates (SUM, MAX, MIN) for numeric columns.
* Check nullability, default values, sequences/identities.
* Validate business-critical queries & stored procedures (PL/SQL often requires manual conversion).
* Check encoding: `select pg_encoding_to_char(encoding) from pg_database where datname='targetdb';`

---

# 8 — Cutover strategy (production)

For *minimal downtime* migrations consider:

1. **Initial full load** — export & import as above.
2. **Delta sync** — capture changes (options):

   * Use ora2pg incremental features (trigger-based) OR
   * Use Oracle CDC / GoldenGate / Debezium / logminer to stream changes to PostgreSQL.
3. **Freeze or short window** — at final cutover: stop writes to Oracle (or redirect to a queue), run final delta, switch apps to PostgreSQL.
4. **Smoke tests** then open to users.

If you cannot accept downtime, use a CDC-based approach (outside ora2pg) to keep two-way change capture.

---

# 9 — Production hardening / tuning after migration

* Put Postgres on fast SSDs; separate WAL disk if possible.
* Set `fsync=on`, `synchronous_commit` as required by durability needs.
* Configure regular backups (pg\_basebackup or pgbackrest) and PITR (WAL archiving).
* Monitoring: pg\_stat\_activity, pg\_stat\_user\_tables, pg\_stat\_replication, and setup Prometheus/Grafana.
* HA: use Patroni/replication for failover in production.

---

# 10 — Is this 3-server option good for production?

**Yes — strongly recommended for migration work.**
Pros:

* Isolates heavy CPU/IO work from Oracle and Postgres servers.
* Easier troubleshooting & retrying (replayable exports).
* Easier to control network and security (migration server is the only host with DB credentials).
* Can parallelize exports/imports.

Cons / caveats:

* Extra infrastructure to manage.
* For *zero-downtime* cutover you’ll still need CDC/replication (ora2pg is great for bulk migration, not continuous real-time sync).
* Must secure the migration host (it has credentials for both DBs).

---

# Short checklist (quick)

* [ ] Time sync & DNS between servers
* [ ] Oracle migration user created and tested
* [ ] PostgreSQL 17 installed & tuned on `pgserver2`
* [ ] `ora2pg` + Oracle Instant Client installed on `ora2pgserver`
* [ ] `ora2pg.conf` created and validated
* [ ] SHOW\_REPORT reviewed and manual items planned
* [ ] Schema exported & applied
* [ ] Data exported & loaded
* [ ] Row-counts and query validation complete
* [ ] Backup & monitoring configured on `pgserver2`
* [ ] Cutover plan and rollback plan documented

---

If you want I can now:

* produce **ready-to-run bash scripts** for `pgserver2` and `ora2pgserver` (with placeholders for passwords/IPs) that perform the installs + basic config, **or**
* produce a **detailed migration playbook** (step-by-step checklist and commands) tailored to your OS and the RAM/cores/disk sizes of `pgserver2` and `ora2pgserver`.

Which one should I generate for you now? (I can drop in exact commands and files you can copy/paste.)
