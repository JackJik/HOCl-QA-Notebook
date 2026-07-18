#!/usr/bin/env wolframscript
(* Rebuild HOCl_QA_Suite.nb via CreateDocument (known-good path for Mac FE). *)
root = DirectoryName[DirectoryName[$InputFileName]];
nbPath = FileNameJoin[{root, "HOCl_QA_Suite.nb"}];
SetDirectory[root];

boxes = ToBoxes[
  Defer[
    Module[{d},
      d = NotebookDirectory[];
      If[!StringQ[d] || d === "", d = DirectoryName[NotebookFileName[]]];
      Get[FileNameJoin[{d, "src", "LaunchHOCl.wl"}]]
    ]
  ],
  StandardForm
];

status = Quiet[Check[
  UsingFrontEnd[
    nb = CreateDocument[
      {
        TextCell["TG Labs / 50MM - HOCl QA & R&D Suite", "Title",
          FontFamily -> "Arial", FontColor -> RGBColor[0.12, 0.35, 0.55]],
        TextCell[
          "Keep this notebook inside HOCl-QA-Notebook (next to src/). Select the blue cell and press Shift-Enter. Enable Dynamics if asked.",
          "Text", FontFamily -> "Arial"],
        Cell[BoxData[boxes], "Input",
          InitializationCell -> True, CellOpen -> True,
          Background -> RGBColor[0.93, 0.96, 1], FontSize -> 13],
        TextCell[
          "Dashboard appears below this cell after evaluation. Docs: docs/README.md",
          "Text", FontFamily -> "Arial", FontSize -> 11]
      },
      WindowTitle -> "HOCl QA & R&D Suite - TG Labs / 50MM",
      WindowSize -> {1100, 860},
      Visible -> False,
      ShowStringCharacters -> False,
      InitializationCellEvaluation -> True,
      InitializationCellWarning -> False
    ];
    NotebookSave[nb, nbPath];
    NotebookClose[nb];
    "ok"
  ],
  "fail"
]];

If[status =!= "ok", Print["FAIL"]; Exit[1]];
raw = Import[nbPath, "Text"];
Print["bytes ", FileByteCount[nbPath]];
Print["TextCell bug ", StringContainsQ[raw, "TextCell["]];
Print["Unevaluated ", StringContainsQ[raw, "Unevaluated"]];
Print["LaunchHOCl ", StringContainsQ[raw, "LaunchHOCl"]];
Print["cell styles check via Import:"];
nb2 = Import[nbPath];
Print[Length[First[nb2]], " cells: ", #[[2]] & /@ First[nb2]];
If[StringContainsQ[raw, "TextCell["] || StringContainsQ[raw, "Unevaluated"],
  Exit[1]
];
Print["PASS"];
Exit[0];
