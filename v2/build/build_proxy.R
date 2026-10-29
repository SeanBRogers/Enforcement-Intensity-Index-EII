# EII v2 -- covert and proxy channel, part 1: US support to warring parties
# (BUILD_PROTOCOL.md, change log 2026-10-29: "not recorded doesn't mean
# non-existent"). Source: UCDP External Support Dataset (ESD) 18.1,
# triad-year version, 1975-2017.
#
# A US-supported triad (supporter = Government of the United States) is
# attributed to a state as:
#   proxy_vs_state  the US supports a side fighting this state's government
#                   (rebels against it, or another government at war with it)
#   proxy_for_state the US supports this state's government in its war
# Only support short of US troops counts here (weapons, materiel and
# logistics, training, funding, intelligence, access to infrastructure or
# territory, troop presence below the warring-party threshold, other or
# unknown). US troops as a warring party are already in the kinetic channel.
# Confirmed and alleged support are kept apart (evidence grade).
#
# Output: v2/output/proxy_country_year.csv. Usage: Rscript v2/build/build_proxy.R [repo_root]

suppressMessages({ library(haven); library(countrycode) })
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw/ucdp_esd")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "proxy_log.txt"); cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 proxy channel build, %s; R %s; haven %s; countrycode %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
   getRversion(), packageVersion("haven"), packageVersion("countrycode"))

td <- tempfile(); unzip(file.path(raw, "ucdp-esd-ty-181.zip"), exdir = td)
t <- as.data.frame(read_dta(list.files(td, pattern = "ucdp-esd-ty-181\\.dta$", recursive = TRUE, full.names = TRUE)[1]))
u <- t[t$ext_name == "Government of United States of America" & t$ext_sup == 1, ]
lg("ESD 18.1 triad-years: %d; with US government support: %d (%d-%d); alleged only: %d",
   nrow(t), nrow(u), min(u$year), max(u$year), sum(u$ext_alleged == 1))

short_of_troops <- c("ext_p", "ext_y", "ext_w", "ext_m", "ext_t", "ext_f", "ext_i", "ext_l", "ext_o", "ext_u")
u$types <- rowSums(u[, short_of_troops] == 1, na.rm = TRUE)
dropped <- sum(u$types == 0)
lg("Triad-years with US troop support only (already in the kinetic channel): %d, not counted here", dropped)
u <- u[u$types > 0, ]

# --- attribute each triad to target and partner states (GW codes)
rows <- list()
add <- function(gw, year, kind, types, alleged, desc) rows[[length(rows) + 1]] <<-
  data.frame(gwno = gw, year = year, kind = kind, types = types, alleged = alleged, desc = desc)
for (i in seq_len(nrow(u))) {
  r <- u[i, ]
  if (r$civil == 1) {                                    # intrastate: the government is side A (gwno_a)
    if (r$actor_nonstate == 1) add(r$gwno_a, r$year, "vs_state", r$types, r$ext_alleged, paste(r$actor_name, "vs", r$oppo_name))
    else                       add(r$gwno_a, r$year, "for_state", r$types, r$ext_alleged, paste(r$actor_name, "vs", r$oppo_name))
  } else {                                               # interstate: find which government the US supports
    a_is_actor <- r$actor_name == paste("Government of", r$country_a)
    sup <- if (a_is_actor) r$gwno_a else r$gwno_b
    opp <- if (a_is_actor) r$gwno_b else r$gwno_a
    add(opp, r$year, "vs_state", r$types, r$ext_alleged, paste(r$actor_name, "vs", r$oppo_name))
    add(sup, r$year, "for_state", r$types, r$ext_alleged, paste(r$actor_name, "vs", r$oppo_name))
  }
}
k <- do.call(rbind, rows)
k <- k[!is.na(k$gwno), ]

# --- GW to COW, with the kinetic channel's rules
sys_ <- read.csv(file.path(root, "v2/sources/raw/System2024/system2024.csv"), stringsAsFactors = FALSE)   # the panel frame (D1)
frame <- sys_[sys_$year >= 1950 & sys_$year <= 2024 & sys_$ccode != 2, c("ccode", "year")]
frame <- rbind(frame, transform(frame[frame$year == 2024, ], year = 2025L))
k$ccode <- suppressWarnings(countrycode(k$gwno, "gwn", "cown"))
same <- is.na(k$ccode) & paste(k$gwno, k$year) %in% paste(sys_$ccode, sys_$year)
k$ccode[same] <- k$gwno[same]
k$ccode[k$gwno == 678 & k$year >= 1990] <- 679
k$ccode[k$gwno == 340] <- 345
lg("GW codes without a COW code: %d", sum(is.na(k$ccode)))
off <- unique(paste(k$ccode, k$year)[!paste(k$ccode, k$year) %in% paste(frame$ccode, frame$year)])
lg("State-years outside the frame: %d%s", length(off), if (length(off)) paste0(" (", paste(off, collapse = "; "), ")") else "")
write.csv(k[order(k$ccode, k$year, k$kind), c("ccode", "year", "kind", "types", "alleged", "desc")],
          file.path(outd, "proxy_triads.csv"), row.names = FALSE)

agg <- function(kind, alleged) {
  z <- k[k$kind == kind & k$alleged == alleged, ]
  if (!nrow(z)) return(data.frame(ccode = integer(), year = integer(), v = integer(), n = integer()))
  a <- aggregate(list(v = z$types), list(ccode = z$ccode, year = z$year), max)
  a$n <- 1L; a
}
out <- frame
for (kind in c("vs_state", "for_state")) {
  c0 <- agg(kind, 0); c1 <- agg(kind, 1)
  v  <- paste0("proxy_", kind)
  out[[v]]                      <- as.integer(paste(out$ccode, out$year) %in% paste(c0$ccode, c0$year))
  out[[paste0(v, "_types")]]    <- c0$v[match(paste(out$ccode, out$year), paste(c0$ccode, c0$year))]
  out[[paste0(v, "_types")]][is.na(out[[paste0(v, "_types")]])] <- 0L
  out[[paste0(v, "_alleged")]]  <- as.integer(paste(out$ccode, out$year) %in% paste(c1$ccode, c1$year) & out[[v]] == 0L)
  for (w in c(v, paste0(v, "_types"), paste0(v, "_alleged"))) out[[w]][out$year < 1975 | out$year > 2017] <- NA   # outside ESD coverage
  lg("%s: %d state-years confirmed, %d alleged only (1975-2017)", v, sum(out[[v]], na.rm = TRUE), sum(out[[paste0(v, "_alleged")]], na.rm = TRUE))
}
write.csv(out[order(out$ccode, out$year), ], file.path(outd, "proxy_country_year.csv"), row.names = FALSE, na = "")
