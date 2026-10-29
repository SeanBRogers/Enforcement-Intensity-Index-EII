# EII v2 — penalties channel: OFAC civil penalties and settlements, 2003–2025.
# Governed by BUILD_PROTOCOL.md (Q8, Q9, Q10; change log 2026-10-27).
#
# Unit: one OFAC civil penalty, settlement or finding of violation, counted with
# OFAC's own number per entry (an "Individuals" entry can aggregate several).
# Year: the date OFAC published the entry (Q10).
# Attribution (Q8, Sean 2026-10-27): each entry is attributed twice.
#   program_country  = target of each sanctions program the entry names (feeds the index)
#   location_country = where the penalized party is located (second attribution)
# Non-country programs (terrorism, narcotics, nonproliferation, ...) have no program country.
#
# Inputs:  v2/sources/raw/ofac_enforcement/pages/ofacYYYY.html  (OFAC by-year pages)
#          v2/sources/raw/ofac_enforcement/txt/<media id>.txt   (pdftotext -layout of each document)
#          v2/build/ofac_program_map.csv
# Outputs: v2/output/penalties_entries.csv, v2/output/penalties_country_year.csv,
#          v2/output/penalties_log.txt

# The OFAC texts and patterns are UTF-8: run in a UTF-8 locale (R 4.2+ on Windows already is).
if (!isTRUE(l10n_info()[["UTF-8"]])) invisible(Sys.setlocale("LC_ALL", "C.UTF-8"))
if (!isTRUE(l10n_info()[["UTF-8"]])) stop("A UTF-8 locale is required (set LC_ALL=C.UTF-8).")
suppressPackageStartupMessages(library(countrycode))
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else getwd()
src  <- file.path(root, "v2", "sources", "raw", "ofac_enforcement")
out  <- file.path(root, "v2", "output"); dir.create(out, showWarnings = FALSE)
logf <- file.path(out, "penalties_log.txt"); cat("EII v2 penalties build\n", file = logf)
lg <- function(...) { s <- paste0(...); cat(s, "\n"); cat(s, "\n", file = logf, append = TRUE) }
lg("Run: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), " | ", R.version.string, " | ",
   tryCatch(system2("pdftotext", "-v", stdout = TRUE, stderr = TRUE)[1], error = function(e) "pdftotext version unknown"))

