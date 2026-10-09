# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** Blocked before database queries. Static review is recorded below; Oracle 19c compatibility is not verified.

## Scope and Safety Boundary

The approved targets are the Oracle 19c CDB connection `DBI_CGEMS401` and direct-PDB connection `DBI_CGEMS401_PGEMS4`. Database work is restricted to `SELECT` statements. The user has confirmed Diagnostic Pack licensing for these environments. Do not run `source/awr_miner.sql` or `source/awr_miner_historical.sql`: both include session changes, PL/SQL, prompts, and other operations outside this authorization.

## Execution Attempt

On 2026-10-09, the SQLcl MCP connection attempt for `DBI_CGEMS401` failed with `ORA-01950: no privileges on tablespace 'USERS'` (reported at line 14). The connection was not established, and no schema inspection or SQL query was submitted. This error does not establish whether the account has access to AWR views or whether the database capture path works. The direct-PDB connection was not attempted.

Ask the database/tooling administrator to investigate the MCP connection initialization and its tablespace requirement. Do not issue a quota/grant change from this project or retry database checks until that setup issue is resolved. No credentials are stored in this document.

### SQL Developer Comparison (User-Provided)

The user confirmed that SQL Developer connects successfully and returned these session identities:

| Connection | User | Service | Container | `CON_ID` | `DBA` role |
| --- | --- | --- | --- | ---: | --- |
| CDB | `C##GU_DBA` | `CGEMS401.generali.it` | `CDB$ROOT` | 1 | Present |
| Direct PDB | `GU_DBA` | `pgems4.generali.it` | `PGEMS4` | 3 | Present |

In both sessions, `SESSION_PRIVS` returned no row for `UNLIMITED TABLESPACE`, and `USER_TS_QUOTAS` returned no rows. This is consistent with an account that has no explicit tablespace quota and no unlimited-tablespace system privilege. It does not explain a failure of a pure `SELECT`: reading AWR views does not allocate segments in `USERS`. The SQL Developer results demonstrate that interactive connections to both targets work, but they do not prove that MCP uses the same initialization path, client identity, or connection hooks. The MCP `ORA-01950` therefore points to an allocation attempt during MCP connection setup or a database-side hook, not a quota requirement of the planned read-only checks. The exact statement and component remain unknown; do not grant quota merely to make the error disappear.

To narrow the source, have the DBA inspect the MCP-side error/log at the reported line and, from SQL Developer, use read-only metadata queries to check database logon triggers and the MCP logging object:

```sql
SELECT owner, trigger_name, triggering_event, status
FROM dba_triggers
WHERE base_object_type = 'DATABASE'
   AND UPPER(triggering_event) LIKE '%LOGON%'
ORDER BY owner, trigger_name;

SELECT owner, object_type, status
FROM dba_objects
WHERE object_name = 'DBTOOLS$MCP_LOG'
ORDER BY owner, object_type;

SELECT owner, table_name, tablespace_name
FROM dba_tables
WHERE table_name = 'DBTOOLS$MCP_LOG'
ORDER BY owner;
```

If a logon trigger is present, review its source for client-specific branches and writes. If the logging object exists, identify which MCP operation writes it and whether its owner or the connected user is expected to allocate the segment. These checks may identify a cause, but no root cause is confirmed yet.

## Static Capture Review

The active capture file is `source/awr_miner.sql`. It reads historical AWR data through `DBA_HIST_*` views, including `DBA_HIST_DATABASE_INSTANCE`, `DBA_HIST_SNAPSHOT`, `DBA_HIST_PARAMETER`, `DBA_HIST_OSSTAT`, `DBA_HIST_SGASTAT`, `DBA_HIST_PGASTAT`, `DBA_HIST_SYSMETRIC_SUMMARY`, `DBA_HIST_SGA_TARGET_ADVICE`, `DBA_HIST_PGA_TARGET_ADVICE`, `DBA_HIST_DATAFILE`, `DBA_HIST_TBSPC_SPACE_USAGE`, `DBA_HIST_SYSTEM_EVENT`, `DBA_HIST_SYS_TIME_MODEL`, `DBA_HIST_EVENT_HISTOGRAM`, `DBA_HIST_SYSSTAT`, `DBA_HIST_SEG_STAT_OBJ`, `DBA_HIST_SEG_STAT`, `DBA_HIST_IOSTAT_FUNCTION`, `DBA_HIST_SQLSTAT`, and `DBA_HIST_SQLTEXT`. It also references `DBA_CPU_USAGE_STATISTICS`, `SYS.GV_$DATABASE`, `V$PDBS`, and `SYS.DBA_TAB_STATISTICS`.

