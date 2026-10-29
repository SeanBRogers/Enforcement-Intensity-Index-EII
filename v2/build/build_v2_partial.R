# EII v2 — partial build (frame, sanctioned flag, kinetic, proxy, posture, penalties, financial)
# Governed by BUILD_PROTOCOL.md (committed 2026-10-27, before any download).
# One code path for every year 1950–2025 (Rule 4). Missing is not zero (Rule 3).
#
# Inputs (raw snapshots, listed with SHA-256 in v2/sources/MANIFEST.csv):
#   v2/sources/raw/System2024/system2024.csv          COW State System v2024
#   v2/sources/raw/GSDB-R5.csv, GSDB-R5_Dyadic.dta      Global Sanctions Data Base, release 5 (by request)
#   v2/sources/raw/ucdp_acd_261/UcdpPrioConflict_v26_1.csv  UCDP/PRIO ACD v26.1
#   troopdata R package 1.1.0 (get_troopdata), snapshotted to
#   v2/sources/raw/troopdata_1.1.0_troops_ad.csv
#
# Outputs:
#   v2/output/EII_v2_partial.csv
#   v2/output/crosswalk_gsdb_targets.csv
#   v2/output/kinetic_conflict_years.csv
#   v2/output/build_log.txt

suppressPackageStartupMessages({ library(countrycode) })
set.seed(42)
args <- commandArgs(trailingOnly = TRUE)   # optional: repository root (default: working directory)
root <- if (length(args)) args[1] else getwd()
raw  <- file.path(root, "v2", "sources", "raw")
out  <- file.path(root, "v2", "output")
dir.create(out, showWarnings = FALSE, recursive = TRUE)
logf <- file.path(out, "build_log.txt")
cat("EII v2 partial build\n", file = logf)
lg <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = logf, append = TRUE) }
lg("Run: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), " | ", R.version.string,
   " | countrycode ", as.character(packageVersion("countrycode")))

YEARS <- 1950:2025

# ---------------------------------------------------------------- 1. Frame (D1)
sys_ <- read.csv(file.path(raw, "System2024", "system2024.csv"), stringsAsFactors = FALSE)
fr <- sys_[sys_$year >= 1950 & sys_$year <= 2024, c("ccode", "stateabb", "statenme", "year")]
f25 <- fr[fr$year == 2024, ]; f25$year <- 2025L          # 2025 carried forward (D1)
fr <- rbind(fr, f25)
fr <- fr[fr$ccode != 2, ]                                  # the US is not its own target
fr <- fr[order(fr$ccode, fr$year), ]
lg("Frame: ", nrow(fr), " country-years, ", length(unique(fr$ccode)), " states, ",
   min(fr$year), "-", max(fr$year), " (2025 = 2024 membership carried forward; US excluded)")

# ------------------------------------------------- 2. Sanctioned flag (D2, GSDB release 5)
# Cases: GSDB-R5 case list, cases naming the United States among their senders (alone or with named
# partners). UN- or coalition-only cases are excluded (Q2: US actions only).
# Targets and years: GSDB-R5 dyadic file, United States sender rows that draw on at least one of those
# cases. The codebook (8.1) advises the dyadic file for dyad-year indicators, and its target ISO3 codes
# avoid splitting the case list's comma-separated target strings (codebook 4).
suppressPackageStartupMessages(library(haven))
c5 <- read.csv(file.path(raw, "GSDB-R5.csv"), stringsAsFactors = FALSE, na.strings = "NA")
us <- c5[grepl("United States", c5$sanctioning_state, fixed = TRUE), ]
lg("GSDB-R5 case list: ", nrow(c5), " cases; ", nrow(us), " name the United States among senders (",
   sum(us$target_mult == 1), " with several targets)")
lg("GSDB-R5 file check: cases with a blank end_year: ", sum(is.na(c5$end_year)), "; ending 2025: ", sum(c5$end_year == 2025, na.rm = TRUE),
   " (the codebook says ongoing cases have a blank end_year; this file codes them 2025, which leaves the flag unchanged)")
