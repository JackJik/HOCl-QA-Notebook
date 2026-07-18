(* ::Package:: *)
(* HOClCore.wl — Speciation, FAC/CC, ORP, unit helpers
   TG Labs / 50MM — HOCl QA & R&D Suite
   All constants in one block for lab recalibration. *)

BeginPackage["HOClCore`"];

(* Public symbols *)
HOClConstants::usage = "Association of default chemistry constants.";
pKaHOCl::usage = "pKaHOCl[TCelsius] temperature-corrected pKa of HOCl.";
fHOCl::usage = "fHOCl[pH, TCelsius] fraction of FAC present as HOCl.";
fOCl::usage = "fOCl[pH, TCelsius] fraction of FAC present as OCl-.";
fCl2::usage = "fCl2[pH, TCelsius] approximate Cl2(aq) fraction at low pH.";
ActiveHOClPPM::usage = "ActiveHOClPPM[facPPM, pH, TCelsius] active HOCl in ppm.";
SpeciationTable::usage = "SpeciationTable[] returns reference HOCl/OCl- table.";
CombinedChlorine::usage = "CombinedChlorine[tcPPM, facPPM] = TC - FAC.";
CombinedChlorineWarning::usage = "CombinedChlorineWarning[cc, opts] True if over threshold.";
ORPCategory::usage = "ORPCategory[orpMV] disinfection category string.";
ORPTrendModel::usage = "ORPTrendModel[facPPM, pH, TCelsius] indicative ORP (mV).";
ValidateNumber::usage = "ValidateNumber[x, min, max] returns {ok, value|msg}.";
SafeDivide::usage = "SafeDivide[a, b, default].";
Cl2OffGasWarning::usage = "Cl2OffGasWarning[pH] True if pH below ~3.5.";

Begin["`Private`"];

(* ========== CALIBRATION BLOCK — edit here ========== *)
HOClConstants = <|
  "pKa25C" -> 7.54,            (* Morris 1966 / standard HOCl pKa @ 25 °C *)
  "pKaTempCoeff" -> -0.019,    (* approx d(pKa)/dT °C^-1; van't Hoff linearization — needs Jack's review *)
  "pKaRefT" -> 25.,
  "cl2OnsetPH" -> 3.5,         (* below this, Cl2(aq)/off-gassing risk *)
  "ccAbsoluteThreshold" -> 0.2,(* ppm combined chlorine absolute trip *)
  "ccFractionThreshold" -> 0.15,(* CC/TC fraction trip *)
  "orpBands" -> {
    {"no disinfection", -Infinity, 400},
    {"marginal", 400, 600},
    {"good (chloramine range)", 600, 750},
    {"excellent (HOCl range)", 750, 900},
    {"possible electrode fault", 900, Infinity}
  },
  "disclaimer" -> "Models/estimates — confirm by validated lab methods (DPD/amperometric FAC, lab THM assay, real stability studies)."
|>;
(* ================================================== *)

pKaHOCl[TCelsius_?NumericQ] := Module[{c = HOClConstants},
  c["pKa25C"] + c["pKaTempCoeff"] * (TCelsius - c["pKaRefT"])
];
pKaHOCl[___] := $Failed;

(* Binary HOCl/OCl-; Cl2 treated separately as low-pH warning flag *)
fHOCl[pH_?NumericQ, TCelsius_ : 25.] := Module[{pka},
  If[!NumericQ[TCelsius], Return[$Failed]];
  pka = pKaHOCl[TCelsius];
  1. / (1. + 10.^(pH - pka))
];
fHOCl[___] := $Failed;

fOCl[pH_?NumericQ, TCelsius_ : 25.] := 1. - fHOCl[pH, TCelsius];
fOCl[___] := $Failed;

