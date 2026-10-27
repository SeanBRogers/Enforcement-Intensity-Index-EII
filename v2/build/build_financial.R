# EII v2 -- financial channel: additions to OFAC's SDN list, 1994-2025.
#
# Unit (BUILD_PROTOCOL.md, Q8): one person, entity, vessel or aircraft added
# to the SDN list, attributed twice (Q8 attribution, 2026-10-27):
#   program country  = target of the sanctions program in the entry's tags
#                      (v2/build/ofac_sdn_tags.csv); feeds the index
#   location country = country of the entry's address(es); second attribution
# Source: OFAC, "Archive of changes to the SDN list": yearly text files
# 1994-2023, three-column PDFs 2024-2025 (converted by sdn_pdf_to_text.R).
#
# Usage: Rscript v2/build/build_financial.R [repo_root]

suppressMessages(library(countrycode))
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw/ofac_sdn")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "financial_log.txt")
cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }

lg("EII v2 financial channel build, %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"))
lg("R %s; countrycode %s; %s", getRversion(), packageVersion("countrycode"),
   tryCatch(system2("pdftotext", "-v", stdout = TRUE, stderr = TRUE)[1], error = function(e) "pdftotext not found"))

# ---------------------------------------------------------------- inputs
yrs <- 1994:2025
src <- vapply(yrs, function(y) {
  yy <- sprintf("%02d", y %% 100)
  cand <- if (y <= 2015) file.path(raw, sprintf("sdnew%s.txt", yy)) else file.path(raw, sprintf("sdnnew%s.txt", yy))
  if (y >= 2024) cand <- file.path(raw, sprintf("sdnnew%s_pdf.txt", yy))
  cand
}, "")
stopifnot(all(file.exists(src)))

read_src <- function(f) {
  x <- readLines(f, warn = FALSE)
  if (!grepl("_pdf\\.txt$", f)) x <- iconv(x, "latin1", "UTF-8")
  x <- gsub("\r", "", x, fixed = TRUE)
  x <- gsub("\t", " ", x, fixed = TRUE)
  x <- gsub("[\001-\010\013-\037\177]", "", x)          # DOS end-of-file and other control characters
  x
}

# ---------------------------------------------------------------- parsing
date_re <- "^\\s*([0-9]{1,2})[/-]([0-9]{1,2})[/-]([0-9]{4}|[0-9]{2})(:|\\s+-\\s|\\s{2,}|\\s*$)(.*)$"
tag_re  <- "\\[([A-Z0-9][A-Z0-9 /&.-]*[A-Z0-9])\\]"
# names in other scripts, printed in the PDFs (and some text files) after the
# romanized name, e.g. "(Cyrillic: ...)"; removed before entries are compared
script_labels <- "Cyrillic|Arabic|Chinese Simplified|Chinese Traditional|Latin|Hebrew|Greek|Korean|Georgian|Hangul|Armenian"
script_re <- paste0("\\s*\\((", script_labels, "):[^)]*\\)")
script_end_re <- paste0("\\((Linked To|Region|", script_labels, "):$")

classify_header <- function(h) {
  l <- tolower(h)
  # "resulting in the following new entries" follows a changed entry (a change);
  # in 1995-1997 it follows a new designation ("has been named resulting in")
  if (grepl("^resulting in", l)) return("change")
  if (grepl("resulting in", l) && grepl("\\b(named|designated|added)\\b", l)) return("add")
  if (grepl("resulting in", l)) return("change")
  if (grepl("\\b(removed|deleted|deletion|deletions|removal|unblocked|delisted|lifted|lifting)\\b", l)) return("remove")
  if (grepl("\\bsuspended\\b", l)) return("remove")
  if (grepl("\\ba\\.?k\\.?a\\.?.?s\\b|new .?akas?.? have been added", l)) return("change")
  if (grepl("additional (information|data|address|identif)|information (has|have) been added|been updated|been expanded|clarification", l)) return("change")
  if (grepl("\\b(changed|updated|modified|amended|corrected|revised|changes)\\b", l)) return("change")
  if (grepl("formally listed|replaced by", l)) return("other")   # relisting of entries already on the list
  if (grepl("added|being added|additional|designat|identified|new entr|been listed|are listed|blocked pending investigation|have been included|need to be blocked", l)) return("add")
  if (grepl("following", l)) return("other")
  NA_character_                       # sub-heading: keep the current section type
}

join_lines <- function(v) {
  out <- ""
  for (s in trimws(v)) {
    if (!nzchar(s)) next
    out <- if (!nzchar(out)) s else if (grepl("-$", out)) paste0(out, s) else paste(out, s)
  }
  out
}