dy <- read_dta(file.path(raw, "GSDB-R5_Dyadic.dta"))
du <- as.data.frame(dy[dy$sanctioning_state == "United States", ])
ids <- lapply(strsplit(as.character(du$case_id), ","), function(x) as.integer(trimws(x)))
named  <- vapply(ids, function(x) any(x %in% us$case_id), logical(1))
single <- vapply(ids, function(x) any(x %in% us$case_id[us$target_mult == 0]), logical(1))
ncase  <- vapply(ids, function(x) sum(x %in% us$case_id), integer(1))
lg("GSDB-R5 dyadic: ", nrow(du), " United States sender dyad-years; ", sum(named), " draw on a US-named case; ",
   sum(!named), " only on UN or coalition cases (excluded)")
du <- du[named, ]; du$single <- single[named]; du$ncase <- ncase[named]
# Target ISO3 (USITC Dynamic Gravity codes) to COW, year-aware where codes span a change of state
iso_special <- c(CSK = 315, DDR = 265, KSV = 347, VDR = 816, RHO = 552, SRB = 345, SVU = 365)
du$ccode <- suppressWarnings(countrycode(du$sanctioned_state_iso3, "iso3c", "cown"))
hit <- du$sanctioned_state_iso3 %in% names(iso_special)
du$ccode[hit] <- iso_special[du$sanctioned_state_iso3[hit]]
du$ccode[du$sanctioned_state_iso3 == "DEU" & du$year <= 1990] <- 260      # FRG to 1990, Germany after
du$ccode[du$sanctioned_state_iso3 == "VNM" & du$year <= 1975] <- 817      # GSDB "South Vietnam" (VNM) before unification
du$ccode[du$sanctioned_state_iso3 == "YEM" & du$year < 1990] <- 678       # GSDB "Yemen, North" (YEM) before unification
ua <- unique(du$sanctioned_state[is.na(du$ccode)])
lg("GSDB-R5 targets without a COW state (not assigned): ", paste(sort(ua), collapse = "; "))
du <- du[!is.na(du$ccode), ]
cw <- unique(du[, c("sanctioned_state", "sanctioned_state_iso3", "ccode")]); cw <- cw[order(cw$sanctioned_state, cw$ccode), ]
write.csv(cw, file.path(out, "crosswalk_gsdb_targets.csv"), row.names = FALSE)
nc <- aggregate(cbind(us_sanction_cases = ncase, single = single) ~ ccode + year, data = du, FUN = max)
nc$under_sanctions_us_single <- as.integer(nc$single > 0); nc$single <- NULL
fr <- merge(fr, nc, by = c("ccode", "year"), all.x = TRUE)
off <- setdiff(paste(nc$ccode, nc$year), paste(fr$ccode, fr$year))
lg("Target-years outside the frame (state not a system member that year), dropped: ", length(off),
   if (length(off)) paste0(" — by code: ", paste(names(table(sub(" .*", "", off))), table(sub(" .*", "", off)), sep = " x", collapse = ", ")) else "")
fr$us_sanction_cases[is.na(fr$us_sanction_cases)] <- 0L
fr$under_sanctions_us_single[is.na(fr$under_sanctions_us_single)] <- 0L
fr$under_sanctions_us <- as.integer(fr$us_sanction_cases > 0)
lg("States under US sanctions (any / single-target cases): ",
   paste(sapply(c(1950, 1970, 1990, 2010, 2020, 2023, 2025), function(y) paste0(y, " ", sum(fr$under_sanctions_us[fr$year == y]), "/",
         sum(fr$under_sanctions_us_single[fr$year == y]))), collapse = "; "))

# ------------------------------------------------ 3. Kinetic (D5, UCDP/PRIO v26.1)
a <- read.csv(file.path(raw, "ucdp_acd_261", "UcdpPrioConflict_v26_1.csv"),
              stringsAsFactors = FALSE, colClasses = "character")
