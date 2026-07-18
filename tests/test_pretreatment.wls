#!/usr/bin/env wolframscript
(* test_pretreatment.wls *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
Get["Pretreatment.wl"];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];
approx[a_, b_, tol_] := NumericQ[a] && NumericQ[b] && Abs[a - b] <= tol;

(* Henderson–Hasselbalch: pH = pKa → base/acid = 1 *)
r = HendersonHasselbalchRatio[7.2, 7.2];
assert[approx[r, 1.0, 0.001], "Phosphate pKa2 7.2 @ pH 7.2 → base/acid = 1.0"];

ph = HendersonHasselbalchPH[7.2, 1.0, 1.0];
assert[approx[ph, 7.2, 0.001], "HH pH with equal base/acid = pKa"];

(* Phosphate buffer design *)
pb = PhosphateBufferDesign[7.2, 0.1];
assert[AssociationQ[pb], "PhosphateBufferDesign returns Association"];
assert[approx[pb["BaseAcidRatio"], 1.0, 0.001], "Phosphate design ratio @ 7.2 = 1"];
assert[approx[pb["AcidM_KH2PO4"], 0.05, 0.001], "Equal split 0.05 M each at pH=pKa"];

(* Buffer capacity positive at pKa *)
beta = BufferCapacity[0.1, 7.2, 7.2];
assert[NumericQ[beta] && beta > 0, "Buffer capacity β > 0 at pKa"];

(* Strong acid stoichiometric: 1 L from pH 7 to pH 4
   Δ[H+] ≈ 1e-4 - 1e-7 ≈ 9.9e-5 mol
   1 M acid → ~0.099 mL *)
dose = StrongAcidDoseML[1.0, 7.0, 4.0, 1.0];
assert[AssociationQ[dose], "StrongAcidDoseML returns Association"];
expectedMoles = (10.^(-4.) - 10.^(-7.)) * 1.0;
assert[approx[dose["MolesH"], expectedMoles, expectedMoles * 0.05],
  "Strong acid moles H+ match stoichiometry ±5%"];
assert[approx[dose["DoseML"], expectedMoles * 1000., expectedMoles * 50.],
  "Strong acid mL matches moles/conc"];

(* Weak acid estimate returns structure *)
wa = WeakAcidDoseEstimate[1.0, 7.0, 5.0, 0.87, 4.76]; (* ~5% vinegar ~0.87 M *)
assert[AssociationQ[wa] && NumericQ[wa["DoseML"]] && wa["DoseML"] > 0,
  "Weak acid dose estimate positive"];

(* Acid catalog *)
assert[Length[AcidCatalog[]] >= 4, "AcidCatalog has ≥4 acids"];

Print["\n=== test_pretreatment: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
