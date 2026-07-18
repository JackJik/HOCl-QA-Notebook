(* ::Package:: *)
(* Byproducts.wl — THM + haloamine risk scoring (indicative warnings)
   TG Labs / 50MM — HOCl QA & R&D Suite
   SAFETY-CRITICAL: never report THM concentration as fact. *)

BeginPackage["Byproducts`"];

ByproductConstants::usage = "Risk model weights (estimates).";
THMRiskScore::usage = "THMRiskScore[assoc] score 0-100.";
HaloamineRiskScore::usage = "HaloamineRiskScore[assoc] score 0-100.";
ByproductRiskLevel::usage = "ByproductRiskLevel[score] Green|Yellow|Red.";
ByproductAssessment::usage = "ByproductAssessment[assoc] full warning package.";
RiskDisclaimer::usage = "Mandatory lab-assay disclaimer string.";

Begin["`Private`"];

(* ========== CALIBRATION BLOCK — estimates only ========== *)
ByproductConstants = <|
  "greenMax" -> 30.,
  "yellowMax" -> 60.,
  (* weights for composite score — CALIBRATE / needs Jack's review *)
  "wOrganic" -> 25.,
  "wFAC" -> 20.,
  "wTime" -> 15.,
  "wTemp" -> 15.,
  "wPH" -> 10.,
  "wTOC" -> 15.,
  "wNitrogen" -> 40.,  (* haloamine driver *)
  "wCC" -> 30.,
  "tocSafePPM" -> 1.0,
  "disclaimer" -> "Model is indicative — confirm by lab assay. Trihalomethanes (chloroform, etc.) and chloramines are regulated disinfection byproducts — verify with lab THM/haloamine testing before release. Computed values are models/estimates to be confirmed by validated lab methods."
|>;
(* ======================================================= *)

RiskDisclaimer[] := ByproductConstants["disclaimer"];

ByproductRiskLevel[score_?NumericQ] := Which[
  score <= ByproductConstants["greenMax"], "Green",
  score <= ByproductConstants["yellowMax"], "Yellow",
  True, "Red"
];
ByproductRiskLevel[___] := "Yellow";

(* Inputs (assoc keys, all optional with defaults):
   OrganicLoad (0-1+), NitrogenLoad (0-1+), FAC (ppm), TempC, TimeDays,
   pH, TOC (ppm), CombinedChlorine (ppm) *)
THMRiskScore[p_Association] := Module[
  {org, fac, tDays, temp, pH, toc, s, c = ByproductConstants},
  org = Clip[Lookup[p, "OrganicLoad", 0.], {0., 5.}];
  fac = Max[0., Lookup[p, "FAC", 0.]];
  tDays = Max[0., Lookup[p, "TimeDays", 0.]];
  temp = Lookup[p, "TempC", 25.];
  pH = Lookup[p, "pH", 5.5];
  toc = Max[0., Lookup[p, "TOC", 0.]];
  s = 0.;
  s += c["wOrganic"] * Min[1., org / 1.];
  s += c["wFAC"] * Min[1., fac / 200.];
  s += c["wTime"] * Min[1., tDays / 90.];
  s += c["wTemp"] * Min[1., Max[0., temp - 15.] / 25.];
  s += c["wPH"] * Min[1., Max[0., pH - 5.] / 4.];  (* higher pH → more THM tendency *)
  s += c["wTOC"] * Min[1., toc / Max[c["tocSafePPM"], 0.1]];
  Clip[s, {0., 100.}]
];
THMRiskScore[___] := $Failed;

HaloamineRiskScore[p_Association] := Module[
  {nLoad, cc, s, c = ByproductConstants},
  nLoad = Clip[Lookup[p, "NitrogenLoad", 0.], {0., 5.}];
  cc = Max[0., Lookup[p, "CombinedChlorine", 0.]];
  s = c["wNitrogen"] * Min[1., nLoad / 1.] + c["wCC"] * Min[1., cc / 1.];
  (* residual room from FAC/time mild contribution *)
  s += 10. * Min[1., Max[0., Lookup[p, "FAC", 0.]] / 200.];
  Clip[s, {0., 100.}]
];
HaloamineRiskScore[___] := $Failed;

ByproductAssessment[p_Association] := Module[
  {thm, halo, overall, level, msgs},
  thm = THMRiskScore[p];
  halo = HaloamineRiskScore[p];
  overall = Max[thm, halo];
  level = ByproductRiskLevel[overall];
  msgs = {};
  If[level === "Green",
    AppendTo[msgs, "Byproduct formation potential appears low under entered conditions."]];
  If[level === "Yellow",
    AppendTo[msgs, "⚠ Moderate THM/haloamine formation potential. Review organic/N load, FAC, storage time, and temperature."]];
  If[level === "Red",
    AppendTo[msgs, "⚠ Elevated THM formation potential: organic load + FAC + storage time. Trihalomethanes (chloroform, etc.) and chloramines are regulated disinfection byproducts — verify with lab THM/haloamine testing before release."]];
  If[Lookup[p, "TOC", 0.] > ByproductConstants["tocSafePPM"],
    AppendTo[msgs, "Feedwater TOC above ~1 ppm guidance — distilled/RO preferred."]];
  If[Lookup[p, "CombinedChlorine", 0.] > 0.2,
    AppendTo[msgs, "Combined chlorine elevated — possible chloramine/haloamine from N-containing species or contamination."]];
  AppendTo[msgs, RiskDisclaimer[]];
  <|
    "THMScore" -> thm,
    "HaloamineScore" -> halo,
    "OverallScore" -> overall,
    "Level" -> level,
    "Messages" -> msgs,
    "Disclaimer" -> RiskDisclaimer[]
  |>
];
ByproductAssessment[___] := $Failed;

End[];
EndPackage[];
