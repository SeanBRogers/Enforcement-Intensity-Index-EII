# EII v2 -- covariates (BUILD_PROTOCOL.md, Q3, Q6, Q13, Q14; build order step 6).
#
# Writes two files, kept apart from the exertion panel:
#   v2/output/covariates_year.csv          one row per year (US burden, rival capacity)
#   v2/output/covariates_country_year.csv  one row per state-year (sanctuary, extractive value)
# Sources and checksums: v2/sources/MANIFEST_covariates.csv.
#
# Usage: Rscript v2/build/build_covariates.R [repo_root]

suppressMessages({ library(readxl); library(countrycode); library(jsonlite) })
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
raw  <- file.path(root, "v2/sources/raw/covariates")
snap <- file.path(root, "v2/sources/snapshots")
outd <- file.path(root, "v2/output")
logf <- file.path(outd, "covariates_log.txt")
cat("", file = logf)
lg <- function(...) { s <- sprintf(...); cat(s, "\n", sep = "", file = logf, append = TRUE); cat(s, "\n", sep = "") }
lg("EII v2 covariates build, %s", format(Sys.time(), "%Y-%m-%d %H:%M %Z"))
lg("R %s; readxl %s; countrycode %s; jsonlite %s", getRversion(), packageVersion("readxl"),
   packageVersion("countrycode"), packageVersion("jsonlite"))

yrs <- 1950:2025
frame <- read.csv(file.path(outd, "EII_v2_partial.csv"), stringsAsFactors = FALSE)[, c("ccode", "year")]

# ======================================================= 1. US burden (OMB)
# OMB Historical Tables, FY2027 Budget (April 2026); actuals through FY2025.
# Fiscal years are used as panel years (FY t ends in calendar year t; the
# fiscal year ended June 30 before FY1977 and September 30 after). The 1976
# transition quarter is dropped.
num <- function(x) suppressWarnings(as.numeric(gsub("[^0-9.-]", "", as.character(x))))
t12 <- read_excel(file.path(raw, "omb/hist01z2_fy2027.xlsx"), col_names = FALSE, .name_repair = "minimal")
t12 <- data.frame(year = num(t12[[1]]), us_surplus_gdp = num(t12[[5]]))
t12 <- t12[!is.na(t12$year) & grepl("^[0-9]{4}$", as.character(t12$year)), ]

t71 <- read_excel(file.path(raw, "omb/hist07z1_fy2027.xlsx"), col_names = FALSE, .name_repair = "minimal")
lab71 <- as.character(t71[[1]])
t71 <- data.frame(year = num(t71[[1]]), us_debt_gross_gdp = num(t71[[7]]),
                  us_debt_public_gdp = num(t71[[9]]), us_debt_public_exfed_gdp = num(t71[[11]]))
t71 <- t71[grepl("^[0-9]{4}$", lab71), ]

t61 <- read_excel(file.path(raw, "omb/hist06z1_fy2027.xlsx"), col_names = FALSE, .name_repair = "minimal")
hdr <- as.character(unlist(t61[2, ]))
lab <- trimws(as.character(t61[[1]]))
pct <- which(lab == "As percentages of GDP:")
row_after <- function(name) { r <- which(lab == name); r[r > pct][1] }
pick <- function(r) num(unlist(t61[r, ]))
yc <- which(grepl("^[0-9]{4}$", hdr))
t61 <- data.frame(year = as.integer(hdr[yc]),
                  us_outlays_gdp = pick(row_after("Total outlays"))[yc],
                  us_defense_gdp = pick(row_after("National defense (1)"))[yc],
                  us_net_interest_gdp = pick(row_after("Net interest (2)"))[yc])

burden <- Reduce(function(a, b) merge(a, b, all = TRUE), list(t12, t71, t61))
burden <- burden[burden$year %in% yrs, ]
stopifnot(nrow(burden) == length(yrs), !anyNA(burden))
lg("US burden: %d fiscal years, %d-%d (OMB Tables 1.2, 6.1, 7.1)", nrow(burden), min(burden$year), max(burden$year))
for (y in c(1950, 1971, 1991, 2001, 2008, 2020, 2025)) {
  b <- burden[burden$year == y, ]
  lg("  %d: gross debt %.1f%% of GDP; debt held by public %.1f%%; net interest %.1f%%; surplus %.1f%%; outlays %.1f%%; defense %.1f%%",
     y, b$us_debt_gross_gdp, b$us_debt_public_gdp, b$us_net_interest_gdp, b$us_surplus_gdp, b$us_outlays_gdp, b$us_defense_gdp)
}