parse_file <- function(f, year_file) {
  x <- read_src(f)
  is_date <- grepl(date_re, x)
  dm <- regmatches(x[is_date], regexec(date_re, x[is_date]))
  ok <- vapply(dm, function(z) {
    mo <- as.integer(z[2]); dy <- as.integer(z[3]); yr <- as.integer(z[4])
    yr <- if (yr < 100) ifelse(yr >= 90, 1900 + yr, 2000 + yr) else yr
    mo >= 1 && mo <= 12 && dy >= 1 && dy <= 31 && yr >= 1993 && yr <= 2026
  }, logical(1))
  di <- which(is_date)[ok]; dm <- dm[ok]
  is_date[] <- FALSE; is_date[di] <- TRUE
  date_of <- rep(NA_character_, length(x)); rest_of <- rep(NA_character_, length(x))
  for (k in seq_along(di)) {
    z <- dm[[k]]; yr <- as.integer(z[4]); yr <- if (yr < 100) ifelse(yr >= 90, 1900 + yr, 2000 + yr) else yr
    date_of[di[k]] <- sprintf("%04d-%02d-%02d", yr, as.integer(z[2]), as.integer(z[3]))
    rest_of[di[k]] <- z[6]
  }
  tx <- trimws(x)
  # next non-blank line, for deciding whether an entry continues ("[TAG]",
  # "(Linked To: ...)" and "-to-" can wrap onto the following line)
  nb <- which(nzchar(tx))
  nxt <- rep(NA_character_, length(x))
  if (length(nb) > 1) nxt[nb[-length(nb)]] <- tx[nb[-1]]
  nxt_date <- rep(FALSE, length(x)); if (length(nb) > 1) nxt_date[nb[-length(nb)]] <- is_date[nb[-1]]
  cont_re <- "^(\\[|\\(|Linked To|-to-|[a-z])"
  n_max <- length(x)
  u_date <- character(n_max); u_sect <- character(n_max); u_kind <- character(n_max); u_text <- character(n_max)
  u_head <- character(n_max); cur_head <- ""
  nu <- 0L
  emit <- function(kind, txt) { nu <<- nu + 1L; u_date[nu] <<- cur_date; u_sect[nu] <<- sect; u_kind[nu] <<- kind; u_text[nu] <<- txt; u_head[nu] <<- cur_head }
  cur_date <- NA_character_; sect <- "pre"; chunk <- ""
  addl <- function(ch, s) if (!nzchar(ch)) s else if (endsWith(ch, "-")) paste0(ch, s) else paste(ch, s)
  for (i in seq_along(x)) {
    tl <- tx[i]
    if (is_date[i]) {
      if (nzchar(chunk)) emit("other", chunk); chunk <- ""
      cur_date <- date_of[i]; sect <- "none"; cur_head <- ""
      tl <- trimws(rest_of[i])
    }
    if (!nzchar(tl)) next
    chunk <- addl(chunk, tl)
    if ((endsWith(tl, ":") || endsWith(tl, "--")) && !is.na(cur_date) && nchar(chunk) < 1500 &&
        !grepl("a\\.k\\.a\\.|link:$|\\(individual\\)|not limited to", chunk) && !grepl(script_end_re, chunk) &&
        lengths(regmatches(chunk, gregexpr(";", chunk))) < 3 &&
        (grepl("\\b(following|have been|has been|are being|were|was)\\b", chunk, ignore.case = TRUE) ||
         (nchar(chunk) < 80 && !grepl("[;,(]", chunk)))) {
      h <- classify_header(chunk)
      if (!is.na(h)) { sect <- h; cur_head <- chunk }
      emit("header", chunk); chunk <- ""; next
    }
    if ((endsWith(tl, "]") || endsWith(tl, "].") || endsWith(tl, ").") || grepl("\\]\\s*\\*+$", tl)) &&
        grepl(tag_re, chunk) && (is.na(nxt[i]) || nxt_date[i] || !grepl(cont_re, nxt[i]))) {
      emit("entry", chunk); chunk <- ""
    }
  }
  if (nzchar(chunk)) emit("other", chunk)
  s <- seq_len(nu)
  data.frame(file = basename(f), date = u_date[s], section = u_sect[s], kind = u_kind[s],
             text = u_text[s], header = u_head[s], year_file = year_file, stringsAsFactors = FALSE)
}

