#!/usr/bin/env wolframscript
(* test_core.wls — HOClCore unit tests *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
Get["HOClCore.wl"];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];
approx[a_, b_, tol_: 0.01] := NumericQ[a] && NumericQ[b] && Abs[a - b] <= tol;

(* fHOCl @ pKa crossover *)
assert[approx[fHOCl[7.54, 25], 0.50, 0.01], "fHOCl[7.54,25] ≈ 0.50"];
assert[approx[fHOCl[6.0, 25], 0.97, 0.02], "fHOCl[6.0,25] ≈ 0.97"];
assert[approx[fHOCl[9.0, 25], 0.03, 0.02], "fHOCl[9.0,25] ≈ 0.03"];
assert[fHOCl[4.5, 25] >= 0.99, "fHOCl[4.5,25] ≥ 0.99"];

(* Active HOCl: 150 ppm at pH 6 → ≈ 145 ppm *)
active = ActiveHOClPPM[150., 6.0, 25.];
assert[approx[active, 145., 3.], "Active HOCl 150 ppm @ pH 6 ≈ 145 ppm"];

(* Combined chlorine *)
cc = CombinedChlorine[3.0, 2.6];
assert[approx[cc, 0.4, 0.001], "CC = TC-FAC = 0.4"];
assert[CombinedChlorineWarning[0.4, "AbsoluteThreshold" -> 0.2, "TotalChlorine" -> 3.0],
  "CC 0.4 trips warning at 0.2 threshold"];
assert[!CombinedChlorineWarning[0.1, "AbsoluteThreshold" -> 0.2],
  "CC 0.1 does not trip absolute 0.2"];

(* Cl2 off-gas *)
assert[Cl2OffGasWarning[3.0], "pH 3.0 off-gas warning"];
assert[!Cl2OffGasWarning[5.0], "pH 5.0 no off-gas warning"];

(* pKa temp correction direction: higher T → lower pKa *)
assert[pKaHOCl[35.] < pKaHOCl[25.], "pKa decreases with temperature"];

(* ORP categories *)
assert[ORPCategory[800] === "excellent (HOCl range)", "ORP 800 excellent"];
assert[ORPCategory[300] === "no disinfection", "ORP 300 no disinfection"];

(* Speciation table exists *)
assert[Length[SpeciationTable[]] >= 8, "SpeciationTable has ≥8 rows"];

Print["\n=== test_core: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