# ======================================================= 2. World Bank WDI snapshots
# Live API responses saved on 2026-10-27 (CC BY 4.0) and committed, so the build
# does not depend on the API's state on a later day.
wdi <- function(ind) {
  j <- fromJSON(file.path(snap, sprintf("wdi_%s_2026-10-27.json", ind)))
  d <- j[[2]]
  data.frame(iso3 = d$countryiso3code, name = d$country$value, year = as.integer(d$date),
             value = d$value, stringsAsFactors = FALSE)
}
gdp <- wdi("NY.GDP.MKTP.CD")
gdp <- gdp[!is.na(gdp$value), ]
lg("WDI GDP (current US$): %d country-years with data, %d-%d", nrow(gdp), min(gdp$year), max(gdp$year))

# ------------------------------------------------------- rival capacity (year level)
world <- setNames(gdp$value[gdp$iso3 == "WLD"], gdp$year[gdp$iso3 == "WLD"])
share_of <- function(members_by_year) {
  vapply(yrs, function(y) {
    m <- members_by_year(y)
    if (is.null(m) || !length(m) || is.na(world[as.character(y)])) return(NA_real_)
    v <- gdp$value[gdp$year == y & gdp$iso3 %in% m]
    if (length(v) < length(m)) return(NA_real_)                    # a member without data: missing, not partial
    100 * sum(v) / world[as.character(y)]
  }, numeric(1))
}
# EU (EEC/EC/EU) by year of accession; the UK counts through 2019.
eu_join <- c(BEL = 1958, FRA = 1958, DEU = 1958, ITA = 1958, LUX = 1958, NLD = 1958,
             DNK = 1973, IRL = 1973, GBR = 1973, GRC = 1981, ESP = 1986, PRT = 1986,
             AUT = 1995, FIN = 1995, SWE = 1995, CYP = 2004, CZE = 2004, EST = 2004,
             HUN = 2004, LVA = 2004, LTU = 2004, MLT = 2004, POL = 2004, SVK = 2004,
             SVN = 2004, BGR = 2007, ROU = 2007, HRV = 2013)
eu_leave <- c(GBR = 2020)
eu_members <- function(y) {
  m <- names(eu_join)[eu_join <= y]
  m[!(m %in% names(eu_leave) & y >= eu_leave[m])]
}
# BRICS by year of joining: BRIC first summit 2009; South Africa 2011; Egypt,
# Ethiopia, Iran and the UAE from 1 January 2024; Indonesia 2025. Saudi Arabia,
# invited in 2023, has not confirmed membership and is not counted.
brics_join <- c(BRA = 2009, RUS = 2009, IND = 2009, CHN = 2009, ZAF = 2011,
                EGY = 2024, ETH = 2024, IRN = 2024, ARE = 2024, IDN = 2025)
brics_members <- function(y) names(brics_join)[brics_join <= y]
brics5 <- function(y) c("BRA", "RUS", "IND", "CHN", "ZAF")

rival <- data.frame(year = yrs,
                    us_gdp_share = share_of(function(y) "USA"),
                    china_gdp_share = share_of(function(y) "CHN"),
                    eu_gdp_share = share_of(eu_members),
                    brics_gdp_share = share_of(brics_members),
                    brics5_gdp_share_fixed = share_of(brics5))
rival$brics_gdp_share[rival$year < 2009] <- NA                   # the bloc did not exist
lg("Rival capacity (share of world GDP at market exchange rates, WDI): first year with data -- US %s, China %s, EU %s, BRICS %s, BRICS-5 fixed %s",
   min(rival$year[!is.na(rival$us_gdp_share)]), min(rival$year[!is.na(rival$china_gdp_share)]),
   min(rival$year[!is.na(rival$eu_gdp_share)]), min(rival$year[!is.na(rival$brics_gdp_share)]),
   min(rival$year[!is.na(rival$brics5_gdp_share_fixed)]))
