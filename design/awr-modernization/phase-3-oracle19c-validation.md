# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** In progress; current CDB metadata and query results are verified through MCP. The older local CDB capture omits main-metrics/AAS sections and fails parser validation; a refreshed capture must be produced with SQL*Plus because the SQLcl MCP runner does not support this script's `SET UNDERLINE` and `REPHEADER` commands. PDB1 reports autoflush enabled but has not exposed PDB-scoped snapshot/event/metric history.

## Scope and Authorization

The approved targets are the Oracle 19c CDB connection `LOCAL_ORCL` and direct-PDB connection `LOCAL_PDB1`. The user confirmed that both databases are dedicated test environments, database work is unrestricted for these tests, and Diagnostic Pack licensing is available. No database settings or data were changed during the checks recorded here.

## Results

Checks used the configured SQLcl MCP connections. Local SQL*Plus is installed at 19.3.0, but the MCP route now resolves both approved targets, so the former local Oracle Net alias issue does not block metadata validation.

| Check | `LOCAL_ORCL` | `LOCAL_PDB1` |
| --- | --- | --- |
| Database version | 19.3.0.0.0 | 19.3.0.0.0 |
| Container / service | `CDB$ROOT` / `orcl` | `PDB1` / `pdb1` |
| Session user | `SYSTEM` | `SYSTEM` |
| Open mode | READ WRITE | READ WRITE |
| NLS language | AMERICAN | AMERICAN |
| MCP autocommit | OFF | OFF |
| DBID / database | 1773986901 / ORCL | 1773986901 / ORCL |
| AWR snapshots in latest direct query | 25 rows, snap IDs 1-25, `CON_ID=0`, zero errors | 25 rows, snap IDs 1-25, all `CON_ID=0` |

The capture SQL references 21 AWR or statistics views. Earlier combined queries completed without access or object errors in both containers, returning a row from all 21 in the CDB and 17 in the PDB; the other four PDB views were empty. Current CDB checks found 3,013 rows in `DBA_HIST_SYSTEM_EVENT` and 4,025 rows in `DBA_HIST_SYSMETRIC_SUMMARY`. Running the capture's AAS query shape returned 253 grouped rows, and its selected main-metrics query returned 25 grouped rows for snapshots 1-25. In PDB1, the same two history views returned zero rows, and `DBA_HIST_SNAPSHOT` returned 25 rows all with `CON_ID=0`; these are not evidence of PDB-level AWR snapshots.

The current CDB check found `DBA_HIST_WR_CONTROL` set to a 10-minute interval and 60-minute retention. `AWR_PDB_AUTOFLUSH_ENABLED=FALSE` in `CDB$ROOT`; Oracle documents that this value has no effect on root snapshots and that an individual PDB's value is honored. The current PDB1 check verified `AWR_PDB_AUTOFLUSH_ENABLED=TRUE`, a 10-minute interval, and 1440-minute retention. Although that PDB-level setting is enabled, its visible history still contains no PDB-scoped rows.

The local CDB capture file `awr-hist-1773986901-ORCL-0-21.out` reports snap IDs 1-21 and `ERROR_COUNT=0`, but it does not contain `MAIN-METRICS` or `AVERAGE-ACTIVE-SESSIONS` blocks. The active parser failed against that file because the missing AAS section leaves `DF_AAS_INT` without `WAIT_CLASS`; later summary generation also lacks an AAS vector. Current CDB queries now show those data are available, so the old output does not establish a general parser defect or current data absence. A refreshed capture and parser run remain necessary. The generated file is not committed because it contains database-derived AWR data.

An attempt to execute `source/awr_miner.sql` through the SQLcl MCP runner stopped on SQL*Plus-specific commands (`SET UNDERLINE`, `REPHEADER`, and `REPFOOTER`). This does not establish SQL*Plus incompatibility; use the installed SQL*Plus 19.3 client for the capture-path check.

## Assessment

The 19c endpoints, services, AWR dictionary access, queryability of the capture views, and current CDB AAS/main-metrics query data are verified. PDB1's current visible history does not establish PDB-level AWR: its snapshots are `CON_ID=0`, and the checked event/metric history views are empty. CDB end-to-end capture compatibility remains unverified until a current SQL*Plus output passes the parser.

`source/awr_miner.sql` explicitly exits when a DBID has two or fewer snapshots. Both current scopes show 25 snapshot rows, but the direct-PDB rows are all `CON_ID=0`; snapshot count alone is not sufficient to establish PDB AWR availability.

## Remaining Work

- Run a fresh `source/awr_miner.sql` capture from `CDB$ROOT` with SQL*Plus 19.3 and validate the output using the pinned R 4.6.1 parser container.
- Determine why PDB1 exposes only `CON_ID=0` snapshots and empty system-event/sysmetric-summary history despite `AWR_PDB_AUTOFLUSH_ENABLED=TRUE`; verify the resulting state in the CDB views.
- Once PDB-scoped AWR history is visible, capture directly from `PDB1` and validate it with the Phase 2 parser checks.
- Record any SQL*Plus-specific behavior and decide whether one capture script can serve both scopes or separate scripts are needed.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
