# EII v2 -- controls and the kill test (BUILD_PROTOCOL.md Q14, Q15).
#
# Q15 (what kills the theory: "Someone attacks us. Sanctions us."): the US as
# target, by the state acting against it.
#   mid_vs_us*       COW Militarized Interstate Disputes 5.0 (participant file),
#                    1950-2014; blank after (the source ends in 2014)
#   sanctions_on_us  GSDB release 5: the state is a sender in a sanctions case
#                    against the United States (EU and UN cases count for every
#                    member, as GSDB's dyadic file spreads them)
# Terrorism against US targets (GTD) and state cyber operations against the US
# are not built yet (sources pending).
#
# Q14 (conflict in the target, from events the kinetic channel does not count):
#   conflict_nonus*  UCDP/PRIO ACD v26.1 conflicts in which the US is not a
#                    party: located in the state, or the state a party
#
# Output: v2/output/controls_country_year.csv. Usage: Rscript v2/build/build_controls.R [repo_root]

suppressPackageStartupMessages({ library(countrycode); library(haven) })
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "controls_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 controls build, %s; R %s; countrycode %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), getRversion(), packageVersion("countrycode"))

sys_ <- read.csv(file.path(raw, "System2024/system2024.csv"), stringsAsFactors = FALSE)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))
key <- paste(frame$ccode, frame$year)
out <- frame
outside <- function(k, what) { o <- unique(k[!k %in% key])
  lg("%s: state-years outside the frame %d%s", what, length(o), if (length(o)) paste0(" (", paste(head(o, 30), collapse = "; "), ")") else "") }

# ---------------------------------------------------------------- Q15: MIDs against the US
b <- read.csv(file.path(raw, "mid/mid5/MIDB 5.0.csv"), stringsAsFactors = FALSE)
us <- b[b$ccode == 2, c("dispnum", "sidea")]
o <- merge(us, b[b$ccode != 2, c("dispnum", "ccode", "styear", "endyear", "sidea", "hostlev")], by = "dispnum", suffixes = c(".us", ""))
o <- o[o$sidea != o$sidea.us & o$endyear >= 1950, ]
lg("MID 5.0: %d disputes with the US; %d opponent participations ending 1950 or later", length(unique(us$dispnum)), nrow(o))
my <- do.call(rbind, lapply(seq_len(nrow(o)), function(i)
  data.frame(ccode = o$ccode[i], year = max(o$styear[i], 1950):o$endyear[i], init = o$sidea[i] == 1, force = o$hostlev[i] >= 4)))
mk <- paste(my$ccode, my$year)
outside(mk, "MID opponents of the US")
out$mid_vs_us <- as.integer(key %in% mk)
out$mid_vs_us_initiator <- as.integer(key %in% mk[my$init])
out$mid_vs_us_force <- as.integer(key %in% mk[my$force])
out$mid_vs_us_attack <- as.integer(key %in% mk[my$init & my$force])
for (v in c("mid_vs_us", "mid_vs_us_initiator", "mid_vs_us_force", "mid_vs_us_attack")) out[[v]][out$year > 2014] <- NA
lg("mid_vs_us %d, initiator %d, used force %d, initiated and used force %d state-years (1950-2014)",
   sum(out$mid_vs_us, na.rm = TRUE), sum(out$mid_vs_us_initiator, na.rm = TRUE), sum(out$mid_vs_us_force, na.rm = TRUE),
   sum(out$mid_vs_us_attack, na.rm = TRUE))

# ---------------------------------------------------------------- Q15: sanctions on the US
dy <- as.data.frame(read_dta(file.path(raw, "GSDB-R5_Dyadic.dta")))
dy <- unique(dy[dy$sanctioned_state_iso3 == "USA", c("sanctioning_state_iso3", "sanctioning_state", "year")])
dy$ccode <- suppressWarnings(countrycode(dy$sanctioning_state_iso3, "iso3c", "cown",
                                         custom_match = c(SRB = 345, CSK = 315, DDR = 265, SVU = 365, KSV = 347)))
