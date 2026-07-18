# Chemistry Notes — HOCl QA & R&D Suite

Science implemented in the packages, with constants and sources.

## 1. Chlorine speciation

```
HOCl ⇌ OCl⁻ + H⁺      pKa = 7.54 at 25 °C
```

Fraction of free available chlorine (FAC) as HOCl:

```
fHOCl(pH, T) = 1 / (1 + 10^(pH − pKa(T)))
fOCl = 1 − fHOCl
Active HOCl (ppm) = FAC (ppm) × fHOCl
```

### Temperature correction for pKa

Default linearization around 7.54 @ 25 °C:

```
pKa(T) = 7.54 − 0.019 × (T − 25)
```

Coefficient `−0.019 °C⁻¹` is an approximate van’t Hoff / literature-order slope (pKa of HOCl decreases with temperature). **Calibrate / confirm against preferred reference (e.g. Morris 1966 and later reviews).** Flagged in ASSUMPTIONS.md.

### Low pH / Cl₂(aq)

Below ~pH 3.5, molecular chlorine Cl₂(aq) becomes significant and **off-gassing risk** is flagged. The `fCl2` helper is a **heuristic warning fraction**, not a full three-species equilibrium.

### Reference table (operator sanity check @ ~25 °C)

| pH   | HOCl % | OCl⁻ % | Note                    |
|------|--------|--------|-------------------------|
| 3.0  | 97     | 0      | Cl₂ off-gassing risk    |
| 4.0  | 99.7   | 0.3    | Optimal stability       |
| 5.0  | 99.7   | 0.3    | Optimal production      |
| 6.0  | 97     | 3      | Acceptable              |
| 7.0  | 78     | 22     | Efficacy declining      |
| 7.54 | 50     | 50     | pKa crossover           |
| 8.0  | 22     | 78     | Hypochlorite dominant   |
| 9.0  | 3      | 97     | Essentially bleach      |

(Percentages in the table are the classic operator reference; the continuous `fHOCl` function is used for computation.)

## 2. FAC / Total Chlorine / Combined Chlorine

```
TC = FAC + CC
CC = TC − FAC
```

Combined chlorine indicates chloramines / organic-N chlorine. Default warning when **CC > 0.2 ppm** (editable) or CC/TC exceeds a fraction threshold (default 0.15).

## 3. Electrolysis (Faraday)

```
Mass (g) = (I × t × M) / (n × F)
F = 96485 C/mol, n = 2, M(HOCl) = 52.46 g/mol
```

Practical constant used in code:

```
HOCl production ≈ 16.3 mg per amp-minute at 100% current efficiency (CE)
Typical CE 70–85% → ~11–14 mg HOCl per amp-minute
```

FAC (ppm) ≈ mg HOCl produced / volume (L) for dilute aqueous solutions.

### Reactor guidance (UI troubleshooting)

- Current density: 50–200 mA/cm²  
- NaCl: 0.5–3.0% w/v  
- Temperature: 15–30 °C  
- pH target: 4.0–6.0  

Low NaCl → O₂ evolution; high temp → side reactions; fouling → resistance; high pH → OCl⁻ back-reaction.

## 4. ORP

Trend bands (not absolute FAC):

| ORP (mV) | Interpretation              |
|----------|-----------------------------|
| <400     | no disinfection             |
| 400–600  | marginal                    |
| 650–750  | good (chloramine range)     |
| 750–900  | excellent (HOCl range)      |
| >900     | possible electrode fault    |

ORP depends on pH, temperature, and species. Use for **trending and cross-checks**, not as a direct FAC measurement. `ORPTrendModel` is a qualitative Nernstian-style indicator for R&D only.

## 5. Shelf-life / decay

First-order FAC loss:

```
FAC(t) = FAC0 × Exp[−k_eff × t]
k_eff = k_base × f_pH × f_temp × f_light × f_demand
```

- **Arrhenius:** `k(T) = A × Exp[−Ea/(R T)]`, R = 8.314 J/mol·K  
- **Q10 shortcut:** rate multiplies by Q10 (default ~2) per +10 °C  

Defaults for `k_base`, `Ea`, light factors, and demand multipliers are **estimates pending TG Labs stability calibration**.

## 6. Pretreatment / buffers

### Strong acid (HCl / muriatic)

Stoichiometric H⁺ for poorly buffered distilled water:

```
moles H⁺ ≈ V × (10^(−pH_target) − 10^(−pH_start))
```

### Weak acids (acetic / vinegar / citric slot)

Henderson–Hasselbalch:

```
pH = pKa + Log10[base/acid]
```

Acetic pKa ≈ 4.76. Vinegar ≈ 5% acetic acid (editable %).

### Phosphate buffer (hydrogels)

pKa2 ≈ 7.2 (H₂PO₄⁻ ⇌ HPO₄²⁻):

```
β ≈ 2.303 × C × α(1−α)
α = 10^(pH−pKa) / (1 + 10^(pH−pKa))
```

**Caution:** distilled water is poorly buffered — dose slowly and re-measure.

## 7. THM / haloamine warnings

Risk scoring only — **never reports a THM concentration as fact**. Drivers:

- Organic precursor load (HA, glycerin, glycols, …)  
- Nitrogen sources → haloamine / chloramine (ties to combined chlorine)  
- High FAC + long contact + higher temp + higher pH  
- Feedwater TOC (prefer distilled/RO, TOC ≲ 1 ppm)  

Mandatory UI disclaimer: confirm by lab THM/haloamine assay before release.

## Guardrail

This suite is a **QA / decision-support tool**, not a release authority. Speciation and Faraday math are exact given inputs; demand coefficients, decay rates, and THM scores are estimates.
