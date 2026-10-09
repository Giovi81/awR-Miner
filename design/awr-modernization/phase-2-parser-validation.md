# Phase 2 R Parser and Output Validation

**Assessment date:** 2026-10-08  
**Status:** Complete for the selected USPS fixture and the tested R 4.6.1 container. This does not establish Oracle compatibility or validate every capture format.

## Reproducible Environment

The test image is based on R 4.6.1 at digest `sha256:198bf78cd85f5355173832ce3713921614c229752fcb4e0e7cb51b7713f745f7`. It uses Debian's 2026-10-06 snapshot for the system libcurl headers, CRAN `curl` 8.0.0 and `renv` 1.3.1, and restores the full parser dependency lock in [renv.lock](../../renv.lock). The direct package versions installed and verified in that image are:

| Package | Version |
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

Build the image with network access, then run the parser checks offline using the commands in [tests/README.md](../../tests/README.md). The repository mount is read-only; test captures and generated outputs live in an automatically removed temporary directory. No R runtime or package was installed on the host.

## Parser and Output Checks

[tests/phase2-parser.R](../../tests/phase2-parser.R) runs the active `source/R-AWR-Mining.R` entrypoint against the standard USPS compressed fixture and compares the generated parsed data with the checked-in USPS Rda baseline. It verifies stable row counts for `DF_MAIN`, `DF_AAS`, and `DF_IO_WAIT_HIST`, exact equality for shared `DF_MAIN` metrics (`snap`, `end`, `os_cpu`, `aas`, `read_iops`, and `write_iops`), and creation of the parsed Rda, a non-empty PDF, `summary.html`, and `OverallSummary.csv`. It also verifies that a synthetic capture containing an Oracle error exits unsuccessfully and is copied into the parser's `error/` directory.

The full offline parser/output test passed twice on R 4.6.1. The two active parser scripts and the test script also parsed successfully in that image. The fixture inputs remained unchanged.

## Compatibility Changes

The test exposed compatibility failures with current CRAN package APIs. The active parser variants now avoid the retired `checkpoint("2015-05-01")` bootstrap, retain the old Perl-regex call shape through `stringr::regex`, and enable dot-all matching when extracting multiline capture sections. `reshape::melt` is selected explicitly so `data.table` does not redirect these calls to its incompatible generic. Plot and report calls were updated for current `ggplot2`, `gridExtra`, and `sjPlot` APIs. The `sjPlot::tab_df()` result is printed explicitly so batch scripts write the HTML file.

These changes preserve the intended script workflow; they do not modify SQL capture behavior or historical release snapshots.

## Baseline Drift and Limits

The historical parsed Rda and the active parser do not have identical `DF_MAIN` schemas. Both contain 1,035 rows and the shared metrics listed above match, but the historical table has 52 columns while the current parser produces 44. The historical file includes 12 fields absent from the current output (`os_cpu_sd`, `cpu_per_s`, `cpu_per_s_sd`, `h_cpu_per_s`, `h_cpu_per_s_sd`, `aas_sd`, `db_time`, `db_time_sd`, `read_bks`, `read_bks_direct`, `write_bks`, and `write_bks_direct`); the current output adds four direct-I/O metrics. This appears to be pre-existing source/baseline drift. No schema behavior change was approved in Phase 2, so the test records the difference rather than asserting complete table-schema parity.

Some deprecation or layout warnings remain (including ggplot2 line-size and `stat_summary(fun.y)` warnings, plus legacy `panel.margin` theme elements). They did not prevent the tested PDF, HTML, CSV, or parsed data from being written.

No Oracle database or SQL*Plus client was used. These results do not establish AWR capture compatibility on Oracle 19c, either at CDB or direct-PDB scope. Those checks remain Phase 3 and are limited to the previously authorized `SELECT` operations; do not run capture scripts.
