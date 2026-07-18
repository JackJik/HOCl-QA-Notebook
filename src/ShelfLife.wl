(* ::Package:: *)
(* ShelfLife.wl — first-order decay, Arrhenius, Q10
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["ShelfLife`"];

ShelfLifeConstants::usage = "Default kinetic constants (calibrate to lab data).";
Keff::usage = "Keff[pH, tempC, lightFactor, demandFactor] effective first-order rate (1/day).";
FACAtTime::usage = "FACAtTime[fac0, keff, tDays] remaining FAC ppm.";
TimeToFloor::usage = "TimeToFloor[fac0, keff, floorPPM] days to reach floor.";
ArrheniusFactor::usage = "ArrheniusFactor[tempC, ea, tRef] relative rate vs Tref.";
Q10Factor::usage = "Q10Factor[tempC, tRef, q10] relative rate.";
AcceleratedProjection::usage = "AcceleratedProjection[fac0, pH, tAcc, tAmb, daysAcc, ...] project ambient.";
DecayCurveData::usage = "DecayCurveData[fac0, keff, tMaxDays, n] list of {t, FAC}.";
HalfLifeDays::usage = "HalfLifeDays[keff].";

Begin["`Private`"];

(* ========== CALIBRATION BLOCK — all estimates ========== *)
ShelfLifeConstants = <|
  "kBase" -> 0.002,           (* 1/day at reference conditions — CALIBRATE *)
  "TRefC" -> 25.,
  "Ea" -> 50000.,             (* J/mol — order-of-magnitude; CALIBRATE *)
  "R" -> 8.314,               (* J/mol·K *)
  "Q10" -> 2.,                (* shelf life halves per ~10 °C — editable *)
  "floorPPMDefault" -> 50.,
  "fPH" -> Function[pH,       (* OCl- decomposes faster; rate rises with pH *)
    1. + 4. * (1. / (1. + 10.^(7.54 - pH)))  (* ~1 at low pH, ~5 at high OCl *)
  ],
  "lightDark" -> 1.0,
  "lightAmbient" -> 1.5,
  "lightStrong" -> 3.0,
  "disclaimer" -> "Shelf-life model is an estimate pending calibration to TG Labs real stability data."
|>;
(* ====================================================== *)

ArrheniusFactor[tempC_?NumericQ, ea_ : Automatic, tRef_ : Automatic] := Module[
  {Ea, Tr, T, R},
  Ea = If[ea === Automatic, ShelfLifeConstants["Ea"], ea];
  Tr = If[tRef === Automatic, ShelfLifeConstants["TRefC"], tRef];
  If[!NumericQ[Ea] || !NumericQ[Tr], Return[$Failed]];
  R = ShelfLifeConstants["R"];
  T = tempC + 273.15;
  Tr = Tr + 273.15;
  Exp[-Ea / R * (1./T - 1./Tr)]
];
ArrheniusFactor[___] := $Failed;

Q10Factor[tempC_?NumericQ, tRef_ : Automatic, q10_ : Automatic] := Module[
  {Tr, Q},
  Tr = If[tRef === Automatic, ShelfLifeConstants["TRefC"], tRef];
  Q = If[q10 === Automatic, ShelfLifeConstants["Q10"], q10];
  If[!NumericQ[Tr] || !NumericQ[Q], Return[$Failed]];
  Q^((tempC - Tr) / 10.)
];
Q10Factor[___] := $Failed;

Options[Keff] = {
  "kBase" -> Automatic,
  "UseQ10" -> False,
  "Ea" -> Automatic,
  "Q10" -> Automatic
};
Keff[pH_?NumericQ, tempC_?NumericQ, lightFactor_ : 1.,
    demandFactor_ : 1., opts: OptionsPattern[]] := Module[
  {kb, fpH, fT, useQ10, lf, df},
  If[!NumericQ[lightFactor] || !NumericQ[demandFactor], Return[$Failed]];
  kb = OptionValue["kBase"];
  If[kb === Automatic, kb = ShelfLifeConstants["kBase"]];
  useQ10 = TrueQ[OptionValue["UseQ10"]];
  fpH = ShelfLifeConstants["fPH"][pH];
  fT = If[useQ10,
    Q10Factor[tempC, Automatic, OptionValue["Q10"]],
    ArrheniusFactor[tempC, OptionValue["Ea"]]
  ];
  lf = Max[lightFactor, 0.];
  df = Max[demandFactor, 0.];
  Max[0., kb * fpH * fT * lf * df]
];
Keff[___] := $Failed;

FACAtTime[fac0_?NumericQ, keff_?NumericQ, tDays_?NumericQ] :=
  fac0 * Exp[-keff * tDays];
FACAtTime[___] := $Failed;

TimeToFloor[fac0_?NumericQ, keff_?NumericQ, floorPPM_ : Automatic] := Module[
  {fl},
  fl = If[floorPPM === Automatic, ShelfLifeConstants["floorPPMDefault"], floorPPM];
  If[!NumericQ[fl], Return[$Failed]];
  Which[
    fac0 <= fl, 0.,
    keff <= 0, Infinity,
    True, Log[fac0 / fl] / keff
  ]
];
TimeToFloor[___] := $Failed;

HalfLifeDays[keff_?NumericQ] := If[keff <= 0, Infinity, Log[2.] / keff];
HalfLifeDays[___] := $Failed;

DecayCurveData[fac0_?NumericQ, keff_?NumericQ, tMaxDays_?NumericQ, n_Integer: 50] :=
  Table[{t, FACAtTime[fac0, keff, t]}, {t, 0., tMaxDays, tMaxDays / Max[n, 1]}];
DecayCurveData[___] := {};

(* Elevated-temp days → equivalent ambient shelf projection via Arrhenius ratio *)
AcceleratedProjection[fac0_?NumericQ, pH_?NumericQ,
    tAccC_?NumericQ, tAmbC_?NumericQ, daysAcc_?NumericQ,
    lightFactor_ : 1., demandFactor_ : 1.] := Module[
  {kAcc, kAmb, facEnd, daysAmbEq, daysToFloorAmb},
  kAcc = Keff[pH, tAccC, lightFactor, demandFactor];
  kAmb = Keff[pH, tAmbC, lightFactor, demandFactor];
  facEnd = FACAtTime[fac0, kAcc, daysAcc];
  daysAmbEq = If[kAmb <= 0, Infinity, (kAcc / kAmb) * daysAcc];
  daysToFloorAmb = TimeToFloor[fac0, kAmb];
  <|
    "FACAfterAccelerated" -> facEnd,
    "EquivalentAmbientDays" -> daysAmbEq,
    "AmbientDaysToFloor" -> daysToFloorAmb,
    "kAccelerated" -> kAcc,
    "kAmbient" -> kAmb,
    "Disclaimer" -> ShelfLifeConstants["disclaimer"]
  |>
];
AcceleratedProjection[___] := $Failed;

End[];
EndPackage[];
