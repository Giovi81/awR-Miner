# Phase 1 Reproducible Test Environment

**Assessment date:** 2026-10-08
**Status:** Base-R fixture smoke environment implemented and verified. The full parser dependency environment remains a Phase 2 prerequisite; no parser or runtime compatibility claim is made.

## Smoke Check

The test at `tests/phase1-smoke.R` reads one compressed capture and verifies its first line using base R only. It does not install packages, access CRAN or Oracle, or write to the fixture.

Run from the repository root in PowerShell:

```powershell
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),destination=/workspace,readonly" --workdir /workspace r-base@sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7 Rscript tests/phase1-smoke.R test-cases/awr-hist-1132973626-ORCL-112295-112992.out.gz
```

**Observed result:** `~~BEGIN-OS-INFORMATION~~`. The check passed both as a direct base-R read and through the committed test script, with Docker networking disabled and the repository mounted read-only. The image is pinned to the R 4.6.1 digest selected in Phase 0.

## Dependency Resolution Boundary

A Docker query against CRAN on 2026-10-08 found `renv` 1.3.1 and these current versions for the packages attached by the primary parser:

| Package | CRAN version |
| --- | --- |
| futile.logger | 1.4.9 |
| ggplot2 | 4.0.3 |
| plyr | 1.8.9 |
| gridExtra | 2.3.1 |
| scales | 1.4.0 |
| reshape | 0.8.10 |
| xtable | 1.8-8 |
| ggthemes | 7.0.0 |
| stringr | 1.6.0 |
| data.table | 1.18.6.1 |
| lubridate | 1.9.5 |
| gplots | 3.3.0 |
| gtools | 3.9.5 |
| dplyr | 1.2.1 |
| sjPlot | 2.9.0 |

The entrypoint also attaches `checkpoint` and calls `checkpoint("2015-05-01")`, but `checkpoint` was not available in the current CRAN package index. The versions above are an inventory, not a lockfile or a tested dependency set. No package was installed and no `renv.lock` was generated.

Before full parser tests in Phase 2, decide how the test environment will handle the retired checkpoint service without silently changing the user's runtime workflow. Then resolve and lock the complete dependency closure, restore it in Docker, and run parser tests against disposable writable copies of fixtures. Until those checks pass, parser behavior on R 4.6.1 remains unverified.

## Acceptance

| Criterion | Result |
| --- | --- |
| Pinned R 4.6.1 container | Verified by digest-pinned image. |
| Fixture read without network or host-side R | Passed with Docker networking disabled and a read-only mount. |
| Repeatable assertion in repository | Implemented at `tests/phase1-smoke.R` and passed. |
| Full parser dependency restore | Deferred to Phase 2; `checkpoint` disposition and a complete lockfile are outstanding. |
| Oracle access | Not required or used. |