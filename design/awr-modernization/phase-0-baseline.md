# Phase 0 Baseline Assessment

**Assessment date:** 2026-10-08  
**Status:** Complete as a read-only repository and documentation assessment. The user selected R 4.6.1 (no older-R backward-compatibility requirement) and Oracle Database 19c, with both CDB-level and PDB-level AWR, as the scope for this iteration. The user confirms the authorized SQL Developer connections have saved credentials and the required licenses. Any database commands are restricted to `SELECT` statements only. No Oracle database was accessed. No runtime source, SQL, release snapshot, or build file was modified.

## Executive Summary

The active workflow is a script-based R parser/plotter plus a SQL*Plus capture script. The working path is `source/`; historical releases were consulted only for a narrow version-metadata comparison. The approved modernization targets are R 4.6.1 and Oracle Database 19c only, with CDB-level and PDB-level AWR both in scope. No database compatibility has been demonstrated. Oracle AI Database 26ai and other newer releases are outside the current scope unless separately approved. A graphical interface is deferred to a future release; evaluate separate SQL captures for CDB and direct-PDB connections within this release's planning.

The repository contains usable compressed capture fixtures and some previously generated outputs, but no automated test harness, dependency lockfile, or Docker test setup was found. A read-only R 4.6.1 smoke check confirms that base `readLines()` can read one `.out.gz` fixture directly. This does not validate the complete parser, plots, or SQL capture.

## Compatibility Matrix

| Component | Verified fact | Intended target / decision | Evidence status |
| --- | --- | --- | --- |
| R | R 4.6.1 was released 2026-06-24. R 4.6.2 prereleases were scheduled to start 2026-10-19, with final release scheduled for 2026-10-29. | Approved release floor and modernization target: R 4.6.1. No older-R backward-compatibility requirement. | Release fact verified from R Project/CRAN on 2026-10-08. Only a base-R gzip-read smoke check was run; application compatibility is untested. |
| Oracle Database 19c | Official 19c documentation and reference pages are available. `DBA_HIST_DATABASE_INSTANCE` documents multitenant fields including `CDB`, `CDB_ROOT_DBID`, and `CON_ID`. The active capture script uses AWR views and contains conditional-compilation branches through 12.2. | Approved sole Oracle target for this iteration; both CDB-level and PDB-level AWR are required. Separate SQL capture scripts may be evaluated. | Scope approved; compatibility remains unverified. Static inspection and documentation review only; no 19c SQL*Plus or database integration test has run. |
| Oracle releases newer than 19c | Oracle AI Database 26ai documentation exists; its AWR documentation describes `AWR_ROOT` and `AWR_PDB` multitenant alternatives to `DBA_HIST` views. | 26ai and other newer releases are outside this iteration's scope. Revisit only with separate approval. | Documentation facts verified; no AWR-Miner compatibility claim. |
| SQL*Plus / SQLcl | The capture script uses SQL*Plus commands and substitution behavior listed below. | Select exact SQL*Plus client version(s) for the Oracle 19c CDB/PDB tests during Phase 1. SQLcl compatibility is not assumed. | No client-version compatibility test has run. |

A documentation page, matching version guard, or successful single-file read is not evidence of end-to-end product compatibility. The selected target versions define scope, not proven support.

## User Decisions and Test Environments (2026-10-08)

- No backward compatibility with R versions older than 4.6.1 is required. Treat R 4.6.1 as both the release floor and target; verify the application on that runtime before claiming support.
- Oracle Database 19c must support both CDB-level and PDB-level AWR capture. Evaluate whether separate SQL capture scripts are warranted; no capture design or SQL changes have been approved yet.
- A graphical interface is desired but explicitly deferred to a future release. Keep this release's workflow script-based.
- The user authorized SQL Developer connection aliases `DBI_CGEMS401` (CDB) and `DBI_CGEMS401_PGEMS4` (direct PDB) as candidate integration-test environments. These are connection names only; no credentials are recorded here. No connection or query was made during this assessment.
- Before running licensed AWR capture queries, confirm Diagnostic Pack entitlement for the relevant environments and have the DBA approve the required read privileges. Connection authorization alone does not establish licensing or database grants.

## Active R Workflow

### Entrypoint and direct packages

The root README directs users to run `source/R-AWR-Mining.R`. In non-interactive use, the script takes the capture working directory as its first argument and changes into it. The default file pattern includes `.out` and `.gz` captures. `settings.R` is optionally sourced from that working directory.

The entrypoint attaches these contributed packages: `checkpoint`, `futile.logger`, `ggplot2`, `plyr`, `gridExtra`, `scales`, `reshape`, `xtable`, `ggthemes`, `stringr`, `data.table`, `lubridate`, `gplots`, `gtools`, `dplyr`, and `sjPlot`. It also attaches base package `grid`. This is the direct attachment list, not a complete transitive dependency inventory.

