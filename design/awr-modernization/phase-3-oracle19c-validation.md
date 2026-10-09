# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** In progress; PDB1 parameter settings and current snapshot metadata were verified through MCP. The PDB-visible snapshot rows are all `CON_ID=0`, its AWR system-event and sysmetric-summary views are empty, and a local CDB capture omits main-metrics/AAS sections and fails parser validation. Root-scope recheck and PDB-level history validation remain open.

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
| AWR snapshot rows in the latest direct query | Not rechecked in `CDB$ROOT`; local capture summary reports 21 rows, snap IDs 1-21 | 25 rows, snap IDs 1-25, all `CON_ID=0` |

The capture SQL references 21 AWR or statistics views. Earlier combined queries completed without access or object errors in both containers, returning a row from all 21 in the CDB and 17 in the PDB; the other four PDB views were empty. A fresh PDB1 check found zero rows in `DBA_HIST_SYSTEM_EVENT` and `DBA_HIST_SYSMETRIC_SUMMARY`. `DBA_HIST_SNAPSHOT` in that PDB returned 25 rows, all with `CON_ID=0`; these are not evidence of PDB-level AWR snapshots.

The current PDB1 check verified `AWR_PDB_AUTOFLUSH_ENABLED=TRUE`, a 10-minute interval, and 1440-minute retention. The last direct CDB check found `DBA_HIST_WR_CONTROL` set to a 60-minute interval and 8-hour retention, with `AWR_PDB_AUTOFLUSH_ENABLED=FALSE`; the root-scope settings need a fresh check because the user subsequently reported changing snapshot settings.

The local CDB capture file `awr-hist-1773986901-ORCL-0-21.out` reports snap IDs 1-21 and `ERROR_COUNT=0`, but it does not contain `MAIN-METRICS` or `AVERAGE-ACTIVE-SESSIONS` blocks. Running the active parser against it in the pinned R 4.6.1 Docker image failed because the missing AAS section leaves `DF_AAS_INT` without `WAIT_CLASS`; the later summary also has no AAS vector. This is an incomplete-capture/data-availability result, not proof of a general parser regression. The generated file is not committed because it contains database-derived AWR data.

## Assessment

The 19c endpoints, services, AWR dictionary access, and queryability of the capture script's referenced views were verified. PDB1's current visible history does not establish PDB-level AWR: its snapshots are `CON_ID=0`, and the checked event/metric history views are empty. The CDB capture output is incomplete, so neither CDB nor PDB end-to-end capture compatibility is established.

`source/awr_miner.sql` explicitly exits when a DBID has two or fewer snapshots. The local CDB output passes that threshold, but required report sections are absent. Do not treat snapshot count alone as sufficient; confirm that the relevant AWR history views contain data before rerunning or accepting a capture.

## Remaining Work

- Recheck current interval, retention, and snapshot counts from `CDB$ROOT`; determine why its local capture omitted main-metrics and AAS sections.
- Determine why PDB1 exposes only `CON_ID=0` snapshots and empty system-event/sysmetric-summary history despite `AWR_PDB_AUTOFLUSH_ENABLED=TRUE`.
- Once both scopes expose the required AWR history data, run captures separately from `CDB$ROOT` and `PDB1`, then validate them with the Phase 2 parser checks.
- Record any SQL*Plus-specific behavior and decide whether one capture script can serve both scopes or separate scripts are needed.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
