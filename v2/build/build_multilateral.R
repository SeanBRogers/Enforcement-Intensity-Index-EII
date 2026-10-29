# EII v2 -- multilateral block (BUILD_PROTOCOL.md D4, Q2 as amended 2026-10-27).
# Outside the index: kept to test whether the US moves enforcement onto others
# and toward cheaper instruments, and to carry the tier-2 question (UN action
# the US drafted or sponsored) once case evidence is coded.
#
# Source: GSDB release 5. Cases are classed by sender from the case list; the
# targets and years come from the dyadic file, as for the US flag (the dyadic
# file spreads a UN case over every member state as a sender).
#   un_*      cases whose sender is the UN (Security Council measures)
#   eu_*      cases naming the EU among their senders
#   regional  cases by other organizations (NATO, ECOWAS, OAU/AU, Arab League,
#             OAS and the like)
# Tier (US-led or not) is not coded here: it needs case evidence (drafter or
# sponsor of the resolution) and stays OPEN.
#
# Output: v2/output/multilateral_country_year.csv. Usage: Rscript v2/build/build_multilateral.R [repo_root]

suppressPackageStartupMessages({ library(countrycode); library(haven) })
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "multilateral_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 multilateral block build, %s; R %s; countrycode %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
   getRversion(), packageVersion("countrycode"))

c5 <- read.csv(file.path(raw, "GSDB-R5.csv"), stringsAsFactors = FALSE, na.strings = "NA")
orgs <- "NATO|ECOWAS|African Union|Organisation of African Unity|League of Arab States|Organization of American States|OAS|Gulf Cooperation|Commonwealth|CARICOM|SADC|IGAD|ECCAS|EAC"
c5$cls_un <- c5$sanctioning_state == "UN"
c5$cls_eu <- grepl("(^|, )EU(,|$)", c5$sanctioning_state)
c5$cls_reg <- grepl(orgs, c5$sanctioning_state)
c5$us_named <- grepl("United States", c5$sanctioning_state, fixed = TRUE)
lg("GSDB-R5 cases: UN %d; EU among senders %d (%d also naming the US); other organizations %d",
   sum(c5$cls_un), sum(c5$cls_eu), sum(c5$cls_eu & c5$us_named), sum(c5$cls_reg))
lg("Other-organization senders: %s", paste(sort(unique(c5$sanctioning_state[c5$cls_reg])), collapse = "; "))

dy <- as.data.frame(read_dta(file.path(raw, "GSDB-R5_Dyadic.dta")))
dy <- unique(dy[, c("case_id", "sanctioned_state_iso3", "sanctioned_state", "year")])
ids <- lapply(strsplit(as.character(dy$case_id), ","), function(x) as.integer(trimws(x)))
pick <- function(cls) vapply(ids, function(x) any(x %in% c5$case_id[cls]), logical(1))
count <- function(cls) vapply(ids, function(x) sum(x %in% c5$case_id[cls]), integer(1))
dy$un <- pick(c5$cls_un); dy$eu <- pick(c5$cls_eu); dy$reg <- pick(c5$cls_reg)
dy$n_un <- count(c5$cls_un)
dy$un_fin <- pick(c5$cls_un & c5$financial == 1)                   # financial measures, from the case list
dy$eu_no_us <- vapply(ids, function(x) any(x %in% c5$case_id[c5$cls_eu & !c5$us_named]), logical(1))
dy <- dy[dy$un | dy$eu | dy$reg, ]
# target ISO3 (USITC Dynamic Gravity codes) to COW: the rules of build_v2_partial.R
iso_special <- c(CSK = 315, DDR = 265, KSV = 347, VDR = 816, RHO = 552, SRB = 345, SVU = 365)
dy$ccode <- suppressWarnings(countrycode(dy$sanctioned_state_iso3, "iso3c", "cown"))
hit <- dy$sanctioned_state_iso3 %in% names(iso_special)
dy$ccode[hit] <- iso_special[dy$sanctioned_state_iso3[hit]]
dy$ccode[dy$sanctioned_state_iso3 == "DEU" & dy$year <= 1990] <- 260
dy$ccode[dy$sanctioned_state_iso3 == "VNM" & dy$year <= 1975] <- 817
dy$ccode[dy$sanctioned_state_iso3 == "YEM" & dy$year < 1990] <- 678
lg("Targets without a COW state (not assigned): %s", paste(sort(unique(dy$sanctioned_state[is.na(dy$ccode)])), collapse = "; "))
dy <- dy[!is.na(dy$ccode), ]

sys_ <- read.csv(file.path(raw, "System2024/system2024.csv"), stringsAsFactors = FALSE)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))
k <- paste(dy$ccode, dy$year); key <- paste(frame$ccode, frame$year)
off <- unique(k[!k %in% key])
lg("Target-years outside the frame: %d%s", length(off), if (length(off)) paste0(" (", paste(head(off, 40), collapse = "; "), ")") else "")
out <- frame
out$un_sanctions <- as.integer(key %in% k[dy$un])
nun <- tapply(dy$n_un, k, max)
out$un_sanction_cases <- ifelse(is.na(nun[key]), 0L, as.integer(nun[key]))
out$un_sanctions_financial <- as.integer(key %in% k[dy$un_fin])
out$eu_sanctions <- as.integer(key %in% k[dy$eu])
out$eu_sanctions_no_us <- as.integer(key %in% k[dy$eu_no_us])
out$regional_sanctions <- as.integer(key %in% k[dy$reg])
for (v in names(out)[-(1:2)])
  lg("%s: %d state-years; by decade %s", v, sum(out[[v]] > 0),
     paste(sapply(seq(1950, 2020, 10), function(d) paste0(d, "s ", sum(out[[v]][out$year %in% d:(d + 9)] > 0))), collapse = ", "))
write.csv(out[order(out$ccode, out$year), ], file.path(outd, "multilateral_country_year.csv"), row.names = FALSE)
