# HOCl QA & R&D Suite — v1 working build

**Repo:** https://github.com/JackJik/HOCl-QA-Notebook  
**Branch:** `feat/hocl-qa-suite` (merged equivalent on `main`)  
**Date:** 2026-07-17

## Modules

| Package | Role |
|---------|------|
| `HOClCore.wl` | Speciation, FAC/CC, ORP, pKa(T) |
| `Electrolysis.wl` | Faraday production, CE, energy, troubleshoot |
| `Pretreatment.wl` | Acetic/vinegar/HCl/citric dosing; phosphate buffer β |
| `ShelfLife.wl` | First-order decay, Arrhenius, Q10, accelerated projection |
| `Byproducts.wl` | THM/haloamine risk scores (indicative only) |
| `Formulations.wl` | 50MM products + excipient demand |
| `UIComponents.wl` | Brand chrome, badges, gauges |
| `HOClNotebookUI.wl` | QA Bench + R&D Engine dashboard |

## Test status

All `tests/*.wls` PASS under `wolframscript`. Integration PDF export verified.

## Calibration backlog

All items in `ASSUMPTIONS.md` marked “calibrate against TG Labs lab data” or “needs Jack’s review.”
