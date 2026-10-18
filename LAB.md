# EII Lab

Measurement and estimation for enforcement data produced by the
institutions being measured.

---

## Why this is a lab and not a paper

In September 2026 a parameter-ordering bug produced a frequentist
coefficient table in which every variable carried another variable's
estimate. `statsmodels` returns ZINB parameters as
`[inflate, count, alpha]`; the extraction code read them as if the
count block came first. The error survived about five weeks
(2 September to 5 October 2026) and a full round of paper planning. It
was caught only because the model was ported to R and the two
implementations disagreed.

On 2026-10-17 an audit of the panel against its stated sources found
that the `degradation` covariate did not reproduce from UCDP/PRIO, that
the `polity` column did not follow any consistent rule, that `friction`
came from an unidentified earlier release, and that several columns had
lost rows in source joins (see **Panel audit** below). Every estimate
computed before that audit has been withdrawn.

The same day, two more errors were found in the code itself, both
during the rerun on the corrected panel:

- **Figures 1 and 2 were mislabeled.** `EII_pipeline.R` attached the
  variable names to the posterior densities by position, in reverse
  order (`scale_y_discrete(labels = rev(...))` on a bayesplot axis that
  does not follow that order), so each density carried another
  variable's name. The labels are now attached by parameter name. Every
  copy of Figures 1 and 2 drawn before 2026-10-17 is mislabeled.
- **The regime-break verdict applied a looser bar than its own
  header.** The header of `regime_break_bayes.R` says the break holds
  only if the early-period effects reach P(dir.) of about 0.95 while the
  late posteriors sit on zero, and fails if they fall below about 0.90.
  Its verdict code tested 0.90 for "holds", and on its first run on the
  corrected panel it printed "SURVIVES" with early cost at 0.902. The
  verdict code was then rewritten to apply the header's bars, reading
  "sit on zero" as both late P(dir.) below 0.90, and with the same seed
  it gives INCONCLUSIVE (see **Open questions**). The script records the
  change and its date; the first run's log is in the author's archive,
  outside this repository, so the first-run result cannot be checked
  here. The header was written after the frequentist version of the same
  split on the corrected panel had been seen (it quotes those results),
  so this test falls short of rule 3: read it as a check on that result,
  not as a prediction made before the data was seen.

The lesson is not "check your indexing." It is that single-platform,
single-source work hides errors that replication and source checks
expose, and that a finding is only as good as the machinery that could
have falsified it.

---

## Operating rules

1. **Two estimators, compared by name, in every run.** Every
   coefficient that enters a manuscript is produced by `pscl` (maximum
   likelihood) and `brms` (MCMC) in the same run of `EII_pipeline.R`,
   and the two are compared by coefficient name, never by position.
   Disagreement in sign is a bug until proven otherwise. This is one
   platform. The independent Python implementation that once served as
   the second platform was retired on 2026-10-17: it had not been run on
   the corrected panel, and an implementation that has not been run
   checks nothing. Rebuilding a second-platform implementation is an
   open item. The follow-on analyses (`period_split.R`,
   `spend_cost_split.R`, `layer_decomposition.R`,
   `degradation_audit.R`: `pscl` only; `regime_break_bayes.R`: `brms`
   only) have one estimator each.

2. **`validate.R` before anything leaves.** Run it before sending
   results, after any panel change, after any code change, after any
   package upgrade. A failure is not necessarily an error, but it must
   be explained before the number travels.

3. **Predictions and falsification conditions go in the script,
   written before the data is seen.** Every test script in this repo
   states what would confirm the hypothesis and what would kill it,
   above the code. This is the only defense against rebuilding an
   instrument until it gives the wanted sign. A verdict rule changed
   after a run may only move toward the stated condition, and the
   change is dated in the script.

4. **No number enters a manuscript from a chat log, a figure, or an
   old draft.** Only from a logged run of code in this repo. Every
   script is run with `R CMD BATCH` and its log (`<script>_R.Rout`) is
   committed beside its outputs.

5. **Nulls are results.** The friction × fiscal interaction is null.
   The layer substitution test finds fiscal null in every layer
   (verdict MIXED). The regime break is inconclusive. All are in the
   repo with their outputs.

---

## Current baseline (2026-10-17, corrected panel)

