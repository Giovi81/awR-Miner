# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status updated 2026-10-26:** The current release scope is Oracle 19c CDB only. The CDB capture/parser path passed on Oracle 19.3 / SQL*Plus 19.3 / R 4.6.1. Direct-PDB results in this report are retained as historical evidence and are not current acceptance criteria. PDB support is deferred and will use a dedicated capture script in a future scope.

## Scope and Authorization

The approved targets are the Oracle 19c CDB connection `LOCAL_ORCL` and direct-PDB connection `LOCAL_PDB1`. The user confirmed that both databases are dedicated test environments, database work is unrestricted for these tests, and Diagnostic Pack licensing is available. No database settings were changed. An explicit AWR snapshot call was made in PDB1; the initial follow-up query filtered on the CDB DBID and therefore missed the PDB-local DBID and its `CON_ID=3` snapshots.

## Results Recorded During Phase 3

The results below document the original CDB and direct-PDB test scope. CDB evidence remains applicable to the current release; PDB evidence is historical only and is deferred from current acceptance.

Checks used the configured SQLcl MCP connections. Local SQL*Plus is installed at 19.3.0, but the MCP route now resolves both approved targets, so the former local Oracle Net alias issue does not block metadata validation.

| Check | `LOCAL_ORCL` | `LOCAL_PDB1` |
| --- | --- | --- |
| Database version | 19.3.0.0.0 | 19.3.0.0.0 |
| Container / service | `CDB$ROOT` / `orcl` | `PDB1` / `pdb1` |
| Session user | `SYSTEM` | `SYSTEM` |
| Open mode | READ WRITE | READ WRITE |
| NLS language | AMERICAN | AMERICAN |
| MCP autocommit | OFF | OFF |
| AWR DBID / database | 1773986901 / ORCL | 2678021654 / ORCL (CDB DBID is 1773986901) |
| AWR snapshots in latest CDB query | 33 rows, snap IDs 1-33, `CON_ID=0`, zero errors | 13 rows, snap IDs 1-13, `CON_ID=3`, zero errors |

The key correction was to query all AWR DBIDs instead of filtering PDB checks by `V$DATABASE.DBID`, which reports the CDB DBID even in the PDB session. The CDB views now show root history under DBID `1773986901` (`CON_ID=0` snapshots and `CON_ID=1` system events) and PDB history under DBID `2678021654` (`CON_ID=3`). The latest CDB check found 33 root snapshots and 13 PDB snapshots, both with zero `ERROR_COUNT`; system-event history contained 4,116 root rows and 1,057 PDB rows.

The general `DBA_HIST_SYSMETRIC_SUMMARY` view returned no rows for the PDB DBID. Oracle's `DBA_HIST_CON_SYSMETRIC_SUMM` view contains the PDB metrics: from the PDB connection, 612 rows across 12 local snapshots for DBID/CON_DBID `2678021654`; from the CDB view, 1,326 rows for `CON_DBID=2678021654`, `CON_ID=3`. The capture SQL now reads that container-specific view when connected to a PDB and retains the general sysmetric view for root/non-CDB sessions. The PDB DBID also appears in `DBA_HIST_WR_CONTROL` with a 10-minute interval and 24-hour retention.

The PDB reports `AWR_PDB_AUTOFLUSH_ENABLED=TRUE` at `CON_ID=3`, `STATISTICS_LEVEL=TYPICAL`, and `CONTROL_MANAGEMENT_PACK_ACCESS=DIAGNOSTIC+TUNING`; the PDB is READ WRITE and not restricted. The CDB root's autoflush value is `FALSE`, which Oracle documents as having no effect on root snapshots; the per-PDB `TRUE` value is honored. The earlier conclusion that manual snapshot creation produced no PDB record was caused by querying only the CDB DBID. Oracle documents `BESTFIT` as the default flush level, mapped to `LITE` for a PDB.

The earlier local capture `awr-hist-1773986901-ORCL-0-21.out` reported snap IDs 1-21 but lacked `MAIN-METRICS` and `AVERAGE-ACTIVE-SESSIONS`, so parser execution failed on missing `DF_AAS_INT$WAIT_CLASS`. A fresh SQL*Plus run generated `awr-hist-1773986901-ORCL-0-26.out` with 19 sections. The active parser completed and generated a parsed RDA, PDF, HTML, and CSV without an error log. The parsed tables contain 26 `DF_MAIN` rows, 264 `DF_AAS` rows, and 446 `DF_IO_WAIT_HIST` rows.

The CDB capture `awr-hist-1773986901-ORCL-0-26.out` parsed successfully after replacing unavailable `tbl_dt()` calls with `data.table()`. The direct-PDB capture using the correct DBID, `awr-hist-2678021654-ORCL-0-14.out`, contains 16 sections including `MAIN-METRICS` and `AVERAGE-ACTIVE-SESSIONS`. The SQL capture now uses `DBA_HIST_CON_SYSMETRIC_SUMM` for PDB metrics. The parser needed two additional data-tolerance fixes: ignore missing PGA/SGA values when choosing the decimal separator, and treat absent host CPU values as zero for the plot-availability check. The pinned parser completed and produced a parsed RDA, PDF, HTML, and CSV without an error log. Parsed row counts were 13 `DF_MAIN`, 130 `DF_AAS`, and 0 `DF_IO_WAIT_HIST`. The PDB capture contains no `IO-WAIT-HISTOGRAM` section, so that metric family remains unverified/unavailable. The Phase 2 fixture test passed after the parser changes. Captures and parsed artifacts are not committed because they contain database-derived AWR data.

## Assessment

The 19c endpoints, services, AWR dictionary access, CDB-level capture/parser path, and direct-PDB capture/parser path are verified. PDB AWR is in a separate DBID and must be selected explicitly; the CDB DBID from `V$DATABASE` is not the PDB AWR DBID. The PDB capture/parser succeeds for the available metrics, but I/O-wait-histogram collection is not established.

`source/awr_miner.sql` exits when the selected DBID has two or fewer snapshots. The PDB DBID has 13 snapshots; its I/O-wait-histogram section is absent even though system-event and sysmetric container data are available.

## Deferred PDB Work

PDB `IO-WAIT-HISTOGRAM` availability and the dedicated PDB capture script are deferred. They are not blockers for the current CDB-only release. Revisit them when PDB support is explicitly resumed.

## Current CDB Follow-up

- Complete CDB-specific user documentation, including the tested environment, privileges, and Diagnostic Pack licensing requirements.
- Define and validate a safe local packaging procedure without invoking the default Ant `build` target or performing Git release actions.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
- Oracle Database 19c `DBA_HIST_CON_SYSMETRIC_SUMM`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_HIST_CON_SYSMETRIC_SUMM.html
- Oracle Database 19c `DBA_HIST_SYSMETRIC_SUMMARY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_HIST_SYSMETRIC_SUMMARY.html
