(* ::Package:: *)
(* Pretreatment.wl — acid dosing, phosphate buffer designer
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["Pretreatment`"];

PretreatmentConstants::usage = "Acid and buffer constants.";
HendersonHasselbalchPH::usage = "HendersonHasselbalchPH[pKa, base, acid] pH.";
HendersonHasselbalchRatio::usage = "HendersonHasselbalchRatio[pKa, pH] base/acid ratio.";
BufferCapacity::usage = "BufferCapacity[totalC, pH, pKa] approximate beta.";
StrongAcidDoseML::usage = "StrongAcidDoseML[volL, pHStart, pHTarget, acidConcM, opts].";
WeakAcidDoseEstimate::usage = "WeakAcidDoseEstimate[...] rough dose for unbuffered water + weak acid.";
AcidCatalog::usage = "AcidCatalog[] named acids with pKa/strength info.";
PhosphateBufferRatio::usage = "PhosphateBufferRatio[pH] KH2PO4/Na2HPO4 base/acid.";
PhosphateBufferDesign::usage = "PhosphateBufferDesign[pH, totalMolar] acid/base molarities.";
VinegarAceticEquiv::usage = "VinegarAceticEquiv[vinegarPct] molarity approx.";

Begin["`Private`"];

(* ========== CALIBRATION BLOCK ========== *)
PretreatmentConstants = <|
  "aceticPKa" -> 4.76,
  "citricPKa1" -> 3.13,       (* use primary for simple slot; multi-protic simplified *)
  "phosphatePKa2" -> 7.2,     (* H2PO4- ⇌ HPO4^2- *)
  "vinegarDefaultPct" -> 5.,  (* % w/v acetic acid *)
  "hclMuriaticDefaultPct" -> 31., (* % w/w typical muriatic *)
  "distilledCaution" -> "Distilled water is poorly buffered — it overshoots easily. Dose slowly and re-measure pH.",
  "densityAceticGlacial" -> 1.049, (* g/mL approx *)
  "MWAcetic" -> 60.05,
  "MWHCl" -> 36.46
|>;
(* ====================================== *)

AcidCatalog[] := {
  <|"Name" -> "Acetic acid (glacial)", "Type" -> "weak", "pKa" -> PretreatmentConstants["aceticPKa"],
    "DefaultPct" -> 99.7, "Note" -> "Weak acid; Henderson–Hasselbalch buffering near pKa 4.76."|>,
  <|"Name" -> "Vinegar (~5% acetic)", "Type" -> "weak", "pKa" -> PretreatmentConstants["aceticPKa"],
    "DefaultPct" -> 5., "Note" -> "Food-grade dilute acetic acid."|>,
  <|"Name" -> "HCl / muriatic", "Type" -> "strong", "pKa" -> -6.3,
    "DefaultPct" -> PretreatmentConstants["hclMuriaticDefaultPct"],
    "Note" -> "Strong acid; near-stoichiometric H+. Enter actual % as input."|>,
  <|"Name" -> "Citric / generic weak acid", "Type" -> "weak",
    "pKa" -> PretreatmentConstants["citricPKa1"],
    "DefaultPct" -> 50., "Note" -> "Editable pKa slot; multi-protic simplified to single pKa."|>
};

HendersonHasselbalchPH[pKa_?NumericQ, base_?NumericQ, acid_?NumericQ] := Module[{},
  If[acid <= 0, Return[$Failed]];
  pKa + Log10[Max[base, 1.*10^-12] / acid]
];
HendersonHasselbalchPH[___] := $Failed;

HendersonHasselbalchRatio[pKa_?NumericQ, pH_?NumericQ] := 10.^(pH - pKa);
HendersonHasselbalchRatio[___] := $Failed;

(* β ≈ 2.303 × C × α(1−α) *)
BufferCapacity[totalC_?NumericQ, pH_?NumericQ, pKa_?NumericQ] := Module[{alpha},
  alpha = 10.^(pH - pKa) / (1. + 10.^(pH - pKa));
  2.303 * totalC * alpha * (1. - alpha)
];
BufferCapacity[___] := $Failed;

PhosphateBufferRatio[pH_?NumericQ] :=
  HendersonHasselbalchRatio[PretreatmentConstants["phosphatePKa2"], pH];
PhosphateBufferRatio[___] := $Failed;

PhosphateBufferDesign[pH_?NumericQ, totalMolar_?NumericQ] := Module[
  {r, acid, base},
  If[totalMolar <= 0, Return[$Failed]];
  r = PhosphateBufferRatio[pH]; (* base/acid = [HPO4]/[H2PO4] *)
  acid = totalMolar / (1. + r);  (* KH2PO4 *)
  base = totalMolar - acid;      (* Na2HPO4 *)
  <|
    "pH" -> pH,
    "pKa2" -> PretreatmentConstants["phosphatePKa2"],
    "TotalM" -> totalMolar,
    "AcidM_KH2PO4" -> acid,
    "BaseM_Na2HPO4" -> base,
    "BaseAcidRatio" -> r,
    "Beta" -> BufferCapacity[totalMolar, pH, PretreatmentConstants["phosphatePKa2"]],
    "Note" -> "Phosphate pair primary pH control in hydrogels. Confirm ionic strength vs clay rheology."
  |>
];
PhosphateBufferDesign[___] := $Failed;

(* Approximate molarity of vinegar/acetic solutions from % w/v *)
VinegarAceticEquiv[vinegarPct_?NumericQ] := Module[
  {gPerL = vinegarPct * 10.}, (* % w/v → g/L if % means g/100mL *)
  gPerL / PretreatmentConstants["MWAcetic"]
];

(* Strong acid: unbuffered water H+ from pH_start to pH_target.
   For distilled water, [H+] ≈ 10^(-pH) (ignore OH- crossover carefully).
   moles H+ needed ≈ V * (10^(-pH_t) - 10^(-pH_s)) when acidifying (pH_t < pH_s).
   This is a stoichiometric estimate for poorly buffered water. *)
Options[StrongAcidDoseML] = {"AcidDensity" -> 1.16}; (* approx muriatic ~31% *)
StrongAcidDoseML[volL_?NumericQ, pHStart_?NumericQ, pHTarget_?NumericQ,
    acidConcM_?NumericQ, opts: OptionsPattern[]] := Module[
  {dH, moles, mL},
  If[volL <= 0 || acidConcM <= 0, Return[$Failed]];
  If[pHTarget >= pHStart,
    Return[<|"DoseML" -> 0., "Message" -> "Target pH is not below start pH; no acid dose.",
      "Caution" -> PretreatmentConstants["distilledCaution"]|>]
  ];
  dH = 10.^(-pHTarget) - 10.^(-pHStart); (* mol/L H+ increase *)
  moles = Max[0., dH] * volL;
  mL = (moles / acidConcM) * 1000.;
  <|
    "DoseML" -> mL,
    "MolesH" -> moles,
    "AcidConcM" -> acidConcM,
    "VolumeL" -> volL,
    "pHStart" -> pHStart,
    "pHTarget" -> pHTarget,
    "Caution" -> PretreatmentConstants["distilledCaution"],
    "Disclaimer" -> "Stoichiometric estimate for unbuffered water — dose slowly and re-measure."
  |>
];
StrongAcidDoseML[___] := $Failed;

(* HCl % w/w → approx molarity (density optional) *)
HClMolarityFromPct[pctWW_?NumericQ, density_ : 1.16] :=
  (pctWW / 100.) * If[NumericQ[density], density, 1.16] * 1000. / PretreatmentConstants["MWHCl"];

(* Weak acid dose estimate: aim for total weak-acid concentration that
   can buffer near target. For unbuffered water, rough guide:
   moles ≈ V * 10^(-pHTarget) * factor + buffer reserve.
   Prefer HH when a conjugate base is present; for pure acid into distilled,
   estimate millimolar acetic around target pH. *)
WeakAcidDoseEstimate[volL_?NumericQ, pHStart_?NumericQ, pHTarget_?NumericQ,
    acidMolarity_?NumericQ, pKa_?NumericQ] := Module[
  {targetHA, moles, mL, fracHA},
  If[volL <= 0 || acidMolarity <= 0, Return[$Failed]];
  (* Fraction protonated at target: for monoprotic HA, fHA = 1/(1+10^(pH-pKa)) *)
  fracHA = 1. / (1. + 10.^(pHTarget - pKa));
  (* Order-of-magnitude: establish ~1 mM total buffer capacity class at target.
     Calibrate against lab titration — estimate. *)
  targetHA = 0.001; (* 1 mmol/L total weak acid — CALIBRATE *)
  moles = targetHA * volL;
  mL = (moles / acidMolarity) * 1000.;
  <|
    "DoseML" -> mL,
    "TargetTotalWeakAcidM" -> targetHA,
    "FracHAAtTarget" -> fracHA,
    "pKa" -> pKa,
    "pHTarget" -> pHTarget,
    "VolumeL" -> volL,
    "Caution" -> PretreatmentConstants["distilledCaution"],
    "Disclaimer" -> "Estimate — calibrate against lab titration. Weak-acid dosing into distilled water is sensitive."
  |>
];
WeakAcidDoseEstimate[___] := $Failed;

(* Export HCl helper for package users *)
Pretreatment`HClMolarityFromPct = HClMolarityFromPct;

End[];
EndPackage[];
