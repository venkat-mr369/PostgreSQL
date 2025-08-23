When logical replication fails in PostgreSQL, fixing it requires a systematic approach to identify and resolve the root cause. Here’s a checklist of what to check and how to fix common issues:

### 1. **Check Error Logs**
- Review both publisher (primary) and subscriber (replica) logs for any replication-related error messages. Logs often provide clear insights into what went wrong (e.g., configuration errors, conflicts, permission problems).[1]

### 2. **Verify Replication Slot Status**
- On the publisher, run:
  ```sql
  SELECT slot_name, plugin, slot_type, active FROM pg_replication_slots;
  ```
  - If `active` is `f`, replication is not running to that slot. If a slot is invalid or inactive, consider dropping and recreating it.[2][3][4]

### 3. **Check Replication Slot Issues**
- Too many inactive or unused slots can fill up disk space with WAL files and cause failure. Remove slots that are no longer needed:
  ```sql
  SELECT * FROM pg_replication_slots;
  -- To remove a slot
  SELECT pg_drop_replication_slot('slot_name');
  ```
- Ensure replication slots are being consumed; otherwise, they accumulate WAL files and fill storage.[3][5]

### 4. **Confirm Configuration Parameters**
- Make sure the following parameters are configured and correctly set on the publisher:
  - `wal_level = logical`
  - `max_replication_slots` is sufficient
  - `max_wal_senders` is sufficient
  - `hot_standby_feedback=on` (to avoid slot invalidation by vacuum).[4][6][7]

- After adjustments, restart PostgreSQL for changes to take effect.

### 5. **Ensure Network and Permissions**
- Network connectivity should be open between publisher and subscriber.
- The replication user must have:
  - REPLICATION role on publisher
  - LOGIN privilege on both sides
  - Sufficient table permissions.[8]

### 6. **Subscription and Publication Validation**
- On the subscriber:
  ```sql
  SELECT subname, subenabled FROM pg_subscription;
  ```
  - If `subenabled` is `f`, enable it:
    ```sql
    ALTER SUBSCRIPTION sub_name ENABLE;
    ```
- Check that the correct publication exists and is referenced in the subscription definition.[6][3]

### 7. **Review Replication Conflicts**
- Table constraints or permissions can cause conflicts (e.g., row-level security or missing primary keys). Review the subscriber’s logs for conflict details.[9][10]

### 8. **Resource & System Checks**
- Ensure adequate resources (CPU, memory, disk space).
- Make sure `max_worker_processes` is not too low.[7]

### 9. **Recreate Subscription/Slot (If Needed)**
- If initial sync failed or slot is corrupted:
  1. Drop the subscription on the subscriber.
  2. Drop and recreate the replication slot on the publisher.
  3. Recreate the subscription.[2][4]

### 10. **Post-Failure Cleanup**
- After fixing, always confirm that replication slots are active, publications and subscriptions are working, and no disk space or log warnings remain.[5][11][1]

#### **Summary Table: What to Check**

| Check                         | What to Look for                                     | Fix/Action                                        |
|-------------------------------|-----------------------------------------------------|---------------------------------------------------|
| Error logs                    | Specific replication errors                         | Investigate and resolve log messages[1][9]      |
| Replication slot status       | Slot inactive or invalid                            | Drop/recreate slot as needed[4][3][2]            |
| Configuration                 | Incorrect `wal_level`, slots, senders, feedback     | Adjust and restart DB[4][6][7]                    |
| Network & Permissions         | Blocked port, insufficient user privileges          | Open ports, grant roles[8]                        |
| Slot accumulation             | Excess WAL, inactive slots filling storage          | Drop unused slots immediately[5][3]               |
| Subscription status           | Not enabled, wrong publication                      | Enable or correct subscription[3]                 |
| Table schema/conflicts        | Constraints, missing PKs, row-level security        | Adjust schema or permissions[9][10]               |