dy$ccode[dy$sanctioning_state_iso3 == "DEU" & dy$year <= 1990] <- 260
dy$ccode[dy$sanctioning_state_iso3 == "YEM" & dy$year < 1990] <- 678
lg("GSDB-R5: %d sender-years against the US; senders without a COW state: %s", nrow(dy),
   paste(unique(dy$sanctioning_state[is.na(dy$ccode)]), collapse = "; "))
dy <- dy[!is.na(dy$ccode), ]
sk <- paste(dy$ccode, dy$year)
outside(sk, "Senders of sanctions on the US")
out$sanctions_on_us <- as.integer(key %in% sk)
lg("sanctions_on_us: %d state-years; senders by decade: %s", sum(out$sanctions_on_us),
   paste(sapply(seq(1950, 2020, 10), function(d) paste0(d, "s ", length(unique(out$ccode[out$sanctions_on_us == 1 & out$year %in% d:(d + 9)])))), collapse = ", "))

# ---------------------------------------------------------------- Q15: state cyber operations against the US
# EuRepoC Global Dataset of Cyber Incidents 1.3 (Zenodo 14965395, CC BY-NC 4.0),
# dyadic file: incidents with the US as receiver, initiator country, and the
# settled attribution's initiator category. State or state-affiliated
# initiators only. Collection grew sharply from 2022, so counts rise with
# visibility as well as activity.
cy_ <- read.csv(file.path(raw, "cyber/eurepoc_dyadic_dataset_0_1.csv"), stringsAsFactors = FALSE)
cy_ <- cy_[cy_$receiver_country == "United States", ]
cy_$year <- suppressWarnings(as.integer(substr(cy_$start_date, 1, 4)))
st <- cy_$initiator_category %in% c("State", "State affiliated actor")
lg("EuRepoC 1.3: %d incidents with the US as receiver; %d with a state or state-affiliated initiator; not attributed or unknown initiator: %d",
   length(unique(cy_$incident_id)), length(unique(cy_$incident_id[st])),
   length(unique(cy_$incident_id[cy_$initiator_country %in% c("Not attributed", "Unknown")])))
cs <- cy_[st & !cy_$initiator_country %in% c("Not attributed", "Unknown", "United States") & !is.na(cy_$year), ]
cs$ccode <- suppressWarnings(countrycode(cs$initiator_country, "country.name", "cown", warn = FALSE))
multi <- is.na(cs$ccode)                                           # joint attributions ("Russia, China"): one row per state
if (any(multi)) {
  sp <- do.call(rbind, lapply(which(multi), function(i) {
    p <- trimws(strsplit(cs$initiator_country[i], ",")[[1]])
    r <- cs[rep(i, length(p)), ]; r$ccode <- suppressWarnings(countrycode(p, "country.name", "cown", warn = FALSE)); r }))
  cs <- rbind(cs[!multi, ], sp)
}
lg("  Joint attributions split into states: %d incidents; still not mapped: %s", sum(multi),
   paste(unique(cs$initiator_country[is.na(cs$ccode)]), collapse = "; "))
cs <- cs[!is.na(cs$ccode), ]
ck_ <- paste(cs$ccode, cs$year)
outside(ck_, "Cyber initiators against the US")
ncy <- tapply(cs$incident_id, ck_, function(v) length(unique(v)))
out$cyber_vs_us_n <- ifelse(is.na(ncy[key]), 0L, as.integer(ncy[key]))
out$cyber_vs_us <- as.integer(out$cyber_vs_us_n > 0)
out$cyber_vs_us_state <- as.integer(key %in% ck_[cs$initiator_category == "State"])
for (v in c("cyber_vs_us_n", "cyber_vs_us", "cyber_vs_us_state")) out[[v]][out$year < 2000 | out$year > 2024] <- NA   # EuRepoC from 2000; 2025 partial
lg("cyber_vs_us: %d state-years, %d incidents (2000-2024); by state: %s", sum(out$cyber_vs_us, na.rm = TRUE), sum(out$cyber_vs_us_n, na.rm = TRUE),
   paste(names(sort(-tapply(out$cyber_vs_us_n, out$ccode, sum, na.rm = TRUE)))[1:6], collapse = ", "))