(* Approximate Cl2(aq) share rises sharply below ~pH 3.5.
   Simplified heuristic for warning UI — not a full Cl2–HOCl–OCl equilibrium.
   Flagged for Jack's review in ASSUMPTIONS.md *)
fCl2[pH_?NumericQ, TCelsius_ : 25.] := Module[{},
  If[!NumericQ[TCelsius], Return[$Failed]];
  If[pH >= HOClConstants["cl2OnsetPH"],
    0.,
    Min[1., 0.5 * (HOClConstants["cl2OnsetPH"] - pH) / 1.5]
  ]
];
fCl2[___] := $Failed;

ActiveHOClPPM[facPPM_?NumericQ, pH_?NumericQ, TCelsius_ : 25.] :=
  facPPM * fHOCl[pH, TCelsius];
ActiveHOClPPM[___] := $Failed;

SpeciationTable[] := {
  (* pH, HOCl%, OCl%, Note — approximate operator reference at 25 °C *)
  {3.0, 97., 0., "Cl2 off-gassing risk"},
  {4.0, 99.7, 0.3, "Optimal stability"},
  {5.0, 99.7, 0.3, "Optimal production target"},
  {6.0, 97., 3., "Acceptable"},
  {7.0, 78., 22., "Efficacy declining"},
  {7.54, 50., 50., "pKa crossover"},
  {8.0, 22., 78., "Hypochlorite dominant"},
  {9.0, 3., 97., "Essentially bleach"}
};

CombinedChlorine[tcPPM_?NumericQ, facPPM_?NumericQ] := Max[0., tcPPM - facPPM];
CombinedChlorine[___] := $Failed;

Options[CombinedChlorineWarning] = {
  "AbsoluteThreshold" -> Automatic,
  "FractionThreshold" -> Automatic,
  "TotalChlorine" -> Automatic
};
CombinedChlorineWarning[cc_?NumericQ, opts: OptionsPattern[]] := Module[
  {abs, frac, tc, absT, fracT},
  absT = OptionValue["AbsoluteThreshold"];
  fracT = OptionValue["FractionThreshold"];
  tc = OptionValue["TotalChlorine"];
  If[absT === Automatic, absT = HOClConstants["ccAbsoluteThreshold"]];
  If[fracT === Automatic, fracT = HOClConstants["ccFractionThreshold"]];
  abs = cc > absT;
  frac = If[NumericQ[tc] && tc > 0, (cc / tc) > fracT, False];
  abs || frac
];
CombinedChlorineWarning[___] := $Failed;

ORPCategory[orpMV_?NumericQ] := Module[{bands = HOClConstants["orpBands"], hit},
  hit = SelectFirst[bands, (#[[2]] <= orpMV < #[[3]]) &, None];
  If[hit === None, "unknown", hit[[1]]]
];
ORPCategory[___] := $Failed;

(* Indicative Nernstian-style qualitative model — NOT a FAC measurement.
   ORP_est ≈ E0' - (RT/F)ln(f(pH, species)) + scale*Log10(FAC)
   Coefficients are order-of-magnitude for R&D exploration only. *)
ORPTrendModel[facPPM_?NumericQ, pH_?NumericQ, TCelsius_ : 25.] := Module[
  {fh, base, nernst, facTerm},
  If[facPPM <= 0, Return[200.]];
  fh = fHOCl[pH, TCelsius];
  base = 900. - 50. * (pH - 5.);  (* centers excellent band near pH 5 HOCl *)
  nernst = 59. * (TCelsius + 273.15) / 298.15 * Log10[Max[fh, 1.*10^-6]];
  facTerm = 40. * Log10[Max[facPPM, 0.1]];
  Clip[base + 0.3 * nernst + facTerm - 80., {200., 1100.}]
];
ORPTrendModel[___] := $Failed;

Cl2OffGasWarning[pH_?NumericQ] := pH < HOClConstants["cl2OnsetPH"];
Cl2OffGasWarning[___] := False;

ValidateNumber[x_, min_: -Infinity, max_: Infinity] := Module[{n},
  n = Quiet[N[x]];
  Which[
    !NumericQ[n], {False, "Enter a valid number."},
    n < min || n > max, {False, "Value out of allowed range (" <> ToString[min] <> "–" <> ToString[max] <> ")."},
    True, {True, n}
  ]
];

SafeDivide[a_?NumericQ, b_?NumericQ, default_: 0.] := If[b == 0 || !NumericQ[b], default, a / b];
SafeDivide[___] := 0.;

End[];
EndPackage[];
