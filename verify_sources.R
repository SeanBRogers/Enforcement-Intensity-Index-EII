# ==============================================================================
# SOURCE VERIFICATION — DOES EACH COVARIATE MATCH ITS STATED SOURCE?
# ==============================================================================
# Checks the panel's covariates against the sources named in CODEBOOK.md,
# value by value. Every "Verified" status for an external source in the
# codebook is produced by this script (degradation: degradation_audit.R).
#
#   polity            Polity5 p5v2018 polity2, under the codebook's entity map
#   vdem_electoral    V-Dem v16 v2x_polyarchy  (vdemdata 16.0)
#   vdem_elections    V-Dem v16 v2xel_frefair
#   friction          UNGA ideal points, IdealpointsJuly2025.tab:
#                     |US - state| idealpointfp, lagged one year
#   fiscal_pressure   FRED FYOIGDA188S (OMB net interest, % of GDP)
#   resource_density  World Bank WDI NY.GDP.TOTL.RT.ZS   (live API)
#   gdp_pc_log        log of World Bank WDI NY.GDP.PCAP.CD (live API)
#
# WDI values are revised between releases, so they are checked to a
# tolerance and the share within it is reported. The others are checked
# to the panel's rounding (half a unit in the last stored decimal).
#
# Each source is downloaded unless a local copy is given:
#   POLITY5_XLS  path to p5v2018.xls
#   VDEM_RDATA   path to vdemdata's data/vdem.RData (the download is pinned to
#                the vdemdata commit that ships V-Dem v16, package version 16.0)
#   UNGA_TAB     path to IdealpointsJuly2025.tab
# ==============================================================================

.libPaths(c("C:/R/library", .libPaths()))
suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(jsonlite)
  library(here)
})

get_file <- function(env, url, ext) {
  p <- Sys.getenv(env, unset = "")
  if (p != "" && file.exists(p)) return(p)
  f <- tempfile(fileext = ext)
  download.file(url, f, mode = "wb", quiet = TRUE)
  f
}

df <- read_csv(here("EII_Panel_Definitive.csv"), show_col_types = FALSE) |>
  mutate(src = sub("_2$", "", iso3))
FAIL <- 0
report <- function(label, ok, n, extra = "") {
  cat(sprintf("  %s  %-18s %d of %d rows%s\n", if (ok == n) "PASS" else "FAIL",
              label, ok, n, extra))
  if (ok != n) FAIL <<- FAIL + 1
}

# ---- Polity5 polity2 ----------------------------------------------------------
p5 <- read_excel(get_file("POLITY5_XLS",
                          "https://www.systemicpeace.org/inscr/p5v2018.xls", ".xls"))
# Polity5 country code(s) by panel code; Rhodesia and Hong Kong are not in Polity5.
pcode <- function(iso, yr) {
  switch(iso,
    AFG = 700, AGO = 540, BLR = 370, BIH = 346, BDI = 516, KHM = 811, CAF = 482,
    CHN = 710, CIV = 437, CUB = 40, COD = 490, ERI = 531, ETH = 530, DDR = 265,
    HTI = 41, IRN = 630, IRQ = 645, LAO = 812, LBN = 660, LBR = 450, LBY = 620,
    MLI = 432, MMR = 775, NIC = 93, NER = 436, PRK = 731, PAK = 770, PAN = 95,
    RUS = 365, SLE = 451, SOM = 520, ZAF = 560, SSD = 525, SYR = 652, UGA = 500,
    VEN = 101, YEM = 679, SRB = 347, ZWE = 552,
    SDN = if (yr <= 2010) 625 else 626,
    VNM = if (yr <= 1975) 816 else 818,
    NA)
}
pol <- df |>
  rowwise() |>
  mutate(ccode = if (src %in% c("RHO", "HKG")) NA_real_ else pcode(src, year)) |>
  ungroup() |>
  left_join(p5 |> group_by(ccode, year) |> summarize(p2 = last(polity2), .groups = "drop"),
            by = c("ccode", "year")) |>
  mutate(p2 = if_else(year > 2018, NA_real_, p2))
cat("\n[polity] Polity5 p5v2018 polity2\n")
report("polity", sum((is.na(pol$polity) & is.na(pol$p2)) |
                     (!is.na(pol$polity) & !is.na(pol$p2) & pol$polity == pol$p2)), nrow(pol))

