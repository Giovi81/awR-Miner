# Phase 1 Reproducible Test Environment

**Assessment date:** 2026-10-08

**Status:** Complete for the offline base-R fixture smoke check. The parser dependency lock and parser tests remain Phase 2 work; this check does not establish parser compatibility.

## Smoke Check

The script at `tests/phase1-smoke.R` reads the first line of a compressed capture with base R and compares it with the expected marker. It uses no contributed packages, does not access CRAN or Oracle, and does not modify the fixture.

Run from the repository root in PowerShell:

```powershell
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),destination=/workspace,readonly" --workdir /workspace r-base@sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7 Rscript tests/phase1-smoke.R test-cases/awr-hist-1132973626-ORCL-112295-112992.out.gz
```

**Observed result:** `~~BEGIN-OS-INFORMATION~~`. The command passed twice with the R 4.6.1 image pinned to the Phase 0 digest, Docker networking disabled, and the repository mounted read-only. No host R installation or package installation was used.

## Phase Boundary

| Criterion | Result |
| --- | --- |
| Digest-pinned R 4.6.1 container | Verified. |
| Existing compressed fixture read without network | Passed twice. |
| Repeatable assertion maintained in the repository | Implemented and passed. |
| Full parser dependency restore and parser tests | Deferred to Phase 2. |
| Oracle access | Not required or used. |

The smoke check proves only that this fixture's expected marker can be read using base R in the pinned container. It does not validate the parser, plots, reports, SQL capture, or Oracle compatibility. Resolve and pin the parser's complete dependency set before Phase 2 parser tests; do not infer support from this smoke check.