# EII Codebook — `EII_Panel_Definitive.csv`

Version 2026-10-17. Describes the panel as it now stands, after the
source audit of 2026-10-17. Every cell changed by that audit is listed in
`panel_corrections.csv` (state, year, variable, original value, new
value, source, reason), so the original panel can be reconstructed from
this file and the log.

Status of each entry:

- **Verified** — reproduced from the panel, or matched value by value
  against the named external source.
- **Documented** — stated in this repository but not independently
  checked.
- **Open** — not documented and not recoverable from the data. Listed
  at the end.

External checks are code in this repository: `verify_sources.R`
(Polity5 `p5v2018.xls`; V-Dem v16 via the `vdemdata` package 16.0; UNGA
ideal points, Harvard Dataverse doi:10.7910/DVN/LEJUQZ, file 11824371; FRED
`FYOIGDA188S`; World Bank WDI API) and `degradation_audit.R` (UCDP/PRIO
Armed Conflict Dataset v25.1). Both were run on 2026-10-17 on the
estimation machine and pass (`verify_sources_R.Rout`,
`degradation_audit_R.Rout`). Every descriptive number in this file
(ranges, missing counts, category counts, zero shares, spans, the DV
reconstructions, the estimation-sample exclusions and the audit counts)
is computed and checked by `codebook_checks.R` (`codebook_checks_R.Rout`),
except where an entry says otherwise.

---

## Unit, coverage, frame

| Item | Value | Status |
|---|---|---|
| Unit of observation | Country-year | Verified |
| Rows / columns | 942 / 24 | Verified (`validate.R`) |
| Years | 1945–2025 | Verified |
| States | 43 names, 44 codes. Nicaragua's two sanctions episodes are coded separately, `NIC` (1985–1990) and `NIC_2` (2018–2025), under one name. Rhodesia (`RHO`, 1965–1979) and Zimbabwe (`ZWE`, 2003–2025) are listed as separate states; counted as one state, the frame has 42 | Verified |
| Frame | Only country-years under U.S. sanctions enter the panel (`under_sanctions` = 1 on every row). Unbalanced: 1 state in 1945, 27 in 2021, 28 in 2025 | Verified |
| 2022–2025 rows | Not built under the extension protocol; the code that produced them is not in this repository; no estimate uses them. See `PREREGISTRATION.md` | Documented |
| Estimation sample | 538 complete cases, 33 states, 1970–2021 (V-Dem). Ends in 2021 because `resource_density` ends in 2021. Variables that alone exclude otherwise complete rows: `resource_density` 95, `friction` 30, the DV 4 | Verified (`validate.R`, `codebook_checks.R`) |

---

## Identifiers and sanctions program

| Variable | Values | Definition | Status |
|---|---|---|---|
| `country` | string, 43 values | State name as stored, e.g. `Germany (East)` for `DDR`, `Rhodesia/Zimbabwe` for `RHO`, `Yugoslavia/Serbia` for `SRB` | Verified |
| `iso3` | string, 44 values | ISO 3166-1 alpha-3. `DDR` (East Germany) and `RHO` (Southern Rhodesia) are withdrawn ISO codes (ISO 3166-3); `NIC_2` (Nicaragua, second episode) is a project code | Verified |
| `year` | 1945–2025 | Calendar year | Verified |
| `under_sanctions` | always 1 | Country-year is under a U.S. sanctions program | Verified (constant). Coding rule: Open |
| `scope` | comprehensive 589, targeted 341, sectoral 12 | Breadth of the program | Open |
| `stated_justification` | terrorism 264, national_security 262, democracy 198, human_rights 139, WMD 76, narcotics 3 | Justification stated for the program | Open |
| `legal_authority` | IEEPA 588, TWEA 256, TWEA/IEEPA 76, UNSCR 15, CAAA 7 | Legal basis of the program | Open |

---

## Enforcement layers (components of the DV)

