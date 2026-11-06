(* Mathematica Syntax Validator *)
(* This module provides functions to validate Mathematica code syntax and structure *)

BeginPackage["SyntaxValidator`"]

ValidateCode::usage = "ValidateCode[code] validates Mathematica code syntax and returns a list of issues";
CheckBrackets::usage = "CheckBrackets[code] checks for balanced brackets, parentheses, and braces";
DetectInvisibleChars::usage = "DetectInvisibleChars[code] detects invisible characters that may cause issues";
ValidateFunction::usage = "ValidateFunction[code] validates function definitions and usage patterns";
FormatCode::usage = "FormatCode[code] formats Mathematica code with proper indentation";

Begin["`Private`"]

(* Check for balanced brackets, parentheses, and braces *)
CheckBrackets[code_String] := Module[{
  openBrackets = 0, openParens = 0, openBraces = 0,
  issues = {}
},
  Do[
    Switch[char,
      "[", openBrackets++,
      "]", openBrackets--; If[openBrackets < 0, AppendTo[issues, "Unmatched closing bracket at position " <> ToString[i]]],
      "(", openParens++,
      ")", openParens--; If[openParens < 0, AppendTo[issues, "Unmatched closing parenthesis at position " <> ToString[i]]],
      "{", openBraces++,
      "}", openBraces--; If[openBraces < 0, AppendTo[issues, "Unmatched closing brace at position " <> ToString[i]]]
    ],
    {i, StringLength[code]}, {char, Characters[code]}
  ];
  
  If[openBrackets > 0, AppendTo[issues, "Unclosed brackets: " <> ToString[openBrackets]]];
  If[openParens > 0, AppendTo[issues, "Unclosed parentheses: " <> ToString[openParens]]];
  If[openBraces > 0, AppendTo[issues, "Unclosed braces: " <> ToString[openBraces]]];
  
  issues
]

(* Detect invisible characters that may cause copy-paste issues *)
DetectInvisibleChars[code_String] := Module[{
  chars = Characters[code],
  invisibleChars = {},
  issues = {}
},
  Do[
    If[! PrintableASCIIQ[char] && char != "\n" && char != "\t" && char != "\r",
      AppendTo[invisibleChars, {char, i}]
    ],
    {i, Length[chars]}, {char, chars}
  ];
  
  If[Length[invisibleChars] > 0,
    AppendTo[issues, "Invisible characters found at positions: " <> ToString[invisibleChars[[All, 2]]]]
  ];
  
  issues
]

(* Validate function definitions *)
ValidateFunction[code_String] := Module[{
  issues = {},
  lines = StringSplit[code, "\n"]
},
  (* Check for common function definition patterns *)
  Do[
    If[StringContainsQ[line, ":="] && !StringContainsQ[line, "["] && StringContainsQ[line, "_"],
      AppendTo[issues, "Potential function definition issue on line " <> ToString[i] <> ": missing brackets"]
    ];
    If[StringContainsQ[line, "Module["] && !StringContainsQ[line, ","],
      AppendTo[issues, "Potential Module syntax issue on line " <> ToString[i] <> ": missing comma after variable list"]
    ],
    {i, Length[lines]}, {line, lines}
  ];
  
  issues
]

(* Format code with proper indentation *)
FormatCode[code_String] := Module[{
  lines = StringSplit[code, "\n"],
  indentLevel = 0,
  formattedLines = {}
},
  Do[
    Module[{trimmedLine = StringTrim[line], indentedLine},
      (* Decrease indent for closing brackets *)
      If[StringStartsQ[trimmedLine, "]"] || StringStartsQ[trimmedLine, "}"] || StringStartsQ[trimmedLine, ")"],
        indentLevel = Max[0, indentLevel - 1]
      ];
      
      (* Apply indentation *)
      indentedLine = StringRepeat["  ", indentLevel] <> trimmedLine;
      AppendTo[formattedLines, indentedLine];
      
      (* Increase indent for opening brackets *)
      If[StringEndsQ[trimmedLine, "["] || StringEndsQ[trimmedLine, "{"] || StringEndsQ[trimmedLine, "("] ||
         StringContainsQ[trimmedLine, "Module["] || StringContainsQ[trimmedLine, "With["] || StringContainsQ[trimmedLine, "Block["],
        indentLevel++
      ]
    ],
    {line, lines}
  ];
  
  StringRiffle[formattedLines, "\n"]
]

(* Main validation function *)
ValidateCode[code_String] := Module[{
  allIssues = {}
},
  allIssues = Join[allIssues, CheckBrackets[code]];
  allIssues = Join[allIssues, DetectInvisibleChars[code]];
  allIssues = Join[allIssues, ValidateFunction[code]];
  
  If[Length[allIssues] == 0,
    {"No syntax issues found"},
    allIssues
  ]
]

End[]
EndPackage[]