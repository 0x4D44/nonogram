' PROGRAM NONOGRAM
' ***************************************************************************
'
' NONOGRAM Solving program
' ========================
'
' Version 01.0 - MGD 03/02/1993
'
' ***************************************************************************

DECLARE SUB AltParam ()
DECLARE SUB Chdr ()
DECLARE SUB CheckEdge ()
DECLARE SUB DotCross ()
DECLARE SUB DrawCGA ()
DECLARE SUB DrawGrid ()
DECLARE SUB EasyFill (I%, K%)
DECLARE SUB FillDot (I%, J%, K%)
DECLARE SUB Fill2ndDot ()
DECLARE SUB FollowRow ()
DECLARE SUB Introduct ()
DECLARE SUB Help ()
DECLARE SUB HelpText ()
DECLARE SUB ParseData (Disp%)
DECLARE SUB Pause ()
DECLARE SUB PlotPoint (I%, J%, T%)
DECLARE SUB QuickData ()
DECLARE SUB ReadData (FileNam$)
DECLARE SUB Testing ()
DECLARE SUB TestRowFull ()
DECLARE SUB Update ()
DECLARE SUB VarSize ()
DECLARE SUB Warning (I%, J%, Old%, New%)

DEFINT A-Z
DIM SHARED Across(25) AS INTEGER      ' Line completed - Horizontal
DIM SHARED Ced AS INTEGER
DIM SHARED ComSize AS INTEGER
DIM SHARED Dis AS INTEGER
DIM SHARED Down(20) AS INTEGER        ' Line completed - Vertical
DIM SHARED Grid(0 TO 26, 0 TO 21) AS INTEGER    ' Grid Array - 1 'XX', 2 - '..'
DIM SHARED Horiz(26, 10) AS INTEGER
DIM SHARED FileLen
DIM SHARED FileNam$
DIM SHARED Frw AS INTEGER
DIM SHARED Mnu AS INTEGER
DIM SHARED OldTotal AS INTEGER
DIM SHARED PlotTotal AS INTEGER
DIM SHARED Qst AS INTEGER
DIM SHARED Solved AS INTEGER
DIM SHARED Sum1, Sum2 AS INTEGER
DIM SHARED SysWar AS INTEGER
DIM SHARED Title$
DIM SHARED Trf AS INTEGER
DIM SHARED Tst AS INTEGER
DIM SHARED Verti(20, 10) AS INTEGER
DIM SHARED Warnd AS INTEGER


' ***************************************************************************
'
' MAIN PROGRAM:
' -------------

ON ERROR GOTO HANDLER

' ***************************************************************************

PlotTotal = 0: ComSize = 20

' The following lines fill the outer rim of "Grid" with dots

 FOR I = 0 TO 21
  Grid(0, I) = 2
  Grid(26, I) = 2
 NEXT I

 FOR J = 0 TO 26
  Grid(J, 0) = 2
  Grid(J, 21) = 2
 NEXT J

' Initialise arrays      

 FOR I = 1 TO 25
  Across(I) = 0
 NEXT I

 FOR J = 1 TO 20
  Down(J) = 0
 NEXT J

' ***************************************************************************
'
' The following section reads in the command line and decides the appropriate
' action to take. To discover valid switches examine the help file.

T = 1
COM$ = ""
T$ = COMMAND$
IF LEN(T$) > 0 AND LEN(T$) < 40 THEN
 FOR I = 1 TO LEN(T$)
  IF MID$(T$, I, 1) = "/" THEN
   COM$(T) = MID$(T$, (I + 1), 1)
   IF COM$(T) = "F" OR COM$(T) = "f" THEN
    F$ = ""
    S = I + 3
    G$ = MID$(T$, S, 1)
     DO
      F$ = F$ + G$: S = S + 1
      G$ = MID$(T$, S, 1)
     LOOP UNTIL G$ = " " OR (S - 1) = LEN(T$) OR G$ = "/"
   END IF
   T = T + 1
  END IF
 NEXT I
END IF

FOR S = 1 TO T
 IF COM$(S) = "?" THEN Help
NEXT S

' ***************************************************************************

SCREEN 0

KEY ON
KEY OFF
KEY 1, "HELP" + CHR$(13)
KEY 2, "FILE" + CHR$(13)
KEY 3, "PARS" + CHR$(13)
KEY 4, "CATA" + CHR$(13)
KEY 5, "CHDR" + CHR$(13)
KEY 6, "COMM" + CHR$(13)
KEY 7, "SOLV" + CHR$(13)
KEY 8, "ALTR" + CHR$(13)
KEY 9, "TITL" + CHR$(13)
KEY 10, "STOP" + CHR$(13)

' **************************************************************************
'
' Introduce this MS-DOS version of the nonogram solver.
' And also read in the problem data.


Introduct

' **************************************************************************


IF (Mnu = 2) THEN
 KEY ON
ELSE
 KEY OFF
END IF

Inpt:

 INPUT "Activity"; ACT$

 LASTK$ = ACT$

 'Current Command List available

 IF ((ACT$ = "SOLV") OR (ACT$ = "solv")) THEN
  GOTO Solv
 ELSEIF ((ACT$ = "CATA") OR (ACT$ = "cata")) THEN
  PRINT
  FILES "*.NGM"
  PRINT
 ELSEIF ((ACT$ = "VERS") OR (ACT$ = "vers")) THEN
  PRINT
  PRINT "NONOGRAM - (C) MGD Software"
  PRINT
  PRINT "Version 01.0"
  PRINT "Revision (none)"
  PRINT
 ELSEIF ((ACT$ = "ALTR") OR (ACT$ = "altr")) THEN
  AltParam
   IF (Mnu = 2) THEN
    KEY ON
   ELSE
    KEY OFF
   END IF
 ELSEIF ((ACT$ = "CHDR") OR (ACT$ = "chdr")) THEN
  Chdr
 ELSEIF ((ACT$ = "FILE") OR (ACT$ = "file")) THEN
  GOTO FILINS
 ELSEIF ((ACT$ = "TITL") OR (ACT$ = "titl")) THEN
  PRINT
  IF Title$ <> "" THEN
   PRINT "  Currently loaded data is:"
   PRINT "    "; Title$
  ELSE
   PRINT "  No data currently loaded"
  END IF
  PRINT
 ELSEIF ((ACT$ = "STOP") OR (ACT$ = "stop")) THEN
  GOTO FIQUIT
 ELSEIF ((ACT$ = "HELP") OR (ACT$ = "help")) THEN
  HelpText
 ELSEIF ((ACT$ = "PARS") OR (ACT$ = "pars")) THEN
  ParseData 0
 ELSEIF ((ACT$ = "VARS") OR (ACT$ = "vars")) THEN
  VarSize
 ELSEIF ((ACT$ = "COMM") OR (ACT$ = "comm")) THEN
  PRINT
  PRINT "Command List"
  PRINT
  PRINT "CATA - List all NONOGRAM data files"
  PRINT "COMM - Command list"
  PRINT "FILE - Load a data file"
  PRINT "HELP - Help option"
  PRINT "PARS - Parse data for errors"
  PRINT "SOLV - Solve nonogram puzzle"
  PRINT "STOP - Stop program and exit"
  PRINT "TITL - Displays current data title"
  PRINT "VARS - Advanced variable setup"
  PRINT "VERS - Software version number"
  PRINT
 ELSEIF ACT$ = "" THEN
 ' Do nothing
 ELSE
  PRINT
  PRINT "  Unknown command - type 'HELP' for help."
  PRINT
 END IF

 GOTO Inpt

