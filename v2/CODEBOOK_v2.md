# EII v2 — Codebook (partial release, 2026-10-27)

**Status: PARTIAL. Not for estimation.** This release contains the frame, the
US sanctions flag, and five exertion channels: financial, penalties,
kinetic, covert action (regime change attempts 1950–1989; proxy support
1975–2017), posture, and trade (Section 301, Section 232 and emergency
tariffs naming the state). Covariates are in
separate files (below). The multilateral block and the trade channel are not
yet built (`BUILD_PROTOCOL.md`, section 7).

File: `v2/output/EII_v2_partial.csv`. Built by `v2/build/run_all.R`
(`build_penalties.R`, `build_financial.R`, `estimate_sdn_1994.R`,
`build_proxy.R`, `build_regime_change.R`, `build_gsdb_fs.R`, `build_trade.R`,
`build_v2_partial.R`, `build_covariates.R`, `build_multilateral.R`, then
`build_controls.R`) from the
sources in `v2/sources/MANIFEST.csv`, `v2/sources/MANIFEST_ofac.csv`,
`v2/sources/MANIFEST_sdn.csv` and `v2/sources/MANIFEST_covariates.csv` (fetch
and verify with `v2/build/fetch_sources.R`). The build needs a UTF-8 locale;
the scripts set one where the system offers it. Build logs:
`v2/output/build_log.txt`, `penalties_log.txt`, `financial_log.txt`,
`proxy_log.txt`, `covariates_log.txt` (all in `v2/output/`).

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
| `under_sanctions_us` | 1 if a GSDB case naming the United States among its senders (alone or with named partners) is in force against the state in the year, else 0. UN- or coalition-only cases are excluded | GSDB release 5: US-named cases from the case list; targets and years from the dyadic file | 1950–2025 | Researcher-coded from public sources; covert measures absent. Multi-target cases (e.g., designations of individuals in many countries at once; the 2002–2009 case against International Criminal Court signatories) flag every named state. States flagged: 47 in 1990, 90 in 2020, 123 in 2025 |
| `under_sanctions_us_single` | As `under_sanctions_us`, counting only cases with a single target (GSDB `target_mult` = 0) | as above | 1950–2025 | Separates sanctions aimed at a state from multi-country designation cases. States flagged: 31 in 1990, 69 in 2020, 95 in 2025 |
| `us_sanction_cases` | Number of US-named GSDB cases in force against the state in the year | as above | 1950–2025 | The GSDB codebook warns that case counts are not intensity measures: an escalating regime can generate several cases and an equally severe embargo one |
| `kin_vs_state` | 1 if the US is a party to an armed conflict against this state's government in the year: an interstate conflict with this state on the other side, or a conflict in which the US backs the side opposing this government | UCDP/PRIO ACD v26.1 | 1950–2025 | Understates: 25-battle-death threshold; misses covert and stand-off US action (Iraq no-fly-zone strikes 1992–2002; the 2011 Libya air campaign, where UCDP lists no US or NATO party) and US arming of one side (Ukraine against Russia from 2022; see the proxy variables for 1975–2017). US force inside a state without its government (against IS in Syria, 2014–2024) is in neither kinetic variable |
| `kin_vs_state_intensity` | Highest UCDP intensity among those conflicts: 0 none, 1 = 25–999 battle deaths, 2 = 1,000 or more | UCDP/PRIO ACD v26.1 | 1950–2025 | as above |
| `kin_in_state` | 1 if the US fights alongside this state's government, inside its territory, against non-state actors | UCDP/PRIO ACD v26.1 | 1950–2025 | as above; UCDP's episode coding starts the US-backed Afghanistan episode in 2003, so 2002 reads 0 |
| `kin_in_state_intensity` | Highest UCDP intensity among those conflicts (0, 1, 2) | UCDP/PRIO ACD v26.1 | 1950–2025 | as above |
| `proxy_vs_state` | 1 if the US government gave a warring party support short of US troops against this state's government in the year: rebels fighting it, or another government at war with it. Confirmed support only | UCDP External Support Dataset (ESD) 18.1, triad-year (`build_proxy.R`) | 1975–2017; blank outside | Understates: ESD covers only conflicts in UCDP (25 battle deaths a year), so support to groups below that threshold, coup support and payments that never entered the public record are absent (`BUILD_PROTOCOL.md`: not recorded is not non-existent). "Government" is UCDP's: in Libya 2014 the US-backed House of Representatives is coded as fighting the Tripoli government. 64 state-years in 15 states (Afghanistan 1980s, Nicaragua 1980s, Angola, Cambodia, Syria 2011–2017 among them); 4 overlap `kin_vs_state` |
| `proxy_vs_state_types` | Number of kinds of support given that year, highest across the state's conflicts: weapons, materiel and logistics, training, funding, intelligence, access to infrastructure, access to territory, troops present but not a warring party, other, unknown | as above | as above | Counts kinds, not amounts or value |
| `proxy_vs_state_alleged` | 1 if the only US support recorded against the state that year is alleged (ESD `ext_alleged`), else 0 | as above | as above | Evidence grade kept apart from confirmed support; 10 state-years |
| `proxy_for_state` | 1 if the US government gave this state's government support short of US troops in a war it fought that year (against rebels or another state). Confirmed support only | as above | as above | Support to a government is not exertion against it: the analog of `kin_in_state`, never summed with `proxy_vs_state`. 481 state-years in 53 states (Colombia 1990–2010 among them); 45 overlap `kin_in_state`. ESD also records US support to Russia against IS in 2017 |
| `proxy_for_state_types` | As `proxy_vs_state_types`, for support to the government | as above | as above | |
| `proxy_for_state_alleged` | As `proxy_vs_state_alleged`, for support to the government | as above | as above | 5 state-years |
| `rc_covert` | 1 if a US covert regime change attempt against the state's government or ruling parties was under way in the year (O'Rourke's definition: US effort to replace, or keep from power, a foreign government or governing faction, by coup, assassination, arming dissidents, election interference or democracy promotion) | O'Rourke, *Covert Regime Change* (2018), Tables 5.1–5.3, hand-entered in `v2/build/orourke_cases.csv` (`build_regime_change.R`) | 1950–1989; blank from 1990 (the source ends in 1989) | O'Rourke requires three declassified primary documents per case, so the count is a floor: she judges unknown successes unlikely but possible. 64 attempts; 303 state-years in 44 states. Soviet republics (Baltic, Belarusian, Ukrainian, Russian SSRs) count for the USSR and Tibet for China. Angola 1964–72 and Mozambique 1964–68 (Portuguese colonies) are not assigned; East Germany 1950–53 and British Guiana 1961–65 fall outside the frame |
| `rc_covert_planned` | 1 if the only covert operation in the year was a plan aborted before implementation (Syria 1955–57, Grenada 1979) | as above | as above | Kept apart from `rc_covert`, as O'Rourke does |
| `rc_covert_type` | O'Rourke's motive class of the operations under way: offensive (against a rival or its alliance), preventive (to keep a state from becoming or joining a rival), hegemonic (to keep a state in the US sphere). Several joined with "; " | as above | as above | Preventive operations include support for incumbent parties in elections (Italy 1947–68, Japan 1952–68): interference in a state's politics, not always against its sitting government. Hegemonic is the class closest to proposition 5 |
| `rc_covert_leader_removal` | 1 if an operation under way that year used a coup or assassination among its tactics | as above | as above | Operation-level: every year of a multi-year operation is flagged, not only the year of the attempt. The leader-level test of proposition 5 starts here |
| `rc_covert_succeeded` | 1 if an operation under way that year eventually brought US-backed forces to power (O'Rourke's "objective achieved") | as above | as above | Outcome of the whole operation, known only after it ends: never use as a predictor of exertion in the same years. 25 of 64 attempts |
| `rc_overt` | 1 if a US overt regime change operation took place in the year (North Korea 1950, Lebanon 1958, Dominican Republic 1965, Grenada 1983, Libya 1986, Panama 1989) | O'Rourke, Table 1.1 | 1950–1989; blank from 1990 | Overlaps the kinetic channel by design |
| `posture_troops_ad` | US active-duty troops located in the country (sum of location rows) | `troopdata` 1.1.0 | 1950–2025; blank where the source has no row, and blank in US-party conflict country-years from 2018 | Official reports omit war-zone deployments from about 2018, and the source fills them with 0 (e.g., Syria 2022 = 0, Iraq 2025 = 0); those cells are set blank. Guard and reserve troops are excluded |
| `posture_note` | Reason a posture cell is blank | build | — | — |
| `pen_program_count` | OFAC civil penalties, settlements and findings of violation published in the year whose sanctions program targets this country. An entry naming several country programs counts once for each; OFAC's own count is used where one entry aggregates several penalties | OFAC enforcement information, 2003–2025 (`build_penalties.R`) | 2003–2025; blank before 2003 | Negotiated and discretionary, published only when resolved. Understates enforcement against US banks, most of which runs through anti-money-laundering law (FinCEN, OCC, Fed, DOJ). 59% of penalties (1,219 of 2,052) were against individuals, mostly Cuba travel cases in 2003–2005 |
| `pen_program_count_firms` | As `pen_program_count`, firms and organizations only (entries for individuals excluded) | as above | as above | Use this to separate exertion against a target from mass enforcement against US travelers |
| `fin_program_count` | Persons, entities, vessels and aircraft added to OFAC's SDN list in the year under a sanctions program that targets this country. An addition under several country programs counts once for each | OFAC, archive of changes to the SDN list (`build_financial.R`; 1994: `estimate_sdn_1994.R`) | 1994–2025 (1994 estimated); blank before 1994 | Records designations, not their effect. Additions under non-country programs (terrorism, narcotics, nonproliferation, cyber, Global Magnitsky, Western Balkans: 39% of additions) have no program country. Vessels and aircraft count as additions (2,023 of 24,277) |
| `fin_program_count_low`, `fin_program_count_high` | Bounds on `fin_program_count`. Equal to it in every year except 1994 | as above | 1994–2025 | 1994 Haiti: 944–1,033 around 1,011 (see below) |
| `fin_estimated` | 1 if `fin_program_count` is estimated (1994), 0 if counted from itemized entries | build | 1994–2025 | Rerun any result without the 1994 rows |
| `fin_program_count_nonindiv` | As `fin_program_count`, excluding individuals | as above | as above | Separates designations of firms, banks, state bodies, vessels and aircraft from designations of officials and other individuals |
| `fin_thematic_location_count` | SDN additions in the year under non-country programs only (narcotics, terrorism, transnational crime, cyber, Global Magnitsky, nonproliferation, Western Balkans and others) whose address is in this country. An addition located in several countries counts once for each | as above | 1994–2025 (1994 is 0: no non-country program existed before 1995) | Makes the drug war and counterterrorism visible: these additions have no program country and do not enter `fin_program_count` (Colombia's program count is 0 in every year; 2,058 narcotics additions are located there). Disjoint from `fin_program_count` by addition. Same address limits as `fin_location_count` |
| `fin_location_count` | SDN additions in the year whose address is in this country, whatever the program (the second attribution, Q8): e.g., a UAE company designated under the Iran program counts for the UAE | as above | as above | An address is found for 84% of additions; vessels, aircraft and individuals listed without an address have none, so 0 means none of the located additions, not none at all. Additions located in the United States (code 2) are outside the frame |
| `fin_gsdb_cases` | Number of GSDB financial sanction cases naming the United States among their senders in force against the state in the year | GSDB-FS v1.0 (financial sanctions, September 2026), case list and dyadic file (`build_gsdb_fs.R`) | 1950–2025 | One case per sender, target and objective: adding names to an existing list is not a new case, so this measures whether a US financial regime is in force (the extensive margin), not designation intensity. The one financial series on a single method across 1950–2025; see the calibration below before using it for 1950–1993 |
| `fin_gsdb_cases_single` | As `fin_gsdb_cases`, single-target cases only (GSDB-R5 `target_mult` = 0) | as above | 1950–2025 | Drops multi-country designation cases (Global Magnitsky and the like), which flag many states at once |
| `fin_gsdb_asset_freeze`, `fin_gsdb_services`, `fin_gsdb_aid`, `fin_gsdb_investment`, `fin_gsdb_payment_infra`, `fin_gsdb_other` | 1 if a US-named case in force that year includes the subtype: asset freeze; ban on financial services; withdrawal of aid; investment restrictions; cut-off from payment infrastructure; other | as above | 1950–2025 | Subtypes from the case list (GSDB's dyadic file merges every case in force for a dyad, including UN cases spread to each member). Payment infrastructure appears only from the 2020s (12 state-years) |
| `trade_301_investigation` | Number of Section 301 investigations the USTR opened against the state in the year (Sean: investigations are threats; dropping a case or finding nothing is a US choice) | CRS R46604 (2020) Table A-2, 1975–2020; Federal Register from 2021 (`v2/build/s301_investigations.csv`, `build_trade.R`) | 1975–2025; blank before 1975 (Section 301 dates from the Trade Act of 1974) | 135 investigations. Cases against the European Communities or EU count for every member that year (`trade_via_eu`). CRS lists "China" in a 1977 case that may be the Republic of China (Taiwan); coded as listed |
| `trade_301_action` | Number of Section 301 actions or escalations published against the state: determinations of action, WTO-authorized retaliation implemented under Section 301, tariff increases | Federal Register notices, hand-coded with citations (`v2/build/trade_actions.csv`) | 1995–2025; blank before 1995 (outcomes not yet coded) | Counts determinations even when the duties were suspended on imposition (France 2020, the six digital services tax cases of 2021). China: three actions in 2018, two escalations in 2019, one in 2024 |
| `trade_232_named` | Number of Section 232 (national security) import measures naming the state: embargoes, country-specific rates or quotas, ended exemptions | Presidential proclamations and executive orders, hand-coded with citations | 1950–2025 | Measures applying to all countries are not counted. Before 2018: Iran 1979, Libya 1982 and 1985 (oil). The 1986 machine-tool restraint agreements (Japan, Taiwan) are not yet verified and not coded |
| `trade_ieepa_named` | Number of emergency-powers (IEEPA) tariff orders naming the state; for the 2025 country-rate orders, only rates above the 10% baseline | Executive Orders 14193–14195, 14257, 14323, 14326, 14329 | 1950–2025 (none before 2025) | The 9 April 2025 rates (EO 14257) were in force for one day before the pause, except for China; the 7 August rates (EO 14326) stayed. India 2025 includes the 25% duty over Russian oil |
| `trade_via_eu` | 1 if any trade event that year reached the state as an EC/EU member | build | 1975–2025 | EU membership by accession year; the UK leaves in 2020 |

Calibration of the GSDB-FS case series against the SDN counts, 1995–2025
(`financial_gsdb_log.txt`). Of the 197 state-years with SDN program
additions, 94.9% also have a US asset-freeze or financial-services case in
force; of the 1,106 state-years with such a case, only 16.9% have SDN
program additions. Year totals move together (correlation 0.89), but at the
state-year level the rank correlation is 0.33. The case series nests the
designation activity but is a different measure: it records that a regime is
in force, not how hard it is used. Before 1994 it can stand in for whether a
US financial sanction was in force against a state, not for how many
designations were made; no designation counts are imputed from it.

`kin_vs_state` and `kin_in_state` are kept separate and never summed: the first
is force against a state, the second is force spent in a state alongside its
government (`BUILD_PROTOCOL.md`, Q8). Posture is never summed with either. The
proxy pair follows the same split. US troops fighting as a warring party are
in the kinetic variables, so ESD triads in which US troops were the only
support (4 triad-years) are not counted as proxy support. ESD support is
attributed by UCDP's sides: in a civil conflict, support to the rebels counts
against the government's state and support to the government counts for it;
in an interstate conflict, support counts for the supported state and against
its opponent. GW codes are mapped to COW as in the kinetic channel.

The regime change variables and the proxy variables overlap only partly:
of the 87 state-years with a covert regime change attempt in 1975–1989, 34
also show US support against the government in ESD, and ESD shows support
against 7 governments (El Salvador, Argentina, Nigeria, Chad, Ethiopia,
Angola, Iran) in years O'Rourke records no regime change attempt. Chad
1981–82 and the Philippines 1984–86 carry both a regime change attempt and
US support to the government in the same years. Where O'Rourke's Table 1.1
and her case tables give different years (Angola 1985–88 against 1986–88;
Haiti 1986–88 against 1986–89), the case table is used.

## Mapping rules (all logged in `build_log.txt`)

- Sanctions flag: cases are selected from the GSDB-R5 case list (the United
  States named among the senders); target countries and years come from the
  dyadic file's United States sender rows that draw on those cases, as the
  GSDB codebook advises for dyad-year indicators (its section 8.1). Dyadic rows
  that draw only on UN or coalition cases (450 of 4,534) are excluded under Q2.
- Target ISO3 codes (USITC Dynamic Gravity) are mapped to COW with
  `countrycode`, plus CSK 315, DDR 265, KSV 347, VDR 816, RHO 552, SRB 345,
  SVU 365, and year rules: DEU is 260 through 1990 and 255 after; VNM (GSDB's
  "South Vietnam") is 817 through 1975 and 816 after; YEM (GSDB's "Yemen,
  North") is 678 before 1990 and 679 after. GSDB labels some current states by
  historical names (e.g., "Malaya" for Malaysia, "Ceylon" for Sri Lanka); the
  ISO3 codes resolve these. The mapping is written to
  `crosswalk_gsdb_targets.csv`.
- Not COW states, so not assigned: Hong Kong, Palestine.
- Target-years before a target was a COW state are dropped (44): Yugoslav
  successor states named before independence (Montenegro, Kosovo, Macedonia,
  Croatia, Bosnia, Slovenia), Eritrea before 1993, Mozambique 1970–1971.
- The GSDB-R5 codebook says ongoing cases have a blank `end_year`; the
  distributed case list has none, and 828 cases end in 2025. Either way an
  ongoing case is in force through 2025, so the flag is unaffected.
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

## Financial channel: how additions are counted and attributed

Entry-level file: `v2/output/sdn_additions.csv` (one row per addition, 24,277
additions, 1995–2025), with its date, type, program tags, program country,
location country, the heading it was listed under, and the first 400
characters of the entry. Year totals: `v2/output/financial_year_totals.csv`.

- **Source.** OFAC's archive of changes to the SDN list: one text file per
  year for 1994–2023 and a three-column PDF for 2024 and 2025. The PDFs are
  converted in reading order by `v2/build/sdn_pdf_to_text.R` (word positions
  from poppler `pdftotext -bbox-layout`, ordered by page, column and line).
  On 2023, which OFAC publishes in both forms, the converted PDF gives the
  same number of additions as the text file on all 223 dates, and 5,613 of
  5,616 entries are identical after normalization.
- **Addition.** An entry in a section OFAC heads as added or designated.
  Changed and removed entries are not additions, nor are entries that appear
  only because an existing entry was changed ("resulting in the following new
  entries"). Year is the date of the change notice (Q10).
- **Aliases.** OFAC prints each a.k.a. of many designees as a separate entry
  (one 2017 designee appears five times). Entries with the same set of names
  and the same identifying details on the same date are counted once
  (26,110 removed). Names in other scripts, printed in the PDFs, are ignored
  for this comparison.
- **Relistings.** An entry deleted and listed again on the same date is not a
  new designation (115 removed; e.g., 1997-10-08, when OFAC deleted
  terrorist organizations and relisted them as Foreign Terrorist
  Organizations). Additions after an earlier delisting do count (e.g., the
  November 2018 reimposition of Iran sanctions).
- **Program country.** From the entry's program tags, by the fixed table
  `v2/build/ofac_sdn_tags.csv`, on the same rules as the penalties channel:
  Ukraine-related programs (including Crimea and the occupied regions) are
  attributed to Russia; non-country programs are not assigned. The Hong Kong
  and Uyghur programs are attributed to China. Tags of non-SDN lists (Foreign
  Sanctions Evaders, Non-SDN Palestinian Legislative Council) are ignored.
- **Location country.** The country of each address in the entry (the last
  element of each address), read as written by OFAC: an address in occupied
  Crimea reads Ukraine. Places that are not COW states (Hong Kong, the West
  Bank, Gaza, British Virgin Islands and other dependencies) are recognized
  but not assigned. Montenegro before 2006, Kosovo before 2008 and South
  Sudan before 2011 are assigned to their predecessor state. Place of birth,
  nationality and the country in identity-document numbers are not
  locations.
- **1994 (estimated; `estimate_sdn_1994.R`, `v2/output/sdn_1994_estimate.csv`).**
  The 1994 file is narrative: it reports most designations as counts (e.g.,
  "General Notice No. 3 ... naming 523 individual officers of the Haitian
  Armed Forces") whose names were published in separate files not in the
  archive. Program counts are estimated; the split by type and the location
  attribution are not, and stay blank for 1994.
  - Libya 32, Iraq 1 and Yugoslavia 3 are counted exactly from the text.
  - Haiti: the stated Haiti general notices of 1994 (Nos. 3, 4, 5, 6, 8, 10)
    total 664 listings. The one count OFAC does not state, the Haitian
    residents named under the 21 June 1994 executive order, is taken from
    the itemized list of the residents' category ("**") deleted on 10/05/94:
    333 distinct listings, plus 14 redesignated that day. That category
    exists only from 21 June 1994, so all of it is a 1994 addition; it holds
    General Notice 9 (117) and 230 other residents. Point estimate 1,011.
    Low (944): General Notices 8 and 10 are already inside the residents'
    category. High (1,033): the 22 blocked individuals removed on 10/05/94,
    whose listing date is not stated, were also 1994 listings.
  - Check: the itemized list of every Haiti listing deleted on 10/16/94,
    when the program ended, leaves about 19 individuals and 37 government
    entities not accounted for by the 1994 notices, consistent with Haiti
    listings made before 1994.
  - Total 1994: 1,047 (bounds 980–1,069). The bounds come from alternative
    readings of the source, not from a statistical model.
- **Checked by hand:** 25 random additions against their source entries and
  headings (program country, location, type and section all correct).
- **Checked against CNAS "Sanctions by the Numbers"**
  (`v2/output/financial_validation_cnas.csv`): within 1% of CNAS's yearly
  total in 11 of the 16 years CNAS publishes (exact in 2010, 2013, 2020 and
  2023). Below CNAS by 2–5% in 2014 and 2017 and by 18–37% in 2012, 2015 and
  2016. CNAS's 2009–2019 series also counts non-SDN lists (Sectoral
  Sanctions Identifications, Foreign Sanctions Evaders, Part 561), which may
  explain 2014–2017; the 2012 gap is not yet explained and is open. Against
  CNAS's 2024 country tallies (individuals by nationality, entities by
  address; this build uses addresses for both), the 2024 location counts
  are: Russia 1,682 (CNAS 1,706), China 286 (276), UAE 142 (119), Iran 134
  (130), Turkey 122 (109), Mexico 106 (102), Belarus 67 (55), Venezuela 38
  (37), North Korea 12 (29). North Korea is low because many North Korean
  individuals are listed with a nationality but no address.

## Multilateral block (`build_multilateral.R`)

Outside the index (`BUILD_PROTOCOL.md`, D4). File:
`v2/output/multilateral_country_year.csv`, same frame; log
`multilateral_log.txt`. Source: GSDB release 5, cases classed by sender from
the case list, targets and years from the dyadic file.

| Variable | Definition | Coverage | Notes |
|---|---|---|---|
| `un_sanctions` | 1 if a UN sanctions case (GSDB sender "UN") is in force against the state | 1950–2025 | 88 cases; 591 state-years. Whether the US drafted or sponsored the measure (tier 2) or not (tier 3) is not yet coded: it needs case evidence, OPEN |
| `un_sanction_cases` | Number of UN cases in force | as above | |
| `un_sanctions_financial` | 1 if a UN case in force includes financial measures (GSDB-R5 case list) | as above | 316 state-years |
| `eu_sanctions` | 1 if a case naming the EU among its senders is in force | as above | 190 cases (3 also name the US); 978 state-years, from the 1990s on |
| `eu_sanctions_no_us` | As `eu_sanctions`, counting only EU cases that do not name the US | as above | |
| `regional_sanctions` | 1 if a case by another organization (African Union, Commonwealth, ECCAS, ECOWAS, Arab League, NATO, OAU, OAS, SADC) is in force | as above | 81 cases; 755 state-years. The Arab League boycott of Israel and the OAU measures against South Africa and Portugal dominate before 1990 |

Not yet built: UN Security Council listings with their original dates (the
current consolidated list drops delisted names), tier coding of UN cases,
and Security Council vetoes as denied cover.

## Controls and the kill test (`build_controls.R`)

File: `v2/output/controls_country_year.csv`, same frame; log
`controls_log.txt`.

| Variable | Definition | Source | Coverage | Notes |
|---|---|---|---|---|
| `mid_vs_us` | 1 if the state is on the side opposing the US in a militarized interstate dispute in the year (Q15) | COW MID 5.0, participant file | 1950–2014; blank after | 340 disputes with the US; 327 state-years. MIDs include threats and displays as well as force |
| `mid_vs_us_initiator` | As above, the state on the initiating side (side A) | as above | as above | 202 state-years |
| `mid_vs_us_force` | As above, the state's own highest action was a use of force or war (hostility level 4–5) | as above | as above | 220 state-years. Use of force in MID terms includes seizures of vessels and personnel, not only attacks |
| `mid_vs_us_attack` | Initiated and used force against the US | as above | as above | 154 state-years; the closest MID reading of "someone attacks us" |
| `sanctions_on_us` | 1 if the state is a sender in a sanctions case against the US in force (Q15) | GSDB release 5, dyadic file | 1950–2025 | 106 state-years; the 1973–74 Arab oil embargo is the largest episode (37 state-years). EU and UN cases count for every member state, as GSDB spreads them |
| `cyber_vs_us` | 1 if a cyber operation against US targets that began in the year is attributed to the state or to an actor affiliated with it (settled attribution) | EuRepoC Global Dataset of Cyber Incidents 1.3, dyadic file (CC BY-NC 4.0) | 2000–2024; blank otherwise | 762 incidents against the US; 188 by a state or state-affiliated actor; 178 state-incident attributions to named states (joint attributions count for each). 64% of incidents have no named attacker, and collection grows sharply from 2022, so counts track visibility as well as activity. China, Russia, Iran and North Korea lead |
| `cyber_vs_us_n` | Number of such incidents | as above | as above | Joint attributions count for each state named |
| `cyber_vs_us_state` | 1 if at least one incident is attributed to the state itself (not an affiliated group) | as above | as above | |
| `conflict_nonus` | 1 if a UCDP armed conflict in which the US is not a party is located in the state, or the state is a party to one (Q14) | UCDP/PRIO ACD v26.1 | 1950–2025 | 1,830 state-years. Disjoint from the kinetic channel by construction |
| `conflict_nonus_intensity` | Highest intensity of those conflicts (0, 1 = 25–999 battle deaths, 2 = 1,000+) | as above | as above | 549 state-years at 1,000+ |
| `conflict_nonus_us_backed` | 1 if such a conflict-year also has US support short of troops to a side (ESD) | UCDP ACD and ESD | 1975–2017; blank outside | 464 of 1,229 conflict state-years in 1975–2017 (38%). Those years are US pressure, not a control: drop them when conflict is used as a control (protocol, 2026-10-27) |

Kill test, as Sean defines it (2026-10-29): attacks on US soil plus
sanctions on the US; attacks on US forces and citizens abroad are reported as
robustness (logged with Claude's objection that a soil-only test has one or
two events). Not yet built: terrorism against US targets on and off US soil
(Global Terrorism Database, by request), and state attacks on US forces after
2014 (MID ends in 2014). The CFR Cyber Operations Tracker has no download;
EuRepoC is used instead.

## Covariates (`build_covariates.R`)

Kept in two files apart from the exertion panel, keyed the same way. Sources
and checksums: `v2/sources/MANIFEST_covariates.csv`; build log:
`v2/output/covariates_log.txt`. Not yet built: the US as a target (Q15) and
the trade channel. Yearly mineral production, like yearly energy production,
is not published (BGS terms allow academic use but not passing the tables
on); only the derived endowment indices are.

### `v2/output/covariates_year.csv` (one row per year, 1950–2025)

Year-level variables are the same for every state in a year, so their
effects are identified from year-to-year variation only (about 31 years for
the financial channel, 1995–2025).

| Variable | Definition | Source | Coverage | Notes |
|---|---|---|---|---|
| `us_debt_gross_gdp` | Gross federal debt, end of fiscal year, % of GDP | OMB Historical Tables (FY2027 Budget), Table 7.1 | 1950–2025 | Includes debt held by federal trust funds |
| `us_debt_public_gdp` | Federal debt held by the public, % of GDP | as above | 1950–2025 | |
| `us_debt_public_exfed_gdp` | Debt held by the public other than the Federal Reserve, % of GDP | as above | 1950–2025 | |
| `us_net_interest_gdp` | Net interest outlays, % of GDP | Table 6.1 | 1950–2025 | The measure of the "check coming due"; it moves differently from debt (Q3 caution) |
| `us_surplus_gdp` | Total surplus (+) or deficit (−), % of GDP | Table 1.2 | 1950–2025 | |
| `us_outlays_gdp` | Total outlays, % of GDP | Table 6.1 | 1950–2025 | |
| `us_defense_gdp` | National defense outlays, % of GDP | Table 6.1 | 1950–2025 | |
| `us_gdp_share` | US GDP as % of world GDP, current US$ | World Bank WDI | 1960–2025 | Market exchange rates; 1950–1959 missing |
| `china_gdp_share` | China, as above | WDI | 1960–2025 | |
| `eu_gdp_share` | EEC/EC/EU members in the year (by accession; the UK through 2019), as above | WDI | 1960–2025 | Missing in a year when any member lacks data |
| `brics_gdp_share` | BRICS members in the year: Brazil, Russia, India, China from 2009; South Africa 2011; Egypt, Ethiopia, Iran, UAE 2024; Indonesia 2025 | WDI | 2009–2024 | Missing before the bloc existed and in 2025 (no 2025 UAE figure). Saudi Arabia is not counted (membership unconfirmed) |
| `brics5_gdp_share_fixed` | The five founding-era members in every year | WDI | 1988–2025 | Fixed membership, for comparison with the time-varying series |

Fiscal years are used as panel years (FY *t* ends in calendar year *t*; the
fiscal year ended June 30 before FY1977). The 1976 transition quarter is
dropped. Net interest matches the v1 series (`fiscal_indicators.csv`, tag
`v1-2026-10-17`) to one decimal place; v1's debt series was gross debt.

### `v2/output/covariates_country_year.csv` (one row per state-year, same frame as the panel)

| Variable | Definition | Source | Coverage | Notes |
|---|---|---|---|---|
| `us_defense_pact` | 1 if the state has a defense obligation with the US in the year | ATOP v5.1 dyad-years | 1950–2018 observed; 2019–2025 carried forward | 2019–2025: 2018 partners plus NATO accessions of North Macedonia (2020), Finland (2023) and Sweden (2024). ATOP's broader `atopally` includes consultation and non-aggression pacts (it lists Russia and China) and is not used. US defense partners: 31 in 1950, 53 in 1990, 66 in 2018, 69 in 2025 |
| `unga_ideal` | UN General Assembly ideal point (higher = closer to the US and Western positions) | Bailey, Strezhnev & Voeten, 1946–2025 file (Voeten Dataverse, v39) | 1950–2025, UN members casting votes | Missing for non-members and years without votes |
| `unga_dist_us` | Absolute distance between the state's and the US's ideal point in the year | as above | as above | The US ideal point moves sharply in 2025 (2.16 in 2024, 2.89 in 2025), so distances to every state change that year |
| `unga_votes` | Roll-call votes behind the estimate | as above | as above | Few votes means a wide credible interval |
| `nat_res_rents_gdp` | Total natural resource rents, % of GDP (extractive value, Q7) | WDI | 1970–2021 | Missing before 1970 and after 2021. WDI's Germany series is assigned to West Germany (260) through 1990 and Yemen's to North Yemen (678) before 1990. Kept for reference: the protocol replaced rents with physical endowment (change log 2026-10-29), because sanctions, war and price policy push rents down |
| `fx_anchor` | Reference currency of the state's exchange rate arrangement in the year (USD, EUR, GBP, …, baskets such as USD-EUR) | Ilzetzki, Reinhart & Rogoff (IRR), monthly anchor file 1946–2025, beta of October 2026 | 1950–2025 | Blank where IRR reports none or the currency is freely falling. A reference currency is assigned to floating currencies too (South Korea, a managed float referenced to the dollar from 1998; Mexico, whose own peso is its reference from 2016), so the anchor alone is not a peg |
| `usd_anchor` | 1 if `fx_anchor` is the US dollar alone, 0 if another currency or a basket, blank if `fx_anchor` is blank | as above | as above | Baskets that include the dollar (USD-EUR for Russia from 2004, USD-AUD) are 0 here; read `fx_anchor` for them |
| `fx_regime_coarse` | IRR coarse de facto regime: 1 no separate legal tender, currency board, peg or band within ±2%; 2 crawling peg or crawling band within ±2%; 3 managed float or band within ±5%; 4 freely floating; 5 freely falling; 6 dual market with missing parallel-market data | IRR regime classification, monthly 1940–2025, beta (last update 5 October 2026) | 1950–2025 | Code 6 covers the Soviet bloc before 1991 and other states with parallel markets but no parallel-rate data (in 1985 also Afghanistan, Angola, Cambodia, Gambia, Guinea, Sudan, Vietnam) |
| `fx_regime_fine` | IRR fine de facto regime, 1–15 (1 = no separate legal tender; 2 = currency board or pre-announced peg; 14 = freely falling; 15 = dual market, parallel data missing) | as above | as above | Dollarized states: `usd_anchor` = 1 and `fx_regime_fine` = 1 (12 in 2025: Ecuador, El Salvador, Panama, the Marshall Islands, Micronesia, Palau and six Eastern Caribbean currency-union members) |
| `usd_peg` | Dollar peg (dollar integration, Q6, zero part): 1 if the anchor is the US dollar and the coarse regime is 1 or 2; 0 if the coarse regime is 3–5, or 1–2 with another anchor; blank if the regime is missing or 6, or 1–2 with no anchor reported | as above | 1950–2025 | Before 1973 most pegs are to the dollar because Bretton Woods made them so, so the variable's meaning shifts in 1971–73. Dollar pegs: 24 in 1950, 41 in 1970 and 1990, 73 in 2000, 83 in 2010, 56 in 2025. A further 12–26 states a year are dollar-referenced but float or are freely falling |
| `usd_debt_share` | Share of long-term public and publicly guaranteed external debt contracted in US dollars, % (dollar integration, Q6, check measure) | World Bank International Debt Statistics (December 2025 release), DT.CUR.USDL.ZS, counterpart World | 1970–2024; IDS reporters only (121 states in the frame) | Low- and middle-income debtors only: high-income states, and non-reporters such as Russia, Venezuela, Saudi Arabia and South Korea, are blank. Measures the currency of liabilities, not the exchange-rate regime: its correlation with `usd_peg` is 0.11–0.38 by decade (mean 59.5% under a dollar peg, 44.6% otherwise), so the two are not interchangeable |
| `endow_oilgas_twh` | Physical endowment (Q7, proposition 3): the highest annual oil plus gas production in 1985–1994, the decade before the financial channel's itemized record, for the territory the state holds in 1995. The same value in every year | as above | Time-invariant; 187 states (84 with zero) | Peak rather than mean, so a sanction or war year in the window (Iraq 1991–94) does not lower it. Production measures developed capacity, not reserves: fields developed after 1994 (Sudan from 1999, Equatorial Guinea, Guyana) are missed. For outcomes before 1995 the window is not prior. Minerals are in the `crit_min_*` variables; a market-priced version and era weighting are open (protocol) |
| `endow_window` | Years behind `endow_oilgas_twh` | build | — | Russia, Serbia, Czechia and unified Germany use their own present-territory series (Serbia and Czechia from 1992 and 1993). Montenegro, South Sudan and Timor-Leste have no data in the window and use their first five years with data (flagged) |
| `crit_min_share_sum` | Critical-minerals endowment (Q7, proposition 3): the state's highest share of world mine production in 1985–1994 in each of 31 series covering 52 of the 60 minerals on the USGS 2025 critical-minerals list, summed over the series (1 = the whole world's output of one mineral). The same value in every year | British Geological Survey, World Mineral Statistics (fetched 2026-10-29) | Time-invariant; 121 states with reported production, 80 with none (0) | Unit-free, so minerals measured in tonnes, kilograms and K2O content can be combined; each mineral counts equally, whatever its price or strategic weight (market pricing and era weighting are open). Largest: China 6.9, Australia 3.7, Russia 3.2, Canada 3.0, South Africa 2.7, Brazil 2.4. Not covered: cesium, rubidium, hafnium, silicon, gallium, indium, rhenium, germanium, tellurium, metallurgical coal. Gross-weight series that mix grades (lithium minerals, titanium minerals, rare earth minerals) are the least precise |
| `crit_min_major_n` | Number of the 31 series in which the state's peak share was at least 5% | as above | as above | China 21, Russia 16, Canada 16, Australia 14 |
| `crit_min_series_n` | Number of series in which the state reported production in its window | as above | as above | |
| `crit_min_unavailable_n` | Number of series in which BGS lists the state as a producer but gives no figures in its window | as above | as above | Those series are left out of the sum, not counted as zero (2 states) |
| `crit_min_window` | Years behind the critical-minerals values | build | — | Russia and the other post-Soviet states, Serbia and Montenegro, and Czechia use 1992–1994 (BGS reports the USSR, Yugoslavia and Czechoslovakia before then), the collapse years of Soviet-era output. States that ended before 1995 use their own years. Montenegro and Kosovo use their first five years with data (flagged). "no production reported": the state is in no BGS producer table for these minerals in its window and scores 0 |
| `eci_sitc` | Economic Complexity Index (production capability), SITC Rev. 2 trade data | Growth Lab, Atlas of Economic Complexity, country-year file (Dataverse doi:10.7910/DVN/H8SFD2, v18) | 1962–2024 | Standardized within each year (mean about 0, s.d. about 1): it places a state against others that year and does not track a state's own change over time. Built from export data, so services and production for the home market are not counted |
| `export_diversity` | Number of products exported with revealed comparative advantage | as above | as above | |

Yearly oil, gas and coal production (`oil_prod_twh`, `gas_prod_twh`,
`coal_prod_twh`, terawatt-hours of primary energy; Our World in Data energy
dataset, mostly Energy Institute Statistical Review data, 1950–2024) is built
to `v2/output/local/energy_production_country_year.csv`, which is not
committed: the Energy Institute allows quotation with attribution but requires
permission for extensive reproduction. Rebuild it locally with the scripts.
Reported states: about 75 a year before 1965, 165–195 from 1985 to 2016, and
only the 49–50 the Energy Institute lists from 2017 (Guyana has no row after
2016). Sanctions and war push yearly production down; the endowment is the
measure for the extractive-value test.

Mapping of the 2026-10-29 sources. IRR reports months; the annual value is the
modal month, and a tie goes to the value held later in the year. This rule
reproduces the authors' own annual anchor file (1946–2016) in 99.0% of
country-years, and the beta release agrees with the stable release
(1946–2019) in 99.6% of country-months for both anchor and regime. IRR codes
territories before independence; those years are dropped, except Czechia's
column, which holds Czechoslovakia's koruna (assigned to 315 through 1992).
Serbia (345) starts in 2006, because its column codes the territory, not
Yugoslavia, before then; IRR's placeholder columns for the USSR, Yugoslavia
and Czechoslovakia (ruble throughout) are not used. Vietnam before 1976 is
left blank in all three sources because which Vietnam is meant is not stated.
OWID energy: the USSR row goes to 365 through 1991 and Russia from 1992;
Yugoslavia to 345 through 1991 and Serbia from 1992; Czechoslovakia to 315;
Germany (reported for its present territory, so including East Germany) to
260 through 1990 and 255 after; Yemen from 1990 only. Atlas: Russia's series
before 1992 is the USSR (the other successor states start in 1992), and
Germany before 1991 is West Germany (260); Czechoslovakia and Yugoslavia are
not in the Atlas.

The protocol named the July 2025 ideal-point release; the 1946–2025 file
posted since adds the 2025 session and is used instead (logged in the
protocol).

