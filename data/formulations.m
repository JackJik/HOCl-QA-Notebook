(* data/formulations.m — editable 50MM / TG Labs product specs
   Loaded by Formulations`LoadFormulations. Coefficients marked ESTIMATE. *)

{
  <|
    "Name" -> "HOCl Cleansing Spray",
    "TargetFAC" -> {50., 225.},
    "TargetPH" -> {4.5, 6.0},
    "ORPExpectation" -> {750., 900.},
    "ShelfLifeClass" -> "A-stable",
    "Excipients" -> {
      <|"Name" -> "NaCl", "PctWW" -> 0.1, "DemandCoeff" -> 0.0,
        "Note" -> "Residual electrolyte; sets ionic strength/conductivity."|>
    },
    "ChlorineDemandRisk" -> "Low organic load → low THM risk but still monitor.",
    "OrganicLoadDefault" -> 0.1,
    "NitrogenLoadDefault" -> 0.05,
    "FloorPPM" -> 50.,
    "Notes" -> "Near-pure HOCl in water; high ORP (750–900 mV) expected. FAC 50–225 ppm."
  |>,
  <|
    "Name" -> "HOCl Hydrogel",
    "TargetFAC" -> {50., 225.},
    "TargetPH" -> {4.5, 6.5},
    "ORPExpectation" -> {650., 900.},
    "ShelfLifeClass" -> "B-demand",
    "Excipients" -> {
      <|"Name" -> "Hyaluronic acid", "PctWW" -> 0.5, "DemandCoeff" -> 2.5,
        "Note" -> "Organic; consumes FAC; MW-dependent. Oxidation/chain-scission risk. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Ectoin", "PctWW" -> 0.5, "DemandCoeff" -> 0.1,
        "Note" -> "Compatible, low demand. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Silica (fumed/colloidal)", "PctWW" -> 1.0, "DemandCoeff" -> 0.05,
        "Note" -> "Largely inert; may shift pH slightly. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Laponite", "PctWW" -> 1.5, "DemandCoeff" -> 0.4,
        "Note" -> "Rheology; surface adsorption of chlorine; ionic-strength sensitivity. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "R 5500 synthetic clay", "PctWW" -> 0.5, "DemandCoeff" -> 0.4,
        "Note" -> "Rheology; surface adsorption. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "KH2PO4", "PctWW" -> 0.2, "DemandCoeff" -> 0.0,
        "Note" -> "Phosphate buffer acid form; primary pH control with Na2HPO4."|>,
      <|"Name" -> "Na2HPO4", "PctWW" -> 0.1, "DemandCoeff" -> 0.0,
        "Note" -> "Phosphate buffer base form; primary pH control with KH2PO4."|>,
      <|"Name" -> "Glycerin", "PctWW" -> 3.0, "DemandCoeff" -> 0.3,
        "Note" -> "Humectant; mild demand; generally compatible. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Butylene glycol", "PctWW" -> 2.0, "DemandCoeff" -> 0.25,
        "Note" -> "Humectant; mild demand; generally compatible. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "NaCl", "PctWW" -> 0.2, "DemandCoeff" -> 0.0,
        "Note" -> "Residual electrolyte; sets ionic strength/conductivity."|>
    },
    "ChlorineDemandRisk" -> "Gel matrix adds chlorine demand and stability complications.",
    "OrganicLoadDefault" -> 0.8,
    "NitrogenLoadDefault" -> 0.15,
    "FloorPPM" -> 50.,
    "Notes" -> "Phosphate buffer pair is the primary pH control lever in the gel."
  |>,
  <|
    "Name" -> "HOCl Hydrogel (HA-forward)",
    "TargetFAC" -> {50., 200.},
    "TargetPH" -> {5.0, 6.5},
    "ORPExpectation" -> {650., 880.},
    "ShelfLifeClass" -> "C-high-demand",
    "Excipients" -> {
      <|"Name" -> "Hyaluronic acid", "PctWW" -> 1.5, "DemandCoeff" -> 2.5,
        "Note" -> "Higher HA — elevated FAC demand & chain-scission risk. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Ectoin", "PctWW" -> 1.0, "DemandCoeff" -> 0.1,
        "Note" -> "Compatible, low demand. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Glycerin", "PctWW" -> 5.0, "DemandCoeff" -> 0.3,
        "Note" -> "Humectant; mild demand. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "Butylene glycol", "PctWW" -> 3.0, "DemandCoeff" -> 0.25,
        "Note" -> "Humectant; mild demand. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "KH2PO4", "PctWW" -> 0.25, "DemandCoeff" -> 0.0,
        "Note" -> "Phosphate buffer acid."|>,
      <|"Name" -> "Na2HPO4", "PctWW" -> 0.12, "DemandCoeff" -> 0.0,
        "Note" -> "Phosphate buffer base."|>,
      <|"Name" -> "Laponite", "PctWW" -> 1.0, "DemandCoeff" -> 0.4,
        "Note" -> "Rheology clay. ESTIMATE — calibrate against lab data."|>,
      <|"Name" -> "NaCl", "PctWW" -> 0.15, "DemandCoeff" -> 0.0,
        "Note" -> "Residual electrolyte."|>
    },
    "ChlorineDemandRisk" -> "High organic (HA) load — monitor FAC decay and THM potential closely.",
    "OrganicLoadDefault" -> 1.2,
    "NitrogenLoadDefault" -> 0.2,
    "FloorPPM" -> 50.,
    "Notes" -> "Higher HA variant for R&D comparison."
  |>
}