# ---- V-Dem v16 --------------------------------------------------------------------
load(get_file("VDEM_RDATA",
              "https://github.com/vdeminstitute/vdemdata/raw/f4dd26922e658442524dfd954bf14f7ebe622d5d/data/vdem.RData", ".RData"))
vd <- vdem |>
  transmute(vid = country_text_id, year,
            e = round(v2x_polyarchy, 3), c = round(v2xel_frefair, 3))
vm <- df |>
  mutate(vid = case_when(src == "RHO" ~ "ZWE", TRUE ~ src)) |>
  left_join(vd, by = c("vid", "year"))
cat("\n[vdem] V-Dem v16\n")
same <- function(a, b, tol) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
report("vdem_electoral", sum(same(vm$vdem_electoral, vm$e, 1e-9)), nrow(vm))
report("vdem_elections", sum(same(vm$vdem_elections, vm$c, 1e-9)), nrow(vm))

# ---- UNGA ideal points (friction) -------------------------------------------------
un <- read_tsv(get_file("UNGA_TAB",
                        "https://dataverse.harvard.edu/api/access/datafile/11824371", ".tab"),
               show_col_types = FALSE) |>
  mutate(year = as.integer(year))
us <- un |> filter(ccode == 2) |> select(year, us = idealpointfp)
ucode <- un |> distinct(iso3c, ccode) |> filter(!is.na(iso3c))
fm <- df |>
  left_join(ucode, by = c("src" = "iso3c")) |>
  mutate(ccode = case_when(src == "DDR" ~ 265, src == "SRB" ~ 345, TRUE ~ ccode),
         lag = year - 1L) |>
  left_join(un |> select(ccode, year, idealpointfp), by = c("ccode", "lag" = "year")) |>
  left_join(us, by = c("lag" = "year")) |>
  mutate(fr = abs(us - idealpointfp))
cat("\n[friction] UNGA ideal points, July 2025 release, lag 1\n")
report("friction", sum(same(fm$friction, fm$fr, 5e-5 + 1e-9)), nrow(fm))

# ---- FRED ---------------------------------------------------------------------
fred <- read_csv("https://fred.stlouisfed.org/graph/fredgraph.csv?id=FYOIGDA188S",
                 show_col_types = FALSE)
names(fred) <- c("date", "value")
fred <- fred |> mutate(year = as.integer(substr(date, 1, 4)), value = as.numeric(value))
ff <- df |> distinct(year, fiscal_pressure) |> left_join(fred, by = "year")
cat("\n[fiscal] FRED FYOIGDA188S\n")
report("fiscal_pressure", sum(same(ff$fiscal_pressure, ff$value, 5e-4 + 1e-9)), nrow(ff),
       " (years)")

# ---- World Bank WDI (live API; revised between releases) ----------------------
wdi <- function(indicator) {
  isos <- setdiff(unique(df$src), c("DDR", "RHO"))
  bind_rows(lapply(isos, function(i) {
    u <- sprintf("https://api.worldbank.org/v2/country/%s/indicator/%s?format=json&per_page=200",
                 i, indicator)
    j <- tryCatch(fromJSON(u), error = function(e) NULL)
    if (is.null(j) || length(j) < 2 || is.null(j[[2]]) || length(j[[2]]) == 0) return(NULL)
    tibble(src = i, year = as.integer(j[[2]]$date), value = j[[2]]$value)
  }))
}
cat("\n[wdi] World Bank WDI (tolerance: resource 0.01, log GDP 0.01)\n")
rr <- df |> left_join(wdi("NY.GDP.TOTL.RT.ZS"), by = c("src", "year")) |> filter(!is.na(resource_density))
report("resource_density", sum(abs(rr$resource_density - rr$value) <= 0.01, na.rm = TRUE), nrow(rr))
gg <- df |> left_join(wdi("NY.GDP.PCAP.CD"), by = c("src", "year")) |> filter(!is.na(gdp_pc_log))
ok <- sum(abs(gg$gdp_pc_log - log(gg$value)) <= 0.01, na.rm = TRUE)
cat(sprintf("  INFO  gdp_pc_log         %d of %d rows within 0.01 (%.1f%%); %d within 0.001\n",
            ok, nrow(gg), 100 * ok / nrow(gg),
            sum(abs(gg$gdp_pc_log - log(gg$value)) <= 0.001, na.rm = TRUE)))

cat(sprintf("\nRESULT: %d source check(s) failed\n", FAIL))
if (FAIL > 0) quit(status = 1)