The script calls `checkpoint("2015-05-01")`. Dependency resolution and package availability therefore need deliberate replacement or reproducible pinning; no package versions or full dependency closure have been recorded. `source/commonFunctions.R` contains a separate `install.packages()` bootstrap using an HTTP CRAN mirror and a package list that includes `lazyeval`; references found for it are in `source/1-offs/Combined-Stats/`, not the primary entrypoint. Treat those one-off workflows separately when defining the supported scope.

`parseMode` is set to `"old"` in the active script. That path reads the capture using `readLines()`. The `"new"` path calls `read_file()`, but it is not the default and `readr` is not attached in the primary package list. Do not assume that path is currently supported without a focused test.

### Inputs, outputs, and fixture evidence

- `test-cases/` contains compressed AWR capture fixtures, including `awr-hist-1132973626-ORCL-112295-112992.out.gz`.
- `source/test-files-Nov-1/` contains compressed captures and pre-generated artifacts, including `.Rda`, `.pdf`, CSV, and error outputs. These may help establish expected outputs, but no golden-output comparison or automated test convention was found.
- A read-only Docker check using `r-base:4.6.1` resolved to image digest `sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7`. Base R `readLines()` read the first line (`~~BEGIN-OS-INFORMATION~~`) from the compressed fixture directly. The fixture mount was read-only; no R packages were installed and no project parser was run.
- The parser and report workflow writes to its working directory: parsed `.Rda` data, plot PDFs, summary HTML, `OverallSummary.csv`, and `attributes.csv`; error handling can create an `error/` directory and copy failed captures. Any full parser check should run in a disposable writable container directory populated from read-only fixture mounts.
- No `DESCRIPTION`, `renv.lock`, Dockerfile/Compose file, `testthat`/`tests` tree, or workflow test configuration was found by the targeted repository search. A repeatable full parser command and package installation recipe remain to be designed in Docker.

The smoke check only disproves the narrow concern that this R version cannot read that compressed fixture via direct `readLines()`. It is not a parser acceptance test.

## SQL Capture and Oracle Requirements

### Licensing and access boundary

`source/awr_miner.sql` asks the operator to confirm Diagnostic Pack licensing and exits unless the answer is YES. This is an explicit acknowledgement gate, not an entitlement check. Oracle's 19c Licensing Information User Manual lists Oracle Diagnostics Pack as separately licensed for applicable offerings and includes AWR among its features. Licensing depends on the specific offering and deployment; AWR-Miner must preserve the gate and must not determine an organization's entitlement.

### Referenced data dictionary objects

Static search of the active capture SQL found the following historical AWR views:

- `DBA_HIST_DATABASE_INSTANCE`, `DBA_HIST_SNAPSHOT`, `DBA_HIST_PARAMETER`, `DBA_HIST_OSSTAT`
- `DBA_HIST_SGASTAT`, `DBA_HIST_PGASTAT`, `DBA_HIST_SYSMETRIC_SUMMARY`
- `DBA_HIST_SGA_TARGET_ADVICE`, `DBA_HIST_PGA_TARGET_ADVICE`, `DBA_HIST_DATAFILE`, `DBA_HIST_TBSPC_SPACE_USAGE`
- `DBA_HIST_SYSTEM_EVENT`, `DBA_HIST_SYS_TIME_MODEL`, `DBA_HIST_EVENT_HISTOGRAM`, `DBA_HIST_SYSSTAT`
- `DBA_HIST_SEG_STAT_OBJ`, `DBA_HIST_SEG_STAT`, `DBA_HIST_IOSTAT_FUNCTION`
- `DBA_HIST_SQLSTAT`, `DBA_HIST_SQLTEXT`

Other referenced views are `DBA_CPU_USAGE_STATISTICS`, `SYS.GV_$DATABASE`, and `V$PDBS`. The SQL therefore needs read access to this object set for the selected execution path. The exact least-privilege grant mechanism, including any direct grants needed by PL/SQL blocks and multitenant execution context, is not established by static inspection. Do not prescribe a broad role or run grant scripts without DBA review and an authorized database test.

### SQL*Plus and version-sensitive constructs

The active SQL uses `DEFINE`, `ACCEPT`, `PROMPT`, `COLUMN ... NEW_VALUE`, bind variables, `WHENEVER SQLERROR`, `SET SERVEROUTPUT`, SQL*Plus `SPOOL`, report headers/footers, and PL/SQL conditional compilation via `PLSQL_CCFLAGS`. It computes a database version and defines guards for 11.1, 11.2, 12.1, and 12.2; the inspected block contains no explicit 19c branch. The capture also queries multitenant state and counts PDBs, but the current AWR queries use `DBA_HIST` objects. The selected 19c CDB/PDB scope requires checking which AWR data is visible from each connection and whether separate capture scripts are warranted.

No SQL*Plus or SQLcl run has been performed. The exact client version, grants, object-column compatibility, SQL error behavior, and spool output have not been validated against the authorized 19c CDB and direct-PDB environments. Static view names do not establish that all referenced columns or client behavior match. Under the current authorization, only SELECT-based metadata and AWR-view checks may be run; the existing capture scripts must not be run because they include `ALTER SESSION`, PL/SQL, SQL*Plus prompts, and spooling as well as SELECTs.

