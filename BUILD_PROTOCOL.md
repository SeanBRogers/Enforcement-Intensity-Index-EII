# EII v2 — Build Protocol

**Protocol of record, committed 2026-10-27, before any v2 source file was
downloaded (Rule 1).** Design answers are Sean Rogers's, given in a working
session on 2026-10-27 and quoted where they set a rule. Defaults proposed by
Claude are marked as such; Sean accepted them in the same session. Changes
after this commit are logged in section 8 with date and reason.

The decision to rebuild is Sean's (LOCKED, 2026-10-17; Canon & Searles
Scaffold v2, Part X). Source coverage in section 3 was checked against each
source's own site on 2026-10-27.

---

## 1. Decision of record

The v1 panel (`EII_Panel_Definitive.csv`, commit `686d009`, 2026-10-17) is
retired as an object of estimation. Its only remaining use is as the
benchmark v2 is compared against (Rule 7). It is frozen as git tag
`v1-2026-10-17` on commit `686d009`, pushed by Sean (the build session
cannot push tags).

---

## 2. Governance rules (proposed by Claude, Part X; accepted by Sean 2026-10-27)

1. **Protocol before data.** This file is committed, dated, before any
   source is downloaded.
2. **Raw sources kept as downloaded.** Each source file is saved unaltered
   with its URL, retrieval date and SHA-256 checksum in `sources/MANIFEST.csv`.
3. **Missing is not zero.** Outside a source's coverage the cell is missing.
   A zero means the source covers that country-year and records nothing.
4. **One code path for all years.** The same code builds 1950–2025. Edits
   after outcomes are visible are bug fixes only, each logged.
5. **Channels are the product.** No combined score (Q12).
6. **External validation is part of the build.** Penalties against Early &
   Preble (OFAC actions 2003–2018); financial channel against CNAS
   *Sanctions by the Numbers* (2017–2025); kinetic against UCDP and MID
   directly. Disagreements are reported, not tuned away.
7. **v1 against v2.** A logged script compares the two builds and refits the
   main model on both. Where v2 moves a result, it says why.
8. **Rebaseline `validate.R`.** Its 44 checks encode v1. They are replaced by
   a v2 baseline in one logged commit, never edited one by one to pass.

---

## 3. Source coverage, verified 2026-10-27

| Source | Version / coverage | Use and consequence |
|---|---|---|
| COW State System Membership | v2024, 1816–Dec 2024 | Country list (D1). 2025 carried forward from 2024 membership, documented |
| Global Sanctions Data Base (GSDB) | Release 5 (codebook 2026-09-01): case list 1,794 cases, 1949–2025; dyadic 170,563 sender–target–years, 1950–2025; plus Financial Sanctions (1,072 cases). By request; received 2026-10-27 | Sanctioned flag (D2); financial subtypes for the financial channel. Not redistributed |
| OFAC archive of SDN list changes | Text 1994–2023; PDF 2001–present | Financial channel (D3). 2024–2025 only as PDF. Pre-1994 needs the Federal Register |
| OFAC civil penalties and enforcement information | By-year pages 2003–2026. 2025: 14 actions, $265,746,819 | Penalties channel. Missing, not zero, before 2003. The 2025 figures are a hand-check |
| UCDP/PRIO Armed Conflict Dataset | v26.1, 1946–2025 | Kinetic channel (D5), the one source spanning 1950–2025 |
| UCDP GED | v26.1, 1989–2025 | Not used for the channel (begins 1989; would break the series) |
| COW Militarized Interstate Disputes | v5.0, 1816–2014 | Validation of the kinetic channel only (ends 2014; would break the series) |
| US troop deployments (`troopdata`: DMDC reports; Kane 1950–2003; Allen, Flynn & Martinez Machain 2022) | Location-year, 1950–2026 (2026 partial) | Posture channel. War-zone and classified deployments omitted in some years (to verify) |
| ATOP alliances | v5.1, 1815–2018 | Legitimate-sanctuary measure (Q6). 2019–2025 carried forward, with US alliance changes added by hand |
| UNGA ideal points (Bailey, Strezhnev & Voeten) | July 2025 release | Diplomatic alignment (Q6), as in v1 |

