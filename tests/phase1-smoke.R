args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: Rscript tests/phase1-smoke.R <capture.gz>", call. = FALSE)
}

fixture <- args[[1L]]
if (!file.exists(fixture)) {
  stop(sprintf("Fixture not found: %s", fixture), call. = FALSE)
}

connection <- gzfile(fixture, open = "rt")
on.exit(close(connection))
first_line <- readLines(connection, n = 1L, warn = FALSE)
expected_line <- "~~BEGIN-OS-INFORMATION~~"
if (length(first_line) != 1L || !identical(first_line, expected_line)) {
  stop(sprintf("Unexpected first fixture line: %s", paste(first_line, collapse = "")), call. = FALSE)
}

cat(first_line, "\n", sep = "")