codes <- function(s) { x <- trimws(strsplit(s, ",", fixed = TRUE)[[1]]); x <- x[x != ""]; as.integer(x) }
has_us <- function(s) 2L %in% codes(s)
k <- list()
for (i in seq_len(nrow(a))) {
  r <- a[i, ]
  sides <- c(A = has_us(r$gwno_a) | has_us(r$gwno_a_2nd), B = has_us(r$gwno_b) | has_us(r$gwno_b_2nd))
  if (!any(sides)) next
  yr <- as.integer(r$year); typ <- as.integer(r$type_of_conflict); inten <- as.integer(r$intensity_level)
  if (typ == 2) {                              # interstate: target = the opposing state(s)
    tg <- if (sides["A"]) codes(r$gwno_b) else codes(r$gwno_a); kind <- "vs_state"
  } else if (sides["B"]) {                     # US backs the non-government side: against the state
    tg <- codes(r$gwno_a); kind <- "vs_state"
  } else {                                     # US backs (or is) the government: force spent in the location
    tg <- codes(r$gwno_loc); kind <- "in_state"
  }
  tg <- setdiff(tg, 2L)
  if (!length(tg)) { lg("Kinetic unassigned (no foreign target): conflict ", r$conflict_id, " ", yr, " ", r$location); next }
  for (t in tg) k[[length(k) + 1]] <- data.frame(conflict_id = r$conflict_id, year = yr, gwno = t,
                                                 kind = kind, type = typ, intensity = inten, location = r$location)
}
k <- do.call(rbind, k)
k$ccode <- suppressWarnings(countrycode(k$gwno, "gwn", "cown"))
same <- is.na(k$ccode) & paste(k$gwno, k$year) %in% paste(sys_$ccode, sys_$year)
lg("Kinetic GW codes with no countrycode match, taken as the identical COW code (valid COW member that year): ",
   paste(unique(paste0(k$gwno[same], " (", k$location[same], ")")), collapse = "; "))
k$ccode[same] <- k$gwno[same]
k$ccode[k$gwno == 678 & k$year >= 1990] <- 679                     # GW 678 = unified Yemen after 1990
k$ccode[k$gwno == 340] <- 345                                      # GW Serbia = COW 345
lg("Kinetic: ", nrow(k), " US-party conflict-target-years from ", length(unique(k$conflict_id)),
   " conflicts; GW codes without a COW code: ", sum(is.na(k$ccode)))
k <- k[k$year >= 1950, ]
write.csv(k, file.path(out, "kinetic_conflict_years.csv"), row.names = FALSE)
agg <- function(sub, nm) { if (!nrow(sub)) return(NULL)
  x <- aggregate(intensity ~ ccode + year, data = sub, FUN = max); names(x)[3] <- nm; x }
kv <- agg(k[k$kind == "vs_state", ], "kin_vs_state_intensity")
ki <- agg(k[k$kind == "in_state", ], "kin_in_state_intensity")
fr <- merge(fr, kv, by = c("ccode", "year"), all.x = TRUE)
fr <- merge(fr, ki, by = c("ccode", "year"), all.x = TRUE)
for (v in c("kin_vs_state_intensity", "kin_in_state_intensity")) fr[[v]][is.na(fr[[v]])] <- 0L
fr$kin_vs_state <- as.integer(fr$kin_vs_state_intensity > 0)
fr$kin_in_state <- as.integer(fr$kin_in_state_intensity > 0)
offk <- setdiff(paste(k$ccode, k$year), paste(fr$ccode, fr$year))
lg("Kinetic target-years outside the frame: ", length(offk), if (length(offk)) paste0(" (", paste(offk, collapse = "; "), ")") else "")

# ------------------------------------------- 3b. Covert and proxy support (build_proxy.R, UCDP ESD 18.1)
px <- read.csv(file.path(out, "proxy_country_year.csv"), stringsAsFactors = FALSE)
pv <- c("proxy_vs_state", "proxy_vs_state_types", "proxy_vs_state_alleged",
        "proxy_for_state", "proxy_for_state_types", "proxy_for_state_alleged")
stopifnot(setequal(paste(px$ccode, px$year), paste(fr$ccode, fr$year)))
fr <- merge(fr, px[, c("ccode", "year", pv)], by = c("ccode", "year"), all.x = TRUE)   # missing outside 1975-2017 (ESD coverage)
lg("Proxy support (ESD 1975-2017): US support short of troops against the state in ", sum(fr$proxy_vs_state, na.rm = TRUE),
   " state-years (", sum(fr$proxy_vs_state_alleged, na.rm = TRUE), " alleged only); to the state in ",
   sum(fr$proxy_for_state, na.rm = TRUE), " (", sum(fr$proxy_for_state_alleged, na.rm = TRUE), " alleged only)")

