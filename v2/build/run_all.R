# EII v2 — run the build in order, from the repository root:
#   Rscript v2/build/fetch_sources.R    (download and verify sources; once)
#   Rscript v2/build/run_all.R
args <- commandArgs(trailingOnly = TRUE); root <- if (length(args)) args[1] else getwd()
for (s in c("build_penalties.R", "build_financial.R", "build_v2_partial.R", "build_covariates.R")) {
  cat("== ", s, "\n", sep = "")
  st <- system2("Rscript", c(file.path(root, "v2", "build", s), shQuote(root)))
  if (st != 0) stop(s, " failed")
}
