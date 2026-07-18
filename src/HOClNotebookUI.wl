(* ::Package:: *)
(* HOClNotebookUI.wl — QA Bench + R&D Engine dashboard
   TG Labs / 50MM — HOCl QA & R&D Suite *)

BeginPackage["HOClNotebookUI`", {
  "HOClCore`", "Electrolysis`", "Pretreatment`", "ShelfLife`",
  "Byproducts`", "Formulations`", "UIComponents`"
}];

HOClDashboard::usage = "HOClDashboard[] full interactive suite UI.";
HOClLoadAll::usage = "HOClLoadAll[rootDir] load packages and formulations from repo root.";

Begin["`Private`"];

HOClLoadAll[root_String] := Module[{src, data, errs = {}, load},
  src = FileNameJoin[{root, "src"}];
  data = FileNameJoin[{root, "data"}];
  load[name_] := Quiet[Check[Get[FileNameJoin[{src, name}]]; True,
    AppendTo[errs, name]; False]];
  Scan[load, {
    "HOClCore.wl", "Electrolysis.wl", "Pretreatment.wl", "ShelfLife.wl",
    "Byproducts.wl", "Formulations.wl", "UIComponents.wl"
  }];
  (* Global symbols so notebook + dashboard share state *)
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

colors := UIComponents`BrandColors;

badge[lab_, pass_] := Framed[
  Style[If[TrueQ[pass], "✓ ", "✗ "] <> lab, 12, Bold, White, FontFamily -> "Helvetica"],
  Background -> If[TrueQ[pass], colors["Green"], colors["Red"]],
  FrameStyle -> None, FrameMargins -> {{8, 8}, {4, 4}}, RoundingRadius -> 6
];

riskChip[level_] := Framed[
  Style["Byproduct risk: " <> level, 13, Bold, White, FontFamily -> "Helvetica"],
  Background -> Switch[level, "Green", colors["Green"], "Yellow", colors["Amber"], _, colors["Red"]],
  FrameStyle -> None, FrameMargins -> {{10, 10}, {5, 5}}, RoundingRadius -> 6
];

HOClDashboard[] := DynamicModule[
  {
    mode = "Landing",
    qaProduct, qaLot = "", qaDate, qaPH = 5.5, qaORP = 820., qaFAC = 150.,
    qaTC = 150., qaTemp = 25., qaCond = 500., qaTOC = 0.3, qaMsg = "",
    rdT = 25., rdFAC = 150.,
    elI = 10., elMin = 10., elVol = 10., elCE = 0.8, elNaCl = 1.5, elV = 5., elPH = 5., elTemp = 25.,
    pretAcid = "Vinegar (~5% acetic)", pretVol = 10., pretStart = 7., pretTarget = 5.,
    pretPct = 5., pretPKa = 4.76, pretBufPH = 6., pretBufC = 0.05,
    slPH = 5.5, slT = 25., slLight = 1., slDemand = 1., slFAC0 = 150., slFloor = 50.,
    slTAcc = 40., slDaysAcc = 14., useQ10 = False,
    bpOrg = 0.5, bpN = 0.1, bpFAC = 150., bpT = 25., bpDays = 30., bpPH = 5.5, bpTOC = 0.5, bpCC = 0.1
  },
  If[!ListQ[Global`$HOClForms] || Length[Global`$HOClForms] === 0,
    Global`$HOClForms = Formulations`DefaultFormulations[]];
  qaProduct = First[Formulations`ProductNames[Global`$HOClForms]];
  qaDate = DateString[{"Year", "-", "Month", "-", "Day"}];

  Column[{
    UIComponents`TitleBar[],
    Dynamic[
      If[ListQ[Global`$HOClLoadErrors] && Length[Global`$HOClLoadErrors] > 0,
        UIComponents`FriendlyError["Could not load: " <> StringRiffle[Global`$HOClLoadErrors, ", "] <>
          ". Ensure src/ is next to this notebook."],
        Nothing
      ]
    ],
    Row[{
      Button["Home", mode = "Landing", Appearance -> "Palette"], Spacer[6],
      Button["QA Bench", mode = "QA", Appearance -> "Palette"], Spacer[6],
      Button["R&D Engine", mode = "RD", Appearance -> "Palette"], Spacer[6],
      Button["Chemistry Ref", mode = "Ref", Appearance -> "Palette"]
    }],
    Spacer[8],
    Dynamic[Switch[mode,
      "Landing", landingPanel[],
      "QA", qaPanel[],
      "RD", rdPanel[],
      "Ref", refPanel[],
      _, Style["Unknown mode", FontFamily -> "Helvetica"]
    ]],
    Spacer[10],
    UIComponents`DisclaimerFooter[]
  }, Spacings -> 0.7, BaseStyle -> {FontFamily -> "Helvetica"}],

  (* nested helpers close over DynamicModule vars via With/Module in Dynamic *)
  Initialization :> (
    landingPanel[] := Column[{
      UIComponents`SectionHeader["Welcome"],
      UIComponents`InfoPanel[
        Column[{
          "Two modes in one portable notebook:",
          "• QA Bench — measured pH, ORP, FAC, TC, temp → speciation, pass/fail, shelf life, PDF",
          "• R&D Engine — electrolysis, pretreatment, stability, byproduct explorers",
          Spacer[4],
          "Target: 50–225 ppm FAC (as HOCl) from NaCl electrolysis of pretreated distilled water."
        }, Spacings -> 0.5]
      ],
      Spacer[10],
      Row[{
        Button[Framed[Style["Open QA Bench", 14, Bold, White, FontFamily -> "Helvetica"],
            Background -> colors["Green"], FrameMargins -> {{16, 16}, {10, 10}}, FrameStyle -> None],
          mode = "QA", Appearance -> None],
        Spacer[12],
        Button[Framed[Style["Open R&D Engine", 14, Bold, White, FontFamily -> "Helvetica"],
            Background -> colors["HeaderBlue"], FrameMargins -> {{16, 16}, {10, 10}}, FrameStyle -> None],
          mode = "RD", Appearance -> None]
      }]
    }];

    qaPanel[] := Column[{
      UIComponents`SectionHeader["QA Bench Mode"],
      Style["Operator floor entry — measured values", 11, colors["Muted"], FontFamily -> "Helvetica"],
      Grid[{
        {"Product", PopupMenu[Dynamic[qaProduct], Formulations`ProductNames[Global`$HOClForms]]},
        {"Batch / Lot ID", InputField[Dynamic[qaLot], String, FieldSize -> 22]},
        {"Date", InputField[Dynamic[qaDate], String, FieldSize -> 14]},
        {"pH", InputField[Dynamic[qaPH], Number, FieldSize -> 8]},
        {"ORP (mV)", InputField[Dynamic[qaORP], Number, FieldSize -> 8]},
        {"FAC (ppm)", InputField[Dynamic[qaFAC], Number, FieldSize -> 8]},
        {"Total Chlorine (ppm)", InputField[Dynamic[qaTC], Number, FieldSize -> 8]},
        {"Temperature (°C)", InputField[Dynamic[qaTemp], Number, FieldSize -> 8]},
        {"Conductivity (µS/cm, opt.)", InputField[Dynamic[qaCond], Number, FieldSize -> 8]},
        {"Feedwater TOC (ppm, opt.)", InputField[Dynamic[qaTOC], Number, FieldSize -> 8]}
      }, Alignment -> Left, Spacings -> {1, 0.55}],
      Spacer[8],
      Dynamic[qaResults[]],
      Spacer[6],
      Button[
        Framed[Style["Export QA Report → PDF", 13, Bold, White, FontFamily -> "Helvetica"],
          Background -> colors["HeaderBlue"], FrameMargins -> {{12, 12}, {8, 8}}, FrameStyle -> None],
        exportQAReport[], Appearance -> None
      ],
      Dynamic[If[StringQ[qaMsg] && qaMsg =!= "", Style[qaMsg, 11, colors["Green"], FontFamily -> "Helvetica"], ""]]
    }, Spacings -> 0.6];

    qaResults[] := Module[
      {errs = {}, prod, fh, fo, active, cc, warnCC, specs, ke, tFloor, decay, risk},
      If[!NumericQ[qaPH] || qaPH < 0 || qaPH > 14, AppendTo[errs, "pH must be 0–14"]];
      If[!NumericQ[qaFAC] || qaFAC < 0, AppendTo[errs, "FAC must be ≥ 0"]];
      If[!NumericQ[qaTC] || qaTC < 0, AppendTo[errs, "TC must be ≥ 0"]];
      If[NumericQ[qaTC] && NumericQ[qaFAC] && qaTC + 1.*10^-9 < qaFAC, AppendTo[errs, "TC should be ≥ FAC"]];
      If[!NumericQ[qaTemp], AppendTo[errs, "Temperature required"]];
      If[errs =!= {}, Return[UIComponents`FriendlyError[StringRiffle[errs, "; "]]]];
      prod = Formulations`GetProduct[Global`$HOClForms, qaProduct];
      If[prod === None, prod = <||>];
      fh = HOClCore`fHOCl[N[qaPH], N[qaTemp]];
      fo = 1. - fh;
      active = HOClCore`ActiveHOClPPM[N[qaFAC], N[qaPH], N[qaTemp]];
      cc = HOClCore`CombinedChlorine[N[qaTC], N[qaFAC]];
      warnCC = HOClCore`CombinedChlorineWarning[cc, "TotalChlorine" -> N[qaTC]];
      specs = Formulations`SpecPassFail[prod, <|"pH" -> N[qaPH], "FAC" -> N[qaFAC], "ORP" -> N[qaORP]|>];
      ke = ShelfLife`Keff[N[qaPH], N[qaTemp], 1., Formulations`ExcipientDemandFactor[prod]];
      tFloor = ShelfLife`TimeToFloor[N[qaFAC], ke, Lookup[prod, "FloorPPM", 50.]];
      decay = ShelfLife`DecayCurveData[N[qaFAC], ke, Max[If[tFloor === Infinity, 90, tFloor*1.2], 30], 40];
      risk = Byproducts`ByproductAssessment[<|
        "OrganicLoad" -> Lookup[prod, "OrganicLoadDefault", 0.2],
        "NitrogenLoad" -> Lookup[prod, "NitrogenLoadDefault", 0.1],
        "FAC" -> N[qaFAC], "TempC" -> N[qaTemp],
        "TimeDays" -> Min[If[NumericQ[tFloor], tFloor, 90], 90.],
        "pH" -> N[qaPH], "TOC" -> N[qaTOC], "CombinedChlorine" -> cc
      |>];
      Column[{
        UIComponents`SectionHeader["Results"],
        Grid[{
          {"HOCl fraction", Style[ToString[Round[100 fh, 0.1]] <> " %", Bold]},
          {"OCl⁻ fraction", ToString[Round[100 fo, 0.1]] <> " %"},
          {"Active HOCl", Style[ToString[Round[active, 0.1]] <> " ppm", Bold]},
          {"Combined Chlorine", Style[ToString[Round[cc, 0.01]] <> " ppm" <> If[warnCC, "  ⚠ FLAG", ""],
            If[warnCC, colors["Red"], colors["Text"]], Bold]},
          {"ORP category", HOClCore`ORPCategory[N[qaORP]]},
          {"Shelf life to floor", Style[
            If[tFloor === Infinity, "≫ stable (k≈0)",
              ToString[Round[tFloor, 0.1]] <> " days (" <> ToString[Round[tFloor/30., 0.1]] <> " mo)"], Bold]}
        }, Alignment -> Left, Spacings -> {1.2, 0.45}],
        If[HOClCore`Cl2OffGasWarning[N[qaPH]],
          UIComponents`WarningPanel["⚠ pH below ~3.5: Cl₂(aq) / off-gassing risk"], Nothing],
        Style["Spec badges", 13, Bold, FontFamily -> "Helvetica"],
        Row[Riffle[
          KeyValueMap[badge[#1 <> " " <> ToString[Round[#2["Value"], 0.01]], #2["Pass"]] &, specs],
          Spacer[8]]],
        riskChip[risk["Level"]],
        UIComponents`WarningPanel[StringRiffle[risk["Messages"], "\n"]],
        ListLinePlot[decay,
          Sequence @@ UIComponents`StyledPlotOpts,
          FrameLabel -> {"Days", "FAC (ppm)"},
          PlotLabel -> Style["Predicted FAC decay", 12, FontFamily -> "Helvetica"],
          PlotStyle -> colors["HeaderBlue"],
          Epilog -> {Dashed, colors["Red"],
            Line[{{0, Lookup[prod, "FloorPPM", 50.]},
              {Max[decay[[All, 1]], 1], Lookup[prod, "FloorPPM", 50.]}}]}
        ],
        Style["Models/estimates — confirm by validated lab methods.", 10, Italic, colors["Muted"], FontFamily -> "Helvetica"]
      }, Spacings -> 0.7]
    ];

    exportQAReport[] := Module[
      {path, stamp, prod, fh, active, cc, specs, ke, tF, risk, report, lotTag},
      Quiet[CreateDirectory[Global`$HOClExport]];
      stamp = DateString[{"Year", "Month", "Day", "-", "Hour", "Minute", "Second"}];
      lotTag = If[StringTrim[qaLot] === "", "NOLOT",
        StringReplace[qaLot, {WhitespaceCharacter .. -> "_", "/" -> "-"}]];
      path = FileNameJoin[{Global`$HOClExport, "QA_Report_" <> lotTag <> "_" <> stamp <> ".pdf"}];
      prod = Formulations`GetProduct[Global`$HOClForms, qaProduct];
      fh = HOClCore`fHOCl[N[qaPH], N[qaTemp]];
      active = HOClCore`ActiveHOClPPM[N[qaFAC], N[qaPH], N[qaTemp]];
      cc = HOClCore`CombinedChlorine[N[qaTC], N[qaFAC]];
      specs = Formulations`SpecPassFail[prod, <|"pH" -> N[qaPH], "FAC" -> N[qaFAC], "ORP" -> N[qaORP]|>];
      ke = ShelfLife`Keff[N[qaPH], N[qaTemp], 1., Formulations`ExcipientDemandFactor[prod]];
      tF = ShelfLife`TimeToFloor[N[qaFAC], ke, Lookup[prod, "FloorPPM", 50.]];
      risk = Byproducts`ByproductAssessment[<|
        "OrganicLoad" -> Lookup[prod, "OrganicLoadDefault", 0.2],
        "NitrogenLoad" -> Lookup[prod, "NitrogenLoadDefault", 0.1],
        "FAC" -> N[qaFAC], "TempC" -> N[qaTemp], "TimeDays" -> 30.,
        "pH" -> N[qaPH], "TOC" -> N[qaTOC], "CombinedChlorine" -> cc
      |>];
      report = Column[{
        Style["TG Labs / 50MM — HOCl QA Report", 18, Bold],
        Style["Controlled QA record (model-assisted) — confirm by validated methods", 10, Italic],
        Grid[{
          {"Product", qaProduct}, {"Lot", qaLot}, {"Date", qaDate}, {"Exported", DateString[]},
          {"pH", qaPH}, {"ORP (mV)", qaORP}, {"FAC (ppm)", qaFAC}, {"Total Cl (ppm)", qaTC},
          {"Temp (°C)", qaTemp}, {"Conductivity", qaCond}, {"TOC (ppm)", qaTOC},
          {"HOCl %", Round[100 fh, 0.1]}, {"Active HOCl (ppm)", Round[active, 0.1]},
          {"Combined Cl (ppm)", Round[cc, 0.01]},
          {"Shelf life (days to floor)", tF}, {"Byproduct risk", risk["Level"]}
        }, Frame -> All, Alignment -> Left],
        Style["Spec: " <> StringRiffle[
          KeyValueMap[#1 <> ":" <> If[TrueQ[#2["Pass"]], "PASS", "FAIL"] &, specs], ", "], 11],
        Style[risk["Disclaimer"], 9, Italic],
        Spacer[16],
        Grid[{
          {"Analyst signature: ____________________", "Date: ________"},
          {"QA approval: _________________________", "Date: ________"}
        }, Alignment -> Left]
      }, Spacings -> 1];
      Quiet[Check[
        Export[path, report, "PDF"]; qaMsg = "Saved: " <> path,
        qaMsg = "Export failed — check export/ folder permissions."
      ]];
    ];

    rdPanel[] := Column[{
      UIComponents`SectionHeader["R&D Simulation Engine"],
      OpenerView[{Style["1. Speciation explorer", 14, Bold, FontFamily -> "Helvetica"],
        Column[{
          Row[{"Temperature (°C): ", Slider[Dynamic[rdT], {5, 45}, ContinuousAction -> False], Dynamic[Round[rdT, 0.1]]}],
          Dynamic[
            Plot[{100 HOClCore`fHOCl[pH, rdT], 100 (1 - HOClCore`fHOCl[pH, rdT])}, {pH, 2, 11},
              PlotRange -> {{2, 11}, {0, 100}}, Sequence @@ UIComponents`StyledPlotOpts,
              FrameLabel -> {"pH", "% of FAC"}, PlotLegends -> {"HOCl", "OCl⁻"},
              PlotLabel -> Style["Speciation @ " <> ToString[Round[rdT, 0.1]] <> " °C", 12, FontFamily -> "Helvetica"],
              PlotStyle -> {colors["HeaderBlue"], colors["Amber"]},
              Epilog -> {
                {Opacity[0.08], colors["Green"], Rectangle[{4, 0}, {6, 100}]},
                {Dashed, GrayLevel[0.4], Line[{{HOClCore`pKaHOCl[rdT], 0}, {HOClCore`pKaHOCl[rdT], 100}}]},
                Inset[Style["pKa", 9, FontFamily -> "Helvetica"], {HOClCore`pKaHOCl[rdT], 92}]
              }]
          ],
          Row[{"FAC (ppm): ", Slider[Dynamic[rdFAC], {10, 300}, ContinuousAction -> False], Dynamic[Round[rdFAC]]}],
          Dynamic[
            Plot[HOClCore`ActiveHOClPPM[rdFAC, pH, rdT], {pH, 2, 11},
              PlotRange -> {{2, 11}, {0, rdFAC * 1.05}}, Sequence @@ UIComponents`StyledPlotOpts,
              FrameLabel -> {"pH", "Active HOCl (ppm)"}, PlotStyle -> colors["Green"],
              Epilog -> {Opacity[0.12], RGBColor[0.2, 0.4, 0.8], Rectangle[{2, 50}, {11, 225}]}]
          ],
          Style["Shaded: production pH 4–6 / FAC band 50–225 ppm. Active HOCl = FAC × fHOCl.", 10, colors["Muted"], FontFamily -> "Helvetica"]
        }, Spacings -> 0.7]
      }, True],
      Spacer[6],
      OpenerView[{Style["2. Electrolysis simulator", 14, Bold, FontFamily -> "Helvetica"],
        Column[{
          Grid[{
            {"Current (A)", Slider[Dynamic[elI], {0.1, 50}, ContinuousAction -> False], Dynamic[Round[elI, 0.1]]},
            {"Time (min)", Slider[Dynamic[elMin], {1, 120}, ContinuousAction -> False], Dynamic[Round[elMin]]},
            {"Volume (L)", Slider[Dynamic[elVol], {0.5, 100}, ContinuousAction -> False], Dynamic[Round[elVol, 0.1]]},
            {"CE", Slider[Dynamic[elCE], {0.3, 1}, ContinuousAction -> False], Dynamic[Round[elCE, 0.01]]},
            {"NaCl % w/v", Slider[Dynamic[elNaCl], {0.1, 5}, ContinuousAction -> False], Dynamic[Round[elNaCl, 0.1]]},
            {"Voltage (V)", Slider[Dynamic[elV], {1, 24}, ContinuousAction -> False], Dynamic[Round[elV, 0.1]]},
            {"Cell pH", Slider[Dynamic[elPH], {2, 10}, ContinuousAction -> False], Dynamic[Round[elPH, 0.1]]},
            {"Temp (°C)", Slider[Dynamic[elTemp], {5, 45}, ContinuousAction -> False], Dynamic[Round[elTemp, 0.1]]}
          }, Alignment -> Left],
          Dynamic[Module[{mg, fac, wh, msgs},
            mg = Electrolysis`FaradayMassHOCl[elI, elMin, elCE];
            fac = Electrolysis`ExpectedFACPPM[elI, elMin, elVol, elCE];
            wh = Electrolysis`EnergyUseWh[elI, elV, elMin];
            msgs = Electrolysis`CETroubleshoot[<|"NaClPct" -> elNaCl, "TempC" -> elTemp, "pH" -> elPH, "CE" -> elCE|>];
            Column[{
              Grid[{
                {"HOCl mass (mg)", Round[mg, 0.1]},
                {"Expected FAC (ppm)", Round[fac, 0.1]},
                {"Energy (Wh)", Round[wh, 0.01]},
                {"Rate (mg/A·min)", Round[Electrolysis`ProductionRateMgPerAmpMin[elCE], 0.01]}
              }, Frame -> All, Alignment -> Left],
              Style["CE troubleshooting", 12, Bold, FontFamily -> "Helvetica"],
              Column[Style["• " <> #, 11, FontFamily -> "Helvetica"] & /@ msgs],
              Plot[Electrolysis`ExpectedFACPPM[elI, t, elVol, elCE], {t, 0, Max[elMin, 1]},
                Sequence @@ UIComponents`StyledPlotOpts, FrameLabel -> {"Time (min)", "FAC (ppm)"},
                PlotLabel -> "Production curve", PlotStyle -> colors["HeaderBlue"]]
            }, Spacings -> 0.5]
          ]]
        }, Spacings -> 0.6]
      }],
      Spacer[6],
      OpenerView[{Style["3. Pretreatment titrator & phosphate buffer", 14, Bold, FontFamily -> "Helvetica"],
        Column[{
          Grid[{
            {"Acid", PopupMenu[Dynamic[pretAcid], {
              "Acetic acid (glacial)", "Vinegar (~5% acetic)", "HCl / muriatic", "Citric / generic weak acid"}]},
            {"Volume (L)", Slider[Dynamic[pretVol], {0.5, 100}, ContinuousAction -> False], Dynamic[Round[pretVol, 0.1]]},
            {"Start pH", Slider[Dynamic[pretStart], {3, 9}, ContinuousAction -> False], Dynamic[Round[pretStart, 0.01]]},
            {"Target pH", Slider[Dynamic[pretTarget], {3, 8}, ContinuousAction -> False], Dynamic[Round[pretTarget, 0.01]]},
            {"Acid %", Slider[Dynamic[pretPct], {1, 37}, ContinuousAction -> False], Dynamic[Round[pretPct, 0.1]]},
            {"Weak-acid pKa", Slider[Dynamic[pretPKa], {2, 6}, ContinuousAction -> False], Dynamic[Round[pretPKa, 0.01]]}
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
            If[!AssociationQ[res], UIComponents`FriendlyError["Could not compute dose."],
              Column[{
                Style["Recommended dose ≈ " <> ToString[Round[res["DoseML"], 0.01]] <> " mL", 13, Bold, FontFamily -> "Helvetica"],
                UIComponents`WarningPanel[Lookup[res, "Caution", ""]],
                Style[Lookup[res, "Disclaimer", ""], 10, Italic, colors["Muted"], FontFamily -> "Helvetica"]
              }]
            ]
          ]],
          Style["Phosphate buffer designer (gels)", 12, Bold, FontFamily -> "Helvetica"],
          Row[{
            "Target pH ", Slider[Dynamic[pretBufPH], {5, 8}, ContinuousAction -> False], Dynamic[Round[pretBufPH, 0.01]],
            Spacer[10], "Total C (M) ", Slider[Dynamic[pretBufC], {0.01, 0.2}, ContinuousAction -> False], Dynamic[Round[pretBufC, 0.001]]
          }],
          Dynamic[Module[{pb = Pretreatment`PhosphateBufferDesign[pretBufPH, pretBufC]},
            If[!AssociationQ[pb], "—",
              Grid[{
                {"Base/Acid ratio", Round[pb["BaseAcidRatio"], 0.001]},
                {"KH₂PO₄ (M)", Round[pb["AcidM_KH2PO4"], 0.0001]},
                {"Na₂HPO₄ (M)", Round[pb["BaseM_Na2HPO4"], 0.0001]},
                {"β capacity", Round[pb["Beta"], 0.0001]}
              }, Frame -> All, Alignment -> Left]
            ]
          ]]
        }, Spacings -> 0.6]
      }],
      Spacer[6],
      OpenerView[{Style["4. Shelf-life / stability studio", 14, Bold, FontFamily -> "Helvetica"],
        Column[{
          Grid[{
            {"pH", Slider[Dynamic[slPH], {3, 9}, ContinuousAction -> False], Dynamic[Round[slPH, 0.01]]},
            {"Temp (°C)", Slider[Dynamic[slT], {5, 50}, ContinuousAction -> False], Dynamic[Round[slT, 0.1]]},
            {"Light factor", Slider[Dynamic[slLight], {1, 3}, ContinuousAction -> False], Dynamic[Round[slLight, 0.1]]},
            {"Demand factor", Slider[Dynamic[slDemand], {1, 5}, ContinuousAction -> False], Dynamic[Round[slDemand, 0.1]]},
            {"FAC₀ (ppm)", Slider[Dynamic[slFAC0], {50, 300}, ContinuousAction -> False], Dynamic[Round[slFAC0]]},
            {"Floor (ppm)", Slider[Dynamic[slFloor], {20, 100}, ContinuousAction -> False], Dynamic[Round[slFloor]]},
            {"Use Q10 (else Arrhenius)", Checkbox[Dynamic[useQ10]]}
          }, Alignment -> Left],
          Dynamic[Module[{ke, tf, data},
            ke = ShelfLife`Keff[slPH, slT, slLight, slDemand, "UseQ10" -> useQ10];
            tf = ShelfLife`TimeToFloor[slFAC0, ke, slFloor];
            data = ShelfLife`DecayCurveData[slFAC0, ke, Max[If[tf === Infinity, 180, tf*1.3], 14], 50];
            Column[{
              Grid[{
                {"k_eff (1/day)", ScientificForm[ke, 3]},
                {"Half-life (days)", Round[ShelfLife`HalfLifeDays[ke], 0.1]},
                {"Days to floor", If[tf === Infinity, "∞", Round[tf, 0.1]]}
              }, Frame -> All],
              ListLinePlot[data, Sequence @@ UIComponents`StyledPlotOpts,
                FrameLabel -> {"Days", "FAC (ppm)"}, PlotStyle -> colors["HeaderBlue"],
                Epilog -> {Dashed, Red, Line[{{0, slFloor}, {Max[data[[All, 1]], 1], slFloor}}]}],
              Style[ShelfLife`ShelfLifeConstants["disclaimer"], 10, Italic, colors["Muted"], FontFamily -> "Helvetica"]
            }]
          ]],
          Style["Accelerated → ambient projection", 12, Bold, FontFamily -> "Helvetica"],
          Row[{
            "T_acc °C ", Slider[Dynamic[slTAcc], {30, 55}, ContinuousAction -> False], Dynamic[Round[slTAcc]],
            Spacer[8], "Days acc ", Slider[Dynamic[slDaysAcc], {1, 90}, ContinuousAction -> False], Dynamic[Round[slDaysAcc]]
          }],
          Dynamic[Module[{ap = ShelfLife`AcceleratedProjection[slFAC0, slPH, slTAcc, 25., slDaysAcc, slLight, slDemand]},
            If[!AssociationQ[ap], "—",
              Grid[{
                {"FAC after accelerated", Round[ap["FACAfterAccelerated"], 0.1]},
                {"Equivalent ambient days", Round[ap["EquivalentAmbientDays"], 0.1]},
                {"Ambient days to floor", Round[ap["AmbientDaysToFloor"], 0.1]}
              }, Frame -> All]
            ]
          ]]
        }, Spacings -> 0.6]
      }],
      Spacer[6],
      OpenerView[{Style["5. Byproduct risk explorer", 14, Bold, FontFamily -> "Helvetica"],
        Column[{
          Grid[{
            {"Organic load", Slider[Dynamic[bpOrg], {0, 3}, ContinuousAction -> False], Dynamic[Round[bpOrg, 0.01]]},
            {"Nitrogen load", Slider[Dynamic[bpN], {0, 3}, ContinuousAction -> False], Dynamic[Round[bpN, 0.01]]},
            {"FAC (ppm)", Slider[Dynamic[bpFAC], {0, 300}, ContinuousAction -> False], Dynamic[Round[bpFAC]]},
            {"Temp (°C)", Slider[Dynamic[bpT], {5, 50}, ContinuousAction -> False], Dynamic[Round[bpT]]},
            {"Storage days", Slider[Dynamic[bpDays], {0, 180}, ContinuousAction -> False], Dynamic[Round[bpDays]]},
            {"pH", Slider[Dynamic[bpPH], {3, 9}, ContinuousAction -> False], Dynamic[Round[bpPH, 0.01]]},
            {"TOC (ppm)", Slider[Dynamic[bpTOC], {0, 5}, ContinuousAction -> False], Dynamic[Round[bpTOC, 0.01]]},
            {"Combined Cl (ppm)", Slider[Dynamic[bpCC], {0, 2}, ContinuousAction -> False], Dynamic[Round[bpCC, 0.01]]}
          }, Alignment -> Left],
          Dynamic[Module[{a},
            a = Byproducts`ByproductAssessment[<|
              "OrganicLoad" -> bpOrg, "NitrogenLoad" -> bpN, "FAC" -> bpFAC,
              "TempC" -> bpT, "TimeDays" -> bpDays, "pH" -> bpPH,
              "TOC" -> bpTOC, "CombinedChlorine" -> bpCC
            |>];
            Column[{
              Row[{riskChip[a["Level"]], Spacer[8],
                Style["score " <> ToString[Round[a["OverallScore"], 0.1]], 12, FontFamily -> "Helvetica"]}],
              Grid[{
                {"THM score (indicative)", Round[a["THMScore"], 0.1]},
                {"Haloamine score (indicative)", Round[a["HaloamineScore"], 0.1]}
              }, Frame -> All],
              UIComponents`WarningPanel[StringRiffle[a["Messages"], "\n"]],
              DensityPlot[
                Byproducts`THMRiskScore[<|"OrganicLoad" -> o, "FAC" -> bpFAC, "TempC" -> bpT,
                  "TimeDays" -> t, "pH" -> bpPH, "TOC" -> bpTOC|>],
                {o, 0, 2}, {t, 0, 120},
                ImageSize -> 360, FrameLabel -> {"Organic load", "Days"},
                PlotLabel -> "THM risk surface (indicative — not concentration)",
                ColorFunction -> "TemperatureMap", PlotLegends -> Automatic,
                BaseStyle -> {FontFamily -> "Helvetica"}
              ]
            }, Spacings -> 0.5]
          ]]
        }, Spacings -> 0.6]
      }],
      Spacer[8],
      Style["ORP depends on pH, temperature, and species — use for trending and cross-checks, not as a direct FAC measurement.",
        10, Italic, colors["Muted"], FontFamily -> "Helvetica"]
    }, Spacings -> 0.5];

    refPanel[] := Column[{
      UIComponents`SectionHeader["Chemistry reference"],
      Style["HOCl / OCl⁻ operator sanity table (~25 °C)", 12, FontFamily -> "Helvetica"],
      TableForm[HOClCore`SpeciationTable[],
        TableHeadings -> {None, {"pH", "HOCl %", "OCl⁻ %", "Note"}}],
      Spacer[8],
      Style["ORP bands (trend only)", 12, Bold, FontFamily -> "Helvetica"],
      Style["<400 none | 400–600 marginal | 650–750 good | 750–900 excellent HOCl | >900 possible electrode fault",
        11, FontFamily -> "Helvetica"],
      Spacer[6],
      Style[HOClCore`HOClConstants["disclaimer"], 10, Italic, colors["Muted"], FontFamily -> "Helvetica"]
    }];
  )
];

End[];
EndPackage[];
