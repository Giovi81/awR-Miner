# Phase 4 Documentation and Release Preparation

**Status:** Ready to begin. Phase 3 is formally complete for its approved scope; the PDB I/O-wait-histogram gap is deferred to a future release. This plan prepares documentation and a safe local packaging procedure. It does not authorize a release, database access, commits, tags, or pushes.

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

- Root `README.md` still says Oracle 10.1+ and R 3.x+, and its basic workflow assumes RStudio. These claims and steps need replacement or qualification against the tested scope.
- `doc/readme_awr_miner.html` is a legacy 2.9 document with old Oracle licensing links and workflow details; decide whether it is maintained, regenerated, or explicitly marked historical.
- `doc/awr_miner.sql` is an older capture snapshot. Do not silently present it as the current `source/` implementation.
- The Phase 0 baseline records required AWR views but does not establish a least-privilege grant recipe. Document this limitation and request DBA review rather than recommending broad grants.
- The default Ant `build` target is unsafe for ordinary validation: it checks out README content, increments the build number, edits active version metadata, moves release artifacts, and invokes Git add/commit/tag/push targets.

## Work Plan

1. Verify current R and Oracle documentation facts against primary sources before updating support statements; record the check date and exact tested versions.
2. Confirm which user-facing docs are authoritative and map each instruction to the active `source/` scripts and pinned tests.
3. Draft setup, capture prerequisites/licensing, tested compatibility, limitations, and fixture-test instructions. Keep database integration results separate from offline parser checks.
4. Inspect Ant dependencies and specify a local packaging approach that works on an isolated copy or uses explicit non-release targets. Do not invoke the default `build` target.
5. Review the resulting docs and packaging instructions for consistency, stale version claims, unverified grants, data handling, and accidental release side effects.

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