PROGRAM Nonogram;

(* PROGRAM DESCRIPTION
*  ===================
*
*  This program solves NONOGRAM puzzles.
*
*
*  PROGRAM INFORMATION
*  ===================
*  Author   : MGD
*  Date     : 15/08/1993
*  Version  : 01.2
*  Language : PASCAL
*)

{$R NONOGRAM.RES}
{$M 40000, 8192}

USES WinTypes, WinProcs, WObjects, StdDlgs, WinDos, Strings, BWCC;
   
VAR
      (* General variables *)
      BoolQStart : BOOLEAN;
      BoolECheck : BOOLEAN;
      BoolFRowTs : BOOLEAN;
      BoolRowFol : BOOLEAN;
      BoolCombin : BOOLEAN;
      TempQStart : BOOLEAN;
      TempECheck : BOOLEAN;
      TempFRowTs : BOOLEAN;
      TempRowFol : BOOLEAN;
      TempCombin : BOOLEAN;
      BoolZeroDg : BOOLEAN;
      BoolNineDg : BOOLEAN;
      BoolOneEDg : BOOLEAN;
      BoolTwoSDg : BOOLEAN;
      BoolFlipDg : BOOLEAN;
      TempZeroDg : BOOLEAN;
      TempNineDg : BOOLEAN;
      TempOneEDg : BOOLEAN;
      TempTwoSDg : BOOLEAN;
      TempFlipDg : BOOLEAN;
      FilTitle   : array [0..80] of CHAR;
      Horiz      : array [0..26, 0..10] of INTEGER;
      Verti      : array [0..20, 0..10] of INTEGER;
      Grid       : array [0..26, 0..21] of INTEGER;
      Across     : array [0..25] of INTEGER;
      Down       : array [0..20] of INTEGER;
      OldTotal   : INTEGER;
      PlotTotal  : INTEGER;
      ComSize    : INTEGER;
      SolTime    : LONGINT;
      HelpFileNm : PChar;
      WaitCursor : HCursor;
      ArrwCursor : HCursor;


CONST
      (* Menu constants *)
      ID_New    = 101;
      ID_Load   = 102;
      ID_Print  = 103;
      ID_Exit   = 104;
      ID_Config = 201;
      ID_Displ  = 202;
      ID_Solve  = 203;
      ID_Parse  = 204;
      ID_QStart = 501;
      ID_ECheck = 502;
      ID_FRowTs = 503;
      ID_RowFol = 504;
      ID_Combin = 505;
      ID_Vars   = 506;
      ID_DiaHlp = 998;
      ID_ZeroDg = 530;
      ID_NineDg = 531;
      ID_OneEDg = 532;
      ID_TwoSDg = 533;
      ID_Flip   = 534;
      ID_Cntnts = 901;
      ID_Intro  = 902;
      ID_DataF  = 903;
      ID_HOnH   = 904;
      ID_About  = 999;

      (* Help Constants *)
      HC_Intro  = 1;
      HC_DataF  = 2;
      HC_Sltn   = 3;
      HC_Dsplay = 4;
      
      (* Other Constants *)
      ExeNameMaxSize = 128;


TYPE
     PMenuApp = ^TMenuApp;
     TMenuApp = OBJECT (TApplication)
       CONSTRUCTOR Init(AName: PChar);
       PROCEDURE   InitMainWindow; virtual;
     END;


     PConfigWin = ^TConfigWin;
     TConfigWin = OBJECT(TDialog)
       Check1, Check2, Check3 : PCheckBox;
       Check4, Check5 : PCheckBox;
       Field : PEdit;

        CONSTRUCTOR Init (AParent: PWindowsObject; AName : PChar);
        PROCEDURE   SetupWindow; virtual;
        PROCEDURE   OK (VAR Msg : TMessage);
                    virtual ID_First + ID_OK; 
        PROCEDURE   QStart (VAR Msg : TMessage);
                    virtual ID_First + ID_QStart;
        PROCEDURE   ECheck (VAR Msg : TMessage);
                    virtual ID_First + ID_ECheck;
        PROCEDURE   FRowTs (VAR Msg : TMessage);
                    virtual ID_First + ID_FRowTs;
        PROCEDURE   RowFol (VAR Msg : TMessage);
                    virtual ID_First + ID_RowFol;
        PROCEDURE   Combin (VAR Msg : TMessage);
                    virtual ID_First + ID_Combin;
        PROCEDURE   DiaHlp (VAR Msg : TMessage);
                    virtual ID_First + ID_DiaHlp;
        END;



     PDisplWin = ^TDisplWin;
     TDisplWin = OBJECT(TDialog)
        Rad1, Rad2, Rad3, Rad4 : PRadioButton;
        Chk1 : PCheckBox;

        CONSTRUCTOR Init (AParent: PWindowsObject; AName : PChar);
        PROCEDURE   SetupWindow; virtual;
        PROCEDURE   OK (VAR Msg : TMessage);
                    virtual ID_First + ID_OK; 
        PROCEDURE   ZeroDg (VAR Msg : TMessage);
                    virtual ID_First + ID_ZeroDg;
        PROCEDURE   NineDg (VAR Msg : TMessage);
                    virtual ID_First + ID_NineDg;
        PROCEDURE   OneEDg (VAR Msg : TMessage);
                    virtual ID_First + ID_OneEDg;
        PROCEDURE   TwoSDg (VAR Msg : TMessage);
                    virtual ID_First + ID_TwoSDg;
        PROCEDURE   Flip (VAR Msg : TMessage);
                    virtual ID_First + ID_Flip;
        PROCEDURE   DiaHlp (VAR Msg : TMessage);
                    virtual ID_First + ID_DiaHlp;
        END;


     PMainWin = ^TMainWin;
     TMainWin = OBJECT(TWindow)
       Sum1, Sum2   : INTEGER;
       TheDC        : HDC;
       TheDevice    : TPaintStruct;
       Filename     : ARRAY[0..fsPathName] OF CHAR;
       ThePen       : HPen;
       BackBrush    : HBrush;
       BlockBrush   : HBrush;
       DotBrush     : HBrush;
       TBackBrush   : TLogBrush;
       TBlockBrush  : TLogBrush;
       TDotBrush    : TLogBrush;

        CONSTRUCTOR Init (AParent : PWindowsObject; ATitle : PChar);
        DESTRUCTOR  Done; virtual;
        PROCEDURE   GetWindowClass (VAR AWndClass : TWndClass);
                    virtual;
        PROCEDURE   FileNew (VAR Msg : TMessage);
                    virtual CM_First + ID_New;
        PROCEDURE   FileLoad (VAR Msg : TMessage);
                    virtual CM_First + ID_Load;
        PROCEDURE   FilePrint (VAR Msg : TMessage);
                    virtual CM_First + ID_Print;
        PROCEDURE   FileExit (VAR Msg : TMessage);
                    virtual CM_First + ID_Exit;
        PROCEDURE   Config (VAR Msg : TMessage);
                    virtual CM_First + ID_Config;
        PROCEDURE   Displ (VAR Msg : TMessage);
                    virtual CM_First + ID_Displ;
        PROCEDURE   Solve (VAR Msg : TMessage);
                    virtual CM_First + ID_Solve;
        PROCEDURE   Parse (VAR Msg : TMessage);
                    virtual CM_First + ID_Parse;
        PROCEDURE   Cntnts (VAR Msg : TMessage);
                    virtual CM_First + ID_Cntnts;
        PROCEDURE   Intro (VAR Msg : TMessage);
                    virtual CM_First + ID_Intro;
        PROCEDURE   DataF (VAR Msg : TMessage);
                    virtual CM_First + ID_DataF;
        PROCEDURE   HOnH (VAR Msg : TMessage);
                    virtual CM_First + ID_HOnH;
        PROCEDURE   About (VAR Msg : TMessage);
                    virtual CM_First + ID_About;
        PROCEDURE   FileNewImplement;
        PROCEDURE   FileLoadImplement;
        PROCEDURE   DrawPoint(I, J, BlockDot : INTEGER; All: BOOLEAN);
        PROCEDURE   Paint (PaintDC : HDC; var PaintInfo : TPaintStruct);
                    virtual;
        PROCEDURE   ParseData (Displa : INTEGER);
        PROCEDURE   QuickData;
        PROCEDURE   CheckEdge;
        PROCEDURE   TestRowFull;
        PROCEDURE   FollowRow;
        PROCEDURE   Combination;
        PROCEDURE   Update;
        PROCEDURE   EasyFill (I, K : INTEGER);
        PROCEDURE   FillDot  (Iin, Kin, STot : INTEGER);
        END;

  

