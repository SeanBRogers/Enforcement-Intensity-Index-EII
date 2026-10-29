# EII v2 -- financial channel, 1994: estimated additions (Sean, 2026-10-29).
#
# OFAC's 1994 change file reports most designations as counts in prose (e.g.,
# "General Notice No. 3 ... naming 523 individual officers"), with the names
# in separate files that are not in the archive. The October 1994 entries list
# every Haiti listing when the Haiti program ended, which lets the prose counts
# be checked and the one unstated count (the residents named under the
# 21 June 1994 executive order) be derived.
#
# Output: v2/output/sdn_1994_estimate.csv (one row per program country:
# point, low and high counts, and the basis of each).
# Usage: Rscript v2/build/estimate_sdn_1994.R [repo_root]

# The OFAC texts and patterns are UTF-8: run in a UTF-8 locale (R 4.2+ on Windows already is).
if (!isTRUE(l10n_info()[["UTF-8"]])) invisible(Sys.setlocale("LC_ALL", "C.UTF-8"))
if (!isTRUE(l10n_info()[["UTF-8"]])) stop("A UTF-8 locale is required (set LC_ALL=C.UTF-8).")
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
f94 <- file.path(root, "v2/sources/raw/ofac_sdn/sdnew94.txt")
x <- iconv(readLines(f94, warn = FALSE), "latin1", "UTF-8")
x <- gsub("[\r\001-\010\013-\037\177]", "", x)

# ------------------------------------------------- 1. Itemized October 1994 lists
# 10/05/94: residents' listings (marked "**") deleted; 10/16/94: every remaining
# [HAITI] listing deleted when sanctions were lifted.
blk <- function(from, to) { a <- grep(from, x)[1]; b <- grep(to, x)[1] - 1; x[a:b] }
entries <- function(v) {
  out <- character(); cur <- ""
  for (s in trimws(v)) {
    if (!nzchar(s)) next
    cur <- if (nzchar(cur)) paste(cur, s) else s
    if (grepl("\\[HAITI\\]\\**$", cur)) { out <- c(out, cur); cur <- "" }
  }
  out
}
oct5_all <- blk("^10/05/94:", "^10/16/94")
r1 <- grep("^THE FOLLOWING NAMES HAVE BEEN REMOVED", oct5_all); r2 <- grep("^THE FOLLOWING NAMES HAVE BEEN CHANGED", oct5_all)
oct5  <- entries(oct5_all[r1:(r2 - 1)])               # the removal section only
redesignated <- 14                                     # 10/05/94: "Fourteen individuals previously listed because of their
                                                       # residency status, have been redesignated" (still listed on 10/16)
oct16 <- entries(blk("^10/16/94", "^10/27/94:"))

norm <- function(s) toupper(gsub("[^A-Za-z0-9]", "", s))
names_of <- function(s) {                              # primary name plus a.k.a. names
  p <- regexpr("\\((a|f|n)\\.k\\.a\\.", s)
  if (p < 0) return(norm(sub("[;(].*$", "", s)))
  inner <- sub("\\).*$", "", substr(s, p + 1, nchar(s)))
  nm <- trimws(gsub("^(a|f|n)\\.k\\.a\\.?\\s*", "", strsplit(inner, ";|, a\\.k\\.a")[[1]]))
  unique(norm(c(substr(s, 1, p - 1), nm)))
}
distinct <- function(v) {                              # entries sharing any name are one listing
  if (!length(v)) return(0L)
  nm <- lapply(v, names_of); pr <- seq_along(nm); idx <- new.env()
  f <- function(i) { while (pr[i] != i) i <- pr[i]; i }
  for (i in seq_along(nm)) for (k in nm[[i]][nzchar(nm[[i]])]) {
    j <- idx[[k]]
    if (!is.null(j)) { a <- f(i); b <- f(j); if (a != b) pr[a] <- b } else assign(k, i, envir = idx)
  }
  length(unique(vapply(seq_along(nm), f, 1L)))
}
dstar <- function(v) grepl("\\]\\*\\*$", v)
sstar <- function(v) grepl("\\][*]$", v)
indiv <- function(v) grepl("\\(individual\\)", v)

