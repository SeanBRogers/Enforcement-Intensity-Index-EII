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
| D3 | Financial channel = SDN additions per country, 1994–2025; pre-1994 missing | SETTLED; built for 1995–2025, 1994 estimated (change log 2026-10-29) |
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
- 2026-10-27, covariates built (`v2/build/build_covariates.R`; Sean, 20:15:
  threats paused, back to covariates). US burden from OMB Historical Tables
  (FY2027 Budget) 1950–2025: gross debt, debt held by the public (with and
  without the Fed), net interest, surplus, outlays and defense, all % of GDP.
  Rival capacity from WDI at market exchange rates, 1960–2025 (1950–1959
  missing); BRICS and EU membership time-varying by accession, plus a fixed
  BRICS-5 series. Sanctuary: ATOP v5.1 defense obligations (not `atopally`,
  which includes non-aggression and consultation pacts with Russia and
  China), 2019–2025 carried forward with logged NATO accessions; UNGA ideal
  points from the 1946–2025 file (supersedes the July 2025 release named in
  section 3). Extractive value: WDI natural resource rents, 1970–2021. WDI
  API responses are committed as snapshots (CC BY 4.0). Year-level covariates
  are identified from year-to-year variation only. Still to build: dollar
  integration (measure to choose), the US as a target (Q15), trade channel.
