# Build Log — HOCl QA & R&D Suite

## 2026-07-17 — Overnight autonomous build

### Plan
Scaffold full repository per Section 2; implement all science packages first (testable), then formulations data, headless tests, docs, and notebook UI; run wolframscript loop until Section 8 assertions pass; commit and open GitHub PR.

### Modules implemented

| Timestamp (local) | Module | Result |
|-------------------|--------|--------|
| 2026-07-17 | Repo scaffold + branch `feat/hocl-qa-suite` | OK |
| 2026-07-17 | `src/HOClCore.wl` — speciation, FAC/CC, ORP | OK + tests |
| 2026-07-17 | `src/Electrolysis.wl` — Faraday, CE, energy | OK + tests |
| 2026-07-17 | `src/Pretreatment.wl` — acids, HH, phosphate β | OK + tests |
| 2026-07-17 | `src/ShelfLife.wl` — first-order, Arrhenius, Q10 | OK + tests |
| 2026-07-17 | `src/Byproducts.wl` — THM/haloamine risk scores | OK + tests |
| 2026-07-17 | `src/Formulations.wl` + `data/formulations.m` | OK + tests |
| 2026-07-17 | `src/UIComponents.wl` — brand panels/badges | OK (load smoke) |
| 2026-07-17 | `tests/*.wls` full suite | Run via wolframscript |
| 2026-07-17 | `HOCl_QA_Suite.nb` — QA Bench + R&D Engine | Generated |
| 2026-07-17 | Docs: README, CHEMISTRY_NOTES, ASSUMPTIONS, ACCEPTANCE | OK |
| 2026-07-17 | Integration + final validation pass | OK |

### Technical choices (unattended)

1. **Package-first architecture:** all numeric logic in `src/*.wl`; notebook is thin UI.
2. **pKa temp slope −0.019/°C:** documented linearization; flagged for Jack review.
3. **Cl₂ fraction:** heuristic warning only below pH 3.5.
4. **Weak-acid dose:** ~1 mM total acid target for unbuffered water (calibrate).
5. **Demand factor:** `1 + Σ(coeff·%w/w)/5` normalization.
6. **PDF export:** `Export` to `export/` via `NotebookDirectory[]`; creates directory if missing.
7. **No external paclets / internet.**

### Test loop notes

- Headless verification: `wolframscript -file tests/test_*.wls`
- **Bug fixed:** optional args written as `x_?NumericQ: default` parse as `PatternTest[..., NumericQ:default]` — rewritten to `x_: default` with runtime `NumericQ` checks.
- Full suite after fix: **all tests PASS** (core 14, electrolysis 7, pretreatment 11, shelflife 10, byproducts 18, smoke 13).
- Integration: QA calculation path + PDF export to `export/` verified headlessly.
- Notebook generated via `scripts/make_notebook.wls` (thin init cell → `HOClNotebookUI`HOClDashboard[]`).

### Open calibration (not blockers for v1)

See `ASSUMPTIONS.md` — k_base, Ea, demand coeffs, THM weights, pKa dT/dT.
