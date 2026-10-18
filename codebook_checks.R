# ==============================================================================
# CODEBOOK CHECKS: EVERY DESCRIPTIVE NUMBER IN CODEBOOK.md, COMPUTED
# ==============================================================================
# CODEBOOK.md states ranges, missing counts, category counts, zero shares and
# reconstruction rules for EII_Panel_Definitive.csv. LAB.md rule 4 says no
# number travels unless a logged run of code in this repository produced it.
# This script computes each of those numbers, and the audit details LAB.md
# cites, from the panel, panel_corrections.csv and degradation_audit.csv, prints it, and checks it against the value the
# codebook states. Any FAIL means the codebook and the data disagree.
#
# Base R only. Added 2026-10-17.
# ==============================================================================

df <- read.csv("EII_Panel_Definitive.csv", stringsAsFactors = FALSE)
pc <- read.csv("panel_corrections.csv", stringsAsFactors = FALSE)

PASS <- 0; FAIL <- 0
chk <- function(label, actual, expected) {
  ok <- isTRUE(all.equal(actual, expected, check.attributes = FALSE))
  if (ok) PASS <<- PASS + 1 else FAIL <<- FAIL + 1
  cat(sprintf("  %s  %-46s %s%s\n", if (ok) "PASS" else "FAIL", label,
              paste(format(actual), collapse = " / "),
              if (ok) "" else paste0("   (codebook: ", paste(format(expected), collapse = " / "), ")")))
}
rng <- function(x) c(min(x, na.rm = TRUE), max(x, na.rm = TRUE))
nmiss <- function(x) sum(is.na(x))

cat("\n[1] UNIT, COVERAGE, FRAME\n")
chk("rows", nrow(df), 942)
chk("columns", ncol(df), 24)
chk("years", rng(df$year), c(1945, 2025))
chk("state names", length(unique(df$country)), 43)
chk("codes (iso3)", length(unique(df$iso3)), 44)
chk("under_sanctions = 1 on every row", all(df$under_sanctions == 1), TRUE)
chk("states in 1945 / 2021 / 2025",
    c(length(unique(df$country[df$year == 1945])),
      length(unique(df$country[df$year == 2021])),
      length(unique(df$country[df$year == 2025]))), c(1, 27, 28))

cat("\n[2] PROGRAM VARIABLES\n")
chk("scope: comprehensive / targeted / sectoral",
    as.vector(table(df$scope)[c("comprehensive", "targeted", "sectoral")]), c(589, 341, 12))
chk("justification: terrorism / natsec / democracy",
    as.vector(table(df$stated_justification)[c("terrorism", "national_security", "democracy")]),
    c(264, 262, 198))
chk("justification: human_rights / WMD / narcotics",
    as.vector(table(df$stated_justification)[c("human_rights", "WMD", "narcotics")]), c(139, 76, 3))
chk("authority: IEEPA / TWEA / TWEA/IEEPA",
    as.vector(table(df$legal_authority)[c("IEEPA", "TWEA", "TWEA/IEEPA")]), c(588, 256, 76))
chk("authority: UNSCR / CAAA",
    as.vector(table(df$legal_authority)[c("UNSCR", "CAAA")]), c(15, 7))

cat("\n[3] ENFORCEMENT LAYERS\n")
L <- c("layer1_ofac_events", "layer2_multilateral", "layer3_agency_actions", "layer4_kinetic")
miss_rows <- df$iso3[is.na(df$layer1_ofac_events)]
chk("layers missing only for NIC_2 (8 rows)", c(length(miss_rows), unique(miss_rows)), c("8", "NIC_2"))
for (l in L) chk(paste(l, "missing"), nmiss(df[[l]]), 8)
chk("layer1 range", rng(df$layer1_ofac_events), c(0, 15))
chk("layer2 range", rng(df$layer2_multilateral), c(0, 3281))
chk("layer3 range", rng(df$layer3_agency_actions), c(0, 45))
chk("layer4 range", rng(df$layer4_kinetic), c(0, 154))
first_nz <- function(l) min(df$year[!is.na(df[[l]]) & df[[l]] > 0])
last_nz  <- function(l) max(df$year[!is.na(df[[l]]) & df[[l]] > 0])
chk("layer1 first nonzero year", first_nz("layer1_ofac_events"), 1979)
chk("layer2 first nonzero year", first_nz("layer2_multilateral"), 1980)
chk("layer3 first nonzero year", first_nz("layer3_agency_actions"), 2003)
chk("layer4 nonzero years", c(first_nz("layer4_kinetic"), last_nz("layer4_kinetic")), c(1950, 2024))
chk("layer4 zero in every 2025 row", all(df$layer4_kinetic[df$year == 2025] == 0, na.rm = TRUE), TRUE)
b <- df[!is.na(df$eii_score), ]
chk("layer2 share of all eii_score points (%)",
    round(100 * sum(b$layer2_multilateral) / sum(b$eii_score), 1), 92.8)