All runs on one machine: Windows 11, R 4.6.1. The pipeline log shows
brms 2.23.0, pscl 1.5.9, loo 2.10.1 and posterior 1.7.0 loading; the
full package list, with cmdstanr 0.9.0 and CmdStan 2.40.0, is in
`sessionInfo_R.txt`, written by `run_followons.R` after the main run
from the same library. Sources: `EII_pipeline_R.Rout`,
`validate_R.Rout`.

**Panel.** 942 country-years, 43 state names (44 codes), 1945–2025.
**Estimation sample.** 538 complete cases, 33 states, 1970–2021;
49.6% zeros, variance/mean 1124.9.

### Count equation: enforcement intensity

| Variable | MLE (pscl) | p | Bayes mean (diffuse) | 95% HDI | P(dir.) |
|---|---|---|---|---|---|
| resource | −0.148 | 0.206 | −0.106 | [−0.344, 0.138] | 0.811 |
| friction | −0.239 | 0.250 | −0.286 | [−0.705, 0.111] | 0.908 |
| degradation | +0.656 | 0.038 | +0.617 | [−0.027, 1.223] | 0.970 |
| fiscal (cost) | −1.485 | < 0.001 | −1.305 | [−1.794, −0.785] | 1.000 |
| trend | −0.879 | 0.001 | −0.887 | [−1.410, −0.373] | 1.000 |
| regime | +0.601 | 0.002 | +0.583 | [0.203, 0.943] | 0.999 |
| gdp per capita | −0.557 | < 0.001 | −0.544 | [−0.846, −0.218] | 1.000 |
| friction × fiscal | +0.203 | 0.262 | +0.154 | [−0.227, 0.545] | 0.782 |

MLE log-likelihood −1545.31. All eight count signs agree between the
two estimators. Every MLE count sign is the same under V-Dem clean
elections and under Polity5 `polity2` (Polity sample 443 rows;
`validate_R.Rout`).

**Reading.** Enforcement intensity falls with U.S. fiscal pressure,
over time, and with target GDP, and rises with target democracy, all
with P(dir.) of 0.998 or more. It rises with armed conflict in the target
(P(dir.) 0.970; the HDI reaches just below zero). Diplomatic distance
(friction) does not raise intensity: its count coefficient is negative
(P(dir.) 0.908, short of 0.95), and in the sanctuary equation below it
points toward a higher probability of a structural zero (P(dir.) 0.978;
the HDI reaches just below zero). Grouping friction with
conflict as drivers of escalation is not supported by these estimates.

### Zero-inflation equation: sanctuary (positive = more structural zeros)

| Variable | Bayes mean (diffuse) | 95% HDI | P(dir.) | MLE |
|---|---|---|---|---|
| regime | −0.053 | [−1.500, 1.191] | 0.500 | +1.332 |
| friction | +0.757 | [−0.020, 1.497] | 0.978 | +4.329 |
| resource | +0.177 | [−0.578, 0.989] | 0.705 | +0.458 |
| degradation | −0.495 | [−2.200, 0.990] | 0.720 | −4.625 |
| trend | −3.266 | [−5.222, −1.690] | 1.000 | −16.419 |

Zero inflation is supported: against a plain negative binomial,
likelihood ratio 81.5 on 6 df (p = 1.7e-15; AIC 3122.6 vs 3192.2; the
χ² p-value is approximate because the test sits on a boundary, which
does not matter at this size). Its
MLE is unstable: 14.3% of rows have P(structural zero) above 0.5 and
8.0% above 0.99 (quasi-separation), so the MLE coefficients are large
with wide standard errors (intercept −19.7, SE 10.2; trend −16.4, SE
8.3). Read this equation from the Bayesian run, where the priors
regularize it. The two estimators agree in sign on four of five
coefficients; on regime they differ, but the Bayesian posterior is
centered on zero (P(dir.) 0.500) and the MLE has p = 0.21, so neither
supports a regime effect on sanctuary. `pscl` and `brms` both model
P(structural zero).

Overdispersion (NB shape): 0.177, 95% interval [0.147, 0.206].

### V-Dem clean elections (Bayesian, diffuse)

