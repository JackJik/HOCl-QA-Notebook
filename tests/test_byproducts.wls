#!/usr/bin/env wolframscript
(* test_byproducts.wls *)
$Path = Prepend[$Path, FileNameJoin[{DirectoryName[$InputFileName], "..", "src"}]];
Get["Byproducts.wl"];
Get["Formulations.wl"];

pass = 0; fail = 0;
assert[cond_, label_] := If[TrueQ[cond],
  Print["PASS: ", label]; pass++,
  Print["FAIL: ", label]; fail++
];

(* Low risk green-ish *)
low = ByproductAssessment[<|
  "OrganicLoad" -> 0.05, "NitrogenLoad" -> 0.0, "FAC" -> 50.,
  "TempC" -> 20., "TimeDays" -> 7., "pH" -> 5.0, "TOC" -> 0.2,
  "CombinedChlorine" -> 0.0
|>];
assert[AssociationQ[low], "Assessment returns Association"];
assert[MemberQ[{"Green", "Yellow", "Red"}, low["Level"]], "Level is G/Y/R"];
assert[StringQ[low["Disclaimer"]] && StringContainsQ[low["Disclaimer"], "lab"],
  "Disclaimer mentions lab assay"];

(* High risk red *)
high = ByproductAssessment[<|
  "OrganicLoad" -> 2., "NitrogenLoad" -> 2., "FAC" -> 200.,
  "TempC" -> 40., "TimeDays" -> 120., "pH" -> 8., "TOC" -> 5.,
  "CombinedChlorine" -> 1.5
|>];
assert[high["Level"] === "Red", "High drivers → Red risk"];
assert[high["OverallScore"] > 60, "High score > 60"];

(* Combined chlorine elevates haloamine score *)
h1 = HaloamineRiskScore[<|"NitrogenLoad" -> 0., "CombinedChlorine" -> 0.|>];
h2 = HaloamineRiskScore[<|"NitrogenLoad" -> 0., "CombinedChlorine" -> 1.|>];
assert[h2 > h1, "Higher CC → higher haloamine score"];

(* Formulations load *)
forms = DefaultFormulations[];
assert[Length[forms] >= 2, "≥2 default products (spray + hydrogel)"];
assert[MemberQ[ProductNames[forms], "HOCl Cleansing Spray"], "Spray product present"];
assert[MemberQ[ProductNames[forms], "HOCl Hydrogel"], "Hydrogel product present"];

gel = GetProduct[forms, "HOCl Hydrogel"];
assert[AssociationQ[gel], "GetProduct hydrogel"];
excNames = Lookup[#, "Name"] & /@ gel["Excipients"];
assert[MemberQ[excNames, "Hyaluronic acid"], "HA excipient"];
assert[MemberQ[excNames, "KH2PO4"], "Phosphate buffer"];
assert[MemberQ[excNames, "Laponite"], "Laponite"];

df = ExcipientDemandFactor[gel];
assert[NumericQ[df] && df >= 1., "Demand factor ≥ 1"];

(* Spec pass/fail *)
pf = SpecPassFail[gel, <|"pH" -> 5.5, "FAC" -> 100., "ORP" -> 800.|>];
assert[TrueQ[pf["pH"]["Pass"]], "pH 5.5 passes hydrogel"];
assert[TrueQ[pf["FAC"]["Pass"]], "FAC 100 passes"];

pfFail = SpecPassFail[gel, <|"pH" -> 9.0, "FAC" -> 10.|>];
assert[!TrueQ[pfFail["pH"]["Pass"]], "pH 9 fails"];
assert[!TrueQ[pfFail["FAC"]["Pass"]], "FAC 10 fails"];

Print["\n=== test_byproducts: ", pass, " passed, ", fail, " failed ==="];
If[fail > 0, Exit[1], Exit[0]];
