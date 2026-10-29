# EII v2 -- financial channel, case series 1950-2025 (Sean, 2026-10-29: "Both,
# data type permitting"). GSDB-FS (Global Sanctions Data Base, Financial
# Sanctions, v1.0, September 2026): financial sanction cases with six subtypes.
# A case is not a designation: GSDB records one case per sender, target and
# objective, and adding names to an existing list is not a new case (codebook,
# Table 4). This series therefore runs on a different unit from the SDN counts;
# it is calibrated against them in the years both cover (1995-2025) and the
# result is logged before it is used for 1950-1993.
#
# US cases: GSDB-R5 cases naming the United States among their senders (D2).
# Subtypes come from the case list (the dyadic file takes the union over every
# case in force for a dyad, including UN cases spread to each member state).
# Targets and years come from the dyadic file.
#
# Output: v2/output/financial_gsdb_country_year.csv. Usage: Rscript v2/build/build_gsdb_fs.R [repo_root]

suppressPackageStartupMessages({ library(countrycode); library(haven) })
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "financial_gsdb_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 GSDB-FS financial case series, %s; R %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), getRversion())

fs <- read.csv(file.path(raw, "GSDB-FS.csv"), stringsAsFactors = FALSE, na.strings = "NA")
fs <- fs[grepl("United States", fs$sanctioning_state, fixed = TRUE), ]
sub <- c(asset_freeze = "asset_freeze", services = "financial_services", aid = "aid",
         investment = "investment_restrictions", payment_infra = "payment_service_infrastructure", other = "other")
tok <- lapply(strsplit(fs$descr_financial, ","), trimws)
for (s in names(sub)) fs[[s]] <- vapply(tok, function(x) sub[[s]] %in% x, logical(1))
r5 <- read.csv(file.path(raw, "GSDB-R5.csv"), stringsAsFactors = FALSE, na.strings = "NA")
fs$single <- r5$target_mult[match(fs$case_id, r5$case_id)] == 0      # single-target cases (GSDB-R5 target_mult)
stopifnot(!anyNA(fs$single))
unk <- setdiff(unique(trimws(unlist(strsplit(fs$descr_financial, ",")))), sub)
if (length(unk)) lg("Subtype values not in the code list: %s", paste(unk, collapse = "; "))
lg("GSDB-FS US-named financial cases: %d (%d also naming other senders); subtypes: %s", nrow(fs),
   sum(fs$sanctioning_state != "United States"), paste(names(sub), sapply(names(sub), function(s) sum(fs[[s]])), collapse = ", "))

dy <- as.data.frame(read_dta(file.path(raw, "GSDB-FS_Dyadic.dta")))
dy <- dy[dy$sanctioning_state == "United States", c("case_id", "sanctioned_state_iso3", "sanctioned_state", "year")]
ids <- lapply(strsplit(as.character(dy$case_id), ","), function(x) as.integer(trimws(x)))
long <- do.call(rbind, lapply(seq_len(nrow(dy)), function(i) {
  x <- ids[[i]][ids[[i]] %in% fs$case_id]
  if (!length(x)) return(NULL)
  data.frame(case_id = x, iso3 = dy$sanctioned_state_iso3[i], target = dy$sanctioned_state[i], year = dy$year[i])
}))
long <- merge(long, fs[, c("case_id", "single", names(sub))], by = "case_id")
iso_special <- c(CSK = 315, DDR = 265, KSV = 347, VDR = 816, RHO = 552, SRB = 345, SVU = 365)
long$ccode <- suppressWarnings(countrycode(long$iso3, "iso3c", "cown"))
hit <- long$iso3 %in% names(iso_special); long$ccode[hit] <- iso_special[long$iso3[hit]]
long$ccode[long$iso3 == "DEU" & long$year <= 1990] <- 260
long$ccode[long$iso3 == "VNM" & long$year <= 1975] <- 817
long$ccode[long$iso3 == "YEM" & long$year < 1990] <- 678
lg("US case-target-years: %d; targets without a COW state: %s", nrow(long), paste(sort(unique(long$target[is.na(long$ccode)])), collapse = "; "))
long <- long[!is.na(long$ccode), ]

sys_ <- read.csv(file.path(raw, "System2024/system2024.csv"), stringsAsFactors = FALSE)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))
key <- paste(frame$ccode, frame$year); k <- paste(long$ccode, long$year)
off <- unique(k[!k %in% key])
lg("Target-years outside the frame: %d%s", length(off), if (length(off)) paste0(" (", paste(head(off, 30), collapse = "; "), ")") else "")
out <- frame
n <- tapply(long$case_id, k, function(v) length(unique(v)))
out$fin_gsdb_cases <- ifelse(is.na(n[key]), 0L, as.integer(n[key]))
n1 <- tapply(long$case_id[long$single], k[long$single], function(v) length(unique(v)))
out$fin_gsdb_cases_single <- ifelse(is.na(n1[key]), 0L, as.integer(n1[key]))
for (s in names(sub)) out[[paste0("fin_gsdb_", s)]] <- as.integer(key %in% k[long[[s]]])
for (v in names(out)[-(1:2)])
  lg("%s: %d state-years; states flagged in %s", v, sum(out[[v]] > 0),
     paste(sapply(c(1950, 1970, 1990, 2010, 2025), function(y) paste0(y, " ", sum(out[[v]][out$year == y] > 0))), collapse = ", "))

# ---- calibration against the SDN designation counts, 1995-2025
fin <- read.csv(file.path(outd, "financial_country_year.csv"), stringsAsFactors = FALSE)
m <- merge(out[out$year %in% 1995:2025, ], fin[, c("ccode", "year", "fin_program_count")], by = c("ccode", "year"), all.x = TRUE)
m$fin_program_count[is.na(m$fin_program_count)] <- 0
sdn <- m$fin_program_count > 0
af <- m$fin_gsdb_asset_freeze == 1 | m$fin_gsdb_services == 1
lg("Calibration 1995-2025 (%d state-years): SDN program additions > 0 in %d; GSDB-FS US asset-freeze or financial-services case in %d",
   nrow(m), sum(sdn), sum(af))
lg("  Of state-years with SDN program additions, %.1f%% have such a GSDB-FS case; of state-years with such a case, %.1f%% have SDN program additions",
   100 * mean(af[sdn]), 100 * mean(sdn[af]))
lg("  Spearman correlation, GSDB-FS US case count with SDN program additions: %.2f (all state-years); %.2f (state-years with either)",
   cor(m$fin_gsdb_cases, m$fin_program_count, method = "spearman"),
   cor(m$fin_gsdb_cases[sdn | af], m$fin_program_count[sdn | af], method = "spearman"))
yrs <- aggregate(cbind(cases = m$fin_gsdb_cases, sdn = m$fin_program_count) ~ m$year, FUN = sum)
lg("  Yearly totals (year: GSDB-FS US cases in force / SDN program additions): %s",
   paste(sprintf("%d: %d/%d", yrs[[1]], yrs$cases, yrs$sdn), collapse = "; "))
lg("  Year-level correlation of the two totals: %.2f", cor(yrs$cases, yrs$sdn))
s1 <- m$fin_gsdb_cases_single > 0
lg("  Single-target cases only: of state-years with SDN program additions, %.1f%% have one; of state-years with one, %.1f%% have SDN program additions",
   100 * mean(s1[sdn]), 100 * mean(sdn[s1]))
write.csv(out[order(out$ccode, out$year), ], file.path(outd, "financial_gsdb_country_year.csv"), row.names = FALSE)
