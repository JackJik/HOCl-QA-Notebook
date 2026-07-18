(* ::Package:: *)
(* UIComponents.wl — Mac-safe styled panels, badges, gauges
   TG Labs / 50MM — HOCl QA & R&D Suite
   Style uses FontSize/FontWeight/FontColor options only (portable on macOS). *)

BeginPackage["UIComponents`"];

BrandColors::usage = "Association of brand colors.";
TitleBar::usage = "TitleBar[] persistent top title.";
StatusBadge::usage = "StatusBadge[label, passQ] green/red chip.";
RiskBadge::usage = "RiskBadge[level] Green/Yellow/Red chip.";
SectionHeader::usage = "SectionHeader[text].";
BodyText::usage = "BodyText[text, opts] styled text (never shows string quotes).";
InfoPanel::usage = "InfoPanel[content].";
WarningPanel::usage = "WarningPanel[text].";
FriendlyError::usage = "FriendlyError[msg].";
GaugeBar::usage = "GaugeBar[value, min, max, label].";
DisclaimerFooter::usage = "DisclaimerFooter[].";
StyledPlotOpts::usage = "Common plot options list.";
MacUIStyle::usage = "MacUIStyle[expr] force StandardForm, no string quotes.";
LabeledGrid::usage = "LabeledGrid[rows, header] styled Grid for tables.";

Begin["`Private`"];

(* Public assignment - keep BrandColors in package context *)
UIComponents`BrandColors = <|
  "HeaderBlue" -> RGBColor[0.12, 0.35, 0.55],
  "PanelBg" -> RGBColor[0.96, 0.97, 0.98],
  "Green" -> RGBColor[0.15, 0.55, 0.30],
  "Amber" -> RGBColor[0.85, 0.55, 0.10],
  "Red" -> RGBColor[0.75, 0.15, 0.15],
  "Text" -> RGBColor[0.15, 0.15, 0.18],
  "Muted" -> RGBColor[0.40, 0.42, 0.45],
  "White" -> GrayLevel[1]
|>;

$Font = "Arial"; (* available on every Mac; Helvetica alias can glitch in some FE builds *)

MacUIStyle[expr_] := Style[expr,
  FormatType -> StandardForm,
  ShowStringCharacters -> False,
  FontFamily -> $Font
];

BodyText[text_String, opts___] := Style[text, FontFamily -> $Font, opts];
BodyText[text_, opts___] := Style[TextString[text], FontFamily -> $Font, opts];

TitleBar[] := Framed[
  Style["TG Labs / 50MM - HOCl QA & R&D Suite",
    FontFamily -> $Font, FontSize -> 20, FontWeight -> Bold,
    FontColor -> BrandColors["White"]],
  Background -> BrandColors["HeaderBlue"],
  FrameMargins -> {{16, 16}, {12, 12}},
  FrameStyle -> None,
  ImageSize -> Full
];

StatusBadge[label_String, passQ_] := Module[{col, mark},
  col = If[TrueQ[passQ], BrandColors["Green"], BrandColors["Red"]];
  mark = If[TrueQ[passQ], "[PASS]", "[FAIL]"];
  Framed[
    Style[mark <> " " <> label,
      FontFamily -> $Font, FontSize -> 12, FontWeight -> Bold,
      FontColor -> BrandColors["White"]],
    Background -> col, FrameStyle -> None,
    FrameMargins -> {{10, 10}, {5, 5}}, RoundingRadius -> 6
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
    Style["Byproduct risk: " <> level,
      FontFamily -> $Font, FontSize -> 13, FontWeight -> Bold,
      FontColor -> BrandColors["White"]],
    Background -> col, FrameStyle -> None,
    FrameMargins -> {{10, 10}, {5, 5}}, RoundingRadius -> 6
  ]
];

SectionHeader[text_String] := Style[text,
  FontFamily -> $Font, FontSize -> 16, FontWeight -> Bold,
  FontColor -> BrandColors["HeaderBlue"]];

InfoPanel[content_] := Framed[
  Style[content, FontFamily -> $Font, FontSize -> 12,
    FontColor -> BrandColors["Text"], ShowStringCharacters -> False],
  Background -> BrandColors["PanelBg"],
  FrameStyle -> BrandColors["HeaderBlue"],
  FrameMargins -> 12,
  RoundingRadius -> 4
];

WarningPanel[text_String] := Framed[
  Style[text, FontFamily -> $Font, FontSize -> 12,
    FontColor -> BrandColors["Text"], ShowStringCharacters -> False],
  Background -> RGBColor[1, 0.95, 0.9],
  FrameStyle -> BrandColors["Amber"],
  FrameMargins -> 12,
  RoundingRadius -> 4
];
WarningPanel[text_] := WarningPanel[TextString[text]];

FriendlyError[msg_String] := Framed[
  Style["WARNING: " <> msg, FontFamily -> $Font, FontSize -> 13,
    FontColor -> BrandColors["Red"], ShowStringCharacters -> False],
  Background -> RGBColor[1, 0.93, 0.93],
  FrameStyle -> BrandColors["Red"],
  FrameMargins -> 10
];
FriendlyError[msg_] := FriendlyError[TextString[msg]];

GaugeBar[value_?NumericQ, min_?NumericQ, max_?NumericQ, label_String: ""] := Module[
  {frac},
  frac = Clip[If[max > min, (value - min)/(max - min), 0.], {0., 1.}];
  Column[{
    Style[label <> ": " <> ToString[Round[value, 0.1], InputForm],
      FontFamily -> $Font, FontSize -> 11, ShowStringCharacters -> False],
    Graphics[{
      {LightGray, Rectangle[{0, 0}, {1, 0.25}]},
      {BrandColors["HeaderBlue"], Rectangle[{0, 0}, {frac, 0.25}]}
    }, ImageSize -> {200, 18}, PlotRange -> {{0, 1}, {0, 0.25}},
      Axes -> False, AspectRatio -> Full]
  }, Spacings -> 0.3]
];

DisclaimerFooter[] := Style[
  "Decision-support tool for FDA-regulated cosmetics QA - not a release authority. " <>
  "Confirm all release-critical results by validated lab methods (DPD/amperometric FAC, lab THM assay, real stability studies).",
  FontFamily -> $Font, FontSize -> 10, FontSlant -> Italic,
  FontColor -> BrandColors["Muted"], ShowStringCharacters -> False
];

StyledPlotOpts = {
  ImageSize -> 420,
  BaseStyle -> {FontFamily -> "Arial", FontSize -> 11},
  Frame -> True,
  FrameStyle -> GrayLevel[0.3],
  GridLines -> Automatic,
  GridLinesStyle -> Directive[GrayLevel[0.85], Dashed],
  LabelStyle -> {FontFamily -> "Arial", FontSize -> 11}
};

(* Grid avoids TableForm InputForm quirks on some Mac FE builds *)
LabeledGrid[rows_List, header_List] := Module[{h, r},
  h = Style[#, FontFamily -> $Font, FontWeight -> Bold, FontSize -> 11,
      ShowStringCharacters -> False] & /@ header;
  r = rows /. {
    n_?NumericQ :> Style[NumberForm[N[n], {5, 2}], FontFamily -> $Font, FontSize -> 11],
    s_String :> Style[s, FontFamily -> $Font, FontSize -> 11, ShowStringCharacters -> False]
  };
  Grid[Prepend[r, h],
    Frame -> All, FrameStyle -> GrayLevel[0.7],
    Background -> {None, {BrandColors["PanelBg"], {White}}},
    Spacings -> {1.2, 0.6}, Alignment -> Left]
];

End[];
EndPackage[];
