#!/usr/bin/env wolframscript
(* Create HOCl_QA_Suite.nb — VISIBLE init + dashboard (macOS)
   Do NOT use CellOpen->False: hidden init cells often never run on open,
   leaving only title/text and a blank notebook. *)

root = DirectoryName[DirectoryName[$InputFileName]];
nbPath = FileNameJoin[{root, "HOCl_QA_Suite.nb"}];

(* Load + launch expression — real WL code, not a string *)
bootExpr = Hold[
  Module[{rootDir, src, res, errs},
    rootDir = Quiet[Check[NotebookDirectory[], ""]];
    If[!StringQ[rootDir] || rootDir === "",
      rootDir = Quiet[Check[DirectoryName[NotebookFileName[]], Directory[]]]
    ];
    src = FileNameJoin[{rootDir, "src"}];
    If[!DirectoryQ[src],
      Return[
        Framed[
          Style[
            "Cannot find src/ next to this notebook.\nExpected: " <>
            ToString[src, InputForm] <>
            "\nClone/open the full HOCl-QA-Notebook folder, not a lone .nb file.",
            FontFamily -> "Arial", FontSize -> 13, FontColor -> Red,
            ShowStringCharacters -> False
          ],
          Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 16
        ]
      ]
    ];
    $Path = DeleteDuplicates[Prepend[$Path, src]];
    errs = {};
    Do[
      res = Quiet[Check[Get[FileNameJoin[{src, f}]]; True, False]];
      If[!TrueQ[res], AppendTo[errs, f]],
      {f, {
        "HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl",
        "ShelfLife.wl", "Byproducts.wl", "Formulations.wl",
        "UIComponents.wl", "HOClNotebookUI.wl"
      }}
    ];
    Global`$HOClLoadErrors = errs;
    If[errs =!= {},
      Return[
        Framed[
          Style[
            "Package load failed: " <> StringRiffle[errs, ", "] <>
            "\nPath used: " <> src,
            FontFamily -> "Arial", FontSize -> 13, FontColor -> Red,
            ShowStringCharacters -> False
          ],
          Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 16
        ]
      ]
    ];
    Quiet[HOClNotebookUI`HOClLoadAll[rootDir]];
    Style[
      HOClNotebookUI`HOClDashboard[],
      FormatType -> StandardForm,
      ShowStringCharacters -> False
    ]
  ]
];

status = Quiet[Check[
  UsingFrontEnd[
    nbObj = CreateDocument[{
      TextCell["TG Labs / 50MM - HOCl QA & R&D Suite", "Title",
        FontFamily -> "Arial",
        FontColor -> RGBColor[0.12, 0.35, 0.55]],
      TextCell[
        "Click anywhere in the code cell below and press Shift+Enter " <>
        "(or: Evaluation > Evaluate Initialization Cells). " <>
        "Enable Dynamics if Mathematica asks. Requires the full repo folder (src/ next to this .nb).",
        "Text", FontFamily -> "Arial"],
      (* VISIBLE initialization cell — must stay open so users can run it *)
      ExpressionCell[
        Unevaluated @@ bootExpr,
        "Input",
        InitializationCell -> True,
        CellOpen -> True,
        FontSize -> 10,
        Background -> RGBColor[0.96, 0.97, 0.99]
      ],
      TextCell[
        "After evaluation, the QA Bench / R&D dashboard appears as output under the code cell. " <>
        "Docs: docs/README.md | docs/CHEMISTRY_NOTES.md | docs/ASSUMPTIONS.md",
        "Text", FontFamily -> "Arial", FontSize -> 11]
    },
      WindowTitle -> "HOCl QA & R&D Suite - TG Labs / 50MM",
      WindowSize -> {1100, 860},
      StyleDefinitions -> "Default.nb",
      ShowStringCharacters -> False,
      FormatType -> StandardForm,
      (* Auto-evaluate init cells when notebook is opened *)
      NotebookEventActions -> {
        "WindowClose" :> Null
      }
    ];
    SetOptions[nbObj,
      ShowStringCharacters -> False,
      FormatType -> StandardForm,
      InitializationCellEvaluation -> True,
      InitializationCellWarning -> False
    ];
    NotebookSave[nbObj, nbPath];
    NotebookClose[nbObj];
    "ok"
  ],
  "fail"
]];

If[status === "ok" && FileExistsQ[nbPath],
  Print["PASS: Notebook written: ", nbPath, " (", FileByteCount[nbPath], " bytes)"];
  Exit[0]
];

Print["INFO: FrontEnd failed — Export fallback"];
nb = Notebook[{
  Cell["TG Labs / 50MM - HOCl QA & R&D Suite", "Title"],
  Cell[
    "Press Shift+Enter on the next cell (or Evaluation > Evaluate Initialization Cells).",
    "Text"
  ],
  Cell[BoxData[ToBoxes[Unevaluated @@ bootExpr]], "Input",
    InitializationCell -> True, CellOpen -> True],
  Cell[
    "Docs: docs/README.md | docs/CHEMISTRY_NOTES.md | docs/ASSUMPTIONS.md",
    "Text"
  ]
},
  WindowTitle -> "HOCl QA & R&D Suite - TG Labs / 50MM",
  WindowSize -> {1100, 860},
  ShowStringCharacters -> False,
  FormatType -> StandardForm,
  InitializationCellEvaluation -> True,
  InitializationCellWarning -> False,
  StyleDefinitions -> "Default.nb"
];
Export[nbPath, nb, "NB"];
If[FileExistsQ[nbPath],
  Print["PASS: fallback notebook: ", nbPath, " (", FileByteCount[nbPath], " bytes)"];
  Exit[0],
  Print["FAIL"]; Exit[1]
];
