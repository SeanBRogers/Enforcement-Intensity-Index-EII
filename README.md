# EII: Enforcement Intensity Index

A country-year panel of the coercive resources the United States expends
against other states, 1950–2025, for every state in the international system.

**Sean Rogers** | University of South Carolina | Department of Political Science

> **Status (2026-10-29): partial release. Not for estimation.** The frame, a US
> sanctions flag, five exertion channels (financial, penalties, kinetic, covert
> action, posture) and the covariates are built. The multilateral
> block and the trade channel are not yet built, and the panel is not for
> estimation until they are and every channel is validated.

## What is here

| Path | What it is |
|---|---|
| [`v2/output/EII_v2_partial.csv`](v2/output/EII_v2_partial.csv) | The panel: one row per state per year, 1950–2025 (201 states, 11,916 rows) |
| [`v2/output/covariates_country_year.csv`](v2/output/covariates_country_year.csv), [`covariates_year.csv`](v2/output/covariates_year.csv) | Covariates, kept apart from the panel: alliance, UN voting, dollar peg, oil and gas endowment, economic complexity (by state-year); US fiscal burden and rivals' share of world GDP (by year) |
| [`v2/CODEBOOK_v2.md`](v2/CODEBOOK_v2.md) | Every variable: definition, source, coverage, and the direction in which its source misreports |
| [`BUILD_PROTOCOL.md`](BUILD_PROTOCOL.md) | The design decisions made before the build, and every change since, with reasons |
| [`v2/build/`](v2/build/) | The R code that fetches, verifies and builds everything, with the fixed attribution tables it uses |
| [`v2/output/`](v2/output/) | Entry-level files behind the panel (every SDN addition and every OFAC penalty, with the source text it was read from), build logs, and the check against CNAS totals |
| [`v2/sources/`](v2/sources/) | Manifests: the URL, retrieval date and SHA-256 checksum of every source file |

## Design

- **Unit and frame.** Target country-year; every member of the Correlates of
  War state system, 1950–2025 (2025 carries forward the 2024 membership). The
  United States is excluded as a target.
- **Channels, never summed.** Financial (additions to OFAC's SDN list),
  penalties (OFAC civil penalties), kinetic (armed conflicts with the US as a
  party, against a state's government or alongside it), covert action
  (US regime change attempts, 1950–1989; US support short of troops to a side
  in a war, 1975–2017) and
  posture (US troops stationed in the country) are separate series. There is no composite score.
- **Missing is not zero.** A zero means the source covers the country-year and
  records nothing; outside a source's coverage the cell is blank.
- **Two attributions.** Financial and penalty events are attributed to the
  country their sanctions program targets and, separately, to the country
  where the listed or penalized party is located.

## Rebuild

From the repository root, in R:

```
Rscript v2/build/fetch_sources.R   # download every public source and verify its checksum
Rscript v2/build/run_all.R         # build the panel
```

Requires R with `countrycode`, `troopdata` (1.1.0), `haven`, `readxl`,
`jsonlite` and `digest`, poppler's `pdftotext`, and a UTF-8 locale. The Global Sanctions Data Base (release 5)
is distributed by its authors on request and may not be redistributed; place
its files in `v2/sources/raw/` as `fetch_sources.R` describes. Rebuilt from an
empty folder on 2026-10-27 (every public source re-downloaded and verified),
all eight output files matched the committed ones byte for byte. On
2026-10-29, after the proxy channel and new covariates were added, a fresh
clone was rebuilt: the new sources were downloaded and every source was
verified against the manifests (the OFAC files were copied from the copy
already verified on 2026-10-27, not re-downloaded), and all 14 committed
output files matched byte for byte.

## Earlier version

Version 1, a panel of sanctioned states only (942 country-years, 43 states),
was retired on 2026-10-27 because the code that built it was never public. It
remains in the repository's history at tag
[`v1-2026-10-17`](https://github.com/SeanBRogers/Enforcement-Intensity-Index-EII/tree/v1-2026-10-17)
(commit `686d009`), kept for the v1–v2 comparison and not for citation.
