# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** In progress; CDB capture and parser validation passed on Oracle 19.3 / SQL*Plus 19.3 / R 4.6.1. In PDB1, a direct `DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT` call completed without error, but visible snapshots remain `CON_ID=0`, event/metric history is empty, and a fresh direct-PDB capture still fails parser validation due to missing AAS/main-metrics sections.

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
| AWR snapshots in latest direct query | 25 rows, snap IDs 1-25, `CON_ID=0`, zero errors | 31 rows, snap IDs 1-31, all `CON_ID=0` |

The capture SQL references 21 AWR or statistics views. Earlier combined queries completed without access or object errors in both containers, returning a row from all 21 in the CDB and 17 in the PDB; the other four PDB views were empty. Current CDB checks found 3,013 rows in `DBA_HIST_SYSTEM_EVENT` and 4,025 rows in `DBA_HIST_SYSMETRIC_SUMMARY`. Running the capture's AAS query shape returned 253 grouped rows, and its selected main-metrics query returned 25 grouped rows for snapshots 1-25. In PDB1, the same two history views returned zero rows, and `DBA_HIST_SNAPSHOT` returned 25 rows all with `CON_ID=0`; these are not evidence of PDB-level AWR snapshots.

The current CDB check found `DBA_HIST_WR_CONTROL` set to a 10-minute interval and 60-minute retention. `AWR_PDB_AUTOFLUSH_ENABLED=FALSE` in `CDB$ROOT`; Oracle documents that this value has no effect on root snapshots and that an individual PDB's value is honored. The current PDB1 check verified `AWR_PDB_AUTOFLUSH_ENABLED=TRUE` at `CON_ID=3`, a 10-minute interval, and 1440-minute retention. An explicit `DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT` call through SQL*Plus 19.3 completed successfully, but the follow-up query still showed only 31 rows in `DBA_HIST_SNAPSHOT`, all `CON_ID=0`, and zero rows in `DBA_HIST_SYSTEM_EVENT` and `DBA_HIST_SYSMETRIC_SUMMARY`.

The earlier local capture `awr-hist-1773986901-ORCL-0-21.out` reported snap IDs 1-21 but lacked `MAIN-METRICS` and `AVERAGE-ACTIVE-SESSIONS`, so parser execution failed on missing `DF_AAS_INT$WAIT_CLASS`. A fresh SQL*Plus run generated `awr-hist-1773986901-ORCL-0-26.out` with 19 sections. The active parser completed and generated a parsed RDA, PDF, HTML, and CSV without an error log. The parsed tables contain 26 `DF_MAIN` rows, 264 `DF_AAS` rows, and 446 `DF_IO_WAIT_HIST` rows.

The first parse of the fresh CDB capture exposed an unavailable `tbl_dt()` helper in the I/O-wait fill joins. Replacing those three calls with `data.table()` allowed the parser to finish; the Phase 2 offline parser/output test passed afterward. A subsequent PDB1 capture, `awr-hist-1773986901-ORCL-0-31.out`, still contained only 13 sections and omitted `MAIN-METRICS` and `AVERAGE-ACTIVE-SESSIONS`. The pinned R 4.6.1 parser failed because `DF_AAS_INT` had no `WAIT_CLASS`; the missing PDB history data remained after the manual snapshot call. Capture and parsed artifacts are not committed because they contain database-derived AWR data. An attempt to execute `source/awr_miner.sql` through the SQLcl MCP runner stopped on SQL*Plus-specific commands (`SET UNDERLINE`, `REPHEADER`, and `REPFOOTER`); the SQL*Plus 19.3 runs are the compatibility evidence for this script.

## Assessment

The 19c endpoints, services, AWR dictionary access, queryability of the capture views, and end-to-end CDB capture/parser path are verified. Direct invocation of `CREATE_SNAPSHOT` in PDB1 completed but did not result in visible PDB-scoped history. PDB1's snapshots are still `CON_ID=0`, its checked event/metric history views are empty, and the direct-PDB capture does not parse. Direct-PDB end-to-end capture compatibility remains unverified.

`source/awr_miner.sql` explicitly exits when a DBID has two or fewer snapshots. Both current scopes show 25 snapshot rows, but the direct-PDB rows are all `CON_ID=0`; snapshot count alone is not sufficient to establish PDB AWR availability.

## Remaining Work

- Determine why PDB1 exposes only `CON_ID=0` snapshots and empty system-event/sysmetric-summary history despite `AWR_PDB_AUTOFLUSH_ENABLED=TRUE` and a successful manual snapshot call; verify the resulting state in the CDB views.
- Once PDB-scoped AWR history is visible, capture directly from `PDB1` and validate it with the Phase 2 parser checks.
- Record any SQL*Plus-specific behavior and decide whether one capture script can serve both scopes or separate scripts are needed.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
