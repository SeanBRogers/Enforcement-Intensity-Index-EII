# EII: Enforcement Intensity Index

Zero-inflated negative binomial estimation of enforcement intensity in strategically produced data.

**Sean Rogers** | University of South Carolina | Department of Political Science

> **Status (2026-10-27): v1 is retired; v2 is being rebuilt from raw sources.**
> Everything below this box describes v1 (tag `v1-2026-10-17`, commit `686d009`),
> kept as the benchmark v2 is compared against. Its results should not be cited
> as current. The v2 build is governed by [`BUILD_PROTOCOL.md`](BUILD_PROTOCOL.md),
> committed before any v2 source was downloaded. A **partial** v2 release (all
> states, 1950–2025: US sanctions flag, kinetic and posture channels) is in
> [`v2/`](v2/), documented in [`v2/CODEBOOK_v2.md`](v2/CODEBOOK_v2.md). It is not
> for estimation until every channel is built and validated.

## Overview

The EII measures enforcement intensity across sanctioned states by triangulating institutional primary sources across four layers (listed below). This approach addresses a core measurement problem: the institutions producing enforcement data have survival incentives to misreport. No single source can be treated as ground truth. The EII builds a composite from sources that misreport in different directions for different institutional reasons. Whether the composite recovers signal that a single source obscures is something the project tests, not an established result; Layer 2 alone contributes 92.8% of all index points (`codebook_checks_R.Rout`).

The estimation uses a zero-inflated negative binomial (ZINB) model to separate two processes: enforcement intensity (conditional on engagement) and sanctuary (structural non-enforcement). The model is estimated by maximum likelihood (`pscl`) and by Bayesian MCMC (`brms`), and every run compares the two by name.

## Status (2026-10-17)

Every result in this repository comes from one logged run of the script that produced it, all made on one machine on 2026-10-17 (Windows 11, R 4.6.1; package and CmdStan versions in `sessionInfo_R.txt`, written by `run_followons.R`). The follow-on runs carry timestamps in `run_followons_R.Rout`; the main pipeline and regime-break logs do not. Each script `x.R` leaves its complete log as `x_R.Rout` beside its outputs. Numbers in `LAB.md`, `CODEBOOK.md` and this file are taken from those logs, from the output files the scripts write, and from the audit log `panel_corrections.csv`.

- The panel was audited against its stated sources on 2026-10-17. Every changed cell is logged in `panel_corrections.csv` and described in `CODEBOOK.md`. Results computed on the panel before the audit should not be cited.
- Figures 1 and 2 as drawn before 2026-10-17 attached variable labels in reverse order. The figures in this repository are corrected (`LAB.md`). Copies of the earlier figures are mislabeled wherever they appear.
- The Python implementation was retired on 2026-10-17. It had not been run on the corrected panel, and an implementation that has not been run checks nothing. The repository is R only.

## Main results (corrected panel, V-Dem electoral, Bayesian, diffuse priors)

Count equation, enforcement intensity given engagement. 538 country-years, 33 states, 1970–2021. Posterior mean, 95% HDI, and P(dir.), the posterior probability that the coefficient has the sign of its mean (`EII_pipeline_R.Rout`).

| Variable | Mean | 95% HDI | P(dir.) |
|---|---|---|---|
| fiscal pressure (net interest, % GDP) | −1.305 | [−1.794, −0.785] | 1.000 |
| trend | −0.887 | [−1.410, −0.373] | 1.000 |
| GDP per capita (log) | −0.544 | [−0.846, −0.218] | 1.000 |
| regime (V-Dem electoral) | +0.583 | [0.203, 0.943] | 0.999 |
| degradation (armed conflict) | +0.617 | [−0.027, 1.223] | 0.970 |
| friction (UNGA distance) | −0.286 | [−0.705, 0.111] | 0.908 |
| resource rents | −0.106 | [−0.344, 0.138] | 0.811 |
| friction × fiscal | +0.154 | [−0.227, 0.545] | 0.782 |