Count: friction −0.406 (P(dir.) 0.992), degradation +1.355 (1.000),
fiscal −1.136 (1.000), trend −0.775 (0.999), regime +1.034 (1.000),
GDP −0.719 (1.000), resource −0.045 (0.675), interaction +0.132
(0.760). Sanctuary: friction +0.797 (0.990), trend −3.336 (1.000);
regime, resource and degradation null. Same count signs as the
primary specification, with friction and degradation sharper. In the
sanctuary equation the regime sign differs (+0.161 here, −0.053 in the
primary), but both posteriors sit on zero (P(dir.) 0.650 and 0.500).

### Prior sensitivity

The friction × fiscal interaction under the four priors (mean,
P(< 0)): Diffuse 0.154, 0.218; Sequential 0.150, 0.222; Skeptical
0.124, 0.249; Restrictive 0.122, 0.262. Every HDI spans zero. P(dir.)
for fiscal is 1.000 and for regime 0.999 under all four; friction
ranges 0.903–0.935; trend 0.998–1.000.

### Diagnostics

| Specification | max R-hat | min ESS | Divergences |
|---|---|---|---|
| Diffuse | 1.0055 | 1290 | 0 |
| Sequential | 1.0028 | 1507 | 0 |
| Skeptical | 1.0042 | 1448 | 0 |
| Restrictive | 1.0026 | 1540 | 0 |
| V-Dem clean elections | 1.0025 | 1228 | 0 |

4 chains × 2,000 iterations (1,000 warmup), adapt_delta 0.90, seed 42.
ESS is the minimum over parameters of `neff_ratio × 4000`.

**Model comparison (LOO).** The four prior specifications are
indistinguishable: every elpd difference is within 1.3 of the best
(Restrictive) and within two standard errors of zero. Each fit has 3 or 4 observations with Pareto k > 0.7, so
the LOO estimates rest on a few observations LOO cannot approximate
well. Before LOO is cited, rerun it with `moment_match = TRUE` or report
the flagged observations.

**Posterior predictive check (diffuse).** Zero rate: observed 49.6%,
predicted 51.9% [46.7, 56.9]. Mean: observed 56.37, predicted 74.80
[40.74, 134.11]. Variance/mean: observed 1124.9, predicted 2143.5
[474.4, 8570.0]. Every observed statistic lies inside its interval; on
average the model predicts a higher mean and more dispersion than the
data show.

**DV sensitivity (MLE; `weighting_sensitivity_R.csv`).** Friction,
fiscal, trend, interaction (p): EII score −0.239, −1.485, −0.879,
+0.203 (0.262); raw count (capped) +0.238, −0.424, −0.484, +0.088
(0.462); financial only (layers 1–3) −0.148, −1.316, −1.007, +0.290
(0.266); equal weight not identified (NB dispersion at its boundary,
θ = 1.03e11). Fiscal stays negative under every identified
construction; friction changes sign under the capped raw count.

### What the audit changed

`degradation_audit.R` reconstructs the pre-audit panel by reverting
every logged cell and fits it (`degradation_audit_R.Rout`). Pre-audit
(535 rows) → current (538 rows): degradation −1.083 → +0.656; resource
+0.336 → −0.148; friction −0.412 (p = 0.055) → −0.239 (p = 0.250);
fiscal −1.081 → −1.485; trend −0.340 → −0.879; regime +0.353 → +0.601;
GDP −0.669 → −0.557; interaction +0.057 → +0.203 (p = 0.26). The
degradation and resource signs reverse; fiscal and GDP stay negative;
the interaction stays null.

---

## Panel audit (2026-10-17)

The panel was checked column by column against its stated sources
(`verify_sources.R`: Polity5 `p5v2018`, V-Dem v16, UNGA ideal points,
FRED, World Bank WDI; `degradation_audit.R`: UCDP/PRIO ACD v25.1). Both
pass every check in their 2026-10-17 logs; `gdp_pc_log` is reported
against a tolerance (684 of 691 rows within 0.01 of current WDI). Every cell changed
(1,434) is logged in `panel_corrections.csv` with its original value,
new value, source and reason. `codebook_checks.R` counts them and
checks the audit details below (the per-state breakdown, the friction
correlation, the cells filled, the rows the audit added to the
estimation sample). Details per column are in `CODEBOOK.md`.

