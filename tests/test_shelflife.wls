#!/usr/bin/env wolframscript
(* test_shelflife.wls *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
Get["ShelfLife.wl"];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];
approx[a_, b_, tol_] := NumericQ[a] && NumericQ[b] && Abs[a - b] <= tol;

(* Known half-life: k = ln2 / t_half; t_half = 10 days → k = 0.0693147 *)
k = Log[2.] / 10.;
fac0 = 150.;
assert[approx[FACAtTime[fac0, k, 10.], 75., 0.01], "FAC half-life 10 d: 150→75"];
assert[approx[FACAtTime[fac0, k, 0.], 150., 0.01], "FAC(t=0)=FAC0"];
assert[approx[FACAtTime[fac0, k, 20.], 37.5, 0.1], "FAC two half-lives → 37.5"];

(* Time to floor 50 ppm from 150 with same k *)
tFloor = TimeToFloor[150., k, 50.];
expectedT = Log[150./50.] / k;
assert[approx[tFloor, expectedT, 0.01], "TimeToFloor matches analytic"];

(* HalfLifeDays *)
assert[approx[HalfLifeDays[k], 10., 0.01], "HalfLifeDays = 10"];

(* Arrhenius: higher T → higher rate factor *)
assert[ArrheniusFactor[35.] > ArrheniusFactor[25.], "Arrhenius rate rises with T"];

(* Q10 ≈ 2 per 10 °C *)
assert[approx[Q10Factor[35., 25., 2.], 2., 0.01], "Q10=2 → factor 2 at +10 °C"];

(* Keff positive *)
ke = Keff[5.5, 25., 1., 1.];
assert[NumericQ[ke] && ke > 0, "Keff positive at default"];

(* Decay curve *)
dc = DecayCurveData[150., k, 30., 10];
assert[ListQ[dc] && Length[dc] >= 2, "DecayCurveData returns points"];

(* Accelerated projection *)
ap = AcceleratedProjection[150., 5.5, 40., 25., 14., 1., 1.];
assert[AssociationQ[ap] && NumericQ[ap["AmbientDaysToFloor"]],
  "AcceleratedProjection returns ambient days"];

Print["\n=== test_shelflife: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