# ------------------------------------- 3c. Regime change attempts (build_regime_change.R, O'Rourke 2018)
rc <- read.csv(file.path(out, "regime_change_country_year.csv"), stringsAsFactors = FALSE)
rv <- c("rc_covert", "rc_covert_planned", "rc_covert_type", "rc_covert_leader_removal", "rc_covert_succeeded", "rc_overt")
stopifnot(setequal(paste(rc$ccode, rc$year), paste(fr$ccode, fr$year)))
fr <- merge(fr, rc[, c("ccode", "year", rv)], by = c("ccode", "year"), all.x = TRUE)    # missing from 1990 (source ends 1989)
lg("Regime change (O'Rourke, 1947-1989): covert attempt underway in ", sum(fr$rc_covert, na.rm = TRUE),
   " state-years; overt in ", sum(fr$rc_overt, na.rm = TRUE))

# ------------------------------------------------------------ 4. Posture (troopdata)
tp <- read.csv(file.path(raw, "troopdata_1.1.0_troops_ad.csv"), stringsAsFactors = FALSE)
tp <- tp[tp$year >= 1950 & tp$year <= 2025, ]
tp$ccode[tp$ccode == 260 & tp$year >= 1991] <- 255                # troopdata codes Germany 260 throughout
tp <- aggregate(troops_ad ~ ccode + year, data = tp, FUN = sum)
fr <- merge(fr, tp, by = c("ccode", "year"), all.x = TRUE)
names(fr)[names(fr) == "troops_ad"] <- "posture_troops_ad"
fr$posture_note <- ifelse(is.na(fr$posture_troops_ad), "no source row", "")
war <- (fr$kin_vs_state == 1 | fr$kin_in_state == 1) & fr$year >= 2018
lg("Posture set missing in ", sum(war & !is.na(fr$posture_troops_ad)),
   " US-party conflict country-years from 2018 (official reports omit war-zone deployments; zeros there are not observed zeros)")
fr$posture_troops_ad[war] <- NA
fr$posture_note[war] <- "war-zone deployment not reported (2018+)"
lg("Posture: country-years with no troopdata row (missing): ", sum(fr$posture_note == "no source row"))

# ------------------------------------------------------- 5. Penalties (build_penalties.R)
pen <- read.csv(file.path(out, "penalties_country_year.csv"), stringsAsFactors = FALSE)
fr <- merge(fr, pen[, c("ccode", "year", "pen_program_count", "pen_program_count_firms")], by = c("ccode", "year"), all.x = TRUE)
for (v in c("pen_program_count", "pen_program_count_firms")) {
  fr[[v]][is.na(fr[[v]]) & fr$year >= 2003] <- 0L                              # OFAC's record covers 2003-2025
  fr[[v]][fr$year < 2003] <- NA                                                 # no source before 2003 (Rule 3)
}
offp <- setdiff(paste(pen$ccode[!is.na(pen$pen_program_count)], pen$year[!is.na(pen$pen_program_count)]), paste(fr$ccode, fr$year))
lg("Penalties: ", sum(fr$pen_program_count, na.rm = TRUE), " program-attributed penalty-country counts merged; ",
   "program country-years outside the frame: ", length(offp), if (length(offp)) paste0(" (", paste(offp, collapse = "; "), ")") else "")

# ---------------------------------------------- 6. Financial (build_financial.R)
fin <- read.csv(file.path(out, "financial_country_year.csv"), stringsAsFactors = FALSE)
fv <- c("fin_program_count", "fin_program_count_nonindiv", "fin_location_count", "fin_thematic_location_count")
fr <- merge(fr, fin[, c("ccode", "year", fv)], by = c("ccode", "year"), all.x = TRUE)
for (v in fv) {
  fr[[v]][is.na(fr[[v]]) & fr$year >= 1995] <- 0L                              # itemized archive covers 1995-2025
  fr[[v]][fr$year < 1995] <- NA                                                 # 1994 estimated below (program count only); pre-1994 needs the Federal Register
}
# 1994: the change file is narrative, so program counts are estimated
# (estimate_sdn_1994.R; Sean, 2026-10-29) with bounds; the split by type and
# the location attribution are not estimated and stay missing.
e94 <- read.csv(file.path(out, "sdn_1994_estimate.csv"), stringsAsFactors = FALSE)
y94 <- fr$year == 1994
fr$fin_program_count[y94] <- 0L
m <- match(paste(fr$ccode[y94], 1994), paste(e94$ccode, e94$year))
fr$fin_program_count[y94][!is.na(m)] <- e94$point[m[!is.na(m)]]
fr$fin_program_count_low  <- fr$fin_program_count
fr$fin_program_count_high <- fr$fin_program_count
fr$fin_program_count_low[y94][!is.na(m)]  <- e94$low[m[!is.na(m)]]
fr$fin_program_count_high[y94][!is.na(m)] <- e94$high[m[!is.na(m)]]
fr$fin_estimated <- ifelse(is.na(fr$fin_program_count), NA_integer_, as.integer(y94))
fr$fin_thematic_location_count[y94] <- 0L                  # no non-country program existed in 1994 (SDT from 1995, SDNT from October 1995)
stopifnot(all(e94$ccode %in% fr$ccode[y94]))
lg("Financial 1994 (estimated from the narrative change file): ", sum(e94$point), " additions (bounds ",
   sum(e94$low), "-", sum(e94$high), ") in ", nrow(e94), " program countries; type split and location missing for 1994")
