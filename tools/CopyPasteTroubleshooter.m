(* Copy-Paste Troubleshooter for Mathematica Code *)
(* This module helps identify and fix common copy-paste issues *)

BeginPackage["CopyPasteTroubleshooter`"]

FixCopyPasteIssues::usage = "FixCopyPasteIssues[code] automatically fixes common copy-paste issues";
DetectEncodingIssues::usage = "DetectEncodingIssues[code] detects encoding-related problems";
NormalizeQuotes::usage = "NormalizeQuotes[code] converts smart quotes to standard quotes";
FixInvisibleSpaces::usage = "FixInvisibleSpaces[code] removes invisible spaces and characters";
ValidateNotebookPaste::usage = "ValidateNotebookPaste[code] validates code pasted from Mathematica notebooks";

Begin["`Private`"]

(* Normalize different types of quotes to standard ASCII quotes *)
NormalizeQuotes[code_String] := Module[{
  normalizedCode = code
},
  (* Replace smart quotes with standard quotes *)
  normalizedCode = StringReplace[normalizedCode, {
    "\[LeftDoubleBracket]" -> "\"",
    "\[RightDoubleBracket]" -> "\"",
    "\[OpenCurlyDoubleQuote]" -> "\"",
    "\[CloseCurlyDoubleQuote]" -> "\"",
    "\[OpenCurlyQuote]" -> "'",
    "\[CloseCurlyQuote]" -> "'",
    FromCharacterCode[8216] -> "'",
    FromCharacterCode[8217] -> "'",
    FromCharacterCode[8220] -> "\"",
    FromCharacterCode[8221] -> "\""
  }];
  
  normalizedCode
]

(* Remove invisible spaces and problematic characters *)
FixInvisibleSpaces[code_String] := Module[{
  cleanedCode = code
},
  (* Remove zero-width spaces and other invisible characters *)
  cleanedCode = StringReplace[cleanedCode, {
    FromCharacterCode[8203] -> "",  (* Zero-width space *)
    FromCharacterCode[8288] -> "",  (* Word joiner *)
    FromCharacterCode[8204] -> "",  (* Zero-width non-joiner *)
    FromCharacterCode[8205] -> "",  (* Zero-width joiner *)
    FromCharacterCode[8201] -> " ", (* Thin space *)
    FromCharacterCode[8194] -> " ", (* En space *)
    FromCharacterCode[8195] -> " ", (* Em space *)
    FromCharacterCode[8202] -> "",  (* Hair space *)
    FromCharacterCode[160] -> " "   (* Non-breaking space *)
  }];
  
  (* Replace non-breaking spaces with regular spaces *)
  cleanedCode = StringReplace[cleanedCode, "\[NonBreakingSpace]" -> " "];
  
  (* Remove trailing spaces from each line *)
  cleanedCode = StringReplace[cleanedCode, RegularExpression[" +\n"] -> "\n"];
  
  cleanedCode
]

(* Detect common encoding issues *)
DetectEncodingIssues[code_String] := Module[{
  issues = {},
  chars = Characters[code]
},
  (* Check for common problematic characters *)
  If[StringContainsQ[code, "\[Rule]"],
    AppendTo[issues, "Found \\[Rule] characters - may need conversion to ->"]
  ];
  If[StringContainsQ[code, "\[Function]"],
    AppendTo[issues, "Found \\[Function] characters - may need conversion to &"]
  ];
  If[StringContainsQ[code, "\[DirectedEdge]"],
    AppendTo[issues, "Found \\[DirectedEdge] characters - check if intended"]
  ];
  
  (* Check for mixed quote types *)
  If[StringContainsQ[code, FromCharacterCode[8220]] || StringContainsQ[code, FromCharacterCode[8221]],
    AppendTo[issues, "Found smart quotes - should be converted to standard quotes"]
  ];
  
  (* Check for invisible characters *)
  Do[
    If[! PrintableASCIIQ[char] && ! MemberQ[{"\n", "\t", "\r"}, char],
      AppendTo[issues, "Non-printable character found: " <> ToString[char, InputForm]]
    ],
    {char, chars}
  ];
  
  If[Length[issues] == 0,
    {"No encoding issues detected"},
    issues
  ]
]

(* Validate code pasted from Mathematica notebooks *)
ValidateNotebookPaste[code_String] := Module[{
  issues = {},
  lines = StringSplit[code, "\n"]
},
  (* Check for In/Out labels that might have been copied *)
  Do[
    If[StringMatchQ[line, "In[" ~~ DigitCharacter.. ~~ "]:=" ~~ ___],
      AppendTo[issues, "Line " <> ToString[i] <> " contains In[] label - should be removed"]
    ];
    If[StringMatchQ[line, "Out[" ~~ DigitCharacter.. ~~ "]=" ~~ ___],
      AppendTo[issues, "Line " <> ToString[i] <> " contains Out[] label - should be removed"]
    ],
    {i, Length[lines]}, {line, lines}
  ];
  
  (* Check for cell markers *)
  If[StringContainsQ[code, "(*"] && StringContainsQ[code, "*)"],
    If[StringContainsQ[code, "CellGroupData"] || StringContainsQ[code, "CellExpression"],
      AppendTo[issues, "Code contains notebook cell structure - extract only the code content"]
    ]
  ];
  
  issues
]

(* Main function to fix copy-paste issues *)
FixCopyPasteIssues[code_String] := Module[{
  fixedCode = code,
  report = {}
},
  (* Apply all fixes *)
  fixedCode = NormalizeQuotes[fixedCode];
  fixedCode = FixInvisibleSpaces[fixedCode];
  
  (* Remove In/Out labels *)
  fixedCode = StringReplace[fixedCode, 
    RegularExpression["^In\\[\\d+\\]:=\\s*"] -> "",
    1
  ];
  fixedCode = StringReplace[fixedCode, 
    RegularExpression["^Out\\[\\d+\\]=\\s*"] -> "",
    1
  ];
  
  (* Clean up multiple empty lines *)
  fixedCode = StringReplace[fixedCode, RegularExpression["\\n\\s*\\n\\s*\\n"] -> "\n\n"];
  
  (* Trim leading and trailing whitespace *)
  fixedCode = StringTrim[fixedCode];
  
  (* Generate report *)
  If[fixedCode != code,
    AppendTo[report, "Code has been cleaned and normalized"];
    AppendTo[report, "Original length: " <> ToString[StringLength[code]]];
    AppendTo[report, "Cleaned length: " <> ToString[StringLength[fixedCode]]];
  ];
  
  <|"Code" -> fixedCode, "Report" -> report|>
]

End[]
EndPackage[]