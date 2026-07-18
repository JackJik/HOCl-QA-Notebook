(* ::Package:: *)
(* Electrolysis.wl — Faraday production, CE, troubleshooting
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["Electrolysis`"];

Needs["HOClCore`"];

ElectrolysisConstants::usage = "Default electrolysis constants.";
FaradayMassHOCl::usage = "FaradayMassHOCl[currentA, timeMin, ce] mass of HOCl in mg.";
ExpectedFACPPM::usage = "ExpectedFACPPM[currentA, timeMin, volumeL, ce] FAC ppm.";
ProductionRateMgPerAmpMin::usage = "mg HOCl per amp-minute at given CE.";
EnergyUseWh::usage = "EnergyUseWh[currentA, voltageV, timeMin] Wh.";
CETroubleshoot::usage = "CETroubleshoot[assoc] returns guidance strings.";
ReactorGuidance::usage = "ReactorGuidance[] returns recommended operating windows.";

Begin["`Private`"];

(* ========== CALIBRATION BLOCK ========== *)
ElectrolysisConstants = <|
  "F" -> 96485.,              (* C/mol Faraday constant *)
  "n" -> 2.,                  (* electrons for Cl- → 1/2 Cl2 → HOCl path *)
  "MHOCl" -> 52.46,           (* g/mol HOCl *)
  "mgPerAmpMin100" -> 16.3,   (* mg HOCl per A·min at 100% CE *)
  "typicalCE" -> {0.70, 0.85},
  "currentDensityMA" -> {50., 200.},  (* mA/cm^2 *)
  "naClPct" -> {0.5, 3.0},            (* % w/v *)
  "tempC" -> {15., 30.},
  "pHTarget" -> {4.0, 6.0}
|>;
(* ====================================== *)

(* Mass (g) = (I t M) / (n F); convert A·min carefully:
   I(A)*t(s)*M/(n*F) with t(s)=tMin*60
   At 100% CE: 1 A · 1 min → 16.3 mg HOCl (spec) *)
FaradayMassHOCl[currentA_?NumericQ, timeMin_?NumericQ, ce_ : 1.] := Module[
  {c = ElectrolysisConstants},
  If[!NumericQ[ce], Return[$Failed]];
  Max[0., currentA * timeMin * c["mgPerAmpMin100"] * Clip[ce, {0., 1.}]]
];
FaradayMassHOCl[___] := $Failed;

ExpectedFACPPM[currentA_?NumericQ, timeMin_?NumericQ, volumeL_?NumericQ, ce_ : 1.] := Module[
  {mg},
  If[!NumericQ[ce] || volumeL <= 0, Return[$Failed]];
  mg = FaradayMassHOCl[currentA, timeMin, ce];
  (* ppm ≈ mg/L for dilute aqueous *)
  mg / volumeL
];
ExpectedFACPPM[___] := $Failed;

ProductionRateMgPerAmpMin[ce_ : 1.] :=
  ElectrolysisConstants["mgPerAmpMin100"] * Clip[If[NumericQ[ce], ce, 1.], {0., 1.}];

EnergyUseWh[currentA_?NumericQ, voltageV_?NumericQ, timeMin_?NumericQ] :=
  currentA * voltageV * (timeMin / 60.);
EnergyUseWh[___] := $Failed;

ReactorGuidance[] := ElectrolysisConstants;

CETroubleshoot[params_Association] := Module[
  {msgs = {},
   naCl = Lookup[params, "NaClPct", 1.5],
   temp = Lookup[params, "TempC", 25.],
   pH = Lookup[params, "pH", 5.],
   ce = Lookup[params, "CE", 0.8],
   fouling = Lookup[params, "Fouling", False],
   cd = Lookup[params, "CurrentDensity", 100.]},
  If[naCl < 0.5, AppendTo[msgs, "Low NaCl → O2 evolution competes; raise brine to 0.5–3.0% w/v."]];
  If[naCl > 3.0, AppendTo[msgs, "High NaCl: check conductivity/corrosion and product residual salt specs."]];
  If[temp > 30., AppendTo[msgs, "High temperature → side reactions and faster FAC decay; cool to 15–30 °C."]];
  If[temp < 15., AppendTo[msgs, "Low temperature may slow kinetics; typical window 15–30 °C."]];
  If[pH > 6.5, AppendTo[msgs, "High pH → OCl- dominant and back-reactions; target pH 4.0–6.0 for HOCl."]];
  If[pH < 3.5, AppendTo[msgs, "Low pH → Cl2(aq)/off-gassing risk; raise toward 4–6."]];
  If[TrueQ[fouling], AppendTo[msgs, "Fouling/scale → higher resistance, lower CE; clean electrodes and check flow."]];
  If[cd < 50. || cd > 200., AppendTo[msgs, "Current density outside 50–200 mA/cm^2 guidance window."]];
  If[ce < 0.70, AppendTo[msgs, "CE below typical 70–85%: check brine, temperature, fouling, and pH."]];
  If[msgs === {}, {"Operating parameters within typical guidance windows."}, msgs]
];
CETroubleshoot[___] := {"Provide parameters as an Association."};

End[];
EndPackage[];