for (y in c(1960, 1980, 2000, 2010, 2025)) {
  r <- rival[rival$year == y, ]
  lg("  %d: US %.1f%%; China %.1f%%; EU %.1f%%; BRICS %.1f%%; BRICS-5 fixed %.1f%%",
     y, r$us_gdp_share, r$china_gdp_share, r$eu_gdp_share, r$brics_gdp_share, r$brics5_gdp_share_fixed)
}
miss_eu <- yrs[is.na(rival$eu_gdp_share) & yrs >= 1960]
if (length(miss_eu)) lg("  EU share missing (a member without GDP data) in: %s", paste(miss_eu, collapse = ", "))

covy <- merge(burden, rival, by = "year", all = TRUE)
write.csv(covy, file.path(outd, "covariates_year.csv"), row.names = FALSE, na = "")

# ======================================================= 3. Country-year covariates
# ------------------------------------------------------- ISO3 to COW
iso_cow <- function(iso, yr) {
  cc <- suppressWarnings(countrycode(iso, "iso3c", "cown", warn = FALSE,
          custom_match = c(SRB = 345, XKX = 347, DEU = 255, YEM = 679, VNM = 816,
                           CZE = 316, RUS = 365, MNE = 341, SSD = 626, TLS = 860)))
  cc[iso == "DEU" & yr <= 1990] <- 260                            # WDI's Germany series before unification
  cc[iso == "YEM" & yr < 1990] <- 678                             # WDI's Yemen series before unification
  cc
}

# ------------------------------------------------------- extractive value: natural resource rents
rents <- wdi("NY.GDP.TOTL.RT.ZS")
rents <- rents[!is.na(rents$value) & nzchar(rents$iso3), ]
rents$ccode <- iso_cow(rents$iso3, rents$year)
unm <- unique(rents$name[is.na(rents$ccode)])
rents <- rents[!is.na(rents$ccode), c("ccode", "year", "value")]
names(rents)[3] <- "nat_res_rents_gdp"
lg("Natural resource rents (%% of GDP, WDI): %d-%d; WDI rows not mapped to a COW state: %d (aggregates and non-states)",
   min(rents$year), max(rents$year), length(unm))

# ------------------------------------------------------- sanctuary: ATOP defense pacts with the US
td <- tempfile(); unzip(file.path(raw, "atop/atop_5.1_csv.zip"), exdir = td)
dy <- read.csv(list.files(td, pattern = "^atop5_1dy\\.csv$", recursive = TRUE, full.names = TRUE))
us <- dy[(dy$mem1 == 2 | dy$mem2 == 2) & dy$year >= 1950, ]
us$ccode <- ifelse(us$mem1 == 2, us$mem2, us$mem1)
atop <- aggregate(list(us_defense_pact = us$defense), list(ccode = us$ccode, year = us$year), max)
lg("ATOP 5.1 dyad-years with the US, 1950-2018: %d; with a defense obligation: %d", nrow(us), sum(us$defense == 1))
# 2019-2025: ATOP ends in 2018. The 2018 defense partners are carried forward,
# adding the NATO accessions since: North Macedonia (2020), Finland (2023),
# Sweden (2024). No US defense pact is known to have ended in 2019-2025.
d18 <- atop$ccode[atop$year == 2018 & atop$us_defense_pact == 1]
add <- c(`343` = 2020, `375` = 2023, `380` = 2024)
cf <- do.call(rbind, lapply(2019:2025, function(y)
  data.frame(ccode = sort(unique(c(d18, as.integer(names(add))[add <= y]))), year = y, us_defense_pact = 1L)))
atop <- rbind(atop[atop$us_defense_pact == 1, ], cf)
lg("US defense partners: %d in 1950, %d in 1990, %d in 2018, %d in 2025 (2019-2025 carried forward with logged accessions)",
   sum(atop$year == 1950), sum(atop$year == 1990), sum(atop$year == 2018), sum(atop$year == 2025))

