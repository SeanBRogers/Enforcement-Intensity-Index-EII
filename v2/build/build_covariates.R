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

# ------------------------------------------------------- assemble on the frame
cy <- frame
cy <- merge(cy, atop, by = c("ccode", "year"), all.x = TRUE)
cy$us_defense_pact[is.na(cy$us_defense_pact)] <- 0L              # ATOP lists every alliance: no listing is no pact
cy <- merge(cy, un, by = c("ccode", "year"), all.x = TRUE)       # not a UN member or no votes: missing
cy <- merge(cy, rents, by = c("ccode", "year"), all.x = TRUE)    # outside WDI coverage: missing
off_un <- setdiff(paste(un$ccode, un$year), paste(frame$ccode, frame$year))
off_rt <- setdiff(paste(rents$ccode, rents$year), paste(frame$ccode, frame$year))
lg("Merged on the frame (%d state-years). Source rows outside the frame: UNGA %d, rents %d (non-COW members or years before COW membership)",
   nrow(cy), length(off_un), length(off_rt))
lg("Coverage in the frame: defense pact %d of %d; UNGA %d; resource rents %d",
   sum(!is.na(cy$us_defense_pact)), nrow(cy), sum(!is.na(cy$unga_dist_us)), sum(!is.na(cy$nat_res_rents_gdp)))
cy <- cy[order(cy$ccode, cy$year), ]
write.csv(cy, file.path(outd, "covariates_country_year.csv"), row.names = FALSE, na = "")
lg("Wrote covariates_year.csv (%d rows) and covariates_country_year.csv (%d rows)", nrow(covy), nrow(cy))
lg("Not yet built: dollar integration (measure to be chosen, Q6), US as target (Q15), trade channel")
