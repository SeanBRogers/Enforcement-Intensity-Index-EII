# EII v2 — Codebook (partial release, 2026-10-27)

**Status: PARTIAL. Not for estimation.** This release contains the frame, the
US sanctions flag, and the kinetic, posture and penalties channels. The
financial (SDN) channel, the multilateral block, the burden blocks and the
covariates are not yet built (`BUILD_PROTOCOL.md`, section 7).

File: `v2/output/EII_v2_partial.csv`. Built by `v2/build/run_all.R`
(`build_penalties.R`, then `build_v2_partial.R`) from the sources in
`v2/sources/MANIFEST.csv` and `v2/sources/MANIFEST_ofac.csv` (fetch and verify
with `v2/build/fetch_sources.R`). Build logs: `v2/output/build_log.txt`,
`v2/output/penalties_log.txt`.

## Unit and frame

| | |
|---|---|
| Unit | Target country-year |
| States | Every member of the COW state system (v2024), 1950–2024; 2025 carries forward the 2024 membership. The United States is excluded as a target |
| Rows | 11,916 country-years, 201 states, 1950–2025 |
| Keys | `ccode` (COW), `year`; `stateabb`, `statenme` from COW |
| Missing vs zero | A blank cell means the source does not cover that country-year. A zero means the source covers it and records nothing (Rule 3) |

In 1990 both the German Federal Republic (260) and Germany (255) have rows, as
in COW.

## Variables

| Variable | Definition | Source | Coverage | Misreporting direction |
|---|---|---|---|---|
| `under_sanctions_us` | 1 if any GSDB case naming the United States among its senders is active in the year (case begin to end year, inclusive), else 0 | GSDB v4 | 1950–2023; blank 2024–2025 (v4 codes ongoing cases as ending in 2023) | Researcher-coded from public sources; covert measures absent. Recent human-rights and anti-corruption programs raise counts after about 2020 (66 states in 2020, 99 in 2023); treat that rise as a possible recording surge |
| `us_sanction_cases` | Number of such active cases | GSDB v4 | as above | as above |
| `kin_vs_state` | 1 if the US is a party to an armed conflict against this state's government in the year: an interstate conflict with this state on the other side, or a conflict in which the US backs the side opposing this government | UCDP/PRIO ACD v26.1 | 1950–2025 | 25-battle-death threshold: misses low-intensity, covert and stand-off US action (e.g., Iraq no-fly-zone strikes 1992–2002) |
| `kin_vs_state_intensity` | Highest UCDP intensity among those conflicts: 0 none, 1 = 25–999 battle deaths, 2 = 1,000 or more | UCDP/PRIO ACD v26.1 | 1950–2025 | as above |
| `kin_in_state` | 1 if the US fights alongside this state's government, inside its territory, against non-state actors | UCDP/PRIO ACD v26.1 | 1950–2025 | as above; UCDP's episode coding starts the US-backed Afghanistan episode in 2003, so 2002 reads 0 |
| `kin_in_state_intensity` | Highest UCDP intensity among those conflicts (0, 1, 2) | UCDP/PRIO ACD v26.1 | 1950–2025 | as above |
| `posture_troops_ad` | US active-duty troops located in the country (sum of location rows) | `troopdata` 1.1.0 | 1950–2025; blank where the source has no row, and blank in US-party conflict country-years from 2018 | Official reports omit war-zone deployments from about 2018, and the source fills them with 0 (e.g., Syria 2022 = 0, Iraq 2025 = 0); those cells are set blank. Guard and reserve troops are excluded |
| `posture_note` | Reason a posture cell is blank | build | — | — |
| `pen_program_count` | OFAC civil penalties, settlements and findings of violation published in the year whose sanctions program targets this country. An entry naming several country programs counts once for each; OFAC's own count is used where one entry aggregates several penalties | OFAC enforcement information, 2003–2025 (`build_penalties.R`) | 2003–2025; blank before 2003 | Negotiated and discretionary, published only when resolved. Understates enforcement against US banks, most of which runs through anti-money-laundering law (FinCEN, OCC, Fed, DOJ). 59% of penalties (1,219 of 2,052) were against individuals, mostly Cuba travel cases in 2003–2005 |
| `pen_program_count_firms` | As `pen_program_count`, firms and organizations only (entries for individuals excluded) | as above | as above | Use this to separate exertion against a target from mass enforcement against US travelers |

`kin_vs_state` and `kin_in_state` are kept separate and never summed: the first
is force against a state, the second is force spent in a state alongside its
government (`BUILD_PROTOCOL.md`, Q8). Posture is never summed with either.

