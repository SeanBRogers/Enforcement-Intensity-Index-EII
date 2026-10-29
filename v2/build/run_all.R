# EII v2 — run the build in order, from the repository root:
#   Rscript v2/build/fetch_sources.R    (download and verify sources; once)
#   Rscript v2/build/run_all.R
# Scripts read UTF-8 text: run in a UTF-8 locale (R 4.2+ on Windows already is); child scripts inherit it.
if (!isTRUE(l10n_info()[["UTF-8"]]) && .Platform$OS.type == "unix") Sys.setenv(LC_ALL = "C.UTF-8")
args <- commandArgs(trailingOnly = TRUE); root <- if (length(args)) args[1] else getwd()
for (s in c("build_penalties.R", "build_financial.R", "estimate_sdn_1994.R", "build_proxy.R", "build_regime_change.R", "build_v2_partial.R", "build_covariates.R")) {
  cat("== ", s, "\n", sep = "")
  st <- system2("Rscript", c(file.path(root, "v2", "build", s), shQuote(root)))
  if (st != 0) stop(s, " failed")
}