The script contains a Diagnostic Pack acknowledgement gate and reads `DBA_HIST_DATABASE_INSTANCE` fields including `CDB`, `CDB_ROOT_DBID`, and `CON_ID`. Its conditional compilation flags stop at version 12.2; static inspection alone does not establish that the generated 19c SQL works. The script uses one capture path and primarily queries `DBA_HIST_*`; whether those views expose the required CDB-root and direct-PDB data in each approved connection remains untested. Separate capture scripts are not justified without the two connection results.

## Read-Only Checks to Run After Access Is Restored

Run the following checks separately on each approved connection and retain the returned database/container identity with the results. These are candidate validation queries, not executed evidence.

1. Identify the session target:

   ```sql
   SELECT SYS_CONTEXT('USERENV', 'DB_NAME') AS db_name,
          SYS_CONTEXT('USERENV', 'CON_NAME') AS con_name,
          SYS_CONTEXT('USERENV', 'CON_ID') AS con_id,
          dbid,
          cdb
   FROM v$database;
   ```

2. Check the version-sensitive instance fields and which database identities are visible:

   ```sql
   SELECT dbid, db_name, version, cdb, cdb_root_dbid, con_id
   FROM dba_hist_database_instance
   WHERE rownum <= 50;
   ```

3. Check snapshot coverage by database/container without returning capture payloads:

   ```sql
   SELECT dbid, con_id, COUNT(*) AS snapshot_rows,
          MIN(begin_interval_time) AS first_snapshot,
          MAX(end_interval_time) AS last_snapshot
   FROM dba_hist_snapshot
   GROUP BY dbid, con_id
   ORDER BY dbid, con_id;
   ```

4. On the CDB connection only, inspect visible PDBs:

   ```sql
   SELECT con_id, name, open_mode
   FROM v$pdbs
   ORDER BY con_id;
   ```

5. In both connections, perform a parse/access probe for each active capture view using a `SELECT` that returns no rows (for example, `SELECT 1 FROM SYS.DBA_HIST_SNAPSHOT WHERE 1 = 0`). Record each success or Oracle error; do not query AWR data beyond the checks above without review. Include the non-AWR views listed in the static review when evaluating capture prerequisites.

Together, checks 1-4 establish the visible connection identity, test selected version-sensitive columns, and describe AWR snapshot/container visibility. The `SELECT 1 ... WHERE 1 = 0` probes establish object resolution and access only; they do not validate the capture script's projected columns. Validate those columns with SELECT projections copied from the relevant capture queries after access is restored. None of these checks establishes SQL*Plus substitution/spooling behavior or end-to-end capture compatibility. Those require separately authorized testing of the capture path, outside the current SELECT-only boundary.

## Results and Exit Criteria

| Check | CDB | Direct PDB |
| --- | --- | --- |
| SQL Developer session identity | Confirmed: `C##GU_DBA`, `CGEMS401.generali.it`, `CDB$ROOT`, `CON_ID=1` | Confirmed: `GU_DBA`, `pgems4.generali.it`, `PGEMS4`, `CON_ID=3` |
| SQL Developer session role | `DBA` present; no `UNLIMITED TABLESPACE` row or explicit user quota row | `DBA` present; no `UNLIMITED TABLESPACE` row or explicit user quota row |
| MCP connection established | Blocked: `ORA-01950` during initialization | Not attempted |
| AWR view access and column compatibility | Not tested | Not tested |
| Visible database IDs and snapshot container scope | Not tested | Not tested |
| Capture execution / SQL*Plus behavior | Not authorized; not tested | Not authorized; not tested |

Phase 3 remains open until both connections can be used for the approved read-only checks. Do not claim Oracle 19c CDB or PDB compatibility, change capture SQL, or select a unified/separate capture design based on this static review.