# ------------------------------------------------------------ 1. Index from OFAC's year pages
strip <- function(x) { x <- gsub("<[^>]+>", "", x); x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&nbsp;|&#160;", " ", x); x <- gsub("&#039;|&rsquo;", "'", x); x <- iconv(x, "UTF-8", "UTF-8", sub = " "); trimws(gsub("\\s+", " ", x)) }
num <- function(x) as.numeric(gsub("[^0-9.]", "", x))
rows <- list()
for (y in 2003:2025) {
  h <- paste(readLines(file.path(src, "pages", sprintf("ofac%d.html", y)), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  tab <- regmatches(h, regexpr("<table.*?</table>", h, perl = TRUE))
  trs <- regmatches(tab, gregexpr("<tr.*?</tr>", tab, perl = TRUE))[[1]][-1]
  for (tr in trs) {
    cells <- regmatches(tr, gregexpr("<t[hd].*?</t[hd]>", tr, perl = TRUE))[[1]]
    if (length(cells) < 4) next
    link <- regmatches(tr, regexpr('href="[^"]+"', tr))
    rows[[length(rows) + 1]] <- data.frame(page_year = y, date = strip(cells[1]), name = strip(cells[2]),
      n = num(strip(cells[3])), usd = num(strip(cells[4])),
      media = if (length(link)) sub('.*/media/([0-9]+)/.*', "\\1", link) else NA_character_)
  }
}
ix <- do.call(rbind, rows)
tot <- ix[grepl("^Year to date", ix$date), ]
ix <- ix[!grepl("^Year to date", ix$date), ]
ix$year <- as.integer(sub("^.*?\\d{1,2}/\\d{1,2}/(\\d{4}).*$", "\\1", ix$date, perl = TRUE))   # first date; drops "a"/"b" and "(Revised ...)" suffixes
ix$n_blank <- is.na(ix$n); ix$n[ix$n_blank] <- 1                  # a blank count is one action (reconciles to OFAC's totals)
ix$usd_blank <- is.na(ix$usd); ix$usd[ix$usd_blank] <- 0          # blank amount: finding of violation without a penalty
lg("OFAC index: ", nrow(ix), " entries, ", length(unique(ix$media)), " documents, 2003-2025; ",
   nrow(tot), " year-total rows set aside")
chk <- merge(aggregate(cbind(n, usd) ~ page_year, data = ix, FUN = sum),
             data.frame(page_year = 2003:2025, n_off = tot$n, usd_off = tot$usd), by = "page_year")
chk$n_ok <- chk$n == chk$n_off; chk$usd_ok <- abs(chk$usd - chk$usd_off) < 1
lg("Check against OFAC's own year totals: count matches in ", sum(chk$n_ok), "/23 years; dollars in ",
   sum(chk$usd_ok), "/23")
if (any(!chk$n_ok | !chk$usd_ok)) for (i in which(!chk$n_ok | !chk$usd_ok))
  lg("  ", chk$page_year[i], ": entries n=", chk$n[i], " vs OFAC ", chk$n_off[i], "; $", format(chk$usd[i], big.mark = ","),
     " vs OFAC $", format(chk$usd_off[i], big.mark = ","))
lg("Blank count cells set to 1: ", sum(ix$n_blank), "; blank amount cells (findings of violation, $0): ", sum(ix$usd_blank))
lg("Entries whose date year differs from their page year: ", sum(ix$year != ix$page_year))

# ------------------------------------------------------------ 2. Program dictionary
pm <- read.csv(file.path(root, "v2", "build", "ofac_program_map.csv"), stringsAsFactors = FALSE)
# Short program names used in the 2003-2011 tables' "Sanctions Program" column.
short <- data.frame(pattern = c("\\bCuba\\b", "\\bIran\\b", "\\bSudan\\b", "\\bKosovo\\b", "\\bFRY\\b|Yugoslavia|Milosevic",
                                "\\bLibya\\b", "\\bIraq\\b", "\\bSyria\\b", "North Korea", "\\bBurma\\b", "\\bZimbabwe\\b",
                                "\\bLiberia\\b", "\\bBelarus\\b", "Sierra Leone", "\\bUNITA\\b|\\bAngola\\b", "\\bTaliban\\b",
                                "Western Balkans", "\\bSDNT\\b|Narcotics", "Kingpin", "\\bSDGT\\b|\\bSDT\\b|Terroris",
                                "\\bNPWMD\\b|Weapons of Mass|Non-?proliferation", "Rough Diamond", "C.te d.Ivoire"),
                    program = c("Cuba", "Iran", "Sudan", "Yugoslavia/Serbia (Kosovo)", "Yugoslavia/Serbia", "Libya", "Iraq",
                                "Syria", "North Korea", "Burma", "Zimbabwe", "Liberia", "Belarus", "Sierra Leone", "Angola (UNITA)",
                                "Afghanistan (Taliban)", "Western Balkans", "Narcotics (SDNT)", "Narcotics (Kingpin)", "Terrorism",
                                "Nonproliferation (WMD)", "Rough diamonds", "Cote d'Ivoire"),
                    program_country_ccode = c(40, 630, 625, 345, 345, 620, 645, 652, 731, 775, 552, 450, 370, 451, 540, 700,
                                              NA, NA, NA, NA, NA, NA, 437), stringsAsFactors = FALSE)
find_programs <- function(txt, dict, last = FALSE) {
  # first = position of the first match (narrative); last = position of the last match (table rows,
  # where the program column sits on the amount line, nearest the end of the block)
  hits <- lapply(seq_len(nrow(dict)), function(i) {
    p <- gregexpr(dict$pattern[i], txt, perl = TRUE)[[1]]
    if (p[1] > 0) data.frame(pos = as.integer(if (last) max(p) else p[1]), program = dict$program[i],
                             ccode = dict$program_country_ccode[i]) else NULL })
  h <- do.call(rbind, hits); if (is.null(h)) return(NULL)
  h <- h[order(h$pos, decreasing = last), ]; h[!duplicated(h$program), ]
}

# CFR part numbers (31 C.F.R. chapter V) and the two executive orders cited in the 2003 tables.
cfr <- read.csv(file.path(root, "v2", "build", "ofac_cfr_parts.csv"), stringsAsFactors = FALSE)
cfr_lookup <- function(part, year) {
  r <- cfr[cfr$part == part & cfr$from_year <= year & cfr$to_year >= year, ]
  if (!nrow(r)) return(NULL); r[1, ]
}
find_cfr <- function(txt, year, table_row = FALSE) {
  pat <- if (table_row) "(?<![0-9$.,])(5\\d\\d|13067|13088|13121)(?![0-9,.])" else
    "(?:31\\s*C\\.?\\s*F\\.?\\s*R\\.?\\s*(?:[Pp]art|pt\\.?|§+)\\s*|Executive Order\\s*|E\\.O\\.\\s*)(5\\d\\d|13067|13088|13121)(?![0-9])"
  m <- gregexpr(pat, txt, perl = TRUE)[[1]]
  if (m[1] == -1) return(NULL)
  st <- attr(m, "capture.start")[, 1]; ln <- attr(m, "capture.length")[, 1]
  parts <- as.integer(substring(txt, st, st + ln - 1))
  h <- do.call(rbind, lapply(seq_along(parts), function(k) { r <- cfr_lookup(parts[k], year)
    if (is.null(r)) NULL else data.frame(pos = as.integer(m[k]), program = r$program, ccode = r$program_country_ccode) }))
  if (is.null(h)) return(NULL)
  h <- h[order(h$pos, decreasing = table_row), ]; h[!duplicated(h$program), ]
}

find_cfr_all <- function(txt, year) {                       # every CFR/EO token in a table row, all positions
  m <- gregexpr("(?<![0-9$.,])(5\\d\\d|13067|13088|13121)(?![0-9,.])", txt, perl = TRUE)[[1]]
  if (m[1] == -1) return(NULL)
  st <- attr(m, "capture.start")[, 1]; ln <- attr(m, "capture.length")[, 1]
  parts <- as.integer(substring(txt, st, st + ln - 1))
  do.call(rbind, lapply(seq_along(parts), function(k) { r <- cfr_lookup(parts[k], year)
    if (is.null(r)) NULL else data.frame(pos = as.integer(m[k]), program = r$program, ccode = r$program_country_ccode) }))
}

# ------------------------------------------------------------ 3. Location dictionary
us_states <- c(state.name, "District of Columbia", "Puerto Rico")
loc_of <- function(token) {
  token <- trimws(token)
  if (!nzchar(token)) return(NA_integer_)
  if (token %in% c(us_states, state.abb, "D.C.", "DC", "U.S.", "United States")) return(2L)
  cc <- suppressWarnings(countrycode(token, "country.name", "cown"))
  if (is.na(cc)) cc <- suppressWarnings(countrycode(token, "country.name", "cown", custom_match = c("Dubai" = 696, "Hong Kong" = NA)))
  as.integer(cc)
}
find_location <- function(txt) {
  pats <- c("based in ([A-Z][A-Za-z.' ]+?)[,.;)]", "headquartered in ([A-Z][A-Za-z.' ]+?)[,.;)]",
            "located in ([A-Z][A-Za-z.' ]+?)[,.;)]", "\\b([A-Z][A-Za-z]+(?: [A-Z][a-z]+)?)-based\\b",
            ", of [A-Z][A-Za-z.' ]+, ([A-Z][A-Za-z.' ]+?)[,.;) ]", "\\bof [A-Z][A-Za-z.' ]+, ([A-Z][A-Za-z.' ]+?)\\s*\\(")
  for (p in pats) {
    m <- regmatches(txt, regexec(p, txt, perl = TRUE))[[1]]
    if (length(m) == 2) { cc <- loc_of(m[2]); if (!is.na(cc)) return(list(cc = cc, how = paste0("phrase: ", m[1]))) }
  }
  if (grepl(",\\s*[A-Z]{2}\\s+\\d{5}", txt, perl = TRUE)) return(list(cc = 2L, how = "US state and ZIP in address"))
  list(cc = NA_integer_, how = "not found")
}

# ------------------------------------------------------------ 4. Attribute each entry
norm <- function(x) gsub("\\s+", " ", x)
txts <- list()
gettxt <- function(id) { if (is.null(txts[[id]])) txts[[id]] <<- norm(iconv(paste(readLines(file.path(src, "txt", paste0(id, ".txt")), warn = FALSE, encoding = "UTF-8"), collapse = " "), "UTF-8", "UTF-8", sub = " ")); txts[[id]] }
amt_pat <- function(u) { w <- formatC(floor(u), format = "d", big.mark = ","); paste0("\\$\\s*", gsub(",", ",", w, fixed = TRUE), "(\\.\\d{2})?(?!,?[0-9])") }
# Multi-entry narrative reports (2004-2011 monthly releases): one block per entry, in index order.
# Each entry is anchored by its amount, searched after the previous entry's; its block starts at its
# heading (its name, or for individuals the nearest capitalized "Individual" before the amount) and
# ends where the next entry's block starts.
istab <- function(t) grepl("Name of Entity|CFR Part, or", t, perl = TRUE)
seg_start <- rep(NA_integer_, nrow(ix)); seg_end <- seg_start
for (m in unique(ix$media)) {
  rows_m <- which(ix$media == m & ix$n > 0); if (length(rows_m) < 2) next
  t <- gettxt(m); if (istab(t)) next
  anchor <- 0L; starts <- rep(NA_integer_, length(rows_m))
  for (j in seq_along(rows_m)) {
    e <- ix[rows_m[j], ]; seg <- substr(t, anchor + 1, nchar(t))
    a <- if (e$usd > 0) as.integer(regexpr(amt_pat(e$usd), seg, perl = TRUE)) else -1L
    indiv <- grepl("Individual", e$name, ignore.case = TRUE); st <- -1L
    if (!indiv) { q <- as.integer(regexpr(substr(norm(e$name), 1, 15), seg, fixed = TRUE)); if (q > 0 && (a < 0 || q <= a)) st <- q }
    if (st < 0 && a > 0) {
      # heading = the sentence holding the last title-case heading verb before the amount
      pre <- substr(seg, 1, a)
      h <- gregexpr("\\b(Settles?|Remits?|Agrees?|Assessed|Penalized|Receives?|Issues?)\\b", pre, perl = TRUE)[[1]]
      cut <- if (h[1] > 0) max(h) - 1L else a - 1L          # no heading (individuals): the sentence holding the amount
      b <- gregexpr("[.?!:] ", substr(pre, 1, cut), perl = TRUE)[[1]]
      st <- if (b[1] > 0) max(b) + 2L else 1L
    }
    if (st < 0) next
    starts[j] <- anchor + st; anchor <- anchor + (if (a > 0) a else st)
  }
  for (j in seq_along(rows_m)) { if (is.na(starts[j])) next
    later <- starts[seq_along(starts) > j]; later <- later[!is.na(later)]
    seg_start[rows_m[j]] <- starts[j]; seg_end[rows_m[j]] <- if (length(later)) min(later) - 1L else nchar(t) }
}
lg("Multi-entry narrative reports: ", sum(!is.na(seg_start)), " entries placed in their own block; ",
   sum(is.na(seg_start) & ix$media %in% ix$media[duplicated(ix$media)] & ix$n > 0 &
       !sapply(ix$media, function(m) istab(gettxt(m)))), " could not be placed")

res <- list(); prog_rows <- list()
for (i in seq_len(nrow(ix))) {
  e <- ix[i, ]; t <- gettxt(e$media)
  tabular <- grepl("Name of Entity|CFR Part, or", t, perl = TRUE)          # the 2003-2011 tables
  if (tabular) {
    am <- gregexpr(amt_pat(e$usd), t, perl = TRUE)[[1]]
    if (am[1] == -1) { block <- NA_character_; how <- "amount not found in table" } else {
      allam <- gregexpr("\\$\\s*[0-9][0-9,]*(\\.\\d{2})?", t, perl = TRUE)[[1]]
      first_word <- regmatches(e$name, regexpr("[A-Za-z][A-Za-z&.-]{3,}", e$name))
      pick <- am[1]
      if (length(am) > 1 && length(first_word)) for (cand in am) {        # same amount twice: take the row naming this entity
        pv <- allam[allam < cand]; s0 <- if (length(pv)) max(pv) + 1 else 1
        if (grepl(first_word, substr(t, s0, cand), fixed = TRUE)) { pick <- cand; break } }
      am <- pick; p <- pick; prev <- allam[allam < p]; start <- if (length(prev)) max(prev) + 1 else 1
      amt_off <- p - start + 1; block <- substr(t, start, p + 80); how <- "table row located by amount"
    }
    progs <- NULL
    if (!is.na(block)) {
      # every program mention in the row's span; keep the one closest to the row's amount (either side)
      allhits <- do.call(rbind, c(lapply(seq_len(nrow(short)), function(k) { g <- gregexpr(short$pattern[k], block, perl = TRUE)[[1]]
                   if (g[1] > 0) data.frame(pos = as.integer(g), program = short$program[k], ccode = short$program_country_ccode[k]) }),
                 list(find_cfr_all(block, e$year)),
                 list(if (grepl("Reporting", block)) data.frame(pos = as.integer(regexpr("Reporting", block)), program = "Reporting procedures", ccode = NA))))
      if (!is.null(allhits)) progs <- allhits[order(abs(allhits$pos - amt_off)), ]
    }
    if (!is.null(progs)) progs <- progs[1, ]                     # one program per table row: the one nearest the amount
    loc <- if (is.na(block) || grepl("^Individual", e$name)) list(cc = NA_integer_, how = if (grepl("^Individual", e$name)) "individuals: not reported" else "no row") else
      if (grepl("[A-Z]{2}\\s+\\d{5}", block, perl = TRUE)) list(cc = 2L, how = "US state and ZIP in address") else find_location(block)
  } else {
    multi <- !is.na(seg_start[i])
    if (multi) { block <- substr(t, seg_start[i], seg_end[i]); how <- "narrative block (multi-entry report)" } else {
      nm <- substr(norm(e$name), 1, 25); p <- regexpr(nm, t, fixed = TRUE)
      start <- if (p > 0) p else 1; block <- substr(t, start, start + 2500)
      how <- if (p > 0) "narrative from entity name" else "narrative from document start" }
    progs <- rbind(find_programs(substr(block, 1, 1500), pm[, c("pattern", "program", "program_country_ccode")]),
                   find_cfr(substr(block, 1, 1500), e$year))
    if (!is.null(progs)) { progs <- progs[order(progs$pos), ]; progs <- progs[!duplicated(progs$ccode) | is.na(progs$ccode), ] }
    if (!multi && (is.null(progs) || grepl("[Mm]ultiple [Ss]anctions [Pp]rograms|[Vv]arious [Ss]anctions [Pp]rograms", substr(block, 1, 600)))) {
      # The release names its programs later (e.g., Binance 2023): scan the whole document for regulation names
      whole <- find_programs(t, pm[, c("pattern", "program", "program_country_ccode")])
      if (!is.null(whole)) { progs <- whole; progs$pos <- 0L; how <- paste0(how, "; programs from whole-document scan") }
    }
    if (is.null(progs)) progs <- find_programs(substr(block, 1, 1500), short)
    loc <- find_location(substr(block, 1, 900))
  }
  if (!is.null(progs) && !tabular) {
    # keep the program(s) named first: those within 300 characters of the first match
    progs <- progs[progs$pos <= min(progs$pos) + 300, ]
  }
  res[[i]] <- data.frame(e, doc_format = if (tabular) "table" else "narrative", block_method = how,
    block_text = substr(gsub("[\r\n]", " ", if (is.na(block)) "" else block), 1, 400),
    programs = if (is.null(progs)) NA_character_ else paste(progs$program, collapse = "; "),
    program_ccodes = if (is.null(progs)) NA_character_ else paste(na.omit(unique(progs$ccode)), collapse = ";"),
    location_ccode = loc$cc, location_method = loc$how)
}
en <- do.call(rbind, res)
# Individuals (named "An Individual", "Individuals", "Two Individuals", ...) versus firms and organizations
en$party_individual <- grepl("^(an |one |two |three |four |five |\\d+ )?individuals?$", trimws(tolower(en$name)), perl = TRUE)
lg("Entries for individuals: ", sum(en$party_individual), " (", sum(en$n[en$party_individual]), " penalties); for firms and organizations: ",
   sum(!en$party_individual & en$n > 0), " (", sum(en$n[!en$party_individual]), " penalties)")
write.csv(en, file.path(out, "penalties_entries.csv"), row.names = FALSE, na = "")
ph <- en$n == 0
lg("Entries: ", nrow(en), " (", sum(en$n), " penalties), of which ", sum(ph), " are 'None' placeholders for months without penalties")
lg("Program found: ", sum(!is.na(en$programs) & !ph), "; no program found: ", sum(is.na(en$programs) & !ph),
   " entries (", sum(en$n[is.na(en$programs)]), " penalties)")
lg("Entries with a country program: ", sum(nzchar(en$program_ccodes) & !is.na(en$program_ccodes)),
   "; non-country program only: ", sum(!is.na(en$programs) & (is.na(en$program_ccodes) | !nzchar(en$program_ccodes))))
lg("Location found: ", sum(!is.na(en$location_ccode)), " entries (US: ", sum(en$location_ccode == 2, na.rm = TRUE),
   "); not found: ", sum(is.na(en$location_ccode)))
lg("Document formats: ", paste(names(table(en$doc_format)), table(en$doc_format), sep = " ", collapse = ", "))

# ------------------------------------------------------------ 5. Country-year counts
pc <- do.call(rbind, lapply(seq_len(nrow(en)), function(i) {
  cs <- en$program_ccodes[i]; if (is.na(cs) || !nzchar(cs)) return(NULL)
  data.frame(ccode = as.integer(strsplit(cs, ";")[[1]]), year = en$year[i], n = en$n[i]) }))
pc_ent <- do.call(rbind, lapply(which(!en$party_individual), function(i) {
  cs <- en$program_ccodes[i]; if (is.na(cs) || !nzchar(cs)) return(NULL)
  data.frame(ccode = as.integer(strsplit(cs, ";")[[1]]), year = en$year[i], n = en$n[i]) }))
pc_ent <- aggregate(n ~ ccode + year, data = pc_ent, FUN = sum); names(pc_ent)[3] <- "pen_program_count_firms"
pc <- aggregate(n ~ ccode + year, data = pc, FUN = sum); names(pc)[3] <- "pen_program_count"
pc <- merge(pc, pc_ent, by = c("ccode", "year"), all.x = TRUE); pc$pen_program_count_firms[is.na(pc$pen_program_count_firms)] <- 0L
lc <- en[!is.na(en$location_ccode), c("location_ccode", "year", "n")]
lc <- aggregate(n ~ location_ccode + year, data = lc, FUN = sum); names(lc) <- c("ccode", "year", "pen_location_count")
cy <- merge(pc, lc, by = c("ccode", "year"), all = TRUE)
write.csv(cy, file.path(out, "penalties_country_year.csv"), row.names = FALSE, na = "")
lg("Country-years with program-attributed penalties: ", nrow(pc), "; with location-attributed penalties: ", nrow(lc),
   " (of which US-located: ", sum(lc$ccode == 2), " years)")
