arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) {
  stop("Usage: Rscript tests/phase1-smoke.R <capture.gz>", call. = FALSE)
}

fixture <- arguments[[1L]]
if (!file.exists(fixture)) {
  stop(sprintf("Fixture not found: %s", fixture), call. = FALSE)
}

read_first_line <- function(path) {
  connection <- gzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  readLines(connection, n = 1L, warn = FALSE)
}

first_line <- read_first_line(fixture)
expected_line <- "~~BEGIN-OS-INFORMATION~~"
if (length(first_line) != 1L || !identical(first_line, expected_line)) {
  stop(sprintf("Unexpected first fixture line: %s", paste(first_line, collapse = "")), call. = FALSE)
}

cat(first_line, "\n", sep = "")