# Codes, not names: the panel names East Germany "Germany (East)" and
# Rhodesia (RHO) "Rhodesia/Zimbabwe"
allzero <- aggregate(b$eii_score, by = list(iso3 = b$iso3), FUN = function(x) all(x == 0))
chk("codes zero on all four layers, whole span",
    sort(allzero$iso3[allzero$x]),
    sort(c("ERI", "DDR", "KHM", "RHO", "NER", "ZAF")))
cuba <- df[df$country == "Cuba", ]
chk("Cuba Layer 1: years and total events",
    c(min(cuba$year), max(cuba$year), sum(cuba$layer1_ofac_events)), c(1962, 2025, 0))

cat("\n[4] DEPENDENT VARIABLE AND ALTERNATIVES (934 built rows)\n")
chk("built rows", nrow(b), 934)
chk("eii_score range", rng(b$eii_score), c(0, 3281))
chk("eii_score zeros among built rows (%)", round(100 * mean(b$eii_score == 0), 1), 58.7)
mx <- b[which.max(b$eii_score), ]
chk("eii_score maximum at", c(mx$country, mx$year), c("Bosnia", "2012"))
chk("eii_score = layer1 + layer2 + layer3 + layer4",
    all(b$eii_score == rowSums(b[, L])), TRUE)
cap <- pmin(b$layer1_ofac_events, 10) + pmin(b$layer2_multilateral, 50) +
       pmin(b$layer3_agency_actions, 20) + pmin(b$layer4_kinetic, 20)
chk("eii_rawcount = capped sum 10/50/20/20", all(b$eii_rawcount == cap), TRUE)
chk("eii_rawcount range", rng(b$eii_rawcount), c(0, 70))
chk("eii_equal = number of nonzero layers", all(b$eii_equal == rowSums(b[, L] > 0)), TRUE)
chk("eii_equal range", rng(b$eii_equal), c(0, 4))
chk("eii_financial = layer1 + layer2 + layer3",
    all(b$eii_financial == rowSums(b[, L[1:3]])), TRUE)
chk("eii_financial range", rng(b$eii_financial), c(0, 3281))

cat("\n[5] COVARIATES: RANGE AND MISSING\n")
chk("fiscal_pressure range / missing", c(rng(df$fiscal_pressure), nmiss(df$fiscal_pressure)), c(1.105, 3.158, 0))
chk("degradation 0 / 1 / missing",
    c(sum(df$degradation == 0, na.rm = TRUE), sum(df$degradation == 1, na.rm = TRUE), nmiss(df$degradation)),
    c(512, 396, 34))
chk("resource_density range / missing", c(rng(df$resource_density), nmiss(df$resource_density)), c(0, 67.44, 368))
chk("resource_density last year", max(df$year[!is.na(df$resource_density)]), 2021)
chk("gdp_pc_log range / missing", c(rng(df$gdp_pc_log), nmiss(df$gdp_pc_log)), c(3.133, 10.898, 251))
chk("vdem_electoral range / missing", c(rng(df$vdem_electoral), nmiss(df$vdem_electoral)), c(0.056, 0.707, 4))
chk("vdem_elections range / missing", c(rng(df$vdem_elections), nmiss(df$vdem_elections)), c(0, 0.782, 4))
chk("polity range / missing", c(rng(df$polity), nmiss(df$polity)), c(-10, 8, 265))
chk("friction range (3 dp) / missing", c(round(rng(df$friction), 3), nmiss(df$friction)), c(1.366, 5.101, 165))
chk("trend = year - 1945 on every row", all(df$trend == df$year - 1945), TRUE)

cat("\n[6] ESTIMATION SAMPLE (V-Dem complete cases)\n")
req <- c("eii_score", "degradation", "vdem_electoral", "friction",
         "resource_density", "gdp_pc_log", "fiscal_pressure")
cc <- complete.cases(df[, req])
chk("complete cases / states / years",
    c(sum(cc), length(unique(df$country[cc])), min(df$year[cc]), max(df$year[cc])),
    c(538, 33, 1970, 2021))
alone <- function(v) sum(is.na(df[[v]]) & complete.cases(df[, setdiff(req, v)]))
chk("rows excluded by resource_density alone", alone("resource_density"), 95)
chk("rows excluded by friction alone", alone("friction"), 30)
chk("rows excluded by the DV alone", alone("eii_score"), 4)

cat("\n[7] AUDIT LOG (panel_corrections.csv)\n")
chk("cells changed", nrow(pc), 1434)
vc <- table(pc$variable)
chk("vdem_electoral / vdem_elections cells filled",
    as.vector(vc[c("vdem_electoral", "vdem_elections")]), c(77, 77))
chk("degradation cells changed", as.vector(vc["degradation"]), 136)
cat("  INFO  cells changed by variable:\n")
print(vc[order(-vc)])


cat("\n[8] AUDIT DETAILS CITED IN LAB.md AND CODEBOOK.md\n")
# Spans of the codes the documents name
span <- function(code) range(df$year[df$iso3 == code])
for (x in list(c("NIC", 1985, 1990), c("NIC_2", 2018, 2025), c("RHO", 1965, 1979),
               c("ZWE", 2003, 2025), c("ERI", 2010, 2025), c("DDR", 1945, 1990),
               c("KHM", 1975, 1992), c("NER", 2023, 2025), c("ZAF", 1985, 1991)))
  chk(paste(x[1], "years in the panel"), span(x[1]), as.numeric(x[2:3]))
