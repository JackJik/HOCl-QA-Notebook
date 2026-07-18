(* ::Package:: *)
(* UIComponents.wl — reusable styled panels, gauges, badges
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["UIComponents`"];

BrandColors::usage = "Brand color association.";
TitleBar::usage = "TitleBar[] persistent top title.";
StatusBadge::usage = "StatusBadge[label, passQ] green/red chip.";
RiskBadge::usage = "RiskBadge[level] Green/Yellow/Red chip.";
SectionHeader::usage = "SectionHeader[text].";
InfoPanel::usage = "InfoPanel[content].";
WarningPanel::usage = "WarningPanel[text].";
FriendlyError::usage = "FriendlyError[msg].";
GaugeBar::usage = "GaugeBar[value, min, max, label].";
DisclaimerFooter::usage = "DisclaimerFooter[].";
StyledPlotOpts::usage = "Common plot options list.";

Begin["`Private`"];

BrandColors = <|
  "HeaderBlue" -> RGBColor[0.12, 0.35, 0.55],
  "PanelBg" -> RGBColor[0.96, 0.97, 0.98],
  "Green" -> RGBColor[0.15, 0.55, 0.30],
  "Amber" -> RGBColor[0.85, 0.55, 0.10],
  "Red" -> RGBColor[0.75, 0.15, 0.15],
  "Text" -> RGBColor[0.15, 0.15, 0.18],
  "Muted" -> RGBColor[0.4, 0.42, 0.45],
  "White" -> White
|>;

TitleBar[] := Framed[
  Style["TG Labs / 50MM — HOCl QA & R&D Suite", 20, Bold, BrandColors["White"],
    FontFamily -> "Helvetica"],
  Background -> BrandColors["HeaderBlue"],
  FrameMargins -> {{16, 16}, {12, 12}},
  FrameStyle -> None,
  ImageSize -> Full
];

StatusBadge[label_String, passQ_] := Module[{col, mark},
  col = If[TrueQ[passQ], BrandColors["Green"], BrandColors["Red"]];
  mark = If[TrueQ[passQ], "✓", "✗"];
  Framed[
    Style[mark <> " " <> label, 13, Bold, BrandColors["White"], FontFamily -> "Helvetica"],
    Background -> col, FrameStyle -> None, FrameMargins -> {{10, 10}, {5, 5}},
    RoundingRadius -> 6
  ]
];

RiskBadge[level_String] := Module[{col},
  col = Switch[level,
    "Green", BrandColors["Green"],
    "Yellow", BrandColors["Amber"],
    "Red", BrandColors["Red"],
    _, BrandColors["Muted"]
  ];
  Framed[
    Style["Byproduct risk: " <> level, 13, Bold, BrandColors["White"], FontFamily -> "Helvetica"],
    Background -> col, FrameStyle -> None, FrameMargins -> {{10, 10}, {5, 5}},
    RoundingRadius -> 6
  ]
];

SectionHeader[text_String] := Style[text, 16, Bold, BrandColors["HeaderBlue"],
  FontFamily -> "Helvetica"];

InfoPanel[content_] := Framed[
  Style[content, 12, BrandColors["Text"], FontFamily -> "Helvetica"],
  Background -> BrandColors["PanelBg"],
  FrameStyle -> BrandColors["HeaderBlue"],
  FrameMargins -> 12,
  RoundingRadius -> 4
];

WarningPanel[text_String] := Framed[
  Style[text, 12, BrandColors["Text"], FontFamily -> "Helvetica"],
  Background -> RGBColor[1, 0.95, 0.9],
  FrameStyle -> BrandColors["Amber"],
  FrameMargins -> 12,
  RoundingRadius -> 4
];

FriendlyError[msg_String] := Framed[
  Style["⚠ " <> msg, 13, BrandColors["Red"], FontFamily -> "Helvetica"],
  Background -> RGBColor[1, 0.93, 0.93],
  FrameStyle -> BrandColors["Red"],
  FrameMargins -> 10
];

GaugeBar[value_?NumericQ, min_?NumericQ, max_?NumericQ, label_String: ""] := Module[
  {frac},
  frac = Clip[If[max > min, (value - min)/(max - min), 0.], {0., 1.}];
  Column[{
    Style[label <> ": " <> ToString[Round[value, 0.1]], 11, FontFamily -> "Helvetica"],
    Graphics[{
      {LightGray, Rectangle[{0, 0}, {1, 0.25}]},
      {BrandColors["HeaderBlue"], Rectangle[{0, 0}, {frac, 0.25}]}
    }, ImageSize -> {200, 18}, PlotRange -> {{0, 1}, {0, 0.25}},
      Axes -> False, AspectRatio -> Full]
  }, Spacings -> 0.3]
];

DisclaimerFooter[] := Style[
  "Decision-support tool for FDA-regulated cosmetics QA — not a release authority. " <>
  "Confirm all release-critical results by validated lab methods (DPD/amperometric FAC, lab THM assay, real stability studies).",
  10, BrandColors["Muted"], FontFamily -> "Helvetica", FontSlant -> Italic
];

StyledPlotOpts = {
  ImageSize -> 420,
  BaseStyle -> {FontFamily -> "Helvetica", FontSize -> 11},
  Frame -> True,
  FrameStyle -> GrayLevel[0.3],
  GridLines -> Automatic,
  GridLinesStyle -> Directive[GrayLevel[0.85], Dashed],
  PlotTheme -> "Detailed"
};

End[];
EndPackage[];