# ------------------------------------------------------- sanctuary: UNGA alignment with the US
un <- read.csv(file.path(raw, "unga/IdealpointestimatesFP_2026FP.csv"), check.names = FALSE, stringsAsFactors = FALSE)
un <- un[un$year %in% yrs, ]
usip <- setNames(un$IdealPointFP[un$ccode == 2], un$year[un$ccode == 2])
un$unga_ideal <- un$IdealPointFP
un$unga_dist_us <- abs(un$IdealPointFP - usip[as.character(un$year)])
un <- un[un$ccode != 2, c("ccode", "year", "unga_ideal", "unga_dist_us", "NVotesFP")]
names(un)[5] <- "unga_votes"
lg("UNGA ideal points (Bailey, Strezhnev & Voeten; 1946-2025 file): %d state-years 1950-2025", nrow(un))

# ------------------------------------------------------- dollar integration: anchor currency and exchange rate regime
# Ilzetzki, Reinhart & Rogoff (IRR), monthly files 1946-2025 ("Beta Version:
# October 2026" on the authors' site; classification last updated 5 October
# 2026). Annual value = the modal month; a tie goes to the value held later in
# the year. Checked against the authors' annual file (1946-2016) and their
# stable release (1946-2019); results in the log.
# The anchor is IRR's reference currency, which is assigned to floating
# currencies as well (Mexico and Korea are USD-anchored), so the anchor alone is
# not a peg. usd_peg combines the anchor with the coarse regime (codes 1-2:
# no separate legal tender, currency board, peg, crawling peg or band within 2%).
irr_long <- function(f, sheet, key_rows, first_col) {
  m <- as.data.frame(read_excel(f, sheet = sheet, col_names = FALSE, .name_repair = "minimal", col_types = "text"))
  per_col <- first_col - 1
  rows <- grep("^[0-9]{4}M[0-9]+$", m[, per_col]); per <- m[rows, per_col]
  cols <- first_col:ncol(m)
  key <- vapply(cols, function(j) trimws(paste(na.omit(unlist(m[key_rows, j])), collapse = " ")), "")
  data.frame(key = rep(key, each = length(rows)), col = rep(cols, each = length(rows)),
             year = as.integer(substr(per, 1, 4)), month = as.integer(sub(".*M", "", per)),
             value = unlist(m[rows, cols]), stringsAsFactors = FALSE)
}
irr_annual <- function(x) {                                       # modal month; a tie goes to the value held latest
  x <- x[!is.na(x$value), ]
  g <- x[c("col", "key", "year", "value")]
  a <- merge(aggregate(list(n = rep(1L, nrow(x))), g, sum), aggregate(list(last = x$month), g, max))
  a <- a[order(a$col, a$year, -a$n, -a$last), ]
  a <- a[!duplicated(a[c("col", "year")]), ]
  data.frame(key = a$key, year = a$year, value = a$value, stringsAsFactors = FALSE)
}
irr_dir <- file.path(raw, "irr")
anc_m <- as.data.frame(read_excel(file.path(irr_dir, "Anchor_monthly_1946-2025.xlsx"), sheet = "Master", col_names = FALSE,
                                  .name_repair = "minimal", col_types = "text"))
r_iso <- which(anc_m[, 1] == "ISO3 Code")
anc_raw <- irr_annual(irr_long(file.path(irr_dir, "Anchor_monthly_1946-2025.xlsx"), "Master", r_iso, 2))
anc <- setNames(anc_raw, c("iso3", "year", "fx_anchor"))
cls_hdr <- function(f, sheet) {                                   # names span two header rows; independence year above them
  m <- as.data.frame(read_excel(f, sheet = sheet, col_names = FALSE, .name_repair = "minimal", col_types = "text", n_max = 7))
  data.frame(col = 3:ncol(m), indep = suppressWarnings(as.integer(unlist(m[2, -(1:2)]))),
             name = trimws(paste(ifelse(is.na(unlist(m[5, -(1:2)])), "", unlist(m[5, -(1:2)])),
                                 ifelse(is.na(unlist(m[6, -(1:2)])), "", unlist(m[6, -(1:2)])))))
}
fcls <- file.path(irr_dir, "ERA_Classification_Monthly_1940-2025.xlsx")
hdr_c <- cls_hdr(fcls, "Coarse")
crs <- irr_annual(irr_long(fcls, "Coarse", 5:6, 3)); names(crs) <- c("name", "year", "fx_regime_coarse")
fin_r <- irr_annual(irr_long(fcls, "Fine", 5:6, 3)); names(fin_r) <- c("name", "year", "fx_regime_fine")
cls <- merge(crs, fin_r, by = c("name", "year"), all = TRUE)
cls$iso3 <- countrycode(cls$name, "country.name", "iso3c", warn = FALSE,
                        custom_match = c(Liechtesntein = "LIE", Micronesia = "FSM", PNG = "PNG", `Netherlands Antilles` = "ANT"))