chk("vdem_electoral missing rows are DDR 1945-1948",
    paste(df$iso3, df$year)[is.na(df$vdem_electoral)], paste("DDR", 1945:1948))

# degradation: the 102 conflict country-years the original column coded 0
da <- read.csv("degradation_audit.csv", stringsAsFactors = FALSE)
dis <- da[!is.na(da$degradation_ucdp) & da$degradation_original == 0 & da$degradation_ucdp == 1, ]
by_code <- table(dis$iso3)
want <- c(AFG = 26, PAK = 23, KHM = 16, RHO = 9, NIC = 6, LAO = 5, ZAF = 5,
          PRK = 4, LBR = 3, NER = 2, HTI = 1, PAN = 1, SLE = 1)
chk("original 0 / UCDP 1, total", nrow(dis), 102)
chk("original 0 / UCDP 1, by code (AFG PAK KHM RHO NIC LAO ZAF PRK LBR NER HTI PAN SLE)",
    as.vector(by_code[names(want)]), as.vector(want))
chk("no other codes in that set", sort(names(by_code)), sort(names(want)))
est <- merge(df[cc, c("iso3", "year")], dis[, c("iso3", "year")])
chk("Pakistan rows of that set in the estimation sample: 2001-2021 except",
    setdiff(2001:2021, est$year[est$iso3 == "PAK"]), 2005)

# friction: correlation of the rebuilt column with the original
fr <- pc[pc$variable == "friction", c("iso3", "year", "old")]
key <- paste(df$iso3, df$year)
old_fr <- df$friction
hit <- match(paste(fr$iso3, fr$year), key)
old_fr[hit] <- suppressWarnings(as.numeric(fr$old))
both <- !is.na(df$friction) & !is.na(old_fr)
chk("cor(friction, original friction), 3 dp, rows",
    c(round(cor(df$friction[both], old_fr[both]), 3), sum(both)), c(0.998, 764))

fill <- fr[is.na(suppressWarnings(as.numeric(fr$old))), ]
chk("friction cells the audit filled",
    sort(paste(fill$iso3, fill$year)),
    sort(c(paste("SRB", c(1992, 1993, 2001:2003)), paste("NIC_2", 2018:2025))))
pol <- pc[pc$variable == "polity" & pc$iso3 == "AFG", ]
chk("polity: Afghanistan 2001-2013 originally -7, now missing",
    c(all(2001:2013 %in% pol$year),
      all(as.numeric(pol$old[pol$year %in% 2001:2013]) == -7),
      all(is.na(df$polity[df$iso3 == "AFG" & df$year %in% 2001:2013]))), c(TRUE, TRUE, TRUE))

# The pre-audit panel (every logged cell reverted) and its estimation sample
orig <- df
for (k in seq_len(nrow(pc))) {
  i <- which(orig$iso3 == pc$iso3[k] & orig$year == pc$year[k])
  orig[[pc$variable[k]]][i] <- suppressWarnings(as.numeric(pc$old[k]))
}
cc0 <- complete.cases(orig[, req])
added <- setdiff(paste(df$iso3, df$year)[cc], paste(orig$iso3, orig$year)[cc0])
dropped <- setdiff(paste(orig$iso3, orig$year)[cc0], paste(df$iso3, df$year)[cc])
chk("pre-audit estimation sample N", sum(cc0), 535)
chk("rows added by the audit", sort(added), paste("SRB", 2001:2003))
chk("rows dropped by the audit", length(dropped), 0)

# eii_equal: no overdispersion
ee <- df$eii_equal[cc]
cat(sprintf("  INFO  eii_equal variance / mean in the estimation sample: %.3f\n", var(ee) / mean(ee)))
chk("eii_equal variance / mean below 1 (no overdispersion)", var(ee) / mean(ee) < 1, TRUE)

# eii_rawcount caps: each is the only value that reproduces the column
caps <- c(10, 50, 20, 20)
rc <- function(cp) pmin(b[[L[1]]], cp[1]) + pmin(b[[L[2]]], cp[2]) +
                   pmin(b[[L[3]]], cp[3]) + pmin(b[[L[4]]], cp[4])
for (j in 1:4) {
  ok <- sapply(1:400, function(v) { cp <- caps; cp[j] <- v; all(rc(cp) == b$eii_rawcount) })
  chk(paste("only cap reproducing eii_rawcount,", L[j], "(1-400 tried)"), which(ok), caps[j])
}
chk("eii_rawcount maximum (a total cap of 70 or more cannot be ruled out)",
    max(b$eii_rawcount), 70)

cat("\n==================================================================\n")
cat(sprintf("RESULT: %d passed, %d failed\n", PASS, FAIL))
cat("==================================================================\n")
if (FAIL > 0) quit(status = 1)