res_all  <- distinct(oct5[dstar(oct5)])                 # residents category ("**"): exists only from 21 June 1994
res_ent  <- distinct(oct5[dstar(oct5) & !indiv(oct5)])
blk16    <- distinct(oct16[sstar(oct16)])               # "Blocked Individuals of Haiti" ("*") still listed in October
blk5     <- distinct(oct5[sstar(oct5)])                 # "*" listings removed on 10/05/94
gov16    <- distinct(oct16[!sstar(oct16) & !dstar(oct16)])
cat(sprintf("October 1994 Haiti listings (distinct): residents ** %d (of which entities %d); blocked individuals * %d still listed + %d removed 10/05; unmarked (government entities) %d\n",
            res_all, res_ent, blk16, blk5, gov16))

# ------------------------------------------------- 2. Counts OFAC states in 1994 (exact)
# Haiti, "Blocked Individuals/Entities of Haiti" general notices:
gn <- c(GN3 = 523, GN4 = 27, GN5 = 35, GN6 = 12, GN8 = 16 + 1, GN10 = 47 + 3)
gn9 <- 90 + 24 + 3      # 08/18/94: 90 entities, 24 individuals ("Blocked Persons of Haiti") + 3 entities
# The residents' list holds about 90 entities, matching General Notice 9's 90
# entities, so GN9 is read as part of the "**" residents category; GN8 and GN10
# are read as "*" blocked individuals and entities (alternative reading in the bounds).
res_total <- res_all + redesignated                    # every residents' listing of 1994
residents_named <- res_total - gn9
haiti_point <- sum(gn) + res_total                     # all "*" notices of 1994 + the whole "**" category
haiti_lo    <- sum(gn[c("GN3","GN4","GN5","GN6")]) + res_total # GN8 and GN10 already inside "**"
haiti_hi    <- haiti_point + blk5                      # the "*" listings removed on 10/05 were also 1994 listings
# Non-Haiti additions stated in the 1994 file (persons and entities, exact):
other <- data.frame(
  ccode = c(620, 645, 345),
  program = c("Libya", "Iraq", "Yugoslavia (FRY S&M)"),
  count = c(14 + 11 + 1 + 3 + 2 + 1, 1, 3),
  basis = c("05/04 5 entities + 9 individuals; 06/21 4 companies + 7 individuals; 07/22 1 bank; 07/25 3 individuals; 09/15 2 individuals; 10/05 1 company",
            "05/04 IRAQ-JORDAN LAND TRANSPORT COMPANY", "05/04 three Cyprus companies"))
est <- rbind(
  data.frame(ccode = 41, program = "Haiti", point = haiti_point, low = haiti_lo, high = haiti_hi,
             basis = sprintf("Stated notices GN3-6, 8, 10 (%d) + residents' category (%d distinct listings removed 10/05/94 + %d redesignated; incl. GN9 %d and %d named under the 21 June order). Low: GN8 and GN10 counted inside the residents' category. High: plus %d blocked individuals removed 10/05/94 whose listing date is not stated.",
                             sum(gn), res_all, redesignated, gn9, residents_named, blk5)),
  data.frame(ccode = other$ccode, program = other$program, point = other$count, low = other$count,
             high = other$count, basis = other$basis))
est$year <- 1994L
cat(sprintf("Haiti 1994 additions: %d (bounds %d-%d); implied listings from before 1994 still listed in October: about %d blocked individuals + %d government entities\n",
            haiti_point, haiti_lo, haiti_hi, blk16 - redesignated - sum(gn), gov16))
cat(sprintf("All 1994 additions: %d (bounds %d-%d)\n", sum(est$point), sum(est$low), sum(est$high)))
write.csv(est[, c("year", "ccode", "program", "point", "low", "high", "basis")],
          file.path(root, "v2/output/sdn_1994_estimate.csv"), row.names = FALSE)
