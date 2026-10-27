# EII v2 — partial build (frame, sanctioned flag, kinetic, posture)
# Governed by BUILD_PROTOCOL.md (committed 2026-10-27, before any download).
# One code path for every year 1950–2025 (Rule 4). Missing is not zero (Rule 3).
#
# Inputs (raw snapshots, listed with SHA-256 in v2/sources/MANIFEST.csv):
#   v2/sources/raw/System2024/system2024.csv          COW State System v2024
#   v2/sources/raw/GSDB_V4.csv                         Global Sanctions Database v4
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

# ------------------------------------------------- 2. Sanctioned flag (D2, GSDB v4)
g <- read.csv(file.path(raw, "GSDB_V4.csv"), stringsAsFactors = FALSE, encoding = "UTF-8")
us <- g[grepl("United States", g$sanctioning_state, fixed = TRUE), ]
lg("GSDB v4: ", nrow(g), " cases; ", nrow(us), " name the United States among senders; ",
   "begin ", min(us$begin), "-", max(us$begin), ", end max ", max(g$end),
   " (ongoing cases coded end = 2023)")

protect <- c("Korea, North" = "Korea North", "Korea, South" = "Korea South",
             "Congo, Democratic Republic of the" = "Congo DR", "Gambia, The" = "Gambia",
             "Egypt, Arab Rep." = "Egypt", "Yemen, North" = "Yemen North")
split_targets <- function(s) {
  for (k in names(protect)) s <- gsub(k, protect[[k]], s, fixed = TRUE)
  trimws(strsplit(s, ",", fixed = TRUE)[[1]])
}
# Explicit COW codes for names countrycode does not resolve or resolves ambiguously.
# NA = not a COW state; the case-target is logged as unassigned.
special <- c("Korea North" = 731, "Korea South" = 732, "Congo DR" = 490, "Gambia" = 420,
             "Egypt" = 651, "Yemen North" = 678, "German Democratic Republic" = 265,
             "Soviet Union" = 365, "Russia" = 365, "Yugoslavia" = 345, "Serbia" = 345,
             "Ceylon" = 780, "Malagasy Republic" = 580, "Malaya" = 820, "Rhodesia" = 552,
             "Transjordan" = 663, "Taiwan" = 713, "North Vietnam" = 816, "South Vietnam" = 817,
             "Ethiopia (excludes Eritrea)" = 530, "Czechoslovakia" = 315, "Macedonia" = 343,
             "Kosovo" = 347, "Montenegro" = 341, "Marshall Islands" = 983,
             "Balkans" = NA, "Hong Kong" = NA, "Palestine" = NA,
             "ICC Rome Statute Signatories" = NA, "League of Arab States" = NA)
cow_of <- function(nm, yr) {
  if (nm %in% names(special)) {
    cc <- unname(special[nm])
  } else {
    cc <- suppressWarnings(countrycode(nm, "country.name", "cown"))
  }
  if (is.na(cc)) return(NA_integer_)
  if (nm == "Germany") cc <- if (yr <= 1990) 260 else 255          # FRG to 1990, Germany after
  if (nm == "Yemen") cc <- if (yr < 1990) 678 else 679              # unified Yemen from 1990
  # GSDB label quirks (checked 2026-10-27 against case years): "Yemen, North" is used for unified
  # Yemen after 1990 (cases 962, 1093, 1204); "South Vietnam" is used for unified Vietnam after
  # 1975 (cases 195, 200, 201, 519, 809).
  if (nm == "Yemen North" && yr >= 1990) cc <- 679
  if (nm == "South Vietnam" && yr >= 1976) cc <- 816
  as.integer(cc)
}
rows <- list(); unassigned <- list()
for (i in seq_len(nrow(us))) {
  for (nm in split_targets(us$sanctioned_state[i])) {
    for (yr in max(1950, us$begin[i]):us$end[i]) {
      cc <- cow_of(nm, yr)
      if (is.na(cc)) { unassigned[[length(unassigned) + 1]] <- data.frame(case_id = us$case_id[i], target_name = nm); next }
      rows[[length(rows) + 1]] <- data.frame(case_id = us$case_id[i], target_name = nm, ccode = cc, year = yr)
    }
  }
}
cy <- do.call(rbind, rows)
cw <- unique(cy[, c("target_name", "ccode")]); cw <- cw[order(cw$target_name, cw$ccode), ]
ua <- unique(do.call(rbind, unassigned))
write.csv(cw, file.path(out, "crosswalk_gsdb_targets.csv"), row.names = FALSE)
lg("GSDB targets: ", length(unique(cw$target_name)), " names mapped to COW codes (",
   "crosswalk_gsdb_targets.csv); ", nrow(ua), " case-targets unassigned (not COW states): ",
   paste(sort(unique(ua$target_name)), collapse = "; "))
nc <- aggregate(case_id ~ ccode + year, data = unique(cy[, c("case_id", "ccode", "year")]), FUN = length)
names(nc)[3] <- "us_sanction_cases"
fr <- merge(fr, nc, by = c("ccode", "year"), all.x = TRUE)
off <- setdiff(paste(nc$ccode, nc$year), paste(fr$ccode, fr$year))
lg("Case-target-years outside the frame (state not a system member that year), dropped: ", length(off),
   if (length(off)) paste0(" — by code: ", paste(names(table(sub(" .*", "", off))), table(sub(" .*", "", off)), sep = " x", collapse = ", ")) else "")
fr$us_sanction_cases[is.na(fr$us_sanction_cases)] <- 0L
fr$under_sanctions_us <- as.integer(fr$us_sanction_cases > 0)
fr$us_sanction_cases[fr$year > 2023] <- NA                       # GSDB v4 ends 2023 (Rule 3)
fr$under_sanctions_us[fr$year > 2023] <- NA

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

# ------------------------------------------------------------------ 6. Write
fr <- fr[order(fr$ccode, fr$year), c("ccode", "stateabb", "statenme", "year",
        "under_sanctions_us", "us_sanction_cases",
        "kin_vs_state", "kin_vs_state_intensity", "kin_in_state", "kin_in_state_intensity",
        "posture_troops_ad", "posture_note", "pen_program_count", "pen_program_count_firms")]
write.csv(fr, file.path(out, "EII_v2_partial.csv"), row.names = FALSE, na = "")
lg("Wrote EII_v2_partial.csv: ", nrow(fr), " rows, ", ncol(fr), " columns")
lg("Not yet built: financial (SDN) channel, multilateral block, burden blocks, covariates")