Not yet verified: UN Security Council and EU list histories with original
listing dates; dollar-integration measures (Q6); Early & Preble and CNAS
replication files; a source for attacks on the US after about 2020 (Q15).

---

## 4. The construct

**Enforcement intensity is the coercive resources the United States expends
against a target in a year, across financial and kinetic channels.**
(Sean, Q1. Corresponds to E in AC section 9.3, Uᴬ = R − max(0, V − τ) − E.)

Sean's account of the mechanism (Q1, 13:55): "Empire overextends, spends too
much, punches too hard, pays a steep price. The public suffers. The countries
impacted suffer, too, in many ways; life, financial, functional. The apex
targets resources and soft targets because the cost is perceived to be lower.
That could be retreat."

The dataset holds three linked blocks. Only the first is the index.

| Block | Content | Unit |
|---|---|---|
| Exertion (the index) | Financial, penalties, kinetic and posture channels, kept separate | Target country-year |
| US burden | Debt, net interest, deficit, outlays (repo `fiscal_indicators.csv`) | Year |
| Target burden | Cost of recovery and repair (sources to be chosen) | Country-year |

Outside blocks, never in the index: multilateral listings (D4); domestic
bank enforcement by FinCEN, the OCC, the Fed and DOJ (Q9).

---

## 5. Design answers

### Q1. What is measured — SETTLED
The sentence in section 4. Burdens on both sides are outcomes recorded in
their own blocks, not parts of the measure.

### Q2. Who enforces — SETTLED: the United States
Sean, 13:58: "I have the most data on the US, and it is the current
hegemon. In AC I suggest the same mechanism happens over time." Only US
actions enter the index; kinetic events only where the US is a party.
Scope condition: the panel tests the mechanism within one apex over time and
cannot test AC's claim that it recurs across apexes.

### Q3. Propositions the data must be able to prove wrong — SETTLED
Sean's periodization (14:08–14:24): 1945 consent-based order; 1971 end of
gold convertibility lowers the cost of expansion through money creation
(AC: "the foundational thermodynamic shift"); 1991 no peer rival, exertion
spreads; 2001–2003 Iraq and Afghanistan, "the final nail"; about 2016–2025
"the check comes due." Administrations defer the cost (Canon Part II, cost
asymmetry, LOCKED). Frame: world-systems (Wallerstein; Arrighi), neither
currently cited in AC for this argument.

1. **Expansion under slack.** With no peer rival, exertion rises and spreads
   to more targets, limited only by domestic burden.
2. **Escalation and volatility under accumulated burden.** As deferred cost
   accumulates, exertion becomes "more severe and volatile" (Sean, 14:20):
   its level and its dispersion rise with US burden.
3. **Extraction and the soft-target shift.** As burden and rival capacity
   rise, exertion concentrates on resource-rich and soft targets (AC Ch. 9,
   Path of Least Resistance). Sean: "That could be retreat."
4. **Kinetic sprint (AC).** Kinetic exertion is temporary and gives way to
   financial exertion; after 2001–2003, kinetic falls and financial takes
   over.

Measurement cautions recorded with them:
- "Financial stress" must name its measure. In `fiscal_indicators.csv`
  (% GDP), net interest fell from 3.16 (1991) to 1.34 (2003) while debt rose
  from 55 (2001) to 100 (2015); net interest rose from 1.49 (2021) to 3.15
  (2025). The measure chosen decides the sign.
- Any rise "in the information age" is tested with source coverage held
  fixed, because the OFAC archive begins in 1994 and the penalties record in
  2003.
- Proposition 4 is tested only on channels spanning 2003 on both sides
  (financial and kinetic), not on penalties.
