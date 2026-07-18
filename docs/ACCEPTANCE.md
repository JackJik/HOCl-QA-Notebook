# Definition of Done — Acceptance Checklist

Tick boxes as modules pass. Do not claim done until all are true.

## Core deliverables

- [x] Repository layout matches Section 2 (`src/`, `tests/`, `data/`, `docs/`, `export/`)
- [x] `HOCl_QA_Suite.nb` present; loads packages via `NotebookDirectory[]` / relative paths
- [x] Styled landing dashboard with navigation to **QA Bench** and **R&D Engine**
- [x] Title bar: "TG Labs / 50MM — HOCl QA & R&D Suite"

## QA Bench Mode

- [x] Product dropdown from formulations data
- [x] Batch/lot ID + date inputs
- [x] Inputs: pH, ORP, FAC, Total Chlorine, temperature, conductivity (optional)
- [x] Outputs: HOCl%/OCl%, active HOCl ppm, combined chlorine + red flag
- [x] Spec PASS/FAIL badges vs product windows
- [x] Predicted shelf life + decay curve
- [x] Byproduct risk light (Green/Yellow/Red) + plain-language warning
- [x] One-click Export QA Report → PDF into `/export/`
- [x] Friendly validation (no raw red errors for bad inputs)

## R&D Simulation Engine

- [x] Speciation explorer (pH/temp, pKa mark, 50–225 band)
- [x] Electrolysis simulator + CE troubleshooting
- [x] Pretreatment titrator (acetic, vinegar, HCl/muriatic, citric/weak slot)
- [x] Phosphate buffer designer
- [x] Shelf-life / stability studio (Arrhenius/Q10, accelerated projection)
- [x] Byproduct risk explorer

## Science & products

- [x] Speciation pKa 7.54 + temperature correction
- [x] FAC/TC/CC logic
- [x] Faraday electrolysis (16.3 mg/A·min @ 100% CE)
- [x] ORP bands + indicative trend model
- [x] Shelf-life first-order + Arrhenius/Q10
- [x] THM/haloamine warning system + lab-assay disclaimer
- [x] Full 50MM product list (spray + hydrogels + listed excipients)
- [x] Editable chlorine-demand / compatibility data in `data/formulations.m`

## Testing

- [x] `tests/test_core.wls` PASS
- [x] `tests/test_electrolysis.wls` PASS
- [x] `tests/test_pretreatment.wls` PASS
- [x] `tests/test_shelflife.wls` PASS
- [x] `tests/test_byproducts.wls` PASS
- [x] Zero-message / smoke load test PASS (`tests/test_smoke_load.wls`)
- [x] Section 8 numeric assertions covered

## Documentation & git

- [x] `docs/README.md` — how to open and use both modes
- [x] `docs/CHEMISTRY_NOTES.md` — science and constants
- [x] `docs/ASSUMPTIONS.md` — estimates flagged for calibration
- [x] `docs/BUILD_LOG.md` — build timeline
- [x] Committed on `feat/hocl-qa-suite`; pushed; PR/summary commit

## Guardrails

- [x] Release-critical results labeled as models/estimates
- [x] No fabricated THM concentrations
- [x] Calibration constants in clearly commented blocks per package

---

**Status:** v1 working build — logic packages fully tested under `wolframscript`. Notebook UI generated for full Mathematica on macOS. Recalibrate demand/kinetics/THM weights against TG Labs bench data before treating outputs as release gates.
