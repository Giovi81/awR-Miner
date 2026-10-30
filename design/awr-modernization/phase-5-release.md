# Phase 5 Release 5.0.9

**Status:** Local package prepared and validated on 2026-10-30. The archive is outside the repository in the user-designated Downloads folder. No historical release snapshots or AWR-derived data were included.

## Release Contents

The package is `AWR-Miner-5.0.9.zip` and contains only:

- `README.md`
- `source/R-AWR-Mining.R`
- `source/awr_miner.sql`
- `source/awr_miner_pdb.sql`

The SQL capture scripts and parser plot metadata identify version 5.0.9. The root README identifies the current release. Historical release directories were left unchanged.

Archive SHA-256:

`13823C9DD65F01907C759B6C57BF59916C4DC92C7CBF4E52DBF68E57BA55926E`

The archive was created and tested with Info-ZIP 3.0 in the pinned local Docker image `sha256:71a5579f9d25ae5028433abb2a5dacaa30c2a57ab5e25ef5238ed96532e92a4e`. Its file listing was checked against the allowlist above.

## Validation and Limits

- The Phase 2 offline parser/output test passed on R 4.6.1 in the pinned Docker image.
- `git diff --check` passed.
- No new live Oracle capture was run for this version-only release. The existing Oracle 19.3 / SQL*Plus 19.3 CDB and direct-PDB evidence is recorded in [phase-3-oracle19c-validation.md](phase-3-oracle19c-validation.md); the PDB I/O-wait-histogram gap remains deferred.
- A fresh local capture could not be exercised during the release walkthrough: the local SQL*Plus alias did not resolve, and SQLcl did not support some SQL*Plus formatting commands used by the capture script.

R 4.6.1 remains the latest tested parser runtime. R 4.6.2 and Oracle/SQL client combinations beyond the documented 19.3 tests are not verified for this release.
