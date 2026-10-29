# EII v2 -- trade channel (BUILD_PROTOCOL.md, change log 2026-10-29; Sean,
# 16:38 "Unpause", 17:11 "Investigations are threats, dropping or non-sig
# findings are choices" and "applies to all as defined against a EU").
# Tier 1, US trade coercion that names a state. Anti-dumping and
# countervailing duties stay outside the index; statements and posts are not
# events.
#   trade_301_investigation  Section 301 investigations opened against the state
#                            (CRS R46604 Table A-2, 1975-2020; Federal Register
#                            from 2021): v2/build/s301_investigations.csv
#   trade_301_action         Section 301 actions and escalations (determinations
#                            of action, retaliation implemented, tariff increases),
#                            1995-2025 from the Federal Register; outcomes before
#                            1995 are not yet coded (blank)
#   trade_232_named          Section 232 measures naming the state (embargoes,
#                            country-specific rates, ended exemptions)
#   trade_ieepa_named        emergency (IEEPA) tariffs naming the state; for the
#                            2025 country-rate orders, rates above the 10% baseline
# Actions defined against the European Communities or EU count for every member
# that year (trade_via_eu flags them). Hand-coded actions with citations:
# v2/build/trade_actions.csv.
#
# Output: v2/output/trade_country_year.csv. Usage: Rscript v2/build/build_trade.R [repo_root]

suppressPackageStartupMessages(library(countrycode))
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "trade_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 trade channel build, %s; R %s; countrycode %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), getRversion(), packageVersion("countrycode"))

sys_ <- read.csv(file.path(root, "v2/sources/raw/System2024/system2024.csv"), stringsAsFactors = FALSE)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))
key <- paste(frame$ccode, frame$year)

# EC/EU members by year (COW codes; the UK left on 31 January 2020)
eu_join <- c(`220` = 1958, `260` = 1958, `255` = 1958, `325` = 1958, `210` = 1958, `211` = 1958, `212` = 1958,
             `200` = 1973, `205` = 1973, `390` = 1973, `350` = 1981, `230` = 1986, `235` = 1986,
             `305` = 1995, `375` = 1995, `380` = 1995, `352` = 2004, `316` = 2004, `366` = 2004, `310` = 2004,
             `367` = 2004, `368` = 2004, `338` = 2004, `290` = 2004, `317` = 2004, `349` = 2004,
             `355` = 2007, `360` = 2007, `344` = 2013)
eu_members <- function(y) {
  m <- as.integer(names(eu_join)[eu_join <= y])
  if (y >= 2020) m <- setdiff(m, 200L)
  intersect(m, frame$ccode[frame$year == y])                       # 260 to 1990, 255 from 1990, as in COW
}
is_eu <- function(e) e %in% c("European Communities", "European Union", "EU")
to_cow <- function(e, y) {
  cc <- suppressWarnings(countrycode(e, "country.name", "cown", warn = FALSE,
          custom_match = c(Korea = 732, `South Korea` = 732, Taiwan = 713, `Czech Republic` = 316, Serbia = 345,
                           `Union of Soviet Socialist Republics (Soviet Union)` = 365, `Myanmar (Burma)` = 775)))
  cc[e == "Germany" & y <= 1990] <- 260
  cc
}
expand <- function(d) {                                            # one row per state (EU actions to members)
  do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
    if (is_eu(d$economy[i])) return(data.frame(d[rep(i, length(eu_members(d$year[i]))), ], ccode = eu_members(d$year[i]), via_eu = TRUE))
    data.frame(d[i, ], ccode = to_cow(d$economy[i], d$year[i]), via_eu = FALSE)
  }))
}

inv <- read.csv(file.path(root, "v2/build/s301_investigations.csv"), stringsAsFactors = FALSE)
act <- read.csv(file.path(root, "v2/build/trade_actions.csv"), stringsAsFactors = FALSE)
lg("Section 301 investigations: %d case-economy rows (%d cases), %d-%d", nrow(inv), length(unique(inv$case)), min(inv$year), max(inv$year))
lg("Hand-coded actions: %s", paste(names(table(act$instrument)), table(act$instrument), collapse = ", "))
ie <- expand(inv); ae <- expand(act)
un <- unique(c(ie$economy[is.na(ie$ccode)], ae$economy[is.na(ae$ccode)]))
lg("Economies without a COW state (not assigned): %s", paste(un, collapse = "; "))
ie <- ie[!is.na(ie$ccode), ]; ae <- ae[!is.na(ae$ccode), ]
for (z in list(list(ie, "investigations"), list(ae, "actions"))) {
  k <- paste(z[[1]]$ccode, z[[1]]$year); o <- unique(k[!k %in% key])
  lg("%s: state-years outside the frame %d%s", z[[2]], length(o), if (length(o)) paste0(" (", paste(o, collapse = "; "), ")") else "")
}
cnt <- function(d) { t <- table(paste(d$ccode, d$year)); v <- as.integer(t[key]); v[is.na(v)] <- 0L; v }
out <- frame
out$trade_301_investigation <- cnt(ie)
out$trade_301_action <- cnt(ae[ae$instrument == "s301_action", ])
out$trade_232_named <- cnt(ae[ae$instrument == "s232_named", ])
out$trade_ieepa_named <- cnt(ae[ae$instrument == "ieepa_named", ])
out$trade_via_eu <- as.integer(key %in% c(paste(ie$ccode, ie$year)[ie$via_eu], paste(ae$ccode, ae$year)[ae$via_eu]))
out$trade_301_investigation[out$year < 1975] <- NA               # Section 301 begins with the Trade Act of 1974
out$trade_301_action[out$year < 1995] <- NA                      # outcomes before 1995 not yet coded
out$trade_via_eu[out$year < 1975] <- NA
for (v in c("trade_301_investigation", "trade_301_action", "trade_232_named", "trade_ieepa_named", "trade_via_eu"))
  lg("%s: %d state-years, %d events; by decade %s", v, sum(out[[v]] > 0, na.rm = TRUE), sum(out[[v]], na.rm = TRUE),
     paste(sapply(seq(1970, 2020, 10), function(d) paste0(d, "s ", sum(out[[v]][out$year %in% d:(d + 9)] > 0, na.rm = TRUE))), collapse = ", "))
write.csv(out[order(out$ccode, out$year), ], file.path(outd, "trade_country_year.csv"), row.names = FALSE, na = "")