## Mapping rules (all logged in `build_log.txt`)

- GSDB lists several targets in one field. Names containing commas ("Korea,
  North", "Yemen, North", "Congo, Democratic Republic of the", "Gambia, The",
  "Egypt, Arab Rep.") are protected before splitting.
- GSDB names are mapped to COW codes with `countrycode` 1.9.0 plus an explicit
  table for historical and ambiguous names (`crosswalk_gsdb_targets.csv`).
  Germany is 260 through 1990 and 255 after; Yemen is 678 before 1990 and 679
  after.
- GSDB label quirks: "South Vietnam" in cases after 1975 is unified Vietnam
  (816; cases 195, 200, 201, 519, 809); "Yemen, North" after 1990 is unified
  Yemen (679; cases 962, 1093, 1204).
- Not COW states, so not assigned: Balkans, Hong Kong, ICC Rome Statute
  Signatories, League of Arab States, Palestine.
- Case-years before a target became a state are dropped: Eritrea before 1993
  (16 case-years), Mozambique 1970–1971 (2).
- UCDP uses Gleditsch–Ward codes. They are converted with `countrycode`; codes
  it does not convert but which are valid COW codes that year (816 North
  Vietnam, 55 Grenada) are taken as identical. GW 678 after 1990 is COW 679;
  GW 340 is COW 345.
- Conflicts with no foreign target are not assigned: Puerto Rican Nationalist
  Party (1950) and al-Qaida (2001–2019, located in the US).
- `troopdata` codes Germany 260 throughout; rows from 1991 are moved to 255.

## Penalties channel: how entries are attributed

Entry-level file: `v2/output/penalties_entries.csv` (one row per OFAC entry,
1,058 entries, 2,052 penalties, 2003–2025), with the programs found, the
method used, and the first 400 characters of the text each attribution was
read from.

- **Index.** OFAC's by-year pages list every entry with its date, name, number
  of penalties and amount, and a link to its document. The 23 rows without a
  link are OFAC's year totals; the build checks itself against them. The
  count matches in all 23 years. Dollars match in 22; in 2004 OFAC's listed
  entries sum to $55,000 more than its stated total (an inconsistency in
  OFAC's page; the count matches).
- **Cells.** A blank count is one action (this reconciles every year to
  OFAC's totals); a blank amount is a finding of violation without a penalty
  ($0). Four "None" rows mark months without penalties.
- **Year.** The date OFAC published the entry (Q10).
- **Program.** 2003–2011 tables: the program in the entry's row (row located
  by its amount; where an amount repeats, the row naming the entity), read
  from the program column or from a 31 C.F.R. part number
  (`v2/build/ofac_cfr_parts.csv`; parts 587 and 590 were reused for a second
  program and are read by year). Narrative releases: the program(s) named in
  the entry's heading and first sentence (regulation names in
  `v2/build/ofac_program_map.csv`, plus C.F.R. part references). Monthly
  narrative reports are split into one block per entry in index order. A
  release whose heading says "multiple sanctions programs" is scanned whole
  (e.g., Binance 2023; Standard Chartered 2019, whose separate Zimbabwe
  settlement appears later in the release).
- **Program country.** Fixed by the program tables. Ukraine-/Russia-related
  programs, including Crimea, are attributed to Russia. Non-country programs
  (terrorism, narcotics, nonproliferation, cyber, Global Magnitsky, reporting
  violations) have no program country.
- **Result.** Program found for 1,051 of 1,054 entries; the 3 not found are
  13 penalties (Alpha Industries 2003, whose amount is not in its report, and
  two 2003 aggregate rows without amounts). 995 entries name at least one
  country program.
- **Checked by hand:** 30 random table rows against their source lines and 25
  random narrative releases against their headings, all correct. The releases
  for Binance 2023, British American Tobacco 2023 and Standard Chartered 2019
  were read in full. The program sets for BNP Paribas 2014, HSBC 2012, ING
  2012, Credit Suisse 2009, Standard Chartered 2012, Wells Fargo 2023,
  Poloniex 2023 and ExxonMobil 2017 match what is publicly reported about
  those settlements, a check made from general knowledge, not a second
  source; systematic validation against Early & Preble is still to come
  (Rule 6).
- **Location (second attribution, Q8).** Recorded in the entry file as
  `location_ccode` with `location_method`. It is found for 423 entries (383
  of them US firms, identified by a US address); for the rest the release
  does not state it in a form the build reads. Because "not found" is not
  zero, location counts are not in the panel yet.
- **Text extraction.** Documents are converted with poppler `pdftotext
  -layout`; the version is recorded in the penalties log. A different version
  may extract text differently.
