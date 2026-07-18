(* ::Package:: *)
(* Formulations.wl — 50MM product definitions & compatibility
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["Formulations`"];

LoadFormulations::usage = "LoadFormulations[path] load data/formulations.m";
DefaultFormulations::usage = "DefaultFormulations[] built-in product list.";
ProductNames::usage = "ProductNames[forms] list of product names.";
GetProduct::usage = "GetProduct[forms, name] product association.";
ExcipientDemandFactor::usage = "ExcipientDemandFactor[product] composite demand multiplier.";
SpecPassFail::usage = "SpecPassFail[product, measurements] per-parameter badges.";
ProductChlorineDemand::usage = "ProductChlorineDemand[product] total demand estimate.";

Begin["`Private`"];

DefaultExcipients[] := {
  <|"Name" -> "Hyaluronic acid", "DemandCoeff" -> 2.5,
    "Note" -> "Organic; consumes FAC; MW-dependent. Oxidation/chain-scission risk. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "Ectoin", "DemandCoeff" -> 0.1,
    "Note" -> "Compatible, low demand. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "Silica (fumed/colloidal)", "DemandCoeff" -> 0.05,
    "Note" -> "Largely inert; may shift pH slightly. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "Laponite", "DemandCoeff" -> 0.4,
    "Note" -> "Rheology clay; surface adsorption of chlorine; ionic-strength sensitive. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "R 5500 synthetic clay", "DemandCoeff" -> 0.4,
    "Note" -> "Rheology; surface adsorption; ionic-strength sensitivity. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "KH2PO4", "DemandCoeff" -> 0.0,
    "Note" -> "Phosphate buffer acid form; primary pH control (with Na2HPO4). Buffering, not demand."|>,
  <|"Name" -> "Na2HPO4", "DemandCoeff" -> 0.0,
    "Note" -> "Phosphate buffer base form; primary pH control (with KH2PO4)."|>,
  <|"Name" -> "Glycerin", "DemandCoeff" -> 0.3,
    "Note" -> "Humectant; mild demand; generally compatible. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "Butylene glycol", "DemandCoeff" -> 0.25,
    "Note" -> "Humectant; mild demand; generally compatible. ESTIMATE — calibrate against lab data."|>,
  <|"Name" -> "NaCl", "DemandCoeff" -> 0.0,
    "Note" -> "Residual electrolyte; sets ionic strength/conductivity."|>
};

DefaultFormulations[] := {
  <|
    "Name" -> "HOCl Cleansing Spray",
    "TargetFAC" -> {50., 225.},
    "TargetPH" -> {4.5, 6.0},
    "ORPExpectation" -> {750., 900.},
    "ShelfLifeClass" -> "A-stable",
    "Excipients" -> {
      <|"Name" -> "NaCl", "PctWW" -> 0.1, "DemandCoeff" -> 0.0, "Note" -> "Residual electrolyte."|>
    },
    "ChlorineDemandRisk" -> "Low organic load → low THM risk but still monitor.",
    "OrganicLoadDefault" -> 0.1,
    "NitrogenLoadDefault" -> 0.05,
    "FloorPPM" -> 50.,
    "Notes" -> "Near-pure HOCl in water; high ORP expected."
  |>,
  <|
    "Name" -> "HOCl Hydrogel",
    "TargetFAC" -> {50., 225.},
    "TargetPH" -> {4.5, 6.5},
    "ORPExpectation" -> {650., 900.},
    "ShelfLifeClass" -> "B-demand",
    "Excipients" -> {
      <|"Name" -> "Hyaluronic acid", "PctWW" -> 0.5, "DemandCoeff" -> 2.5,
        "Note" -> "Organic; consumes FAC; oxidation/chain-scission risk. ESTIMATE."|>,
      <|"Name" -> "Ectoin", "PctWW" -> 0.5, "DemandCoeff" -> 0.1, "Note" -> "Compatible, low demand. ESTIMATE."|>,
      <|"Name" -> "Silica (fumed/colloidal)", "PctWW" -> 1.0, "DemandCoeff" -> 0.05, "Note" -> "Largely inert. ESTIMATE."|>,
      <|"Name" -> "Laponite", "PctWW" -> 1.5, "DemandCoeff" -> 0.4, "Note" -> "Clay adsorption. ESTIMATE."|>,
      <|"Name" -> "R 5500 synthetic clay", "PctWW" -> 0.5, "DemandCoeff" -> 0.4, "Note" -> "Clay adsorption. ESTIMATE."|>,
      <|"Name" -> "KH2PO4", "PctWW" -> 0.2, "DemandCoeff" -> 0.0, "Note" -> "Phosphate buffer acid."|>,
      <|"Name" -> "Na2HPO4", "PctWW" -> 0.1, "DemandCoeff" -> 0.0, "Note" -> "Phosphate buffer base."|>,
      <|"Name" -> "Glycerin", "PctWW" -> 3.0, "DemandCoeff" -> 0.3, "Note" -> "Humectant mild demand. ESTIMATE."|>,
      <|"Name" -> "Butylene glycol", "PctWW" -> 2.0, "DemandCoeff" -> 0.25, "Note" -> "Humectant mild demand. ESTIMATE."|>,
      <|"Name" -> "NaCl", "PctWW" -> 0.2, "DemandCoeff" -> 0.0, "Note" -> "Residual electrolyte."|>
    },
    "ChlorineDemandRisk" -> "Gel matrix adds chlorine demand and stability complications.",
    "OrganicLoadDefault" -> 0.8,
    "NitrogenLoadDefault" -> 0.15,
    "FloorPPM" -> 50.,
    "Notes" -> "Phosphate buffer pair is primary pH control lever in gel."
  |>,
  <|
    "Name" -> "HOCl Hydrogel (HA-forward)",
    "TargetFAC" -> {50., 200.},
    "TargetPH" -> {5.0, 6.5},
    "ORPExpectation" -> {650., 880.},
    "ShelfLifeClass" -> "C-high-demand",
    "Excipients" -> {
      <|"Name" -> "Hyaluronic acid", "PctWW" -> 1.5, "DemandCoeff" -> 2.5,
        "Note" -> "Higher HA — elevated FAC demand & chain-scission risk. ESTIMATE."|>,
      <|"Name" -> "Ectoin", "PctWW" -> 1.0, "DemandCoeff" -> 0.1, "Note" -> "Compatible. ESTIMATE."|>,
      <|"Name" -> "Glycerin", "PctWW" -> 5.0, "DemandCoeff" -> 0.3, "Note" -> "Humectant. ESTIMATE."|>,
      <|"Name" -> "Butylene glycol", "PctWW" -> 3.0, "DemandCoeff" -> 0.25, "Note" -> "Humectant. ESTIMATE."|>,
      <|"Name" -> "KH2PO4", "PctWW" -> 0.25, "DemandCoeff" -> 0.0, "Note" -> "Phosphate buffer acid."|>,
      <|"Name" -> "Na2HPO4", "PctWW" -> 0.12, "DemandCoeff" -> 0.0, "Note" -> "Phosphate buffer base."|>,
      <|"Name" -> "Laponite", "PctWW" -> 1.0, "DemandCoeff" -> 0.4, "Note" -> "Rheology. ESTIMATE."|>,
      <|"Name" -> "NaCl", "PctWW" -> 0.15, "DemandCoeff" -> 0.0, "Note" -> "Electrolyte."|>
    },
    "ChlorineDemandRisk" -> "High organic (HA) load — monitor FAC decay and THM potential closely.",
    "OrganicLoadDefault" -> 1.2,
    "NitrogenLoadDefault" -> 0.2,
    "FloorPPM" -> 50.,
    "Notes" -> "Higher HA variant for R&D comparison."
  |>
};

LoadFormulations[path_String] := Module[{data},
  data = Quiet[Check[Get[path], $Failed]];
  If[data === $Failed || !ListQ[data],
    DefaultFormulations[],
    data
  ]
];
LoadFormulations[___] := DefaultFormulations[];

ProductNames[forms_List] := Lookup[#, "Name", ""] & /@ forms;
ProductNames[___] := {};

GetProduct[forms_List, name_String] := Module[{hit},
  hit = SelectFirst[forms, (#["Name"] === name) &, None];
  hit
];
GetProduct[___] := None;

(* Demand multiplier: 1 + sum(coeff * %w/w)/scale — order-of-magnitude *)
ExcipientDemandFactor[product_Association] := Module[
  {ex = Lookup[product, "Excipients", {}], total = 0.},
  total = Total[
    (Lookup[#, "DemandCoeff", 0.] * Lookup[#, "PctWW", 0.]) & /@ ex
  ];
  1. + total / 5.  (* scale so typical gel ~1.5–3x — CALIBRATE *)
];
ExcipientDemandFactor[___] := 1.;

ProductChlorineDemand[product_Association] := Module[
  {ex = Lookup[product, "Excipients", {}]},
  (* mg FAC-scale index per formulation — not absolute mg *)
  Total[(Lookup[#, "DemandCoeff", 0.] * Lookup[#, "PctWW", 0.]) & /@ ex]
];
ProductChlorineDemand[___] := 0.;

(* measurements: Association with PH, FAC, ORP, TempC, optional Conductivity *)
SpecPassFail[product_Association, m_Association] := Module[
  {ph, fac, orp, facR, phR, orpR, results},
  ph = Lookup[m, "pH", None];
  fac = Lookup[m, "FAC", None];
  orp = Lookup[m, "ORP", None];
  facR = Lookup[product, "TargetFAC", {50., 225.}];
  phR = Lookup[product, "TargetPH", {4.5, 6.0}];
  orpR = Lookup[product, "ORPExpectation", {750., 900.}];
  results = <||>;
  If[NumericQ[ph],
    results["pH"] = <|"Value" -> ph, "Range" -> phR,
      "Pass" -> (phR[[1]] <= ph <= phR[[2]])|>];
  If[NumericQ[fac],
    results["FAC"] = <|"Value" -> fac, "Range" -> facR,
      "Pass" -> (facR[[1]] <= fac <= facR[[2]])|>];
  If[NumericQ[orp],
    results["ORP"] = <|"Value" -> orp, "Range" -> orpR,
      "Pass" -> (orpR[[1]] <= orp <= orpR[[2]])|>];
  results
];
SpecPassFail[___] := <||>;

End[];
EndPackage[];
