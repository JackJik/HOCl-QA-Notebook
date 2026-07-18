# Assumptions & Calibration Items

Items marked **calibrate against TG Labs lab data** or **needs Jack's review** must not be treated as release-authoritative.

## Chemistry constants (exact / textbook unless noted)

| Item | Value | Status |
|------|-------|--------|
| HOCl pKa @ 25 °C | 7.54 | Standard (Morris-type literature) |
| pKa temperature coefficient | −0.019 / °C | **Estimate — needs Jack's review** |
| Faraday constant F | 96485 C/mol | Exact (conventional) |
| n (electrons) | 2 | Standard for Cl⁻→HOCl path used here |
| M(HOCl) | 52.46 g/mol | Formula weight |
| mg HOCl per A·min @ 100% CE | 16.3 | Spec / Faraday-derived practical constant |
| Acetic pKa | 4.76 | Standard |
| Phosphate pKa2 | 7.2 | Standard (ionic-strength dependent in reality) |
| R (gas constant) | 8.314 J/mol·K | Exact |

## Estimates — calibrate against TG Labs lab data

### Chlorine-demand coefficients (mg FAC-scale per % w/w — order-of-magnitude)

| Excipient | Default DemandCoeff | Notes |
|-----------|---------------------|-------|
| Hyaluronic acid | 2.5 | Organic; oxidation / chain-scission risk |
| Ectoin | 0.1 | Low demand |
| Silica | 0.05 | Largely inert |
| Laponite | 0.4 | Surface adsorption |
| R 5500 synthetic clay | 0.4 | Surface adsorption |
| Glycerin | 0.3 | Mild demand |
| Butylene glycol | 0.25 | Mild demand |
| KH₂PO₄ / Na₂HPO₄ | 0.0 | Buffering, not demand |
| NaCl | 0.0 | Electrolyte |

Composite demand factor scaling (`1 + Σ(coeff·%)/5`) is an **arbitrary normalization** — calibrate to measured FAC loss on real gels.

### Shelf-life kinetics

| Parameter | Default | Status |
|-----------|---------|--------|
| k_base | 0.002 day⁻¹ | **Calibrate to real stability data** |
| Ea | 50 kJ/mol | **Order-of-magnitude — calibrate** |
| Q10 | 2 | Editable rule-of-thumb |
| f_pH shape | rises toward high pH / OCl⁻ | Functional form estimate |
| Light factors (dark/ambient/strong) | 1.0 / 1.5 / 3.0 | **Estimate** |

### THM / haloamine risk model

Weights in `Byproducts.wl` (`wOrganic`, `wFAC`, `wTime`, `wTemp`, `wPH`, `wTOC`, `wNitrogen`, `wCC`) and Green/Yellow/Red cutoffs (30 / 60) are **indicative scoring only**. Never interpret scores as THM ppm.

### Cl₂(aq) fraction at low pH

`fCl2` is a **heuristic** for UI warning, not a full Cl₂–HOCl–OCl⁻ equilibrium. **Needs Jack's review** if quantitative low-pH work is required.

### Strong-acid dose in distilled water

Uses ideal [H⁺] = 10^(−pH). Real distilled/CO₂-equilibrated water has carbonate buffering and will **not** match exactly — always dose slowly and re-measure.

### Weak-acid dose

Default ~1 mM total weak-acid target is an **order-of-magnitude** titration aid. **Calibrate against lab titration curves.**

### ORP trend model

`ORPTrendModel` is qualitative / Nernstian-style for R&D exploration. **Not** a substitute for measured ORP or FAC.

### Combined chlorine thresholds

Default absolute trip 0.2 ppm and fraction trip 0.15 are **editable operational defaults** — set to TG Labs SOP.

### Vinegar / muriatic concentration

Defaults 5% acetic and 31% HCl — **operator must enter actual lot concentrations**.

### Product list

Spray + standard hydrogel + HA-forward hydrogel. Additional SKUs: edit `data/formulations.m`.

---

**Release guardrail:** Spec pass/fail, shelf life, and byproduct lights are **models/estimates to be confirmed by validated lab methods** (DPD/amperometric FAC, lab THM assay, real stability studies). This tool is not a release authority.