FILINS:
 PRINT
 INPUT "  Please enter the name of the data source"; FileNam$
 PRINT

   IF FileNam$ = "" THEN
    GOTO Inpt
   END IF

   ' Open file given and if it is valid start pulling in data.

   ReadData FileNam$
    IF (FISTAT = 1) THEN
     PRINT
     PRINT "  That is not a valid file - <CR> to exit "
     PRINT
     FISTAT = 0
     GOTO FILINS
    ELSEIF (Warnd <> 1) THEN
     PRINT
     PRINT "  "; FileLen; " bytes read from "; FileNam$
     PRINT
     PRINT "  Saved Data is:"
     PRINT "    "; Title$
     PRINT
    END IF

    GOTO Inpt

' ***************************************************************************

FIQUIT:

PRINT
PRINT "Program stopped"
PRINT
END

' **************************************************************************
'
' MAIN SOLUTION SECTION
' =====================

Solv:

 ParseData 1
  IF ((Sum1 <> Sum2) OR (Sum1 = 0) OR (Sum2 = 0)) THEN GOTO Inpt

 PlotTotal = 0: KEY OFF: CLS

  IF Dis = 2 THEN
   DrawGrid                       'VGA option
  ELSE
   DrawCGA                        'CGA option
  END IF

IF Solved = 1 THEN
  FOR J = 1 TO 20
   FOR I = 1 TO 25
    PlotPoint I, J, Grid(I, J)
   NEXT I
  NEXT J

  LOCATE 10, 60
  PRINT "Nonogram is"
  LOCATE 11, 60
  PRINT "already solved."
ELSE

    FOR I = 1 TO 25
     FOR J = 1 TO 20
      Grid(I, J) = 0
     NEXT J
    NEXT I
    FOR I = 1 TO 25
     Across(I) = 0
    NEXT I
    FOR I = 1 TO 20
     Down(I) = 0
    NEXT I

    IF Qst = 2 THEN QuickData
    Start! = TIMER: RunTot = 0

    DO
     RunTot = RunTot + 1
     IF RunTot > 3 THEN RunTot = 1
     OldTotal = PlotTotal
     Update
     IF Ced = 2 THEN CheckEdge
     IF Trf = 2 THEN TestRowFull
     IF Frw = 2 THEN FollowRow
     IF RunTot = 3 AND Tst = 2 THEN Testing
    LOOP UNTIL ((PlotTotal = OldTotal AND RunTot = 3) OR PlotTotal = 500)

    Finish! = TIMER: Solved = 1
    Update

    LOCATE 2, 1
     IF PlotTotal = 500 THEN
      PRINT "Successfully finished in "; Finish! - Start!; "seconds."
     ELSE
      PRINT "Finished in "; Finish! - Start!; "seconds."
      LOCATE 3, 1
      PRINT PlotTotal
     END IF

END IF

 IF Dis = 2 THEN
  LOCATE 28, 1
  PRINT "Press any key to continue"
 ELSE
  LOCATE 22, 60
  PRINT "Press any key"
  LOCATE 23, 60
  PRINT " to continue"
 END IF

 Pause
 SCREEN 0: CLS : KEY ON


GOTO Inpt

' ***************************************************************************

' Error Handling Routine
' ----------------------

HANDLER:

      NUMBER = ERR
      IF (NUMBER = 53) THEN
       IF (SysWar = 0) THEN
        PRINT "File not located in this directory"
        PRINT "Enter new file specification ([d:\]\xxx\...\xxx) "
        PRINT
       END IF
       Warnd = 1
       CLOSE #1
      END IF

      RESUME NEXT
' ***************************************************************************

SUB AltParam
' ***************************************************************************
' This procedure allows for parameter altering to take place.
' NOTE:  The 'true' value is 2 and false value '1'.
'
' ---------------------------------

