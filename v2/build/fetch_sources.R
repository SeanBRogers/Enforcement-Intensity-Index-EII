# EII v2 — fetch and verify raw sources (Rule 2).
# Downloads every public source listed in v2/sources/MANIFEST.csv into v2/sources/raw/,
# regenerates the troopdata snapshot, unzips archives, and checks each file's SHA-256
# against the manifest. GSDB is released by request only: place GSDB_V4.csv in
# v2/sources/raw/ yourself; this script verifies it if present.
# Usage (from the repository root): Rscript v2/build/fetch_sources.R

suppressPackageStartupMessages({ library(digest) })
raw <- file.path("v2", "sources", "raw"); dir.create(raw, showWarnings = FALSE, recursive = TRUE)
man <- read.csv(file.path("v2", "sources", "MANIFEST.csv"), stringsAsFactors = FALSE)

for (i in seq_len(nrow(man))) {
  f <- file.path(raw, man$file[i]); src <- man$source[i]
  if (file.exists(f)) next
  if (grepl("^https://", src) && !grepl("by request", src)) {
    download.file(src, f, mode = "wb", quiet = TRUE)
  } else if (grepl("^R package troopdata", src)) {
    if (!requireNamespace("troopdata", quietly = TRUE) ||
        as.character(packageVersion("troopdata")) != "1.1.0")
      stop("troopdata 1.1.0 is required to regenerate ", man$file[i])
    d <- suppressWarnings(troopdata::get_troopdata(startyear = 1950, endyear = 2026))
    write.csv(as.data.frame(d), f, row.names = FALSE)
  }
}
for (z in c("States2024.zip", "System2024.zip")) unzip(file.path(raw, z), exdir = raw)
unzip(file.path(raw, "ucdp-prio-acd-261-csv.zip"), exdir = file.path(raw, "ucdp_acd_261"))

ok <- TRUE
for (i in seq_len(nrow(man))) {
  f <- file.path(raw, man$file[i])
  if (!file.exists(f)) { cat("MISSING  ", man$file[i], "\n"); ok <- FALSE; next }
  h <- digest(file = f, algo = "sha256")
  same <- identical(h, man$sha256[i]); ok <- ok && same
  cat(if (same) "OK       " else "MISMATCH ", man$file[i], "\n")
}
if (!ok) stop("One or more sources are missing or differ from the manifest; do not build.")
cat("All sources match the manifest.\n")
