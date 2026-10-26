# AWR-Miner Modernization Design

## Status

**Updated 2026-10-26:** Phases 0-2 are complete, and the Oracle 19.3 CDB capture/parser path passed with SQL*Plus 19.3 and R 4.6.1. The current release scope is CDB only. PDB support is deferred and, when resumed, will use a dedicated capture script; prior PDB test results remain historical evidence, not current acceptance criteria. See [phase-3-oracle19c-validation.md](phase-3-oracle19c-validation.md). The release floor/target remains R 4.6.1, with Oracle Database 19c as the only database target. Remaining work is to finalize CDB-specific documentation and safe local release packaging. The default Ant `build` target remains prohibited for routine validation because it includes release and Git side effects.

## Goal

Prepare a reviewable, testable modernization of AWR-Miner targeting R 4.6.1 and Oracle Database 19c for CDB-level AWR only. Keep the current script workflow for this release. PDB support is deferred to a future release and will use a dedicated capture script. A graphical interface is also deferred. Newer Oracle releases are outside the current scope.

## Confirmed Constraints

- `source/` is the working implementation; `release/` contains historical snapshots and is not a modernization target.
- Run R, dependency installation, tests, and builds in pinned Docker containers. Do not install tooling on the host.
- Keep fixture-based parser checks separate from checks requiring Oracle access.
- Preserve the AWR Diagnostic Pack license check. Identify and document required Oracle privileges and licensed views before claiming capture compatibility.
- The current release targets Oracle 19c CDB-level AWR only. PDB support is out of scope and is planned for a future dedicated capture script.
- Defer the graphical interface to a later release; do not expand the current release into a GUI project.
- The user authorized database testing on dedicated targets on 2026-10-09. Current project work is limited to the CDB target; do not perform PDB work as part of this release scope.
- Do not run the default Ant `build` target for routine analysis or validation. It changes source/release artifacts and includes Git operations.
- Do not commit, tag, push, or access a database without explicit authorization. The only database integration target in the current scope is the dedicated CDB environment; fixture tests remain offline.

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

## Phase 1 Result

The repository smoke assertion at `tests/phase1-smoke.R` runs with base R in the digest-pinned R 4.6.1 image, with Docker networking disabled and the repository mounted read-only. It passed twice with the expected fixture marker. This does not test parser dependencies or generated outputs. Parser dependencies and fixture-backed parser/output tests are covered by Phase 2; Oracle checks remain Phase 3 work.

## Phase 2 Result

The full parser dependency lock and digest-pinned Docker environment are implemented. The parser/output check passed twice offline on the USPS fixture, validating stable parsed metrics, parsed-data output, a non-empty PDF, HTML/CSV reports, and malformed-capture error handling. The historical Rda baseline has a documented `DF_MAIN` schema drift from the active parser; see [phase-2-parser-validation.md](phase-2-parser-validation.md). This does not establish Oracle or SQL*Plus compatibility.

## Work Sequence

### 0. Baseline assessment

- Inspect the active R parser, settings, SQL capture paths, documentation, Ant targets, and available fixtures.
- Record the current dependency inventory and existing testable behavior.
- Verify the latest stable R release against the R Project on the assessment date.
- Verify the Oracle 19c CDB-level requirements against current Oracle primary documentation. Record the authorized test environment and defer live checks to Phase 3.
- Deliverable: a dated baseline and compatibility matrix that distinguishes verified facts, intended support, and untested hypotheses.
- Acceptance: every version claim has an official source; each matrix cell identifies its evidence or its required test.
- Risk and rollback: assessment is read-only; no source rollback is needed.

### 1. Reproducible test environment

- Pin the initial fixture-smoke image to `r-base:4.6.1` at digest `sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7`.
- First acceptance check: run base R with Docker networking disabled, mount the existing compressed fixture read-only, and verify its first line is `~~BEGIN-OS-INFORMATION~~`. This isolates the test from Oracle, CRAN, and host-side R. The assertion is maintained in `tests/phase1-smoke.R` and passed twice using the pinned image.
- Phase 2 resolved the retired `checkpoint("2015-05-01")` bootstrap and locked the complete direct and transitive parser dependencies; details and tested versions are recorded in [phase-2-parser-validation.md](phase-2-parser-validation.md).
- Keep fixture inputs read-only and route generated files to a disposable writable directory. Keep credentials out of images and command history.
- The base-R fixture check is complete. Do not change the runtime entrypoint or dependency mechanism as part of Phase 1.
- Acceptance: the base-R fixture check produced the same result on repeated runs without Oracle access, CRAN access, or host-side R installation. The later parser environment must restore only pinned dependencies.
- Risk and rollback: keep container setup additive and retain the current script workflow; remove or revise only newly proposed container/test artifacts if the approach is rejected.

### 2. R parser and output validation

- Build focused checks from existing fixtures before changing parser behavior.
- Cover parsed data and representative plots/reports, including malformed or incomplete capture inputs where fixtures permit.
- Acceptance: baseline behavior is recorded, regression checks are repeatable, and any intentional behavior change is separately approved.
- Risk and rollback: isolate implementation changes from historical releases and retain fixture-backed comparisons to the prior behavior.

### 3. SQL*Plus and Oracle compatibility

- Review capture SQL, SQL*Plus assumptions, AWR views/columns, version guards, privileges, and Diagnostic Pack licensing.
- Validate the CDB path using the authorized Oracle 19c CDB target; keep database-generated capture validation separate from local fixture tests.
- The CDB capture/parser path has passed on the tested 19c environment. PDB checks are historical and deferred; future PDB work will use a dedicated script.
- Acceptance: document what the authorized checks establish for CDB scope; do not claim end-to-end capture compatibility without executing and validating the capture path.
- Risk and rollback: avoid database changes; keep capture-script modifications narrow and reversible, and do not run integration checks without authorization.

### 4. Documentation and release packaging

- Update setup, supported-version statements, privileges/licensing, container usage, and validation instructions only after evidence exists.
- Keep GUI design and implementation outside this release; record it as follow-up scope for a later release.
- Inspect Ant release targets and define a safe local packaging procedure without invoking targets that commit, tag, or push.
- Acceptance: documentation matches tested support, release artifacts are locally reviewable, and no remote Git action occurs without explicit approval.
- Risk and rollback: preserve existing release snapshots; discard only newly generated, unapproved artifacts.

## Decisions Before Implementation

- Phase 0 is complete. Its evidence is a static repository/documentation assessment plus the documented base-R fixture smoke check; it does not establish full parser or Oracle compatibility.
- Phase 1's pinned, offline base-R fixture smoke check and Phase 2's fixture-backed parser/output checks are complete. The Phase 2 result records a pre-existing parsed-table schema difference from the historical baseline.
- Keep the current CDB workflow on its existing capture path. When PDB work resumes, implement and validate it as a dedicated capture script.
- Keep the GUI deferred to a future release, as already agreed.

## Next Action

Phases 0-3 have completed their current-scope checks, including a successful CDB capture/parser run on Oracle 19.3. Finish CDB-specific user documentation and define a safe local packaging procedure. PDB compatibility and its dedicated capture script are deferred to a future scope; the missing PDB `IO-WAIT-HISTOGRAM` data is not a blocker for this release.