# ---------------------------------------------------------------- Q14: conflict without the US
a <- read.csv(file.path(raw, "ucdp_acd_261/UcdpPrioConflict_v26_1.csv"), stringsAsFactors = FALSE, colClasses = "character")
codes <- function(s) { x <- trimws(strsplit(s, ",", fixed = TRUE)[[1]]); x <- x[x != ""]; suppressWarnings(as.integer(x)) }
rows <- list()
for (i in seq_len(nrow(a))) {
  r <- a[i, ]
  parties <- unique(c(codes(r$gwno_a), codes(r$gwno_a_2nd), codes(r$gwno_b), codes(r$gwno_b_2nd)))
  if (2L %in% parties) next                                      # US a party: in the kinetic channel
  tg <- unique(c(codes(r$gwno_loc), codes(r$gwno_a), codes(r$gwno_b)))
  tg <- tg[!is.na(tg)]
  if (length(tg)) rows[[length(rows) + 1]] <- data.frame(gwno = tg, year = as.integer(r$year), intensity = as.integer(r$intensity_level))
}
cf <- do.call(rbind, rows)
cf$ccode <- suppressWarnings(countrycode(cf$gwno, "gwn", "cown"))
same <- is.na(cf$ccode) & paste(cf$gwno, cf$year) %in% paste(sys_$ccode, sys_$year)
cf$ccode[same] <- cf$gwno[same]
cf$ccode[cf$gwno == 678 & cf$year >= 1990] <- 679
cf$ccode[cf$gwno == 340] <- 345
cf <- cf[!is.na(cf$ccode) & cf$year >= 1950, ]
ck <- paste(cf$ccode, cf$year)
outside(ck, "Conflicts without the US")
mx <- tapply(cf$intensity, ck, max)
out$conflict_nonus_intensity <- ifelse(is.na(mx[key]), 0L, as.integer(mx[key]))
out$conflict_nonus <- as.integer(out$conflict_nonus_intensity > 0)
lg("conflict_nonus: %d state-years (%d with 1,000+ battle deaths)", sum(out$conflict_nonus), sum(out$conflict_nonus_intensity == 2))
# A conflict the US is not a party to can still be US pressure (support short
# of troops to a side): flagged, so it can be dropped as a post-treatment control.
px <- read.csv(file.path(outd, "proxy_country_year.csv"), stringsAsFactors = FALSE)
pb <- (px$proxy_vs_state %in% 1 | px$proxy_for_state %in% 1)[match(key, paste(px$ccode, px$year))]
out$conflict_nonus_us_backed <- ifelse(out$year < 1975 | out$year > 2017, NA_integer_, as.integer(out$conflict_nonus == 1 & pb))
lg("conflict_nonus_us_backed: %d of %d conflict state-years in 1975-2017 have US support short of troops to a side (ESD)",
   sum(out$conflict_nonus_us_backed, na.rm = TRUE), sum(out$conflict_nonus[out$year %in% 1975:2017]))

out <- out[order(out$ccode, out$year), c("ccode", "year", "mid_vs_us", "mid_vs_us_initiator", "mid_vs_us_force", "mid_vs_us_attack",
                                         "sanctions_on_us", "cyber_vs_us", "cyber_vs_us_n", "cyber_vs_us_state", "conflict_nonus", "conflict_nonus_intensity", "conflict_nonus_us_backed")]
write.csv(out, file.path(outd, "controls_country_year.csv"), row.names = FALSE, na = "")
