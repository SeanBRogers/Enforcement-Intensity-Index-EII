# EII v2 -- covert and proxy channel, part 2: US-backed regime change attempts,
# 1947-1989 (BUILD_PROTOCOL.md, change log 2026-10-29).
# Source: O'Rourke, Covert Regime Change: America's Secret Cold War (Cornell
# University Press, 2018), Tables 1.1 and 5.1-5.3, hand-entered with the
# table of origin in v2/build/orourke_cases.csv (64 covert attempts, 2 covert
# plans aborted before implementation, 6 overt operations). Where Table 1.1 and
# the case tables give different years (two cases), the case table is used.
#
# Output: v2/output/regime_change_country_year.csv, on the panel frame; blank
# from 1990 (the source ends in 1989).
# Usage: Rscript v2/build/build_regime_change.R [repo_root]

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "regime_change_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 regime change build, %s; R %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), getRversion())

cs <- read.csv(file.path(root, "v2/build/orourke_cases.csv"), stringsAsFactors = FALSE)
stopifnot(sum(cs$mode == "covert" & cs$achieved != "aborted") == 64, sum(cs$mode == "overt") == 6,
          sum(cs$mode == "covert" & cs$achieved == "yes") == 25)
lg("Cases: %d covert attempts (%d achieved their objective), %d covert plans aborted, %d overt operations",
   sum(cs$mode == "covert" & cs$achieved != "aborted"), sum(cs$mode == "covert" & cs$achieved == "yes"),
   sum(cs$achieved == "aborted"), sum(cs$mode == "overt"))
lg("Not assigned (no COW state): %s", paste(cs$target[is.na(cs$ccode)], collapse = "; "))

sys_ <- read.csv(file.path(root, "v2/sources/raw/System2024/system2024.csv"), stringsAsFactors = FALSE)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))

cs <- cs[!is.na(cs$ccode), ]
cy <- do.call(rbind, lapply(seq_len(nrow(cs)), function(i)
  data.frame(case = cs$case[i], ccode = cs$ccode[i], year = cs$start[i]:cs$end[i])))
cy <- merge(cy, cs[, c("case", "mode", "type", "tactics", "achieved")], by = "case")
cy <- cy[cy$year >= 1950, ]
inf <- paste(cy$ccode, cy$year) %in% paste(frame$ccode, frame$year)
lg("Case-years from 1950 outside the frame (state not a system member): %d (%s)", sum(!inf),
   paste(unique(paste0(cy$ccode[!inf], " ", cy$year[!inf])), collapse = ", "))
cy <- cy[inf, ]

key <- paste(frame$ccode, frame$year)
flag <- function(rows) as.integer(key %in% paste(cy$ccode[rows], cy$year[rows]))
imp <- cy$mode == "covert" & cy$achieved != "aborted"
out <- frame
out$rc_covert <- flag(imp)
out$rc_covert_planned <- as.integer(flag(cy$achieved == "aborted") == 1 & out$rc_covert == 0)
tp <- tapply(cy$type[imp], paste(cy$ccode, cy$year)[imp], function(v) paste(sort(unique(v)), collapse = "; "))
out$rc_covert_type <- ifelse(is.na(tp[key]), "", tp[key])
out$rc_covert_leader_removal <- flag(imp & grepl("Coup|ssassination", cy$tactics))
out$rc_covert_succeeded <- flag(imp & cy$achieved == "yes")
out$rc_overt <- flag(cy$mode == "overt")
vars <- c("rc_covert", "rc_covert_planned", "rc_covert_type", "rc_covert_leader_removal", "rc_covert_succeeded", "rc_overt")
for (v in vars) out[[v]][out$year > 1989] <- NA                 # source ends in 1989
for (v in vars[vars != "rc_covert_type"])
  lg("%s: %d state-years (1950-1989), %d states", v, sum(out[[v]], na.rm = TRUE), length(unique(out$ccode[out[[v]] %in% 1])))
write.csv(out[order(out$ccode, out$year), ], file.path(outd, "regime_change_country_year.csv"), row.names = FALSE, na = "")
