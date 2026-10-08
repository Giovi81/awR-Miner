arguments <- commandArgs(trailingOnly = TRUE)
if (length(arguments) != 1L) {
  stop("Usage: Rscript tests/phase2-parser.R <repository-root>", call. = FALSE)
}

repository_root <- normalizePath(arguments[[1L]], mustWork = TRUE)
parser_script <- file.path(repository_root, "source", "R-AWR-Mining.R")
fixture <- file.path(
  repository_root,
  "test-cases",
  "awr-hist-389926331-USPS-775-985.out.gz"
)
baseline_file <- file.path(
  repository_root,
  "test-cases",
  "mem-test",
  "USPS-389926331-776-985-parsed.Rda"
)

if (!file.exists(fixture)) {
  stop(sprintf("Parser fixture not found: %s", fixture), call. = FALSE)
}
if (!file.exists(baseline_file)) {
  stop(sprintf("Parsed baseline not found: %s", baseline_file), call. = FALSE)
}

write_test_settings <- function(work_dir, plot_mode) {
  plot_setting <- if (identical(plot_mode, "PAGE1")) {
    'c("SOME", "PAGE1")'
  } else {
    '"NONE"'
  }
  writeLines(
    c(
      'debugFilePattern <- "^__no_fixture_matches__$"',
      'parseOverride <- "ALL"',
      sprintf("plotOverride <- %s", plot_setting)
    ),
    file.path(work_dir, "settings.R")
  )
}

run_parser <- function(work_dir) {
  output <- suppressWarnings(
    system2(
      file.path(R.home("bin"), "Rscript"),
      args = c(shQuote(parser_script), shQuote(work_dir)),
      stdout = TRUE,
      stderr = TRUE
    )
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  list(status = status, output = output)
}

test_root <- tempfile("awr-miner-phase2-")
dir.create(test_root)
valid_work_dir <- file.path(test_root, "valid")
dir.create(valid_work_dir)
if (!file.copy(fixture, valid_work_dir)) {
  stop("Could not copy parser fixture", call. = FALSE)
}
write_test_settings(valid_work_dir, "PAGE1")

valid_result <- run_parser(valid_work_dir)
if (valid_result$status != 0L) {
  writeLines(tail(valid_result$output, 25L), stderr())
  stop(sprintf("Parser exited with status %s", valid_result$status), call. = FALSE)
}

parsed_files <- list.files(valid_work_dir, pattern = "-parsed\\.Rda$", full.names = TRUE)
if (length(parsed_files) != 1L) {
  stop(sprintf("Expected one parsed Rda output, found %d", length(parsed_files)), call. = FALSE)
}
if (length(list.files(valid_work_dir, pattern = "\\.err$")) != 0L) {
  stop("Valid capture produced a parser error log", call. = FALSE)
}

actual_environment <- new.env(parent = emptyenv())
baseline_environment <- new.env(parent = emptyenv())
load(parsed_files[[1L]], envir = actual_environment)
load(baseline_file, envir = baseline_environment)
actual <- actual_environment$main.save
baseline <- baseline_environment$main.save

for (table_name in c("DF_MAIN", "DF_AAS", "DF_IO_WAIT_HIST")) {
  actual_table <- actual[[table_name]]
  baseline_table <- baseline[[table_name]]
  if (!is.data.frame(actual_table) || !is.data.frame(baseline_table)) {
    stop(sprintf("Expected data frame %s in parsed output", table_name), call. = FALSE)
  }
  if (!identical(nrow(actual_table), nrow(baseline_table))) {
    stop(
      sprintf(
        "Unexpected row count for %s: current %d, baseline %d",
        table_name,
        nrow(actual_table),
        nrow(baseline_table)
      ),
      call. = FALSE
    )
  }
}

for (column_name in c("snap", "end", "os_cpu", "aas", "read_iops", "write_iops")) {
  if (!(column_name %in% names(actual$DF_MAIN)) || !(column_name %in% names(baseline$DF_MAIN))) {
    stop(sprintf("Expected stable DF_MAIN column %s", column_name), call. = FALSE)
  }
  if (!isTRUE(all.equal(
    actual$DF_MAIN[[column_name]],
    baseline$DF_MAIN[[column_name]],
    check.attributes = FALSE
  ))) {
    stop(sprintf("Unexpected parsed values for DF_MAIN$%s", column_name), call. = FALSE)
  }
}

if (!file.exists(file.path(valid_work_dir, "summary.html"))) {
  stop("Expected summary.html report", call. = FALSE)
}
if (!file.exists(file.path(valid_work_dir, "OverallSummary.csv"))) {
  stop("Expected OverallSummary.csv report", call. = FALSE)
}
plot_files <- list.files(valid_work_dir, pattern = "-plot\\.pdf$", full.names = TRUE)
if (length(plot_files) == 0L || any(file.info(plot_files)$size <= 0L)) {
  stop("Expected a non-empty plot PDF", call. = FALSE)
}

malformed_work_dir <- file.path(test_root, "malformed")
dir.create(malformed_work_dir)
malformed_name <- "awr-hist-9999999999-MALFORMED-1-2.out"
writeLines(
  c(
    "~~BEGIN-OS-INFORMATION~~",
    "ERROR at line 1: synthetic parser test",
    "~~END-OS-INFORMATION~~"
  ),
  file.path(malformed_work_dir, malformed_name)
)
write_test_settings(malformed_work_dir, "NONE")
malformed_result <- run_parser(malformed_work_dir)
if (malformed_result$status == 0L) {
  stop("Malformed capture unexpectedly succeeded", call. = FALSE)
}

copied_error_file <- file.path(malformed_work_dir, "error", malformed_name)
if (!file.exists(copied_error_file)) {
  stop("Malformed capture was not copied to the error directory", call. = FALSE)
}

unlink(test_root, recursive = TRUE)
cat("Phase 2 parser and output checks passed\n")