- **`degradation` rebuilt from UCDP/PRIO** (armed conflict located in
  the state, any intensity). The original column agreed with UCDP on
  88.8% of the 908 codable rows; all 102 disagreements were conflict
  country-years coded 0 (Afghanistan 26, Pakistan 23, Cambodia 16,
  Rhodesia 9, Nicaragua 6, Laos 5, South Africa 5, North Korea 4,
  Liberia 3, Niger 2, Haiti, Panama and Sierra Leone 1 each). In the
  estimation sample there were 54: Afghanistan 2002–2021 (20 rows, mean
  EII 179), Pakistan in 20 of the 21 years 2001–2021 (all but 2005; mean
  EII 256), Haiti 1991, Laos 1986–1990, Nicaragua 1985–1990, Panama 1989
  and Sierra Leone 2001. 1945, 2025 and Hong Kong cannot be coded from
  ACD v25.1 and are missing.
- **`friction` rebuilt from the July 2025 UNGA ideal-point release**
  with the construction the old values follow (|US − state|
  `idealpointfp`, lagged one year; correlation 0.998 with the old
  column). This filled Serbia 1992–1993 and 2001–2003 and `NIC_2`, and
  brought Serbia 2001–2003 into the estimation sample (535 → 538).
- **`polity` rebuilt as Polity5 `polity2`.** The original column filled
  −66 occupation years inconsistently (Afghanistan 2001–2013 carried
  −7), gave values after 2018, when Polity5 ends, and to Rhodesia and
  Hong Kong (not in Polity5), and disagreed with Polity5 for East Germany
  1949–1959, Sudan 1999–2010 and North Vietnam in 1964 and 1973–1975.
- **V-Dem:** 77 rows filled that exist in V-Dem v16 but were lost in the
  original join (East Germany 1949–1990, Rhodesia, North Vietnam
  1964–1975, Nicaragua 2018–2025).
- **`NIC_2`** (Nicaragua 2018–2025): enforcement layers and DV columns
  set missing. The original build gave zero on every layer despite
  EO 13851 (November 2018). WDI resource rents and GDP filled.

**Open.** Six states are zero on all four layers across their whole
span (Eritrea 2010–2025, East Germany 1945–1990, Cambodia 1975–1992,
Rhodesia 1965–1979, Niger 2023–2025, South Africa 1985–1991); Cuba has
zero Layer 1 events 1962–2025; and Layer 4 is zero in every 2025 row,
consistent with UCDP v25.1 ending in 2024. These may be true zeros or
gaps in source coverage or joins. The panel build code is not in this
repository, so they stay flagged until the layers are re-pulled.

---

## Open questions

**The regime break is inconclusive.** `regime_break_bayes.R` fits the
Bayesian ZINB separately to 1970–2002 (197 rows, 19 states, 76.1%
zeros) and 2003–2021 (341 rows, 28 states, 34.3% zeros) with N(0, 1.5)
priors, spend (net outlays, % GDP) and cost (net interest, % GDP)
entered separately. The script's header sets the bars at about 0.90
(fails) and about 0.95 with the late posteriors on zero (holds). The verdict code, corrected after the first run (see
**Why this is a lab**), implements them as: the break holds if early
spend is positive and early cost negative, both with P(dir.) ≥ 0.95,
and both late P(dir.) < 0.90; it fails if both early P(dir.) are below
0.90; anything else is inconclusive.

| | Early 1970–2002 | Late 2003–2021 |
|---|---|---|
| Spend | +1.052, HDI [−0.293, 2.319], P(dir.) 0.942 | +0.100, HDI [−0.242, 0.436], P(dir.) 0.710 |
| Cost | −0.779, HDI [−2.024, 0.370], P(dir.) 0.902 | −0.048, HDI [−0.306, 0.221], P(dir.) 0.640 |

Verdict: INCONCLUSIVE. The late period is null on both. Neither early
effect reaches 0.95; early spend is about two Monte Carlo standard
errors below it (MCSE 0.0037; ESS bulk 5171). Early cost sits 0.002
above 0.90, within its own Monte Carlo error (MCSE 0.0050): under the
original 0.90 code the verdict on these draws turned on simulation
noise. The early-minus-late differences are not decisive either
(spend: P(diff > 0) = 0.915; cost: P(diff > 0) = 0.126), and the script
treats them as descriptive because the two periods are separate models.
Diagnostics: max R-hat 1.0031 (early) and 1.0025 (late), no
divergences. What can be said: the fiscal–enforcement link is null
after 2003; before 2003 the signs match a fiscal mechanism but fall
short of the header's bar; a break is not established.

