UNIT MDGentpu;

(* PROGRAM DESCRIPTION
*  ===================
*
*  This is the interface unit for the MDGEN DLL. The latter contains routines
*  which are currently used in the following programs:
*
*  - NONOGRAM.EXE  (Nonogram Solver v2.2)
*
*  It contains three procedures/functions related to checking file existance
*  and formatting dates using information contained in WIN.INI.
*
*
*  PROGRAM INFORMATION
*  ===================
*  Author   : M G Davidson
*  Date     : 10/04/1994
*  Version  : 1.0
*  Language : PASCAL
*)



(***************************************************************************)
(* DLL Interface *)


INTERFACE

FUNCTION GetVersion: PChar;
FUNCTION FileExists(FileName: PChar): BOOLEAN;
PROCEDURE ConvertDate(GivenTime: LONGINT; ReturnString: PChar);


(***************************************************************************)
(* DLL Implementation *)


IMPLEMENTATION

FUNCTION GetVersion;    EXTERNAL 'MDGen' INDEX 1;
FUNCTION FileExists;    EXTERNAL 'MDGen' INDEX 2;
PROCEDURE ConvertDate;  EXTERNAL 'MDGen' INDEX 3;

END.
