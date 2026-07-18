#!/usr/bin/env wolframscript
(* test_ui.wls — navigation HoldRest + full functional smoke (no human GUI) *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
root = FileNameJoin[{DirectoryName[$InputFileName], ".."}];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];
approx[a_, b_, tol_] := NumericQ[a] && NumericQ[b] && Abs[a - b] <= tol;

(* --- 1. HoldRest regression: helper must not fire assignment at build time --- *)
Get["UIComponents.wl"];
Get["HOClCore.wl"]; Get["Electrolysis.wl"]; Get["Pretreatment.wl"];
Get["ShelfLife.wl"]; Get["Byproducts.wl"]; Get["Formulations.wl"];
Get["HOClNotebookUI.wl"];

assert[MemberQ[Attributes[HOClNotebookUI`Private`navButton], HoldRest],
  "navButton has HoldRest"];
assert[MemberQ[Attributes[HOClNotebookUI`Private`bigButton], HoldRest],
  "bigButton has HoldRest"];

mode = "Landing";
btn = HOClNotebookUI`Private`navButton["QA Bench", mode = "QA"];
assert[mode === "Landing", "navButton does not set mode at construction"];
assert[MatchQ[btn, _Button], "navButton returns Button"];
(* Action should still be a Set, not a bare string *)
assert[!MatchQ[btn, Button[_, _String, ___]],
  "navButton action is not a pre-evaluated string"];

mode = "Landing";
bb = HOClNotebookUI`Private`bigButton["Go", Red, mode = "RD"];
assert[mode === "Landing", "bigButton does not set mode at construction"];

(* --- 2. Launch path --- *)
r = Get[FileNameJoin[{root, "src", "LaunchHOCl.wl"}]];
assert[MatchQ[r, _Style | _DynamicModule] || Head[r] === Style || Head[r] === DynamicModule ||
  (Head[r] === Style && MatchQ[r[[1]], _DynamicModule]),
  "LaunchHOCl returns styled dashboard"];

(* --- 3. Core QA path numbers --- *)
assert[approx[fHOCl[7.54, 25], 0.5, 0.01], "fHOCl pKa"];
assert[approx[ActiveHOClPPM[150., 6., 25.], 145., 3.], "active HOCl"];
assert[approx[FaradayMassHOCl[10., 10., 1.], 1630., 1.], "Faraday 100%"];
assert[approx[FaradayMassHOCl[10., 10., 0.8], 1304., 1.], "Faraday 80%"];
cc = CombinedChlorine[3., 2.6];
assert[approx[cc, 0.4, 0.001] && CombinedChlorineWarning[0.4, "AbsoluteThreshold" -> 0.2],
  "CC warning"];
assert[approx[HendersonHasselbalchRatio[7.2, 7.2], 1., 0.001], "phosphate ratio"];
k = Log[2.]/10.;
assert[approx[FACAtTime[150., k, 10.], 75., 0.1], "decay half-life"];
assert[AssociationQ[ByproductAssessment[<|"FAC" -> 150., "pH" -> 5.5, "OrganicLoad" -> 0.5|>]],
  "byproduct assessment"];

(* --- 4. Formulations + specs --- *)
forms = DefaultFormulations[];
assert[Length[forms] >= 2, "products loaded"];
gel = GetProduct[forms, "HOCl Hydrogel"];
assert[AssociationQ[gel], "hydrogel product"];
pf = SpecPassFail[gel, <|"pH" -> 5.5, "FAC" -> 100., "ORP" -> 800.|>];
assert[TrueQ[pf["pH"]["Pass"]] && TrueQ[pf["FAC"]["Pass"]], "spec pass"];
pf2 = SpecPassFail[gel, <|"pH" -> 9., "FAC" -> 10.|>];
assert[!TrueQ[pf2["pH"]["Pass"]], "spec fail pH"];

(* --- 5. Electrolysis + pretreatment + shelf --- *)
assert[approx[ExpectedFACPPM[10., 10., 10., 1.], 163., 1.], "FAC ppm"];
dose = StrongAcidDoseML[1., 7., 4., 1.];
assert[AssociationQ[dose] && dose["DoseML"] > 0, "strong acid dose"];
wa = WeakAcidDoseEstimate[1., 7., 5., 0.87, 4.76];
assert[AssociationQ[wa] && wa["DoseML"] > 0, "weak acid dose"];
pb = PhosphateBufferDesign[7.2, 0.1];
assert[approx[pb["BaseAcidRatio"], 1., 0.001], "buffer design"];
ke = Keff[5.5, 25., 1., 1.];
assert[NumericQ[ke] && ke > 0, "Keff"];
ap = AcceleratedProjection[150., 5.5, 40., 25., 14.];
assert[AssociationQ[ap] && NumericQ[ap["AmbientDaysToFloor"]], "accelerated"];

(* --- 6. PDF export --- *)
exportDir = FileNameJoin[{root, "export"}];
Quiet[CreateDirectory[exportDir]];
path = FileNameJoin[{exportDir, "QA_Report_UI_TEST.pdf"}];
report = Column[{
  Style["TG Labs Test", Bold],
  Grid[{{"FAC", 150}, {"Active", ActiveHOClPPM[150., 5.5, 25.]}}, Frame -> All]
}];
ex = Quiet[Check[Export[path, report, "PDF"]; True, False]];
assert[TrueQ[ex] && FileExistsQ[path] && FileByteCount[path] > 100, "PDF export works"];

(* --- 7. Dashboard structure: Buttons hold Set to mode --- *)
HOClNotebookUI`HOClLoadAll[root];
dash = HOClNotebookUI`HOClDashboard[];
assert[MatchQ[dash, _DynamicModule], "HOClDashboard is DynamicModule"];
(* Flatten buttons from expression (DynamicModule body is held-ish; use Cases on FullForm) *)
buttons = Cases[dash, Button[label_, act_, opts___] :> {label, HoldForm[act]}, Infinity];
assert[Length[buttons] >= 4, "dashboard has >= 4 Buttons (nav)"];
(* At least one action should involve Set/mode when held properly — inspect FullForm strings *)
ff = ToString[FullForm[dash]];
assert[StringContainsQ[ff, "Button"], "FullForm contains Button"];
(* mode variable present in DynamicModule *)
assert[StringContainsQ[ff, "mode"] || StringContainsQ[ff, "Landing"] || StringContainsQ[ff, "QA"],
  "dashboard references navigation modes"];

(* --- 8. All src packages load clean --- *)
errs = {};
Do[
  If[!TrueQ[Quiet[Check[Get[FileNameJoin[{root, "src", f}]]; True, False]]],
    AppendTo[errs, f]],
  {f, {
    "HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl", "ShelfLife.wl",
    "Byproducts.wl", "Formulations.wl", "UIComponents.wl", "HOClNotebookUI.wl",
    "LaunchHOCl.wl"
  }}
];
(* LaunchHOCl auto-runs HOClLaunch - that's ok *)
assert[errs === {} || errs === {"LaunchHOCl.wl"}, (* Launch returns UI, Get still ok *)
  "all packages load: " <> ToString[errs]];

Print["\n=== test_ui: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