nm_iso <- unique(cls[, c("name", "iso3")])
stopifnot(!anyDuplicated(na.omit(nm_iso$iso3)))
anc_nm <- setNames(unlist(anc_m[r_iso + 1, -1]), unlist(anc_m[r_iso, -1]))   # the anchor file's own country names
lg("IRR classification: %d countries; names not mapped to ISO3: %s; mapped names differing from the anchor file's name for that code: %s",
   nrow(nm_iso), paste(nm_iso$name[is.na(nm_iso$iso3)], collapse = "; "),
   paste(with(nm_iso[!is.na(nm_iso$iso3) & nm_iso$name != anc_nm[nm_iso$iso3], ], paste0(name, "=", iso3, " (", anc_nm[iso3], ")")), collapse = "; "))
cls$indep <- hdr_c$indep[match(cls$name, hdr_c$name)]
for (v in c("fx_regime_coarse", "fx_regime_fine")) cls[[v]] <- suppressWarnings(as.integer(cls[[v]]))   # "MISSING", "n.a." -> NA
irr <- merge(anc, cls[, c("iso3", "year", "indep", "fx_regime_coarse", "fx_regime_fine")], by = c("iso3", "year"), all = TRUE)
irr$indep <- ave(irr$indep, irr$iso3, FUN = function(v) if (all(is.na(v))) NA_integer_ else max(v, na.rm = TRUE))
irr$fx_anchor[irr$fx_anchor %in% c("n.a.", "Freely_falling")] <- NA   # no reference currency, or excluded while freely falling
# Years before independence describe a territory, not a state (Serbia's column
# codes "no separate legal tender" through 1996), so they are dropped, except
# the Czech column, which carries Czechoslovakia's koruna before 1993.
pre <- !is.na(irr$indep) & irr$year < irr$indep & irr$iso3 != "CZE"
irr <- irr[!pre & !grepl("^X_", irr$iso3) & irr$year %in% yrs, ]   # X_SUN, X_YUG, X_CSK: RUB placeholders, not used
irr$ccode <- iso_cow(irr$iso3, irr$year)
irr$ccode[irr$iso3 == "CZE" & irr$year <= 1992] <- 315
irr$ccode[irr$iso3 == "VNM" & irr$year <= 1975] <- NA              # which Vietnam is not stated
irr <- irr[!is.na(irr$ccode), ]
irr$usd_anchor <- ifelse(is.na(irr$fx_anchor), NA_integer_, as.integer(irr$fx_anchor == "USD"))
irr$usd_peg <- with(irr, ifelse(is.na(fx_regime_coarse) | fx_regime_coarse == 6, NA_integer_,
                         ifelse(fx_regime_coarse >= 3, 0L, ifelse(is.na(fx_anchor), NA_integer_, as.integer(fx_anchor == "USD")))))
irr <- irr[, c("ccode", "year", "fx_anchor", "usd_anchor", "fx_regime_coarse", "fx_regime_fine", "usd_peg")]
stopifnot(!anyDuplicated(paste(irr$ccode, irr$year)))
lg("IRR anchor and regime (monthly to annual by modal month): %d state-years %d-%d; USD pegs: %s", nrow(irr), min(irr$year), max(irr$year),
   paste(sapply(c(1950, 1970, 1990, 2010, 2025), function(y) paste0(y, " ", sum(irr$usd_peg[irr$year == y], na.rm = TRUE))), collapse = "; "))
# checks: the authors' annual file (1946-2016) and stable monthly release (1946-2019)
a16 <- as.data.frame(read_excel(file.path(irr_dir, "Anchor_annual_1946-2016.xlsx"), sheet = "Master", col_names = FALSE,
                                .name_repair = "minimal", col_types = "text"))
r16 <- which(a16[, 1] == "ISO3 Code"); yr16 <- grep("^[0-9]{4}$", a16[, 1])
a16 <- data.frame(iso3 = rep(unlist(a16[r16, -1]), each = length(yr16)), year = as.integer(a16[yr16, 1]),
                  v16 = unlist(a16[yr16, -1]), stringsAsFactors = FALSE)