(**********************************************************************)

(* Methods of TMainWin from here onwards................................*)


CONSTRUCTOR TMainWin.Init (AParent : PWindowsObject; ATitle : PChar);
VAR
    FileNameLen : INTEGER;
    FileName2   : array [0..ExeNameMaxSize + 1] of CHAR;
    I           : INTEGER;
BEGIN
  (* Initialise program *)
  TWindow.Init (AParent, ATitle);
  Attr.Menu := LoadMenu (HInstance, 'MenuBar');
  Attr.w := 600;
  Attr.h := 450;
  SolTime := 0;
  BoolQStart := TRUE;
  BoolECheck := TRUE;
  BoolFRowTs := TRUE;
  BoolRowFol := TRUE;
  BoolCombin := TRUE;
  BoolZeroDg := TRUE;
  BoolNineDg := FALSE;
  BoolOneEDg := FALSE;
  BoolTwoSDg := FALSE;
  BoolFlipDg := FALSE;
  ComSize    := 20;

  (* Create brushes *)
  WITH TBackBrush DO
  BEGIN
    lbStyle := bs_solid;
    lbColor := $00FF0000;
    lbHatch := 0;
  END;
  WITH TDotBrush DO
  BEGIN
    lbStyle := bs_solid;
    lbColor := $00808080;
    lbHatch := 0;
  END;
  WITH TBlockBrush DO
  BEGIN
    lbStyle := bs_solid;
    lbColor := $00FFFFFF;
    lbHatch := 0;
  END;
  ThePen := CreatePen(ps_solid, 1, 0);
  BackBrush := CreateBrushIndirect(TBackBrush);
  BlockBrush := CreateBrushIndirect(TBlockBrush);
  DotBrush := CreateBrushIndirect(TDotBrush); 

  (* Load Cursors *)
  WaitCursor := LoadCursor(0, IDC_WAIT);
  ArrwCursor := LoadCursor(0, IDC_ARROW);

  (* Construct HelpFileName *)
  FileNameLen := GetModuleFileName(HInstance, FileName2, ExeNameMaxSize);
  I := FileNameLen -1;
  WHILE (I <> 0) AND ((FileName2[I] <> '\') AND (FileName2[I] <> ':')) DO
    DEC(I);
    INC(I);
   IF (I + 13) <= ExeNameMaxSize THEN
     StrCopy(@FileName2[I], 'NONOGRAM.HLP')
   ELSE
     StrCopy(@FileName2[I], '?');
   HelpFileNm := StrNew(FileName2);
END;


DESTRUCTOR TMainWin.Done;
BEGIN
  (* Tidy up and dispose of everything *)
  WinHelp (HWindow, HelpFileNm, Help_Quit, 0);
  DeleteObject(BackBrush);
  DeleteObject(BlockBrush);
  DeleteObject(DotBrush);
  DeleteObject(ThePen);
  StrDispose(HelpFileNm);
  TWindow.Done;
END;

PROCEDURE TMainWin.GetWindowClass (VAR AWndClass : TWndClass);
BEGIN
  TWindow.GetWindowClass (AWndClass);
  AWndClass.HIcon := LoadIcon (HInstance, 'TheIcon');
END;


PROCEDURE TMainWin.FileNew (VAR Msg : TMessage);
VAR
    I, J : INTEGER;
BEGIN
  (* Reset storage arrays *)
  FOR I := 1 TO 25 DO
    FOR J := 1 TO 10 DO
      Horiz[I, J] :=0;
  FOR I := 1 TO 20 DO
    FOR J := 1 TO 10 DO
      Verti[I, J] := 0;

  SolTime := 0;

  FOR I := 1 TO 25 DO
    FOR J := 1 TO 20 DO
      Grid[I, J] := 0;
  FOR I := 1 TO 25 DO
    Across[I] := 0;
  FOR I := 1 TO 20 DO
    Down[I] := 0;

  SetWindowText(HWindow, 'Nonogram Solver - [none]');
  InvalidateRect(HWindow, nil, True);
END;


PROCEDURE TMainWin.FileLoad (VAR Msg : TMessage);
BEGIN
  IF Application^.ExecDialog(New(PFileDialog,
     Init(@self, PChar(sd_FileOpen),
     StrCopy(FileName,'*.NGM')))) = id_OK then
  FileLoadImplement;
END;


PROCEDURE TMainWin.FilePrint (VAR Msg : TMessage);
VAR
     Entry      : array [0..64] of CHAR;
     TextString : array [0..80] of CHAR;
     Printer    : PChar;
     Driver     : PChar;
     Port       : PChar;
     PrinterDC  : HDC;
     XRes, YRes : INTEGER;
     TextSp     : INTEGER;
     Pnt, LeftM : INTEGER;
     XVal, YVal : INTEGER;
     I, J, K    : INTEGER;
     M, N       : INTEGER;
BEGIN
  GetProfileString ('windows', 'device', '', Entry, 64);
  Printer := Entry;

  Driver := StrScan (Printer, ',');
  Driver^ := #0;
  Inc (Driver);

  Port := StrScan (Driver, ',');
  Port^ := #0;
  Inc (Port);

  PrinterDC := CreateDC (Driver, Printer, Port, nil);

  IF (PrinterDC = 0) THEN
   BEGIN
     MessageBox (HWindow, 'Cannot print Nonogram!!!', 'Printer Error', mb_IconStop);
   END
  ELSE
   BEGIN
     Escape (PrinterDC, STARTDOC, 17, PChar ('Nonogram-Printout'), nil);

     XRes := GetDeviceCaps (PrinterDC, HORZRES);
     YRes := GetDeviceCaps (PrinterDC, VERTRES);
     TextSp := YRes DIV 64;

     StrCopy(TextString, 'The Nonogram Solver - Version 01.0');
     TextOut(PrinterDC, 10, (TextSp), TextString, StrLen(TextString));
     StrCopy(TextString, '==================================');
     TextOut(PrinterDC, 10, (2 * TextSp), TextString, StrLen(TextString));
     TextOut(PrinterDC, 10, (5 * TextSp), FilTitle, StrLen(FilTitle));
     StrCopy(TextString, 'Time for solution: ');
     TextOut(PrinterDC, 10, (6 * TextSp), TextString, StrLen(TextString));
     IF (SolTime = 0) THEN
      BEGIN
        StrCopy(TextString, 'Not Solved');
      END
     ELSE
      BEGIN
        Str(SolTime, TextString);
      END;
     TextOut(PrinterDC, 600, (6 * TextSp), TextString, StrLen(TextString));

     Pnt := XRes DIV 100;
     LeftM := 10 * Pnt;

     XVal := 1000;
     YVal := 1000;

     FOR I := 1 TO 25 DO
      BEGIN
       FOR J := 1 TO 20 DO
        BEGIN
         IF (BoolFlipDg) THEN K := (26 - I)
         ELSE K := I;

        IF ((BoolZeroDg) OR (BoolNineDg)) THEN
        BEGIN
          M := J;
          N := (26 - K);
        END;

        IF ((BoolOneEDg) OR (BoolTwoSDg)) THEN
        BEGIN
          M := (21 - J);
          N := K;
        END;

        XVal := LeftM + (M - 1) * 4 * Pnt;
        YVal := (10 * TextSp) + (N - 1) * 4 * Pnt;
        IF (Grid[I, J] = 1) THEN
         BEGIN
           SelectObject(PrinterDC, BackBrush);
           Rectangle(PrinterDC, XVal, YVal, (XVal + 4 * Pnt),
                     (YVal + 4 * Pnt));
         END
        ELSE
         BEGIN
           SelectObject(PrinterDC, BlockBrush);
           Rectangle(PrinterDC, XVal, YVal, (XVal + 4 * Pnt),
                     (YVal + 4 * Pnt));
         END;
       END;
     END;

    Escape (PrinterDC, NEWFRAME, 0, nil, nil);
    Escape (PrinterDC, ENDDOC, 0, nil, nil);
    DeleteDC (PrinterDC);


   END;
END;


PROCEDURE TMainWin.FileExit (VAR Msg : TMessage);
BEGIN
  TMainWin.Done;
END;


PROCEDURE TMainWin.Config (VAR Msg : TMessage);
BEGIN           
  Application^.ExecDialog(New(PConfigWin, Init(@self, 'SolveBox')));
END;


PROCEDURE TMainWin.Displ (VAR Msg : TMessage);
BEGIN
  Application^.ExecDialog(New(PDisplWin, Init(@self, 'DisplayBox')));
  InvalidateRect(HWindow, nil, True);
END;


PROCEDURE TMainWin.Solve (VAR Msg : TMessage);
VAR
    I, J       : INTEGER;
    LocRound   : INTEGER;
    TextString : array[0..80] of CHAR;
    Strt, Fin  : LONGINT;
BEGIN
  SetCursor(WaitCursor);
  ParseData (1);
  IF ((Sum1 <> Sum2) OR (Sum1 = 0) OR (Sum2 = 0)) THEN EXIT;
  FOR I := 1 TO 25 DO
  BEGIN
   FOR J := 1 TO 20 DO
    Grid[I, J] := 0;
   Across[I] := 0;
  END;                                          
                   
  FOR I := 1 TO 20 DO
   Down[I] := 0;

  (* Fill in calculated data stored in the GRID array *)

  FOR J := 1 TO 20 DO
  BEGIN
   FOR I := 1 TO 25 DO
   BEGIN
    DrawPoint(I, J, 0, TRUE);
   END;
  END; 

  TheDC := GetDC(HWindow);
   SetBkColor(TheDC, $00808080);
   SetTextColor(TheDC, $00F0F0F0);
   StrCopy(TextString, 'Solve Time (ms) :                ');
   TextOut(TheDC, 410, 20, TextString, StrLen(TextString));
   Str(SolTime, TextString);
   TextOut(TheDC, 530, 20, TextString, StrLen(TextString));
   StrCopy(TextString, 'Points Found      :                ');
   TextOut(TheDC, 410, 40, TextString, StrLen(TextString));
  ReleaseDC(HWindow, TheDC);

  SolTime   := 0;
  Strt := GetTickCount;

  OldTotal := -1;
  PlotTotal := 0;

  IF (BoolQStart) THEN QuickData;

  WHILE (OldTotal <> PlotTotal) DO
  BEGIN
    OldTotal := PlotTotal;
    Update;
    IF (BoolECheck) THEN CheckEdge;
    IF (BoolFRowTs) THEN TestRowFull;
    IF (BoolRowFol) THEN FollowRow;
    IF (BoolCombin) THEN Combination;
  END;

  Fin := GetTickCount;

  Update;
  SolTime := Fin - Strt;

  TheDC := GetDC(HWindow);
   SetBkColor(TheDC, $00808080);
   SetTextColor(TheDC, $00F0F0F0);
   StrCopy(TextString, 'Solve Time (ms) :                ');
   TextOut(TheDC, 410, 20, TextString, StrLen(TextString));
   Str(SolTime, TextString);
   TextOut(TheDC, 530, 20, TextString, StrLen(TextString));
  ReleaseDC(HWindow, TheDC);
  SetCursor(ArrwCursor);

  IF (PlotTotal = 500) THEN
   BEGIN
    MessageBox(HWindow, 'Successfully finished', 'Solve:', mb_IconInformation);
   END
  ELSE
   BEGIN
    MessageBox(HWindow, 'Finished', 'Solve:', mb_IconInformation);
   END;
END;


PROCEDURE TMainWin.Parse (VAR Msg : TMessage);
BEGIN
  ParseData (0);
END;


PROCEDURE TMainWin.Cntnts (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_Index, 0);
END;


PROCEDURE TMainWin.Intro (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_Context, HC_Intro);
END;


PROCEDURE TMainWin.DataF (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_Context, HC_DataF);
END;


PROCEDURE TMainWin.HOnH (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_HelpOnHelp, 0);
END;


PROCEDURE TMainWin.About (VAR Msg : TMessage);
VAR
    AboutDlg : PDialog;
BEGIN
  AboutDlg := New (PDialog, Init (@self, 'AboutBox'));
  AboutDlg^.Execute;
  Dispose (AboutDlg, Done);
END;


PROCEDURE TMainWin.FileNewImplement;
VAR
     I,J : INTEGER;
BEGIN
  SolTime := 0;

  FOR I := 1 TO 25 DO
   FOR J := 1 TO 20 DO
    Grid[I, J] := 0;

  FOR I := 1 TO 25 DO
   Across[I] := 0;

  FOR I := 1 TO 20 DO
   Down[I] := 0;

  InvalidateRect(HWindow, nil, True);
END;


PROCEDURE TMainWin.FileLoadImplement;
VAR
    File1   : TEXT;
    A,I,J,K : INTEGER;
    TextString: ARRAY [0..60] OF CHAR;
BEGIN
  FOR I := 1 TO 25 DO
   FOR J := 1 TO 20 DO
    Grid[I, J] := 0;

  SolTime := 0;

  InvalidateRect(HWindow, nil, True);

  Assign(File1, Filename);
  Reset(File1);
  ReadLn(File1, FilTitle);

   FOR I := 0 TO 21 DO
    FOR J := 1 TO 10 DO
     Verti[I, J] := 0;

   FOR I := 0 TO 26 DO
    FOR J := 1 TO 10 DO
     Horiz[I, J] := 0;

   I := 1; J := 1; K :=0;

   WHILE NOT EOF(File1) DO
   BEGIN
    Read(File1, A);
     IF (A <> 99) THEN
      BEGIN
       IF (K = 0) THEN Verti[I, J] := A
       ELSE Horiz[I, J] := A;
       J := J + 1;              
      END
     ELSE
      BEGIN
       J := 1;
       IF ((I = 20) AND (K = 0)) THEN
        BEGIN
         I := 0;
         K := 1;
        END;
       I := I + 1;
      END;
   END;

   Close(File1);
   StrCopy(TextString, 'Nonogram Solver - [');                     
   StrCat(TextString, FileName);
   StrCat(TextString, ']');
   SetWindowText(HWindow, TextString);
   MessageBox (HWindow, FilTitle, 'Selection:', MB_ICONINFORMATION);
END;

               
PROCEDURE TMainWin.DrawPoint(I, J, BlockDot : INTEGER; All: BOOLEAN);
VAR
     TextString : array[0..2] of CHAR;
     TextStrinh : array[0..3] of CHAR;
     XVal, YVal : INTEGER;
     M, N, K    : INTEGER;
BEGIN
  IF ((I < 1) OR (I > 25)) THEN EXIT;
  IF ((J < 1) OR (J > 20)) THEN EXIT;
  IF ((Grid[I, J] > 0) AND NOT(All)) THEN EXIT;

  IF (BoolFlipDg) THEN K := (26 - I)
  ELSE K := I;

  IF (BoolZeroDg) THEN
   BEGIN
    M := J;
    N := (26 - K);
   END;

  IF (BoolNineDg) THEN
   BEGIN
    M := (26 - K);
    N := (21 - J);
   END;

   IF (BoolOneEDg) THEN
    BEGIN
     M := (21 - J);
     N := K;
    END;

   IF (BoolTwoSDg) THEN
    BEGIN
     M := K;
     N := J;
    END;

  XVal := 22 + 14 * M;
  YVal := 14 * N;
  TheDC := GetDC(HWindow);

   IF (BlockDot = 0) THEN
    BEGIN
     SelectObject(TheDC, BackBrush);
     Rectangle(TheDC, XVal, YVal, (XVal + 14), (YVal + 14));
    END;

   IF (BlockDot = 1) THEN
    BEGIN
     IF (Grid[I, J] = 0) THEN PlotTotal := PlotTotal + 1;
     SelectObject(TheDC, BlockBrush);
     Rectangle(TheDC, XVal, YVal, (XVal + 14), (YVal + 14));
     Grid[I, J] := 1;
    END;
   
   IF (BlockDot = 2) THEN
    BEGIN
     IF (Grid[I, J] = 0) THEN PlotTotal := PlotTotal + 1;
     SelectObject(TheDC, DotBrush);
     Rectangle(TheDC, XVal, YVal, (XVal + 14), (YVal + 14));
     Grid[I, J] := 2;
    END;

  ReleaseDC(HWindow, TheDC);
END;


PROCEDURE TMainWin.Paint(PaintDC : HDC; var PaintInfo: TPaintStruct);
VAR
     TextString : array [0..80] of CHAR;
     ValsString : array [0..2] of CHAR;
     ValueInt   : LONGINT;
     OffSet     : INTEGER;
     XPT, YPT   : INTEGER;
     OffSet2    : INTEGER;
     I, J       : INTEGER;
     BlockDot   : INTEGER;
     XVal, YVal : INTEGER;
     DownSize   : INTEGER;
     AlongSize  : INTEGER;
     DownOffSet : INTEGER;
BEGIN
  SetBkColor(PaintDC, $00808080);
  SetTextColor(PaintDC, $00F0F0F0);
  SelectObject(PaintDC, BackBrush);
  Rectangle(PaintDC, 10, 10, 405, 405);

  IF (BoolZeroDg OR BoolOneEDg) THEN
   BEGIN
    DownSize := 26;
    AlongSize := 21;
    DownOffSet := 370;
    StrCopy(TextString, '                                     ');
    TextOut(PaintDC, 34, 370, TextString, StrLen(TextString));
    TextOut(PaintDC, 162, 370, TextString, StrLen(TextString));
    TextOut(PaintDC, 162, 384, TextString, StrLen(TextString));
   END
  ELSE
   BEGIN
    DownSize := 21;
    AlongSize := 26;
    DownOffSet := 300;
    StrCopy(TextString, '                                                        ');
    TextOut(PaintDC, 34, 300, TextString, StrLen(TextString));
    TextOut(PaintDC, 162, 300, TextString, StrLen(TextString));
    TextOut(PaintDC, 162, 314, TextString, StrLen(TextString));
   END;

  ValueInt := 1;
  WHILE (ValueInt < DownSize) DO
  BEGIN
   Str(ValueInt, TextString);
    IF (ValueInt < 10) THEN OffSet := 23
    ELSE OffSet := 15;
   TextOut(PaintDC, OffSet, (14 * ValueInt), TextString, StrLen(TextString));
   ValueInt := ValueInt + 1;
  END;


  ValueInt := 1; OffSet := 0; OffSet2 := 9876;
  WHILE (ValueInt < AlongSize) DO
  BEGIN
   OffSet := ValueInt;
     IF ((ValueInt > 9) AND (ValueInt < 20)) THEN
      BEGIN
       OffSet2 := ValueInt - 10;
       OffSet := 1;
      END;
     IF (ValueInt > 19) THEN
      BEGIN
       OffSet2 := ValueInt - 20;
       OffSet := 2;
      END;
     Str(OffSet, TextString);
     XPT := 22 + 14*ValueInt;
     TextOut(PaintDC, XPT, DownOffSet, TextString, StrLen(TextString));
     ValueInt := ValueInt + 1;
     IF (OffSet = 1) THEN 
      BEGIN
       Str(OffSet2, TextString);
       XPT := 162 + 14*OffSet2;
       TextOut(PaintDC, XPT, (DownOffSet + 14), TextString, StrLen(TextString));
      END;
     IF (OffSet = 2) THEN
      BEGIN
       Str(OffSet2, TextString);
       XPT := 302 + 14*OffSet2;
       TextOut(PaintDC, XPT, (DownOffSet + 14), TextString, StrLen(TextString));
      END;
  END;

  (* Draw in user informtion *)

  StrCopy(TextString, 'Solve Time (ms) :                ');
  TextOut(PaintDC, 410, 20, TextString, StrLen(TextString));

  Str(SolTime, TextString);
  TextOut(PaintDC, 530, 20, TextString, StrLen(TextString));

  StrCopy(TextString, 'Points Found      :                ');
  TextOut(PaintDC, 410, 40, TextString, StrLen(TextString));

  Str(PlotTotal, TextString);
  TextOut(PaintDC, 530, 40, TextString, StrLen(TextString));

  (* Fill in calculated data stored in the GRID array *)

  FOR J := 1 TO 20 DO
  BEGIN
   FOR I := 1 TO 25 DO
   BEGIN
    DrawPoint(I, J, Grid[I, J], TRUE);
   END;
  END; 

END;


PROCEDURE TMainWin.ParseData (Displa : INTEGER);
VAR
     I, K       : INTEGER;
     TextString : array[0..40] of CHAR;
BEGIN
  Sum1 := 0; Sum2 := 0;

  FOR I := 1 TO 25 DO
   FOR K := 1 TO 10 DO
    Sum1 := Sum1 + Horiz[I, K];

  FOR I := 1 TO 20 DO
   FOR K := 1 TO 10 DO
    Sum2 := Sum2 + Verti[I, K];

  IF (Sum1 <> Sum2) THEN
   BEGIN
    MessageBox (HWindow, 'Data supplied is suspect', 'Warning:', mb_IconStop);
   END
  ELSE
   BEGIN
    IF ((Sum1 = 0) or (Sum2 = 0)) THEN 
     BEGIN
      IF (Displa = 0) THEN StrCopy(TextString, 'Parse Data:')
      ELSE StrCopy(TextString, 'Solve:');
      MessageBox (HWindow, 'No data loaded', TextString, mb_IconExclamation);
     END
    ELSE
     BEGIN
      IF (Displa = 0) THEN
       BEGIN
        MessageBox (HWindow, 'Test Passed', 'Parse Data:', mb_OK);
       END;  
     END;
   END;
END;


PROCEDURE TMainWin.QuickData;
VAR
    I, J : INTEGER;                       
    Tot  : INTEGER;
BEGIN
 FOR I := 1 TO 20 DO
 BEGIN
  Tot := 0;
   FOR J := 1 TO 10 DO
   BEGIN
    IF (Verti[I, J] > 0) THEN
     BEGIN
      Tot := Tot + 1 + Verti[I, J];
     END;
   END;
   Tot := Tot - 1;
   IF (Tot = 25) THEN EasyFill(I, 0);
   IF (Tot > 12) THEN FillDot(I, 0, Tot);
 END;

 FOR I := 1 TO 25 DO
 BEGIN
  Tot := 0;
   FOR J := 1 TO 10 DO
   BEGIN
    IF (Horiz[I, J] > 0) THEN
     BEGIN
      Tot := Tot + 1 + Horiz[I, J];
     END;
   END;
   Tot := Tot - 1;
   IF (Tot = 20) THEN EasyFill(I, 1);
   IF (Tot > 12) THEN FillDot(I, 1, Tot);
 END;

END;


PROCEDURE TMainWin.CheckEdge;
VAR
    I, J, T : INTEGER;
    Value, Temp : INTEGER;
BEGIN

 FOR I := 1 TO 25 DO
 BEGIN
  IF (Grid[I, 1] = 1) THEN
   BEGIN
    FOR J := 1 TO Horiz[I, 1] DO
     DrawPoint(I, J, 1, FALSE);
    J := Horiz[I, 1] + 1;
    DrawPoint(I, J, 2, FALSE);
   END;

  IF (Grid[I, 20] = 1) THEN
   BEGIN
    FOR T := 1 TO 10 DO
    BEGIN
     Temp := Horiz[I, T];
     IF (Temp > 0) THEN Value := Temp;
    END;
    FOR J := (21 - Value) TO 20 DO
     DrawPoint(I, J, 1, FALSE);
    DrawPoint(I, (20 - Value), 2, FALSE);
   END; 
 END;

 FOR I := 1 TO 20 DO
 BEGIN
  IF (Grid[1, I] = 1) THEN
   BEGIN
    FOR J := 1 TO Verti[I, 1] DO
     DrawPoint(J, I, 1, FALSE);
    DrawPoint((Verti[I, 1] + 1), I, 2, FALSE);
   END;

  IF (Grid[25, I] = 1) THEN
   BEGIN
    FOR T := 1 TO 10 DO
    BEGIN
     Temp := Verti[I, T];
     IF (Temp > 0) THEN Value := Temp;
    END;
    FOR J := (26 - Value) TO 25 DO
     DrawPoint(J, I, 1, FALSE);
    DrawPoint((25 - Value), I, 2, FALSE);
   END;
 END;
END;


PROCEDURE TMainWin.TestRowFull;
VAR
    Dot      : array [0..10] of INTEGER;
    I, J, S  : INTEGER;
    Value, K : INTEGER;
    Total    : INTEGER;
    Postn    : INTEGER;
    AOk      : INTEGER;
BEGIN

 FOR I := 1 TO 20 DO
 BEGIN
  Total := 0; Postn := 1; AOk := 1;
  FOR S := 1 TO 10 DO
   Dot[S] := 0;
  FOR J := 1 TO 25 DO
  BEGIN
   Value := Grid[J, I];
   IF (Value = 1) THEN
    BEGIN
     Total := Total + 1;
    END
   ELSE
    BEGIN
     IF (Total > 0) THEN
      BEGIN
       Dot[Postn] := Total;
       Postn := Postn + 1;
       IF (Postn > 10) THEN
        BEGIN
         Postn := 1; AOk := 0;
        END;
      END;
     Total := 0;
    END;
  END;
  IF (Total > 0) THEN Dot[Postn] := Total;

   FOR S := 1 TO 10 DO
    IF (Dot[S] <> Verti[I, S]) THEN AOk := 0;

  IF (AOk = 1) THEN
   BEGIN
    FOR K := 1 TO 25 DO
     IF (Grid[K, I] <> 1) THEN DrawPoint(K, I, 2, FALSE);
    Down[I] := 1;
   END;
 END;



 FOR I := 1 TO 25 DO
 BEGIN
  Total := 0; Postn := 1; AOk := 1;
  FOR S := 1 TO 10 DO
   Dot[S] := 0;
   FOR J := 1 TO 20 DO
   BEGIN
    Value := Grid[I, J];
    IF (Value = 1) THEN
     BEGIN
      Total := Total + 1;
     END
    ELSE
     BEGIN
      IF (Total > 0) THEN
       BEGIN
        Dot[Postn] := Total;
        Postn := Postn + 1;
        IF (Postn > 10) THEN
         BEGIN
          Postn := 1; AOk := 0;
         END;
       END;
      Total := 0;
     END;
   END;
   IF (Total > 0) THEN Dot[Postn] := Total;

   FOR S := 1 TO 10 DO
    IF (Dot[S] <> Horiz[I, S]) THEN AOk := 0;

   IF (AOk = 1) THEN
    BEGIN
     FOR K := 1 TO 20 DO
      IF (Grid[I, K] <> 1) THEN DrawPoint(I, K, 2, FALSE);
     Across[I] := 1;
    END;
 END;

END;


PROCEDURE TMainWin.FollowRow;
VAR
      I, J, K, M : INTEGER;
      Jump, Find : INTEGER;
      DotPlace   : INTEGER;
      DotPl      : INTEGER;
BEGIN

 FOR I := 1 TO 20 DO
 BEGIN
  IF (Down[I] <> 1) THEN
   BEGIN
    Find := 1; Jump := 0; J := -1;
    WHILE (Jump = 0) DO
    BEGIN

 (* Find the starting position of the first "..". *)

     IF (J = 24) THEN Jump := 1;
     IF (J < 24) THEN J := J + 1;

     WHILE ((Grid[J, I] = 1) AND (Jump = 0)) DO
     BEGIN
      IF (J = 24) THEN Jump := 1;
      IF (J < 24) THEN J := J + 1;
     END; 

     IF ((Grid[J, I] = 2) AND (Jump = 0)) THEN
      BEGIN
       IF ((Grid[J + 1, I] = 1) AND (Jump = 0)) THEN
        BEGIN
         FOR K := (J + 1) TO (J + Verti[I, Find]) DO
          DrawPoint(K, I, 1, FALSE);
         DotPlace := J + Verti[I, Find] + 1;
         IF (DotPlace < 26) THEN DrawPoint(DotPlace, I, 2, FALSE);
         Find := Find + 1;
        END;
      END
     ELSE
      BEGIN
       Jump := 1;
      END;

    END;
   END;
 END;

 (* Horiziontal rows from the right *)

 FOR I := 1 TO 20 DO
 BEGIN
  IF (Down[I] <> 1) THEN
   BEGIN
    M := 10;
    WHILE (Verti[I, M] = 0) DO
    BEGIN
     M := M - 1;
    END;


    Find := M; Jump := 0; J := 27;
    WHILE (Jump = 0) DO
    BEGIN

  (* Find the starting position of the first "..". *)

     IF (J = 2) THEN Jump := 1;
     IF (J > 2) THEN J := J - 1;                               
      WHILE ((Grid[J, I] = 1) AND (Jump = 0)) DO
      BEGIN
       IF (J = 2) THEN Jump := 1;
       IF (J > 2) THEN J := J - 1;
      END;

     IF ((Grid[J, I] = 2) AND (Jump = 0)) THEN
      BEGIN
       IF ((Grid[J - 1, I] = 1) AND (Jump = 0)) THEN
        BEGIN
         FOR K := (J - 1) DOWNTO (J - Verti[I, Find]) DO
           DrawPoint(K, I, 1, FALSE);
         DotPl := J - Verti[I, Find] - 1;
         IF (DotPl > 0) THEN DrawPoint(DotPl, I, 2, FALSE);
         Find := Find - 1;
         IF (Find = 0) THEN Jump := 1;
        END;
      END
     ELSE
      BEGIN
      Jump := 1;
      END;

    END;
   END;
 END;

 (* Vertical rows from the top *)

 FOR I := 1 TO 25 DO
 BEGIN
  IF (Across[I] <> 1) THEN
   BEGIN
    Find := 1; Jump := 0; J := -1;
    WHILE (Jump = 0) DO
    BEGIN

    (* Find the starting position of the first "..". *)
     IF (J = 19) THEN Jump := 1;
     IF (J < 19) THEN J := J + 1;
      WHILE ((Grid[I, J] = 1) AND (Jump = 0)) DO                                   
      BEGIN
       IF (J = 19) THEN Jump := 1;
       IF (J < 19) THEN J := J + 1;
      END;

     IF ((Grid[I, J] = 2) AND (Jump = 0)) THEN
      BEGIN
       IF ((Grid[I, J + 1] = 1) AND (Jump = 0)) THEN
        BEGIN
         FOR K := (J + 1) TO (J + Horiz[I, Find]) DO
          DrawPoint(I, K, 1, FALSE);
         DotPlace := J + Horiz[I, Find] + 1;
         IF (DotPlace < 21) THEN DrawPoint(I, DotPlace, 2, FALSE);
         Find := Find + 1;
        END;
      END
     ELSE
      BEGIN
       Jump := 1;
      END;

    END;
   END;
 END;

 (* Vertical rows from the bottom *)

 FOR I := 1 TO 25 DO
 BEGIN
  IF (Across[I] <> 1) THEN
   BEGIN

    M := 10;
    WHILE (Horiz[I, M] = 0) DO
    BEGIN
     M := M - 1;
    END;

    Find := M; Jump := 0; J := 22;
    WHILE (Jump = 0) DO
    BEGIN

    (* Find the starting position of the first '..'. *)
     IF (J = 2) THEN Jump := 1;
     IF (J > 2) THEN J := J - 1;
      WHILE ((Grid[I, J] = 1) AND (Jump = 0)) DO
      BEGIN
       IF (J = 2) THEN Jump := 1;
       IF (J > 2) THEN J := J - 1;
      END;

     IF ((Grid[I, J] = 2) AND (Jump = 0)) THEN
      BEGIN
       IF ((Grid[I, J - 1] = 1) AND (Jump = 0)) THEN
        BEGIN
         FOR K := (J - 1) DOWNTO (J - Horiz[I, Find]) DO
          DrawPoint(I, K, 1, FALSE);
         DotPlace := J - Horiz[I, Find] - 1;
         IF (DotPlace > 0) THEN DrawPoint(I, DotPlace, 2, FALSE);
         Find := Find - 1;
         IF (Find = 0) THEN Jump := 1;
        END;
      END
     ELSE
      BEGIN
       Jump := 1;
      END;

    END;
   END;
 END;


END;


PROCEDURE TMainWin.Combination;
LABEL
        1, 2;
VAR
        Possi   : array [1..25] of INTEGER;
        Poten   : array [1..25, 1..600] of INTEGER;
        Start   : array [1..10] of INTEGER;
        A, B, C : INTEGER;
        D, I    : INTEGER;
        M, N, P : INTEGER;
        Q, R    : INTEGER;
        U, V, T : INTEGER;
        Comp    : INTEGER;
        NotFin  : INTEGER;
        More    : INTEGER;
        Flag    : INTEGER;
        PotenPl : INTEGER;
        Finish  : INTEGER;
        TextString : array [0..10] of CHAR;
BEGIN

 FOR I := 1 TO 20 DO
 BEGIN
  IF (Down[I] <> 1) THEN
  BEGIN
   PotenPl := 1; Notfin := 1; More := 0;
   T := 0;
   WHILE NOT (Verti[I, T + 1] = 0) DO
   BEGIN
    T := T + 1;
   END;

    Start[1] := 1;
    FOR M := 1 TO T - 1 DO
     Start[M + 1] := Start[M] + Verti[I, M] + 1;

   WHILE (Notfin = 1) DO
   BEGIN
    FOR M := 1 TO 25 DO         
     Possi[M] := 2;           


    FOR M := 1 TO T DO
     FOR N := Start[M] TO (Start[M] + Verti[I, M] - 1) DO
      Possi[N] := 1;

    Flag := 0;
    FOR P := 1 TO 25 DO
    BEGIN
      A := Possi[P]; B := Grid[P, I];
      IF ((A = 1) AND (B = 2)) THEN Flag := 1;
      IF ((A = 2) AND (B = 1)) THEN Flag := 1;
    END;
   
    IF (Flag = 0) THEN
     BEGIN
      FOR Q := 1 TO 25 DO
       Poten[Q, PotenPl] := Possi[Q];
      PotenPl := PotenPl + 1;  
      IF (PotenPl > ComSize) THEN
       BEGIN
        Notfin := 0;
        More := 1;
       END;
     END;

    V := T;

1:
    Start[V] := Start[V] + 1;
     Finish := Start[V] - 1;
     FOR R := V TO T DO
      Finish := Finish + Verti[I, R] + 1;
     Finish := Finish - 1;

     U := V;
     WHILE (U < T) DO
     BEGIN
      Start[U + 1] := Start[U] + 1 + Verti[I, U];
      U := U + 1;
     END;

    IF (Finish > 25) THEN
     BEGIN
      V := V - 1;
      IF (V > 0) THEN
       BEGIN
        GOTO 1
       END
      ELSE
       BEGIN
        Notfin := 0;
       END;
     END;

   END;
   



   IF (More = 0) THEN
   BEGIN
    FOR C := 1 TO 25 DO
    BEGIN
     Comp := Poten[C, 1];
     FOR D := 2 TO (PotenPl - 1) DO
      IF (Comp <> Poten[C, D]) THEN Comp := 0;
     IF (Comp <> 0) THEN
     BEGIN
      DrawPoint(C, I, Comp, FALSE);
      DrawPoint(C, I, Comp, FALSE);
     END;
    END;
   END;


  END;
 END;

  (* Now work across the data set *)

 FOR I := 1 TO 25 DO
 BEGIN
  IF (Across[I] <> 1) THEN
  BEGIN
   PotenPl := 1; Notfin := 1; More := 0;
   T := 0;
   WHILE NOT (Horiz[I, T + 1] = 0) DO
   BEGIN
    T := T + 1;
   END;

    Start[1] := 1;
    FOR M := 1 TO T - 1 DO
     Start[M + 1] := Start[M] + Horiz[I, M] + 1;

   WHILE (Notfin = 1) DO
   BEGIN

    FOR M := 1 TO 20 DO  
     Possi[M] := 2;       


    FOR M := 1 TO T DO
     FOR N := Start[M] TO (Start[M] + Horiz[I, M] - 1) DO
      Possi[N] := 1;

    (* Compare Possi array with actual data *)

    Flag := 0;
    FOR P := 1 TO 20 DO
    BEGIN
      A := Possi[P]; B := Grid[I, P];
      IF ((A = 1) AND (B = 2)) THEN Flag := 1;
      IF ((A = 2) AND (B = 1)) THEN Flag := 1;
    END;
  
    IF (Flag = 0) THEN
    BEGIN
     FOR Q := 1 TO 20 DO
      Poten[Q, PotenPl] := Possi[Q];
     PotenPl := PotenPl + 1;
     IF (PotenPl > ComSize) THEN
      BEGIN
       Notfin := 0;
       More := 1;
      END;
    END;         


    V := T;

2:
     Start[V] := Start[V] + 1;
     Finish := Start[V] - 1;
     FOR R := V TO T DO
      Finish := Finish + Horiz[I, R] + 1;
     Finish := Finish - 1;

     U := V;
     WHILE (U < T) DO
     BEGIN
      Start[U + 1] := Start[U] + 1 + Horiz[I, U];
      U := U + 1;
     END;

    IF (Finish > 20) THEN
    BEGIN
     V := V - 1;
      IF (V > 0) THEN
       BEGIN
        GOTO 2
       END
      ELSE
       BEGIN 
        Notfin := 0;
       END;
    END;

   END;

   IF (More = 0) THEN
    BEGIN
     FOR C := 1 TO 20 DO
     BEGIN
      Comp := Poten[C, 1];
      FOR D := 2 TO (PotenPl - 1) DO
       IF (Comp <> Poten[C, D]) THEN Comp := 0;
      IF (Comp <> 0) THEN
       BEGIN
        DrawPoint(I, C, Comp, FALSE);
        DrawPoint(I, C, Comp, FALSE);
       END;
     END;
    END;

  END;
 END;


END;


PROCEDURE TMainWin.Update;
VAR
        TextString : array [0..10] of CHAR;
BEGIN

   TheDC := GetDC(HWindow);
    SetBkColor(TheDC, $00808080);
    SetTextColor(TheDC, $00F0F0F0);
    Str(PlotTotal, TextString);
    TextOut(TheDC, 530, 40, TextString, StrLen(TextString));
   ReleaseDC(HWindow, TheDC);

END;


PROCEDURE TMainWin.EasyFill(I, K : INTEGER);
VAR
    A, P, J, T : INTEGER;
BEGIN
 P := 0; J := 0;

  IF (K <> 1) THEN Down[I] := 1
  ELSE Across[I] := 1;

  FOR J := 1 TO 10 DO
  BEGIN
   IF (K <> 1) THEN
    BEGIN
     A := Verti[I, J];
     FOR T := 1 TO A DO
      DrawPoint((P + T), I, 1, FALSE);
     P := P + A;
     IF (P < 25) THEN DrawPoint((P + 1), I, 2, FALSE);
     P := P + 1;
    END
   ELSE
    BEGIN
     A := Horiz[I, J];
     FOR T := 1 TO A DO
      DrawPoint(I, (P + T), 1, FALSE);
     P := P + A;
     IF (P < 20) THEN DrawPoint(I, (P + 1), 2, FALSE);
     P := P + 1;
    END;
  END;
END;


PROCEDURE TMainWin.FillDot (Iin, Kin, STot : INTEGER);
VAR
    A, J, L, M, N, P  : INTEGER;
    S                 : INTEGER;
    AOk, Left, Right  : INTEGER;
    Value, GapSize    : INTEGER;
    StartPos, StopPos : INTEGER;
BEGIN
 P := 0; J := 0;

 FOR J := 1 TO 10 DO
 BEGIN
  IF (Kin <> 1) THEN
   BEGIN
    A := Verti[Iin, J];
    AOk := 0; Left := 0;
     FOR L := 1 TO (J - 1) DO
     BEGIN
      Value := Verti[Iin, L];
      IF (Value > 0) THEN Left := Left + 1 + Value;
     END;
    Right := 0;
     FOR M := (J + 1) TO 10 DO
     BEGIN
      Value := Verti[Iin, M];
      IF (Value > 0) THEN Right := Right + 1 + Value;
     END;
    Right := 25 - Right;
    GapSize := Right - Left;

    S := GapSize - A;
    IF (S < 0) THEN AOk := 1;
    StartPos := Left + S + 1;
    StopPos := Right - S;

    IF ((StartPos <= StopPos) AND (AOk <> 1)) THEN
     BEGIN
      FOR N := StartPos TO StopPos DO
       DrawPoint(N, Iin, 1, FALSE);
     END;

   END
  ELSE
   BEGIN
    A := Horiz[Iin, J];
    AOk := 0; Left := 0;
     FOR L := 1 TO (J - 1) DO
     BEGIN
      Value := Horiz[Iin, L];
      IF (Value > 0) THEN Left := Left + 1 + Value;
     END;
    Right := 0;
     FOR M := (J + 1) TO 10 DO
     BEGIN
      Value := Horiz[Iin, M];
      IF (Value > 0) THEN Right := Right + 1 + Value;
     END;
    Right := 20 - Right;
    GapSize := Right - Left;

    S := GapSize - A;
    IF (S < 0) THEN AOk := 1;
    StartPos := Left + S + 1;
    StopPos := Right - S;

    IF ((StartPos <= StopPos) AND (AOk <> 1)) THEN
     BEGIN
      FOR N := StartPos TO StopPos DO
       DrawPoint(Iin, N, 1, FALSE);
     END;
  END;
 END;
END;

(**********************************************************************)

(* Methods of TConfigWin follow.................................. *) 


CONSTRUCTOR TConfigWin.Init (AParent : PWindowsObject; AName : PChar);
BEGIN
  TDialog.Init (AParent, AName);
  Check1 := New(PCheckBox, InitResource(@self, ID_QStart));
  Check2 := New(PCheckBox, InitResource(@self, ID_ECheck));
  Check3 := New(PCheckBox, InitResource(@self, ID_FRowTs));
  Check4 := New(PCheckBox, InitResource(@self, ID_RowFol));
  Check5 := New(PCheckBox, InitResource(@self, ID_Combin));
  Field  := New(PEdit, InitResource(@self, ID_Vars, 4));
END;


PROCEDURE TConfigWin.SetupWindow;
VAR
    Line : array [0..4] of char;
    TextItem : PChar;
BEGIN
  TDialog.SetupWindow;

  IF (BoolQStart) THEN
   Check1^.Check
  ELSE
   Check1^.UnCheck;

  IF (BoolECheck) THEN
   Check2^.Check
  ELSE
   Check2^.UnCheck;

  IF (BoolFRowTs) THEN
   Check3^.Check
  ELSE
   Check3^.UnCheck;

  IF (BoolRowFol) THEN
   Check4^.Check
  ELSE
   Check4^.UnCheck;

  IF (BoolCombin) THEN
   Check5^.Check
  ELSE
   Check5^.UnCheck;

  TempQStart := BoolQStart;
  TempECheck := BoolECheck;
  TempFRowTs := BoolFRowTs;
  TempRowFol := BoolRowFol;
  TempCombin := BoolCombin;

  Str(ComSize, Line);
  Field^.Insert(@Line);

END;


PROCEDURE TConfigWin.OK (VAR Msg : TMessage);
VAR
      Code  : INTEGER;
      Line : array [0..4] of CHAR;
      S    : String;
BEGIN
  GetDlgItemText (HWindow, id_Vars, @Line, 4);
  S := StrPas (Line);
  Val (S, ComSize, Code);

  IF (ComSize > 600) THEN ComSize := 600;
  IF (ComSize < 0) THEN ComSize := 0;

  BoolQStart := TempQStart;
  BoolECheck := TempECheck;
  BoolFRowTs := TempFRowTs;
  BoolRowFol := TempRowFol;
  BoolCombin := TempCombin;
 
  TDialog.OK (Msg);
END;


PROCEDURE TConfigWin.QStart (VAR Msg : TMessage);
BEGIN
  TempQStart := NOT(TempQStart);
  IF (TempQStart) THEN
   Check1^.Check
  ELSE
   Check1^.UnCheck;
END;


PROCEDURE TConfigWin.ECheck (VAR Msg : TMessage);
BEGIN
  TempECheck := NOT(TempECheck);
  IF (TempECheck) THEN
   Check2^.Check
  ELSE
   Check2^.UnCheck;
END;


PROCEDURE TConfigWin.FRowTs (VAR Msg : TMessage);
BEGIN
  TempFRowTs := NOT(TempFRowTs);
  IF (TempFRowTs) THEN
   Check3^.Check
  ELSE
   Check3^.UnCheck;
END;


PROCEDURE TConfigWin.RowFol (VAR Msg : TMessage);
BEGIN
  TempRowFol := NOT(TempRowFol);
  IF (TempRowFol) THEN
   Check4^.Check
  ELSE
   Check4^.UnCheck;
END;


PROCEDURE TConfigWin.Combin (VAR Msg : TMessage);
BEGIN
  TempCombin := NOT(TempCombin);
  IF (TempCombin) THEN
   Check5^.Check
  ELSE
   Check5^.UnCheck;
END;


PROCEDURE TConfigWin.DiaHlp (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_Context, HC_Sltn);
END;

(**********************************************************************)

(* Methods of TDisplWin follow... *)

CONSTRUCTOR TDisplWin.Init (AParent : PWindowsObject; AName : PChar);
BEGIN
  TDialog.Init (AParent, AName);
  Rad1 := New(PRadioButton, InitResource(@self, ID_ZeroDg));
  Rad2 := New(PRadioButton, InitResource(@self, ID_NineDg));
  Rad3 := New(PRadioButton, InitResource(@self, ID_OneEDg));
  Rad4 := New(PRadioButton, InitResource(@self, ID_TwoSDg));
  Chk1 := New(PCheckBox, InitResource(@self, ID_Flip));
END;


PROCEDURE TDisplWin.SetupWindow;
BEGIN
  TDialog.SetupWindow;
  TempZeroDg := BoolZeroDg;
  TempNineDg := BoolNineDg;
  TempOneEDg := BoolOneEDg;
  TempTwoSDg := BoolTwoSDg;
  TempFlipDg := BoolFlipDg;

  IF (BoolZeroDg) THEN
   BEGIN
    Rad1^.Check;
    Rad2^.UnCheck;
    Rad3^.UnCheck;
    Rad4^.UnCheck;
   END;

  IF (BoolNineDg) THEN
   BEGIN
    Rad1^.UnCheck;
    Rad2^.Check;
    Rad3^.UnCheck;
    Rad4^.UnCheck;
   END;

  IF (BoolOneEDg) THEN
   BEGIN
    Rad1^.UnCheck;
    Rad2^.UnCheck;
    Rad3^.Check;
    Rad4^.UnCheck;
   END;

  IF (BoolTwoSDg) THEN
   BEGIN
    Rad1^.UnCheck;
    Rad2^.UnCheck;
    Rad3^.UnCheck;
    Rad4^.Check;
   END;

  IF (BoolFlipDg) THEN Chk1^.Check
  ELSE Chk1^.UnCheck;

END;


PROCEDURE TDisplWin.ZeroDg (VAR Msg : TMessage);
BEGIN
 TempZeroDg := TRUE;
 TempNineDg := FALSE;
 TempOneEDg := FALSE;
 TempTwoSDg := FALSE;
 Rad1^.Check;
 Rad2^.UnCheck;
 Rad3^.UnCheck;
 Rad4^.UnCheck;
END;


PROCEDURE TDisplWin.NineDg (VAR Msg : TMessage);
BEGIN
 TempZeroDg := FALSE;
 TempNineDg := TRUE;
 TempOneEDg := FALSE;
 TempTwoSDg := FALSE;
 Rad1^.UnCheck;
 Rad2^.Check;
 Rad3^.UnCheck;
 Rad4^.UnCheck;
END;


PROCEDURE TDisplWin.OneEDg (VAR Msg : TMessage);
BEGIN
 TempZeroDg := FALSE;
 TempNineDg := FALSE;
 TempOneEDg := TRUE;
 TempTwoSDg := FALSE;
 Rad1^.UnCheck;
 Rad2^.UnCheck;
 Rad3^.Check;
 Rad4^.UnCheck;
END;


PROCEDURE TDisplWin.TwoSDg (VAR Msg : TMessage);
BEGIN
 TempZeroDg := FALSE;
 TempNineDg := FALSE;
 TempOneEDg := FALSE;
 TempTwoSDg := TRUE;
 Rad1^.UnCheck;
 Rad2^.UnCheck;
 Rad3^.UnCheck;
 Rad4^.Check;
END;


PROCEDURE TDisplWin.Flip (VAR Msg : TMessage);
BEGIN
  TempFlipDg := NOT(TempFlipDg);
  IF (TempFlipDg) THEN Chk1^.Check
  ELSE Chk1^.UnCheck;   
END;


PROCEDURE TDisplWin.DiaHlp (VAR Msg : TMessage);
BEGIN
  WinHelp (HWindow, HelpFileNm, Help_Context, HC_Dsplay);
END;


PROCEDURE TDisplWin.OK (VAR Msg : TMessage);
BEGIN                                                             
  BoolZeroDg := TempZeroDg;
  BoolNineDg := TempNineDg;
  BoolOneEDg := TempOneEDg;
  BoolTwoSDg := TempTwoSDg;
  BoolFlipDg := TempFlipDg;
  TDialog.OK(Msg);
END;

(**********************************************************************)
(* Main program follows................. *)


CONSTRUCTOR TMenuApp.Init(AName: PChar);
BEGIN
  TApplication.Init(AName);
  HAccTable := LoadAccelerators (HInstance, 'Accelerators_1');
END;


PROCEDURE TMenuApp.InitMainWindow;
BEGIN
  MainWindow := New (PMainWin, Init (nil, 'Nonogram Solver - [none]'));
END;


(**********************************************************************)


VAR MenuApp : TMenuApp;

BEGIN
  MenuApp.Init ('NONOGRAM');
  MenuApp.Run;
  MenuApp.Done;
END.



