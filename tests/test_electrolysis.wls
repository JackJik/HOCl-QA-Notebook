#!/usr/bin/env wolframscript
(* test_electrolysis.wls *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
Get["HOClCore.wl"];
Get["Electrolysis.wl"];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];
approx[a_, b_, tol_] := NumericQ[a] && NumericQ[b] && Abs[a - b] <= tol;

(* 10 A × 10 min @ 100% CE → 1630 mg *)
m100 = FaradayMassHOCl[10., 10., 1.0];
assert[approx[m100, 1630., 1.], "10A×10min @100% CE ≈ 1630 mg HOCl"];

m80 = FaradayMassHOCl[10., 10., 0.8];
assert[approx[m80, 1304., 1.], "10A×10min @80% CE ≈ 1304 mg HOCl"];

(* Rate *)
assert[approx[ProductionRateMgPerAmpMin[1.0], 16.3, 0.01], "16.3 mg per A·min @100%"];
assert[approx[ProductionRateMgPerAmpMin[0.8], 13.04, 0.05], "13.04 mg per A·min @80%"];

(* FAC ppm: 1630 mg in 10 L → 163 ppm *)
fac = ExpectedFACPPM[10., 10., 10., 1.0];
assert[approx[fac, 163., 1.], "Expected FAC 1630 mg / 10 L = 163 ppm"];

(* Energy *)
e = EnergyUseWh[10., 5., 60.]; (* 10A * 5V * 1h = 50 Wh *)
assert[approx[e, 50., 0.1], "Energy 10A 5V 60min = 50 Wh"];

(* Troubleshoot returns list *)
msgs = CETroubleshoot[<|"NaClPct" -> 0.2, "TempC" -> 40., "pH" -> 8., "CE" -> 0.5|>];
assert[ListQ[msgs] && Length[msgs] >= 1, "CETroubleshoot returns guidance"];

Print["\n=== test_electrolysis: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