Two limits on reading it. Each period z-scores its own variables, so
early and late coefficients are in different units: signs and P(dir.)
compare, magnitudes do not. And spend, cost and trend vary by year
only, so in each window they rest on 33 and 19 time points however many
country-years there are.

**The period split fails its own test, on a degenerate fit.**
`period_split.R` states in advance that if fiscal pressure is null in
both subperiods, "the pooled result is an artifact of pooling." On the
corrected panel: pooled −1.485 (p < 0.001), 1970–2002 −1.052
(p = 0.100), 2003–2021 −0.017 (p = 0.898); verdict FALSIFIED
(`period_split_test.csv`). The verdict is knife-edge: it turns on the
early p = 0.1003 against the script's 0.10 cutoff. Two caveats. The script's own: the late
window has little variance in the fiscal variable (SD 0.164 vs 0.583
over country-years). And the early fit is degenerate: every coefficient
in its zero-inflation equation runs to the boundary (from −312 to +78,
standard errors from about 7,100 to 71,900; `period_split_R.Rout`), so
the early p-value is not reliable. In the late fit only the
zero-inflation coefficient on degradation diverges (−16.0, SE 899); the
rest of that fit is well behaved. The verdict stands until a
better-specified test replaces it.

**Spend and cost are different things, and spend does nothing pooled.**
`cor = 0.042` across the 52 sample years 1970–2021. Over the 33 early
and 19 late sample years, spend SD 1.52 → 3.26 and cost SD 0.70 → 0.17.
`spend_cost_split.R` states in advance that if spend is null "the
expansion mechanism does not operate through outlay." Pooled, spend is
+0.005 (p = 0.975) and cost −1.487 (p < 0.001); verdict "COST
SUPPORTED, spend not." By period: 1970–2002 spend +1.887 (p = 0.019),
cost −1.102 (p = 0.073); 2003–2021 spend +0.091 (p = 0.595), cost
−0.029 (p = 0.830). The early fit's zero-inflation equation runs to the
boundary and its standard errors do not compute (NaN in
`spend_cost_split_R.Rout`), so the early p-values are not reliable; as
in the period split, the late fit diverges only on the zero-inflation
degradation coefficient. The Bayesian version of this test is the
regime break above.

**Explanations for the post-2003 null are untested.** Candidates that
fit the timing include the debt constraint not binding while borrowing
was cheap (the reading in `period_split.R`), the reorganization of the
enforcing agencies in 2003–2004, and the cost of the wars in Iraq and
Afghanistan. None is tested here. Total outlays, which include war
spending, are already the spend variable, and they are null after 2003
despite their larger variance; a war explanation would have to work
through composition or capacity, not the size of the budget. Any of
these enters the repo as a new script with its prediction written
first.

**The estimation sample ends before the test case.** Net interest was
1.49% of GDP in 2021 and 3.15% in 2025 (`fiscal_indicators.csv`). The
constraint returned after the estimation sample stops (2021, where
`resource_density` ends); the panel's 2022–2025 rows are not yet built
under the extension protocol. Extension to 2025 is the
highest-value build available (`PREREGISTRATION.md`).

**Extensive vs intensive expansion.** The DV counts events, so it
measures states-entering-the-frame well and apparatus-thickening
poorly. A new reporting rule generates zero events and imposes
enormous cost. Scope condition, not flaw, but it should be stated.

**The fiscal divergence.** Residual from `net_interest ~ debt + yield`
(FRED data, 1966–2025; unaffected by the panel audit;
`divergence_diagnostic_R.Rout`) passes gate 1 (trend r = 0.054). Gate
2 prints no verdict; its variance ratio is 0.73, far above the ~0.15
level the script warns about. Gate 3 has no pass threshold in the
script; the AR(1) is 0.884, which is what that gate was written to warn
about. Reading the residual as maturity structure rather than reporting
distortion is an interpretation, not something this repository tests.
A corrected benchmark needs Treasury average interest rates, available
only from 2001.

