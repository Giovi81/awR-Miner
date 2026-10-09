# Phase 3 SQL*Plus and Oracle 19c Compatibility

**Assessment date:** 2026-10-09  
**Status:** In progress; both MCP connections work and metadata checks passed. End-to-end capture is waiting for additional AWR snapshots; the user reports enabling automatic PDB snapshots in `PDB1`, pending verification.

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
| AWR snapshots | 1 (snap ID 1; `CON_ID=0`) | 1 (snap ID 1; `CON_ID=0`) |

The capture SQL references 21 AWR or statistics views. A combined query against all 21 completed without access or object errors in both containers. It returned a row from all 21 in the CDB and 17 in the PDB; the other four PDB views were empty, not inaccessible. `CDB_HIST_SNAPSHOT` in the CDB likewise reports only the `CON_ID=0` snapshot.

The initial CDB check found `DBA_HIST_WR_CONTROL` set to a 60-minute snapshot interval, 8-hour retention, and default Top SQL setting. The initial query of `AWR_PDB_AUTOFLUSH_ENABLED` in the CDB returned `FALSE`. Oracle documents `FALSE` as the default, which disables automatic AWR snapshots for PDBs; the parameter may also be set per PDB.

After those checks, the user reported changing the snapshot interval to 10 minutes, retention to 24 hours, and setting `AWR_PDB_AUTOFLUSH_ENABLED=TRUE` on `PDB1`. These updates have not yet been re-read through MCP, and no new snapshots have yet been observed. The reported PDB-level change is distinct from the earlier value read in `CDB$ROOT`.

## Assessment

The 19c endpoints, services, AWR dictionary access, and queryability of the capture script's referenced views are verified. These checks do not establish that the complete capture script runs or that generated output parses correctly.

`source/awr_miner.sql` explicitly exits when a DBID has two or fewer snapshots. Both targets exposed only one snapshot at the last check, so running the capture then would stop before producing a valid capture. The user has since reported enabling automatic snapshots for `PDB1`; verify the setting and wait for at least three snapshots in each scope before running capture. No SQL capture script was run during the initial checks.

## Remaining Work

- Recheck the reported 10-minute interval, 24-hour retention, and `PDB1` autoflush setting through MCP; wait until each scope has at least three snapshots.
- Run the capture separately from `CDB$ROOT` and `PDB1` once each scope has sufficient snapshots; retain the output files and validate them with the Phase 2 parser checks.
- Record any SQL*Plus-specific behavior and decide whether one capture script can serve both scopes or separate scripts are needed.

## Sources

- Oracle Database 19c `DBMS_WORKLOAD_REPOSITORY`: https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_WORKLOAD_REPOSITORY.html
- Oracle Database 19c `AWR_PDB_AUTOFLUSH_ENABLED`: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/AWR_PDB_AUTOFLUSH_ENABLED.html
