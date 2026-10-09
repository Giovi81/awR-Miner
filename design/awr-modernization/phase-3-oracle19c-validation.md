# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** In progress; metadata checks passed on 2026-10-09 for both approved targets. The reported settings are verified and each scope now exposes 20 snapshots. End-to-end capture and parser validation are still pending.

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
| AWR snapshots visible to capture | 20 (snap IDs 1-20; `CON_ID=0`) | 20 (snap IDs 1-20; `CON_ID=0`) |
| Latest snapshot end time | 2026-10-09 21:50:57 | 2026-10-09 21:50:57 |

Both MCP sessions used `SYSTEM`, reported Oracle 19.3.0.0.0 in READ WRITE mode, NLS language AMERICAN, and autocommit OFF. The capture SQL references 21 AWR or statistics views. A combined query against all 21 completed without access or object errors in both containers. It returned a row from all 21 in the CDB and 17 in the PDB; the other four PDB views were empty, not inaccessible.

The refreshed CDB check found `DBA_HIST_WR_CONTROL` set to a 10-minute snapshot interval and 24-hour retention for DBID `1773986901`. In `CDB$ROOT`, `AWR_PDB_AUTOFLUSH_ENABLED` remains `FALSE`; this is the root-level value and does not report the PDB-specific setting.

The direct `PDB1` check confirmed `AWR_PDB_AUTOFLUSH_ENABLED=TRUE`. `DBA_HIST_DATABASE_INSTANCE` exposed DBID `1773986901`, and `DBA_HIST_SNAPSHOT` returned 20 snapshots for that DBID. This is the DBID and snapshot count the capture script uses in the direct-PDB connection. `CDB_HIST_SNAPSHOT` in the CDB reports the corresponding 20 root snapshots.

## Assessment

The 19c endpoints, services, AWR dictionary access, queryability of the capture script's referenced views, updated snapshot settings, and sufficient snapshot counts are verified. These checks do not establish that the complete capture script runs or that generated output parses correctly.

`source/awr_miner.sql` exits when the selected DBID has two or fewer snapshots. Both approved targets now expose 20 snapshots for the DBID selected by the script, so the snapshot-count precondition is met. No capture script has been run yet.

## Remaining Work

- Run `source/awr_miner.sql` separately from `CDB$ROOT` and `PDB1`; retain each generated output file and validate it with the Phase 2 parser checks.
- Record any SQL*Plus-specific behavior and decide whether one capture script can serve both scopes or separate scripts are needed.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