units <- do.call(rbind, Map(function(f, y) { t0 <- Sys.time(); r <- parse_file(f, y)
  cat(sprintf("  %s: %d units (%.0fs)\n", basename(f), nrow(r), as.numeric(Sys.time() - t0, units = "secs"))); r }, src, yrs))
units$year <- as.integer(substr(units$date, 1, 4))
lg("Parsed %d units from %d files (%d entries, %d headers, %d other text blocks)",
   nrow(units), length(src), sum(units$kind == "entry"), sum(units$kind == "header"), sum(units$kind == "other"))

# ---------------------------------------------------------------- additions
add <- units[units$kind == "entry" & units$section == "add" & !is.na(units$year), ]
lg("Entries in sections headed as additions: %d", nrow(add))
drop93 <- add$year < 1994
lg("Dropped %d additions dated before 1994 (the 1994 file opens with December 1993 actions)", sum(drop93))
add <- add[!drop93, ]
offyear <- add$year != add$year_file
lg("Additions whose date year differs from the file year: %d (dated year used)", sum(offyear))

# entry fields
add$etype <- ifelse(grepl("\\(individual\\)", add$text), "individual",
             ifelse(grepl("\\(vessel\\)", add$text), "vessel",
             ifelse(grepl("\\(aircraft\\)", add$text), "aircraft", "entity")))
add$tags <- vapply(regmatches(add$text, gregexpr(tag_re, add$text)), function(t)
  paste(unique(gsub("\\s+", " ", gsub("^\\[|\\]$", "", t))), collapse = ";"), "")

# alias block: text inside the first (a.k.a./f.k.a./n.k.a. ...) parenthesis
alias_split <- function(s) {
  p <- regexpr("\\((a|f|n)\\.k\\.a\\.", s)
  if (p < 0) return(list(primary = NA_character_, names = character(), rest = s))
  depth <- 0; endp <- NA
  for (k in p:nchar(s)) {
    ch <- substr(s, k, k)
    if (ch == "(") depth <- depth + 1 else if (ch == ")") { depth <- depth - 1; if (depth == 0) { endp <- k; break } }
  }
  if (is.na(endp)) return(list(primary = NA_character_, names = character(), rest = s))
  inner <- substr(s, p + 1, endp - 1)
  nm <- trimws(gsub("^(a|f|n)\\.k\\.a\\.\\s*", "", strsplit(inner, ";\\s*")[[1]]))
  list(primary = trimws(substr(s, 1, p - 1)), names = nm, rest = substr(s, endp + 1, nchar(s)))
}
norm <- function(s) toupper(gsub("[^A-Za-z0-9]", "", s))
add$text_clean <- gsub(script_re, "", add$text)
al <- lapply(add$text_clean, alias_split)
add$dedup_key <- vapply(seq_along(al), function(i) {
  a <- al[[i]]
  if (is.na(a$primary)) return(paste0("T#", norm(add$text_clean[i])))
  paste0("A#", paste(sort(unique(norm(c(a$primary, a$names)))), collapse = "|"), "#", norm(a$rest))
}, "")
dup <- duplicated(add[, c("date", "dedup_key")])
lg("Alias and repeat listings removed: %d (one entry per name set and identifying details per date; OFAC lists each a.k.a. of some designees as its own entry)", sum(dup))
dd <- table(add$year[dup]); lg("  by year: %s", paste(names(dd), dd, sep = "=", collapse = ", "))
add <- add[!dup, ]

# same-day relisting: an entry removed and added again on the same date (e.g.
# 1997-10-08, terrorist organizations deleted as SDTs and relisted as SDTs and
# FTOs) is not a new designation
primary_of <- function(s) { a <- alias_split(gsub(script_re, "", s)); norm(if (!is.na(a$primary)) a$primary else sub("[;,].*$", "", s)) }
rem <- units[units$kind == "entry" & units$section == "remove" & !is.na(units$date), ]
rem_key <- unique(paste(rem$date, vapply(rem$text, primary_of, "")))
relist <- paste(add$date, vapply(add$text, primary_of, "")) %in% rem_key
lg("Same-day relistings removed (deleted and added again on the same date): %d", sum(relist))
if (any(relist)) { rl <- table(add$date[relist]); lg("  dates: %s", paste(names(rl), rl, sep = "=", collapse = ", ")) }
add <- add[!relist, ]

# ---------------------------------------------------------------- location
fix_cty <- c("Korea, North" = "North Korea", "Korea, South" = "South Korea",
             "Congo, Democratic Republic of the" = "Democratic Republic of the Congo",
             "Congo, Republic of the" = "Republic of the Congo",
             "Micronesia, Federated States of" = "Micronesia",
             "Bahamas, The" = "Bahamas", "Gambia, The" = "Gambia",
             "Macedonia, The Former Yugoslav Republic of" = "North Macedonia",
             "Virgin Islands, British" = "British Virgin Islands",
             "Korea, Democratic People's Republic of" = "North Korea")
