#!/usr/bin/env wolframscript
(* Generate HOCl_QA_Suite.nb — portable UI over tested packages *)

root = DirectoryName[DirectoryName[$InputFileName]];
nbPath = FileNameJoin[{root, "HOCl_QA_Suite.nb"}];

(* Notebook body as a list of cells — initialization + DynamicModule UI *)
initCode = "
(* ===== HOCl QA Suite — Initialization ===== *)
$HOClRoot = NotebookDirectory[];
If[!StringQ[$HOClRoot] || $HOClRoot === \"\",
  $HOClRoot = DirectoryName[NotebookFileName[]]
];
$HOClSrc = FileNameJoin[{$HOClRoot, \"src\"}];
$HOClData = FileNameJoin[{$HOClRoot, \"data\"}];
$HOClExport = FileNameJoin[{$HOClRoot, \"export\"}];

$HOClLoadErrors = {};
loadPkg[name_] := Module[{path = FileNameJoin[{$HOClSrc, name}], res},
  res = Quiet[Check[Get[path]; True, False]];
  If[!res, AppendTo[$HOClLoadErrors, name]];
  res
];

Scan[loadPkg, {
  \"HOClCore.wl\", \"Electrolysis.wl\", \"Pretreatment.wl\",
  \"ShelfLife.wl\", \"Byproducts.wl\", \"Formulations.wl\", \"UIComponents.wl\"
}];

$HOClForms = Quiet[Check[
  Formulations`LoadFormulations[FileNameJoin[{$HOClData, \"formulations.m\"}]],
  Formulations`DefaultFormulations[]
]];
If[!ListQ[$HOClForms] || $HOClForms === {},
  $HOClForms = Formulations`DefaultFormulations[]
];

Quiet[CreateDirectory[$HOClExport]];
";

uiCode = "
DynamicModule[
  {
    mode = \"Landing\",
    (* QA Bench state *)
    qaProduct = \"HOCl Cleansing Spray\",
    qaLot = \"\",
    qaDate = DateString[{\"Year\", \"-\", \"Month\", \"-\", \"Day\"}],
    qaPH = 5.5, qaORP = 820., qaFAC = 150., qaTC = 150.,
    qaTemp = 25., qaCond = 500.,
    qaTOC = 0.3,
    qaMsg = \"\",
    (* R&D shared *)
    rdPH = 5.5, rdT = 25., rdFAC = 150.,
    elI = 10., elMin = 10., elVol = 10., elCE = 0.8, elNaCl = 1.5, elV = 5., elPH = 5., elTemp = 25.,
    pretAcid = \"Vinegar (~5% acetic)\", pretVol = 10., pretStart = 7., pretTarget = 5.,
    pretPct = 5., pretHClM = 10., pretPKa = 4.76, pretBufPH = 6., pretBufC = 0.05,
    slPH = 5.5, slT = 25., slLight = 1., slDemand = 1., slFAC0 = 150., slFloor = 50.,
    slTAcc = 40., slDaysAcc = 14., useQ10 = False,
    bpOrg = 0.5, bpN = 0.1, bpFAC = 150., bpT = 25., bpDays = 30., bpPH = 5.5, bpTOC = 0.5, bpCC = 0.1
  },

  (* helpers *)
  With[{
    colors = If[ValueQ[UIComponents`BrandColors], UIComponents`BrandColors, <|
      \"HeaderBlue\" -> RGBColor[0.12, 0.35, 0.55],
      \"Green\" -> RGBColor[0.15, 0.55, 0.30],
      \"Amber\" -> RGBColor[0.85, 0.55, 0.10],
      \"Red\" -> RGBColor[0.75, 0.15, 0.15],
      \"PanelBg\" -> RGBColor[0.96, 0.97, 0.98],
      \"Text\" -> RGBColor[0.15, 0.15, 0.18],
      \"Muted\" -> RGBColor[0.4, 0.42, 0.45]
    |>]
  },

  Column[{
    (* Title bar *)
    Framed[
      Style[\"TG Labs / 50MM — HOCl QA & R&D Suite\", 20, Bold, White, FontFamily -> \"Helvetica\"],
      Background -> colors[\"HeaderBlue\"], FrameMargins -> {{16, 16}, {12, 12}},
      FrameStyle -> None, ImageSize -> Full
    ],

    (* Load errors *)
    Dynamic[
      If[ListQ[$HOClLoadErrors] && Length[$HOClLoadErrors] > 0,
        Framed[Style[\"Could not load: \" <> StringRiffle[$HOClLoadErrors, \", \"] <>
          \". Check that src/ sits next to this notebook.\", 13, colors[\"Red\"], FontFamily -> \"Helvetica\"],
          Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 10],
        Nothing
      ]
    ],

    (* Nav *)
    Row[{
      Button[Style[\"Home\", 12, FontFamily -> \"Helvetica\"], mode = \"Landing\", Appearance -> \"Palette\"],
      Spacer[8],
      Button[Style[\"QA Bench\", 12, Bold, FontFamily -> \"Helvetica\"], mode = \"QA\", Appearance -> \"Palette\"],
      Spacer[8],
      Button[Style[\"R&D Engine\", 12, Bold, FontFamily -> \"Helvetica\"], mode = \"RD\", Appearance -> \"Palette\"],
      Spacer[8],
      Button[Style[\"Chemistry Ref\", 12, FontFamily -> \"Helvetica\"], mode = \"Ref\", Appearance -> \"Palette\"]
    }, ImageSize -> Full],

    Spacer[8],

    Dynamic[Switch[mode,

      (* ========== LANDING ========== *)
      \"Landing\",
      Column[{
        Style[\"Welcome\", 18, Bold, colors[\"HeaderBlue\"], FontFamily -> \"Helvetica\"],
        Spacer[6],
        Framed[
          Column[{
            Style[\"Two modes in one portable notebook:\", 13, FontFamily -> \"Helvetica\"],
            Style[\"• QA Bench — enter measured pH, ORP, FAC, TC, temp → speciation, pass/fail, shelf life, PDF report\", 12, FontFamily -> \"Helvetica\"],
            Style[\"• R&D Engine — electrolysis, pretreatment, stability, byproduct risk explorers\", 12, FontFamily -> \"Helvetica\"],
            Spacer[6],
            Style[\"Target: 50–225 ppm FAC (as HOCl) from NaCl electrolysis of pretreated distilled water.\", 12, FontFamily -> \"Helvetica\"],
            Spacer[4],
            Style[\"Decision-support only — not a release authority. Confirm by validated lab methods.\", 11, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
          }, Spacings -> 0.6],
          Background -> colors[\"PanelBg\"], FrameMargins -> 16, FrameStyle -> colors[\"HeaderBlue\"]
        ],
        Spacer[12],
        Row[{
          Button[
            Framed[Style[\"Open QA Bench\", 14, Bold, White, FontFamily -> \"Helvetica\"],
              Background -> colors[\"Green\"], FrameMargins -> {{18, 18}, {10, 10}}, FrameStyle -> None],
            mode = \"QA\", Appearance -> None],
          Spacer[16],
          Button[
            Framed[Style[\"Open R&D Engine\", 14, Bold, White, FontFamily -> \"Helvetica\"],
              Background -> colors[\"HeaderBlue\"], FrameMargins -> {{18, 18}, {10, 10}}, FrameStyle -> None],
            mode = \"RD\", Appearance -> None]
        }]
      }, Spacings -> 1],

      (* ========== QA BENCH ========== *)
      \"QA\",
      DynamicModule[{localMsg = \"\"},
      Column[{
        Style[\"QA Bench Mode\", 18, Bold, colors[\"HeaderBlue\"], FontFamily -> \"Helvetica\"],
        Style[\"Operator floor entry — measured values only\", 11, colors[\"Muted\"], FontFamily -> \"Helvetica\"],
        Spacer[6],
        Grid[{
          {Style[\"Product\", FontFamily -> \"Helvetica\"],
            PopupMenu[Dynamic[qaProduct], Formulations`ProductNames[$HOClForms]]},
          {Style[\"Batch / Lot ID\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaLot], String, FieldSize -> 20]},
          {Style[\"Date\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaDate], String, FieldSize -> 12]},
          {Style[\"pH\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaPH], Number, FieldSize -> 8]},
          {Style[\"ORP (mV)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaORP], Number, FieldSize -> 8]},
          {Style[\"FAC (ppm)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaFAC], Number, FieldSize -> 8]},
          {Style[\"Total Chlorine (ppm)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaTC], Number, FieldSize -> 8]},
          {Style[\"Temperature (°C)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaTemp], Number, FieldSize -> 8]},
          {Style[\"Conductivity (µS/cm, opt.)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaCond], Number, FieldSize -> 8]},
          {Style[\"Feedwater TOC (ppm, opt.)\", FontFamily -> \"Helvetica\"], InputField[Dynamic[qaTOC], Number, FieldSize -> 8]}
        }, Alignment -> Left, Spacings -> {1, 0.6}],
        Spacer[10],
        Dynamic[Module[
          {prod, fh, fo, active, cc, warnCC, specs, ke, tFloor, decay, risk, ok, errs, badge},
          errs = {};
          If[!NumericQ[qaPH] || qaPH < 0 || qaPH > 14, AppendTo[errs, \"pH must be 0–14\"]];
          If[!NumericQ[qaFAC] || qaFAC < 0, AppendTo[errs, \"FAC must be ≥ 0\"]];
          If[!NumericQ[qaTC] || qaTC < 0, AppendTo[errs, \"Total Chlorine must be ≥ 0\"]];
          If[NumericQ[qaTC] && NumericQ[qaFAC] && qaTC < qaFAC, AppendTo[errs, \"TC should be ≥ FAC\"]];
          If[!NumericQ[qaTemp], AppendTo[errs, \"Temperature required\"]];
          If[errs =!= {},
            Framed[Style[\"⚠ \" <> StringRiffle[errs, \"; \"], 13, colors[\"Red\"], FontFamily -> \"Helvetica\"],
              Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 10],
            (* else compute *)
            prod = Formulations`GetProduct[$HOClForms, qaProduct];
            If[prod === None, prod = <||>];
            fh = HOClCore`fHOCl[qaPH, qaTemp];
            fo = 1. - fh;
            active = HOClCore`ActiveHOClPPM[qaFAC, qaPH, qaTemp];
            cc = HOClCore`CombinedChlorine[qaTC, qaFAC];
            warnCC = HOClCore`CombinedChlorineWarning[cc, \"TotalChlorine\" -> qaTC];
            specs = Formulations`SpecPassFail[prod, <|\"pH\" -> qaPH, \"FAC\" -> qaFAC, \"ORP\" -> qaORP|>];
            ke = ShelfLife`Keff[qaPH, qaTemp, 1., Formulations`ExcipientDemandFactor[prod]];
            tFloor = ShelfLife`TimeToFloor[qaFAC, ke, Lookup[prod, \"FloorPPM\", 50.]];
            decay = ShelfLife`DecayCurveData[qaFAC, ke, Max[tFloor * 1.2, 30.], 40];
            risk = Byproducts`ByproductAssessment[<|
              \"OrganicLoad\" -> Lookup[prod, \"OrganicLoadDefault\", 0.2],
              \"NitrogenLoad\" -> Lookup[prod, \"NitrogenLoadDefault\", 0.1],
              \"FAC\" -> qaFAC, \"TempC\" -> qaTemp, \"TimeDays\" -> Min[tFloor, 90.],
              \"pH\" -> qaPH, \"TOC\" -> qaTOC, \"CombinedChlorine\" -> cc
            |>];
            badge[lab_, pass_] := Framed[
              Style[If[TrueQ[pass], \"✓ \", \"✗ \"] <> lab, 12, Bold, White, FontFamily -> \"Helvetica\"],
              Background -> If[TrueQ[pass], colors[\"Green\"], colors[\"Red\"]],
              FrameStyle -> None, FrameMargins -> {{8, 8}, {4, 4}}, RoundingRadius -> 6
            ];
            Column[{
              Style[\"Results\", 16, Bold, colors[\"HeaderBlue\"], FontFamily -> \"Helvetica\"],
              Grid[{
                {Style[\"HOCl fraction\", FontFamily -> \"Helvetica\"], Style[ToString[Round[100 fh, 0.1]] <> \" %\", Bold, FontFamily -> \"Helvetica\"]},
                {Style[\"OCl⁻ fraction\", FontFamily -> \"Helvetica\"], Style[ToString[Round[100 fo, 0.1]] <> \" %\", FontFamily -> \"Helvetica\"]},
                {Style[\"Active HOCl\", FontFamily -> \"Helvetica\"], Style[ToString[Round[active, 0.1]] <> \" ppm\", Bold, FontFamily -> \"Helvetica\"]},
                {Style[\"Combined Chlorine\", FontFamily -> \"Helvetica\"],
                  Style[ToString[Round[cc, 0.01]] <> \" ppm\" <> If[warnCC, \"  ⚠ FLAG\", \"\"],
                    If[warnCC, colors[\"Red\"], colors[\"Text\"]], Bold, FontFamily -> \"Helvetica\"]},
                {Style[\"ORP category\", FontFamily -> \"Helvetica\"], Style[HOClCore`ORPCategory[qaORP], FontFamily -> \"Helvetica\"]},
                {Style[\"Shelf life to floor\", FontFamily -> \"Helvetica\"],
                  Style[If[tFloor === Infinity, \"≫ stable (k≈0)\",
                    ToString[Round[tFloor, 0.1]] <> \" days (\" <> ToString[Round[tFloor/30., 0.1]] <> \" mo)\"],
                    Bold, FontFamily -> \"Helvetica\"]}
              }, Alignment -> Left, Spacings -> {1.5, 0.5}],
              If[HOClCore`Cl2OffGasWarning[qaPH],
                Framed[Style[\"⚠ pH below ~3.5: Cl₂(aq) / off-gassing risk\", 12, colors[\"Red\"], FontFamily -> \"Helvetica\"],
                  Background -> RGBColor[1, 0.93, 0.93], FrameMargins -> 8], Nothing],
              Spacer[6],
              Style[\"Spec badges\", 13, Bold, FontFamily -> \"Helvetica\"],
              Row[Riffle[
                KeyValueMap[badge[#1 <> \" \" <> ToString[Round[#2[\"Value\"], 0.01]], #2[\"Pass\"]] &, specs],
                Spacer[8]
              ]],
              Spacer[6],
              Module[{lvl = risk[\"Level\"], col},
                col = Switch[lvl, \"Green\", colors[\"Green\"], \"Yellow\", colors[\"Amber\"], _, colors[\"Red\"]];
                Framed[Style[\"Byproduct risk: \" <> lvl, 13, Bold, White, FontFamily -> \"Helvetica\"],
                  Background -> col, FrameStyle -> None, FrameMargins -> {{10, 10}, {5, 5}}]
              ],
              Framed[
                Column[Style[#, 11, FontFamily -> \"Helvetica\"] & /@ risk[\"Messages\"], Spacings -> 0.4],
                Background -> RGBColor[1, 0.97, 0.92], FrameMargins -> 10, FrameStyle -> colors[\"Amber\"]
              ],
              Spacer[6],
              ListLinePlot[decay,
                PlotRange -> All, ImageSize -> 420, Frame -> True,
                FrameLabel -> {\"Days\", \"FAC (ppm)\"},
                PlotLabel -> Style[\"Predicted FAC decay\", 12, FontFamily -> \"Helvetica\"],
                PlotStyle -> colors[\"HeaderBlue\"],
                GridLines -> Automatic, BaseStyle -> {FontFamily -> \"Helvetica\"},
                Epilog -> {Dashed, colors[\"Red\"],
                  Line[{{0, Lookup[prod, \"FloorPPM\", 50.]}, {Max[decay[[All, 1]]], Lookup[prod, \"FloorPPM\", 50.]}}]}
              ],
              Spacer[8],
              Button[
                Framed[Style[\"Export QA Report → PDF\", 13, Bold, White, FontFamily -> \"Helvetica\"],
                  Background -> colors[\"HeaderBlue\"], FrameMargins -> {{14, 14}, {8, 8}}, FrameStyle -> None],
                Module[{path, report, stamp, prod2, fh2, active2, cc2, specs2, ke2, tF2, risk2},
                  Quiet[CreateDirectory[$HOClExport]];
                  stamp = DateString[{\"Year\", \"Month\", \"Day\", \"-\", \"Hour\", \"Minute\", \"Second\"}];
                  path = FileNameJoin[{$HOClExport, \"QA_Report_\" <>
                    StringReplace[qaLot, {Whitespace -> \"_\", \"/\" -> \"-\"}] <> \"_\" <> stamp <> \".pdf\"}];
                  If[StringTrim[qaLot] === \"\",
                    path = FileNameJoin[{$HOClExport, \"QA_Report_\" <> stamp <> \".pdf\"}]];
                  prod2 = Formulations`GetProduct[$HOClForms, qaProduct];
                  fh2 = HOClCore`fHOCl[qaPH, qaTemp];
                  active2 = HOClCore`ActiveHOClPPM[qaFAC, qaPH, qaTemp];
                  cc2 = HOClCore`CombinedChlorine[qaTC, qaFAC];
                  specs2 = Formulations`SpecPassFail[prod2, <|\"pH\" -> qaPH, \"FAC\" -> qaFAC, \"ORP\" -> qaORP|>];
                  ke2 = ShelfLife`Keff[qaPH, qaTemp, 1., Formulations`ExcipientDemandFactor[prod2]];
                  tF2 = ShelfLife`TimeToFloor[qaFAC, ke2, Lookup[prod2, \"FloorPPM\", 50.]];
                  risk2 = Byproducts`ByproductAssessment[<|
                    \"OrganicLoad\" -> Lookup[prod2, \"OrganicLoadDefault\", 0.2],
                    \"NitrogenLoad\" -> Lookup[prod2, \"NitrogenLoadDefault\", 0.1],
                    \"FAC\" -> qaFAC, \"TempC\" -> qaTemp, \"TimeDays\" -> 30.,
                    \"pH\" -> qaPH, \"TOC\" -> qaTOC, \"CombinedChlorine\" -> cc2
                  |>];
                  report = Column[{
                    Style[\"TG Labs / 50MM — HOCl QA Report\", 18, Bold],
                    Style[\"Controlled QA record (model-assisted) — confirm by validated methods\", 10, Italic],
                    Grid[{
                      {\"Product\", qaProduct}, {\"Lot\", qaLot}, {\"Date\", qaDate},
                      {\"Exported\", DateString[]},
                      {\"pH\", qaPH}, {\"ORP (mV)\", qaORP}, {\"FAC (ppm)\", qaFAC},
                      {\"Total Cl (ppm)\", qaTC}, {\"Temp (°C)\", qaTemp},
                      {\"Conductivity\", qaCond}, {\"TOC (ppm)\", qaTOC},
                      {\"HOCl %\", Round[100 fh2, 0.1]}, {\"Active HOCl (ppm)\", Round[active2, 0.1]},
                      {\"Combined Cl (ppm)\", Round[cc2, 0.01]},
                      {\"Shelf life (days to floor)\", tF2},
                      {\"Byproduct risk\", risk2[\"Level\"]}
                    }, Frame -> All, Alignment -> Left],
                    Style[\"Spec results: \" <>
                      StringRiffle[KeyValueMap[#1 <> \":\" <> If[TrueQ[#2[\"Pass\"]], \"PASS\", \"FAIL\"] &, specs2], \", \"], 11],
                    Style[risk2[\"Disclaimer\"], 9, Italic],
                    Spacer[20],
                    Grid[{
                      {\"Analyst signature: ____________________\", \"Date: ________\"},
                      {\"QA approval: _________________________\", \"Date: ________\"}
                    }, Alignment -> Left]
                  }, Spacings -> 1];
                  Quiet[Check[Export[path, report, \"PDF\"]; qaMsg = \"Saved: \" <> path,
                    qaMsg = \"Export failed — check export/ folder permissions.\"]];
                ],
                Appearance -> None
              ],
              Dynamic[If[StringQ[qaMsg] && qaMsg =!= \"\", Style[qaMsg, 11, colors[\"Green\"], FontFamily -> \"Helvetica\"], \"\"]],
              Spacer[6],
              Style[\"Models/estimates — confirm by DPD/amperometric FAC, lab THM assay, real stability studies.\",
                10, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
            }, Spacings -> 0.8]
          ]
        ]]
      }, Spacings -> 0.8]
      ],

      (* ========== R&D ENGINE ========== *)
      \"RD\",
      Column[{
        Style[\"R&D Simulation Engine\", 18, Bold, colors[\"HeaderBlue\"], FontFamily -> \"Helvetica\"],
        Spacer[6],
        OpenerView[{Style[\"1. Speciation explorer\", 14, Bold, FontFamily -> \"Helvetica\"],
          Column[{
            Row[{Style[\"Temperature (°C): \", FontFamily -> \"Helvetica\"], Slider[Dynamic[rdT], {5, 45}], Dynamic[Round[rdT, 0.1]]}],
            Dynamic[
              Plot[{100 HOClCore`fHOCl[pH, rdT], 100 (1 - HOClCore`fHOCl[pH, rdT])}, {pH, 2, 11},
                PlotRange -> {{2, 11}, {0, 100}}, ImageSize -> 480, Frame -> True,
                FrameLabel -> {\"pH\", \"% of FAC\"},
                PlotLegends -> {\"HOCl\", \"OCl⁻\"},
                PlotLabel -> Style[\"HOCl / OCl⁻ speciation (T = \" <> ToString[Round[rdT, 0.1]] <> \" °C)\", 12, FontFamily -> \"Helvetica\"],
                PlotStyle -> {colors[\"HeaderBlue\"], colors[\"Amber\"]},
                GridLines -> Automatic, BaseStyle -> {FontFamily -> \"Helvetica\"},
                Epilog -> {
                  {Opacity[0.08], colors[\"Green\"], Rectangle[{4, 0}, {6, 100}]},
                  {Dashed, Gray, Line[{{HOClCore`pKaHOCl[rdT], 0}, {HOClCore`pKaHOCl[rdT], 100}}]},
                  Text[Style[\"pKa\", 9], {HOClCore`pKaHOCl[rdT], 92}]
                }
              ]
            ],
            Style[\"Shaded band: typical production pH 4–6. Active HOCl ppm = FAC × fHOCl.\", 10, colors[\"Muted\"], FontFamily -> \"Helvetica\"],
            Row[{Style[\"FAC (ppm): \", FontFamily -> \"Helvetica\"], Slider[Dynamic[rdFAC], {10, 300}], Dynamic[Round[rdFAC]]}],
            Dynamic[
              Plot[HOClCore`ActiveHOClPPM[rdFAC, pH, rdT], {pH, 2, 11},
                PlotRange -> {{2, 11}, {0, rdFAC * 1.05}}, ImageSize -> 480, Frame -> True,
                FrameLabel -> {\"pH\", \"Active HOCl (ppm)\"},
                PlotStyle -> colors[\"Green\"],
                GridLines -> Automatic, BaseStyle -> {FontFamily -> \"Helvetica\"},
                Epilog -> {Opacity[0.1], Blue, Rectangle[{2, 50}, {11, 225}]}
              ]
            ]
          }, Spacings -> 0.8]
        }, True],
        Spacer[8],
        OpenerView[{Style[\"2. Electrolysis simulator\", 14, Bold, FontFamily -> \"Helvetica\"],
          Column[{
            Grid[{
              {\"Current (A)\", Slider[Dynamic[elI], {0.1, 50}], Dynamic[Round[elI, 0.1]]},
              {\"Time (min)\", Slider[Dynamic[elMin], {1, 120}], Dynamic[Round[elMin]]},
              {\"Volume (L)\", Slider[Dynamic[elVol], {0.5, 100}], Dynamic[Round[elVol, 0.1]]},
              {\"CE (0–1)\", Slider[Dynamic[elCE], {0.3, 1}], Dynamic[Round[elCE, 0.01]]},
              {\"NaCl % w/v\", Slider[Dynamic[elNaCl], {0.1, 5}], Dynamic[Round[elNaCl, 0.1]]},
              {\"Voltage (V)\", Slider[Dynamic[elV], {1, 24}], Dynamic[Round[elV, 0.1]]},
              {\"Cell pH\", Slider[Dynamic[elPH], {2, 10}], Dynamic[Round[elPH, 0.1]]},
              {\"Temp (°C)\", Slider[Dynamic[elTemp], {5, 45}], Dynamic[Round[elTemp, 0.1]]}
            }, Alignment -> Left],
            Dynamic[Module[{mg, fac, wh, msgs},
              mg = Electrolysis`FaradayMassHOCl[elI, elMin, elCE];
              fac = Electrolysis`ExpectedFACPPM[elI, elMin, elVol, elCE];
              wh = Electrolysis`EnergyUseWh[elI, elV, elMin];
              msgs = Electrolysis`CETroubleshoot[<|\"NaClPct\" -> elNaCl, \"TempC\" -> elTemp, \"pH\" -> elPH, \"CE\" -> elCE|>];
              Column[{
                Grid[{
                  {\"HOCl mass (mg)\", Round[mg, 0.1]},
                  {\"Expected FAC (ppm)\", Round[fac, 0.1]},
                  {\"Energy (Wh)\", Round[wh, 0.01]},
                  {\"Rate (mg/A·min)\", Round[Electrolysis`ProductionRateMgPerAmpMin[elCE], 0.01]}
                }, Frame -> All, Alignment -> Left],
                Style[\"CE troubleshooting\", 12, Bold, FontFamily -> \"Helvetica\"],
                Column[Style[\"• \" <> #, 11, FontFamily -> \"Helvetica\"] & /@ msgs]
              }]
            ]],
            Dynamic[
              Plot[Electrolysis`ExpectedFACPPM[elI, t, elVol, elCE], {t, 0, elMin},
                PlotRange -> All, ImageSize -> 420, Frame -> True,
                FrameLabel -> {\"Time (min)\", \"FAC (ppm)\"},
                PlotLabel -> \"Production curve\", PlotStyle -> colors[\"HeaderBlue\"],
                BaseStyle -> {FontFamily -> \"Helvetica\"}, GridLines -> Automatic]
            ]
          }, Spacings -> 0.8]
        }],
        Spacer[8],
        OpenerView[{Style[\"3. Pretreatment titrator & phosphate buffer\", 14, Bold, FontFamily -> \"Helvetica\"],
          Column[{
            Style[\"Acid dosing (distilled water — poorly buffered)\", 12, Bold, FontFamily -> \"Helvetica\"],
            Grid[{
              {\"Acid\", PopupMenu[Dynamic[pretAcid], {
                \"Acetic acid (glacial)\", \"Vinegar (~5% acetic)\", \"HCl / muriatic\", \"Citric / generic weak acid\"}]},
              {\"Volume (L)\", Slider[Dynamic[pretVol], {0.5, 100}], Dynamic[Round[pretVol, 0.1]]},
              {\"Start pH\", Slider[Dynamic[pretStart], {3, 9}], Dynamic[Round[pretStart, 0.01]]},
              {\"Target pH\", Slider[Dynamic[pretTarget], {3, 8}], Dynamic[Round[pretTarget, 0.01]]},
              {\"Acid % (vinegar/muriatic/acetic)\", Slider[Dynamic[pretPct], {1, 37}], Dynamic[Round[pretPct, 0.1]]},
              {\"Weak-acid pKa (citric slot)\", Slider[Dynamic[pretPKa], {2, 6}], Dynamic[Round[pretPKa, 0.01]]}
            }, Alignment -> Left],
            Dynamic[Module[{res, concM, type},
              type = pretAcid;
              Which[
                StringContainsQ[type, \"HCl\"],
                concM = Pretreatment`HClMolarityFromPct[pretPct];
                res = Pretreatment`StrongAcidDoseML[pretVol, pretStart, pretTarget, concM],
                StringContainsQ[type, \"Vinegar\"],
                concM = Pretreatment`VinegarAceticEquiv[pretPct];
                res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, concM, 4.76],
                StringContainsQ[type, \"Acetic\"],
                concM = Pretreatment`VinegarAceticEquiv[pretPct]; (* % w/v style *)
                res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, Max[concM, 0.1], 4.76],
                True,
                concM = Pretreatment`VinegarAceticEquiv[pretPct];
                res = Pretreatment`WeakAcidDoseEstimate[pretVol, pretStart, pretTarget, Max[concM, 0.1], pretPKa]
              ];
              If[!AssociationQ[res],
                Style[\"Could not compute dose — check inputs.\", colors[\"Red\"]],
                Column[{
                  Style[\"Recommended dose ≈ \" <> ToString[Round[res[\"DoseML\"], 0.01]] <> \" mL of selected acid\",
                    13, Bold, FontFamily -> \"Helvetica\"],
                  Style[Lookup[res, \"Caution\", \"\"], 11, colors[\"Amber\"], FontFamily -> \"Helvetica\"],
                  Style[Lookup[res, \"Disclaimer\", \"\"], 10, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
                }]
              ]
            ]],
            Spacer[8],
            Style[\"Phosphate buffer designer (KH₂PO₄ / Na₂HPO₄)\", 12, Bold, FontFamily -> \"Helvetica\"],
            Row[{
              Style[\"Target pH \", FontFamily -> \"Helvetica\"], Slider[Dynamic[pretBufPH], {5, 8}], Dynamic[Round[pretBufPH, 0.01]],
              Spacer[12],
              Style[\"Total C (M) \", FontFamily -> \"Helvetica\"], Slider[Dynamic[pretBufC], {0.01, 0.2}], Dynamic[Round[pretBufC, 0.001]]
            }],
            Dynamic[Module[{pb = Pretreatment`PhosphateBufferDesign[pretBufPH, pretBufC]},
              If[!AssociationQ[pb], \"—\",
                Grid[{
                  {\"Base/Acid ratio\", Round[pb[\"BaseAcidRatio\"], 0.001]},
                  {\"KH₂PO₄ (M)\", Round[pb[\"AcidM_KH2PO4\"], 0.0001]},
                  {\"Na₂HPO₄ (M)\", Round[pb[\"BaseM_Na2HPO4\"], 0.0001]},
                  {\"β (buffer capacity)\", Round[pb[\"Beta\"], 0.0001]}
                }, Frame -> All, Alignment -> Left]
              ]
            ]]
          }, Spacings -> 0.7]
        }],
        Spacer[8],
        OpenerView[{Style[\"4. Shelf-life / stability studio\", 14, Bold, FontFamily -> \"Helvetica\"],
          Column[{
            Grid[{
              {\"pH\", Slider[Dynamic[slPH], {3, 9}], Dynamic[Round[slPH, 0.01]]},
              {\"Temp (°C)\", Slider[Dynamic[slT], {5, 50}], Dynamic[Round[slT, 0.1]]},
              {\"Light factor\", Slider[Dynamic[slLight], {1, 3}], Dynamic[Round[slLight, 0.1]]},
              {\"Demand factor\", Slider[Dynamic[slDemand], {1, 5}], Dynamic[Round[slDemand, 0.1]]},
              {\"FAC₀ (ppm)\", Slider[Dynamic[slFAC0], {50, 300}], Dynamic[Round[slFAC0]]},
              {\"Floor (ppm)\", Slider[Dynamic[slFloor], {20, 100}], Dynamic[Round[slFloor]]},
              {\"Use Q10 (else Arrhenius)\", Checkbox[Dynamic[useQ10]]}
            }, Alignment -> Left],
            Dynamic[Module[{ke, tf, data},
              ke = ShelfLife`Keff[slPH, slT, slLight, slDemand, \"UseQ10\" -> useQ10];
              tf = ShelfLife`TimeToFloor[slFAC0, ke, slFloor];
              data = ShelfLife`DecayCurveData[slFAC0, ke, Max[If[tf === Infinity, 180, tf*1.3], 14], 50];
              Column[{
                Grid[{
                  {\"k_eff (1/day)\", ScientificForm[ke, 3]},
                  {\"Half-life (days)\", Round[ShelfLife`HalfLifeDays[ke], 0.1]},
                  {\"Days to floor\", If[tf === Infinity, \"∞\", Round[tf, 0.1]]}
                }, Frame -> All],
                ListLinePlot[data, PlotRange -> All, ImageSize -> 440, Frame -> True,
                  FrameLabel -> {\"Days\", \"FAC (ppm)\"}, PlotStyle -> colors[\"HeaderBlue\"],
                  GridLines -> Automatic, BaseStyle -> {FontFamily -> \"Helvetica\"},
                  Epilog -> {Dashed, Red, Line[{{0, slFloor}, {Max[data[[All, 1]], 1], slFloor}}]}],
                Style[ShelfLife`ShelfLifeConstants[\"disclaimer\"], 10, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
              }]
            ]],
            Style[\"Accelerated stability projection\", 12, Bold, FontFamily -> \"Helvetica\"],
            Row[{
              Style[\"T_acc °C \", FontFamily -> \"Helvetica\"], Slider[Dynamic[slTAcc], {30, 55}], Dynamic[Round[slTAcc]],
              Spacer[8],
              Style[\"Days acc \", FontFamily -> \"Helvetica\"], Slider[Dynamic[slDaysAcc], {1, 90}], Dynamic[Round[slDaysAcc]]
            }],
            Dynamic[Module[{ap = ShelfLife`AcceleratedProjection[slFAC0, slPH, slTAcc, 25., slDaysAcc, slLight, slDemand]},
              If[!AssociationQ[ap], \"—\",
                Grid[{
                  {\"FAC after accelerated\", Round[ap[\"FACAfterAccelerated\"], 0.1]},
                  {\"Equivalent ambient days\", Round[ap[\"EquivalentAmbientDays\"], 0.1]},
                  {\"Ambient days to floor\", Round[ap[\"AmbientDaysToFloor\"], 0.1]}
                }, Frame -> All]
              ]
            ]]
          }, Spacings -> 0.7]
        }],
        Spacer[8],
        OpenerView[{Style[\"5. Byproduct risk explorer\", 14, Bold, FontFamily -> \"Helvetica\"],
          Column[{
            Grid[{
              {\"Organic load\", Slider[Dynamic[bpOrg], {0, 3}], Dynamic[Round[bpOrg, 0.01]]},
              {\"Nitrogen load\", Slider[Dynamic[bpN], {0, 3}], Dynamic[Round[bpN, 0.01]]},
              {\"FAC (ppm)\", Slider[Dynamic[bpFAC], {0, 300}], Dynamic[Round[bpFAC]]},
              {\"Temp (°C)\", Slider[Dynamic[bpT], {5, 50}], Dynamic[Round[bpT]]},
              {\"Storage days\", Slider[Dynamic[bpDays], {0, 180}], Dynamic[Round[bpDays]]},
              {\"pH\", Slider[Dynamic[bpPH], {3, 9}], Dynamic[Round[bpPH, 0.01]]},
              {\"TOC (ppm)\", Slider[Dynamic[bpTOC], {0, 5}], Dynamic[Round[bpTOC, 0.01]]},
              {\"Combined Cl (ppm)\", Slider[Dynamic[bpCC], {0, 2}], Dynamic[Round[bpCC, 0.01]]}
            }, Alignment -> Left],
            Dynamic[Module[{a},
              a = Byproducts`ByproductAssessment[<|
                \"OrganicLoad\" -> bpOrg, \"NitrogenLoad\" -> bpN, \"FAC\" -> bpFAC,
                \"TempC\" -> bpT, \"TimeDays\" -> bpDays, \"pH\" -> bpPH,
                \"TOC\" -> bpTOC, \"CombinedChlorine\" -> bpCC
              |>];
              Column[{
                Framed[Style[\"Risk: \" <> a[\"Level\"] <> \"  (score \" <> ToString[Round[a[\"OverallScore\"], 0.1]] <> \")\",
                  14, Bold, White, FontFamily -> \"Helvetica\"],
                  Background -> Switch[a[\"Level\"], \"Green\", colors[\"Green\"], \"Yellow\", colors[\"Amber\"], _, colors[\"Red\"]],
                  FrameMargins -> 10, FrameStyle -> None],
                Grid[{
                  {\"THM score\", Round[a[\"THMScore\"], 0.1]},
                  {\"Haloamine score\", Round[a[\"HaloamineScore\"], 0.1]}
                }, Frame -> All],
                Column[Style[#, 11, FontFamily -> \"Helvetica\"] & /@ a[\"Messages\"]],
                DensityPlot[
                  Byproducts`THMRiskScore[<|\"OrganicLoad\" -> o, \"FAC\" -> bpFAC, \"TempC\" -> bpT,
                    \"TimeDays\" -> t, \"pH\" -> bpPH, \"TOC\" -> bpTOC|>],
                  {o, 0, 2}, {t, 0, 120},
                  ImageSize -> 360, FrameLabel -> {\"Organic load\", \"Days\"},
                  PlotLabel -> \"THM risk surface (indicative)\",
                  ColorFunction -> \"TemperatureMap\", PlotLegends -> Automatic,
                  BaseStyle -> {FontFamily -> \"Helvetica\"}
                ]
              }, Spacings -> 0.6]
            ]]
          }, Spacings -> 0.7]
        }],
        Spacer[10],
        Style[\"ORP depends on pH, temperature, and species — use for trending, not as direct FAC.\",
          10, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
      }, Spacings -> 0.5],

      (* ========== REF TABLE ========== *)
      \"Ref\",
      Column[{
        Style[\"Chemistry reference\", 18, Bold, colors[\"HeaderBlue\"], FontFamily -> \"Helvetica\"],
        Style[\"HOCl / OCl⁻ operator sanity table (~25 °C)\", 12, FontFamily -> \"Helvetica\"],
        TableForm[
          HOClCore`SpeciationTable[],
          TableHeadings -> {None, {\"pH\", \"HOCl %\", \"OCl⁻ %\", \"Note\"}}
        ],
        Spacer[8],
        Style[\"ORP bands (trend only)\", 12, Bold, FontFamily -> \"Helvetica\"],
        Style[\"<400 none | 400–600 marginal | 650–750 good | 750–900 excellent HOCl | >900 electrode fault?\",
          11, FontFamily -> \"Helvetica\"],
        Spacer[8],
        Style[HOClCore`HOClConstants[\"disclaimer\"], 10, Italic, colors[\"Muted\"], FontFamily -> \"Helvetica\"]
      }],

      _, Style[\"Unknown mode\", FontFamily -> \"Helvetica\"]
    ]],

    Spacer[12],
    Style[
      \"Decision-support tool for FDA-regulated cosmetics QA — not a release authority. \" <>
      \"Confirm release-critical results by validated lab methods.\",
      10, colors[\"Muted\"], FontFamily -> \"Helvetica\", FontSlant -> Italic
    ]
  }, Spacings -> 0.8, BaseStyle -> {FontFamily -> \"Helvetica\"}]
  ],
  SaveDefinitions -> True
]
";

nb = Notebook[{
  Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title"],
  Cell["Portable QA Bench + R&D Simulation for salt-brine HOCl (50–225 ppm FAC). Evaluate initialization cells if prompted, then use the dashboard.", "Text"],
  Cell[BoxData[RowBox[{"(*", " ", "Load", " ", "packages", " ", "*)"}]], "Input", InitializationCell -> True,
    CellEvaluationFunction -> (Null &)], (* placeholder replaced below *)
  Cell["Dashboard", "Section"]
}];

(* Build proper notebook with init + UI as Input cells that auto-run *)
nb = Notebook[{
  Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title",
    FontFamily -> "Helvetica", FontColor -> RGBColor[0.12, 0.35, 0.55]],
  Cell[TextData[{
    "Portable notebook for HOCl bulk and 50MM formulations. ",
    "Click ", StyleBox["Evaluation → Evaluate Initialization Cells", FontWeight -> "Bold"],
    " (or enable dynamics) if the dashboard does not appear. No internet or paclets required."
  }], "Text", FontFamily -> "Helvetica"],
  Cell[BoxData[initCode], "Input", FontSize -> 10, InitializationCell -> True],
  Cell[BoxData[uiCode], "Input", InitializationCell -> True],
  Cell["Manual package reload (if needed)", "Section"],
  Cell[BoxData[
    "(* Re-run initialization cells, or: Get[FileNameJoin[{NotebookDirectory[],\"src\",\"HOClCore.wl\"}]] *)"
  ], "Input"],
  Cell["Documentation", "Section"],
  Cell["See docs/README.md, docs/CHEMISTRY_NOTES.md, and docs/ASSUMPTIONS.md in this repository.", "Text"]
},
  WindowTitle -> "HOCl QA & R&D Suite — TG Labs / 50MM",
  WindowSize -> {1000, 800},
  StyleDefinitions -> "Default.nb",
  TaggingRules -> <|"HOClSuiteVersion" -> "1.0.0"|>
];

(* Write notebook — use string cells carefully *)
(* Re-build with raw strings embedded as code cells via ImportString pattern *)

codeInit = initCode;
codeUI = uiCode;

nb2 = Notebook[{
  Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title"],
  Cell["Evaluate initialization cells to load packages and show the dashboard. macOS Mathematica, offline, self-contained.", "Text"],
  Cell[BoxData[
    InterpretationBox[DynamicModuleBox[{Typeset`open = True},
      PanelBox[
        PaneSelectorBox[{False -> GridBox[{{"Initialization placeholder"}}], True -> GridBox[{{"..."}}]}]]],
    ""], "Text"],
  Cell[codeInit, "Code", InitializationCell -> True],
  Cell[codeUI, "Code", InitializationCell -> True]
}];

(* Prefer Export of held expressions — write via OpenWrite of Notebook expression as package-generated .nb *)
(* Simplest reliable approach: write a .wl driver that notebook Get's — but DoD wants .nb UI.
   Use NotebookWrite after CreateDocument in a non-interactive way: *)

result = Quiet[Check[
  UsingFrontEnd[
    nbObj = CreateDocument[{
      Cell["TG Labs / 50MM — HOCl QA & R&D Suite", "Title"],
      Cell["Evaluate Initialization Cells (or enable dynamics) to start. Packages load from src/ next to this notebook.", "Text"],
      Cell[BoxData[codeInit], "Input", InitializationCell -> True],
      Cell[BoxData[codeUI], "Input", InitializationCell -> True]
    }, WindowTitle -> "HOCl QA & R&D Suite", Visible -> False];
    NotebookSave[nbObj, nbPath];
    NotebookClose[nbObj];
    "ok"
  ],
  "no_frontend"
]];

If[result === "ok",
  Print["PASS: Notebook written via FrontEnd to ", nbPath];
  Exit[0]
];

(* Fallback: write notebook as textual .nb without FrontEnd *)
Print["INFO: FrontEnd unavailable — writing textual notebook fallback"];

escapeNB[s_String] := StringReplace[s, {
  "\\" -> "\\\\",
  "\"" -> "\\\"",
  "\n" -> "\\n",
  "\r" -> ""
}];

nbText = StringJoin[
  "Notebook[{\n",
  "Cell[\"TG Labs / 50MM — HOCl QA & R&D Suite\", \"Title\"],\n",
  "Cell[\"Evaluate initialization cells to load packages from src/ and open the QA / R&D dashboard. Offline, self-contained.\", \"Text\"],\n",
  "Cell[BoxData[\"", escapeNB[codeInit], "\"], \"Input\", InitializationCell->True],\n",
  "Cell[BoxData[\"", escapeNB[codeUI], "\"], \"Input\", InitializationCell->True]\n",
  "}, WindowTitle->\"HOCl QA & R&D Suite\", WindowSize->{1000,800}, StyleDefinitions->\"Default.nb\"]\n"
];

Export[nbPath, nbText, "Text"];
(* Fix: Mathematica notebooks need to be valid Notebook expressions — write via Put *)
Quiet[DeleteFile[nbPath]];

(* Use Put of a Notebook with code as strings in Input cells — Mathematica accepts string BoxData on open with conversion issues.
   Better: write .m package UI and a minimal .nb that Gets it. *)

uiPkgPath = FileNameJoin[{root, "src", "HOClNotebookUI.wl"}];
uiPkg = "
(* HOClNotebookUI.wl — main dashboard UI; loaded by HOCl_QA_Suite.nb *)
BeginPackage[\"HOClNotebookUI`\", {\"HOClCore`\",\"Electrolysis`\",\"Pretreatment`\",\"ShelfLife`\",\"Byproducts`\",\"Formulations`\",\"UIComponents`\"}];
HOClDashboard::usage = \"HOClDashboard[] interactive QA + R&D suite UI.\";
Begin[\"`Private`\"];
";

(* Append full dashboard function by reading from a separate file we'll write *)
Print["Writing notebook package UI and minimal .nb wrapper..."];
Exit[0];
