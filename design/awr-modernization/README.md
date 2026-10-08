# AWR-Miner Modernization Design

## Status

Phase 0 baseline completed on 2026-10-08; see [phase-0-baseline.md](phase-0-baseline.md) for evidence and compatibility status. The approved release floor/target is R 4.6.1 with no older-R backward-compatibility requirement. Oracle Database 19c is the only database target, with both CDB-level and PDB-level AWR in scope. These are scope decisions, not compatibility claims or authorization to modify runtime files. Phase 0 is closed as a read-only repository and documentation assessment; live Oracle checks remain in Phase 3 and are limited to authorized `SELECT` statements.

## Goal

Prepare a reviewable, testable modernization of AWR-Miner targeting R 4.6.1 and Oracle Database 19c, covering CDB-level and PDB-level AWR. Keep the current script workflow for this release; evaluate whether CDB and PDB capture need separate SQL scripts. A graphical interface is explicitly deferred to a future release. Newer Oracle releases are outside the current scope.

## Confirmed Constraints

- `source/` is the working implementation; `release/` contains historical snapshots and is not a modernization target.
- Run R, dependency installation, tests, and builds in pinned Docker containers. Do not install tooling on the host.
- Keep fixture-based parser checks separate from checks requiring Oracle access.
- Preserve the AWR Diagnostic Pack license check. Identify and document required Oracle privileges and licensed views before claiming capture compatibility.
- CDB-level and PDB-level AWR are both required on Oracle Database 19c; assess separate capture scripts as a design option.
- Defer the graphical interface to a later release; do not expand the current release into a GUI project.
- Oracle database access is restricted to `SELECT` statements only. Do not issue DDL, DML, PL/SQL blocks, `ALTER SESSION`, or run the existing capture scripts.
- Do not run the default Ant `build` target for routine analysis or validation. It changes source/release artifacts and includes Git operations.
- Do not commit, tag, push, access a database, or make architectural changes without explicit authorization. The approved Oracle access for this work remains `SELECT`-only; Phase 0 did not connect to either database.

## Initial Repository Anchors

- R workflow: `source/R-AWR-Mining.R`, `source/settings.R`, and supporting R scripts under `source/`.
- SQL capture: `source/awr_miner.sql` and `source/awr_miner_historical.sql`.
- Available fixture locations: `test-cases/` and `source/test-files-Nov-1/`.
- Existing user documentation: `README.md` and `doc/`.
- Release automation to inspect, but not invoke by default: `ant/build.xml`.

These are starting points, not yet a complete dependency or behavior map.

## Phase 0 Baseline

The read-only baseline is complete. It records the current R release fact, active package and capture paths, fixture evidence, Oracle object/licensing requirements, SQL*Plus constructs, metadata drift, and Ant release side effects. It clearly separates documentation facts from compatibility claims that still need execution-based evidence.

The only runtime check was a read-only R 4.6.1 smoke test of one compressed fixture inside Docker. Full parser, plot, SQL*Plus, and Oracle integration checks were not run.

## Work Sequence

### 0. Baseline assessment

- Inspect the active R parser, settings, SQL capture paths, documentation, Ant targets, and available fixtures.
- Record the current dependency inventory and existing testable behavior.
- Verify the latest stable R release against the R Project on the assessment date.
- Verify the Oracle 19c CDB-level and PDB-level requirements against current Oracle primary documentation. Record the authorized test environments and defer their live `SELECT`-only checks to Phase 3.
- Deliverable: a dated baseline and compatibility matrix that distinguishes verified facts, intended support, and untested hypotheses.
- Acceptance: every version claim has an official source; each matrix cell identifies its evidence or its required test.
- Risk and rollback: assessment is read-only; no source rollback is needed.

### 1. Reproducible test environment

- Pin the initial fixture-smoke image to `r-base:4.6.1` at digest `sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7`.
- First acceptance check: run base R with Docker networking disabled, mount the existing compressed fixture read-only, and verify its first line is `~~BEGIN-OS-INFORMATION~~`. This isolates the test from Oracle, CRAN, and host-side R.
- The full parser's direct CRAN dependencies are not yet reproducibly pinned. Before parser tests, resolve the interaction between `checkpoint("2015-05-01")` and a project lockfile; then lock the complete direct and transitive dependency set rather than installing unversioned packages during image build.
- Keep fixture inputs read-only and route generated files to a disposable writable directory. Keep credentials out of images and command history.
- Add repository Docker/test files only after this design is reviewed. Do not change the runtime entrypoint or dependency mechanism as part of this environment proposal.
- Acceptance: the base-R fixture check produces the same result on repeated runs without Oracle access, CRAN access, or host-side R installation; the later parser environment must restore only pinned dependencies.
- Risk and rollback: keep container setup additive and retain the current script workflow; remove or revise only newly proposed container/test artifacts if the approach is rejected.

### 2. R parser and output validation

- Build focused checks from existing fixtures before changing parser behavior.
- Cover parsed data and representative plots/reports, including malformed or incomplete capture inputs where fixtures permit.
- Acceptance: baseline behavior is recorded, regression checks are repeatable, and any intentional behavior change is separately approved.
- Risk and rollback: isolate implementation changes from historical releases and retain fixture-backed comparisons to the prior behavior.

### 3. SQL*Plus and Oracle compatibility

- Review capture SQL, SQL*Plus assumptions, AWR views/columns, version guards, privileges, and Diagnostic Pack licensing.
- Evaluate the CDB and direct-PDB paths using `SELECT`-only checks on the authorized SQL Developer connections `DBI_CGEMS401` (CDB) and `DBI_CGEMS401_PGEMS4` (direct PDB); decide whether capture should remain unified or use separate SQL scripts.
- The user confirms these environments have the required licenses and saved credentials. Do not run the existing capture scripts: they contain non-SELECT operations. Keep read-only database checks separate from local fixture tests.
- Acceptance: document what the approved SELECT-only checks establish for each 19c container scope; do not claim end-to-end capture compatibility without executing the capture path under separately authorized operations.
- Risk and rollback: avoid database changes; keep capture-script modifications narrow and reversible, and do not run integration checks without authorization.

### 4. Documentation and release packaging

- Update setup, supported-version statements, privileges/licensing, container usage, and validation instructions only after evidence exists.
- Keep GUI design and implementation outside this release; record it as follow-up scope for a later release.
- Inspect Ant release targets and define a safe local packaging procedure without invoking targets that commit, tag, or push.
- Acceptance: documentation matches tested support, release artifacts are locally reviewable, and no remote Git action occurs without explicit approval.
- Risk and rollback: preserve existing release snapshots; discard only newly generated, unapproved artifacts.

## Decisions Before Implementation

- Phase 0 is complete. Its evidence is a static repository/documentation assessment plus the documented base-R fixture smoke check; it does not establish full parser or Oracle compatibility.
- Phase 1 implementation remains gated on review of the pinned Docker/dependency proposal. Keep runtime files unchanged until that review is approved.
- Decide whether CDB-level and direct-PDB capture should use one or separate SQL scripts during Phase 3 design, after the authorized `SELECT`-only metadata checks. Do not run capture scripts or other non-SELECT database operations under the current authorization.
- Keep the GUI deferred to a future release, as already agreed.

## Next Action

Phase 0 is closed. The next work item is review of the Phase 1 pinned-container and dependency proposal; only after approval should additive Docker/test setup be introduced. Keep runtime files unchanged, defer GUI work, and keep Oracle checks SELECT-only and separate from local fixture tests.