- A 1971 break test needs pre-1994 financial history (Federal Register).
- The 2016–2025 phase spans administrations of both parties and rests on
  about ten years at the end of the series.
- Volatility (proposition 2) is tested by letting the dispersion parameter
  depend on burden (Claude's proposal; Sean agreed).

### Q4. Unit — SETTLED: target country-year

### Q5. Risk set — SETTLED: all states, 1950–2025
Sean, 14:29: "I want all since it's the population. The first iteration
selects only the in group and that is somewhat problematic." Start year 1950
for the proof of concept (Sean, 14:43), so every year has the same sanctions
source. Sean's severity ordering (1 = sanction, 2 = kinetic) is derived from
separate per-channel indicators, not stored as the measure, because channels
co-occur and the ratchet runs both ways.

### Q6. What a zero is — SETTLED
Three kinds: untouched, sanctuary, no source. No source is missing, never
zero; gaps only hand-coding could fill stay missing (Sean, 14:43).
Sean, 14:43: "Sanctuary is a function of diplomacy (legit or handshake)."
- Legitimate sanctuary: formal alliance (ATOP) or close alignment (UNGA).
- Handshake (AC): wired into the dollar core and left alone without a
  formal tie (Claude's proposed observable; Sean agreed). Measures to be
  chosen and logged before use.
Diplomacy is measured from sources independent of enforcement.

### Q7. Imposition and enforcement — SETTLED
Sean, 14:49: "Imposing ends when sanctuary is established or cost to
interdict exceeds extractive value" (AC 9.3: the Apex stops when E exceeds
R). An episode ends when exertion stops; legal termination is recorded
separately. Cost and extractive value are measured independently of the
ending (exertion; resource rents and dollar integration). Program creation
and actions under a program are separate event types within one episode,
and both count (Claude's default, accepted).

### Q8. One event per channel — SETTLED (Claude's defaults, accepted)
- **Financial:** one person or entity added to the SDN list, attributed to a
  country. 1994 onward for the proof of concept; pre-1994 missing until the
  Federal Register work.
- **Penalties:** one OFAC civil penalty or settlement, counted, not
  dollar-weighted (penalty money flows to the US). A penalty counts once for
  each country program it names; non-country programs (narcotics,
  terrorism) are not assigned.
- **Kinetic:** a country-year in which the US is a party to an armed
  conflict in UCDP/PRIO, with US troops deployed there as the weight.
- **Posture:** US troops at every location, 1950 on. Sean, 14:53: bases are
  coercion, "costs to prevent flares," borne by the US and the host. Never
  summed with the punitive channels: allies read high on posture and near
  zero on punitive, which is sanctuary in the Q6 sense. AC Ch. 4 lists
  "basing agreements" and "permanent forward-deployed presence" in the
  kinetic apparatus. Recorded tension: Canon Part II (LOCKED) predicts bases
  outlast need. Recorded limit: posture shows where the US spends, not at
  whom (Sean, 14:57: bases watch the adversary and keep the peace). Naming:
  AC already uses "dual mandate" for the Federal Reserve.

### Q9. Misreporting direction per source — SETTLED
- OFAC SDN: records the visible adjudication, nothing of what is tolerated
  (AC's 99/1); designations may cluster around political announcements.
- OFAC penalties: negotiated, discretionary, published only when settled.
  Understates enforcement against US banks, which runs mostly through
  BSA/AML law. On 2026-10-13 FinCEN ($1.2B, $750M credited for the OCC),
  the OCC ($750M) and OFAC ($11.7M) penalized Bank of America; about 1% was
  OFAC. This contradicts AC's claim that Bank of America received
  "substantially smaller penalties or no enforcement at all."
- UCDP: 25-battle-death threshold; misses low-intensity and covert US
  action.
- MID: includes threats and displays; ends 2014.
- Troop data: omits war-zone and classified deployments in some years.
- GSDB: researcher-coded from public sources; covert measures absent.

### Q10. Event timing — SETTLED (Claude's default, accepted)
An event's date is its public announcement (Federal Register or OFAC
release). Conflict data uses its own coded year. Coverage in section 3.

### Q11. One construct or several — SETTLED: several
Channels kept separate; multilateral listings and domestic bank enforcement
are outside blocks.

### Q12. Weights — SETTLED: no combined score

### Q13. What drives sanctuary versus intensity — SETTLED
Sean, 15:07: diplomacy drives both. No variable is yet justified as
entering only one part, so separating sanctuary from engaged-but-quiet
years rests partly on functional form. Primary model: zero-inflated (AC's
Handshake as a latent structural zero), with dollar integration entered in
the zero part only and that restriction argued in writing. Robustness: a
hurdle model (every zero a year without action). This hurdle is not the
two-stage OFAC-to-kinetic hurdle found dead on 2026-10-07.

### Q14. Theory variables and controls — SETTLED
Conflict in the target is measured from events the kinetic channel does not
count. Rival capacity (Sean, 15:07: China, BRICS and the EU, "both
increasing"): each bloc's share of world GDP, BRICS membership time-varying
by accession date. These series trend upward and are hard to separate from
time.

### Q15. What kills the theory — SETTLED
Sean, 15:07: "Someone attacks us. Sanctions us." Reading agreed: the theory
fails if US exertion is explained by the US being attacked or sanctioned (a
defensive response) rather than by accumulated burden and extractive value.
Data: GSDB (US as target); MID (US as target, to 2014); UCDP (US as a
party); the Global Terrorism Database (public release appears to end about
2020; low confidence). Attacks on the US after about 2020: no source yet.

---

## 6. Decisions before the first pull

| ID | Decision | Status |
|---|---|---|
| D1 | All states, target country-year, 1950–2025; COW v2024 list, 2025 carried forward | SETTLED |
| D2 | `under_sanctions` = a GSDB-R5 case naming the US as a sender in force against the state (targets and years from the dyadic file); COW codes; crosswalk logged | SETTLED (release 5 in use) |
| D3 | Financial channel = SDN additions per country, 1994–2025; pre-1994 missing | SETTLED for the proof of concept; built for 1995–2025 (1994 OPEN, change log 2026-10-27) |
| D4 | Multilateral block: UN Security Council and EU listings, outside the index, kept to test whether the US shifts enforcement onto others and toward cheaper instruments | SETTLED; listing-date recovery OPEN |
| D5 | Kinetic = US-party conflict in UCDP/PRIO v26.1, troop-weighted; MID for validation; GED not used | SETTLED |
| D6 | Program variables from GSDB's coded types and objectives, not hand-coded | SETTLED |

---

## 7. Build order

1. Commit this file (done 2026-10-27, commit `5d13375`) and push tag
   `v1-2026-10-17` on `686d009` (Sean).
2. Frame: country list and sanctioned flag (D1, D2).
3. Penalties, kinetic and posture channels: first pulls, manifest,
   checksums.
4. Financial channel 1994–2025 (text archive 1994–2023; PDF 2024–2025).
5. Multilateral block; pre-1994 financial history (Federal Register).
6. Burden blocks and covariates.
7. External validation (Rule 6), v1–v2 comparison (Rule 7), `validate.R`
   rebaseline (Rule 8).
8. Retest. Only then is v2 released.

A partial release is labelled partial and is not used for estimation. v2 is
released when every channel has a codebook entry (unit, coverage,
misreporting direction) and the build code that produced every cell is in
the repository.

---

## 8. Change log

- 2026-10-27: protocol committed (`5d13375`).
- 2026-10-27: corrected section 1 and section 7, step 1. The first commit
  said the v1 tag was pushed with it; the build session is not permitted to
  push tags, so Sean pushes it.
- 2026-10-27, first pulls (partial release). Changes found necessary once the
  sources were in hand, each applied to every year by the same code:
  - D2: GSDB release 5 is distributed only by request form and had not been
    received; the sanctioned flag uses GSDB v4 (the author's copy, file dated
    2024-06-13), which codes ongoing cases as ending in 2023. The flag is
    missing for 2024–2025 until release 5 replaces v4.
  - D5 and Q8: the kinetic weight is UCDP's intensity level, not troops.
    `troopdata` 1.1.0 has no missing values but records 0 or near-0 US troops
    where US forces were publicly reported (Syria 2022 and 2025, Iraq 2022 and
    2025): official reports omit war-zone deployments from about 2018 and the
    source fills them with 0. Posture is set missing in US-party conflict
    country-years from 2018.
  - Q8: the kinetic channel is two indicators, never summed: force against a
    state's government (`kin_vs_state`) and force spent inside a state
    alongside its government (`kin_in_state`).
  - GSDB label quirks mapped by case year: "South Vietnam" after 1975 is
    unified Vietnam; "Yemen, North" after 1990 is unified Yemen.
  - The penalties channel is deferred: OFAC's yearly enforcement tables carry
    no sanctions-program column, so country attribution needs each of 346
    linked documents (1,081 entries, 2003–2025; 23 entries have no document
    link).
- 2026-10-27, Q8 attribution (Sean, 15:53): financial and penalty events are
  attributed twice. `program_country` is the target of the sanctions program
  named (e.g., Iran for the Iranian Transactions and Sanctions Regulations)
  and feeds the index. `location_country` is where the listed or penalized
  party is located (e.g., a UAE company under the Iran program), kept as a
  second attribution to test the soft-target shift (Q3, proposition 3).
  Non-country programs (narcotics, terrorism, nonproliferation, cyber,
  human rights) have no program country; their location country is still
  recorded. GSDB release 5 requested by Sean the same day.
- 2026-10-27, penalties channel built (`v2/build/build_penalties.R`):
  - Unit as Q8: OFAC's own count per entry; a blank count is one action and a
    blank amount a finding of violation ($0), which reconciles the count to
    OFAC's year totals in all 23 years. In 2004 OFAC's listed amounts exceed
    its stated total by $55,000; recorded, not altered.
  - Program attribution from fixed tables (`ofac_program_map.csv`,
    `ofac_cfr_parts.csv`), not case-by-case judgment. Ukraine-/Russia-related
    programs, including Crimea, are attributed to Russia.
  - A second count excluding individuals (`pen_program_count_firms`) is added:
    59% of penalties are against individuals, mostly Cuba travel cases in
    2003–2005, which is enforcement against US travelers rather than exertion
    against a state.
  - Location attribution is found for 423 of 1,054 entries and is kept in the
    entry file only; it does not enter the panel until it is built to a
    standard where "not found" can be distinguished from zero.
- 2026-10-27, GSDB release 5 received (Sean, 16:29) and replaces v4 (D2). US-named
  cases from the case list; targets and years from the dyadic file (GSDB
  codebook 8.1); UN- or coalition-only rows excluded (Q2). The 2024–2025 flag is
  now observed, not missing. A second flag, `under_sanctions_us_single`, counts
  only single-target cases, separating sanctions aimed at a state from
  multi-country designation cases. The GSDB Financial Sanctions file (six
  financial subtypes per case, including exclusion from payment
  infrastructure) is received for the financial channel. Neither file is
  redistributed (GSDB terms of use).
- 2026-10-27, financial channel built (`v2/build/build_financial.R`; D3, Q8):
  - Source: OFAC's archive of changes to the SDN list, one file per year
    (text 1994–2023; three-column PDFs 2024–2025, converted in reading order
    by `sdn_pdf_to_text.R`). The converter was checked on 2023, for which
    OFAC publishes both: identical addition counts on every one of 223
    dates, and 5,613 of 5,616 entries identical after normalization.
  - An addition is an entry in a section OFAC heads as added or designated.
    Changes, removals and entries that become new only because an existing
    entry was changed ("resulting in the following new entries") are not
    additions.
  - OFAC prints each a.k.a. of many designees as its own entry (one 2017
    designee appears five times). Entries with the same name set and the
    same identifying details on the same date are counted once (26,110
    removed). An entry deleted and relisted on the same date is not a new
    designation (115 removed).
  - Program country from the entry's program tags (`ofac_sdn_tags.csv`), on
    the penalties channel's rules: Ukraine-related programs to Russia;
    Western Balkans, terrorism, narcotics, nonproliferation, cyber, Global
    Magnitsky and other non-country programs not assigned. Location country
    from the entry's address(es); vessels and aircraft have none.
  - 1994 is narrative, not itemized (e.g., "523 individual officers of the
    Haitian Armed Forces", listed only in a separate file not in the
    archive). The panel's financial columns start in 1995; 1994 is left
    missing pending Sean's decision between hand-coding the counts OFAC
    states in the text and leaving it missing.
  - Checked against CNAS "Sanctions by the Numbers" (16 years with a
    published CNAS total; `v2/output/financial_validation_cnas.csv`): within
    1% in 11 (2009–2011, 2013, 2018–2020, 2022–2025; exact in 2010, 2013,
    2020 and 2023). Below CNAS by 2–5% in 2014 and 2017 and by 18–37% in
    2012, 2015 and 2016. CNAS's 2009–2019 series also counts non-SDN lists
    (Sectoral Sanctions Identifications from 2014, Foreign Sanctions Evaders,
    Part 561), which may explain 2014–2017; 2012 is not explained. A crude
    independent count of 2012 entries under "added" headings (990) matches
    the parser's 997 before alias removal, so the gap is not a parsing loss.
    OPEN: reconcile 2012 against OFAC's 2012 recent-actions notices.
- 2026-10-27, v1 files removed from `main` (Sean, 18:04). Every v1 file
  (panel, code, results, figures, codebook and notes) was unchanged since
  commit `686d009` and remains there at tag `v1-2026-10-17`. References in
  this protocol to v1 files (`EII_Panel_Definitive.csv`,
  `fiscal_indicators.csv`, `validate.R`) mean those files at that tag.
- 2026-10-27, reproduction: rebuilt from an empty folder with every public
  source re-downloaded (including the 32 SDN change files) and checked against
  the manifests, and the GSDB release 5 files placed by hand, the eight output
  files (panel, penalties, financial, kinetic, crosswalk) matched commit
  `0535c90` byte for byte. Two consecutive runs of the financial build were
  also identical.
- 2026-10-27, estimation order (Sean, 18:43): covariates are built before
  any model is fit; section 7 stands (no estimation on the partial release).
  The financial program count is the primary outcome; penalties secondary;
  kinetic modelled separately. OPEN: whether the financial count is read as
  attention or as expenditure (Q1); the dollar-integration measure (Q6).
- 2026-10-27, Q1 amended (Sean, 19:18): "Trade coercion is central to the
  theory." A trade channel is added to the exertion index, kept separate like
  the others, and built before any model is fit. Reason: tariffs and trade
  threats are the main US instrument against allies, through which the
  Handshake's price is extracted (Sean, 19:16: allies "carrying water for the
  US ... a handshake but penance"). The test that separates penance from
  Lake's (2009) hierarchy-as-contract: payments to the US (arms purchases,
  Treasury holdings, concessions) rise with US pressure regardless of the
  ally's security needs. Sources, event unit and coverage are OPEN and are
  settled here before the first pull. Recorded at the same time, out of scope
  for v2: coercion by non-government US actors (markets, banks), Q2.
- 2026-10-27, trade channel (Sean, 19:22): antidumping and countervailing
  duties go in an outside block, not the index (petition-driven by US firms
  and decided quasi-judicially; Q2). Threats: Sean, 19:22: "really
  problematic, especially recently. But it is consistent with the [storm] I
  theorize." Rule for threats OPEN (proposal in the session: formal steps
  only, recorded separately from impositions).