**IV-side triangulation does not exist.** The DV draws on several
sources across its four layers (Layer 3 has one; see `CODEBOOK.md`).
Every predictor is single-source: OMB (via FRED) for fiscal, the UNGA
ideal points for friction, V-Dem/Polity for regime, UCDP/PRIO for
degradation. The priors range from weakly informative (Diffuse) to
deliberately tight (Skeptical, Restrictive), but none is informed by
prior evidence, because no independent measurement of these effects
exists to inform them.

**No second platform.** Rule 1 now rests on two estimators in one R
run. A second implementation in another language, run on the corrected
panel and compared by name, would restore the check that caught the
September bug.

---

## Dead ends (do not revisit without new evidence)

**"The financial-only DV makes friction × fiscal significant
(p = 0.021)."** A positional misread of statsmodels output, which orders
parameters [inflate, count, alpha]: the 0.021 was the p-value of the
count friction coefficient. Read by name, the interaction was null.

**"MLE and Bayes disagree in sign on 5 of 8 count coefficients."** Also
the misread. The old comparison read count variable *i* at
`params[i+1]`; on the layout [inflate ×6, count ×9, alpha] those
positions are five inflate coefficients, the count intercept, count
resource and count friction, which reproduces "five of eight" exactly,
and its "interaction β = −0.412, p = 0.055" was the count friction
coefficient. Read by name, the frameworks agree on every count sign,
on the pre-audit panel then and on the corrected panel now. Any
simulation that compared the two by position carries the same artifact;
the September prototype Monte Carlo is not in this repository and is
unverified.

**Equal-weight DV under ZINB.** `eii_equal` (number of active layers,
0–4) has no overdispersion, so the NB dispersion runs to its boundary
and the model is not identified. The pipeline reports the row as not
identified instead of estimating it.

**Sequential updating from the proxy panel.** The 25-country proxy EII
was built in an ephemeral container in May 2026 and no longer exists.
Its posteriors cannot be verified and must not be used as priors. The
prior specification named `Spec2_Sequential` centers the interaction at
−0.1 with SD 1.0; it does not encode any proxy posterior and should be
read as one more prior.

**Single-factor fiscal strain index.** The five candidate indicators'
correlations do not support one factor (no factor model was fit).
`net_interest` vs `debt_gdp` correlate at −0.010; `yield10` vs
`debt_gdp` at −0.773 (`fiscal_pull_R.Rout`).

**Layer substitution under fiscal strain.** On the corrected panel all
four fiscal coefficients are null in 2003–2021 (p = 0.63 to 1.00);
verdict MIXED (`layer_substitution_test.csv`). No asymmetry can be read
from it, because the fiscal variable barely moves in that window
(SD 0.164).

---

## Files

| File | Purpose | Log |
|---|---|---|
| `EII_pipeline.R` | Main estimation: MLE and Bayesian, 4 priors, clean elections, Polity5, DV sensitivity, figures | `EII_pipeline_R.Rout` |
| `validate.R` | 44 regression checks against the frequentist baseline | `validate_R.Rout` |
| `verify_sources.R` | Each covariate against its stated external source | `verify_sources_R.Rout` |
| `degradation_audit.R` | Rebuilds `degradation` from UCDP/PRIO; reconstructs and fits the pre-audit panel (`degradation_audit.csv`) | `degradation_audit_R.Rout` |
| `codebook_checks.R` | Every descriptive number in `CODEBOOK.md`, computed and checked | `codebook_checks_R.Rout` |
| `fiscal_pull.R` | Five fiscal indicators from FRED, 1945–2025 | `fiscal_pull_R.Rout` |
| `divergence_diagnostic.R` | Three gates on the reporting-gap construct | `divergence_diagnostic_R.Rout` |
| `layer_decomposition.R` | Spectacle vs apparatus substitution test | `layer_decomposition_R.Rout` |
| `period_split.R` | Early/late split on the original specification (`period_split_test.csv`) | `period_split_R.Rout` |
| `spend_cost_split.R` | Spend and cost as separate mechanisms (`spend_cost_split.csv`) | `spend_cost_split_R.Rout` |
| `regime_break_bayes.R` | Bayesian test of the period break (`regime_break_posteriors.csv`) | `regime_break_bayes_R.Rout` |
| `run_followons.R` | Runs the checks and frequentist follow-ons, one logged run each | `run_followons_R.Rout` |