j <- merge(a16, setNames(anc_raw, c("iso3", "year", "v25")), by = c("iso3", "year"))
lg("  Check: annualized anchor matches the authors' annual file (1946-2016) in %.1f%% of %d country-years",
   100 * mean(j$v16 == j$v25, na.rm = TRUE), sum(!is.na(j$v16)))
st <- irr_long(file.path(irr_dir, "Anchor_monthly_1946-2019.xlsx"), "Master", r_iso, 2)
bt <- irr_long(file.path(irr_dir, "Anchor_monthly_1946-2025.xlsx"), "Master", r_iso, 2)
k2 <- merge(st, bt, by = c("key", "year", "month"))
lg("  Check: beta and stable releases agree on the monthly anchor in %.2f%% of %d country-months (1946-2019)",
   100 * mean(k2$value.x == k2$value.y, na.rm = TRUE), sum(!is.na(k2$value.x)))
cs <- irr_long(file.path(irr_dir, "ERA_Classification_Monthly_1940-2019.xlsx"), "Coarse", 5:6, 3)
cb <- irr_long(fcls, "Coarse", 5:6, 3)
k3 <- merge(cs, cb, by = c("key", "year", "month"))
lg("  Check: beta and stable releases agree on the monthly coarse regime in %.2f%% of %d country-months (1946-2019)",
   100 * mean(k3$value.x == k3$value.y, na.rm = TRUE), sum(!is.na(k3$value.x)))

# ------------------------------------------------------- dollar integration, check measure: dollar share of external debt
# World Bank International Debt Statistics (source 6, December 2025 release),
# DT.CUR.USDL.ZS: share of long-term public and publicly guaranteed external
# debt contracted in US dollars, counterpart "World". Reporting countries only
# (low- and middle-income debtors): high-income states are not covered.
ids <- fromJSON(file.path(snap, "ids_DT.CUR.USDL.ZS_2026-10-29.json"), simplifyVector = FALSE)
idv <- do.call(rbind, lapply(ids$source$data, function(r) {
  if (is.null(r$value)) return(NULL)
  g <- setNames(lapply(r$variable, function(x) x$id), vapply(r$variable, function(x) x$concept, ""))
  data.frame(iso3 = g$Country, year = as.integer(sub("^YR", "", g$Time)), usd_debt_share = as.numeric(r$value))
}))
idv <- idv[idv$year %in% yrs, ]
idv$ccode <- iso_cow(idv$iso3, idv$year)
nm_id <- unique(idv$iso3[is.na(idv$ccode)])
idv <- idv[!is.na(idv$ccode), c("ccode", "year", "usd_debt_share")]
stopifnot(!anyDuplicated(paste(idv$ccode, idv$year)))
lg("Dollar share of PPG external debt (IDS, %s release): %d state-years %d-%d, %d states; codes not mapped (regional aggregates): %d",
   ids$lastupdated, nrow(idv), min(idv$year), max(idv$year), length(unique(idv$ccode)), length(nm_id))

