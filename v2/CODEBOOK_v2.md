# EII v2 — Codebook (partial release, 2026-10-27)

**Status: PARTIAL. Not for estimation.** This release contains the frame, the
US sanctions flag, the kinetic channel and the posture channel. The financial
(SDN) channel, the penalties channel, the multilateral block, the burden blocks
and the covariates are not yet built (`BUILD_PROTOCOL.md`, section 7).

File: `v2/output/EII_v2_partial.csv`. Built by `v2/build/build_v2_partial.R`
from the sources in `v2/sources/MANIFEST.csv` (fetch and verify with
`v2/build/fetch_sources.R`). The build log is `v2/output/build_log.txt`.

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
