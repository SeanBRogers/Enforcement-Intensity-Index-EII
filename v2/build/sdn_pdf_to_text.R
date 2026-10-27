# Convert OFAC's three-column "changes to the SDN list" PDFs (2024 on) to
# plain text in reading order. pdftotext's default and -layout modes
# interleave the columns, so this reads word boxes (pdftotext -bbox-layout)
# and orders lines by page, then column, then vertical position.
# Usage: Rscript sdn_pdf_to_text.R in.pdf out.txt

args <- commandArgs(trailingOnly = TRUE)
pdf <- args[1]; out <- args[2]
bbox <- tempfile(fileext = ".html")
stopifnot(system2("pdftotext", c("-bbox-layout", shQuote(pdf), shQuote(bbox))) == 0)
x <- readLines(bbox, encoding = "UTF-8", warn = FALSE)
unlink(bbox)

is_page <- grepl("^\\s*<page ", x)
is_line <- grepl("^\\s*<line ", x)
is_word <- grepl("^\\s*<word ", x)
page <- cumsum(is_page)
line_id <- cumsum(is_line)

attr_num <- function(s, a) as.numeric(sub(paste0('.*', a, '="([0-9.]+)".*'), "\\1", s))
lines <- data.frame(line_id = line_id[is_line], page = page[is_line],
                    xmin = attr_num(x[is_line], "xMin"), ymin = attr_num(x[is_line], "yMin"))
w <- x[is_word]
words <- data.frame(line_id = line_id[is_word],
                    text = sub('^\\s*<word [^>]*>(.*)</word>\\s*$', "\\1", w),
                    stringsAsFactors = FALSE)
txt <- tapply(words$text, words$line_id, paste, collapse = " ")
lines$text <- unname(txt[as.character(lines$line_id)])
lines <- lines[!is.na(lines$text), ]

# Column boundaries for a 612-pt letter page with three text columns starting
# near x = 72, 245 and 405 (checked on sampled pages of the 2023-2025 files).
lines$col <- ifelse(lines$xmin < 220, 1L, ifelse(lines$xmin < 395, 2L, 3L))
lines <- lines[order(lines$page, lines$col, lines$ymin, lines$xmin), ]

dec <- function(s) {
  s <- gsub("&lt;", "<", s, fixed = TRUE); s <- gsub("&gt;", ">", s, fixed = TRUE)
  s <- gsub("&quot;", "\"", s, fixed = TRUE); s <- gsub("&#39;", "'", s, fixed = TRUE)
  s <- gsub("&apos;", "'", s, fixed = TRUE)
  gsub("&amp;", "&", s, fixed = TRUE)
}
out_txt <- dec(lines$text)
# Date markers are set as bullets ("\u2022 01/05/23"); page headers repeat the
# title. Drop the headers and write dates as the text archive does ("01/05/23:").
out_txt <- sub("^\u2022\\s*([0-9]{2}/[0-9]{2}/[0-9]{2})\\s*$", "\\1:", out_txt)
drop <- grepl("^(SINCE JANUARY 1, [0-9]{4}|OFFICE OF FOREIGN ASSETS CONTROL|CHANGES TO THE Specially Designated Nationals and Blocked Persons List|CHANGES TO THE SDNLIST IN [0-9]{4}|- ?[0-9]+ ?-)$", out_txt)
cat(sprintf("Dropped %d page header, title and page-number lines\n", sum(drop)))
out_txt <- out_txt[!drop]
writeLines(out_txt, out, useBytes = TRUE)
cat(sprintf("%s: %d pages, %d lines\n", basename(pdf), max(lines$page), nrow(lines)))
