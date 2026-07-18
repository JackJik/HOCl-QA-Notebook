# TG Labs / 50MM — HOCl QA & R&D Suite

Portable **Mathematica** notebook for troubleshooting, QA, and shelf-life prediction of salt-brine electrolyzed HOCl (50–225 ppm FAC) and 50MM cosmetic hydrogels.

**Requirements:** Full Mathematica (current) on macOS Ventura+. No internet, no paclets, no external dependencies.

---

## Quick start (MacBook Pro)

1. Clone or copy this **entire repository** (folder `HOCl-QA-Notebook` must contain both `HOCl_QA_Suite.nb` and `src/`).
2. Open **`HOCl_QA_Suite.nb` from that folder** (double-click or Mathematica → File → Open).
3. Select the **blue code cell** (one short `Module`/`Get` line).
4. Press **Shift-Enter** (or Evaluation → Evaluate Initialization Cells).
5. Click **Enable Dynamics** if prompted.
6. The **dashboard appears as OUTPUT under the blue cell** (scroll down if needed).

The notebook only loads `src/LaunchHOCl.wl`. All chemistry/UI code lives in `src/*.wl` — if the blue cell looks like a huge broken block of text, you have an old copy; run `git pull` and reopen.

Packages load relative to the notebook directory. Missing `src/` shows a red error panel, not a blank page.

---

## Repository layout

```
HOCl-QA-Notebook/
├── HOCl_QA_Suite.nb      ← main deliverable
├── src/                  ← Wolfram Language packages (tested)
├── tests/                ← wolframscript unit tests
├── data/formulations.m   ← editable product specs
├── docs/                 ← this guide + chemistry notes
└── export/               ← PDF QA reports written at runtime
```

---

## QA Bench Mode (operators)

1. Select **product** from the dropdown (definitions in `data/formulations.m`).
2. Enter **batch/lot ID** and **date**.
3. Enter measured **pH**, **ORP (mV)**, **FAC (ppm)**, **Total Chlorine (ppm)**, **temperature (°C)**, and optional **conductivity (µS/cm)**.
4. Read instantly:
   - HOCl % / OCl⁻ % and **active HOCl (ppm)**  
   - **Combined chlorine** (TC − FAC) with red flag if over threshold  
   - **Spec PASS/FAIL** badges for pH, FAC, ORP  
   - **Shelf-life estimate** (days to product floor, default 50 ppm) and decay curve  
   - **Byproduct risk** Green / Yellow / Red + plain-language warning  
5. Click **Export QA Report → PDF**. File lands in `export/` with lot, timestamp, inputs, results, and signature block.

**Tips:** Leave blanks only where optional; invalid numbers show a friendly message. This tool does **not** authorize product release — confirm with validated lab methods.

---

## R&D Simulation Engine (chemists)

| Dashboard | What it does |
|-----------|----------------|
| **Speciation explorer** | HOCl/OCl⁻ vs pH (temp slider); pKa mark; 50–225 ppm band |
| **Electrolysis simulator** | Current, time, NaCl%, CE, volume → FAC, energy, CE troubleshooting |
| **Pretreatment titrator** | Acetic / vinegar / HCl-muriatic / citric; phosphate buffer designer for gels |
| **Shelf-life studio** | pH, temp, light, demand → decay, Arrhenius/Q10, accelerated→ambient |
| **Byproduct risk explorer** | Organic/N load, FAC, temp, time, TOC → risk score + warnings |

Sliders use non-continuous tracking where needed for smooth UI.

---

## Editing products & constants

- **Products / excipients:** edit `data/formulations.m` (or `Formulations\` defaults).  
- **Chemistry constants:** each `src/*.wl` file has a clearly commented **CALIBRATION BLOCK** at the top of the private section.  
- Estimates and calibration flags: `docs/ASSUMPTIONS.md`.  
- Science write-up: `docs/CHEMISTRY_NOTES.md`.

---

## Headless tests (optional)

With `wolframscript` on PATH:

```bash
cd HOCl-QA-Notebook
for t in tests/test_*.wls; do wolframscript -file "$t" || exit 1; done
```

All tests must print PASS and exit 0.

---

## Guardrails

- QA / decision-support only — **not a release authority**.  
- Speciation & Faraday math are exact given inputs.  
- Demand coefficients, decay rates, and THM scores are **estimates pending lab calibration**.  
- Never treat byproduct **scores** as measured THM concentrations.

---

## Support

Questions on chemistry defaults or recalibration: Jack / TG Labs process team.  
Build history: `docs/BUILD_LOG.md`. Acceptance: `docs/ACCEPTANCE.md`.
