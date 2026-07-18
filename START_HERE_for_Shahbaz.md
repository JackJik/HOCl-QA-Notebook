# HOCl QA & R&D Suite — instructions for Shahbaz

**From:** TG Labs / Jack  
**Tool:** Mathematica notebook for HOCl bulk + 50MM hydrogel QA and R&D  
**Version:** v1 working build (portable, offline)

---

## What you need

| Requirement | Notes |
|-------------|--------|
| **Mac** | macOS Ventura or newer recommended |
| **Full Mathematica** | Not just Wolfram Player — full desktop Mathematica |
| **This whole folder** | Do **not** open only the `.nb` file by itself |

No internet, no license paclets, no install beyond Mathematica.

---

## Install / open (5 minutes)

1. Unzip the package if you received a zip. You should have a folder named something like:
   ```
   HOCl-QA-Notebook/
   ```
2. Put that folder anywhere convenient (Desktop, Documents, Dropbox — all fine).
3. Open the folder and confirm you see **both**:
   - `HOCl_QA_Suite.nb`
   - `src/` (folder with many `.wl` files)
4. Double-click **`HOCl_QA_Suite.nb`**  
   (or Mathematica → File → Open → select that file **from inside this folder**).
5. Click the **blue code cell**, then press **Shift-Enter**.
6. If Mathematica asks:
   - **Enable Dynamics** → Yes  
   - **Evaluate initialization cells** → Yes  
7. Scroll down — the **dashboard** appears as output under the blue cell.
8. Use the **tabs**: **Home | QA Bench | R&D Engine | Chemistry Ref**.

### If it fails

| Symptom | Fix |
|---------|-----|
| Red panel “Cannot find src/” | You opened a copy of the `.nb` outside the folder. Open the `.nb` that sits **next to** `src/`. |
| Blank / no dashboard | Shift-Enter on the blue cell again; enable Dynamics. |
| Tabs do nothing | Enable Dynamics; re-run the blue cell (Shift-Enter). |
| Still stuck | Send Jack a screenshot of the full window including the blue cell and any red text. |

---

## How to use it

### QA Bench (floor / batch release support)

1. Tab → **QA Bench**
2. Choose **product** (spray / hydrogel / HA-forward)
3. Enter **lot**, **date**, measured **pH, ORP, FAC, Total Chlorine, temperature** (conductivity & TOC optional)
4. Read: active HOCl, combined chlorine flag, pass/fail badges, shelf-life estimate, byproduct risk
5. **Export QA Report → PDF** → file goes into the folder’s `export/` directory

**Important:** This is a **decision-support** tool, not a release authority. Confirm FAC, THM/haloamines, and stability with validated lab methods before release.

### R&D Engine (chemist)

Tab → **R&D Engine**, then open the sections you need:

1. Speciation explorer  
2. Electrolysis simulator  
3. Pretreatment / phosphate buffer  
4. Shelf-life / accelerated stability  
5. Byproduct risk explorer  

### Chemistry Ref

Tab → **Chemistry Ref** — HOCl/OCl⁻ table and ORP bands for training / sanity check.

---

## What you may edit later

| File | Purpose |
|------|---------|
| `data/formulations.m` | Products, FAC/pH/ORP windows, excipients, demand coeffs |
| `src/*.wl` CALIBRATION BLOCKS | Rate constants, pKa slope, THM weights, etc. |
| `docs/ASSUMPTIONS.md` | What still needs lab calibration |
| `docs/CHEMISTRY_NOTES.md` | Science reference |

Do **not** rename/move `src/` away from the `.nb` without updating paths.

---

## Optional: GitHub (if Jack shared the repo)

```bash
git clone https://github.com/JackJik/HOCl-QA-Notebook.git
cd HOCl-QA-Notebook
git checkout feat/hocl-qa-suite
```

Then open `HOCl_QA_Suite.nb` from that clone.

---

## Support

Questions or bugs: contact Jack with screenshot + lot/product if QA-related.  
Calibration of demand coefficients and shelf-life rates: use real TG Labs stability data (see `docs/ASSUMPTIONS.md`).