All eight count signs match the maximum-likelihood fit. The friction × fiscal interaction is null under every prior. The early-versus-late fiscal break (`regime_break_bayes.R`) is **inconclusive** against the bars stated in the script's header (`LAB.md` explains how they were set and how the verdict code was corrected). Full results, diagnostics and caveats are in `LAB.md`.

## Repository contents

```
README.md, LAB.md, PREREGISTRATION.md, CODEBOOK.md, .gitignore

Data
  EII_Panel_Definitive.csv      Panel, 942 country-years, 43 state names (44 codes), 1945–2025
  panel_corrections.csv         Every cell changed in the 2026-10-17 audit: original value, new value, source, reason
  fiscal_indicators.csv         Five FRED fiscal series, 1945–2025 (written by fiscal_pull.R)

Main estimation
  EII_pipeline.R                pscl + brms; four priors; clean-elections and Polity5 robustness; DV sensitivity; figures
  validate.R                    44 regression checks against the frequentist baseline

Source and codebook checks
  verify_sources.R              Each covariate against its stated external source
  degradation_audit.R           degradation rebuilt from UCDP/PRIO; pre-audit panel reconstructed and refit
  codebook_checks.R             Every descriptive number in CODEBOOK.md, computed and checked

Follow-on analyses (LAB.md, open questions)
  fiscal_pull.R, divergence_diagnostic.R, layer_decomposition.R,
  period_split.R, spend_cost_split.R, regime_break_bayes.R

Runner
  run_followons.R               Runs the source checks, codebook checks, validate.R and the frequentist
                                follow-ons, one logged run each, and writes sessionInfo_R.txt

Logs (one per script)           *_R.Rout, plus sessionInfo_R.txt

Outputs
  EII_pipeline.R                bayesian_results_all_specs_R.csv, weighting_sensitivity_R.csv,
                                panel_estimation_sample_R.csv, fig1–fig7 *_R.png
  regime_break_bayes.R          regime_break_posteriors.csv
  degradation_audit.R           degradation_audit.csv
  divergence_diagnostic.R       fiscal_divergence.csv, fig_divergence.png
  layer_decomposition.R         layer_substitution_test.csv
  period_split.R                period_split_test.csv
  spend_cost_split.R            spend_cost_split.csv

Not committed (*.rds): fitted brms models, reproducible from the scripts with seed 42
```

## EII construction

The dependent variable sums four layers of institutional enforcement data:

| Layer | Source | Years with nonzero values in the panel |
|-------|--------|----------|
| 1. OFAC Executive Actions | Federal Register, OFAC SDN | 1979– |
| 2. Multilateral Designations | OpenSanctions, IMF MONA | 1980– |
| 3. Agency Enforcement | OFAC civil penalties | 2003– (source begins 2003) |
| 4. Kinetic Operations | COW MID, UCDP/PRIO, GED | 1950–2024 |

Each source's coverage by year is not documented in this repository (`CODEBOOK.md`, open items); a zero can mean no event or no source.

`eii_score = layer1 + layer2 + layer3 + layer4`

## Model

**Count equation** (what drives enforcement intensity given engagement):

```
log(μ) = β₀ + β₁·resource + β₂·friction + β₃·degradation + β₄·fiscal
         + β₅·trend + β₆·regime + β₇·gdp_pc + β₈·friction×fiscal
```

**Zero-inflation equation** (what predicts structural zeros, or sanctuary), with π = P(structural zero) as in `pscl` and `brms`:

```
logit(π) = γ₀ + γ₁·regime + γ₂·friction + γ₃·resource + γ₄·degradation + γ₅·trend
```

A positive γ means more sanctuary.

## Requirements