PRINT
PRINT "The current program configuration is - "
PRINT
PRINT "Menu bar display              - ";
 IF (Mnu = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Mnu = 2: PRINT "YES"
   ELSE
    Mnu = 1: PRINT "NO"
   END IF
PRINT "VGA grid display (NO = CGA)   - ";
 IF (Dis = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Dis = 2: PRINT "YES"
   ELSE
    Dis = 1: PRINT "NO"
   END IF
PRINT "Enable QuickStart routinue    - ";
 IF (Qst = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Qst = 2: PRINT "YES"
   ELSE
    Qst = 1: PRINT "NO"
   END IF
PRINT "Enable edge testing           - ";
 IF (Ced = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Ced = 2: PRINT "YES"
   ELSE
    Ced = 1: PRINT "NO"
   END IF
PRINT "Enable full row testing       - ";
 IF (Trf = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Trf = 2: PRINT "YES"
   ELSE
    Trf = 1: PRINT "NO"
   END IF
PRINT "Enable row following method   - ";
 IF (Frw = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Frw = 2: PRINT "YES"
   ELSE
    Frw = 1: PRINT "NO"
   END IF
PRINT "Enable combination algorithm  - ";
 IF (Tst = 2) THEN
  PRINT "YES";
 ELSE
  PRINT "NO";
 END IF
  PRINT TAB(43); " - Now - ";
  DO
   T$ = INKEY$
  LOOP WHILE T$ = ""
   IF (T$ = "Y") OR (T$ = "y") THEN
    Tst = 2: PRINT "YES"
   ELSE
    Tst = 1: PRINT "NO"
   END IF
 PRINT
 PRINT "Current options noted - save?  ";
 DO
  T$ = INKEY$
 LOOP WHILE T$ = ""

 IF (T$ = "Y") OR (T$ = "y") THEN
  PRINT "YES"
  OPEN "NONOGRAM.PRM" FOR OUTPUT AS #3
   WRITE #3, Mnu, Dis, Qst, Ced, Trf, Frw, Tst
  CLOSE #3
  PRINT
  PRINT "New default options saved"
  PRINT
 ELSE
  PRINT "NO"
  PRINT
  PRINT "Options have not been saved"
  PRINT
 END IF



' ***************************************************************************
END SUB

SUB Chdr
' ***************************************************************************
' This sub changes the default directory.
'
' ------------------------

Dire$ = ""

PRINT
INPUT "Please enter the new default directory path"; Dire$
PRINT

CHDIR Dire$

' ***************************************************************************
END SUB

SUB CheckEdge
' ***************************************************************************
' This subroutinue checks to see if any squares along the edges have been
' filled in. If they have then they are candidates for filling in.
'
' ---------------------
'

FOR I = 1 TO 25
 IF Grid(I, 1) = 1 THEN
  FOR J = 1 TO Horiz(I, 1)
   PlotPoint I, J, 1
  NEXT J
   PlotPoint I, (Horiz(I, 1) + 1), 2
 END IF

 IF Grid(I, 20) = 1 THEN
  FOR T = 1 TO 10
   Temp = Horiz(I, T)
   IF Temp > 0 THEN Value = Temp
  NEXT T
  FOR J = (21 - Value) TO 20 STEP 1
   PlotPoint I, J, 1
  NEXT J
   PlotPoint I, (20 - Value), 2
 END IF

NEXT I

FOR I = 1 TO 20
 IF Grid(1, I) = 1 THEN
  FOR J = 1 TO Verti(I, 1)
   PlotPoint J, I, 1
  NEXT J
   PlotPoint (Verti(I, 1) + 1), I, 2
 END IF

 IF Grid(25, I) = 1 THEN
  FOR T = 1 TO 10
   Temp = Verti(I, T)
   IF Temp > 0 THEN Value = Temp
  NEXT T
  FOR J = (26 - Value) TO 25 STEP 1
   PlotPoint J, I, 1
  NEXT J
   PlotPoint (25 - Value), I, 2
 END IF

NEXT I

' ***************************************************************************
END SUB

SUB DotCross
' ***************************************************************************
' This sub is finds a cross next to a dot and then attempts to fill in
' as much of the related line as is possible.
'
' --------------------------

FOR I = 1 TO 20
 LastPos = 2

 FOR J = 1 TO 26
  IF J < 26 THEN
   NextPos = Grid(J, I)
  ELSE
   NextPos = 2
  END IF
 NEXT J
   Flag = 0
   IF LastPos = 2 AND NextPos = 1 THEN Flag = 1
   IF LastPos = 2 AND NextPos = 1 THEN Flag = 1

    IF Flag = 1 THEN      'Program has detected a cross next to a dot.

    
     FOR T = 1 TO 25
     NEXT
    END IF
NEXT I

' ***************************************************************************
END SUB

SUB DrawCGA
' ***************************************************************************
' This sub draws the CGA version of the GRID which is then filled in as the
' solution for the NONOGRAM is calculated.
'
' --------------------

CLS
LOCATE 1, 1: PRINT Title$

FOR I = 3 TO 22 STEP 1
LOCATE I, 1: PRINT (I - 2)
NEXT I
J = 0
FOR I = 5 TO 54 STEP 2
LOCATE 23, I: J = J + 1
K = J
'IF J < 10 THEN
' PRINT J;
'ELSEIF J < 20 THEN
' PRINT " 1";
'ELSEIF J < 30 THEN
' PRINT " 2";
'END IF
'LOCATE 24, I
'Top2:
'IF K > 9 THEN K = K - 10: GOTO Top2
'IF J > 9 THEN PRINT K
PRINT CHR$(65 + (I - 5) / 2)
NEXT I


' ***************************************************************************
END SUB

SUB DrawGrid
' ***************************************************************************
' This sub draws the VGA grid which is filled in as the solution progresses.
'
' -------------------------

SCREEN 12
LOCATE 1, 1: PRINT Title$

FOR I = 5 TO 24 STEP 1
LOCATE I, 1: PRINT (I - 4)
NEXT I
J = 0
FOR I = 4 TO 53 STEP 2
LOCATE 25, I: J = J + 1
K = J
IF J < 10 THEN
 PRINT J;
ELSEIF J < 20 THEN
 PRINT " 1";
ELSEIF J < 30 THEN
 PRINT " 2";
END IF
LOCATE 26, I
Top:
IF K > 9 THEN K = K - 10: GOTO Top
IF J > 9 THEN PRINT K
NEXT I

' ***************************************************************************
END SUB

SUB EasyFill (I, K)
' ***************************************************************************
' This sub is called by the sub QuickData and assumes that the data provided
' is such that it fills the row in only one way. It then fills in this data.'
'
' -----------------------


 P = 0
 J = 0
 IF K <> 1 THEN
  Down(I) = 1
 ELSE
  Across(I) = 1
 END IF


FOR J = 1 TO 10

 IF K <> 1 THEN
   A = Verti(I, J)
   FOR T = 1 TO A
    PlotPoint (P + T), I, 1
   NEXT T
   P = P + A
   IF P < 25 THEN
    PlotPoint (P + 1), I, 2
   END IF
   P = P + 1
 ELSE
   A = Horiz(I, J)
'   LOCATE 1, 1
'   PRINT I
'   Pause
   FOR T = 1 TO A
    PlotPoint I, (P + T), 1
   NEXT T
   P = P + A
   IF P < 20 THEN
   PlotPoint I, (P + 1), 2
   END IF
   P = P + 1
 END IF
' LOCATE 1, 1
' PRINT A;

NEXT J


END SUB

SUB Fill2ndDot
' ***************************************************************************
' This SUB while occassionally working is not guranteed to produce the
' correct results - it remains solely for time/effort reasons.
'
' ------------------------

FOR I = 1 TO 20
 Total1 = 0: Total2 = 0
 LastPos = 0: CurrPos = Grid(1, I)
 IF CurrPos = 1 THEN Total1 = 1
 FOR J = 2 TO 25 STEP 1
  LastPos = CurrPos
  CurrPos = Grid(J, I)
  True = 0
  IF (CurrPos = 1 AND LastPos = 2) THEN True = 1
  IF (CurrPos = 1 AND LastPos = 0) THEN True = 1
  IF True = 1 THEN Total1 = Total1 + 1
 NEXT J
 FOR S = 1 TO 10
  IF Verti(I, S) > 0 THEN Total2 = Total2 + 1
 NEXT S

' LOCATE 1, 1
' PRINT "Total", I, Total1, Total2
' Pause

 IF Total1 = Total2 THEN
  FOR K = 1 TO Total1
   Left = 0
   LastPos = 0: CurrPos = 0: M = 0
    DO UNTIL Left = K - 1
     M = M + 1
     LastPos = CurrPos
     CurrPos = Grid(M, I)
     True = 0
     IF CurrPos = 2 AND LastPos = 1 THEN True = 1
     IF CurrPos = 0 AND LastPos = 1 THEN True = 1
     IF True = 1 THEN Left = Left + 1
    LOOP

   Left = M
   Place = Left

   DO
    Place = Place + 1
    Test = Grid(Place, I)
    IF Test = 2 THEN Left = Place
   LOOP WHILE (Test <> 1) AND (Place + 1 < 26)

   Right = 0
   LastPos = 0: CurrPos = 0: M = 26
    DO UNTIL Right = (Total1 - K)
     M = M - 1
     LastPos = CurrPos
     CurrPos = Grid(M, I)
     True = 0
     IF CurrPos = 2 AND LastPos = 1 THEN True = 1
     IF CurrPos = 0 AND LastPos = 1 THEN True = 1
     IF True = 1 THEN Right = Right + 1
    LOOP

    Right = M
    Place = Right

    DO
     Place = Place - 1
     Test = Grid(Place, I)
     IF Test = 2 THEN Right = Place
    LOOP WHILE (Test <> 1) AND (Place - 1 > 0)

'    LOCATE 1, 1
'    PRINT "kkk", Left, Right
'    Pause

    Right = Right - 1
    GapSize = Right - Left
    A = Verti(I, K)

      Ok = 0: S = GapSize - A
      IF S < 0 THEN Ok = 1
      StartPos = Left + S + 1
      StopPos = Right - S

     IF StartPos <= StopPos AND Ok <> 1 THEN
       FOR N = StartPos TO StopPos
        PlotPoint N, I, 1
       NEXT N
     END IF
' -----------------------------
' If the section of 'XX' is already the correct length then it should be
' sandwiched between a set of two dots.
' -----------------------------

    Tott = 0: Start = 0: Stopp = 0: Trap = 0
    FOR v = (Left + 1) TO Right
'     LOCATE 1, 1
'     PRINT "jfjf", Tott, A, V
'     Pause
     IF Grid(v, I) = 1 THEN Tott = Tott + 1: Stopp = v
     IF Tott = 1 AND Trap = 0 THEN Start = v: Trap = 1
    NEXT v

    IF Tott = A THEN
     IF Start > 1 THEN PlotPoint (Start - 1), I, 2
     IF Stopp < 25 THEN PlotPoint (Stopp + 1), I, 2
    END IF
  NEXT K
 END IF
NEXT I

FOR I = 1 TO 25
 Total1 = 0: Total2 = 0
 LastPos = 0: CurrPos = Grid(I, 1)
 IF CurrPos = 1 THEN Total1 = 1
 FOR J = 2 TO 20 STEP 1
  LastPos = CurrPos
  CurrPos = Grid(I, J)
  True = 0
  IF (CurrPos = 1 AND LastPos = 2) THEN True = 1
  IF (CurrPos = 1 AND LastPos = 0) THEN True = 1
  IF True = 1 THEN Total1 = Total1 + 1
 NEXT J
 FOR S = 1 TO 10
  IF Horiz(I, S) > 0 THEN Total2 = Total2 + 1
 NEXT S

' LOCATE 1, 1
' PRINT "Total", I, Total1, Total2
' Pause

 IF Total1 = Total2 THEN
  FOR K = 1 TO Total1
   Left = 0
   LastPos = 0: CurrPos = 0: M = 0
    DO UNTIL Left = K - 1
     M = M + 1
     LastPos = CurrPos
     CurrPos = Grid(I, M)
     True = 0
     IF CurrPos = 2 AND LastPos = 1 THEN True = 1
     IF CurrPos = 0 AND LastPos = 1 THEN True = 1
     IF True = 1 THEN Left = Left + 1
    LOOP

   Left = M
   Place = Left

   DO
    Place = Place + 1
    Test = Grid(I, Place)
    IF Test = 2 THEN Left = Place
   LOOP WHILE (Test <> 1) AND (Place + 1 < 21)

   Right = 0
   LastPos = 0: CurrPos = 0: M = 21
    DO UNTIL Right = (Total1 - K)
     M = M - 1
     LastPos = CurrPos
     CurrPos = Grid(I, M)
     True = 0
     IF CurrPos = 2 AND LastPos = 1 THEN True = 1
     IF CurrPos = 0 AND LastPos = 1 THEN True = 1
     IF True = 1 THEN Right = Right + 1
    LOOP

    Right = M
    Place = Right

    DO
     Place = Place - 1
     Test = Grid(I, Place)
     IF Test = 2 THEN Right = Place
    LOOP WHILE (Test <> 1) AND (Place - 1 > 0)

'    LOCATE 1, 1
'    PRINT "kkk", Left, Right
'    Pause

    Right = Right - 1
    GapSize = Right - Left
    A = Horiz(I, K)

      Ok = 0: S = GapSize - A
      IF S < 0 THEN Ok = 1
      StartPos = Left + S + 1
      StopPos = Right - S

     IF StartPos <= StopPos AND Ok <> 1 THEN
       FOR N = StartPos TO StopPos
        PlotPoint I, N, 1
       NEXT N
     END IF
 
' ***************************************************************************

    Tott = 0: Start = 0: Stopp = 0: Trap = 0
    FOR v = (Left + 1) TO Right
'     LOCATE 1, 1
'     PRINT "jfjf", Tott, A, V
'     Pause
     IF Grid(I, v) = 1 THEN Tott = Tott + 1: Stopp = v
     IF Tott = 1 AND Trap = 0 THEN Start = v: Trap = 1
    NEXT v

    IF Tott = A THEN
     IF Start > 1 THEN PlotPoint I, (Start - 1), 2
     IF Stopp < 20 THEN PlotPoint I, (Stopp + 1), 2
    END IF
  NEXT K
 END IF
NEXT I

' ***************************************************************************
END SUB

SUB FillDot (I, K, S)
' ***************************************************************************
' This sub fills in intial data given to it. (ie calculates under initial
' conditions of no entries the grid array points where 'XX's must be)
' Thus this sub is only of use at the beginning of the solution.
'
' ---------------------

 P = 0
 J = 0
 IF K <> 1 THEN
  IF Down(I) = 1 THEN EXIT SUB
 ELSE
  IF Across(I) = 1 THEN EXIT SUB
 END IF

FOR J = 1 TO 10

 IF K <> 1 THEN
   A = Verti(I, J)
    Ok = 0
    Left = 0
    FOR L = 1 TO (J - 1)
     Value = Verti(I, L)
     IF Value > 0 THEN Left = Left + 1 + Value
    NEXT L
    Right = 0
    FOR M = (J + 1) TO 10
     Value = Verti(I, M)
     IF Value > 0 THEN Right = Right + 1 + Value
    NEXT M
    Right = 25 - Right
    GapSize = Right - Left

      S = GapSize - A
      IF S < 0 THEN Ok = 1
      StartPos = Left + S + 1
      StopPos = Right - S


     IF StartPos <= StopPos AND Ok <> 1 THEN
       FOR N = StartPos TO StopPos
        PlotPoint N, I, 1
       NEXT N
     END IF
 ELSE
   A = Horiz(I, J)
    Ok = 0
    Left = 0
    FOR L = 1 TO (J - 1)
     Value = Horiz(I, L)
     IF Value > 0 THEN Left = Left + 1 + Value
    NEXT L
    Right = 0
    FOR M = (J + 1) TO 10
     Value = Horiz(I, M)
     IF Value > 0 THEN Right = Right + 1 + Value
    NEXT M
    Right = 20 - Right
    GapSize = Right - Left

      S = GapSize - A
      IF S < 0 THEN Ok = 1
      StartPos = Left + S + 1
      StopPos = Right - S
     
'LOCATE 1, 1
'PRINT "GG", A, Left, Right
'PRINT "HH", A, StartPos, StopPos
'Pause

     IF StartPos <= StopPos AND Ok <> 1 THEN
       FOR N = StartPos TO StopPos
'        LOCATE 1, 1
'        PRINT I, N, StartPos, StopPos
'        Pause
        PlotPoint I, N, 1
       NEXT N
     END IF
 END IF

NEXT J

' ***************************************************************************
END SUB

SUB FollowRow
' ***************************************************************************
' This sub finds the first dot /cross combination working from left/right
' and then attempts to fill in as much of the row from the respective end
' as it validly can.
'
' ---------------------------



'Horizontal rows from the left

FOR I = 1 TO 20
 IF Down(I) <> 1 THEN
  
  Find = 1: Jump = 0: J = -1
  DO
                                        'Find the starting position of the
   DO                                   'first '..'.
    IF J = 24 THEN Jump = 1
    IF J < 24 THEN J = J + 1
   LOOP WHILE Grid(J, I) = 1 AND Jump = 0

   IF Grid(J, I) = 2 AND Jump = 0 THEN
    IF Grid(J + 1, I) = 1 AND Jump = 0 THEN
     FOR K = (J + 1) TO (J + Verti(I, Find)) STEP 1
      PlotPoint K, I, 1
     NEXT K
     DotPlace = J + Verti(I, Find) + 1
     IF DotPlace < 26 THEN PlotPoint DotPlace, I, 2
     Find = Find + 1
    END IF
   ELSE
    Jump = 1
   END IF

  LOOP WHILE Jump = 0
 END IF
NEXT I

'Horiziontal rows from the right

FOR I = 1 TO 20
 IF Down(I) <> 1 THEN

  M = 11
  DO
   M = M - 1
  LOOP WHILE Verti(I, M) = 0


  Find = M: Jump = 0: J = 27
  DO
                                        'Find the starting position of the
   DO                                   'first '..'.
    IF J = 2 THEN Jump = 1
    IF J > 2 THEN J = J - 1
   LOOP WHILE Grid(J, I) = 1 AND Jump = 0

   IF Grid(J, I) = 2 AND Jump = 0 THEN
    IF Grid(J - 1, I) = 1 AND Jump = 0 THEN
     FOR K = (J - 1) TO (J - Verti(I, Find)) STEP -1
      PlotPoint K, I, 1
     NEXT K
     DotPl = J - Verti(I, Find) - 1
     IF DotPl > 0 THEN PlotPoint DotPl, I, 2
     Find = Find - 1
     IF Find = 0 THEN Jump = 1
    END IF
   ELSE
    Jump = 1
   END IF

  LOOP WHILE Jump = 0
 END IF
NEXT I

' Vertical rows from the top

FOR I = 1 TO 25
 IF Across(I) <> 1 THEN
 
  Find = 1: Jump = 0: J = -1
  DO
                                        'Find the starting position of the
   DO                                   'first '..'.
    IF J = 19 THEN Jump = 1
    IF J < 19 THEN J = J + 1
   LOOP WHILE Grid(I, J) = 1 AND Jump = 0

   IF Grid(I, J) = 2 AND Jump = 0 THEN
    IF Grid(I, J + 1) = 1 AND Jump = 0 THEN
     FOR K = (J + 1) TO (J + Horiz(I, Find)) STEP 1
      PlotPoint I, K, 1
     NEXT K
     DotPlace = J + Horiz(I, Find) + 1
     IF DotPlace < 21 THEN PlotPoint I, DotPlace, 2
     Find = Find + 1
    END IF
   ELSE
    Jump = 1
   END IF

  LOOP WHILE Jump = 0
 END IF
NEXT I

' Vertical rows from the bottom

FOR I = 1 TO 25
 IF Across(I) <> 1 THEN

  M = 11
  DO
   M = M - 1
  LOOP WHILE Horiz(I, M) = 0

  Find = M: Jump = 0: J = 22
  DO
                                        'Find the starting position of the
   DO                                   'first '..'.
    IF J = 2 THEN Jump = 1
    IF J > 2 THEN J = J - 1
   LOOP WHILE Grid(I, J) = 1 AND Jump = 0

   IF Grid(I, J) = 2 AND Jump = 0 THEN
    IF Grid(I, J - 1) = 1 AND Jump = 0 THEN
     FOR K = (J - 1) TO (J - Horiz(I, Find)) STEP -1
      PlotPoint I, K, 1
     NEXT K
     DotPlace = J - Horiz(I, Find) - 1
     IF DotPlace > 0 THEN PlotPoint I, DotPlace, 2
     Find = Find - 1
     IF Find = 0 THEN Jump = 1
    END IF
   ELSE
    Jump = 1
   END IF

  LOOP WHILE Jump = 0
 END IF
NEXT I

' ***************************************************************************
END SUB

SUB Help
' **************************************************************************
' Command line help is provided in this sub.
'
' --------------------


PRINT "NONOGRAM.EXE is a program tailored to solve NONOGRAM's. For more"
PRINT "information refer to the README.NGM file that accompanies this"
PRINT "program."
PRINT
PRINT "To run the program it must be started in interactive mode - ie it"
PRINT "does not support batch file processing."
PRINT
PRINT " Syntax:   NONOGRAM [/?]"
PRINT
PRINT "       /?            - displays this help screen."
PRINT
PRINT "Version 01.0  MGD - 1993"
END

' **************************************************************************
END SUB

SUB HelpText
' ***************************************************************************
' This comprises the help text  - see the user manual for more data.
' (alternatively you could try and understand this program....)
'
' --------------------------
'
CLS
PRINT "HELP for NONOGRAM version 1.0"
PRINT
PRINT "NONOGRAM is designed to solve the range of NONOGRAM puzzles. It uses"
PRINT "various techniques to extract the best solution it can from the"
PRINT "available data. Not all NONOGRAMs have unique solutions - see user"
PRINT "manual or accompanying NONOGRAM.TXT file for more information."
PRINT
PRINT "Data is supplied in a standard formatted file. This data can then be"
PRINT "parsed to check for errors before attempting to solve the NONOGRAM."
PRINT
PRINT "The most commonly used  commands have  been assigned to the  function"
PRINT "keys, and are listed along the bottom of the screen.  A full  list of"
PRINT "commands can be obtained by using the 'COMM' function."
PRINT
PRINT "All commands are entered at the 'Activity?'  prompt by entering the"
PRINT "four character description and pressing <CR>."
PRINT
PRINT

' ***************************************************************************
END SUB

SUB Introduct
' ***************************************************************************
' This is the sub containing the introductory screen and some related
' information. The remainder of the user dialogue is handled in the main
' program structure.
'
' ---------------------------

CLS

PRINT
PRINT
PRINT
PRINT
PRINT "               NONOGRAM - The Nonogram solving program"
PRINT
PRINT
PRINT "                         Version 01.0"
PRINT
PRINT "                         MGD Software"
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT " Press any key to start......."

DO
LOOP WHILE INKEY$ = ""



CLS

PRINT
PRINT
PRINT " NONOGRAM Solver - Version 01.0"
PRINT
PRINT

' Set default parameters

Qst = 2: Ced = 2: Trf = 2: Frw = 2: Tst = 2
Mnu = 2: Dis = 2

Warnd = 0
SysWar = 1

OPEN "NONOGRAM.PRM" FOR INPUT AS #4
 IF (Warnd = 1) THEN GOTO EXITG
 INPUT #4, Mnu, Dis, Qst, Ced, Trf, Frw, Tst
 W = 0
 IF ((Mnu < 1) OR (Qst < 1) OR (Ced < 1) OR (Trf < 1)) THEN W = 1
 IF ((Mnu > 2) OR (Qst > 2) OR (Ced > 2) OR (Trf > 2)) THEN W = 1
 IF ((Frw < 1) OR (Tst < 1) OR (Dis < 1)) THEN W = 1
 IF ((Frw > 2) OR (Tst > 2) OR (Dis > 2)) THEN W = 1
 IF (W = 1) THEN
  PRINT "!! WARNING !! - Setup data file is corrupt or inaccurate"
  PRINT
  PRINT
 ELSE
  PRINT " Default options modified"
  PRINT
  PRINT
 END IF
CLOSE #4

SysWar = 0

EXITG:
' ***************************************************************************
END SUB

SUB ParseData (Disp)
' ***************************************************************************
' This sub parses the input data and can reveal potential errors.
'
' --------------------

Sum1 = 0
Sum2 = 0

FOR I = 1 TO 25
 FOR K = 1 TO 10
  Sum1 = Sum1 + Horiz(I, K)
 NEXT K
NEXT I

FOR I = 1 TO 20
 FOR K = 1 TO 10
  Sum2 = Sum2 + Verti(I, K)
 NEXT K
NEXT I

PRINT

IF Sum2 <> Sum1 THEN
 PRINT "WARNING"
 PRINT
 PRINT "  Data supplied is suspect and will not solve properly."
 PRINT
ELSEIF (Sum1 = 0 OR Sum2 = 0) THEN
 PRINT "  No data loaded in memory."
 PRINT
ELSEIF (Disp = 0) THEN
 PRINT "  Data supplied has passed this test.   ("; Sum2; "elements. )"
 PRINT
END IF

' ***************************************************************************
END SUB

SUB Pause
' ***************************************************************************
' This sub handles the Pause routinue - simple.
'
' -------------------------

DO
 A$ = INKEY$
LOOP WHILE A$ = ""

IF A$ = "Q" OR A$ = "q" THEN END
' ***************************************************************************
END SUB

SUB PlotPoint (I, J, T)
' ***************************************************************************
' This sub when given a coordinate (I,J) plots a point of type T at that
' point and enters the value of T in the grid array. Thus the grid array
' contains enough information to reconstruct the NONOGRAM solution after
' one has been found.
'
' ----------------------

IF Dis = 2 THEN
 LOCATE (4 + J), (3 + 2 * I)
ELSE
 LOCATE (2 + J), (3 + 2 * I)
END IF


IF T = 1 THEN
 PRINT "XX";
  IF Grid(I, J) <> 1 AND Grid(I, J) <> 0 THEN Warning I, J, Grid(I, J), 1
  IF Grid(I, J) = 0 THEN PlotTotal = PlotTotal + 1
  Grid(I, J) = 1
ELSEIF T = 2 THEN
 IF Dis = 2 THEN COLOR 2
  PRINT "..";
 IF Dis = 2 THEN COLOR 15
  IF Grid(I, J) = 0 THEN PlotTotal = PlotTotal + 1
  IF Grid(I, J) <> 2 AND Grid(I, J) <> 0 THEN Warning I, J, Grid(I, J), 2
  Grid(I, J) = 2
END IF

' ***************************************************************************
END SUB

SUB QuickData
' ***************************************************************************
' This sub checks to see if any easy killings can made on the data grid
' array. (ie obvious lines with only one possible block combination)
' If there are it then calls the appropriate subroutines to carry out the
' actual filling work.
'
' -----------------------

FOR I = 1 TO 20
Tot = 0
FOR J = 1 TO 10
 IF Verti(I, J) > 0 THEN Tot = Tot + 1 + Verti(I, J)
NEXT J
 Tot = Tot - 1
 IF Tot = 25 THEN EasyFill I, 0
 IF Tot > 12 THEN FillDot I, 0, Tot
NEXT I

FOR I = 1 TO 25
Tot = 0
FOR J = 1 TO 10
 IF Horiz(I, J) > 0 THEN Tot = Tot + 1 + Horiz(I, J)
NEXT J
 Tot = Tot - 1
 IF Tot = 20 THEN EasyFill I, 1
 IF Tot > 12 THEN FillDot I, 1, Tot
NEXT I

' ***************************************************************************
END SUB

SUB ReadData (FileNam$)
' ***************************************************************************
' This sub is the data retrieval sub - the parameter (string) passed to it
' contains the filename to be read in. The error handling for this sub is
' covered in the 'HANDLER' section at the end of the main program.
'
' ---------------------------------


Warnd = 0: DotFnd = 0


 FOR I = 1 TO LEN(FileNam$)
  T = ASC(MID$(FileNam$, I, 1))
  IF ((T < 123) AND (T > 96)) THEN T = T - 32
  T$ = CHR$(T)
  MID$(FileNam$, I, 1) = T$
  IF T$ = "." THEN DotFnd = 1
 NEXT I

 IF DotFnd = 0 THEN FileNam$ = FileNam$ + ".NGM"

OPEN FileNam$ FOR INPUT AS 1
IF (Warnd = 1) THEN GOTO Exst

I = 1: J = 1: K = 0: Solved = 0
FileLen = LOF(1)

 ' Read one title line.

 LINE INPUT #1, Title$

 ' Clear old network data.

 FOR L = 1 TO 26
  FOR M = 1 TO 10
   Horiz(L, M) = 0
  NEXT M
 NEXT L

 FOR L = 1 TO 20
  FOR M = 1 TO 10
   Verti(L, M) = 0
  NEXT M
 NEXT L

 ' Read network Data.

DO
INPUT #1, A
IF (A <> 99) THEN
  IF K = 0 THEN
   Verti(I, J) = A
'   PRINT "Verti", I, J, K, A
  ELSE
   Horiz(I, J) = A
'   PRINT "Horiz", I, J, K, A
  END IF
 J = J + 1
ELSE
 J = 1
 IF I = 20 AND K = 0 THEN I = 0: K = 1
 I = I + 1
END IF
LOOP UNTIL EOF(1) OR A = 999


CLOSE #1

Exst:

' ***************************************************************************
END SUB

SUB Testing
' ***************************************************************************
' This sub considers all the possible arrangements of a row of dots and then
' comes to a conclusion about how the row must arranged. This is also by far
' the most important sub in this program.
'
' ----------------------------


DIM Possi(25)
DIM Poten(25, 200)
DIM Start(10)


FOR I = 1 TO 20

 IF Down(I) <> 1 THEN

 PotenPl = 1: Notfin = 1: More = 0
 
  T = -1
  DO
   T = T + 1
  LOOP UNTIL Verti(I, T + 1) = 0

    Start(1) = 1
    FOR M = 1 TO T - 1
     Start(M + 1) = Start(M) + Verti(I, M) + 1
    NEXT M

   DO

    FOR M = 1 TO 25           ' Overwrite previous temporary possibility
     Possi(M) = 2             ' array.
    NEXT M

    FOR M = 1 TO T
     FOR N = Start(M) TO (Start(M) + Verti(I, M) - 1)
      Possi(N) = 1
     NEXT N
    NEXT M

    'Compare Possi array with actual data

    Flag = 0
    FOR P = 1 TO 25
      A = Possi(P): B = Grid(P, I)
      IF A = 1 AND B = 2 THEN Flag = 1
      IF A = 2 AND B = 1 THEN Flag = 1
    NEXT P
   
    IF Flag = 0 THEN
     FOR Q = 1 TO 25
'      LOCATE 1, 1
'      PRINT "Across"; Q, PotenPl
      Poten(Q, PotenPl) = Possi(Q)
     NEXT Q
      PotenPl = PotenPl + 1
      IF PotenPl > ComSize THEN Notfin = 0: More = 1
    END IF


    v = T

Getit:
    Start(v) = Start(v) + 1
     Finish = Start(v) - 1
     FOR R = v TO T
      Finish = Finish + Verti(I, R) + 1
     NEXT R
     Finish = Finish - 1

     U = v
     DO WHILE U < T
      Start(U + 1) = Start(U) + 1 + Verti(I, U)
      U = U + 1
     LOOP

    IF Finish > 25 THEN
     v = v - 1
      IF v > 0 THEN
       GOTO Getit
      ELSE
       Notfin = 0
      END IF
    END IF

   LOOP WHILE Notfin = 1

   IF More = 0 THEN
    FOR C = 1 TO 25
     Comp = Poten(C, 1)
     FOR D = 2 TO (PotenPl - 1) STEP 1
      IF Comp <> Poten(C, D) THEN Comp = 0
     NEXT D
      IF Comp <> 0 THEN
       IF Comp = 2 THEN PlotPoint C, I, 2
       IF Comp = 1 THEN PlotPoint C, I, 1
      END IF
    NEXT C
   END IF


 END IF
NEXT I

'Now work across the data set

FOR I = 1 TO 25

 IF Across(I) <> 1 THEN

 PotenPl = 1: Notfin = 1: More = 0

  T = -1
  DO
   T = T + 1
  LOOP UNTIL Horiz(I, T + 1) = 0

    Start(1) = 1
    FOR M = 1 TO T - 1
     Start(M + 1) = Start(M) + Horiz(I, M) + 1
    NEXT M

   DO

    FOR M = 1 TO 20           ' Overwrite previous temporary possibility
     Possi(M) = 2             ' array.
    NEXT M

    FOR M = 1 TO T
     FOR N = Start(M) TO (Start(M) + Horiz(I, M) - 1)
      Possi(N) = 1
     NEXT N
    NEXT M

    'Compare Possi array with actual data

    Flag = 0
    FOR P = 1 TO 20
      A = Possi(P): B = Grid(I, P)
      IF A = 1 AND B = 2 THEN Flag = 1
      IF A = 2 AND B = 1 THEN Flag = 1
    NEXT P
  
    IF Flag = 0 THEN
     FOR Q = 1 TO 20
'      LOCATE 1, 1
'      PRINT "Down"; Q, PotenPl
      Poten(Q, PotenPl) = Possi(Q)
     NEXT Q
      PotenPl = PotenPl + 1
      IF PotenPl > ComSize THEN Notfin = 0: More = 1
    END IF


    v = T

Getit2:
    Start(v) = Start(v) + 1
     Finish = Start(v) - 1
     FOR R = v TO T
      Finish = Finish + Horiz(I, R) + 1
     NEXT R
     Finish = Finish - 1

     U = v
     DO WHILE U < T
      Start(U + 1) = Start(U) + 1 + Horiz(I, U)
      U = U + 1
     LOOP

    IF Finish > 20 THEN
     v = v - 1
      IF v > 0 THEN
       GOTO Getit2
      ELSE
       Notfin = 0
      END IF
    END IF

   LOOP WHILE Notfin = 1

   IF More = 0 THEN
    FOR C = 1 TO 20
     Comp = Poten(C, 1)
     FOR D = 2 TO (PotenPl - 1) STEP 1
      IF Comp <> Poten(C, D) THEN Comp = 0
     NEXT D
      IF Comp <> 0 THEN
       IF Comp = 2 THEN PlotPoint I, C, 2
       IF Comp = 1 THEN PlotPoint I, C, 1
      END IF
    NEXT C
   END IF

 END IF
NEXT I

END SUB

SUB TestRowFull
' ***************************************************************************
' This sub checks to see if all the 'XX' blocks in a row are fully filled in.
' If they are it then fills in the intervening gaps with dots.
'
' -----------------------


DIM Dot(10)

FOR I = 1 TO 20
Total = 0: Postn = 1: Ok = 1
FOR S = 1 TO 10
 Dot(S) = 0
NEXT S
 FOR J = 1 TO 25
  Value = Grid(J, I)
  IF Value = 1 THEN
   Total = Total + 1
  ELSE
    IF Total > 0 THEN
     Dot(Postn) = Total
     Postn = Postn + 1
     IF Postn > 10 THEN Postn = 1: Ok = 0
    END IF
   Total = 0
  END IF
 NEXT J
 IF Total > 0 THEN Dot(Postn) = Total

  FOR S = 1 TO 10
   IF Dot(S) <> Verti(I, S) THEN Ok = 0
  NEXT S

 IF Ok = 1 THEN
  FOR K = 1 TO 25
   IF Grid(K, I) <> 1 THEN PlotPoint K, I, 2
  NEXT K
 Down(I) = 1
 END IF
NEXT I



FOR I = 1 TO 25
Total = 0: Postn = 1: Ok = 1
FOR S = 1 TO 10
 Dot(S) = 0
NEXT S
 FOR J = 1 TO 20
  Value = Grid(I, J)
  IF Value = 1 THEN
   Total = Total + 1
  ELSE
    IF Total > 0 THEN
     Dot(Postn) = Total
     Postn = Postn + 1
     IF Postn > 10 THEN Postn = 1: Ok = 0
    END IF
   Total = 0
  END IF
 NEXT J
 IF Total > 0 THEN Dot(Postn) = Total

  FOR S = 1 TO 10
   IF Dot(S) <> Horiz(I, S) THEN Ok = 0
  NEXT S

  IF Ok = 1 THEN
    FOR K = 1 TO 20
     IF Grid(I, K) <> 1 THEN PlotPoint I, K, 2
    NEXT K
  Across(I) = 1
  END IF
NEXT I

' ***************************************************************************
END SUB

SUB Update
' ***************************************************************************
' This sub updates the display in the top right hand corner of the solution
' display - the number displayed indicates how many points are left to be
' found. Initially this value is 500.
'
' --------------------------

 LOCATE 1, 75
 PRINT 500 - PlotTotal

' ***************************************************************************
END SUB

SUB VarSize
' ***************************************************************************
' This sub allows a user to change the size of some of the variable arrays.
' While changing them from the optimum values will not speed up the solution
' they may allow solutions to be found for previously unsolvable NONOGRAMs
'
' --------------------------

PRINT
PRINT " The current program configuration is - "
PRINT
PRINT "  Combination array size (< 200) - ";
PRINT ComSize;
  INPUT ; " - Now - "; T
   IF (T > 0) AND (T < 201) THEN
    ComSize = T: PRINT "   Changed to"; ComSize
    Solved = 0
   ELSE
    PRINT "   Invalid entry - not changed"
   END IF
PRINT

' ***************************************************************************
END SUB

SUB Warning (I, J, Old, New)
' ***************************************************************************
' If a data overwrite (ie a value of Grid is being changed from 1 to 2 or
' vice-versa) this sub is called into action and warns the user of what is
' happening.
'
' ----------------------------


LOCATE 2, 1
IF Dis = 2 THEN COLOR 12
PRINT "Warning - Data Overwrite In Progress"
PRINT "At (I,J) "; I; J; " from "; Old; "to"; New; "Any key to resume"
Pause
IF Dis = 2 THEN COLOR 15

' ***************************************************************************
END SUB