## Documentation, Versions, and Release Automation

- The root README describes the old desktop workflow and says R 3.x+. It must not be treated as evidence of a current minimum version.
- The active R plot version is `5.0.5`; active `source/awr_miner.sql` declares capture version `5.1.1`; `ant/build.xml` uses major version `5.0` plus an incrementing build number.
- The `release/5.0.8/` snapshot has R plot and capture SQL metadata both set to `5.0.8`. It was consulted only to identify this divergence, not used as a source for modernization changes.
- Ant's default `build` target is unsafe for routine checks: it depends on `clean` (deletes `build/`), increments `ant/mybuild.number`, edits source version metadata, builds and moves release artifacts, checks out `README.md` from `origin`, and invokes Git add/commit, tag, and push targets. Do not invoke it without explicit release authorization.

## Official Sources Checked

All checked on 2026-10-08:

- R Project news: https://www.r-project.org/
- CRAN release information: https://cran.r-project.org/
- Oracle Database 19c documentation: https://docs.oracle.com/en/database/oracle/oracle-database/19/
- Oracle Database 19c `DBA_HIST_DATABASE_INSTANCE` reference: https://docs.oracle.com/en/database/oracle/oracle-database/19/refrn/DBA_HIST_DATABASE_INSTANCE.html
- Oracle Database 19c Licensing Information User Manual: https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/Licensing-Information.html
- Oracle AI Database 26ai documentation: https://docs.oracle.com/en/database/oracle/oracle-database/26/
- Oracle AI Database 26ai AWR views guidance: https://docs.oracle.com/en/database/oracle/oracle-database/26/tgdba/using-automatic-workload-repository-views.html
- Oracle Database 19c security guide (general privileges and roles): https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/configuring-privilege-and-role-authorization.html

## User Decisions and Test Environments (2026-10-08)

- No backward compatibility with R versions older than 4.6.1 is required. Treat R 4.6.1 as both the release floor and target; verify the application on that runtime before claiming support.
- Oracle Database 19c must support both CDB-level and PDB-level AWR capture. Evaluate whether separate SQL capture scripts are warranted; no capture design or SQL changes have been approved yet.
- A graphical interface is desired but explicitly deferred to a future release. Keep this release's workflow script-based.
- The user authorized SQL Developer connection aliases `DBI_CGEMS401` (CDB) and `DBI_CGEMS401_PGEMS4` (direct PDB) as test environments, confirms credentials are saved, and confirms required licenses are available. No credentials are recorded here. No connection or query was made during this assessment.
- Database command authorization is strictly SELECT-only. Do not run DDL, DML, PL/SQL blocks, `ALTER SESSION`, or existing capture scripts. The capture scripts' non-SELECT operations are outside this authorization; end-to-end capture validation would require separate explicit authorization.
- Required read privileges still need to be established for the authorized user. Do not use broad role grants or modify database privileges; report access errors for DBA review.

## Phase 0 Exit Criteria

| Criterion | Result |
| --- | --- |
| Active source paths and workflow mapped | Complete for primary R entrypoint and capture SQL; one-off scripts remain outside the primary workflow. |
| Direct package list and dependency-management risks recorded | Complete as an initial inventory; transitive package closure and pinned versions remain for Phase 1. |
| Existing fixtures and safe local evidence identified | Complete; one base-R compressed-fixture smoke check passed. Full parser/output test not run. |
| Oracle objects, license gate, SQL*Plus constructs, and compatibility unknowns recorded | Complete by static inspection; exact least-privilege grants and database behavior remain unverified. |
| Current R and Oracle documentation facts recorded | Complete; R 4.6.1 and Oracle 19c scope are approved. Oracle runtime compatibility remains unverified and requires the separately scoped Phase 3 checks. |
| Authorized Oracle test environments and access boundary recorded | Complete; the CDB and direct-PDB aliases are identified, but no connection or query was made during this read-only baseline. SELECT-only environment checks are assigned to Phase 3. |
| Release automation hazards inspected | Complete; default Ant build must not be used for ordinary validation. |

## Decisions to Carry Forward

1. R 4.6.1 is the approved release floor/target; no older-R backward-compatibility requirement.
2. Oracle Database 19c CDB-level and PDB-level AWR are both in scope. Evaluate unified versus separate capture scripts without changing SQL until a design is reviewed.
3. The current script workflow remains for this release; GUI work is deferred.
4. The user identified authorized test aliases `DBI_CGEMS401` (CDB) and `DBI_CGEMS401_PGEMS4` (direct PDB), with saved credentials and required licenses. Database commands remain SELECT-only; confirm read access through those queries and do not run capture scripts.
5. Review and approve the Phase 1 container/dependency design before adding Docker or dependency files. This baseline does not authorize runtime, dependency, or container changes.