# ------------------------------------------------------- extractive value: physical endowment (oil, gas, coal production)
# Our World in Data energy dataset (Energy Institute Statistical Review and
# other sources), TWh of primary energy. Successor and predecessor series are
# assigned by year: USSR to 365 through 1991, Russia from 1992; Yugoslavia to
# 345 through 1991, Serbia from 1992; Czechoslovakia to 315 through 1992;
# Germany (reported for its present territory) to 260 through 1990 and 255
# after; Vietnam only from 1976.
ow <- read.csv(file.path(raw, "owid/owid-energy-data.csv"), stringsAsFactors = FALSE)
ow <- ow[ow$year %in% yrs, c("country", "iso_code", "year", "oil_production", "gas_production", "coal_production")]
names(ow)[4:6] <- c("oil_prod_twh", "gas_prod_twh", "coal_prod_twh")
ow$ccode <- NA_integer_
hist <- c(USSR = 365, Yugoslavia = 345, Czechoslovakia = 315)
h <- ow$country %in% names(hist)
ow$ccode[h] <- hist[ow$country[h]]
st_ <- nzchar(ow$iso_code) & !grepl("^OWID", ow$iso_code)
ow$ccode[st_] <- iso_cow(ow$iso_code[st_], ow$year[st_])
ow$ccode[ow$iso_code == "RUS" & ow$year <= 1991] <- NA            # reconstructed present-day territory; the USSR row holds the state
ow$ccode[ow$iso_code == "SRB" & ow$year <= 1991] <- NA
ow$ccode[ow$country == "Yugoslavia" & ow$year >= 1992] <- NA
ow$ccode[ow$country == "Czechoslovakia" & ow$year >= 1993] <- NA
ow$ccode[ow$iso_code == "VNM" & ow$year <= 1975] <- NA
ow$ccode[ow$iso_code == "YEM" & ow$year < 1990] <- NA            # unified-territory series before unification
energy <- ow[!is.na(ow$ccode) & rowSums(!is.na(ow[, 4:6])) > 0, c("ccode", "year", "oil_prod_twh", "gas_prod_twh", "coal_prod_twh")]
stopifnot(!anyDuplicated(paste(energy$ccode, energy$year)))
lg("Energy production (OWID): %d state-years; states with oil data by year: %s", nrow(energy),
   paste(sapply(c(1950, 1965, 1985, 2016, 2017, 2024), function(y) paste0(y, " ", sum(energy$year == y & !is.na(energy$oil_prod_twh)))), collapse = "; "))
# Fixed endowment: the highest annual oil plus gas production in 1985-1994,
# before the financial channel's itemized record (1995-), for the territory
# each state holds in 1995 (Russia, Serbia, Czechia and unified Germany use
# their own present-territory series). States formed after 1994 use their
# first five years of data, flagged.
ow$og <- ow$oil_prod_twh + ow$gas_prod_twh
terr <- ow[nzchar(ow$iso_code) & !grepl("^OWID", ow$iso_code) & !is.na(ow$og), ]
terr$ccode95 <- iso_cow(terr$iso_code, pmax(terr$year, 1995))
endow <- do.call(rbind, lapply(split(terr, terr$ccode95), function(z) {
  w <- z[z$year %in% 1985:1994, ]
  if (nrow(w)) return(data.frame(ccode = z$ccode95[1], endow_oilgas_twh = max(w$og), endow_mean = mean(w$og),
                                 endow_window = paste0(min(w$year), "-", max(w$year))))
  w <- head(z[order(z$year), ], 5)
  data.frame(ccode = z$ccode95[1], endow_oilgas_twh = max(w$og), endow_mean = mean(w$og),
             endow_window = paste0(min(w$year), "-", max(w$year), " (no data 1985-1994; first five years with data)"))
}))
# states that ended before 1995: their own series, 1985 to their last year
gone <- do.call(rbind, lapply(list(c(315, "Czechoslovakia"), c(260, "Germany")), function(p) {
  z <- ow[ow$country == p[2] & ow$year %in% 1985:1994 & ow$ccode %in% as.integer(p[1]), ]
  data.frame(ccode = as.integer(p[1]), endow_oilgas_twh = max(z$og), endow_mean = mean(z$og),
             endow_window = paste0(min(z$year), "-", max(z$year)))
}))
endow <- rbind(endow, gone)
endow <- endow[!is.na(endow$ccode), ]
stopifnot(!anyDuplicated(endow$ccode))
big <- endow[endow$ccode != 2, ]; big <- big[order(-(big$endow_oilgas_twh - big$endow_mean)), ][1:5, ]
lg("Endowment (max annual oil+gas TWh, 1985-1994): %d states; largest: %s", nrow(endow),
   paste(head(setdiff(endow$ccode[order(-endow$endow_oilgas_twh)], 2), 8), collapse = ", "))
lg("  Peak exceeds the window mean most for (ccode: peak vs mean): %s",
   paste(sprintf("%d: %.0f vs %.0f", big$ccode, big$endow_oilgas_twh, big$endow_mean), collapse = "; "))
lg("  States with no data in 1985-1994 (first five years with data used): %s",
   paste(sprintf("%d (%s)", endow$ccode, sub(" .*", "", endow$endow_window))[grepl("first five", endow$endow_window)], collapse = ", "))
endow$endow_mean <- NULL

