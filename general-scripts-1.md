```sql
-- This script provides a detailed, organized view of the PostgreSQL server's
-- current configuration settings. It's useful for a quick review or
-- for troubleshooting.

SELECT
    name,               -- The name of the configuration parameter
    setting,            -- The current value of the parameter
    unit,               -- The unit of the value (e.g., kB, s, ms)
    source,             -- Where the setting value came from (e.g., default, configuration file, etc.)
    boot_val,           -- The value of the setting at boot time
    reset_val,          -- The value the setting would revert to on a reload
    pending_restart     -- True if a restart is needed for the change to take effect
FROM
    pg_catalog.pg_settings
ORDER BY
    name;
```

-----

### Understanding the Columns

The `pg_settings` view provides a wealth of information about your server's configuration. Here’s a breakdown of the most important columns in the script:

  * **`name`**: This is the name of the configuration parameter, like `shared_buffers` or `max_connections`.
  * **`setting`**: This is the **current, active value** of the parameter. This is the most important column for seeing what your server is actually using.
  * **`unit`**: For settings that have a unit (like memory or time), this column specifies it. Examples include `kB` for kilobytes, `s` for seconds, or `ms` for milliseconds.
  * **`source`**: This column tells you **how the current value was set**. Common values include:
      * `default`: The setting is using its built-in default value.
      * `configuration file`: The setting was defined in `postgresql.conf` or an included file.
      * `override`: The setting was changed with `ALTER SYSTEM`.
      * `client`: The setting was provided by the client when connecting.
  * **`boot_val`**: The value that the setting had when the server instance was last started. This is useful for seeing if a setting was changed after the server was booted.
  * **`reset_val`**: The value the parameter will have after the next configuration reload (`pg_ctl reload` or `SELECT pg_reload_conf()`). This can differ from `boot_val` and `setting`.
  * **`pending_restart`**: A boolean (`t` or `f`) indicating whether you need to **restart the PostgreSQL server** for the new value to take effect. If this is `t`, the current `setting` is not the one being used by the server.
