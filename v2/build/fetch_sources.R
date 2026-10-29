# EII v2 — fetch and verify raw sources (Rule 2).
# Downloads every public source listed in v2/sources/MANIFEST.csv into v2/sources/raw/,
# regenerates the troopdata snapshot, unzips archives, and checks each file's SHA-256
# against the manifest. GSDB is released by request only: place GSDB-R5.csv, GSDB-R5_Dyadic.dta,
# GSDB-FS.csv and GSDB-FS_Dyadic.dta (and their codebooks) in
# v2/sources/raw/ yourself; this script verifies it if present.
# Usage (from the repository root): Rscript v2/build/fetch_sources.R

suppressPackageStartupMessages({ library(digest) })
raw <- file.path("v2", "sources", "raw"); dir.create(raw, showWarnings = FALSE, recursive = TRUE)
man <- read.csv(file.path("v2", "sources", "MANIFEST.csv"), stringsAsFactors = FALSE)

for (i in seq_len(nrow(man))) {
  f <- file.path(raw, man$file[i]); src <- man$source[i]
  if (file.exists(f)) next
  dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
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
unzip(file.path(raw, "mid/MID-5-Data-and-Supporting-Materials.zip"), exdir = file.path(raw, "mid/mid5"))

ok <- TRUE
for (i in seq_len(nrow(man))) {
  f <- file.path(raw, man$file[i])
  if (!file.exists(f)) { cat("MISSING  ", man$file[i], "\n"); ok <- FALSE; next }
  h <- digest(file = f, algo = "sha256")
  same <- identical(h, man$sha256[i]); ok <- ok && same
  cat(if (same) "OK       " else "MISMATCH ", man$file[i], "\n")
}
# OFAC enforcement pages and documents (penalties channel): v2/sources/MANIFEST_ofac.csv
mo <- read.csv(file.path("v2", "sources", "MANIFEST_ofac.csv"), stringsAsFactors = FALSE)
for (d in c("pages", "docs", "txt")) dir.create(file.path(raw, "ofac_enforcement", d), showWarnings = FALSE, recursive = TRUE)
page_drift <- 0L
for (i in seq_len(nrow(mo))) {
  f <- file.path(raw, mo$file[i])
  if (!file.exists(f)) download.file(mo$source[i], f, mode = "wb", quiet = TRUE)
  same <- identical(digest(file = f, algo = "sha256"), mo$sha256[i])
  if (!same && grepl("/pages/", mo$file[i])) { page_drift <- page_drift + 1L; next }   # live pages can change after retrieval
  if (!same) { cat("MISMATCH ", mo$file[i], "\n"); ok <- FALSE }
}
cat("OFAC documents checked: ", sum(grepl("/docs/", mo$file)), "; year pages differing from the 2026-10-27 snapshot: ", page_drift,
    " (use the archived snapshot if any differ)\n", sep = "")
# Text extraction for the penalties build (poppler pdftotext; version recorded in the build log)
for (f in list.files(file.path(raw, "ofac_enforcement", "docs"), full.names = TRUE)) {
  txt <- file.path(raw, "ofac_enforcement", "txt", sub("\\.pdf$", ".txt", basename(f)))
  if (!file.exists(txt)) system2("pdftotext", c("-layout", shQuote(f), shQuote(txt)))
}
# OFAC archive of changes to the SDN list (financial channel): v2/sources/MANIFEST_sdn.csv
ms <- read.csv(file.path("v2", "sources", "MANIFEST_sdn.csv"), stringsAsFactors = FALSE)
dir.create(file.path(raw, "ofac_sdn"), showWarnings = FALSE, recursive = TRUE)
for (i in seq_len(nrow(ms))) {
  f <- file.path(raw, ms$file[i])
  if (!file.exists(f)) download.file(ms$source[i], f, mode = "wb", quiet = TRUE)
  if (!identical(digest(file = f, algo = "sha256"), ms$sha256[i])) { cat("MISMATCH ", ms$file[i], "\n"); ok <- FALSE }
}
cat("SDN change files checked: ", nrow(ms), "\n", sep = "")
# 2024-2025 are three-column PDFs: convert to reading-order text
for (f in ms$file[grepl("\\.pdf$", ms$file)]) {
  out <- file.path(raw, sub("\\.pdf$", "_pdf.txt", f))
  if (!file.exists(out)) system2("Rscript", c(file.path("v2", "build", "sdn_pdf_to_text.R"), shQuote(file.path(raw, f)), shQuote(out)))
}
# Covariates: v2/sources/MANIFEST_covariates.csv (paths relative to v2/sources).
# Files under raw/ are downloaded; the WDI API snapshots under snapshots/ are
# committed to the repository (CC BY 4.0) because the live API changes.
# BGS World Mineral Statistics is served page by page through an OGC API: the
# pages are fetched in synthetic_id order and joined (header once).
bgs_fetch <- function(dest, base, limit = 10000) {
  hdr <- NULL; body <- character(); i <- 0
  repeat {
    tf <- tempfile(fileext = ".csv")
    download.file(sprintf("%s&limit=%d&offset=%d", base, limit, i * limit), tf, mode = "wb", quiet = TRUE)
    x <- readLines(tf, encoding = "UTF-8", warn = FALSE)
    if (is.null(hdr)) hdr <- x[1] else stopifnot(identical(hdr, x[1]))
    body <- c(body, x[-1]); i <- i + 1
    if (length(x) - 1 < limit) break
  }
  stopifnot(!anyDuplicated(sub(",.*$", "", body)))
  con <- file(dest, "wb"); writeLines(c(hdr, body), con, sep = "\n", useBytes = TRUE); close(con)
}
mc <- read.csv(file.path("v2", "sources", "MANIFEST_covariates.csv"), stringsAsFactors = FALSE)
for (i in seq_len(nrow(mc))) {
  f <- file.path("v2", "sources", mc$file[i])
  dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(f) && grepl("ogcapi.bgs.ac.uk", mc$source[i])) bgs_fetch(f, mc$source[i])
  if (!file.exists(f) && grepl("^raw/", mc$file[i])) download.file(mc$source[i], f, mode = "wb", quiet = TRUE)
  if (!file.exists(f)) { cat("MISSING  ", mc$file[i], "\n"); ok <- FALSE; next }
  if (!identical(digest(file = f, algo = "sha256"), mc$sha256[i])) { cat("MISMATCH ", mc$file[i], "\n"); ok <- FALSE }
}
cat("Covariate sources checked: ", nrow(mc), "\n", sep = "")
if (!ok) stop("One or more sources are missing or differ from the manifest; do not build.")
cat("All sources match the manifest.\n")