place_ccode <- function(nm, yr) {
  out <- suppressWarnings(countrycode(nm, "country.name", "cown", warn = FALSE,
           custom_match = c("Burma" = 775, "Serbia" = 345, "Serbia and Montenegro" = 345,
                            "Yugoslavia" = 345, "Kosovo" = 347, "Montenegro" = 341,
                            "Czech Republic" = 316, "Germany" = 255, "Vietnam" = 816,
                            "Yemen" = 679, "Russia" = 365, "Macau" = NA, "Hong Kong" = NA,
                            "West Bank" = NA, "Gaza" = NA, "Palestinian" = NA,
                            "Region: Gaza" = NA, "Region: West Bank" = NA,
                            "Republic of Serbia" = 345, "England" = 200, "Scotland" = 200,
                            "Wales" = 200, "Northern Ireland" = 200, "Crimea" = 369)))
  out
}
loc_of <- function(s, etype) {
  a <- alias_split(s)
  body <- if (!is.na(a$primary)) a$rest else s
  body <- sub("\\[.*$", "", body)                       # drop tags and anything after
  body <- gsub("\\(Linked To:[^)]*\\)", "", body)
  body <- gsub("\\((individual|vessel|aircraft)\\)", "", body)
  for (k in names(fix_cty)) body <- gsub(k, fix_cty[[k]], body, fixed = TRUE)
  segs <- trimws(strsplit(body, ";")[[1]])
  if (!length(segs)) return(character())
  if (is.na(a$primary)) {                               # strip the name from the first segment
    tok <- trimws(strsplit(segs[1], ",")[[1]])
    keep <- if (etype == "individual") tok[-(1:min(2, length(tok)))] else tok[-1]
    segs[1] <- paste(keep, collapse = ", ")
  }
  segs <- segs[!grepl("^(alt\\. )?(POB|DOB|nationality|citizen|Passport|Gender)\\b", segs)]
  last <- vapply(segs, function(z) { t <- trimws(strsplit(z, ",")[[1]]); if (length(t)) t[length(t)] else "" }, "")
  last <- sub("\\.$", "", trimws(last))
  # "Vojvodina (Serbia)": a region with its country in parentheses
  last <- sub("^[A-Za-z .'-]+ \\(([A-Za-z .'-]+)\\)$", "\\1", last)
  unique(last[nzchar(last)])
}
add$loc_raw <- vapply(seq_len(nrow(add)), function(i) paste(loc_of(add$text_clean[i], add$etype[i]), collapse = ";"), "")
loc_tok <- strsplit(add$loc_raw, ";")
all_tok <- unique(unlist(loc_tok))
# only short, clean tokens can be a country: identifiers such as
# "Tax ID No. 77... (Russia)" are not addresses
all_tok <- all_tok[grepl("^[A-Za-z][A-Za-z .'-]{1,40}$", all_tok) | grepl("^Region: ", all_tok)]
tok_cc <- place_ccode(all_tok)
non_cow_places <- c("Macau", "Hong Kong", "West Bank", "Gaza", "Region: Gaza", "Region: West Bank", "Palestinian",
                    "British Virgin Islands", "Cayman Islands", "Bermuda", "Gibraltar", "Isle of Man", "Jersey",
                    "Guernsey", "Netherlands Antilles", "Aruba", "Curacao", "Anguilla", "Turks and Caicos Islands",
                    "Puerto Rico", "Greenland", "Western Sahara", "New Caledonia", "French Polynesia")
is_place <- !is.na(tok_cc) | all_tok %in% non_cow_places
names(tok_cc) <- all_tok; names(is_place) <- all_tok
add$location_ccode <- vapply(loc_tok, function(t) {
  t <- t[t %in% all_tok[is_place]]
  cc <- unique(tok_cc[t]); cc <- cc[!is.na(cc)]
  paste(cc, collapse = ";")
}, "")
add$location_found <- vapply(loc_tok, function(t) any(t %in% all_tok[is_place]), logical(1))
# successor states coded to their predecessor before COW membership begins
yr_fix <- function(cc, yr) {
  if (!nzchar(cc)) return(cc)
  v <- as.integer(strsplit(cc, ";")[[1]])
  v[v == 341 & yr < 2006] <- 345; v[v == 347 & yr < 2008] <- 345; v[v == 626 & yr < 2011] <- 625
  paste(sort(unique(v)), collapse = ";")
}
add$location_ccode <- mapply(yr_fix, add$location_ccode, add$year, USE.NAMES = FALSE)
lg("Location (address country) found for %d of %d additions (%.1f%%)", sum(add$location_found), nrow(add), 100 * mean(add$location_found))

