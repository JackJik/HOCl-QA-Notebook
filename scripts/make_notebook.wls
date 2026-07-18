#!/usr/bin/env wolframscript
(* Create HOCl_QA_Suite.nb — thin UI wrapper over packages *)
root = DirectoryName[DirectoryName[$InputFileName]];
nbPath = FileNameJoin[{root, "HOCl_QA_Suite.nb"}];

init = "
Module[{root, src, res},
  root = Quiet[Check[NotebookDirectory[], \"\"]];
  If[!StringQ[root] || root === \"\",
    root = Quiet[Check[DirectoryName[NotebookFileName[]], Directory[]]]
  ];
  src = FileNameJoin[{root, \"src\"}];
  $Path = DeleteDuplicates[Prepend[$Path, src]];
  $HOClLoadErrors = {};
  Do[
    res = Quiet[Check[Get[FileNameJoin[{src, f}]]; True, False]];
    If[!TrueQ[res], AppendTo[$HOClLoadErrors, f]],
    {f, {\"HOClCore.wl\", \"Electrolysis.wl\", \"Pretreatment.wl\",
      \"ShelfLife.wl\", \"Byproducts.wl\", \"Formulations.wl\",
      \"UIComponents.wl\", \"HOClNotebookUI.wl\"}}
  ];
  HOClNotebookUI`HOClLoadAll[root];
  If[ListQ[$HOClLoadErrors] && Length[$HOClLoadErrors] > 0,
    Framed[
      Style[\"Package load problem: \" <> StringRiffle[$HOClLoadErrors, \", \"] <>
        \". Ensure the src/ folder sits next to this notebook.\", 13, Red, FontFamily -> \"Helvetica\"],
      Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 12
    ],
    HOClNotebookUI`HOClDashboard[]
  ]
]
";

(* Try FrontEnd first *)
status = Quiet[Check[
  UsingFrontEnd[
    nb = Notebook[{
      Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title"],
      Cell[TextData[{
        "Self-contained HOCl QA Bench + R&D Engine. ",
        "If the dashboard does not appear, choose Evaluation → Evaluate Initialization Cells, ",
        "and click Enable Dynamics if prompted. Requires full Mathematica on macOS. No internet/paclets."
      }], "Text"],
      Cell[BoxData[init], "Input", InitializationCell -> True],
      Cell["Documentation: docs/README.md · Chemistry: docs/CHEMISTRY_NOTES.md · Assumptions: docs/ASSUMPTIONS.md", "Text"]
    },
      WindowTitle -> "HOCl QA & R&D Suite — TG Labs / 50MM",
      WindowSize -> {1024, 800},
      StyleDefinitions -> "Default.nb"
    ];
    Export[nbPath, nb, "NB"];
    "ok"
  ],
  "fail"
]];

If[status === "ok" && FileExistsQ[nbPath],
  Print["PASS: Wrote notebook via Export: ", nbPath];
  Exit[0]
];

(* Fallback without FrontEnd: Export Notebook expression directly *)
nb = Notebook[{
  Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title"],
  Cell["Self-contained HOCl QA Bench + R&D Engine. Evaluate initialization cells and enable dynamics. Full Mathematica on macOS; no internet/paclets.", "Text"],
  Cell[BoxData[init], "Input", InitializationCell -> True],
  Cell["Documentation: docs/README.md · Chemistry: docs/CHEMISTRY_NOTES.md · Assumptions: docs/ASSUMPTIONS.md", "Text"]
},
  WindowTitle -> "HOCl QA & R&D Suite — TG Labs / 50MM",
  WindowSize -> {1024, 800},
  StyleDefinitions -> "Default.nb"
];

Export[nbPath, nb, "NB"];
If[FileExistsQ[nbPath],
  Print["PASS: Wrote notebook (no FrontEnd): ", nbPath, " size=", FileByteCount[nbPath]];
  Exit[0],
  Print["FAIL: could not write notebook"];
  Exit[1]
];
