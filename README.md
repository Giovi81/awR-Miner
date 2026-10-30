AWR-Miner
=========

AWR-Miner captures Oracle Automatic Workload Repository (AWR) data with SQL*Plus and parses the capture files with R to generate performance plots and reports.

**Current release:** 5.0.9 (2026-10-30).

## Verified Compatibility

The current support statement is limited to the following tested versions and paths:

- R 4.6.1 for parser and generated outputs; the offline fixture test passed on 2026-10-26.
- Oracle Database 19.3 CDB root and direct-PDB capture paths, using SQL*Plus 19.3 and R 4.6.1; integration checks were completed on 2026-10-09.

These checks do not establish support for other Oracle Database or SQL client versions. R 4.6.2 was released on 2026-10-29 and is the latest stable release as of 2026-10-30; it has not been tested for AWR-Miner. See the [Phase 3 validation record](design/awr-modernization/phase-3-oracle19c-validation.md) for the tested database paths and evidence.

The direct-PDB capture tested on Oracle 19.3 did not contain an `IO-WAIT-HISTOGRAM` section. That metric is unavailable in the tested PDB path and is deferred to a future release.

## Prerequisites

- Oracle Diagnostic Pack entitlement for the database use. AWR-Miner asks the operator to confirm licensing; the prompt does not check entitlement. The operator is responsible for confirming licensing with their organization and Oracle terms.
- SQL*Plus and permission to read the AWR views used by the selected capture path. The tested client was SQL*Plus 19.3. The exact least-privilege grants have not been established; ask the database administrator to review access rather than applying broad grants.
- R 4.6.1 with the parser dependencies available. The pinned Docker environment and offline fixture checks are documented in [tests/README.md](tests/README.md).

## Capture and Parse

1. Connect with SQL*Plus to the intended Oracle 19c container and run the matching capture script: [`source/awr_miner.sql`](source/awr_miner.sql) for CDB-level AWR from the CDB root, or [`source/awr_miner_pdb.sql`](source/awr_miner_pdb.sql) for a direct PDB connection. The scripts prompt for Diagnostic Pack licensing and write AWR capture files.
2. Run the parser with the directory containing the `.out` or `.out.gz` captures as its first argument:

	```text
	Rscript source/R-AWR-Mining.R "path/to/capture-files"
	```

	The parser writes its reports and parsed data to that directory. Keep database-derived captures and generated outputs protected according to your organization's data-handling rules.

For repeatable offline parser validation, follow the Docker commands in [tests/README.md](tests/README.md). This fixture test does not connect to Oracle and is separate from capture integration testing.

## Version and Licensing Sources

Checked on 2026-10-30: the [CRAN R sources page](https://cran.r-project.org/src/base/R-4/) lists R 4.6.2, released 2026-10-29, as the latest release. AWR-Miner's latest tested R version remains 4.6.1. Oracle's [19c Licensing Information User Manual](https://docs.oracle.com/en/database/oracle/oracle-database/19/dblic/Licensing-Information.html) lists AWR under Oracle Diagnostics Pack. Licensing depends on the organization's Oracle offering and entitlements; this documentation is not a license determination.

# Options
Options can be set interactively in an IDE like RStudio in the "console" section or through a file named very specifically *settings.R*. Using settings.R is the more reliable and preferred method. 

The *settings.R* file should be placed in the same directory as the .out files. This allows you to have a different settings.R file for each directory of files.

The following options can be added to settings.R

## File Pattern Override
`filePatternOverride <- "^awr-hist.+FOO.+(\\.out|\\.gz)$"`
The example above would only look for .out or .gz files with a name that contains "FOO". This an easy way to limit parsing to just a file or subset of files without having to move files into new directories. The default file patterh is:
`"^awr-hist*.*(\\.out|\\.gz)$"`


## Debug Mode
`debugModeOverride <- TRUE`
`rm(debugModeOverride)`
Debug mode is useful for a number of situations, including:
- dumping parsed data out to .Rda format files
- errors encountered with a particular file
- timing of specific components

In debug mode, the parsed data for each database is saved as highly compressed .Rda files. These are also used for the "combined stats" scripts.

The following are sub-options of debug mode, ie you must be in debug mode first for these to work.
### Debug Mode > dumpCSV
`dumpCSV <- TRUE`
This also dumps all data frames to comma separated files.

### Debug Mode > debugMoveFiles
`debugMoveFiles <- TRUE`
This option moves all completed .out files into a *done* subdirectory. If you have a lot of files, but only a few have errors, this allows you to separate the valid files from the ones that have errors. 

*End of Debug Mode Options*

## Parse Override
```
parseOverride <- c("!TOP-SQL-BY-SNAPID") # default, don't parse TOP-SQL-BY-SNAPID
parseOverride <- "ALL" [ALL|NONE|SOME|PAGE1|AAS]
parseOverride <- c("SOME","aas_facet")
rm(parseOverride)
```
This is useful if there is a section with errors that won't parse. Also if you just want to extract certain data. It can cause errors, so if just extracting data to .Rda or .csv, `set plotOverride <- "NONE"`


## Plot Override
```
plotOverride <- "ALL" [ALL|NONE|SOME|PAGE1|AAS] | 
plotOverride <- "NONE" # Don't plot anything, often combined with parse override and debug mode to dump data
plotOverride <- c("SOME","PAGE1,"AAS")
rm(plotOverride)
```
This allows you to control what is output to PDF. It's useful for debugging. 
