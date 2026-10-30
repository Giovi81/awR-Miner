# Phase 4 Documentation and Release Preparation

**Status:** Complete for documentation and local packaging preparation (2026-10-30). No package artifact or release was created. Phase 3 is formally complete for its approved scope; the PDB I/O-wait-histogram gap is deferred to a future release. This work does not authorize database access, commits, tags, or pushes.

## Progress

- Verified on 2026-10-30 from the CRAN R sources page that R 4.6.2 was released on 2026-10-29; it is not tested for AWR-Miner. The latest tested version remains R 4.6.1. Oracle's 19c licensing manual lists AWR under Oracle Diagnostics Pack (checked 2026-10-26).
- Updated the root README with the tested versions, the current R release fact, CDB/PDB capture paths, licensing/access caveats, the deferred PDB histogram limitation, and the offline Docker parser test reference.
- Identified the root README as the current operator guide and marked `doc/readme_awr_miner.html` and `doc/awr_miner.sql` as historical 2.9 documents. The settings options in the README remain documented because they are present in the active parser/settings code.
- Built the pinned Phase 2 Docker test image and passed `tests/phase2-parser.R` offline after the README update.
- Documented a local-only staging and review procedure below. Ant packaging was inspected but not run; no package artifacts or release have been created.

## Objective

Align user-facing instructions with the verified R 4.6.1 and Oracle Database 19c scope, document setup, capture licensing and access prerequisites, and define a locally reviewable packaging process that does not mutate working source or perform Git release operations.

## Scope

- Update the root README and relevant capture/parser documentation to distinguish tested support from older claims and untested environments.
- Document the tested script workflow, pinned Docker parser-test environment, test commands, and separate CDB/PDB capture entrypoints.
- Preserve the Diagnostic Pack confirmation gate. Explain that entitlement is the operator's responsibility and that required Oracle read access depends on the executed path; exact least-privilege grants remain unverified and must not be guessed.
- State that CDB and direct-PDB capture/parser paths were tested on Oracle 19.3 with SQL*Plus 19.3 and R 4.6.1. Do not imply support for other Oracle or SQL client versions.
- Record the missing PDB I/O-wait-histogram data as a known limitation deferred to a future release.
- Inspect Ant packaging behavior and define a local-only procedure producing reviewable artifacts without invoking commit, tag, push, source version mutation, or historical release replacement.

Out of scope: changing capture/parser behavior, investigating the deferred PDB metric, adding GUI functionality, changing historical `release/` snapshots, running database captures, and publishing a release.

## Initial Documentation Gaps

- At the start of Phase 4, the root `README.md` still said Oracle 10.1+ and R 3.x+ and assumed an RStudio workflow. The current README now documents tested scope and script-based usage; its supported settings options remain documented.
- `doc/readme_awr_miner.html` and `doc/awr_miner.sql` are historical 2.9 documents, now labeled as such. The current operator instructions and capture entrypoints are in the root README and `source/`.
- The Phase 0 baseline records required AWR views but does not establish a least-privilege grant recipe. Document this limitation and request DBA review rather than recommending broad grants.
- The default Ant `build` target is unsafe for ordinary validation: it checks out README content, increments the build number, edits active version metadata, moves release artifacts, and invokes Git add/commit/tag/push targets.

## Work Plan

1. [x] Verify current R and Oracle documentation facts against primary sources before updating support statements; record the check date and exact tested versions.
2. [x] Confirm which user-facing docs are authoritative and map current instructions to active `source/` scripts and pinned tests.
3. [x] Document setup, capture prerequisites/licensing, tested compatibility, limitations, and fixture-test instructions. Keep database integration results separate from offline parser checks.
4. [x] Inspect Ant targets and document local-only staging/review without invoking release targets.
5. [x] Review the resulting docs for stale version claims, unverified grants, data handling, and accidental release side effects.

## Acceptance Criteria

- Version statements distinguish tested support (R 4.6.1, Oracle 19.3, SQL*Plus 19.3) from intended scope and untested combinations.
- Diagnostic Pack licensing, operator responsibility, Oracle access prerequisites, and the absence of a verified least-privilege grant recipe are clear.
- CDB/PDB entrypoints and the deferred PDB histogram limitation are accurately described.
- Parser checks can be followed using the pinned Docker instructions without host-side R or Oracle access.
- Locally generated AWR capture files and parsed outputs remain test evidence and are excluded from all package artifacts.
- A local packaging procedure is documented and reviewable without changing active source/version metadata, overwriting historical releases, or performing Git operations.
- No release is created or published as part of Phase 4 documentation work.

## Validation and Risks

- Run the focused documentation consistency checks available in the repository and inspect the final diff. Run parser tests only if a documentation edit changes their instructions; use the pinned Docker environment.
- Do not run Ant's default `build` target. No R, package manager, Java/Ant, or other development tool may be installed on the host.
- Preserve user changes and any local AWR-derived artifacts. Do not add database captures or parsed outputs to documentation or release artifacts.
- Roll back only newly introduced documentation edits if rejected; leave historical releases and pre-existing user changes untouched.

## Safe Local Packaging Procedure

This procedure prepares a reviewable staging directory only. It was not executed, and no archive or release was created.

1. Work in a new disposable staging directory outside the repository's `source/`, `release/`, and `build/` paths.
2. Copy only an explicitly reviewed allowlist of current runtime files: `README.md`, `source/R-AWR-Mining.R`, `source/awr_miner.sql`, and `source/awr_miner_pdb.sql`. Add other user-facing files only after confirming they are current and required.
3. Exclude `release/`, `build/`, `test-cases/`, `source/test-files-Nov-1/`, `source/1-offs/`, local settings, and all capture or generated-data files, including `.out`, `.gz`, `.Rda`, `.pdf`, and generated `.csv` files.
4. Review the staged file manifest and confirm no capture data or generated output is present. If an archive is later required, create it only with an approved digest-pinned container tool after its availability and command are verified.
5. Keep the staged artifact local for review. Publishing it or performing any Git commit, tag, or push requires separate authorization.

Do not use the Ant `build` target: it checks out the README from `origin`, increments build metadata, edits active source version fields, moves files into `release/`, prompts for a commit, and invokes Git add/commit/tag/push. The `copy-to-build` target is also not a suitable package shortcut: it clears `build/` and copies the legacy sample output archive and HTML guide.