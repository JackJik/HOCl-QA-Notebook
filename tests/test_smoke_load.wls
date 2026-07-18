#!/usr/bin/env wolframscript
(* test_smoke_load.wls — zero-message load of all packages *)
src = FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}];
$Path = Prepend[$Path, src];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];

files = {"HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl",
  "ShelfLife.wl", "Byproducts.wl", "Formulations.wl", "UIComponents.wl",
  "HOClNotebookUI.wl"};

Do[
  msgs = {};
  result = Quiet[Check[
    Get[FileNameJoin[{src, f}]]; "ok",
    "error",
    {Get::noopen, Syntax::sntxf, Syntax::sntxi, Power::infy, Infinity::indet}
  ], {Get::noopen}];
  (* Capture messages during load *)
  assert[result === "ok", "Load " <> f];
  ,
  {f, files}
];

(* Formulations data file *)
dataPath = FileNameJoin[{DirectoryName[$InputFileName], "..", "data", "formulations.m"}];
data = Quiet[Check[Get[dataPath], $Failed]];
assert[ListQ[data] && Length[data] >= 2, "formulations.m loads as list"];

(* Cross-package call smoke *)
assert[NumericQ[fHOCl[5., 25]], "fHOCl after full load"];
assert[NumericQ[FaradayMassHOCl[1., 1., 1.]], "Faraday after full load"];
assert[NumericQ[Keff[5., 25.]], "Keff after full load"];
assert[AssociationQ[ByproductAssessment[<|"FAC" -> 100., "pH" -> 5.|>]],
  "ByproductAssessment after full load"];

Print["\n=== test_smoke_load: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
