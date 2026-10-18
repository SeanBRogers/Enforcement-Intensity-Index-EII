# ==============================================================================
# RUN THE FOLLOW-ON ANALYSES: ONE LOGGED RUN EACH
# ==============================================================================
# Runs every follow-on script in this repository with R CMD BATCH, so each one
# leaves a complete log (<script>_R.Rout) next to its outputs, all on one
# machine and one R version. Run it from the package folder:
#
#   & "C:\Program Files\R\R-4.6.1\bin\R.exe" CMD BATCH --no-save --no-restore run_followons.R run_followons_R.Rout
#
# EII_pipeline.R and regime_break_bayes.R are not rerun here. Each takes
# minutes and has its own logged run of record (EII_pipeline_R.Rout,
# regime_break_bayes_R.Rout).
#
# fiscal_pull.R re-pulls live FRED series and rewrites fiscal_indicators.csv,
# which is an input to spend_cost_split.R, divergence_diagnostic.R and
# regime_break_bayes.R. A silent FRED revision would change those inputs. So
# this runner keeps the committed file, compares the re-pull to it value by
# value, puts the committed file back either way, and stops before any
# analysis if FRED has revised anything.
#
# verify_sources.R and degradation_audit.R download their sources (Polity5,
# V-Dem v16, UNGA ideal points, FRED, the World Bank API, UCDP/PRIO v25.1),
# so this needs an internet connection.
#
# It ends by writing sessionInfo_R.txt, the record of the R, package and
# CmdStan versions on the estimation machine.
# ==============================================================================

.libPaths(c("C:/R/library", .libPaths()))

stopifnot(file.exists("EII_Panel_Definitive.csv"),
          file.exists("fiscal_indicators.csv"))

rexe <- file.path(R.home("bin"), "R.exe")  # the same R that is running this file
cat("Runner started:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n")
cat("R:", R.version.string, "\n")
cat("Binary:", rexe, "\n")
cat("Folder:", getwd(), "\n\n")

run <- function(script) {
  stopifnot(file.exists(script))
  log <- sub("\\.R$", "_R.Rout", script)
  t0 <- Sys.time()
  st <- system2(rexe, c("CMD", "BATCH", "--no-save", "--no-restore", script, log))
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(sprintf("%-26s exit %d  %5.0f s  -> %s\n", script, st, secs, log))
  flush.console()
  st
}

# ---- 1. FRED re-pull, checked against the committed fiscal_indicators.csv ----
cat("==================================================================\n")
cat("1. FISCAL INDICATORS: RE-PULL AND COMPARE\n")
cat("==================================================================\n")
committed <- read.csv("fiscal_indicators.csv")
backup <- "fiscal_indicators_committed.tmp"
stopifnot(file.copy("fiscal_indicators.csv", backup, overwrite = TRUE))

st_pull <- run("fiscal_pull.R")
repull <- if (st_pull == 0) read.csv("fiscal_indicators.csv") else NULL

# Put the committed file back whatever happened, so no input changes in this run
stopifnot(file.copy(backup, "fiscal_indicators.csv", overwrite = TRUE))
file.remove(backup)

same <- !is.null(repull) &&
  identical(dim(committed), dim(repull)) &&
  identical(names(committed), names(repull)) &&
  identical(committed$year, repull$year) &&
  isTRUE(all.equal(committed, repull, tolerance = 1e-9))

if (!is.null(repull) && identical(dim(committed), dim(repull)) &&
    identical(names(committed), names(repull))) {
  cat("\nLargest absolute difference, re-pull vs committed, by column:\n")
  for (v in setdiff(names(committed), "year")) {
    a <- committed[[v]]; b <- repull[[v]]
    na_mismatch <- sum(is.na(a) != is.na(b))
    d <- suppressWarnings(max(abs(a - b), na.rm = TRUE))
    cat(sprintf("  %-14s %.3g  (NA mismatches: %d)\n", v, d, na_mismatch))
  }
}

if (!same) {
  if (!is.null(repull)) write.csv(repull, "fiscal_indicators_FRED_repull.csv", row.names = FALSE)
  cat("\nSTOPPED: the FRED re-pull does not match the committed fiscal_indicators.csv\n")
  cat("(or fiscal_pull.R failed). The committed file is unchanged. The re-pull, if\n")
  cat("any, is in fiscal_indicators_FRED_repull.csv. No analysis was run.\n")
  quit(status = 1)
}
cat("\nRe-pull matches the committed file on every value. Committed file kept.\n\n")

# ---- 2. Source checks, validation, and the follow-on analyses ----
cat("==================================================================\n")
cat("2. SOURCE CHECKS, VALIDATION, FOLLOW-ON ANALYSES\n")
cat("==================================================================\n")
scripts <- c("verify_sources.R",        # covariates vs their stated sources
             "degradation_audit.R",     # degradation vs UCDP/PRIO; pre-audit refit
             "validate.R",              # 44 checks against the frequentist baseline
             "codebook_checks.R",       # every descriptive number in CODEBOOK.md
             "divergence_diagnostic.R", # fiscal reporting divergence gates
             "layer_decomposition.R",   # substitution test, 2003-2021
             "period_split.R",          # fiscal pressure, early vs late
             "spend_cost_split.R")      # spend and cost as separate mechanisms
status <- c(fiscal_pull.R = st_pull)
for (s in scripts) status[s] <- run(s)

# ---- Summary ----
cat("\n==================================================================\n")
cat("SUMMARY\n")
cat("==================================================================\n")
for (s in names(status)) {
  cat(sprintf("  %-26s %s\n", s, if (status[s] == 0) "OK (exit 0)" else
    paste0("FAILED (exit ", status[s], "): read ", sub("\\.R$", "_R.Rout", s))))
}
cat(sprintf("\n%d of %d scripts exited 0.\n", sum(status == 0), length(status)))

# ---- Environment record ----
# Loads every package this repository's scripts use and writes their
# versions, with the CmdStan version, to sessionInfo_R.txt.
env_ok <- tryCatch({
  suppressPackageStartupMessages(
    for (p in c("tidyverse", "here", "pscl", "MASS", "brms", "cmdstanr", "loo",
                "bayesplot", "posterior", "readxl", "jsonlite"))
      library(p, character.only = TRUE))
  writeLines(c(capture.output(sessionInfo()), "",
               paste("CmdStan:", cmdstanr::cmdstan_version()),
               paste("Recorded:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                     "by run_followons.R")),
             "sessionInfo_R.txt")
  cat("\nSaved: sessionInfo_R.txt\n")
  TRUE
}, error = function(e) {
  cat("\nENVIRONMENT RECORD FAILED:", conditionMessage(e), "\n")
  FALSE
})

cat("Runner finished:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n\n")
sessionInfo()
if (any(status != 0) || !env_ok) quit(status = 1)