# ---------------------------------------------------------------- program country
tagmap <- read.csv(file.path(root, "v2/build/ofac_sdn_tags.csv"), stringsAsFactors = FALSE, na.strings = "")
alltags <- unique(unlist(strsplit(add$tags, ";")))
alltags <- alltags[nzchar(alltags)]
unm <- setdiff(alltags, tagmap$tag)
if (length(unm)) {
  tc <- sort(table(unlist(strsplit(add$tags, ";")))[unm], decreasing = TRUE)
  lg("UNMAPPED TAGS (%d): %s", length(unm), paste(names(tc), tc, sep = "=", collapse = ", "))
}
prog_cc <- function(tags, yr) {
  t <- strsplit(tags, ";")[[1]]
  r <- tagmap[tagmap$tag %in% t & !is.na(tagmap$ccode) & tagmap$sdn == 1 &
              (is.na(tagmap$from) | yr >= tagmap$from) & (is.na(tagmap$to) | yr <= tagmap$to), ]
  paste(sort(unique(r$ccode)), collapse = ";")
}
non_sdn <- tagmap$tag[tagmap$sdn == 0]
only_non_sdn <- vapply(strsplit(add$tags, ";"), function(t) length(t) > 0 && all(t %in% non_sdn), logical(1))
lg("Dropped %d additions tagged only with non-SDN lists (FSE, NS-PLC)", sum(only_non_sdn))
add <- add[!only_non_sdn, ]
add$program_ccode <- mapply(prog_cc, add$tags, add$year, USE.NAMES = FALSE)
add$program_tagged <- nzchar(add$tags)
lg("Additions with at least one program tag: %d of %d", sum(add$program_tagged), nrow(add))
lg("Additions with a program country: %d (the rest are under non-country programs only, e.g. terrorism, narcotics, nonproliferation)",
   sum(nzchar(add$program_ccode)))

# ---------------------------------------------------------------- outputs
ent <- add[, c("date", "year", "file", "etype", "tags", "program_ccode", "location_ccode", "loc_raw", "header", "text")]
ent$header <- substr(ent$header, 1, 200)
ent$text <- substr(ent$text, 1, 400)
write.csv(ent, file.path(outd, "sdn_additions.csv"), row.names = FALSE)

long <- function(cc_col, keep) {
  d <- add[keep, ]
  s <- strsplit(d[[cc_col]], ";")
  data.frame(ccode = as.integer(unlist(s)), year = rep(d$year, lengths(s)))
}
cy <- function(df, nm) { if (!nrow(df)) return(data.frame(ccode = integer(), year = integer())); a <- aggregate(list(n = rep(1, nrow(df))), df, sum); names(a)[3] <- nm; a }
p_all  <- cy(long("program_ccode", rep(TRUE, nrow(add))), "fin_program_count")
p_ent  <- cy(long("program_ccode", add$etype != "individual"), "fin_program_count_nonindiv")
l_all  <- cy(long("location_ccode", rep(TRUE, nrow(add))), "fin_location_count")
fy <- Reduce(function(a, b) merge(a, b, all = TRUE), list(p_all, p_ent, l_all))
fy[is.na(fy)] <- 0
write.csv(fy[order(fy$ccode, fy$year), ], file.path(outd, "financial_country_year.csv"), row.names = FALSE)

yt <- aggregate(list(additions = rep(1, nrow(add))), list(year = add$year), sum)
yt$individuals <- tapply(add$etype == "individual", add$year, sum)[as.character(yt$year)]
yt$with_program_country <- tapply(nzchar(add$program_ccode), add$year, sum)[as.character(yt$year)]
yt$with_location <- tapply(add$location_found, add$year, sum)[as.character(yt$year)]
lg("Additions by year (after alias removal):")
for (i in seq_len(nrow(yt))) lg("  %d  %5d additions  %5d individuals  %5d with program country  %5d with location",
                               yt$year[i], yt$additions[i], yt$individuals[i], yt$with_program_country[i], yt$with_location[i])
write.csv(yt, file.path(outd, "financial_year_totals.csv"), row.names = FALSE)
saveRDS(units, file.path(outd, "..", "sources", "raw", "ofac_sdn", "units.rds"))