# ------------------------------------------------------- production capability: economic complexity
# Growth Lab (Harvard), Atlas of Economic Complexity, SITC Rev. 2 country-year
# file (Dataverse doi:10.7910/DVN/H8SFD2, CC0). ECI is standardized within each
# year: it ranks a state against others that year, not against itself over time.
ec <- read.csv(file.path(raw, "eci/sitc_country_year.csv"), stringsAsFactors = FALSE)
ec <- ec[!is.na(ec$eci) & ec$year %in% yrs, ]
ec$ccode <- iso_cow(ec$country_iso3_code, ec$year)
ec$ccode[ec$country_iso3_code == "VNM" & ec$year <= 1975] <- NA
nm_ec <- unique(ec$country_iso3_code[is.na(ec$ccode)])
ec <- ec[!is.na(ec$ccode), c("ccode", "year", "eci", "diversity")]
names(ec) <- c("ccode", "year", "eci_sitc", "export_diversity")
stopifnot(!anyDuplicated(paste(ec$ccode, ec$year)))
lg("Economic complexity (Atlas, SITC): %d state-years %d-%d; Atlas economies not mapped to a COW state: %d (territories)",
   nrow(ec), min(ec$year), max(ec$year), length(nm_ec))

# ------------------------------------------------------- assemble on the frame
cy <- frame
cy <- merge(cy, atop, by = c("ccode", "year"), all.x = TRUE)
cy$us_defense_pact[is.na(cy$us_defense_pact)] <- 0L              # ATOP lists every alliance: no listing is no pact
cy <- merge(cy, un, by = c("ccode", "year"), all.x = TRUE)       # not a UN member or no votes: missing
cy <- merge(cy, rents, by = c("ccode", "year"), all.x = TRUE)    # outside WDI coverage: missing
cy <- merge(cy, irr, by = c("ccode", "year"), all.x = TRUE)      # not classified by IRR: missing
cy <- merge(cy, endow, by = "ccode", all.x = TRUE)               # time-invariant
cy <- merge(cy, ec, by = c("ccode", "year"), all.x = TRUE)       # not in the Atlas: missing
cy <- merge(cy, idv, by = c("ccode", "year"), all.x = TRUE)      # not an IDS reporter: missing
offs <- sapply(list(UNGA = un, rents = rents, IRR = irr, energy = energy, ECI = ec, IDS = idv), function(s)
  length(setdiff(paste(s$ccode, s$year), paste(frame$ccode, frame$year))))
lg("Merged on the frame (%d state-years). Source rows outside the frame: %s (non-COW members or years before COW membership)",
   nrow(cy), paste(names(offs), offs, collapse = ", "))
lg("Coverage in the frame (of %d): defense pact %d; UNGA %d; resource rents %d; USD anchor %d; regime %d; USD peg %d; USD debt share %d; endowment %d; ECI %d",
   nrow(cy), sum(!is.na(cy$us_defense_pact)), sum(!is.na(cy$unga_dist_us)), sum(!is.na(cy$nat_res_rents_gdp)),
   sum(!is.na(cy$usd_anchor)), sum(!is.na(cy$fx_regime_coarse)), sum(!is.na(cy$usd_peg)), sum(!is.na(cy$usd_debt_share)),
   sum(!is.na(cy$endow_oilgas_twh)), sum(!is.na(cy$eci_sitc)))
cy <- cy[order(cy$ccode, cy$year), ]
write.csv(cy, file.path(outd, "covariates_country_year.csv"), row.names = FALSE, na = "")
# Yearly production is the Energy Institute's data, whose terms require
# permission for extensive reproduction: it is written to a local file that is
# not committed (v2/output/local/), keyed on the same frame. The endowment above
# is a derived statistic and is published.
en <- merge(frame, energy, by = c("ccode", "year"), all.x = TRUE)
dir.create(file.path(outd, "local"), showWarnings = FALSE)
write.csv(en[order(en$ccode, en$year), ], file.path(outd, "local", "energy_production_country_year.csv"), row.names = FALSE, na = "")
lg("Wrote local/energy_production_country_year.csv (not committed): oil production reported in %d of %d state-years", sum(!is.na(en$oil_prod_twh)), nrow(en))
lg("Wrote covariates_year.csv (%d rows) and covariates_country_year.csv (%d rows)", nrow(covy), nrow(cy))
lg("Not yet built: minerals endowment, US as target (Q15), trade channel")
