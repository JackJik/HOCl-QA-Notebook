(* ::Package:: *)
(* LaunchHOCl.wl — single entry point for HOCl_QA_Suite.nb
   Keep notebook cells trivial: Get[FileNameJoin[{NotebookDirectory[], "src", "LaunchHOCl.wl"}]]
   All strings live here so notebook export cannot strip quotes. *)

HOClLaunch[] := Module[
  {rootDir, src, res, errs = {}, dash, f, files},

  rootDir = Quiet[Check[NotebookDirectory[], ""]];
  If[!StringQ[rootDir] || rootDir === "",
    rootDir = Quiet[Check[DirectoryName[NotebookFileName[]], ""]]
  ];
  If[!StringQ[rootDir] || rootDir === "",
    rootDir = Directory[]
  ];

  src = FileNameJoin[{rootDir, "src"}];

  If[!DirectoryQ[src],
    Return[
      Framed[
        Style[
          StringJoin[
            "Cannot find src/ next to this notebook.\n",
            "Looked for: ", src, "\n",
            "Open HOCl_QA_Suite.nb from inside the HOCl-QA-Notebook folder ",
            "(the folder that contains src/, data/, docs/)."
          ],
          FontFamily -> "Arial", FontSize -> 13, FontColor -> Red,
          ShowStringCharacters -> False
        ],
        Background -> RGBColor[1, 0.93, 0.93],
        FrameMargins -> 16
      ]
    ]
  ];

  $Path = DeleteDuplicates[Prepend[$Path, src]];

  files = {
    "HOClCore.wl",
    "Electrolysis.wl",
    "Pretreatment.wl",
    "ShelfLife.wl",
    "Byproducts.wl",
    "Formulations.wl",
    "UIComponents.wl",
    "HOClNotebookUI.wl"
  };

  Do[
    res = Quiet[Check[Get[FileNameJoin[{src, f}]]; True, False]];
    If[!TrueQ[res], AppendTo[errs, f]],
    {f, files}
  ];

  Global`$HOClLoadErrors = errs;

  If[errs =!= {},
    Return[
      Framed[
        Style[
          StringJoin[
            "Package load failed: ", StringRiffle[errs, ", "], "\n",
            "Path used: ", src
          ],
          FontFamily -> "Arial", FontSize -> 13, FontColor -> Red,
          ShowStringCharacters -> False
        ],
        Background -> RGBColor[1, 0.93, 0.93],
        FrameMargins -> 16
      ]
    ]
  ];

  Quiet[HOClNotebookUI`HOClLoadAll[rootDir]];

  dash = HOClNotebookUI`HOClDashboard[];

  Style[dash, FormatType -> StandardForm, ShowStringCharacters -> False]
];

(* Evaluating this file launches the suite *)
HOClLaunch[]