Missing (8 rows each): Nicaragua's second episode, `NIC_2`, 2018–2025.
The original build gave it zero on every layer in every year, although
EO 13851 (November 2018) established the Nicaragua sanctions program;
the source joins failed for the `_2` code. The rows are marked not built
until the layers are re-pulled.

| Variable | Range | Definition | Source | Status |
|---|---|---|---|---|
| `layer1_ofac_events` | 0–15 | OFAC executive actions against the state in the year. Nonzero from 1979 | Federal Register, OFAC SDN | Documented. Event unit: Open |
| `layer2_multilateral` | 0–3,281 | Multilateral designations. Nonzero from 1980. 92.8% of all `eii_score` points | OpenSanctions, IMF MONA | Documented. Unit: Open |
| `layer3_agency_actions` | 0–45 | OFAC civil penalties. The source begins in 2003, so zeros before 2003 mean no source, not observed non-enforcement | OFAC civil penalties | Documented |
| `layer4_kinetic` | 0–154 | Kinetic operations. Nonzero 1950–2024; zero in every 2025 row, consistent with UCDP v25.1 ending in 2024, so 2025 zeros may mean no source | COW MID, UCDP/PRIO, UCDP GED | Documented. Source coverage by year, count vs. intensity weighting, and de-duplication across the three sources: Open |

**Unverified zeros (Open).** Six states are zero on all four layers
across their whole span: Eritrea 2010–2025, East Germany 1945–1990,
Cambodia 1975–1992, Rhodesia 1965–1979, Niger 2023–2025, South Africa
1985–1991. Cuba has zero Layer 1 events 1962–2025. These may be true
zeros under the layer definitions or failed joins; they cannot be
settled without the build code or a re-pull of the layer sources.

---

## Dependent variable and alternative constructions

| Variable | Range | Definition | Status |
|---|---|---|---|
| `eii_score` | 0–3,281 | `layer1 + layer2 + layer3 + layer4`, unweighted. Primary DV. 58.7% zeros across the 934 built rows; 49.6% zeros and variance/mean 1,124.9 in the estimation sample; maximum Bosnia 2012. Missing for `NIC_2` | Verified (exact on all 934 built rows) |
| `eii_rawcount` | 0–70 | Per-layer capped sum: `min(L1,10) + min(L2,50) + min(L3,20) + min(L4,20)` | Verified: reconstructed from the data, exact on all 934 built rows; each cap is the only value from 1 to 400 that reproduces the column. The column's maximum is 70, so a total cap of 70 or more cannot be ruled out. Rationale for the caps: Open |
| `eii_equal` | 0–4 | Number of layers with a nonzero value. Not identified under the ZINB (no overdispersion; the NB dispersion runs to its boundary) | Verified (exact on all 934 built rows) |
| `eii_financial` | 0–3,281 | `layer1 + layer2 + layer3` (excludes kinetic) | Verified (exact on all 934 built rows) |

---

## Covariates

