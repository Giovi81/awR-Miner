# Run AWR-Miner without installing R

Docker runs R and its required packages in an isolated Linux container. You do not need R or RStudio installed on your computer. This workflow reuses the pinned R 4.6.1 environment used for parser validation; it does not upgrade R or extend the verified Oracle compatibility statement.

## Requirements

- Docker Engine, or Docker Desktop configured to run Linux containers, installed and running. Follow your organization's installation, licensing, and data-handling policies.
- The extracted AWR-Miner release containing this guide, `R-AWR-Mining.R`, `renv.lock`, and the `tests` directory containing `Dockerfile` and `Dockerfile.dockerignore`. Alternatively, use a checkout of the repository.
- Internet access for the initial image build. It downloads the pinned base image, system dependencies, and R packages; R and package installation happen only inside Docker.
- A writable local directory containing your AWR captures (`.out` or `.out.gz`). Keep a backup of the original captures.

Docker is used here only for parsing captures and generating reports. Capturing data still requires SQL*Plus, database privileges, and Oracle Diagnostic Pack entitlement as described in the main README (included as `readme.R-plots.html` in releases). Do not put database credentials in Docker commands or image files. No database connection is needed for parsing.

## 1. Build the image once

Open PowerShell in the extracted release directory (or the repository root):

```powershell
docker build --file tests\Dockerfile --tag awr-miner-r:4.6.1 .
if ($LASTEXITCODE -ne 0) { throw "AWR-Miner image build failed" }
```

The Dockerfile pins the base image by digest and restores package versions from `renv.lock`. The image tag above is a local name, not an image published in a registry. The Dockerfile-specific ignore file restricts the build context to the build files and dependency lock; capture files and credentials are not sent to the builder.

Keep all these files from the same release. Rebuild the image when changing release or dependency lock, even if the R version is unchanged. The first build can take several minutes; later runs reuse the local image.

## 2. Select the parser and capture directory

In the same PowerShell window, select the directory containing the parser:

```powershell
# Extracted release:
$parserDirectory = (Resolve-Path ".").Path

# Repository checkout: use this instead of the line above.
# $parserDirectory = (Resolve-Path ".\source").Path

$captureDirectory = (Resolve-Path "C:\AWR captures").Path
```

Replace `C:\AWR captures` with an existing directory containing your captures. Spaces in the path are supported. Select only the required data directory, not your whole home directory or drive.

Optional: place your trusted `settings.R` in the capture directory before running. The parser reads it automatically, just as in a local R run. This file is executable R code, so review it before use. Options such as `debugMoveFiles` can move processed captures; see the main README for settings.

## 3. Generate reports

```powershell
docker run --rm --network none --mount "type=bind,source=$parserDirectory,destination=/app,readonly" --mount "type=bind,source=$captureDirectory,destination=/data" awr-miner-r:4.6.1 Rscript /app/R-AWR-Mining.R /data
if ($LASTEXITCODE -ne 0) { throw "AWR-Miner parsing failed; inspect the console and capture directory logs" }
```

The parser directory is read-only. The capture directory is writable because the parser saves its reports and parsed data there. Networking is disabled during execution; the image must already exist locally.

After the command finishes, open the capture directory on your computer. Depending on capture contents and settings, outputs include `summary.html`, `OverallSummary.csv`, plot PDFs (`*-plot.pdf`), and parsed data files (`*-parsed.Rda`). `status.log` records processing activity. Open HTML and PDF reports with your normal browser and PDF viewer; no R installation is needed.

`--rm` removes the temporary container, not the reports: the data directory is a **bind mount**, meaning the container writes directly to your selected local folder. Reuse the same command for later captures. Protect both captures and reports according to your organization's data-handling rules.

## Linux and macOS

From the extracted release directory, use the same image build and mounts with your shell's path syntax:

```sh
docker build --file tests/Dockerfile --tag awr-miner-r:4.6.1 .
# Stop if the build fails.
parserDirectory="$(pwd)"
# Repository checkout: use parserDirectory="$(pwd)/source" instead.
captureDirectory="/absolute/path/to/AWR captures"
docker run --rm --network none --user "$(id -u):$(id -g)" --mount "type=bind,source=$parserDirectory,destination=/app,readonly" --mount "type=bind,source=$captureDirectory,destination=/data" awr-miner-r:4.6.1 Rscript /app/R-AWR-Mining.R /data
```

The user option keeps generated files owned by your local user on Linux. These shell examples are provided for convenience; the end-user bind-mount workflow was validated with Docker Desktop on Windows, not separately on Linux/macOS hosts.

## Troubleshooting

- **Cannot connect to Docker:** start Docker Desktop or your Docker service and select Linux containers.
- **Image build fails:** check Internet/proxy access to the image registry, Debian snapshot, and R package repositories. Do not bypass pinned versions by silently replacing them with `latest`.
- **Mount path not found or access denied:** use an existing absolute path and allow Docker access to that folder. Ensure the capture directory is writable.
- **No captures found:** check the selected directory and filenames. The default pattern looks for `awr-hist` capture names; `filePatternOverride` in `settings.R` can change it.
- **Parser failure or incomplete outputs:** inspect console messages, `status.log`, any `.err` files, and the `error` directory. Do not treat the presence of a report alone as proof that all captures succeeded.

For offline regression checks using repository fixtures rather than your own captures, see `tests/README.md` in the repository. Those checks do not connect to Oracle.
