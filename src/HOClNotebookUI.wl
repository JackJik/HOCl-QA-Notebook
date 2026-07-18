(* ::Package:: *)
(* HOClNotebookUI.wl — QA Bench + R&D Engine dashboard (macOS-safe)
   TG Labs / 50MM — HOCl QA & R&D Suite
   No DynamicModule Initialization helpers (fragile on Mac FE).
   No Nothing in layouts. Style uses Font* options. ShowStringCharacters->False. *)

BeginPackage["HOClNotebookUI`", {
  "HOClCore`", "Electrolysis`", "Pretreatment`", "ShelfLife`",
  "Byproducts`", "Formulations`", "UIComponents`"
}];

HOClDashboard::usage = "HOClDashboard[] full interactive suite UI.";
HOClLoadAll::usage = "HOClLoadAll[rootDir] load packages and formulations from repo root.";

Begin["`Private`"];

$UIFont = "Arial";

HOClLoadAll[root_String] := Module[{src, data, errs = {}, load},
  src = FileNameJoin[{root, "src"}];
  data = FileNameJoin[{root, "data"}];
  load[name_] := Quiet[Check[Get[FileNameJoin[{src, name}]]; True,
    AppendTo[errs, name]; False]];
  Scan[load, {
    "HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl", "ShelfLife.wl",
    "Byproducts.wl", "Formulations.wl", "UIComponents.wl"
  }];
  Global`$HOClRoot = root;
  Global`$HOClExport = FileNameJoin[{root, "export"}];
  Quiet[CreateDirectory[Global`$HOClExport]];
  Global`$HOClForms = Quiet[Check[
    Formulations`LoadFormulations[FileNameJoin[{data, "formulations.m"}]],
    Formulations`DefaultFormulations[]
  ]];
  If[!ListQ[Global`$HOClForms] || Length[Global`$HOClForms] === 0,
    Global`$HOClForms = Formulations`DefaultFormulations[]];
  If[!ValueQ[Global`$HOClLoadErrors] || !ListQ[Global`$HOClLoadErrors],
    Global`$HOClLoadErrors = {}];
  Global`$HOClLoadErrors = DeleteDuplicates[Join[Global`$HOClLoadErrors, errs]];
  <|"Errors" -> Global`$HOClLoadErrors, "Products" -> Length[Global`$HOClForms]|>
];

col[key_String] := UIComponents`BrandColors[key];

txt[s_String, opts___] := Style[s, FontFamily -> $UIFont, ShowStringCharacters -> False, opts];
txt[s_, opts___] := Style[TextString[s], FontFamily -> $UIFont, ShowStringCharacters -> False, opts];

badge[lab_String, passQ_] := Framed[
  txt[If[TrueQ[passQ], "[PASS] ", "[FAIL] "] <> lab,
    FontSize -> 12, FontWeight -> Bold, FontColor -> GrayLevel[1]],
  Background -> If[TrueQ[passQ], col["Green"], col["Red"]],
  FrameStyle -> None, FrameMargins -> {{8, 8}, {4, 4}}, RoundingRadius -> 6
];

riskChip[level_String] := Framed[
  txt["Byproduct risk: " <> level,
    FontSize -> 13, FontWeight -> Bold, FontColor -> GrayLevel[1]],
  Background -> Switch[level,
    "Green", col["Green"], "Yellow", col["Amber"], "Red", col["Red"], _, col["Muted"]],
  FrameStyle -> None, FrameMargins -> {{10, 10}, {5, 5}}, RoundingRadius -> 6
];

(* HoldRest is REQUIRED: without it, `mode = "QA"` runs when the button is
   *built*, so the click action is a no-op string and navigation appears broken. *)
SetAttributes[navButton, HoldRest];
navButton[label_String, action_] := Button[
  txt[label, FontSize -> 12, FontWeight -> Bold],
  action,
  Appearance -> "Palette",
  ImageSize -> {120, 30},
  Method -> "Preemptive"
];

SetAttributes[bigButton, HoldRest];
bigButton[label_String, bg_, action_] := Button[
  Framed[txt[label, FontSize -> 14, FontWeight -> Bold, FontColor -> GrayLevel[1]],
    Background -> bg, FrameMargins -> {{16, 16}, {10, 10}}, FrameStyle -> None,
    RoundingRadius -> 4],
  action,
  Appearance -> None,
  Method -> "Queued"
];

HOClDashboard[] := DynamicModule[
  {
    mode = "Landing",
    qaProduct = "HOCl Cleansing Spray",
    qaLot = "",
    qaDate = DateString[{"Year", "-", "Month", "-", "Day"}],
    qaPH = 5.5, qaORP = 820., qaFAC = 150., qaTC = 150.,
    qaTemp = 25., qaCond = 500., qaTOC = 0.3, qaMsg = "",
    rdT = 25., rdFAC = 150.,
    elI = 10., elMin = 10., elVol = 10., elCE = 0.8, elNaCl = 1.5,
    elV = 5., elPH = 5., elTemp = 25.,
    pretAcid = "Vinegar (~5% acetic)", pretVol = 10., pretStart = 7.,
    pretTarget = 5., pretPct = 5., pretPKa = 4.76, pretBufPH = 6., pretBufC = 0.05,
    slPH = 5.5, slT = 25., slLight = 1., slDemand = 1., slFAC0 = 150., slFloor = 50.,
    slTAcc = 40., slDaysAcc = 14., useQ10 = False,
    bpOrg = 0.5, bpN = 0.1, bpFAC = 150., bpT = 25., bpDays = 30.,
    bpPH = 5.5, bpTOC = 0.5, bpCC = 0.1,
    productNames
  },

  (* init product list once *)
  If[!ListQ[Global`$HOClForms] || Length[Global`$HOClForms] === 0,
    Global`$HOClForms = Formulations`DefaultFormulations[]];
  productNames = Formulations`ProductNames[Global`$HOClForms];
  If[productNames === {}, productNames = {"HOCl Cleansing Spray"}];
  If[!MemberQ[productNames, qaProduct], qaProduct = First[productNames]];

  UIComponents`MacUIStyle @ Column[{
    UIComponents`TitleBar[],

    (* error banner - never use Nothing (shows as text on some Mac FE builds) *)
    Dynamic[
      If[ListQ[Global`$HOClLoadErrors] && Length[Global`$HOClLoadErrors] > 0,
        UIComponents`FriendlyError["Could not load: " <>
          StringRiffle[Global`$HOClLoadErrors, ", "] <>
          ". Ensure the src/ folder sits next to this notebook."],
        ""
      ]
    ],

    (* Inline Button + HoldRest helpers: assignment must stay unevaluated until click *)
    Row[{
      Button[txt["Home", FontSize -> 12, FontWeight -> Bold],
        mode = "Landing", Appearance -> "Palette", ImageSize -> {120, 30}],
      Spacer[8],
      Button[txt["QA Bench", FontSize -> 12, FontWeight -> Bold],
        mode = "QA", Appearance -> "Palette", ImageSize -> {120, 30}],
      Spacer[8],
      Button[txt["R&D Engine", FontSize -> 12, FontWeight -> Bold],
        mode = "RD", Appearance -> "Palette", ImageSize -> {120, 30}],
      Spacer[8],
      Button[txt["Chemistry Ref", FontSize -> 12, FontWeight -> Bold],
        mode = "Ref", Appearance -> "Palette", ImageSize -> {120, 30}]
    }],

    Spacer[10],

    (* ===== MAIN PANEL SWITCH (inline - no Initialization helpers) ===== *)
    Dynamic[
      Switch[mode,

        (* ----- LANDING ----- *)
        "Landing",
        Column[{
          UIComponents`SectionHeader["Welcome"],
          Spacer[6],
          UIComponents`InfoPanel[
            Column[{
              txt["Two modes in one portable notebook:", FontSize -> 13],
              txt["  - QA Bench: enter measured pH, ORP, FAC, TC, temp -> speciation, pass/fail, shelf life, PDF", FontSize -> 12],
              txt["  - R&D Engine: electrolysis, pretreatment, stability, byproduct explorers", FontSize -> 12],
              Spacer[4],
              txt["Target: 50-225 ppm FAC (as HOCl) from NaCl electrolysis of pretreated distilled water.", FontSize -> 12],
              Spacer[4],
              txt["Decision-support only - not a release authority. Confirm by validated lab methods.",
                FontSize -> 11, FontSlant -> Italic, FontColor -> col["Muted"]]
            }, Spacings -> 0.45]
          ],
          Spacer[12],
          Row[{
            bigButton["Open QA Bench", col["Green"], mode = "QA"],
            Spacer[16],
            bigButton["Open R&D Engine", col["HeaderBlue"], mode = "RD"]
          }]
        }, Spacings -> 0.8],

        (* ----- QA BENCH ----- *)
        "QA",
        Column[{
          UIComponents`SectionHeader["QA Bench Mode"],
          txt["Operator floor entry - measured values only", FontSize -> 11, FontColor -> col["Muted"]],
          Spacer[6],
          Grid[{
            {txt["Product"], PopupMenu[Dynamic[qaProduct], productNames]},
            {txt["Batch / Lot ID"], InputField[Dynamic[qaLot], String, FieldSize -> 22]},
            {txt["Date"], InputField[Dynamic[qaDate], String, FieldSize -> 14]},
            {txt["pH"], InputField[Dynamic[qaPH], Number, FieldSize -> 8]},
            {txt["ORP (mV)"], InputField[Dynamic[qaORP], Number, FieldSize -> 8]},
            {txt["FAC (ppm)"], InputField[Dynamic[qaFAC], Number, FieldSize -> 8]},
            {txt["Total Chlorine (ppm)"], InputField[Dynamic[qaTC], Number, FieldSize -> 8]},
            {txt["Temperature (C)"], InputField[Dynamic[qaTemp], Number, FieldSize -> 8]},
            {txt["Conductivity (uS/cm, optional)"], InputField[Dynamic[qaCond], Number, FieldSize -> 8]},
            {txt["Feedwater TOC (ppm, optional)"], InputField[Dynamic[qaTOC], Number, FieldSize -> 8]}
          }, Alignment -> {{Right, Left}, Baseline}, Spacings -> {1.2, 0.55}],
          Spacer[10],
          Dynamic[Module[
            {errs = {}, prod, fh, fo, active, cc, warnCC, specs, ke, tFloor, decay, risk, floorPPM},
            If[!NumericQ[qaPH] || qaPH < 0 || qaPH > 14, AppendTo[errs, "pH must be 0-14"]];
            If[!NumericQ[qaFAC] || qaFAC < 0, AppendTo[errs, "FAC must be >= 0"]];
            If[!NumericQ[qaTC] || qaTC < 0, AppendTo[errs, "TC must be >= 0"]];
            If[NumericQ[qaTC] && NumericQ[qaFAC] && qaTC + 1.*10^-9 < qaFAC,
              AppendTo[errs, "TC should be >= FAC"]];
            If[!NumericQ[qaTemp], AppendTo[errs, "Temperature required"]];
            If[errs =!= {},
              UIComponents`FriendlyError[StringRiffle[errs, "; "]],
              prod = Formulations`GetProduct[Global`$HOClForms, qaProduct];
              If[prod === None, prod = <||>];
              fh = HOClCore`fHOCl[N[qaPH], N[qaTemp]];
              fo = 1. - fh;
              active = HOClCore`ActiveHOClPPM[N[qaFAC], N[qaPH], N[qaTemp]];
              cc = HOClCore`CombinedChlorine[N[qaTC], N[qaFAC]];
              warnCC = HOClCore`CombinedChlorineWarning[cc, "TotalChlorine" -> N[qaTC]];
              specs = Formulations`SpecPassFail[prod,
                <|"pH" -> N[qaPH], "FAC" -> N[qaFAC], "ORP" -> N[qaORP]|>];
              ke = ShelfLife`Keff[N[qaPH], N[qaTemp], 1.,
                Formulations`ExcipientDemandFactor[prod]];
              floorPPM = Lookup[prod, "FloorPPM", 50.];
              tFloor = ShelfLife`TimeToFloor[N[qaFAC], ke, floorPPM];
              decay = ShelfLife`DecayCurveData[N[qaFAC], ke,
                Max[If[tFloor === Infinity, 90., tFloor * 1.2], 30.], 40];
              risk = Byproducts`ByproductAssessment[<|
                "OrganicLoad" -> Lookup[prod, "OrganicLoadDefault", 0.2],
                "NitrogenLoad" -> Lookup[prod, "NitrogenLoadDefault", 0.1],
                "FAC" -> N[qaFAC], "TempC" -> N[qaTemp],
                "TimeDays" -> Min[If[NumericQ[tFloor], tFloor, 90.], 90.],
                "pH" -> N[qaPH], "TOC" -> N[qaTOC], "CombinedChlorine" -> cc
              |>];
              Column[{
                UIComponents`SectionHeader["Results"],
                Grid[{
                  {txt["HOCl fraction"], txt[ToString[NumberForm[100. * fh, {4, 1}]] <> " %", FontWeight -> Bold]},
                  {txt["OCl- fraction"], txt[ToString[NumberForm[100. * fo, {4, 1}]] <> " %"]},
                  {txt["Active HOCl"], txt[ToString[NumberForm[active, {5, 1}]] <> " ppm", FontWeight -> Bold]},
                  {txt["Combined Chlorine"],
                    txt[ToString[NumberForm[cc, {4, 2}]] <> " ppm" <> If[warnCC, "  ** FLAG **", ""],
                      FontWeight -> Bold, FontColor -> If[warnCC, col["Red"], col["Text"]]]},
                  {txt["ORP category"], txt[HOClCore`ORPCategory[N[qaORP]]]},
                  {txt["Shelf life to floor"],
                    txt[If[tFloor === Infinity, "stable (k~0)",
                      ToString[NumberForm[tFloor, {6, 1}]] <> " days (" <>
                      ToString[NumberForm[tFloor/30., {5, 1}]] <> " mo)"], FontWeight -> Bold]}
                }, Alignment -> Left, Spacings -> {1.4, 0.45}],
                If[HOClCore`Cl2OffGasWarning[N[qaPH]],
                  UIComponents`WarningPanel["WARNING: pH below ~3.5 - Cl2(aq) / off-gassing risk"],
                  ""],
                Spacer[4],
                txt["Spec badges", FontSize -> 13, FontWeight -> Bold],
                Row[Riffle[
                  KeyValueMap[
                    badge[#1 <> " " <> ToString[NumberForm[#2["Value"], {5, 2}]], #2["Pass"]] &,
                    specs],
                  Spacer[8]]],
                Spacer[4],
                riskChip[risk["Level"]],
                UIComponents`WarningPanel[StringRiffle[risk["Messages"], " | "]],
                ListLinePlot[decay,
                  Sequence @@ UIComponents`StyledPlotOpts,
                  FrameLabel -> {txt["Days"], txt["FAC (ppm)"]},
                  PlotLabel -> txt["Predicted FAC decay", FontSize -> 12],
                  PlotStyle -> col["HeaderBlue"],
                  Epilog -> {Dashed, col["Red"],
                    Line[{{0, floorPPM}, {Max[decay[[All, 1]], 1], floorPPM}}]}],
                txt["Models/estimates - confirm by validated lab methods.",
                  FontSize -> 10, FontSlant -> Italic, FontColor -> col["Muted"]]
              }, Spacings -> 0.65]
            ]
          ]],
          Spacer[8],
          bigButton["Export QA Report -> PDF", col["HeaderBlue"],
            Module[{path, stamp, prod, fh, active, cc, specs, ke, tF, risk, report, lotTag},
              Quiet[CreateDirectory[Global`$HOClExport]];
              stamp = DateString[{"Year", "Month", "Day", "-", "Hour", "Minute", "Second"}];
              lotTag = If[StringTrim[qaLot] === "", "NOLOT",
                StringReplace[qaLot, {WhitespaceCharacter .. -> "_", "/" -> "-"}]];
              path = FileNameJoin[{Global`$HOClExport,
                "QA_Report_" <> lotTag <> "_" <> stamp <> ".pdf"}];
              prod = Formulations`GetProduct[Global`$HOClForms, qaProduct];
              fh = HOClCore`fHOCl[N[qaPH], N[qaTemp]];
              active = HOClCore`ActiveHOClPPM[N[qaFAC], N[qaPH], N[qaTemp]];
              cc = HOClCore`CombinedChlorine[N[qaTC], N[qaFAC]];
              specs = Formulations`SpecPassFail[prod,
                <|"pH" -> N[qaPH], "FAC" -> N[qaFAC], "ORP" -> N[qaORP]|>];
              ke = ShelfLife`Keff[N[qaPH], N[qaTemp], 1.,
                Formulations`ExcipientDemandFactor[prod]];
              tF = ShelfLife`TimeToFloor[N[qaFAC], ke, Lookup[prod, "FloorPPM", 50.]];
              risk = Byproducts`ByproductAssessment[<|
                "OrganicLoad" -> Lookup[prod, "OrganicLoadDefault", 0.2],
                "NitrogenLoad" -> Lookup[prod, "NitrogenLoadDefault", 0.1],
                "FAC" -> N[qaFAC], "TempC" -> N[qaTemp], "TimeDays" -> 30.,
                "pH" -> N[qaPH], "TOC" -> N[qaTOC], "CombinedChlorine" -> cc
              |>];
              report = Column[{
                Style["TG Labs / 50MM - HOCl QA Report", FontSize -> 18, FontWeight -> Bold],
                Style["Controlled QA record (model-assisted) - confirm by validated methods",
                  FontSize -> 10, FontSlant -> Italic],
                Grid[{
                  {"Product", qaProduct}, {"Lot", qaLot}, {"Date", qaDate},
                  {"Exported", DateString[]},
                  {"pH", qaPH}, {"ORP (mV)", qaORP}, {"FAC (ppm)", qaFAC},
                  {"Total Cl (ppm)", qaTC}, {"Temp (C)", qaTemp},
                  {"Conductivity", qaCond}, {"TOC (ppm)", qaTOC},
                  {"HOCl %", Round[100 fh, 0.1]}, {"Active HOCl (ppm)", Round[active, 0.1]},
                  {"Combined Cl (ppm)", Round[cc, 0.01]},
                  {"Shelf life (days to floor)", tF},
                  {"Byproduct risk", risk["Level"]}
                }, Frame -> All, Alignment -> Left],
                Style["Spec: " <> StringRiffle[
                  KeyValueMap[#1 <> ":" <> If[TrueQ[#2["Pass"]], "PASS", "FAIL"] &, specs],
                  ", "], FontSize -> 11],
                Style[risk["Disclaimer"], FontSize -> 9, FontSlant -> Italic],
                Spacer[16],
                Grid[{
                  {"Analyst signature: ____________________", "Date: ________"},
                  {"QA approval: _________________________", "Date: ________"}
                }, Alignment -> Left]
              }, Spacings -> 1];
              Quiet[Check[
                Export[path, report, "PDF"]; qaMsg = "Saved: " <> path,
                qaMsg = "Export failed - check export/ folder permissions."
              ]];
            ]
          ],
          Dynamic[If[StringQ[qaMsg] && qaMsg =!= "",
            txt[qaMsg, FontSize -> 11, FontColor -> col["Green"]], ""]]
        }, Spacings -> 0.6],

        (* ----- R&D ENGINE ----- *)
        "RD",
        Column[{
          UIComponents`SectionHeader["R&D Simulation Engine"],
          Spacer[6],

          OpenerView[{
            txt["1. Speciation explorer", FontSize -> 14, FontWeight -> Bold],
            Column[{
              Row[{txt["Temperature (C): "],
                Slider[Dynamic[rdT], {5, 45}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[rdT, 0.1]]]]}],
              Dynamic[
                Plot[{100 HOClCore`fHOCl[pH, rdT], 100 (1 - HOClCore`fHOCl[pH, rdT])},
                  {pH, 2, 11},
                  PlotRange -> {{2, 11}, {0, 100}},
                  Sequence @@ UIComponents`StyledPlotOpts,
                  FrameLabel -> {"pH", "% of FAC"},
                  PlotLegends -> {"HOCl", "OCl-"},
                  PlotLabel -> "Speciation @ " <> ToString[Round[rdT, 0.1]] <> " C",
                  PlotStyle -> {col["HeaderBlue"], col["Amber"]},
                  Epilog -> {
                    {Opacity[0.08], col["Green"], Rectangle[{4, 0}, {6, 100}]},
                    {Dashed, GrayLevel[0.4],
                      Line[{{HOClCore`pKaHOCl[rdT], 0}, {HOClCore`pKaHOCl[rdT], 100}}]},
                    Inset[txt["pKa", FontSize -> 9], {HOClCore`pKaHOCl[rdT], 92}]
                  }]
              ],
              Row[{txt["FAC (ppm): "],
                Slider[Dynamic[rdFAC], {10, 300}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[rdFAC]]]]}],
              Dynamic[
                Plot[HOClCore`ActiveHOClPPM[rdFAC, pH, rdT], {pH, 2, 11},
                  PlotRange -> {{2, 11}, {0, rdFAC * 1.05}},
                  Sequence @@ UIComponents`StyledPlotOpts,
                  FrameLabel -> {"pH", "Active HOCl (ppm)"},
                  PlotStyle -> col["Green"],
                  Epilog -> {Opacity[0.12], RGBColor[0.2, 0.4, 0.8],
                    Rectangle[{2, 50}, {11, 225}]}]
              ],
              txt["Shaded: production pH 4-6 / FAC band 50-225 ppm. Active HOCl = FAC x fHOCl.",
                FontSize -> 10, FontColor -> col["Muted"]]
            }, Spacings -> 0.6]
          }, True],

          Spacer[8],
          OpenerView[{
            txt["2. Electrolysis simulator", FontSize -> 14, FontWeight -> Bold],
            Column[{
              Grid[{
                {txt["Current (A)"], Slider[Dynamic[elI], {0.1, 50}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elI, 0.1]]]]},
                {txt["Time (min)"], Slider[Dynamic[elMin], {1, 120}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elMin]]]]},
                {txt["Volume (L)"], Slider[Dynamic[elVol], {0.5, 100}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elVol, 0.1]]]]},
                {txt["CE"], Slider[Dynamic[elCE], {0.3, 1}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elCE, 0.01]]]]},
                {txt["NaCl % w/v"], Slider[Dynamic[elNaCl], {0.1, 5}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elNaCl, 0.1]]]]},
                {txt["Voltage (V)"], Slider[Dynamic[elV], {1, 24}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elV, 0.1]]]]},
                {txt["Cell pH"], Slider[Dynamic[elPH], {2, 10}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elPH, 0.1]]]]},
                {txt["Temp (C)"], Slider[Dynamic[elTemp], {5, 45}, ContinuousAction -> False], Dynamic[txt[ToString[Round[elTemp, 0.1]]]]}
              }, Alignment -> Left],
              Dynamic[Module[{mg, fac, wh, msgs},
                mg = Electrolysis`FaradayMassHOCl[elI, elMin, elCE];
                fac = Electrolysis`ExpectedFACPPM[elI, elMin, elVol, elCE];
                wh = Electrolysis`EnergyUseWh[elI, elV, elMin];
                msgs = Electrolysis`CETroubleshoot[<|
                  "NaClPct" -> elNaCl, "TempC" -> elTemp, "pH" -> elPH, "CE" -> elCE|>];
                Column[{
                  Grid[{
                    {txt["HOCl mass (mg)"], txt[ToString[Round[mg, 0.1]]]},
                    {txt["Expected FAC (ppm)"], txt[ToString[Round[fac, 0.1]]]},
                    {txt["Energy (Wh)"], txt[ToString[Round[wh, 0.01]]]},
                    {txt["Rate (mg/A-min)"],
                      txt[ToString[Round[Electrolysis`ProductionRateMgPerAmpMin[elCE], 0.01]]]}
                  }, Frame -> All, Alignment -> Left],
                  txt["CE troubleshooting", FontSize -> 12, FontWeight -> Bold],
                  Column[txt["- " <> #, FontSize -> 11] & /@ msgs],
                  Plot[Electrolysis`ExpectedFACPPM[elI, t, elVol, elCE],
                    {t, 0, Max[elMin, 1]},
                    Sequence @@ UIComponents`StyledPlotOpts,
                    FrameLabel -> {"Time (min)", "FAC (ppm)"},
                    PlotLabel -> "Production curve",
                    PlotStyle -> col["HeaderBlue"]]
                }, Spacings -> 0.5]
              ]]
            }, Spacings -> 0.55]
          }],

          Spacer[8],
          OpenerView[{
            txt["3. Pretreatment titrator and phosphate buffer", FontSize -> 14, FontWeight -> Bold],
            Column[{
              Grid[{
                {txt["Acid"], PopupMenu[Dynamic[pretAcid], {
                  "Acetic acid (glacial)", "Vinegar (~5% acetic)",
                  "HCl / muriatic", "Citric / generic weak acid"}]},
                {txt["Volume (L)"], Slider[Dynamic[pretVol], {0.5, 100}, ContinuousAction -> False], Dynamic[txt[ToString[Round[pretVol, 0.1]]]]},
                {txt["Start pH"], Slider[Dynamic[pretStart], {3, 9}, ContinuousAction -> False], Dynamic[txt[ToString[Round[pretStart, 0.01]]]]},
                {txt["Target pH"], Slider[Dynamic[pretTarget], {3, 8}, ContinuousAction -> False], Dynamic[txt[ToString[Round[pretTarget, 0.01]]]]},
                {txt["Acid %"], Slider[Dynamic[pretPct], {1, 37}, ContinuousAction -> False], Dynamic[txt[ToString[Round[pretPct, 0.1]]]]},
                {txt["Weak-acid pKa"], Slider[Dynamic[pretPKa], {2, 6}, ContinuousAction -> False], Dynamic[txt[ToString[Round[pretPKa, 0.01]]]]}
              }, Alignment -> Left],
              Dynamic[Module[{res, concM},
                Which[
                  StringContainsQ[pretAcid, "HCl"],
                    concM = Pretreatment`HClMolarityFromPct[pretPct];
                    res = Pretreatment`StrongAcidDoseML[pretVol, pretStart, pretTarget, concM],
                  StringContainsQ[pretAcid, "Vinegar"],
                    concM = Pretreatment`VinegarAceticEquiv[pretPct];
                    res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, Max[concM, 0.01], 4.76],
                  StringContainsQ[pretAcid, "Acetic"],
                    concM = Pretreatment`VinegarAceticEquiv[Min[pretPct, 100]];
                    res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, Max[concM, 0.01], 4.76],
                  True,
                    concM = Pretreatment`VinegarAceticEquiv[pretPct];
                    res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, Max[concM, 0.01], pretPKa]
                ];
                If[!AssociationQ[res],
                  UIComponents`FriendlyError["Could not compute dose."],
                  Column[{
                    txt["Recommended dose ~ " <> ToString[Round[res["DoseML"], 0.01]] <> " mL",
                      FontSize -> 13, FontWeight -> Bold],
                    UIComponents`WarningPanel[Lookup[res, "Caution", ""]],
                    txt[Lookup[res, "Disclaimer", ""], FontSize -> 10, FontSlant -> Italic,
                      FontColor -> col["Muted"]]
                  }]
                ]
              ]],
              txt["Phosphate buffer designer (gels)", FontSize -> 12, FontWeight -> Bold],
              Row[{
                txt["Target pH "],
                Slider[Dynamic[pretBufPH], {5, 8}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[pretBufPH, 0.01]]]],
                Spacer[10],
                txt["Total C (M) "],
                Slider[Dynamic[pretBufC], {0.01, 0.2}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[pretBufC, 0.001]]]]
              }],
              Dynamic[Module[{pb = Pretreatment`PhosphateBufferDesign[pretBufPH, pretBufC]},
                If[!AssociationQ[pb],
                  txt["-"],
                  Grid[{
                    {txt["Base/Acid ratio"], txt[ToString[Round[pb["BaseAcidRatio"], 0.001]]]},
                    {txt["KH2PO4 (M)"], txt[ToString[Round[pb["AcidM_KH2PO4"], 0.0001]]]},
                    {txt["Na2HPO4 (M)"], txt[ToString[Round[pb["BaseM_Na2HPO4"], 0.0001]]]},
                    {txt["Buffer capacity beta"], txt[ToString[Round[pb["Beta"], 0.0001]]]}
                  }, Frame -> All, Alignment -> Left]
                ]
              ]]
            }, Spacings -> 0.55]
          }],

          Spacer[8],
          OpenerView[{
            txt["4. Shelf-life / stability studio", FontSize -> 14, FontWeight -> Bold],
            Column[{
              Grid[{
                {txt["pH"], Slider[Dynamic[slPH], {3, 9}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slPH, 0.01]]]]},
                {txt["Temp (C)"], Slider[Dynamic[slT], {5, 50}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slT, 0.1]]]]},
                {txt["Light factor"], Slider[Dynamic[slLight], {1, 3}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slLight, 0.1]]]]},
                {txt["Demand factor"], Slider[Dynamic[slDemand], {1, 5}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slDemand, 0.1]]]]},
                {txt["FAC0 (ppm)"], Slider[Dynamic[slFAC0], {50, 300}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slFAC0]]]]},
                {txt["Floor (ppm)"], Slider[Dynamic[slFloor], {20, 100}, ContinuousAction -> False], Dynamic[txt[ToString[Round[slFloor]]]]},
                {txt["Use Q10 (else Arrhenius)"], Checkbox[Dynamic[useQ10]]}
              }, Alignment -> Left],
              Dynamic[Module[{ke, tf, data},
                ke = ShelfLife`Keff[slPH, slT, slLight, slDemand, "UseQ10" -> useQ10];
                tf = ShelfLife`TimeToFloor[slFAC0, ke, slFloor];
                data = ShelfLife`DecayCurveData[slFAC0, ke,
                  Max[If[tf === Infinity, 180., tf * 1.3], 14.], 50];
                Column[{
                  Grid[{
                    {txt["k_eff (1/day)"], txt[ToString[ScientificForm[ke, 3]]]},
                    {txt["Half-life (days)"], txt[ToString[Round[ShelfLife`HalfLifeDays[ke], 0.1]]]},
                    {txt["Days to floor"],
                      txt[If[tf === Infinity, "inf", ToString[Round[tf, 0.1]]]]}
                  }, Frame -> All],
                  ListLinePlot[data,
                    Sequence @@ UIComponents`StyledPlotOpts,
                    FrameLabel -> {"Days", "FAC (ppm)"},
                    PlotStyle -> col["HeaderBlue"],
                    Epilog -> {Dashed, Red,
                      Line[{{0, slFloor}, {Max[data[[All, 1]], 1], slFloor}}]}],
                  txt[ShelfLife`ShelfLifeConstants["disclaimer"],
                    FontSize -> 10, FontSlant -> Italic, FontColor -> col["Muted"]]
                }]
              ]],
              txt["Accelerated -> ambient projection", FontSize -> 12, FontWeight -> Bold],
              Row[{
                txt["T_acc C "], Slider[Dynamic[slTAcc], {30, 55}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[slTAcc]]]],
                Spacer[8],
                txt["Days acc "], Slider[Dynamic[slDaysAcc], {1, 90}, ContinuousAction -> False],
                Dynamic[txt[ToString[Round[slDaysAcc]]]]
              }],
              Dynamic[Module[{ap = ShelfLife`AcceleratedProjection[
                  slFAC0, slPH, slTAcc, 25., slDaysAcc, slLight, slDemand]},
                If[!AssociationQ[ap],
                  txt["-"],
                  Grid[{
                    {txt["FAC after accelerated"], txt[ToString[Round[ap["FACAfterAccelerated"], 0.1]]]},
                    {txt["Equivalent ambient days"], txt[ToString[Round[ap["EquivalentAmbientDays"], 0.1]]]},
                    {txt["Ambient days to floor"], txt[ToString[Round[ap["AmbientDaysToFloor"], 0.1]]]}
                  }, Frame -> All]
                ]
              ]]
            }, Spacings -> 0.55]
          }],

          Spacer[8],
          OpenerView[{
            txt["5. Byproduct risk explorer", FontSize -> 14, FontWeight -> Bold],
            Column[{
              Grid[{
                {txt["Organic load"], Slider[Dynamic[bpOrg], {0, 3}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpOrg, 0.01]]]]},
                {txt["Nitrogen load"], Slider[Dynamic[bpN], {0, 3}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpN, 0.01]]]]},
                {txt["FAC (ppm)"], Slider[Dynamic[bpFAC], {0, 300}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpFAC]]]]},
                {txt["Temp (C)"], Slider[Dynamic[bpT], {5, 50}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpT]]]]},
                {txt["Storage days"], Slider[Dynamic[bpDays], {0, 180}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpDays]]]]},
                {txt["pH"], Slider[Dynamic[bpPH], {3, 9}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpPH, 0.01]]]]},
                {txt["TOC (ppm)"], Slider[Dynamic[bpTOC], {0, 5}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpTOC, 0.01]]]]},
                {txt["Combined Cl (ppm)"], Slider[Dynamic[bpCC], {0, 2}, ContinuousAction -> False], Dynamic[txt[ToString[Round[bpCC, 0.01]]]]}
              }, Alignment -> Left],
              Dynamic[Module[{a},
                a = Byproducts`ByproductAssessment[<|
                  "OrganicLoad" -> bpOrg, "NitrogenLoad" -> bpN, "FAC" -> bpFAC,
                  "TempC" -> bpT, "TimeDays" -> bpDays, "pH" -> bpPH,
                  "TOC" -> bpTOC, "CombinedChlorine" -> bpCC
                |>];
                Column[{
                  Row[{
                    riskChip[a["Level"]], Spacer[8],
                    txt["score " <> ToString[Round[a["OverallScore"], 0.1]], FontSize -> 12]
                  }],
                  Grid[{
                    {txt["THM score (indicative)"], txt[ToString[Round[a["THMScore"], 0.1]]]},
                    {txt["Haloamine score (indicative)"], txt[ToString[Round[a["HaloamineScore"], 0.1]]]}
                  }, Frame -> All],
                  UIComponents`WarningPanel[StringRiffle[a["Messages"], " | "]],
                  DensityPlot[
                    Byproducts`THMRiskScore[<|
                      "OrganicLoad" -> o, "FAC" -> bpFAC, "TempC" -> bpT,
                      "TimeDays" -> t, "pH" -> bpPH, "TOC" -> bpTOC|>],
                    {o, 0, 2}, {t, 0, 120},
                    ImageSize -> 360,
                    FrameLabel -> {"Organic load", "Days"},
                    PlotLabel -> "THM risk surface (indicative - not concentration)",
                    ColorFunction -> "TemperatureMap",
                    PlotLegends -> Automatic,
                    BaseStyle -> {FontFamily -> "Arial"}
                  ]
                }, Spacings -> 0.5]
              ]]
            }, Spacings -> 0.55]
          }],

          Spacer[8],
          txt["ORP depends on pH, temperature, and species - use for trending and cross-checks, not as a direct FAC measurement.",
            FontSize -> 10, FontSlant -> Italic, FontColor -> col["Muted"]]
        }, Spacings -> 0.45],

        (* ----- CHEMISTRY REF ----- *)
        "Ref",
        Column[{
          UIComponents`SectionHeader["Chemistry reference"],
          txt["HOCl / OCl- operator sanity table (~25 C)", FontSize -> 12],
          Spacer[4],
          UIComponents`LabeledGrid[
            HOClCore`SpeciationTable[],
            {"pH", "HOCl %", "OCl- %", "Note"}
          ],
          Spacer[10],
          txt["ORP bands (trend only)", FontSize -> 12, FontWeight -> Bold],
          txt["<400 none | 400-600 marginal | 650-750 good | 750-900 excellent HOCl | >900 possible electrode fault",
            FontSize -> 11],
          Spacer[8],
          txt[HOClCore`HOClConstants["disclaimer"],
            FontSize -> 10, FontSlant -> Italic, FontColor -> col["Muted"]]
        }, Spacings -> 0.5],

        (* fallback *)
        _,
        txt["Unknown mode", FontColor -> col["Red"]]
      ],
      TrackedSymbols :> {mode}
    ],

    Spacer[12],
    UIComponents`DisclaimerFooter[]
  }, Spacings -> 0.7]
];

End[];
EndPackage[];