R 4.6.1 with pscl 1.5.9, brms 2.23.0, cmdstanr 0.9.0 and CmdStan 2.40.0, tidyverse 2.0.0, loo 2.10.1, bayesplot 1.16.0, posterior 1.7.0, here 1.0.2 (full list in `sessionInfo_R.txt`). `validate.R` also uses MASS, which ships with R. `verify_sources.R` also needs readxl and jsonlite. `verify_sources.R`, `degradation_audit.R` and `fiscal_pull.R` download their sources, so they need an internet connection.

Every script except `codebook_checks.R` (base R only) begins with `.libPaths(c("C:/R/library", .libPaths()))`, the author's local package library. On a machine without that folder R ignores the entry.

## Usage

Run every script from the repository folder with `R CMD BATCH`, so it leaves its log:

```
R CMD BATCH --no-save --no-restore validate.R validate_R.Rout            # first, and after any change
R CMD BATCH --no-save --no-restore EII_pipeline.R EII_pipeline_R.Rout    # main estimation, about 10 minutes
R CMD BATCH --no-save --no-restore regime_break_bayes.R regime_break_bayes_R.Rout
R CMD BATCH --no-save --no-restore run_followons.R run_followons_R.Rout  # source checks and frequentist follow-ons
```

`run_followons.R` re-pulls the FRED series and stops before any analysis if they no longer match `fiscal_indicators.csv`. It puts the committed file back afterwards, so the analyses always read the committed series.

## Estimation design

- **Primary regime measure:** V-Dem Electoral Democracy Index (`v2x_polyarchy`)
- **Additional:** V-Dem Clean Elections Index (`v2xel_frefair`), Bayesian in `EII_pipeline.R`; `validate.R` checks that its frequentist count signs match the primary specification
- **Robustness:** Polity5 `polity2`, frequentist only
- **Prior sensitivity:** four Bayesian specifications (Diffuse, Sequential, Skeptical, Restrictive). "Sequential" is a name only: its interaction prior is N(−0.1, 1.0), and the proxy-panel run it was meant to update from cannot be reproduced (`LAB.md`)
- **DV sensitivity:** three alternative DV constructions: raw count, financial only (layers 1–3), and equal weight. Equal weight is not identified under the ZINB (`LAB.md`)
- **Sampler:** 4 chains × 2,000 iterations (1,000 warmup), adapt_delta 0.90, seed 42, one core

## Panel

- 942 country-years, 43 state names, 1945–2025; 33 states in the estimation sample
- Nicaragua's two sanctions episodes carry separate codes, `NIC` (1985–1990) and `NIC_2` (2018–2025), under one name, so there are 44 codes for 43 names. Rhodesia (1965–1979, `RHO`) and Zimbabwe (2003–2025, `ZWE`) are listed as separate states; counted as one, the frame has 42
- `NIC_2` enforcement layers are missing (not built): the original source joins failed for that code
- Rows for 2022–2025 are not built under the extension protocol, and the code that produced them is not in this repository; no estimate uses them (`PREREGISTRATION.md`)
- 538 complete cases in the estimation sample, 1970–2021
- Binding constraints: `resource_density` (WDI ends 2021; alone excludes 95 otherwise complete rows) and `friction` (no prior-year ideal point; alone excludes 30); the DV is missing for 4 otherwise complete rows (`NIC_2` 2018–2021)

## Reproducibility

The main model is estimated two ways in one run, by maximum likelihood (`pscl`) and by MCMC (`brms`), and `EII_pipeline.R` compares them coefficient by coefficient, by name (Section 10 of its log). That is one platform, not two. A second, independent implementation would catch errors that a single platform cannot; there is none now, and rebuilding one is an open item (`LAB.md`).

The MCMC runs use seed 42 on one core. On different hardware or package versions the same seed can give slightly different draws, so a rerun elsewhere should match the posterior summaries closely but not necessarily to the last digit. `validate.R` holds the frequentist baseline (44 checks) and should be run first on any new machine.

## Citation

Rogers, Sean. 2026. Working paper, University of South Carolina. (Working title under revision; final citation will be posted on submission.)

## License

Data and code are provided for replication purposes. Please cite accordingly.