for (v in c("fin_program_count", "fin_location_count")) {
  off <- setdiff(paste(fin$ccode[fin[[v]] > 0], fin$year[fin[[v]] > 0]), paste(fr$ccode, fr$year))
  lg("Financial ", v, ": ", sum(fr[[v]], na.rm = TRUE), " counts merged; country-years outside the frame: ", length(off),
     if (length(off)) paste0(" (", paste(off, collapse = "; "), "; code 2 is the United States, excluded as a target)") else "")
}

# ------------------------------------- 6b. Financial case series 1950-2025 (build_gsdb_fs.R, GSDB-FS)
gf <- read.csv(file.path(out, "financial_gsdb_country_year.csv"), stringsAsFactors = FALSE)
gv <- setdiff(names(gf), c("ccode", "year"))
stopifnot(setequal(paste(gf$ccode, gf$year), paste(fr$ccode, fr$year)))
fr <- merge(fr, gf, by = c("ccode", "year"), all.x = TRUE)
lg("Financial cases (GSDB-FS, US-named): ", sum(fr$fin_gsdb_cases > 0), " state-years with a case in force, 1950-2025")

# ------------------------------------------------------------- 6c. Trade channel (build_trade.R)
tr <- read.csv(file.path(out, "trade_country_year.csv"), stringsAsFactors = FALSE)
stopifnot(setequal(paste(tr$ccode, tr$year), paste(fr$ccode, fr$year)))
fr <- merge(fr, tr, by = c("ccode", "year"), all.x = TRUE)
lg("Trade (Section 301, 232, emergency tariffs): ", sum(fr$trade_301_investigation > 0, na.rm = TRUE), " state-years with a 301 investigation; ",
   sum(fr$trade_301_action > 0, na.rm = TRUE), " with a 301 action (1995-); ", sum(fr$trade_232_named > 0), " with a named 232 measure; ",
   sum(fr$trade_ieepa_named > 0), " with named emergency tariffs")

# ------------------------------------------------------------------ 7. Write
fr <- fr[order(fr$ccode, fr$year), c("ccode", "stateabb", "statenme", "year",
        "under_sanctions_us", "under_sanctions_us_single", "us_sanction_cases",
        "kin_vs_state", "kin_vs_state_intensity", "kin_in_state", "kin_in_state_intensity",
        "proxy_vs_state", "proxy_vs_state_types", "proxy_vs_state_alleged",
        "proxy_for_state", "proxy_for_state_types", "proxy_for_state_alleged",
        "rc_covert", "rc_covert_planned", "rc_covert_type", "rc_covert_leader_removal", "rc_covert_succeeded", "rc_overt",
        "posture_troops_ad", "posture_note", "pen_program_count", "pen_program_count_firms",
        "fin_program_count", "fin_program_count_low", "fin_program_count_high", "fin_estimated",
        "fin_program_count_nonindiv", "fin_location_count", "fin_thematic_location_count",
        "fin_gsdb_cases", "fin_gsdb_cases_single", "fin_gsdb_asset_freeze", "fin_gsdb_services", "fin_gsdb_aid",
        "fin_gsdb_investment", "fin_gsdb_payment_infra", "fin_gsdb_other",
        "trade_301_investigation", "trade_301_action", "trade_232_named", "trade_ieepa_named", "trade_via_eu")]
write.csv(fr, file.path(out, "EII_v2_partial.csv"), row.names = FALSE, na = "")
lg("Wrote EII_v2_partial.csv: ", nrow(fr), " rows, ", ncol(fr), " columns")
lg("Not yet built here: multilateral block, target burden block (covariates: build_covariates.R)")
