# Parser Validation

Build the pinned R 4.6.1 test image from the repository root. The build downloads the pinned `renv` release, restores the versions in `renv.lock`, and uses a dated Debian snapshot for the system libcurl headers:

```powershell
docker build --file tests/Dockerfile --tag awr-miner-phase2:20261008 .
```

Run the parser checks with networking disabled and the repository mounted read-only:

```powershell
docker run --rm --network none --mount "type=bind,source=$($PWD.Path),destination=/workspace,readonly" --workdir /workspace awr-miner-phase2:20261008 Rscript tests/phase2-parser.R /workspace
```

The test copies its capture into a temporary writable directory, compares key parsed tables with the checked-in USPS baseline, verifies HTML, CSV, and PDF outputs, and checks that a synthetic Oracle error capture is copied to the parser's error directory. It does not access Oracle or alter repository fixtures. The older `phase1-smoke.R` remains a base-R-only gzip marker check.