- 2026-10-27, kinetic channel gaps found (Sean, 20:37: "Are we sure conflicts
  aren't part of US pressures?"). UCDP/PRIO v26.1 does not code the US as a
  warring party in three kinds of US force, so the channel reads 0 there:
  (1) air campaigns: Libya 2011 lists no US or NATO secondary party;
  (2) force inside a state without its government: US operations against IS
  in Syria 2014–2024 are not assigned to Syria (2025, after the change of
  government, is); (3) arming one side: Ukraine against Russia from 2022.
  The channel understates US kinetic exertion in these cases. Consequence for
  Q14: "conflict in the target" cannot be used as a control where the
  conflict is itself US pressure (a post-treatment control). Candidate
  sources for the missing forms (OPEN): UCDP External Support Dataset
  (1975–2017), SIPRI arms transfers (US to each recipient, 1950–), USAID
  Greenbook military assistance by country.
- 2026-10-27, Q2 and D4 amended (Sean, 20:55: "I like it"; 20:46: "Do we think
  UN or NATO pressure isn't the US? ... who is the gun? ... It's not always us
  v the world, it's UN/coalition with US might"). The enforcer is the US,
  acting in its own name (tier 1) or through UN, NATO and coalition action it
  drafted, sponsored or mainly armed (tier 2). Tier 3 (multilateral action
  without US lead) stays an outside block. Tiers are recorded separately and
  never summed. Tier 2 requires case evidence (drafter or sponsor of the
  resolution; US share of strikes, sorties or troops); the US's structural
  weight (UN budget share, NATO spending share) is the same in every case and
  does not by itself make a case tier 2. The 450 GSDB country-years excluded
  as UN- or coalition-only under the original Q2 are reclassified to tier 2 or
  3 as evidence allows. AC already treats multilateral institutions as
  "formally multilateral but institutionally captured by apex influence" and
  as "the architecture's optical mask" (IMF, World Bank); AC does not discuss
  the Security Council or vetoes. Sean, 20:55: "the Noblest of Shrouds:
  international cover. Also, China and Russia block all kinds of [things] in
  brinkmanship." Security Council vetoes are a candidate measure of denied
  cover (OPEN; source to verify).
- 2026-10-27, proposition 4 given a mechanism and the burden measure named
  (Sean, 21:06–21:07). Sean: "Cheaper instruments is important because fiscal
  stress requires it and bullets are expensive. Not always the case but
  non-kinetic exists for that reason." Logged as the testable form: fiscal
  stress raises the share of exertion carried by non-kinetic instruments
  (financial, and tier-2 multilateral) relative to kinetic ones. The cost
  mechanism fails if the shift follows the calendar but not burden, even if
  the Kinetic Sprint pattern holds. The stronger claim that cost is why the
  instruments exist is not tested (sanctions predate fiscal stress; IEEPA
  1977 and post-2001 Treasury capacity are rival causes). Burden measure,
  fixed before any substitution analysis: primary `us_debt_public_gdp`
  (accumulated deferred cost, "the check comes due"); reported alternative
  `us_net_interest_gdp` (the cost paid each year). Both are reported
  whichever way they come out. No substitution analysis had been run when
  this was logged. Note: the original mycology framing was removed from AC
  for parsimony; the slime-mold analogy stands.
- 2026-10-29, financial channel 1994 estimated (Sean, 10:03: "I think
  estimate since that's the whole thing ... tag it ... give a CI and move
  on"). `estimate_sdn_1994.R`: program counts for 1994 from the counts OFAC
  states in the narrative file, with the one unstated count (residents named
  under the 21 June 1994 order) taken from the itemized October 1994 deletion
  lists. Total 1,047 (bounds 980–1,069; Haiti 1,011, 944–1,033). The bounds
  are alternative readings of the source, not a statistical interval.
  Flagged in the panel (`fin_estimated`, `fin_program_count_low`/`_high`);
  the type split and location stay missing for 1994. Results are reported
  with and without the 1994 rows. A 1995 value was not used as a prior:
  1994 is dominated by the Haiti program, which ended in October 1994.
- 2026-10-29, covert and proxy channel moved into v2.0 (Sean, 11:05:
  "Absolutely ... Visibility is at the heart of EII, not recorded doesn't
  mean non-existent"). Reason: the kinetic channel sees only overt,
  UCDP-coded war; Cold War coercion was largely covert and post-1991 coercion
  largely overt, so without this channel the expansion after 1991
  (proposition 1) is confounded with coercion becoming visible. Sources
  (OPEN, to verify before the first pull): O'Rourke, Covert Regime Change
  (2018), US regime-change attempts 1947–1989; UCDP External Support Dataset
  (1975–2017), US support to warring parties; SIPRI arms transfers. Coverage
  breaks (1989, 2017) are flagged, never filled with zero. AC check: the AC
  versions in Drive (May 2026 Google Doc; August 2026 .docx) do not discuss
  the Eisenhower Doctrine, filibustering or the Contras; AC's Cold War
  material is §8.3–8.4 (Truman Doctrine, Leffler 1992, Westad 2005) and the
  post-Vietnam turn to "proxy mechanisms". Proposition 5 (the Handshake
  priced in the current node's goods; test: relief after payment) is OPEN.
- 2026-10-29, Q8 amended (Sean, 11:14: "I agree emphatically"). Additions
  under non-country programs only (39% of SDN additions; 19% are narcotics)
  are counted where the designee is located, in their own column
  (`fin_thematic_location_count`), alongside the program-country count. The
  original rule left the drug war invisible: 4,599 narcotics additions, 2,058
  of them located in Colombia and 1,278 in Mexico, counted toward no country.
  The same change is due for penalties once location attribution there is
  built (currently 423 of 1,054 entries). Sean's notes, same exchange, not yet
  design: the Monroe Doctrine and Roosevelt Corollary as hemispheric
  extraction (AC's August draft treats the Monroe Doctrine as British-enforced
  free-riding, not extraction); the fall in Colombia's narcotics designations
  after 2010 is not necessarily the Shroud (rival readings: partnership under
  Plan Colombia, fragmentation of the cartels, designations moving to
  Mexico).
- 2026-10-29, item 2 decisions (Sean, 11:32):
  - Extractive value (proposition 3): physical endowment (production or
    holdings of oil, gas and key minerals, from a window before the outcome
    it explains), not yearly rents, which sanctions, war and price policy
    push down. Sean: "It can be priced by markets too if need be": a
    market-priced version is the stated alternative. Weighting resources by
    era using the US's own declared needs (stockpile lists, critical-minerals
    lists, Strategic Petroleum Reserve) is proposed, OPEN.
  - Proposition 5 (the Handshake priced in the current node's goods), in
    Sean's form: "there is no relief, you've joined a gang and accepted mafia
    protection. Hotel California." Aligned states that make what the current
    node runs on pay continuing tribute (arms purchases, investment in the
    US, Treasury holdings, pledges) for protection; unaligned ones are
    contained. Falsifiable form (Claude, in session): exit is punished. The
    proposition fails if an ally that stops paying or realigns faces no rise
    in US exertion. Candidate cases: France leaving NATO's integrated command
    (1966), New Zealand's nuclear ban and ANZUS (1985), the Philippine base
    closures (1991), Turkey's S-400 purchase and the CAATSA sanctions (2020).
    Wording of the test OPEN pending Sean.
  - Dollar integration (Q6, zero part): dollar peg, from the
    Ilzetzki-Reinhart-Rogoff anchor-currency classification (1946-2016 on
    the authors' site; extension to 2025 to verify). A check measure is
    OPEN.
  - Candidate propositions, not yet design: (a) 1970-71 as the assembly of
    the 99/1 architecture: the Bank Secrecy Act (26 October 1970) builds the
    apparatus that makes dollar flows legible, the Comprehensive Drug Abuse
    Prevention and Control Act (27 October 1970) completes the drug
    prohibition, the gold window closes (15 August 1971), while the
    Eurodollar and offshore zone grows outside US reach; (b) dollars held
    abroad, including in informal and illicit economies, finance the US
    through seigniorage (Federal Reserve estimates put about 60% of $100
    notes abroad). Note, not a proposition (Sean: "critical and important"
    but risks reading as conspiratorial): intelligence-community payments
    to warlords and local power holders (mujahideen 1980s, Afghanistan 2001,
    Iraq's Awakening 2007-08, the Contras), to be hand-coded only with an
    evidence grade (official record, investigation, credible reporting) and
    reported by grade.

- 2026-10-29, item 2 built (Sean, 11:37: "spin up the data and get it all
  added to the panel with codebook entries"). Choices made in the build,
  each open to Sean's review:
  - Covert and proxy channel, part 1: `build_proxy.R`, UCDP ESD 18.1
    (1975–2017), US government support short of US troops, split into
    support against a state's government (`proxy_vs_state`: 64 state-years,
    15 states) and support to it (`proxy_for_state`: 481, 53 states), with
    alleged support kept apart. O'Rourke's 1947–1989 regime-change data is
    not publicly downloadable (book appendix or author needed); SIPRI arms
    transfers not yet pulled. Both OPEN.
  - Dollar peg: the IRR anchor is a reference currency that floating
    currencies also have, so `usd_peg` = dollar anchor and coarse regime 1–2.
    IRR's site now posts monthly files to 2025 (beta, October 2026) beside
    the stable 1946–2019 release; the beta is used and checked against the
    stable release (99.6% agreement). Annual value = modal month. Before 1973
    the peg mostly records Bretton Woods. Check measure still OPEN.
  - Endowment: highest annual oil plus gas production in 1985–1994 (peak,
    not mean, so the sanctioned or war years in the window do not lower it),
    territory as of 1995, from OWID/Energy Institute. Coal is kept as a
    yearly series only. Yearly production is written to a local, uncommitted
    file: the Energy Institute requires permission for extensive
    reproduction (EIA's public-domain series were checked as a substitute
    and rejected: pre-2000 coverage is patchy and its petroleum energy
    series is zero-filled for the USSR and others). Production misses reserves not yet developed in the
    window (Sudan, Guyana). Minerals, the market-priced version and era
    weighting remain OPEN.
  - Production capability (Sean: "production capability!!"):
    economic complexity, Atlas SITC 1962–2024 (`eci_sitc`, standardized
    within year).
  - Build hygiene: the text-processing scripts now require a UTF-8 locale
    and set one where available; outputs are unchanged by this.
  - Sean's note, same message, not yet design: the protection racket
    extends to leaders, who are "on the outs when they deviate" (Iran's
    revolution cited); a leader-level reading of proposition 5's "exit is punished".
- 2026-10-29, decisions (Sean, 13:28–13:30):
  - Proposition 5 test agreed: exit is punished. Leaders are in scope, in
    Sean's words: "if you won't play ball, we'll ensure your successor
    does." Implication to test: a leader who deviates faces a higher hazard
    of US-backed removal, and the successor realigns (UNGA distance falls,
    US exertion against the state falls). It fails if deviating leaders face
    no higher hazard, or if installed successors do not realign.
  - Dollar-integration check measure: dollar share of public external debt
    (World Bank IDS, DT.CUR.USDL.ZS, 1970–2024, low- and middle-income
    reporters only), added as `usd_debt_share`. It correlates weakly with
    `usd_peg` (0.11–0.38 by decade): the two measure different things (the
    regime versus the currency of liabilities) and are reported side by side.
  - Minerals (Claude's reading of "critical", to confirm): the endowment
    uses the US critical-minerals list.
  - O'Rourke's data ends in 1989 (Sean: "insufficient BUT it opens a great
    opportunity to fill the gap"): extending US covert regime-change coding
    past 1989 is a candidate contribution, not yet design. Caution: records
    of covert action surface with a declassification lag, so coverage falls
    toward the present; this produces a spurious decline unless coverage is
    modelled or graded.
- 2026-10-29, Bretton Woods and the dollar peg (Sean, 13:36: "3, yes"):
  1971–73 is treated as a break and tested directly (candidate proposition
  (a)), not dropped and not absorbed into a post-1973 interaction. Sean's
  standing rule restated, same message: missing, blocked or incomplete data
  can be estimated, with the estimate flagged (Rule 3 still applies: never
  filled with zero).
  - Minerals source (Claude, to confirm): BGS World Mineral Statistics
    (production by country, 1970–2024, nil distinguished from not
    available), mapped to the USGS 2025 critical-minerals list (60
    minerals, Federal Register 7 November 2025). BGS terms allow
    non-commercial academic use; giving the tables to third parties needs
    permission, so only derived indices are published and the yearly tables
    stay local, as with energy.
- 2026-10-29, covert and proxy channel, part 2 (Sean supplied the book,
  13:48): US regime change attempts 1947–1989 from O'Rourke, *Covert Regime
  Change* (2018), Tables 1.1 and 5.1–5.3, hand-entered with their table of
  origin (`v2/build/orourke_cases.csv`): 64 covert attempts (25 achieved),
  2 aborted plans, 6 overt operations; six `rc_*` columns, blank from 1990.
  The case list is in the book; O'Rourke's online appendixes hold the
  primary-source citations, not needed for the coding. Post-1989 extension
  remains the open opportunity (see the entry above on the declassification
  lag).
- 2026-10-29, critical-minerals endowment built (Sean, 13:29: "critical";
  13:36: find a source now). BGS World Mineral Statistics, 31 mine-production
  series covering 52 of the 60 minerals on the USGS 2025 list. Index: highest
  share of world production in 1985–1994 per series, summed
  (`crit_min_share_sum`), and the number of series with a share of 5% or
  more (`crit_min_major_n`); territory as of 1995, as for oil and gas. Equal
  weight per mineral; market pricing and era weighting remain OPEN. A state in
  no BGS producer table scores 0, since BGS lists producers (an
  understatement for unrecorded artisanal output); a listed producer without
  figures is left out of the sum, not zeroed.
- 2026-10-29, Sean (16:38): (1) financial before 1994, "Both, data type
  permitting. The world changes so our data and method change"; (2) trade
  channel unpaused; (3) "There is no attack on the US, EXCEPT cyber ... and
  that's squishy." Claude disagreed on (3) in session: attacks on US forces
  and citizens abroad (Pueblo 1968, Beirut 1983, Stark 1987, Pan Am 103,
  the 1998 embassy bombings, Cole 2000, 9/11, Al Asad 2020, Tower 22 2024)
  are what Q15's "someone attacks us" has to test against. Built:
  - Financial case series 1950–2025 from GSDB-FS (`fin_gsdb_*`), calibrated
    against SDN additions over 1995–2025 before any use for 1950–1993: it
    nests SDN activity (94.9% of SDN state-years have a case) but measures a
    regime in force, not intensity (16.9% of case-years have SDN additions;
    state-year rank correlation 0.33). Used as an extensive-margin series;
    no designation counts are imputed from it. A method change across the
    1994 seam is bridged by the overlap years, never assumed away.
  - Multilateral block (D4) from GSDB-R5: UN, EU and other-organization
    cases (`multilateral_country_year.csv`). Tier coding of UN cases,
    listing-date recovery and vetoes remain OPEN.
  - Kill test (Q15), part 1: MID 5.0 opponents of the US (1950–2014) and
    GSDB senders of sanctions on the US. Part 2 OPEN: terrorism against US
    targets (GTD, by request, Sean), state cyber operations (CFR tracker),
    state attacks on US forces after 2014 (hand-coded with sources).
  - Q14 control: UCDP conflicts without the US, with the US-backed share
    flagged (38% of conflict-years in 1975–2017 have US support to a side
    in ESD, so they cannot serve as controls).
- 2026-10-29, trade channel measure PROPOSED (Claude, for Sean's approval
  before any pull; Sean, 16:38: "Unpause"). Tier 1, US tariff coercion
  against a named state; anti-dumping and countervailing duties stay outside
  the index (2026-10-27); threats (statements, posts) excluded.
  - Events: (a) Section 301 investigation opened against the state (a formal
    Federal Register action, the stage before retaliation); (b) Section 301
    retaliation imposed (tariffs or suspended preferences); (c) Section 232
    measures that name the state (a country-specific rate, quota or the loss
    of an exemption: Turkey's doubled steel tariff, 2018); (d) emergency
    (IEEPA) tariffs that name the state (Canada, Mexico and China, 2025;
    Brazil and India, 2025); for the 2025 country-rate tariffs, only rates
    above the general baseline count.
  - Sources: CRS R46604 (2020), Table A-2 (all 130 Section 301 cases,
    1975–2020) and Table A-1 (outcomes 1995–2020); the Federal Register for
    outcomes before 1995 and for cases from 2021; presidential proclamations
    (232) and executive orders (IEEPA).
  - Cases against the European Communities or EU count for each member in
    that year, flagged, as GSDB does for EU sanctions.
  - Coverage 1975–2025 (Section 301 begins with the Trade Act of 1974);
    blank before 1975.
  - For Sean: whether investigations count as events or only retaliation;
    whether EU cases go to members or stay EU-level.
