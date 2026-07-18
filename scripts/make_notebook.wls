#!/usr/bin/env wolframscript
(* Create HOCl_QA_Suite.nb — proper ExpressionCell (not string BoxData) for macOS FE *)
root = DirectoryName[DirectoryName[$InputFileName]];
nbPath = FileNameJoin[{root, "HOCl_QA_Suite.nb"}];

(* Actual expression - NOT a string - so BoxData stores real code *)
initExpr = Hold[
  Module[{root, src, res, dash},
    root = Quiet[Check[NotebookDirectory[], ""]];
    If[!StringQ[root] || root === "",
      root = Quiet[Check[DirectoryName[NotebookFileName[]], Directory[]]]
    ];
    src = FileNameJoin[{root, "src"}];
    $Path = DeleteDuplicates[Prepend[$Path, src]];
    Global`$HOClLoadErrors = {};
    Do[
      res = Quiet[Check[Get[FileNameJoin[{src, f}]]; True, False]];
      If[!TrueQ[res], AppendTo[Global`$HOClLoadErrors, f]],
      {f, {
        "HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl",
        "ShelfLife.wl", "Byproducts.wl", "Formulations.wl",
        "UIComponents.wl", "HOClNotebookUI.wl"
      }}
    ];
    Quiet[HOClNotebookUI`HOClLoadAll[root]];
    dash = If[
      ListQ[Global`$HOClLoadErrors] && Length[Global`$HOClLoadErrors] > 0,
      Framed[
        Style[
          "Package load problem: " <> StringRiffle[Global`$HOClLoadErrors, ", "] <>
          ". Ensure the src/ folder sits next to this notebook.",
          FontFamily -> "Arial", FontSize -> 13, FontColor -> Red,
          ShowStringCharacters -> False
        ],
        Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 12
      ],
      HOClNotebookUI`HOClDashboard[]
    ];
    Style[dash, FormatType -> StandardForm, ShowStringCharacters -> False]
  ]
];

status = Quiet[Check[
  UsingFrontEnd[
    nbObj = CreateDocument[{
      TextCell["TG Labs / 50MM - HOCl QA & R&D Suite", "Title",
        FontFamily -> "Arial", FontColor -> RGBColor[0.12, 0.35, 0.55]],
      TextCell[
        "Self-contained HOCl QA Bench + R&D Engine. " <>
        "If the dashboard does not appear: Evaluation > Evaluate Initialization Cells, " <>
        "and enable dynamics if prompted. Full Mathematica on macOS. No internet or paclets.",
        "Text", FontFamily -> "Arial"],
      ExpressionCell[
        Unevaluated @@ initExpr,
        "Input",
        InitializationCell -> True,
        CellOpen -> False, (* hide code; still auto-runs as init *)
        FontSize -> 10
      ],
      TextCell[
        "Tip: If you need to re-run, choose Evaluation > Evaluate Initialization Cells. " <>
        "Documentation: docs/README.md | Chemistry: docs/CHEMISTRY_NOTES.md | Assumptions: docs/ASSUMPTIONS.md",
        "Text", FontFamily -> "Arial", FontSize -> 11]
    },
      WindowTitle -> "HOCl QA & R&D Suite - TG Labs / 50MM",
      WindowSize -> {1040, 820},
      StyleDefinitions -> "Default.nb",
      ShowStringCharacters -> False,
      FormatType -> StandardForm
    ];
    (* Ensure notebook option: never show string quotes on output *)
    SetOptions[nbObj,
      ShowStringCharacters -> False,
      FormatType -> StandardForm,
      StyleDefinitions -> "Default.nb"
    ];
    NotebookSave[nbObj, nbPath];
    NotebookClose[nbObj];
    "ok"
  ],
  "fail"
]];

If[status === "ok" && FileExistsQ[nbPath],
  Print["PASS: Notebook written via FrontEnd: ", nbPath, " (", FileByteCount[nbPath], " bytes)"];
  Exit[0]
];

(* Fallback: Export Notebook with ToBoxes of real expression *)
Print["INFO: FrontEnd path failed - using Export fallback"];
nb = Notebook[{
  Cell["TG Labs / 50MM - HOCl QA & R&D Suite", "Title"],
  Cell[
    "Self-contained HOCl QA Bench + R&D Engine. Evaluate initialization cells and enable dynamics.",
    "Text"
  ],
  Cell[BoxData[ToBoxes[Unevaluated @@ initExpr]], "Input",
    InitializationCell -> True, CellOpen -> False],
  Cell[
    "Documentation: docs/README.md | docs/CHEMISTRY_NOTES.md | docs/ASSUMPTIONS.md",
    "Text"
  ]
},
  WindowTitle -> "HOCl QA & R&D Suite - TG Labs / 50MM",
  WindowSize -> {1040, 820},
  ShowStringCharacters -> False,
  FormatType -> StandardForm,
  StyleDefinitions -> "Default.nb"
];

Export[nbPath, nb, "NB"];
If[FileExistsQ[nbPath],
  Print["PASS: Wrote notebook fallback: ", nbPath, " (", FileByteCount[nbPath], " bytes)"];
  Exit[0],
  Print["FAIL: could not write notebook"];
  Exit[1]
];