| Variable | Range | Missing | Definition and source | Status |
|---|---|---|---|---|
| `fiscal_pressure` | 1.105–3.158 | 0 | U.S. federal outlays for net interest, % of GDP, fiscal-year basis. Office of Management and Budget via FRED `FYOIGDA188S`. One value per year for every state | Verified (within 0.0005 of FRED in all 81 years) |
| `degradation` | 0 / 1 (512 / 396) | 34 | 1 if an armed conflict (UCDP/PRIO ACD v25.1, intensity 1 or 2, any type) is located in the state that year (`gwno_loc`). Missing for 1945 and 2025 (outside ACD v25.1) and Hong Kong (no Gleditsch-Ward code) | Verified: rebuilt 2026-10-17; equal to the UCDP rebuild on all 908 codable rows (`degradation_audit.R`). The original column agreed on 88.8% of them and coded 102 conflict country-years as 0: Afghanistan 26, Pakistan 23, Cambodia 16, Rhodesia 9, Nicaragua 6, Laos 5, South Africa 5, North Korea 4, Liberia 3, Niger 2, Haiti, Panama and Sierra Leone 1 each |
| `resource_density` | 0–67.44 | 368 | Total natural resource rents, % of GDP. World Bank WDI `NY.GDP.TOTL.RT.ZS`. Ends 2021 | Verified (all 574 non-missing rows within 0.01 of current WDI) |
| `gdp_pc_log` | 3.133–10.898 | 251 | Natural log of GDP per capita in current U.S. dollars, WDI `NY.GDP.PCAP.CD` (nominal) | Verified to WDI revision noise: of 691 rows, 672 within 0.001 and 684 within 0.01 of current WDI |
| `vdem_electoral` | 0.056–0.707 | 4 | V-Dem Electoral Democracy Index, `v2x_polyarchy`, three decimals. Primary regime measure. The 4 missing are East Germany 1945–1948, before V-Dem's coverage | Verified: identical to V-Dem v16 on every row |
| `vdem_elections` | 0–0.782 | 4 | V-Dem Clean Elections Index, `v2xel_frefair` | Verified, as above |
| `polity` | −10 to 8 | 265 | Polity5 `polity2` (Marshall & Gurr 2020). Missing where `polity2` is missing (−66 foreign interruption; East Germany 1989–1990 at series end), after 2018 (Polity5 ends), and for Rhodesia and Hong Kong (not in Polity5). Entities: North Vietnam through 1975, Vietnam from 1976; Yugoslavia, then Serbia and Montenegro; Sudan through 2010, Sudan-North from 2011. Robustness measure, frequentist only | Verified (equal to Polity5 `polity2` on every row) |
| `friction` | 1.366–5.101 | 165 | Architectural Friction: absolute distance between the United States and the state in UNGA foreign-policy ideal points (`idealpointfp`; Bailey, Strezhnev & Voeten), lagged one year, from the July 2025 release (`IdealpointsJuly2025.tab`). Higher = more diplomatic non-alignment. Missing where the state has no ideal point for the prior year (e.g. not a UN member, or not voting) | Verified (rebuilt 2026-10-17; equal to the source on every row). The previous column came from an earlier, unidentified release (correlation 0.998 with this one) and lacked Serbia 1992–1993 and 2001–2003 and `NIC_2` |
| `trend` | 0–80 | 0 | `year − 1945` | Verified (exact on all rows) |

### Remaining source gaps

- WDI now publishes GDP per capita for some country-years the panel
  leaves empty, mostly in 2025 (not counted by a script in this
  repository). They belong to the extension build.

---

## Transformations used in estimation (not stored in the panel)

From `EII_pipeline.R` and `validate.R`:

- Each regime specification drops rows missing the DV, `degradation`,
  the regime measure, `friction`, `resource_density`, `gdp_pc_log` or
  `fiscal_pressure` (missing values are never filled with zero), then
  z-scores every continuous IV within that sample: `friction_z`,
  `resource_density_z`, `fiscal_pressure_z`, `gdp_pc_log_z`, `trend_z`,
  `regime_z`.
- `fric_x_fiscal = friction_z × fiscal_pressure_z`.

---

## Provenance

The code that built the panel from its sources is not in this
repository; every script here takes `EII_Panel_Definitive.csv` as given.
The reconstructions above were recovered from the data and the named
sources.

---

## Open items

1. Build code: add the panel build to the repository. Items 2–4 depend
   on it.
2. Re-pull the layers for `NIC_2`, and settle whether the six all-zero
   states and Cuba's Layer 1 zeros are true zeros.
3. Layer units and coverage: what counts as one Layer 1 event; the
   Layer 2 unit; how Layer 4 combines COW MID, UCDP/PRIO and GED, and
   whether it is a count or intensity-weighted; each source's coverage
   by year (including whether 2025 Layer 4 zeros are real); and the
   number of distinct sources (earlier documents said ten; the layer
   table names eight).
4. `under_sanctions`, `scope`, `stated_justification`,
   `legal_authority`: coding rules and source documents.
5. `eii_rawcount`: rationale for the caps 10 / 50 / 20 / 20.
