LIBRARY MDGEN;

(* PROGRAM DESCRIPTION
*  ===================
*
*  This DLL contains routines which are currently used in the following
*  programs:
*
*  - NONOGRAM.EXE  (Nonogram Solver v2.3)
*
*  It contains three procedures/functions related to checking file existance
*  and formatting dates using information contained in WIN.INI.
*
*  Version 1.0. Initial release. Three functions available in this DLL. The
*  first checks for file existence while the second checks for date
*  formatting information from WIN.INI. The third function returns the
*  version number of the program. This version was released on 10/04/94.
*
*
*  Version 1.01. DLL has been tidied up with surplus code removed. This
*  version was released on 15/11/94.
*
*
*
*  PROGRAM INFORMATION
*  ===================
*  Author   : M G Davidson
*  Date     : 15/11/1994
*  Version  : 1.01
*  Language : PASCAL
*)


{$R MDGEN.RES}

USES WinTypes, WinProcs, WinDOS, Strings;

(***************************************************************************)
(* Functions/procedures defined from here onwards *)


FUNCTION GetVersion: PChar; EXPORT;
BEGIN
  (* Return the version number of this DLL *)
  StrCopy(GetVersion, '1.01');
END;


FUNCTION FileExists(FileName: PChar): BOOLEAN; EXPORT;
VAR
  F: File;
BEGIN
  (* Boolean function that returns True if the file exists; otherwise,
     it returns False. Closes the file if it exists. *)
  {$I-}
  Assign(F, FileName);
  Reset(F);
  Close(F);
  {$I+}
  FileExists := (IOResult = 0) AND (StrComp(FileName, '') <> 0);
END;


PROCEDURE ConstructDate(Given, ReturnBuf: PChar; TimeInfo: TDateTime);
VAR
  Spare: ARRAY [0..10] OF CHAR;
BEGIN

  (* This procedure compares the string it is given and then constructs
     a date. It is called by ConvertDate and is not EXPORTED *)
  IF (StrComp(Given, 'D') = 0) THEN
  BEGIN
    Str(TimeInfo.Day, Spare);
    StrCopy(ReturnBuf, Spare);
  END;
  IF (StrComp(Given, 'DD') = 0) THEN
  BEGIN
    IF (TimeInfo.Day < 10) THEN
    BEGIN
      StrCopy(ReturnBuf, '0');
      Str(TimeInfo.Day, Spare);
      StrCat(ReturnBuf, Spare);
    END
    ELSE
    BEGIN
      Str(TimeInfo.Day, Spare);
      StrCopy(ReturnBuf, Spare);
    END;
  END;

  IF (StrComp(Given, 'M') = 0) THEN
  BEGIN
    Str(TimeInfo.Month, Spare);
    StrCopy(ReturnBuf, Spare);
  END;
  IF (StrComp(Given, 'MM') = 0) THEN
  BEGIN
    IF (TimeInfo.Month < 10) THEN
    BEGIN
      StrCopy(ReturnBuf, '0');
      Str(TimeInfo.Month, Spare);
      StrCat(ReturnBuf, Spare);
    END
    ELSE
    BEGIN
      Str(TimeInfo.Month, Spare);
      StrCopy(ReturnBuf, Spare);
    END;
  END;

  IF (StrComp(Given, 'YYYY') = 0) THEN
  BEGIN
    Str(TimeInfo.Year, Spare);
    StrCopy(ReturnBuf, Spare);
  END;
  IF (StrComp(Given, 'YY') = 0) THEN
  BEGIN
    Str(TimeInfo.Year, Spare);
    Spare[0] := Spare[2];
    Spare[1] := Spare[3];
    Spare[2] := #0;
    StrCopy(ReturnBuf, Spare);
  END;

END;


PROCEDURE ConvertDate(GivenTime: LONGINT; ReturnString: PChar); EXPORT;
VAR
  I, J: LONGINT;
  TimeInfo: TDateTime;
  DateFormat: ARRAY [0..20] OF CHAR;
  Grp1, Grp2, Grp3, Sepr: ARRAY [0..5] OF CHAR;
  Spare: ARRAY [0..10] OF CHAR;
BEGIN
  (* Convert a date to a string using the formatting information given
     in WIN.INI. This function is exported *)

  (* Unpack given time *)
  UnpackTime(GivenTime, TimeInfo);
  GetProfileString('intl', 'sShortDate', 'DD/MM/YY', DateFormat, 20);

  (* Convert date information to upper case *)
  I := 0;
  WHILE (DateFormat[I] <> #0) DO
  BEGIN
    IF ((DateFormat[I] = 'D') OR (DateFormat[I] = 'M') OR (DateFormat[I] = 'Y') OR
        (DateFormat[I] = 'd') OR (DateFormat[I] = 'm') OR (DateFormat[I] = 'y')) THEN
      DateFormat[I] := UpCase(DateFormat[I]);
    INC(I);
  END;

  (* Seperate out date information  - move to start of information *)
  I := 0;
  WHILE ((DateFormat[I] <> 'D') AND (DateFormat[I] <> 'M') AND (DateFormat[I] <> 'Y')) DO
    INC(I);

  J := 0;
  WHILE ((DateFormat[I] = 'D') OR (DateFormat[I] = 'M') OR (DateFormat[I] = 'Y')) DO
  BEGIN
    Grp1[J] := DateFormat[I];
    INC(I);
    INC(J);
  END;
  Grp1[J] := #0;
    
  (* Get seperator *)
  Sepr[0] := DateFormat[I];
  Sepr[1] := #0;
  INC(I);

  (* Get second piece of date information *)
  J := 0;
  WHILE ((DateFormat[I] = 'D') OR (DateFormat[I] = 'M') OR (DateFormat[I] = 'Y')) DO
  BEGIN
    Grp2[J] := DateFormat[I];
    INC(I);
    INC(J);
  END;
  Grp2[J] := #0;
  INC(I);

  (* Get third piece of date information *)
  J := 0;
  WHILE ((DateFormat[I] = 'D') OR (DateFormat[I] = 'M') OR (DateFormat[I] = 'Y')) DO
  BEGIN
    Grp3[J] := DateFormat[I];
    INC(I);
    INC(J);
  END;
  Grp3[J] := #0;

  (* Now after all that we can construct the actual date *)
  ConstructDate(Grp1, Spare, TimeInfo);
  StrCopy(ReturnString, Spare);
  StrCat(ReturnString, Sepr);
  ConstructDate(Grp2, Spare, TimeInfo);
  StrCat(ReturnString, Spare);
  StrCat(ReturnString, Sepr);
  ConstructDate(Grp3, Spare, TimeInfo);
  StrCat(ReturnString, Spare);

END;


(***************************************************************************)
(* Exports section *)


EXPORTS
  GetVersion   INDEX 1,
  FileExists   INDEX 2,
  ConvertDate  INDEX 3;


(***************************************************************************)
(* Main program from here onwards *)


BEGIN
END.
