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
*  Date     : 11/12/1993
*  Version  : 2.0
*  Language : PASCAL
*)

{$R NONOGRAM.RES}
{$M 40000, 8192}


USES WinTypes, WinProcs, WObjects, StdDlgs, WinDos, Strings, BWCC, CommDlg;

CONST
  (* Menu/resource ID constants *)
  CM_NEW       = 101;    (* File|New menu resource ID *)
  CM_LOAD      = 102;    (* File|Load menu resource ID *)
  CM_PRINT     = 103;    (* File|Print menu resource ID *)
  CM_SETUP     = 104;    (* File|Print setup menu resource ID *)
  CM_EDIT      = 105;    (* File|Edit menu resource ID *)
  CM_EXIT      = 106;    (* File|Exit menu resource ID *)
  CM_CONFSOLUT = 201;    (* Options|Configure solution menu resource ID *)
  CM_CONFDISPL = 202;    (* Options|Configure display menu resource ID *)
  CM_PREFER    = 203;    (* Options|Preferences menu resource ID *)
  CM_SOLVE     = 204;    (* Options|Solve Nonogram menu resource ID *)
  CM_PARSE     = 205;    (* Options|Parse data menu resource ID *)
  CM_STOPSO    = 223;    (* Options|Stop solve menu resource ID - XOR with ID_SOLVE *)
  ID_QSTART    = 501;    (* Solution configure dialog - Quick start check box *)
  ID_ECHECK    = 502;    (* Solution configure dialog - Edge checking check box *)
  ID_FROWTS    = 503;    (* Solution configure dialog - Full row testing check box *)
  ID_ROWFOL    = 504;    (* Solution configure dialog - row following check box *)
  ID_COMBIN    = 505;    (* Solution configure dialog - combinational check box *)
  ID_VARS      = 506;    (* Solution configure dialog - VARS edit text *)
  ID_ZERODG    = 530;    (* Display configure dialog - 0 degrees radio button *)
  ID_NINEDG    = 531;    (* Display configure dialog - 90 degrees radio button *)
  ID_ONEEDG    = 532;    (* Display configure dialog - 180 degrees radio button *)
  ID_TWOSDG    = 533;    (* Display confgiure dialog - 270 degrees radio button *)
  ID_FLIP      = 534;    (* Display configure dialog - flip display check box *)
  ID_ABOTTITLE = 550;    (* About dialog program title box *)
  ID_COPYRIGHT = 551;    (* About dialog CopyRight static text control *)
  ID_REGISTER  = 552;    (* Registered to box *)
  ID_VERSIONNO = 553;    (* About dialog version number *)
  ID_RELSEDATE = 554;    (* About dialog release date *)
  ID_PREFSOLVE = 650;    (* Preferences dialog box - solve confirmation *)
  ID_PREFLOADC = 651;    (* Preferences dialog box - load confirmation *)
  ID_PREFTOOLB = 652;    (* Preferences dialog box - tool bar *)
  ID_PREFSTATU = 653;    (* Preferences dialog box - status bar *)
  ID_PREFSAVEO = 654;    (* Preferences dialog box - save on exit *)
  ID_DILOGHELP = 998;    (* Dialog help button resource ID *)
  CM_CONTENTS  = 901;    (* Menu Help|Contents resource ID *)
  CM_INTRO     = 902;    (* Menu Help|Introduction resource ID *)
  CM_HELPONHLP = 903;    (* Menu Help|Help on help resource ID *)
  CM_HELPABOUT = 999;    (* Menu Help|About resource ID *)

  (* Help Constants *)
  HC_INTRO     = 1;     
  HC_PREFER    = 2;      (* Preferences dialog help context ID *)
  HC_SOLUTION  = 3;      (* Solution options dialog help context ID *) 
  HC_DISPLAY   = 4;      (* Display options dialog help context ID *)
      
  (* Other Constants *)
  NoToolButtons = 12;                        (* Number of tool bar buttons *)
  MaxXAcross = 100;                          (* Maximum number of X rows *)
  MaxYAcross = 100;                          (* Maximum number of Y rows *)
  MaxNoElements = 30;                        (* Maximum number of elements per row *)

TYPE
  (* Display enumerated type *)
  DisplayRotation = (Zero, Nine, OneE, TwoS);

  (* Solution VARS array type *)
  PPotVal = ^TPotVal;
  TPotVal = RECORD
    Data: ARRAY [1..MaxYAcross, 1..300] OF SHORTINT;
  END;


  (* Main program declarations *)
  PNonogram = ^TNonogram;
  TNonogram = OBJECT (TApplication)
    CONSTRUCTOR Init(AName: PChar);
    PROCEDURE   InitMainWindow; virtual;
  END;


  (* About box dialog prototype *)
  PAboutBox = ^TAboutBox;
  TAboutBox = OBJECT(TDialog)                  
    Text1, Text2, Text3, Text4,                (* Static text control handles *)
    Text5: PStatic;

    CONSTRUCTOR Init(AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
  END;
                                        

  (* Preferences dialog box prototypes *)
  PPreferences = ^TPreferences;
  TPreferences = OBJECT(TDialog)
    Check1, Check2, Check3,
    Check4, Check5: PCheckBox;                 (* Check box handles *)

    CONSTRUCTOR Init (AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK (VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK;
    PROCEDURE   DialogHelp (VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
  END;


  (* Solution options configuration dialog prototypes *)
  PConfigWin = ^TConfigWin;
  TConfigWin = OBJECT(TDialog)
    Check1, Check2, Check3,
    Check4, Check5: PCheckBox;                 (* Check box handles *)   
    Field: PEdit;                              (* VARS field edit control *)

    CONSTRUCTOR Init (AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK (VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
    PROCEDURE   DialogHelp (VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
  END;


  (* Display options dialog box prototypes *)
  PDisplayOptions = ^TDisplayOptions;
  TDisplayOptions = OBJECT(TDialog)
    Rad1, Rad2, Rad3, Rad4: PRadioButton;      (* Radio button handles *)   
    Chk1: PCheckBox;                           (* Check box handle *)

    CONSTRUCTOR Init (AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK (VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
    PROCEDURE   DialogHelp (VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
  END;


  (* Toolbutton window prototype *)
  PToolbutton = ^TToolbutton;
  TToolbutton = OBJECT(TWindow)
    UpPosition: BOOLEAN;                         (* Is the button up or down? *)
    LMseButton: BOOLEAN;                         (* Is the left button down? *)
    Enabled: BOOLEAN;                            (* Is the button enabled? *)
    EnBit, DisEnBit: HBitmap;                    (* Handles to enabled and disabled bitmap
                                                    pictures *)
    WPAR, LPAR: INTEGER;                         (* Message to be sent values *)
    DownText,                                    (* Text to be displayed: button is down *)
    UpText: ARRAY [0..100] OF CHAR;              (* Text to be displayed: button is up *)

    CONSTRUCTOR Init(AParent: PWindowsObject; XPos, YPos: INTEGER;
                     EnB, DisEnB: HBitmap; WPR, LPR: INTEGER; En: BOOLEAN);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    FUNCTION    GetClassName: PChar; virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct); virtual;
    PROCEDURE   PaintButton(TheDC: HDC);
    PROCEDURE   WMLButtonDown(VAR Msg: TMessage);
                virtual WM_FIRST + WM_LBUTTONDOWN;
    PROCEDURE   WMLButtonUp(VAR Msg: TMessage);
                virtual WM_FIRST + WM_LBUTTONUP;
    PROCEDURE   WMMouseMove(VAR Msg: TMessage);
                virtual WM_FIRST + WM_MOUSEMOVE;
    PROCEDURE   SetDownText(TextString: PChar);
    PROCEDURE   SetUpText(TextString: PChar);
  END;


  (* Toolbar window prototype *)
  PToolbar = ^TToolbar;
  TToolbar = OBJECT(TWindow)
    ToolbuttonPntr: ARRAY[1..NoToolButtons] OF PToolButton;
    HButUp, HButDown: HBitmap;

    CONSTRUCTOR Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    FUNCTION    GetClassName: PChar; virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct); virtual;
    PROCEDURE   EnableButton(ButtonNo: INTEGER; Enable: BOOLEAN);
    PROCEDURE   ShowButton(ButtonNo: INTEGER; CmdShow: INTEGER);
  END;


  (* Status bar window prototypes *)
  PStatbar = ^TStatbar;
  TStatbar = OBJECT(TWindow)
    Text: ARRAY [0..100] OF CHAR;              (* The main text string *)
    TimeText: ARRAY [0..20] OF CHAR;           (* The time taken text string *)
    PointText: ARRAY [0..10] OF CHAR;          (* The number of points found so far *)
    HStatbarFont: HFONT;                       (* Handle to vertical axes font *)
    StatbarFont: TLOGFONT;                     (* Font record for the status bar font *)
    DkGrayPen,                                 (* Handle to dark gray pen *)
    LtGrayPen: HPEN;                           (* Hanlde to light gray pen *)

    CONSTRUCTOR Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    FUNCTION    GetClassName: PChar; virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct); virtual;
    PROCEDURE   SetText(TheDC: HDC; TextString: PChar); virtual;
    PROCEDURE   SetTime(TheDC: HDC; TextString, TextStrtwo: PChar); virtual;
  END;


  (* Main display window prototypes  - this is the actual window in which the Nonogram
     is displayed *)
  PDisplay = ^TDisplay;
  TDisplay = OBJECT(TWindow)
    Sum1, Sum2: INTEGER;                       (* Sums of the across/down array elements *)
    Filename: ARRAY [0..FSPATHNAME] OF CHAR;   (* Nonogram filename *)
    FilTitle: ARRAY [0..200] OF CHAR;          (* Nonogram datafile title *)
    SentMessage: TMsg;                         (* General message handle *)
    SolveTime: LONGINT;                        (* Solve time variable *)
    XAcross, YAcross: INTEGER;                 (* Nonogram size attributes *)
    XFilled: ARRAY [1..MaxXAcross] OF INTEGER; (* Main input puzzle data storage in X *)
    YFilled: ARRAY [1..MaxYAcross] OF INTEGER; (* Main input puzzle data storage in Y *)
    PlotTotal: INTEGER;                        (* Total number of points found so far *)
    VScrollbarPresent,                         (* Vertical scrollbar visible on screen *)
    HScrollbarPresent: BOOLEAN;                (* Horizontal scrollbar visible on screen *)

    (* The following are used by the main program *)
    XElements: ARRAY [1..MaxXAcross, 1..MaxNoElements] OF INTEGER;   (* Obvious *)   
    YElements: ARRAY [1..MaxYAcross, 1..MaxNoElements] OF INTEGER;   (* Obvious *)
    ScreenGrid: ARRAY [1..MaxXAcross, 1..MaxYAcross] OF INTEGER;     (* Obvious *)

    (* The following are used by the combinational algorithm *)
    PossiblePos: ARRAY [1..MaxYAcross] OF INTEGER;
    Start: ARRAY [1..MaxNoElements] OF INTEGER;

    CONSTRUCTOR Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    FUNCTION    GetClassName: PChar; virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   WMSize(VAR Msg: TMessage);
                virtual WM_FIRST + WM_SIZE;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct); virtual;
    PROCEDURE   DrawAxes(TheDC: HDC);
    PROCEDURE   DrawPoint(TheDC: HDC; XPos, YPos, BlockDot: INTEGER; Allways: BOOLEAN);
    PROCEDURE   QuickData;
    PROCEDURE   CheckEdge;
    PROCEDURE   TestRowFull;
    PROCEDURE   FollowRow;
    PROCEDURE   Combination;
    PROCEDURE   EasyFill(I, K: INTEGER);
    PROCEDURE   FillDot(Iin, Kin, STot: INTEGER);
    PROCEDURE   ResetData;
    PROCEDURE   ParseData;
  END;


  (* Main window - This is the main window. *)
  PMainWindow = ^TMainWindow;
  TMainWindow = OBJECT(TWindow)
    SolveConfirmation,                         (* Preferences solve confirmation *)
    LoadConfirmation,                          (* Preferenced load confirmation *) 
    SaveOnExit: BOOLEAN;                       (* Preferences save on exit *)
    SentMessage: TMsg;                         (* General message handle *)
    BackBrush,                                 (* Back brush handle *)
    BlockBrush,                                (* Block brush handle *)
    DotBrush: HBrush;                          (* Filled block brush handle *)
    TBackBrush,                                (* Back brush structure *)
    TBlockBrush,                               (* Block brush structure *)
    TDotBrush: TLogBrush;                      (* Filled block brush handle *)
    HAxesVFont,                                (* Handle to vertical axes font *)
    HAxesHFont: HFONT;                         (* Handle to horizontal axes font *)
    AxesVFont,                                 (* Vertical axes font record *)
    AxesHFont: TLOGFONT;                       (* Horizontal axes font *)
    ToolBarHan: PToolbar;                      (* Pointer to toolbar *)
    DisplayHan: PDisplay;                      (* Pointer to display window *)
    PotentData: PPotVal;                       (* Pointer to the potential data array *)
    StatbarHan: PStatbar;                      (* Pointer to status bar *)
    ToolbarExist, DisplayExist,                (* Do toolbar and main window exist *)
    StatbarExist: BOOLEAN;                     (* Does status bar exist *)
    QuickStrtOn,                               (* Flag - Quick Data is on *)
    EdgeCheckOn,                               (* Flag - Edge Checking is on *)
    FullRwTstOn,                               (* Flag - Full Row Testing is on *)
    RowFollowOn,                               (* Flag - Row following is on *)
    CombinatnOn: BOOLEAN;                      (* Flag - Combination algorithm is on *)
    VARSSize: INTEGER;                         (* Size of the VARS array *)
    DisplayRotate: DisplayRotation;            (* Which way round do we display the data *)
    DisplayFlip: BOOLEAN;                      (* Should we flip the data around *)
    Filename: ARRAY [0..FSPATHNAME] OF CHAR;   (* Nonogram filename *)
    CanThink: BOOLEAN;                         (* Indicates that solving is allowed *)
    SolveInProgress: BOOLEAN;                  (* Indicates that solving is in progress *)
    StopSolAndExit: BOOLEAN;                   (* Stop solving and then exit *)
    PrintStruct: TPRINTDLG;                    (* Printer information structure *)
    DevModePrn: TDEVMODE;                         (* Printer - device mode *)
    DevNamesPrn: TDEVNAMES;                       (* Printer - device names *)
    PDevModePrn: PDEVMODE;
    PDevNamesPrn: PDEVNAMES;

    CONSTRUCTOR Init (AParent: PWindowsObject; ATitle: PChar);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   WMSize(VAR Msg: TMessage);
                virtual WM_FIRST + WM_SIZE;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
                virtual;
    PROCEDURE   RedoChildren;
    PROCEDURE   FileNew(VAR Msg: TMessage);
                virtual CM_FIRST + CM_NEW;
    PROCEDURE   FileLoad(VAR Msg: TMessage);
                virtual CM_FIRST + CM_LOAD;
    PROCEDURE   FilePrint(VAR Msg: TMessage);
                virtual CM_FIRST + CM_PRINT;
    FUNCTION    GetPrinterDC: HDC;
    PROCEDURE   FileSetup(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SETUP;
    PROCEDURE   FileEdit(VAR Msg: TMessage);
                virtual CM_FIRST + CM_EDIT;
    PROCEDURE   FileExit(VAR Msg: TMessage);
                virtual CM_FIRST + CM_EXIT;
    PROCEDURE   ConfigureSolution(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONFSOLUT;
    PROCEDURE   ConfigureDisplay(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONFDISPL;
    PROCEDURE   Preferences(VAR Msg: TMessage);
                virtual CM_FIRST + CM_PREFER;
    PROCEDURE   Solve(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SOLVE;
    PROCEDURE   Parse(VAR Msg: TMessage);
                virtual CM_FIRST + CM_PARSE;
    PROCEDURE   HelpContents(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONTENTS;
    PROCEDURE   Intro(VAR Msg: TMessage);
                virtual CM_FIRST + CM_INTRO;
    PROCEDURE   HelpOnHelp(VAR Msg: TMessage);
                virtual CM_FIRST + CM_HELPONHLP;
    PROCEDURE   HelpAbout(VAR Msg: TMessage);
                virtual CM_FIRST + CM_HELPABOUT;
    PROCEDURE   FileLoadImplement;
    FUNCTION    GetClassName: PChar; virtual;
    FUNCTION    CanClose: BOOLEAN; virtual;
  END;
 

(**********************************************************************)
(* Methods of TToolbar from here onwards *)


CONSTRUCTOR TToolbar.Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
VAR
  ParentRect: TRect;
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, '');

  (* Get parent client width *)
  GetClientRect(AParent^.HWindow, ParentRect);

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos;
    Y := YPos;
    W := Width;
    H := Height;
    Style := WS_CHILD OR WS_VISIBLE;
  END;

  (* Load blank toolbar button resource bitmap *)
  HButUp   := LoadBitmap(HInstance, 'UPBUTTON');
  HButDown := LoadBitmap(HInstance, 'DOWNBUTTON');
END;


DESTRUCTOR TToolbar.Done;
BEGIN
  (* Delete objects *)
  DeleteObject(HButUp);
  DeleteObject(HButDown);

  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TToolbar.GetWindowClass(VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.Style := CS_HREDRAW OR CS_VREDRAW;
  AWndClass.HIcon := LoadIcon (HInstance, IDI_APPLICATION);
  AWndClass.HBRBackground := COLOR_BTNFACE + 1;
END;


FUNCTION TToolbar.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'TOOLBAR';
END;


PROCEDURE TToolbar.SetupWindow;
VAR
  I: INTEGER;
BEGIN
  (* Call ancestor method *)                   
  TWindow.SetupWindow;

  (* Create toolbar buttons - first group *)
  ToolbuttonPntr[1] := New(PToolbutton, Init(@self, 8, 4, LoadBitmap(HInstance, 'TB_NEW'),
                           0, CM_NEW, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[1]);
  ToolbuttonPntr[2] := New(PToolbutton, Init(@self, 32, 4, LoadBitmap(HInstance, 'TB_LOAD'),
                           0, CM_LOAD, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[2]);
  ToolbuttonPntr[3] := New(PToolbutton, Init(@self, 56, 4, LoadBitmap(HInstance, 'TB_SAVE'),
                           0, CM_EDIT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[3]);
  ToolbuttonPntr[4] := New(PToolbutton, Init(@self, 80, 4, LoadBitmap(HInstance, 'TB_PRINT'),
                           0, CM_PRINT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[4]);

  (* Second group *)
  ToolbuttonPntr[5] := New(PToolbutton, Init(@self, 114, 4, LoadBitmap(HInstance, 'TB_SOLVE'),
                           LoadBitmap(HInstance, 'TB_DISSOLVE'), CM_SOLVE, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[5]);
  ToolbuttonPntr[6] := New(PToolbutton, Init(@self, 138, 4, LoadBitmap(HInstance, 'TB_PARSE'),
                           LoadBitmap(HInstance, 'TB_DISPARSE'), CM_PARSE, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[6]);

  (* Third group *)
  ToolbuttonPntr[7] := New(PToolbutton, Init(@self, 172, 4, LoadBitmap(HInstance, 'TB_CONFSOLUT'),
                           0, CM_CONFSOLUT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[7]);
  ToolbuttonPntr[8] := New(PToolbutton, Init(@self, 196, 4, LoadBitmap(HInstance, 'TB_CONFDISPL'),
                           0, CM_CONFDISPL, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[8]);
  ToolbuttonPntr[9] := New(PToolbutton, Init(@self, 220, 4, LoadBitmap(HInstance, 'TB_PREFER'),
                           0, CM_PREFER, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[9]);

  (* Fourth group *)
  ToolbuttonPntr[10] := New(PToolbutton, Init(@self, 254, 4, LoadBitmap(HInstance, 'TB_HELP'),
                           0, CM_CONTENTS, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[10]);
  ToolbuttonPntr[11] := New(PToolbutton, Init(@self, 278, 4, LoadBitmap(HInstance, 'TB_ABOUT'),
                           0, CM_HELPABOUT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[11]);

  (* And finally the hidden stop solving button *)
  ToolbuttonPntr[12] := New(PToolbutton, INit(@self, 114, 4, LoadBitmap(HInstance, 'TB_STOPSOLVE'),
                            0, CM_STOPSO, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[12]);
  ShowButton(12, SW_HIDE);

  (* Set text strings *)
  ToolbuttonPntr[1]^.SetDownText('Clear current Nonogram data');
  ToolbuttonPntr[1]^.SetUpText('');
  ToolbuttonPntr[2]^.SetDownText('Open a Nonogram data file');
  ToolbuttonPntr[2]^.SetUpText('');
  ToolbuttonPntr[3]^.SetDownText('Edit a Nonogram data file');
  ToolbuttonPntr[3]^.SetUpText('');
  ToolbuttonPntr[4]^.SetDownText('Print a Nonogram');
  ToolbuttonPntr[4]^.SetUpText('');
  ToolbuttonPntr[5]^.SetDownText('Solve currently loaded Nonogram');
  ToolbuttonPntr[5]^.SetUpText('');
  ToolbuttonPntr[6]^.SetDownText('Parse currently loaded Nonogram data');
  ToolbuttonPntr[6]^.SetUpText('');
  ToolbuttonPntr[7]^.SetDownText('Configure Nonogram solution');
  ToolbuttonPntr[7]^.SetUpText('');
  ToolbuttonPntr[8]^.SetDownText('Configure Nonogram display');
  ToolbuttonPntr[8]^.SetUpText('');
  ToolbuttonPntr[9]^.SetDownText('Configure Nonogram preferences');
  ToolbuttonPntr[9]^.SetUpText('');
  ToolbuttonPntr[10]^.SetDownText('Help for the Nonogram solver');
  ToolbuttonPntr[10]^.SetUpText('');
  ToolbuttonPntr[11]^.SetDownText('About the Nonogram solver');
  ToolbuttonPntr[11]^.SetUpText('Nonogram Solver - Version 2.0');
  ToolbuttonPntr[12]^.SetDownText('Interrupt current Nonogram solve');
  ToolbuttonPntr[12]^.SetUpText('');
END;
                                                     

PROCEDURE TToolbar.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);
END;


PROCEDURE TToolbar.EnableButton(ButtonNo: INTEGER; Enable: BOOLEAN);
BEGIN
  (* Enable or disable a given button *)
  IF ((ButtonNo > 0) AND (ButtonNo <= NoToolButtons)) THEN
  BEGIN
    IF ((Enable) AND NOT(ToolbuttonPntr[ButtonNo]^.Enabled)) THEN
    BEGIN
      ToolbuttonPntr[ButtonNo]^.Enabled := TRUE;
      ToolbuttonPntr[ButtonNo]^.PaintButton(0);
    END;

    IF (NOT(Enable) AND (ToolbuttonPntr[ButtonNo]^.Enabled)) THEN
    BEGIN
      ToolbuttonPntr[ButtonNo]^.Enabled := FALSE;
      ToolbuttonPntr[ButtonNo]^.PaintButton(0);
    END;
  END;
END;


PROCEDURE TToolbar.ShowButton(ButtonNo: INTEGER; CmdShow: INTEGER);
BEGIN
  (* Show or hide a given button *)
  IF ((ButtonNo > 0) AND (ButtonNo <= NoToolButtons)) THEN
  BEGIN
    ShowWindow(ToolbuttonPntr[ButtonNo]^.HWindow, CmdShow);
  END;
END;


(**********************************************************************)
(* Methods of TToolButton from here onwards *)


CONSTRUCTOR TToolButton.Init(AParent: PWindowsObject; XPos, YPos: INTEGER;
                             EnB, DisEnB: HBitmap; WPR, LPR: INTEGER; En: BOOLEAN);
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, '');

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos;
    Y := YPos;
    W := 24;
    H := 22;
    Style := WS_CHILD OR WS_VISIBLE;
  END;

  (* Initialise member variables *)
  Enabled := En;
  EnBit := EnB;
  DisEnBit := DisEnB;
  WPAR := WPR;
  LPAR := LPR;

  strcopy(DownText, 'DSJDGFF');
  strcopy(UpText, 'DSJDGFF');

  (* These cannot be set through the constructor *)
  UpPosition := TRUE;
  LMseButton := FALSE;
END;


DESTRUCTOR TToolButton.Done;
BEGIN
  (* Free resources *)
  DeleteObject(EnBit);
  DeleteObject(DisEnBit);

  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TToolButton.GetWindowClass(VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.Style := CS_HREDRAW OR CS_VREDRAW;
  AWndClass.HIcon := LoadIcon (HInstance, IDI_APPLICATION);
END;


FUNCTION TToolButton.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'TOOLBUTTON';
END;


PROCEDURE TToolbutton.SetupWindow;
BEGIN
  (* Call ancestor method *)
  TWindow.SetupWindow;
END;


PROCEDURE TToolbutton.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);

  (* Actually paint the button *)
  PaintButton(PaintDC);
END;


PROCEDURE TToolbutton.PaintButton(TheDC: HDC);
VAR
  MemDC: HDC;
  MadeDC: BOOLEAN;
BEGIN
  (* Check to see that we are given a DC *)
  IF (TheDC = 0) THEN
  BEGIN
    TheDC := GetDC(HWindow);
    MadeDC := TRUE;
  END
  ELSE
    MadeDC := FALSE;

  (* Create a compatible DC *)
  MemDC := CreateCompatibleDC(TheDC);

  (* Paint the button *)
  IF (UpPosition) THEN
    SelectObject(MemDC, PToolBar(Parent)^.HButUp)
  ELSE
    SelectObject(MemDC, PToolBar(Parent)^.HButDown);

  (* BitBlt it *)
  BitBlt(TheDC, 0, 0, Attr.W, Attr.H, MemDC, 0, 0, SRCCopy);

  (* Draw actual button face *)
  IF (Enabled) THEN
  BEGIN
    IF (EnBit <> 0) THEN
    BEGIN
      SelectObject(MemDC, EnBit);
      IF (UpPosition) THEN
        BitBlt(TheDC, 3, 3, Attr.W, Attr.H, MemDC, 0, 0, SRCCopy)
      ELSE
        BitBlt(TheDC, 4, 4, Attr.W, Attr.H, MemDC, 0, 0, SRCCopy);
    END;
  END
  ELSE                    
  BEGIN
    IF (DisEnBit <> 0) THEN
    BEGIN
      SelectObject(MemDC, DisEnBit);
      BitBlt(TheDC, 3, 3, Attr.W, Attr.H, MemDC, 0, 0, SRCCopy);
    END;
  END;

  (* Delete compatible DC *)
  DeleteDC(MemDC);

  (* Release DC if we made one *)
  IF (MadeDC) THEN
    ReleaseDC(HWindow, TheDC);
END;


PROCEDURE TToolbutton.WMLButtonDown(VAR Msg: TMessage);
BEGIN
  (* Call ancestor method *)
  TWindow.WMLButtonDown(Msg);

  IF (Enabled) THEN
  BEGIN
    (* Reset button *)
    LMseButton := TRUE;
    UpPosition := FALSE;
    InvalidateRect(HWindow, NIL, TRUE);
    SetCapture(HWindow);

    (* Update status display *)
    IF (PMainWindow(PToolbar(Parent)^.Parent)^.StatbarExist) THEN
    BEGIN
      IF (StrComp('DSJDGFF', DownText) <> 0) THEN
        PMainWindow(PToolbar(Parent)^.Parent)^.StatbarHan^.SetText(0, DownText);
    END;
  END;
END;


PROCEDURE TToolbutton.WMLButtonUp(VAR Msg: TMessage);
VAR
  OldUpPosition: BOOLEAN;
BEGIN
  IF (Enabled) THEN
  BEGIN
    (* Reset button *)
    OldUpPosition := UpPosition;
    LMseButton := FALSE;
    ReleaseCapture;
    UpPosition := TRUE;
    InvalidateRect(HWindow, NIL, TRUE);

    (* Send message to main window *)
    IF NOT(OldUpPosition) THEN
    BEGIN
      PaintButton(0);
      PostMessage(PMainWindow(PToolbar(Parent)^.Parent)^.HWindow, WM_COMMAND, WPAR, LPAR);
    END;

    (* Update status display *)
    IF (PMainWindow(PToolbar(Parent)^.Parent)^.StatbarExist) THEN
    BEGIN
      IF (StrComp('DSJDGFF', UpText) <> 0) THEN
        PMainWindow(PToolbar(Parent)^.Parent)^.StatbarHan^.SetText(0, UpText);
    END;
  END;
END;


PROCEDURE TToolbutton.WMMouseMove(VAR Msg: TMessage);
VAR
  XPos, YPos: INTEGER;
BEGIN
  XPos := LOWORD(Msg.lParam);
  YPos := HIWORD(Msg.lParam);

  (* Reset button *)
  IF (((XPos < 0) OR (XPos > Attr.W)) OR ((YPos < 0) OR (YPos > Attr.H))) THEN
  BEGIN
    IF NOT(UpPosition) THEN
    BEGIN
      UpPosition := TRUE;
      InvalidateRect(HWindow, NIL, TRUE);
    END;
  END
  ELSE
  BEGIN
    IF (UpPosition AND LMseButton) THEN
    BEGIN
      UpPosition := FALSE;
      InvalidateRect(HWindow, NIL, TRUE);
    END;
  END;
END;


PROCEDURE TToolbutton.SetDownText(TextString: PChar);
BEGIN
  (* Set the down button text string *)
  strcopy(DownText, TextString);
END;


PROCEDURE TToolbutton.SetUpText(TextString: PChar);
BEGIN
  (* Set the down button text string *)
  strcopy(UpText, TextString);
END;


(**********************************************************************)
(* Methods of TStatbar from here onwards *)


CONSTRUCTOR TStatbar.Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
VAR
  ParentRect: TRect;
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, '');

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos -60;
    Y := YPos;
    W := Width;
    H := 80;
    Style := WS_CHILD OR WS_VISIBLE;
  END;

  (* Create a font record for the status bar font *)
  WITH StatbarFont DO
  BEGIN
    LFHeight := 16;
    LFWidth := 0;
    LFEscapement := 0;
    LFOrientation := 0;
    LFWeight := FW_NORMAL;
    LFItalic := 0;
    LFUnderline := 0;
    LFStrikeOut := 0;
    LFCharSet := ANSI_CHARSET;
    LFOutPrecision := OUT_STROKE_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := PROOF_QUALITY;
    lfPitchAndFamily := FF_DONTCARE;
    StrCopy (@LFFaceName, 'Arial');
  END;
  HStatbarFont := CreateFontIndirect(StatbarFont);

  (* Create pens *)
  DkGrayPen := CreatePen(PS_SOLID, 1, RGB(128, 128, 128));
  LtGrayPen := CreatePen(PS_SOLID, 1, RGB(200, 200, 200));
END;


DESTRUCTOR TStatbar.Done;
BEGIN
  (* Delete objects *)
  DeleteObject(HStatbarFont);
  DeleteObject(DkGrayPen);
  DeleteObject(LtGrayPen);

  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TStatbar.GetWindowClass(VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.Style := CS_HREDRAW OR CS_VREDRAW;
  AWndClass.HIcon := LoadIcon (HInstance, IDI_APPLICATION);
  AWndClass.HBRBackground := COLOR_BTNFACE + 1;
END;


FUNCTION TStatbar.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'STATUS_BAR';
END;


PROCEDURE TStatbar.SetupWindow;
BEGIN
  (* Call ancestor method *)
  TWindow.SetupWindow;

  (* Default values *)
  strcopy(Text, 'Nonogram Solver - Version 2.0');
  strcopy(TimeText, 'N/A');
  strcopy(PointText, '0');
END;
                                                     

PROCEDURE TStatbar.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);

  (* Draw text *)
  SetText(PaintDC, Text);
  SetTime(PaintDC, TimeText, PointText);
END;


PROCEDURE TStatbar.SetText(TheDC: HDC; TextString: PChar);
VAR
  MadeDC: BOOLEAN;
  TempX: INTEGER;
BEGIN
  (* Set the status bar text to that specified in TextString *)
  strcopy(Text, TextString);

  (* Check to see that we are given a DC *)
  IF (TheDC = 0) THEN
  BEGIN
    TheDC := GetDC(HWindow);
    MadeDC := TRUE;
  END
  ELSE
    MadeDC := FALSE;

  TempX := Attr.W-100;
  IF (TempX < 5) THEN TempX := 5;

  (* Draw the surrounding box *)
  SelectObject(TheDC, DkGrayPen);
  MoveTo(TheDC, TempX, 2);
  LineTo(TheDC, 5, 2);
  LineTo(TheDC, 5, 19);

  SelectObject(TheDC, GetStockObject(WHITE_PEN));
  LineTo(TheDC, TempX, 19);
  LineTo(TheDC, TempX, 3);

  (* Clear the old text box *)
  SelectObject(TheDC, LtGrayPen);
  SelectObject(TheDC, GetStockObject(LTGRAY_BRUSH));
  Rectangle(TheDC, 6, 3, (TempX-1), 19);

  (* Select status bar font *)
  SelectObject(TheDC, HStatbarFont);

  (* Set up colours *)
  SetBkColor(TheDC, RGB(180, 180, 180));
  SetTextColor(TheDC, RGB(0, 0, 0));

  (* Set up clipping region *)
  IntersectClipRect(TheDC, 5, 2, TempX, 19);

  (* Draw the text *)
  TextOut(TheDC, 10, 3, Text, strlen(Text));

  (* Reset clipping region *)
  SelectClipRgn(TheDC, 0);

  (* Release DC *)
  IF (MadeDC) THEN
    ReleaseDC(HWindow, TheDC);
END;


PROCEDURE TStatbar.SetTime(TheDC: HDC; TextString, TextStrtwo: PChar);
VAR
  MadeDC: BOOLEAN;
BEGIN
  (* Set the status bar text to that specified in TextString *)
  strcopy(TimeText, TextString);
  strcopy(PointText, TextStrtwo);

  (* Check to see that we are given a DC *)
  IF (TheDC = 0) THEN
  BEGIN
    TheDC := GetDC(HWindow);
    MadeDC := TRUE;
  END
  ELSE
    MadeDC := FALSE;

  (* Draw time status box *)
  SelectObject(TheDC, DkGrayPen);
  MoveTo(TheDC, (Attr.W-40), 2);
  LineTo(TheDC, (Attr.W-95), 2);
  LineTo(TheDC, (Attr.W-95), 19);

  SelectObject(TheDC, GetStockObject(WHITE_PEN));
  LineTo(TheDC, (Attr.W-40), 19);
  LineTo(TheDC, (Attr.W-40), 3);

  (* Draw number of points box *)
  SelectObject(TheDC, DkGrayPen);
  MoveTo(TheDC, (Attr.W-5), 2);
  LineTo(TheDC, (Attr.W-35), 2);
  LineTo(TheDC, (Attr.W-35), 19);

  SelectObject(TheDC, GetStockObject(WHITE_PEN));
  LineTo(TheDC, (Attr.W-5), 19);
  LineTo(TheDC, (Attr.W-5), 3);

  (* Clear old boxes *)
  SelectObject(TheDC, LtGrayPen);
  SelectObject(TheDC, GetStockObject(LTGRAY_BRUSH));
  Rectangle(TheDC, (Attr.W-94), 3, (Attr.W-40), 19);
  Rectangle(TheDC, (Attr.W-34), 3, (Attr.W-5), 19);

  (* Select status bar font *)
  SelectObject(TheDC, HStatbarFont);

  (* Set up colours *)
  SetBkColor(TheDC, RGB(180, 180, 180));
  SetTextColor(TheDC, RGB(0, 0, 0));

  (* Set clipping and then draw the text *)
  TextOut(TheDC, (Attr.W-30), 3, PointText, strlen(PointText));
  TextOut(TheDC, (Attr.W-90), 3, TimeText, strlen(TimeText));

  (* Release DC *)
  IF (MadeDC) THEN
    ReleaseDC(HWindow, TheDC);
END;


(**********************************************************************)
(* Methods of TDisplay from here onwards *)


CONSTRUCTOR TDisplay.Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, '');

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos;
    Y := YPos;
    W := Width;
    H := Height;
    Style := WS_CHILD OR WS_VISIBLE OR WS_VSCROLL OR WS_HSCROLL;
  END;

  (* Initialize variables *)
  VScrollBarPresent := FALSE;
  HScrollBarPresent := FALSE;

  (* Read initialisation file (NONOGRAM.INI) *)
  XAcross := GetPrivateProfileInt('Main Window', 'XAcross', 20, 'NONOGRAM.INI');
  YAcross := GetPrivateProfileInt('Main Window', 'YAcross', 25, 'NONOGRAM.INI');

  (* Initialize scrollbars *)
  Scroller := New(PScroller, Init(@self, 14, 14, (XAcross+3), (YAcross+3)));
END;


DESTRUCTOR TDisplay.Done;
BEGIN
  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TDisplay.GetWindowClass(VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.Style := CS_HREDRAW OR CS_VREDRAW;
  AWndClass.HIcon := LoadIcon (HInstance, IDI_APPLICATION);
END;


FUNCTION TDisplay.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'NONOGRAM_DISPLAY';
END;


PROCEDURE TDisplay.SetupWindow;
BEGIN
  (* Call ancestor method *)                   
  TWindow.SetupWindow;

  (* Reset all the arrays etc *)
  ResetData;
END;


PROCEDURE TDisplay.WMSize(VAR Msg: TMessage);
VAR
  Value: INTEGER;
BEGIN
  (* Call ancestor method *)
  TWindow.WMSize(Msg);

  (* Handle horizontal scroll bar *)
  IF ((PMainWindow(Parent)^.DisplayRotate = Zero) OR
      (PMainWindow(Parent)^.DisplayRotate = OneE)) THEN
    Value := XAcross*14+42
  ELSE
    Value := YAcross*14+42;
  IF (VScrollBarPresent) THEN Value := Value + 20;
  IF (Attr.W < Value) THEN
  BEGIN
    ShowScrollBar(HWindow, SB_HORZ, TRUE);
    HScrollBarPresent := TRUE;
  END
  ELSE
  BEGIN
    ShowScrollBar(HWindow, SB_HORZ, FALSE);
    HScrollBarPresent := FALSE;
  END;

  (* Handle vertical scroll bar *)
  IF ((PMainWindow(Parent)^.DisplayRotate = Zero) OR
      (PMainWindow(Parent)^.DisplayRotate = OneE)) THEN
    Value := YAcross*14+42
  ELSE
    Value := XAcross*14+42;
  IF (HScrollbarPresent) THEN Value := Value + 20;
  IF (Attr.H < Value) THEN
  BEGIN
    ShowScrollBar(HWindow, SB_VERT, TRUE);
    VScrollBarPresent := TRUE;
  END
  ELSE
  BEGIN
    ShowScrollBar(HWindow, SB_VERT, FALSE);
    VScrollBarPresent := FALSE;
  END;
END;


PROCEDURE TDisplay.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
VAR
  A, B: INTEGER;
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);

  (* Draw the grid axes *)
  DrawAxes(PaintDC);

  (* Draw in Nonogram grid data *)
  FOR A := 1 TO XAcross DO
    FOR B := 1 TO YAcross DO
      DrawPoint(PaintDC, A, B, ScreenGrid[A, B], TRUE);
END;


PROCEDURE TDisplay.DrawPoint(TheDC: HDC; XPos, YPos, BlockDot: INTEGER; Allways: BOOLEAN);
VAR
  MadeDC: BOOLEAN;
  XPhys, YPhys, XAct, YAct, Temp: INTEGER;
BEGIN
  (* Check to see that this point should be drawn *)
  IF (((ScreenGrid[XPos, YPos] = 0) OR ((ScreenGrid[XPos, YPos] > 0) AND Allways)) AND
      ((XPos > 0) AND (YPos > 0) AND (YPos <= YAcross) AND (XPos <= XAcross))) THEN
  BEGIN
    (* Check to see that we are given a DC *)
    IF (TheDC = 0) THEN
    BEGIN
      TheDC := GetDC(HWindow);
      MadeDC := TRUE;
    END
    ELSE
      MadeDC := FALSE;

    (* Calculate the actual physical device position from OUR logical coordinates *)
    IF (PMainWindow(Parent)^.DisplayFlip) THEN
      XPhys := XAcross+1-XPos
    ELSE
      XPhys := XPos;
    YPhys := YPos;


    (* Display rotations *)
    CASE (PMainWindow(Parent)^.DisplayRotate) OF
      Zero :
      BEGIN
        XPhys := XPhys;
        YPhys := YPhys;
      END;

      Nine :
      BEGIN
        Temp  := XPhys;
        XPhys := YPhys;
        YPhys := XAcross+1-Temp;
      END;

      OneE :
      BEGIN
        XPhys := XAcross+1-XPhys;
        YPhys := YAcross+1-YPhys;
      END;

      TwoS :
      BEGIN
        Temp  := XPhys;
        XPhys := YAcross+1-YPhys;
        YPhys := Temp;
      END;
    END;

    (* Calculate block postions *)
    XAct := 22 + 14 * XPhys;
    YAct := 14 * YPhys;

    (* Draw actual blocks on the screen *)
    CASE BlockDot OF
      0 :
      BEGIN
        (* Draw an empty square block *)
        SelectObject(TheDC, PMainWindow(Parent)^.BackBrush);
        Rectangle(TheDC, XAct, YAct, (XAct + 14), (YAct + 14));
      END;

      1 :
      BEGIN
        (* Draw a filled in block *)
        IF (ScreenGrid[XPos, YPos] = 0) THEN
          INC(PlotTotal);
        SelectObject(TheDC, PMainWindow(Parent)^.BlockBrush);
        Rectangle(TheDC, XAct, YAct, (XAct + 14), (YAct + 14));
        ScreenGrid[XPos, YPos] := 1;
      END;
   
      2 :
      BEGIN
        (* Draw a space style square block *) 
        IF (ScreenGrid[XPos, YPos] = 0) THEN
          INC(PlotTotal);
        SelectObject(TheDC, PMainWindow(Parent)^.DotBrush);
        Rectangle(TheDC, XAct, YAct, (XAct + 14), (YAct + 14));
        ScreenGrid[XPos, YPos] := 2;
      END;
    END;

    (* Release DC if we made one *)
    IF (MadeDC) THEN
      ReleaseDC(HWindow, TheDC);
  END;
END;


PROCEDURE TDisplay.DrawAxes(TheDC: HDC);
VAR
  MadeDC: BOOLEAN;
  A, B, YAct, XAct: INTEGER;
  TextString: ARRAY [0..80] OF CHAR;
BEGIN
  (* Check to see if passed a DC *)
  IF (TheDC = 0) THEN
  BEGIN
    TheDC := GetDC(HWindow);
    MadeDC := TRUE;
  END
  ELSE
    MadeDC := FALSE;

  (* Set up colours *)
  SetBkColor(TheDC, GetSysColor(COLOR_WINDOW));
  SetTextColor(TheDC, GetSysColor(COLOR_WINDOWTEXT));
  SelectObject(TheDC, PMainWindow(Parent)^.HAxesVFont);

  (* Check to see if we should rotate the axes *)
  IF ((PMainWindow(Parent)^.DisplayRotate = Nine) OR
      (PMainWindow(Parent)^.DisplayRotate = TwoS)) THEN
  BEGIN
    YAct := XAcross;
    XAct := YAcross;
  END
  ELSE
  BEGIN
    YAct := YAcross;
    XAct := XAcross;
  END;  

  (* Draw the main window axes *)
  FOR A := 1 TO YAct DO
  BEGIN
    SetTextAlign(TheDC, TA_RIGHT);
    Str(A, TextString);
    TextOut(TheDC, 25, (14*A), TextString, StrLen(TextString));
  END;

  (* Select horizontal font *)
  SelectObject(TheDC, PMainWindow(Parent)^.HAxesHFont);

  (* Draw horizontal scales *)
  B := 20+(14*YAct);
  FOR A := 1 TO XAct DO
  BEGIN
    Str(A, TextString);
    TextOut(TheDC, 23+(14*A), B, TextString, StrLen(TextString));
  END;

  (* If 'MadeDC' then dispose of it *)
  IF (MadeDC) THEN
    ReleaseDC(HWindow, TheDC);
END;


PROCEDURE TDisplay.QuickData;
VAR
  I, J: INTEGER;                       
  Tot: INTEGER;
BEGIN
  (* Work across in the XAcross direction *)
  FOR I := 1 TO XAcross DO
  BEGIN
    Tot := 0; J := 1;
    WHILE ((XElements[I, J] > 0) AND (J <= MaxNoElements)) DO
    BEGIN
      (* Add up value of elements in this row *)
      Tot := Tot + 1 + XElements[I, J];
      INC(J);
    END;
    Tot := Tot - 1;

    (* Check to decide what to do now *)
    IF (Tot = YAcross) THEN EasyFill(I, 0);
    IF (Tot > (YAcross DIV 2)) THEN FillDot(I, 0, Tot);
  END;

  (* Work across in the YAcross direction *)
  FOR I := 1 TO YAcross DO
  BEGIN
    Tot := 0; J := 1;
    WHILE ((YElements[I, J] > 0) AND (J <= MaxNoElements)) DO
    BEGIN
      (* Add up value of elemnts in this row *)
      Tot := Tot + 1 + YElements[I, J];
      INC(J);
    END;
    Tot := Tot - 1;

    (* Check to decide what to do now *)
    IF (Tot = XAcross) THEN EasyFill(I, 1);
    IF (Tot > (XAcross DIV 2)) THEN FillDot(I, 1, Tot);
  END;
END;


PROCEDURE TDisplay.CheckEdge;
VAR
  I, J, T: INTEGER;
  Value: INTEGER;
BEGIN

  (* This procedure checks for dots at the edge of the grid
     and fills in any known data following these dots *)

  (* Work in the XAcross direction first *)
  FOR I := 1 TO XAcross DO
  BEGIN
    IF (ScreenGrid[I, 1] = 1) THEN
    BEGIN
      (* Found some data so draw it in *)
      FOR J := 1 TO XElements[I, 1] DO
        DrawPoint(0, I, J, 1, FALSE);
      J := XElements[I, 1] + 1;
      DrawPoint(0, I, J, 2, FALSE);
    END;

    IF (ScreenGrid[I, YAcross] = 1) THEN
    BEGIN
      (* Find the value of the last block in this row/column *) 
      J := 1;
      WHILE ((XElements[I, J] > 0) AND (J <= MaxNoElements)) DO
      BEGIN
        Value := XElements[I, J];
        INC(J);
      END;

      (* Draw the data in *)
      FOR J := (YAcross+1-Value) TO YAcross DO
        DrawPoint(0, I, J, 1, FALSE);
      DrawPoint(0, I, (YAcross - Value), 2, FALSE);
    END; 
  END;

  (* Now work in the YAcross direction *)
  FOR I := 1 TO YAcross DO
  BEGIN
    IF (ScreenGrid[1, I] = 1) THEN
    BEGIN
      (* Found some data so draw it in *)
      FOR J := 1 TO YElements[I, 1] DO
        DrawPoint(0, J, I, 1, FALSE);
      J := YElements[I, 1] + 1;
      DrawPoint(0, J, I, 2, FALSE);
    END;

    IF (ScreenGrid[XAcross, I] = 1) THEN
    BEGIN
      (* Find the value of the last block in this row/column *) 
      J := 1;
      WHILE ((YElements[I, J] > 0) AND (J <= MaxNoElements)) DO
      BEGIN
        Value := YElements[I, J];
        INC(J);
      END;

      (* Draw the data in *)
      FOR J := (XAcross+1-Value) TO YAcross DO
        DrawPoint(0, J, I, 1, FALSE);
      DrawPoint(0, (XAcross - Value), I, 2, FALSE);
    END; 
  END;
END;


PROCEDURE TDisplay.TestRowFull;
VAR
  Dot: ARRAY [1..MaxNoElements] OF INTEGER;
  I, J, S: INTEGER;
  Value, K: INTEGER;
  Total: INTEGER;
  Postn: INTEGER;
  AOk: INTEGER;
BEGIN
  (* This procedure sums the values of filled blocks
     in a row and checks to see if the row is full *)

  (* Work in the XAcross direction *)
  FOR I := 1 TO XAcross DO
  BEGIN
    (* Initialise variables *)
    Total := 0; Postn := 1; AOk := 1;

    FOR S := 1 TO MaxNoElements DO
      Dot[S] := 0;

    (* Add up the values of the elements in this direction *)
    FOR J := 1 TO YAcross DO
    BEGIN
      Value := ScreenGrid[I, J];
      IF (Value = 1) THEN
      BEGIN
        INC(Total);
      END
      ELSE
      BEGIN
        IF (Total > 0) THEN
        BEGIN
          Dot[Postn] := Total;
          INC(Postn);

          (* Check to see that value of Postn is still valid *)
          IF (Postn > MaxNoElements) THEN
          BEGIN
            Postn := 1; AOk := 0;
          END;
        END;
        Total := 0;
      END;
    END;
    IF (Total > 0) THEN Dot[Postn] := Total;

    (* Compare screen data with actual data *)
    FOR S := 1 TO MaxNoElements DO
      IF (Dot[S] <> XElements[I, S]) THEN AOk := 0;

    (* If everything OK then draw points *)
    IF (AOk = 1) THEN
    BEGIN
      FOR K := 1 TO YAcross DO
        IF (ScreenGrid[I, K] <> 1) THEN DrawPoint(0, I, K, 2, FALSE);
      XFilled[I] := 1;
    END;
  END;

  (* Now work across in the YAcross direction *)
  FOR I := 1 TO YAcross DO
  BEGIN
    (* Initialise variables *)
    Total := 0; Postn := 1; AOk := 1;

    FOR S := 1 TO MaxNoElements DO
      Dot[S] := 0;

    (* Add up the values of the elements in this direction *)
    FOR J := 1 TO XAcross DO
    BEGIN
      Value := ScreenGrid[J, I];
      IF (Value = 1) THEN
      BEGIN
        INC(Total);
      END
      ELSE
      BEGIN
        IF (Total > 0) THEN
        BEGIN
          Dot[Postn] := Total;
          INC(Postn);

          (* Check to see that the value of Postn is still valid *)
          IF (Postn > MaxNoElements) THEN
          BEGIN
            Postn := 1; AOk := 0;
          END;
        END;
        Total := 0;
      END;
    END;
    IF (Total > 0) THEN Dot[Postn] := Total;

    (* Compare screen data with actual data *)
    FOR S := 1 TO MaxNoElements DO
      IF (Dot[S] <> YElements[I, S]) THEN AOk := 0;

    (* If everything OK then draw points *)
    IF (AOk = 1) THEN
    BEGIN
      FOR K := 1 TO XAcross DO
        IF (ScreenGrid[K, I] <> 1) THEN DrawPoint(0, K, I, 2, FALSE);
      YFilled[I] := 1;
    END;
  END;
END;


PROCEDURE TDisplay.FollowRow;
VAR
  I, J, K, M: INTEGER;
  Jump, Find: INTEGER;
  DotPlace: INTEGER;
  DotPl: INTEGER;

  PreviousDot, KeepGoing: BOOLEAN;
  CurrentBlock: INTEGER;
BEGIN
  (* This procedure attempts to fill in blocks on partly filled rows *)

  (* Work from 0 upwards in the XAcross direction *)
  FOR I := 1 TO XAcross DO
  BEGIN
    (* If the row is not already full then... *)
    IF (XFilled[I] <> 1) THEN
    BEGIN
      (* Intialise variables *)
      PreviousDot := TRUE;
      KeepGoing := TRUE;
      J := 1;
      CurrentBlock := 1;

      WHILE (KeepGoing) DO
      BEGIN
        IF (ScreenGrid[I, J] = 1) THEN
        BEGIN
          (* Decide if we should draw in some extra data *)
          IF (PreviousDot AND KeepGoing) THEN
          BEGIN
            (* Draw in the points following this dot *)
            FOR K := J TO (J+XElements[I, CurrentBlock]-1) DO
              DrawPoint(0, I, K, 1, FALSE);
            IF (K+1 <= YAcross) THEN
              DrawPoint(0, I, K+1, 2, FALSE);
            INC(CurrentBlock);

            J := K+2;
            IF (J > YAcross) THEN KeepGoing := FALSE;
          END
          ELSE
          BEGIN
            INC(J);
            IF (J > YAcross) THEN KeepGoing := FALSE;
            PreviousDot := FALSE;
          END;
        END;

        IF (ScreenGrid[I, J] = 2) THEN
        BEGIN
          (* Well the previous one was a dot *)
          PreviousDot := TRUE;
          INC(J);
          IF (J > YAcross) THEN KeepGoing := FALSE;
        END;

        IF (ScreenGrid[I, J] = 0) THEN
        BEGIN
          (* Better stop *)
          KeepGoing := FALSE;
          INC(J);
          IF (J > YAcross) THEN KeepGoing := FALSE;
        END;
      END;
    END;
  END;

  (* Work from YAcross downwards in the XAcross direction *)
  FOR I := 1 TO XAcross DO
  BEGIN
    (* If the row is not already full then... *)
    IF (XFilled[I] <> 1) THEN
    BEGIN
      (* Initialise variables *)
      PreviousDot := TRUE;
      KeepGoing := TRUE;
      J := YAcross;

      CurrentBlock := MaxNoElements;
      WHILE (XElements[I, CurrentBlock] = 0) DO
      BEGIN
        DEC(CurrentBlock);
      END;

      WHILE (KeepGoing) DO
      BEGIN
        IF (ScreenGrid[I, J] = 1) THEN
        BEGIN
          (* Decide if we should draw in some extra data *)
          IF (PreviousDot AND KeepGoing) THEN
          BEGIN
            (* Draw in the points following this dot *)
            FOR K := J DOWNTO (J-XElements[I, CurrentBlock]+1) DO
              DrawPoint(0, I, K, 1, FALSE);
            IF (K-1 >= 1) THEN
              DrawPoint(0, I, K-1, 2, FALSE);
            DEC(CurrentBlock);

            J := K-2;
            IF (J < 1) THEN KeepGoing := FALSE;
          END
          ELSE
          BEGIN
            DEC(J);
            IF (J < 1) THEN KeepGoing := FALSE;
            PreviousDot := FALSE;
          END;
        END;

        IF (ScreenGrid[I, J] = 2) THEN
        BEGIN
          (* Well the previous one was a dot *)
          PreviousDot := TRUE;
          DEC(J);
          IF (J < 1) THEN KeepGoing := FALSE;
        END;

        IF (ScreenGrid[I, J] = 0) THEN
        BEGIN
          (* Better stop *)
          KeepGoing := FALSE;
          DEC(J);
          IF (J < 1) THEN KeepGoing := FALSE;
        END;
      END;
    END;
  END;

  (* Work from 0 upwards in the YAcross direction *)
  FOR I := 1 TO YAcross DO
  BEGIN
    (* If the row is not already full then... *)
    IF (YFilled[I] <> 1) THEN
    BEGIN
      (* Intialise variables *)
      PreviousDot := TRUE;
      KeepGoing := TRUE;
      J := 1;
      CurrentBlock := 1;

      WHILE (KeepGoing) DO
      BEGIN
        IF (ScreenGrid[J, I] = 1) THEN
        BEGIN
          (* Decide if we should draw in some extra data *)
          IF (PreviousDot AND KeepGoing) THEN
          BEGIN
            (* Draw in the points following this dot *)
            FOR K := J TO (J+YElements[I, CurrentBlock]-1) DO
              DrawPoint(0, K, I, 1, FALSE);
            IF (K+1 <= XAcross) THEN
              DrawPoint(0, K+1, I, 2, FALSE);
            INC(CurrentBlock);

            J := K+2;
            IF (J > XAcross) THEN KeepGoing := FALSE;
          END
          ELSE
          BEGIN
            INC(J);
            IF (J > XAcross) THEN KeepGoing := FALSE;
            PreviousDot := FALSE;
          END;
        END;

        IF (ScreenGrid[J, I] = 2) THEN
        BEGIN
          (* Well the previous one was a dot *)
          PreviousDot := TRUE;
          INC(J);
          IF (J > XAcross) THEN KeepGoing := FALSE;
        END;

        IF (ScreenGrid[J, I] = 0) THEN
        BEGIN
          (* Better stop *)
          KeepGoing := FALSE;
          INC(J);
          IF (J > XAcross) THEN KeepGoing := FALSE;
        END;
      END;
    END;
  END;

 (* Work from XAcross downwards in the YACross direction *)
  FOR I := 1 TO YAcross DO
  BEGIN
    (* If the row is not already full then... *)
    IF (XFilled[I] <> 1) THEN
    BEGIN
      (* Initialise variables *)
      PreviousDot := TRUE;
      KeepGoing := TRUE;
      J := XAcross;

      CurrentBlock := MaxNoElements;
      WHILE (YElements[I, CurrentBlock] = 0) DO
      BEGIN
        DEC(CurrentBlock);
      END;

      WHILE (KeepGoing) DO
      BEGIN
        IF (ScreenGrid[J, I] = 1) THEN
        BEGIN
          (* Decide if we should draw in some extra data *)
          IF (PreviousDot AND KeepGoing) THEN
          BEGIN
            (* Draw in the points following this dot *)
            FOR K := J DOWNTO (J-YElements[I, CurrentBlock]+1) DO
              DrawPoint(0, K, I, 1, FALSE);
            IF (K-1 >= 1) THEN
              DrawPoint(0, K-1, I, 2, FALSE);
            DEC(CurrentBlock);

            J := K-2;
            IF (J < 1) THEN KeepGoing := FALSE;
          END
          ELSE
          BEGIN
            DEC(J);
            IF (J < 1) THEN KeepGoing := FALSE;
            PreviousDot := FALSE;
          END;
        END;

        IF (ScreenGrid[J, I] = 2) THEN
        BEGIN
          (* Well the previous one was a dot *)
          PreviousDot := TRUE;
          DEC(J);
          IF (J < 1) THEN KeepGoing := FALSE;
        END;

        IF (ScreenGrid[J, I] = 0) THEN
        BEGIN
          (* Better stop *)
          KeepGoing := FALSE;
          DEC(J);
          IF (J < 1) THEN KeepGoing := FALSE;
        END;
      END;
    END;
  END;

END;


PROCEDURE TDisplay.Combination;
VAR
  A, B, I, M, R, T, U, V, Comp: INTEGER;
  BlockLookingAt: INTEGER;
  Flag: INTEGER;
  Finish: INTEGER;
  PotenNum: INTEGER;
  NotFinished: BOOLEAN;
  Moving: BOOLEAN;
  More: BOOLEAN;
BEGIN

  (* Work in the XAcross direction firstly *)
  FOR I := 1 TO XAcross DO
  BEGIN
    (* Check to see if there are any messages waiting in the
       applications message queue *)
    IF (PeekMessage(SentMessage, 0, 0, 0, PM_REMOVE)) THEN
    BEGIN
      IF ((SentMessage.Message = WM_COMMAND) AND (SentMessage.wParam = CM_STOPSO)) THEN
        PMainWindow(Parent)^.CanThink := FALSE;
      TranslateMessage(SentMessage);
      DispatchMessage(SentMessage);
    END;

    (* Check to see if this row is fully filled already *)
    IF ((XFilled[I] <> 1) AND PMainWindow(Parent)^.CanThink) THEN
    BEGIN
      (* Initialise variables *)
      More := FALSE;
      PotenNum := 1;
      NotFinished := TRUE;

      (* How many elements in this row have values greater than zero *)
      T := 0;
      WHILE NOT(XElements[I, T + 1] = 0) DO
        INC(T);

      (* Calculate starting positions of each block *)
      Start[1] := 1;
      FOR M := 1 TO T - 1 DO
        Start[M + 1] := Start[M] + XElements[I, M] + 1;

      WHILE (NotFinished) DO
      BEGIN
        (* Reset array holding possible position data *)
        FOR M := 1 TO YAcross DO
          PossiblePos[M] := 2;

        FOR A := 1 TO T DO
          FOR B := Start[A] TO (Start[A] + XElements[I, A] - 1) DO
            PossiblePos[B] := 1;

        (* Check this arrangement with data already obtained *)
        Flag := 0; A := 1;
        WHILE ((A <= YAcross) AND (Flag = 0)) DO
        BEGIN
          IF ((PossiblePos[A] = 1) AND (ScreenGrid[I, A] = 2)) THEN Flag := 1;
          IF ((PossiblePos[A] = 2) AND (ScreenGrid[I, A] = 1)) THEN Flag := 1;
          INC(A);
        END;

        IF (Flag = 0) THEN
        BEGIN
          FOR A := 1 TO YAcross DO
             PMainWindow(Parent)^.PotentData^.Data[A, PotenNum] := PossiblePos[A];
          INC(PotenNum);

          (* Check potential combinations number, PotenNum *)
          IF (PotenNum > PMainWindow(Parent)^.VARSSize) THEN
          BEGIN
            NotFinished := FALSE;
            More := TRUE;
          END;
        END;

        (* Now rearrange the order of the blocks *)
        BlockLookingAt := T;
        Moving := TRUE;

        WHILE (Moving) DO
        BEGIN
          Finish := Start[BlockLookingAt];
          INC(Start[BlockLookingAt]);

          (* Calculate the position of the very last filled square *)
          FOR R := BlockLookingAt TO T DO
            Finish := Finish + XElements[I, R] + 1;
          Finish := Finish - 1;

          (* Move any blocks following the one that was moved *)
          U := BlockLookingAt;
          WHILE (U < T) DO
          BEGIN
            Start[U + 1] := Start[U] + 1 + XElements[I, U];
            U := U + 1;
          END;

          (* Have blocks been moved further than the limit? *)
          IF (Finish > YAcross) THEN
          BEGIN
            DEC(BlockLookingAt);
            IF (BlockLookingAt = 0) THEN
            BEGIN
              Moving := FALSE;
              NotFinished := FALSE;
            END;
          END
          ELSE
            Moving := FALSE;
        END;
      END; 

      (* Now actually draw the blocks on the screen *)
      IF NOT(More) THEN
      BEGIN
        FOR A := 1 TO YAcross DO
        BEGIN
          Comp := PMainWindow(Parent)^.PotentData^.Data[A, 1];
          FOR B := 2 TO (PotenNum - 1) DO
            IF (Comp <> PMainWindow(Parent)^.PotentData^.Data[A, B]) THEN Comp := 0;
          IF (Comp <> 0) THEN
          BEGIN
            DrawPoint(0, I, A, Comp, FALSE);
          END;
        END;
      END;
    END;
  END;


  (* Now work in the YAcross direction firstly *)
  FOR I := 1 TO YAcross DO
  BEGIN
    (* Check to see if there are any messages waiting in the
       applications message queue *)
    IF (PeekMessage(SentMessage, 0, 0, 0, PM_REMOVE)) THEN
    BEGIN
      IF ((SentMessage.Message = WM_COMMAND) AND (SentMessage.wParam = CM_STOPSO)) THEN
        PMainWindow(Parent)^.CanThink := FALSE;
      TranslateMessage(SentMessage);
      DispatchMessage(SentMessage);
    END;

    (* Check to see if this row is fully filled already *)
    IF ((YFilled[I] <> 1) AND PMainWindow(Parent)^.CanThink) THEN
    BEGIN
      (* Initialise variables *)
      More := FALSE;
      PotenNum := 1;
      NotFinished := TRUE;

      (* How many elements in this row have values greater than zero *)
      T := 0;
      WHILE NOT(YElements[I, T + 1] = 0) DO
        INC(T);

      (* Calculate starting positions of each block *)
      Start[1] := 1;
      FOR M := 1 TO T - 1 DO
        Start[M + 1] := Start[M] + YElements[I, M] + 1;

      WHILE (NotFinished) DO
      BEGIN
        (* Reset array holding possible position data *)
        FOR M := 1 TO XAcross DO
          PossiblePos[M] := 2;

        FOR A := 1 TO T DO
          FOR B := Start[A] TO (Start[A] + YElements[I, A] - 1) DO
            PossiblePos[B] := 1;

        (* Check this arrangement with data already obtained *)
        Flag := 0; A := 1;
        WHILE ((A <= XAcross) AND (Flag = 0)) DO
        BEGIN
          IF ((PossiblePos[A] = 1) AND (ScreenGrid[A, I] = 2)) THEN Flag := 1;
          IF ((PossiblePos[A] = 2) AND (ScreenGrid[A, I] = 1)) THEN Flag := 1;
          INC(A);
        END;

        IF (Flag = 0) THEN
        BEGIN
          FOR A := 1 TO XAcross DO
            PMainWindow(Parent)^.PotentData^.Data[A, PotenNum] := PossiblePos[A];
          INC(PotenNum);

          (* Check potential combinations number, PotenNum *)
          IF (PotenNum > PMainWindow(Parent)^.VARSSize) THEN
          BEGIN
            NotFinished := FALSE;
            More := TRUE;
          END;
        END;

        (* Now rearrange the order of the blocks *)
        BlockLookingAt := T;
        Moving := TRUE;

        WHILE (Moving) DO
        BEGIN
          Finish := Start[BlockLookingAt];
          INC(Start[BlockLookingAt]);

          (* Calculate the position of the very last filled square *)
          FOR R := BlockLookingAt TO T DO
            Finish := Finish + YElements[I, R] + 1;
          Finish := Finish - 1;

          (* Move any blocks following the one that was moved *)
          U := BlockLookingAt;
          WHILE (U < T) DO
          BEGIN
            Start[U + 1] := Start[U] + 1 + YElements[I, U];
            U := U + 1;
          END;

          (* Have blocks been moved further than the limit? *)
          IF (Finish > XAcross) THEN
          BEGIN
            DEC(BlockLookingAt);
            IF (BlockLookingAt = 0) THEN
            BEGIN
              Moving := FALSE;
              NotFinished := FALSE;
            END;
          END
          ELSE
            Moving := FALSE;
        END;
      END; 
 
      (* Actually draw the data on the screen *)
      IF NOT(More) THEN
      BEGIN
        FOR A := 1 TO XAcross DO
        BEGIN
          Comp := PMainWindow(Parent)^.PotentData^.Data[A, 1];
          FOR B := 2 TO (PotenNum - 1) DO
            IF (Comp <> PMainWindow(Parent)^.PotentData^.Data[A, B]) THEN Comp := 0;
          IF (Comp <> 0) THEN
          BEGIN
            DrawPoint(0, A, I, Comp, FALSE);
          END;
        END;
      END;
    END;
  END;

END;


PROCEDURE TDisplay.EasyFill(I, K: INTEGER);
VAR
  P, J, T: INTEGER;
BEGIN
  (* This procedure will fill in all the dots
     for a row that has been fully defined *)

  (* Modify array containing filled row data *)
  IF (K = 0) THEN
  BEGIN
    XFilled[I] := 1;
    J := 1; P := 0;
    WHILE ((XElements[I, J] > 0) AND (J <= MaxNoElements)) DO
    BEGIN
      (* Fill the whole row in the XAcross direction *)
      FOR T := 1 TO (XElements[I, J]) DO
        DrawPoint(0, I, (P+T), 1, FALSE);
      P := P + XElements[I, J];

      (* Check to see if we should draw following dot *)
      IF (P < YAcross) THEN DrawPoint(0, I, (P+1), 2, FALSE);
      INC(P);
      INC(J);
    END; 
  END
  ELSE
  BEGIN
    YFilled[I] := 1;
    J := 1; P := 0;
    WHILE ((YElements[I, J] > 0) AND (J <= MaxNoElements)) DO
    BEGIN
      (* Fill the whole row in the YAcross direction *)
      FOR T := 1 TO (YElements[I, J]) DO
        DrawPoint(0, (P+T), I, 1, FALSE);
      P := P + YElements[I, J];

      (* Check to see if we should draw following dot *)
      IF (P < XAcross) THEN DrawPoint(0, (P+1), I, 2, FALSE);
      INC(P);
      INC(J);
    END; 
  END;
END;


PROCEDURE TDisplay.FillDot(Iin, Kin, STot: INTEGER);
VAR
  A, J, L, M, N, P, S: INTEGER;
  AOk, Left, Right,
  Value, GapSize,
  StartPos, StopPos : INTEGER;
BEGIN
  (* This procedure draws in data for partly filled rows.
     It is called from QuickData *)

  P := 0; J := 0;

  FOR J := 1 TO MaxNoElements DO
  BEGIN
    IF (Kin = 0) THEN
    BEGIN
      (* Work in the XAcross direction *)

      (* Get the size of the block in row 'Iin' at position 'J' (ie before block 'J') *)
      A := XElements[Iin, J];
      AOk := 0; Left := 0; Right := 0;

      (* Sum values of the blocks prior to this block *)
      FOR L := 1 TO (J - 1) DO
      BEGIN
        Value := XElements[Iin, L];
        IF (Value > 0) THEN Left := Left + 1 + Value;
      END;

      (* Sum values of the blocks after this block (ie after block 'J') *)
      FOR M := (J + 1) TO MaxNoElements DO
      BEGIN
        Value := XElements[Iin, M];
        IF (Value > 0) THEN Right := Right + 1 + Value;
      END;

      Right := YAcross - Right;
      GapSize := Right - Left;

      S := GapSize - A;
      IF (S < 0) THEN AOk := 1;
      StartPos := Left + S + 1;
      StopPos := Right - S;

      (* Draw the points on the screen *)
      IF ((StartPos <= StopPos) AND (AOk = 0)) THEN
      BEGIN
        FOR N := StartPos TO StopPos DO
          DrawPoint(0, Iin, N, 1, FALSE);
      END;
    END
    ELSE
    BEGIN
      (* Work in the YAcross direction *)

      (* Get the size of the block in row 'Iin' at position 'J' (ie before block 'J') *)
      A := YElements[Iin, J];
      AOk := 0; Left := 0; Right := 0;

      (* Sum values of the blocks prior to this block *)
      FOR L := 1 TO (J - 1) DO
      BEGIN
        Value := YElements[Iin, L];
        IF (Value > 0) THEN Left := Left + 1 + Value;
      END;

      (* Sum values of the blocks after this block (ie after block 'J') *)
      FOR M := (J + 1) TO MaxNoElements DO
      BEGIN
        Value := YElements[Iin, M];
        IF (Value > 0) THEN Right := Right + 1 + Value;
      END;

      Right := XAcross - Right;
      GapSize := Right - Left;

      S := GapSize - A;
      IF (S < 0) THEN AOk := 1;
      StartPos := Left + S + 1;
      StopPos := Right - S;

      (* Draw the points on the screen *)
      IF ((StartPos <= StopPos) AND (AOk <> 1)) THEN
      BEGIN
        FOR N := StartPos TO StopPos DO
          DrawPoint(0, N, Iin, 1, FALSE);
      END;
    END;
  END;
END;


PROCEDURE TDisplay.ResetData;
VAR
  I, J: INTEGER;
BEGIN
  (* Reset X storage array *)
  FOR I := 1 TO MaxXAcross DO
    FOR J := 1 TO MaxNoElements DO
      XElements[I, J] :=0;

  (* Reset Y storage array *)
  FOR I := 1 TO MaxYAcross DO
    FOR J := 1 TO MaxNoElements DO
      YElements[I, J] := 0;

  (* Reset screen grid array *)
  FOR I := 1 TO MaxXAcross DO
    FOR J := 1 TO MaxYAcross DO
      ScreenGrid[I, J] := 0;
                                         
  (* Reset filled row arrays *)
  SolveTime := 0;
  FOR I := 1 TO 25 DO
    YFilled[I] := 0;
  FOR I := 1 TO 20 DO
    XFilled[I] := 0;

  (* Reset variables *)
  StrCopy(FileName, 'None');
  StrCopy(FilTitle, '');

  (* Set window text appropriately and display screen *)
  InvalidateRect(HWindow, NIL, TRUE);
END;


PROCEDURE TDisplay.ParseData;
VAR
  I, K: INTEGER;
BEGIN
  (* Parse the data set for errors *)
  Sum1 := 0;
  Sum2 := 0;

  (* Calculate sum of data sets *)
  FOR I := 1 TO XAcross DO
    FOR K := 1 TO MaxNoElements DO
      Sum1 := Sum1 + XElements[I, K];

  FOR I := 1 TO YAcross DO
    FOR K := 1 TO MaxNoElements DO
      Sum2 := Sum2 + YElements[I, K];
END;


(**********************************************************************)
(* Methods of TMainWindow from here onwards *)


CONSTRUCTOR TMainWindow.Init (AParent: PWindowsObject; ATitle: PChar);
VAR
  I: INTEGER;
BEGIN
  (* Call ancestor method *)
  TWindow.Init (AParent, ATitle);

  (* Get menu handle *)
  Attr.Menu := LoadMenu(HInstance, 'MENUBAR');

  (* Initialise program *)
  Attr.W := GetPrivateProfileInt('Main Window', 'Width', 600, 'NONOGRAM.INI');
  Attr.H := GetPrivateProfileInt('Main Window', 'Height', 450, 'NONOGRAM.INI');
  Attr.X := GetPrivateProfileInt('Main Window', 'X position', 0, 'NONOGRAM.INI'); 
  Attr.Y := GetPrivateProfileInt('Main Window', 'Y position', 0, 'NONOGRAM.INI');
  Attr.Style := Attr.Style;

  (* Reset pointers *)
  ToolbarHan := NIL;
  DisplayHan := NIL;
  StatbarHan := NIL;

  (* Initialise variables *)
  ToolbarExist := FALSE;
  StatbarExist := FALSE;
  DisplayExist := FALSE;
  SolveInProgress := FALSE;
  StopSolAndExit := FALSE;

  (* Create brushes *)
  WITH TBackBrush DO
  BEGIN
    lbStyle := BS_SOLID;
    lbColor := $00FF0000;
    lbHatch := 0;
  END;
  WITH TDotBrush DO
  BEGIN
    lbStyle := BS_SOLID;
    lbColor := $00808080;
    lbHatch := 0;
  END;
  WITH TBlockBrush DO
  BEGIN
    lbStyle := BS_SOLID;
    lbColor := $00FFFFFF;
    lbHatch := 0;
  END;

  BackBrush := CreateBrushIndirect(TBackBrush);
  BlockBrush := CreateBrushIndirect(TBlockBrush);
  DotBrush := CreateBrushIndirect(TDotBrush); 

  (* Create a font record for the vertical axes font... *)
  WITH AxesVFont DO
  BEGIN
    LFHeight := 15;
    LFWidth := 0;
    LFEscapement := 0;
    LFOrientation := 0;
    LFWeight := FW_BOLD;
    LFItalic := 0;
    LFUnderline := 0;
    LFStrikeOut := 0;
    LFCharSet := ANSI_CHARSET;
    LFOutPrecision := OUT_STROKE_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := PROOF_QUALITY;
    lfPitchAndFamily := FF_DONTCARE;
    StrCopy (@LFFaceName, 'Arial');
  END;
  HAxesVFont := CreateFontIndirect(AxesVFont);

  (* ...and one for the horizontal axes font *)
  WITH AxesHFont DO
  BEGIN
    LFHeight := 15;
    LFWidth := 0;
    LFEscapement := 900;
    LFOrientation := 900;
    LFWeight := FW_BOLD;
    LFItalic := 0;
    LFUnderline := 0;
    LFStrikeOut := 0;
    LFCharSet := ANSI_CHARSET;
    LFOutPrecision := OUT_STROKE_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := PROOF_QUALITY;
    lfPitchAndFamily := FF_DONTCARE;
    StrCopy (@LFFaceName, 'Arial');
  END;
  HAxesHFont := CreateFontIndirect(AxesHFont);

  (* Initialise new combination algorithm data structure *)
  New(PotentData);
END;


DESTRUCTOR TMainWindow.Done;
VAR
  I: INTEGER; 
BEGIN
  (* Tidy up and dispose of everything *)
  WinHelp (HWindow, 'NONOGRAM.HLP', Help_Quit, 0);
  DeleteObject(BlockBrush);
  DeleteObject(DotBrush);
  DeleteObject(BackBrush);
  DeleteObject(HAxesVFont);
  DeleteObject(HAxesHFont);

  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TMainWindow.GetWindowClass (VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.HIcon := LoadIcon (HInstance, 'ICON_1');
END;


PROCEDURE TMainWindow.SetupWindow;
VAR
  A, YPos, Height, Width: INTEGER;
  Msg: TMessage;
  WinRect: TRECT;
BEGIN
  (* Call ancestor method *)
  TWindow.SetupWindow;

  SaveOnExit := BOOLEAN(GetPrivateProfileInt('Main Window', 'Save on exit', 0, 'NONOGRAM.INI'));
  SolveConfirmation := BOOLEAN(GetPrivateProfileInt('Main Window', 'Solve Confirmation',
                                                    1, 'NONOGRAM.INI'));
  LoadConfirmation := BOOLEAN(GetPrivateProfileInt('Main Window', 'Load Confirmation',
                                                    1, 'NONOGRAM.INI'));

  (* Solution options *)
  QuickStrtOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Quick start on',
                                              1, 'NONOGRAM.INI'));
  EdgeCheckOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Edge checking on',
                                              1, 'NONOGRAM.INI'));
  FullRwTstOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Full row testing on',
                                              1, 'NONOGRAM.INI'));
  RowFollowOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Row following on',
                                              1, 'NONOGRAM.INI'));
  CombinatnOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Combination on',
                                              1, 'NONOGRAM.INI'));
  VARSSize := GetPrivateProfileInt('Solution Options', 'VARS size', 20, 'NONOGRAM.INI');

  (* Display options *)
  DisplayRotate := DisplayRotation(GetPrivateProfileInt('Display Options', 'Display rotation',
                                                        0, 'NONOGRAM.INI'));
  DisplayFlip := BOOLEAN(GetPrivateProfileInt('Display Options', 'Display flip',
                                              0, 'NONOGRAM.INI'));

  (* Get client window size *)
  GetClientRect(HWindow, WinRect);

  (* Now create new windows - first of all the tool bar *)
  IF (BOOLEAN(GetPrivateProfileInt('Main Window', 'Tool bar exist', 1, 'NONOGRAM.INI'))) THEN
  BEGIN
    ToolbarHan := New(PToolbar, Init(@self, 0, 0, (WinRect.Right - WinRect.Left), 30));
    Application^.MakeWindow(ToolbarHan);
    ToolbarExist := TRUE;
  END
  ELSE
    ToolbarExist := FALSE;

  (* Create status bar *)
  IF (BOOLEAN(GetPrivateProfileInt('Main Window', 'Status bar exist', 1, 'NONOGRAM.INI'))) THEN
  BEGIN
    StatbarHan := New(PStatbar, Init(@self, 0, (WinRect.Bottom - 22),
                      (WinRect.Right - WinRect.Left), 22));
    Application^.MakeWindow(StatbarHan);
    StatbarExist := TRUE;
  END
  ELSE
    StatbarExist := FALSE;

  (* Create main display window *)
  IF (ToolbarExist) THEN
    YPos := 30
  ELSE
    YPos := 0;

  Height := (WinRect.Bottom - WinRect.Top);
  IF (ToolbarExist) THEN Height := Height - 30;
  IF (StatbarExist) THEN Height := Height - 22;

  Width := (WinRect.Right - WinRect.Left);

  DisplayHan := New(PDisplay, Init(@self, 0, YPos, Width, Height));
  Application^.MakeWindow(DisplayHan);
  DisplayExist := TRUE;

  (* Set up printer options *)
  WITH PrintStruct DO
  BEGIN
    lStructSize := sizeof(TPRINTDLG);
    hwndOwner   := HWindow;
    hDevMode    := 0;
    hDevNames   := 0;
    Flags       := PD_RETURNDC OR PD_NOSELECTION OR PD_NOPAGENUMS;
    nCopies     := 1;
  END;

  (* Initialise variables *)
  FileNew(Msg);
END;


PROCEDURE TMainWindow.WMSize(VAR Msg: TMessage);
BEGIN
  (* Call ancestor method *)
  TWindow.WMSize(Msg);

  (* Redraw children *)
  RedoChildren;
END;


PROCEDURE TMainWindow.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);
END;


PROCEDURE TMainWindow.RedoChildren;
VAR
  XPos, YPos, Width, Height: INTEGER;
  WinRect: TRECT;
BEGIN
  (* Get client window size *)
  GetClientRect(HWindow, WinRect);

  (* Reset the position of the tool bar window *)
  IF (ToolbarExist) THEN
    MoveWindow(ToolbarHan^.HWindow, 0, 0, (WinRect.Right - WinRect.Left), 30, TRUE);

  IF (StatbarExist) THEN
    MoveWindow(StatbarHan^.HWindow, 0, (WinRect.Bottom - 22),
               (WinRect.Right - WinRect.Left), 22, TRUE);

  IF (DisplayExist) THEN
  BEGIN
    IF (ToolbarExist) THEN
      YPos := 30
    ELSE
      YPos := 0;

    Height := (WinRect.Bottom - WinRect.Top);
    IF (ToolbarExist) THEN Height := Height - 30;
    IF (StatbarExist) THEN Height := Height - 22;

    Width := (WinRect.Right - WinRect.Left);

    MoveWindow(DisplayHan^.HWindow, 0, YPos, Width, Height, TRUE);
  END;
END;


PROCEDURE TMainWindow.FileNew(VAR Msg: TMessage);
VAR
  I, J: INTEGER;
BEGIN
  (* Clear child window data *)
  PDisplay(DisplayHan)^.ResetData;

  (* Set window text appropraitely and display screen *)
  SetWindowText(HWindow, 'Nonogram Solver - [none]');

  (* Manipulate menu's appropriately *)
  EnableMenuItem(Attr.Menu, CM_SOLVE, MF_GRAYED);
  EnableMenuItem(Attr.Menu, CM_PARSE, MF_GRAYED);
  EnableMenuItem(Attr.Menu, CM_STOPSO, MF_GRAYED);

  IF (ToolbarExist) THEN
  BEGIN
    (* Disable toolbar buttons *)
    ToolbarHan^.EnableButton(5, FALSE);
    ToolbarHan^.EnableButton(6, FALSE);
  END;
END;


PROCEDURE TMainWindow.FileLoad(VAR Msg: TMessage);
BEGIN
  (* If it is a valid file name then actually load the data *)
  IF (Application^.ExecDialog(New(PFileDialog,
      Init(@self, PChar(sd_FileOpen),
      StrCopy(FileName,'*.NGM')))) = ID_OK) THEN
    FileLoadImplement;
END;


PROCEDURE TMainWindow.FilePrint(VAR Msg: TMessage);
VAR
  hPr: HDC;
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  TextStrPtr: PChar;

  FontRecord: TLOGFONT;
  HFontRecord: HFONT;
  XRes, YRes, TextSp, BlkPoint, Temp: INTEGER;
  LeftMargin, TopMargin, I, J, X, Y: INTEGER;
  Year, Month, Day, DOW, Hour, Min, Sec, Hund: WORD;
BEGIN
  (* Handle Nonogram printing *)
  hPr := GetPrinterDC;

  (* OK - we didn't get a valid DC so we'd better just give up *)
  IF (hPr = 0) THEN
  BEGIN
    MessageBox(HWindow, 'Cannot print!', 'Nonogram solver', MB_ICONEXCLAMATION);
    EXIT;
  END;

  (* Start print job off *)
  StrCopy(TextString, 'Nonogram - ');
  StrCat(TextString, PDisplay(DisplayHan)^.FileName);
  TextStrPtr := @TextString;
  Escape(hPr, STARTDOC, (StrLen(TextString)+1), TextStrPtr, nil);

  (* Get display resolution *)
  XRes := GetDeviceCaps(hPr, HORZRES);
  YRes := GetDeviceCaps(hPr, VERTRES);
  TextSp := YRes DIV 64;

  SetMapMode(hPr, MM_TEXT);

  (* If status bar exists then update it *)
  IF (StatbarExist) THEN
    StatbarHan^.SetText(0, 'Printing...');

  (* Create a general font record *)
  WITH FontRecord DO
  BEGIN
    lfHeight := XRes DIV 24;
    lfWidth := 0;
    lfEscapement := 0;
    lfOrientation := 0;
    lfWeight := FW_BOLD;
    lfItalic := 0;
    lfUnderline := 1;
    lfStrikeOut := 0;
    lfCharSet := ANSI_CHARSET;
    lfOutPrecision := OUT_STROKE_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfQuality := PROOF_QUALITY;
    lfPitchAndFamily := FF_SWISS;
    StrCopy (@LFFaceName, 'Arial');
  END;
  HFontRecord := CreateFontIndirect(FontRecord);

  (* Now select this font *)
  SelectObject(hPr, HFontRecord);

  StrCopy(TextString, 'The Nonogram Solver - Version 2.0');
  TextOut(hPr, 10, (TextSp), TextString, StrLen(TextString));

  (* Modify the font *)
  SelectObject(hPr, HAxesVFont);
  DeleteObject(HFontRecord);
  FontRecord.lfHeight := XRes DIV 48;
  FontRecord.lfUnderline := 0;
  FontRecord.lfWeight := FW_NORMAL;
  HFontRecord := CreateFontIndirect(FontRecord);
  SelectObject(hPr, HFontRecord);

  (* Output the Nonogram data *)
  StrCopy(TextString, 'File name: ');
  StrCat(TextString, PDisplay(DisplayHan)^.FileName);
  TextOut(hPr, 30, 4*TextSp, TextString, StrLen(TextString));
  StrCopy(TextString, 'File title: ');
  StrCat(TextString, PDisplay(DisplayHan)^.FilTitle);
  TextOut(hPr, 30, 5*TextSp, TextString, StrLen(TextString));
  StrCopy(TextString, 'Solution time: ');
  IF (PDisplay(DisplayHan)^.SolveTime = 0) THEN
  BEGIN
    StrCat(TextString, 'Not solved ');
  END
  ELSE
  BEGIN
    Str(PDisplay(DisplayHan)^.SolveTime, TextStrtwo);
    StrCat(TextString, TextStrtwo);
    StrCat(TextString, ' seconds');
  END;
  TextOut(hPr, 30, 6*TextSp, TextString, StrLen(TextString));

  (* Add date and time to print out *)
  GetDate(Year, Month, Day, DOW);
  GetTime(Hour, Min, Sec, Hund);
  StrCopy(TextString, 'Printed at: ');
  IF (Hour < 10) THEN
    StrCat(TextString, '0');
  Str(Hour, TextStrtwo);
  StrCat(TextString, TextStrtwo);
  StrCat(TextString, ':');
  IF (Min < 10) THEN
    StrCat(TextString, '0');
  Str(Min, TextStrtwo);
  StrCat(TextString, TextStrtwo);
  StrCat(TextString, ':');
  IF (Sec < 10) THEN
    StrCat(TextString, '0');
  Str(Sec, TextStrtwo);
  StrCat(TextString, TextStrtwo);

  StrCat(TextString, ' on ');
  CASE DOW OF
    0: StrCat(TextString, 'Sunday');
    1: StrCat(TextString, 'Monday');
    2: StrCat(TextString, 'Tuesday');
    3: StrCat(TextString, 'Wednesday');
    4: StrCat(TextString, 'Thursday');
    5: StrCat(TextString, 'Friday');
    6: StrCat(TextString, 'Saturday');
  END;

  StrCat(TextString, ', ');
  IF (Day < 10) THEN
    StrCat(TextString, '0');
  Str(Day, TextStrtwo);
  StrCat(TextString, TextStrtwo);
  StrCat(TextString, '/');
  IF (Month < 10) THEN
    StrCat(TextString, '0');
  Str(Month, TextStrtwo); 
  StrCat(TextString, TextStrtwo);
  StrCat(TextString, '/');
  Str(Year, TextStrtwo);
  StrCat(TextString, TextStrtwo);
  TextOut(hPr, 30, 7*TextSp, TextString, StrLen(TextString));

  (* Now draw the actual datafile *)
  BlkPoint := ((9*XRes) DIV 10) DIV PDisplay(DisplayHan)^.XAcross;
  Temp := ((8*YRes) DIV 10) DIV PDisplay(DisplayHan)^.YAcross;
  IF (Temp < BlkPoint) THEN BlkPoint := Temp;
  LeftMargin := (XRes - BlkPoint*PDisplay(DisplayHan)^.XAcross) DIV 2;
  TopMargin := (3*(YRes - BlkPoint*PDisplay(DisplayHan)^.YAcross)) DIV 4;

  FOR I := 1 TO PDisplay(DisplayHan)^.YAcross DO
  BEGIN
    FOR J := 1 TO PDisplay(DisplayHan)^.XAcross DO
    BEGIN
      IF (PDisplay(DisplayHan)^.ScreenGrid[J, I] = 1) THEN
      BEGIN
        (* Select filled brush and draw point *)
        SelectObject(hPr, BackBrush);
        X := LeftMargin+(J-1)*BlkPoint;
        Y := TopMargin+(I-1)*BlkPoint;
        Rectangle(hPr, X , Y, (X+BlkPoint), (Y+BlkPoint));
      END
      ELSE
      BEGIN
        SelectObject(hPr, BlockBrush);
        X := LeftMargin+(J-1)*BlkPoint;
        Y := TopMargin+(I-1)*BlkPoint;
        Rectangle(hPr, X , Y, (X+BlkPoint), (Y+BlkPoint));
      END;
    END;
  END;

  (* End of printer escapes *)
  Escape (hPr, NEWFRAME, 0, nil, nil);
  Escape (hPr, ENDDOC, 0, nil, nil);

  (* If status bar exists then update it *)
  IF (StatbarExist) THEN
    StatbarHan^.SetText(0, 'Printing complete');

  (* Delete the DC *)
  DeleteDC (hPr);
END;


FUNCTION TMainWindow.GetPrinterDC: HDC;
VAR
  lpDevMode: ^TDEVMODE;
  lpDevNames: ^TDEVNAMES;
  lpszDriverName: PChar;
  lpszDeviceName: PChar;
  lpszPortName: PChar;
  Locked: BOOLEAN;
BEGIN

  IF NOT(PrintDlg(PrintStruct)) THEN
  BEGIN
    GetPrinterDC := 0;
    EXIT;
  END;

  IF (PrintStruct.hDC <> 0) THEN
  BEGIN
    (* Use the already created DC *)
    GetPrinterDC := PrintStruct.hDC;
    EXIT;
  END
  ELSE
  BEGIN
    (* Check to see that *)
    IF (PrintStruct.hDC <> 0) THEN
    BEGIN
      GetPrinterDC := 0;
      EXIT;
    END
    ELSE
    BEGIN
      (* Apply global lock and get driver/device/port names *)
      lpDevNames := GlobalLock(PrintStruct.hDevNames);
      lpszDriverName := PChar(lpDevNames) + lpDevNames^.wDriverOffset;
      lpszDeviceName := PChar(lpDevNames) + lpDevNames^.wDeviceOffset;
      lpszPortName := PChar(lpDevNames) + lpDevNames^.wOutputOffset;
      GlobalUnlock(PrintStruct.hDevNames);

      IF (PrintStruct.hDevMode <> 0) THEN
      BEGIN
        lpDevMode := GlobalLock(PrintStruct.hDevNames);
        Locked := TRUE;
      END
      ELSE
        Locked := FALSE;

      (* Now with DevMode locked try to create a DC *)
      GetPrinterDC := CreateDC(lpszDriverName, lpszDeviceName, lpszPortName, PChar(lpDevMode));

      IF (Locked) THEN
        GlobalUnlock(PrintStruct.hDevNames);
    END;
  END;
END;


PROCEDURE TMainWindow.FileSetup(VAR Msg: TMessage);
VAR
  FlagSave: WORD;
BEGIN
  FlagSave := PrintStruct.Flags;
  PrintStruct.Flags := PrintStruct.Flags OR PD_PRINTSETUP;
  (* Setup the printer etc *)
  PrintDlg(PrintStruct);
  PrintStruct.Flags := FlagSave;
END;


PROCEDURE TMainWindow.FileEdit(VAR Msg: TMessage);
VAR
  TextString: ARRAY [0..100] OF CHAR;
BEGIN
  (* Open up a instance of NOTEPAD.EXE with the current datafile *)
  StrCopy(TextString, 'NOTEPAD.EXE ');
  StrCat(TextString, PDisplay(DisplayHan)^.FileName);
  WinExec(TextString, SW_SHOW);
END;


PROCEDURE TMainWindow.FileExit(VAR Msg: TMessage);
BEGIN
  (* We are finsihed so close the window *)
  TMainWindow.CloseWindow;
END;


PROCEDURE TMainWindow.ConfigureSolution(VAR Msg: TMessage);
BEGIN
  (* Bring up the solution options dialog box *)
  Application^.ExecDialog(New(PConfigWin, Init(@self, 'SolveBox')));
END;


PROCEDURE TMainWindow.ConfigureDisplay(VAR Msg: TMessage);
BEGIN
  (* Bring up the display dialog box *)
  Application^.ExecDialog(New(PDisplayOptions, Init(@self, 'DisplayBox')));
  PostMessage(PDisplay(DisplayHan)^.HWindow, WM_SIZE, 0, 0);
  InvalidateRect(HWindow, NIL, TRUE);
END;


PROCEDURE TMainWindow.Preferences(VAR Msg: TMessage);
BEGIN
  (* Bring up the preferences dialog box *)
  Application^.ExecDialog(New(PPreferences, Init(@self, 'Preferences')));
END;


PROCEDURE TMainWindow.Solve(VAR Msg: TMessage);
VAR
  I, J, OldTotal: INTEGER;
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  TextStrthr, TextStrfou: ARRAY [0..10] OF CHAR;
  Strt, Fin: LONGINT;
  MainMenu: HMenu;
  TheDC: HDC;
BEGIN
  (* Check that the data is OK - ie no errors *)
  PDisplay(DisplayHan)^.ParseData;
  IF ((PDisplay(DisplayHan)^.Sum1 <> PDisplay(DisplayHan)^.Sum2) OR
      (PDisplay(DisplayHan)^.Sum1 = 0) OR
      (PDisplay(DisplayHan)^.Sum2 = 0)) THEN EXIT;

  (* Solving has now started *)
  SolveInProgress := TRUE;

  (* Clear the current screen data *)
  FOR I := 1 TO MaxXAcross DO
  BEGIN
    FOR J := 1 TO MaxYAcross DO
      PDisplay(DisplayHan)^.ScreenGrid[I, J] := 0;
  END;

  (* Clear the current puzzle data *)
  FOR I := 1 TO PDisplay(DisplayHan)^.XAcross DO
    PDisplay(DisplayHan)^.XFilled[I] := 0;

  FOR I := 1 TO PDisplay(DisplayHan)^.YAcross DO
    PDisplay(DisplayHan)^.YFilled[I] := 0;

  (* Redraw the screen *)
  FOR I := 1 TO PDisplay(DisplayHan)^.XAcross DO
    FOR J := 1 TO PDisplay(DisplayHan)^.YAcross DO
      PDisplay(DisplayHan)^.DrawPoint(0, I, J, 0, TRUE); 

  PDisplay(DisplayHan)^.SolveTime := 0;
  Strt := GetTickCount;
  OldTotal := -1;
  PDisplay(DisplayHan)^.PlotTotal := 0;

  (* Set the menu appropriately *)
  StrCopy(TextString, '&Stop solving');
  MainMenu := GetMenu(HWindow);
  ModifyMenu(MainMenu, CM_SOLVE, MF_BYCOMMAND, CM_STOPSO, TextString);
  DrawMenuBar(HWindow);

  (* Set status bar up *)
  IF (StatbarExist) THEN
  BEGIN
    StatbarHan^.SetTime(0, '0.000', '0');
    StatbarHan^.SetText(0, 'Solving...');
  END;

  (* Disable the solve toolbar icon *)
  ToolbarHan^.ShowButton(5, SW_HIDE);
  ToolbarHan^.ShowButton(12, SW_SHOW);

  (* Set the window title appropriately *)
  GetWindowText(HWindow, TextString, 70);
  StrCopy(TextStrtwo, TextString);
  StrCat(TextStrtwo, ' - [solving]');
  SetWindowText(HWindow, TextStrtwo);

  (* Check to see if we should use the 'QuickData' routine *)
  IF (QuickStrtOn) THEN PDisplay(DisplayHan)^.QuickData;

  (* This is the actual crunching solve routine *)
  CanThink := TRUE;
  WHILE ((OldTotal <> PDisplay(DisplayHan)^.PlotTotal) AND CanThink) DO
  BEGIN
    OldTotal := PDisplay(DisplayHan)^.PlotTotal;
    IF (EdgeCheckOn) THEN PDisplay(DisplayHan)^.CheckEdge;
    IF (FullRwTstOn) THEN PDisplay(DisplayHan)^.TestRowFull;
    IF (RowFollowOn) THEN PDisplay(DisplayHan)^.FollowRow;
    IF (CombinatnOn) THEN PDisplay(DisplayHan)^.Combination;

    (* Update time/number of points display on status bar *)
    IF (StatbarExist) THEN
    BEGIN
      Str(PDisplay(DisplayHan)^.PlotTotal, TextStrthr);
      Fin := GetTickCount;
      Str(((Fin-Strt)/ 1000):5:3, TextStrfou);
      StatbarHan^.SetTime(0, TextStrfou, TextStrthr);
    END;
                 
    (* Check to see if there are any messages waiting in the
       applications message queue *)
    IF (PeekMessage(SentMessage, 0, 0, 0, PM_REMOVE)) THEN
    BEGIN
      IF ((SentMessage.Message = WM_COMMAND) AND (SentMessage.wParam = CM_STOPSO)) THEN
      BEGIN
        SolveInProgress := FALSE;
        CanThink := FALSE;
      END;
      TranslateMessage(SentMessage);
      DispatchMessage(SentMessage);
    END;
  END;

  Fin := GetTickCount;
  PDisplay(DisplayHan)^.SolveTime := Fin - Strt;

  (* Solving is now finished *)
  SolveInProgress := FALSE;

  (* Reset window title *)
  SetWindowText(HWindow, TextString);

  (* Reset the menu to its previous state *)
  StrCopy(TextString, '&Solve');
  MainMenu := GetMenu(HWindow);
  ModifyMenu(MainMenu, CM_STOPSO, MF_BYCOMMAND, CM_SOLVE, TextString);
  DrawMenuBar(HWindow);

  (* Refresh status bar *)
  IF (StatbarExist) THEN
  BEGIN
    IF (CanThink) THEN
    BEGIN
      IF (PDisplay(DisplayHan)^.PlotTotal =
          (PDisplay(DisplayHan)^.XAcross * PDisplay(DisplayHan)^.YAcross)) THEN
      BEGIN
        StatbarHan^.SetText(0, 'Successfully solved');
      END
      ELSE
      BEGIN
        StatbarHan^.SetText(0, 'Cannot obtain a solution!');
      END;
    END
    ELSE
    BEGIN
      StatbarHan^.SetText(0, 'Solution interrupted');
    END;
  END;

  (* Re-enable the solve toolbar button *)
  ToolbarHan^.ShowButton(12, SW_HIDE);
  ToolbarHan^.ShowButton(5, SW_SHOW);

  (* Display a finished message - but only if needed/wanted *)
  IF (SolveConfirmation) THEN
  BEGIN
    IF (PDisplay(DisplayHan)^.PlotTotal =
       (PDisplay(DisplayHan)^.XAcross * PDisplay(DisplayHan)^.YAcross)) THEN
    BEGIN
      MessageBox(HWindow, 'Successfully finished', 'Solve:', MB_ICONINFORMATION);
    END
    ELSE
    BEGIN
      IF (CanThink) THEN
      BEGIN
        MessageBox(HWindow, 'Finished', 'Solve:', MB_ICONINFORMATION);
      END
      ELSE
      BEGIN
        MessageBox(HWindow, 'Interrupted', 'Solve:', MB_ICONEXCLAMATION);
      END;
    END;
  END;

  IF (StopSolAndExit) THEN
    PostMessage(HWindow, WM_COMMAND, CM_EXIT, 0);
END;


PROCEDURE TMainWindow.Parse(VAR Msg: TMessage);
VAR
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  Sum1, Sum2: INTEGER;
BEGIN
  (* Call the parsing data routine proper *)
  PDisplay(DisplayHan)^.ParseData;
  Sum1 := PDisplay(DisplayHan)^.Sum1;
  Sum2 := PDisplay(DisplayHan)^.Sum2;

  (* If they differ take action *)
  IF (Sum1 <> Sum2) THEN
  BEGIN
    StrCopy(TextString, 'Data supplied is suspect');
    StrCat(TextString, CHR(13));
    StrCat(TextString, CHR(13));
    Str(Sum1, TextStrtwo);
    StrCat(TextString, TextStrtwo);
    StrCat(TextString, ' (XElements)');
    StrCat(TextString, CHR(13));
    Str(Sum2, TextStrtwo);
    StrCat(TextString, TextStrtwo);
    StrCat(TextSTring, ' (YElements)');
    MessageBox (HWindow, TextString, 'Warning:', MB_ICONSTOP);
  END
  ELSE
  BEGIN
    (* Check to see that some data is loaded *)
    IF ((Sum1 = 0) OR (Sum2 = 0)) THEN 
    BEGIN
      StrCopy(TextString, 'Parse Error:');
      MessageBox (HWindow, 'No data loaded', TextString, MB_ICONEXCLAMATION);
    END
    ELSE
    BEGIN
      StrCopy(TextString, 'Parse data test passed');
      StrCat(TextString, CHR(13));
      StrCat(TextString, CHR(13));
      Str(Sum1, TextStrtwo);
      StrCat(TextString, TextStrtwo);
      StrCat(TextString, ' (XElements)');
      StrCat(TextString, CHR(13));
      Str(Sum2, TextStrtwo);
      StrCat(TextString, TextStrtwo);
      StrCat(TextSTring, ' (YElements)');
      MessageBox (HWindow, TextString, 'Parse Data:', MB_ICONINFORMATION);
    END;
  END;
END;


PROCEDURE TMainWindow.HelpContents(VAR Msg: TMessage);
BEGIN
  (* Bring up the main Windows help file - Contents page *)
  WinHelp(HWindow, 'NONOGRAM.HLP' , HELP_INDEX, 0);
END;


PROCEDURE TMainWindow.Intro(VAR Msg: TMessage);
BEGIN
  WinHelp (HWindow, 'NONOGRAM.HLP', HELP_CONTEXT, HC_INTRO);
END;


PROCEDURE TMainWindow.HelpOnHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up the standard Windows help on help datafile *)
  WinHelp (HWindow, 'NONOGRAM.HLP', HELP_HELPONHELP, 0);
END;


PROCEDURE TMainWindow.HelpAbout(VAR Msg: TMessage);
BEGIN
  (* Bring up the 'About' dialog box *)
  Application^.ExecDialog(New(PAboutBox, Init(@self, 'AboutBox')));
END;


PROCEDURE TMainWindow.FileLoadImplement;
VAR
  File1: TEXT;
  A, I, J, Code, LineNo, LinePos: INTEGER;
  DoingX, Finished: BOOLEAN;
  TextString, TextStrtwo, TextBuf: ARRAY [0..80] OF CHAR;
  Msg: TMessage;
BEGIN
  (* This procedure reads in the standard format data file - the order is

     1) Read datafile title
     2) Read datafile size (20x25 etc)
     3) Read datafile data *)

  (* Reset everything *)
  FileNew(Msg);

  (* Set up intial values *)
  J := 0;
  DoingX := TRUE;
  Finished := FALSE;
  LineNo := 1;
  LinePos := 1;

  (* Actually load the file *)
  Assign(File1, Filename);
  Reset(File1);

  (* Read the data title *)
  IF NOT(EOF(File1)) THEN
    ReadLn(File1, PDisplay(DisplayHan)^.FilTitle);

  (* Read in Nonogram size: XAcross by YAcross *)
  ReadLn(File1, PDisplay(DisplayHan)^.XAcross, PDisplay(DisplayHan)^.YAcross);

  WHILE NOT(EOF(File1) AND Finished) DO
  BEGIN
    (* Read a whole line in *)
    ReadLn(File1, TextString);

    A := StrLen(TextString);
    TextString[A] := ' ';
    TextString[A+1] := #0;

    (* Parse line of data *)
    FOR I := 0 TO A DO
    BEGIN
      IF ((TextString[I] <> #32) AND (TextString[I] <> #44)) THEN
      BEGIN
        TextBuf[J] := TextString[I];                    
        TextBuf[J+1] := #0;
        INC(J);
      END
      ELSE
      BEGIN
        TextBuf[J] := #0;
        J := 0;
        IF (DoingX) THEN
        BEGIN
          Val(TextBuf, PDisplay(DisplayHan)^.XElements[LineNo, LinePos], Code);
        END
        ELSE
        BEGIN
          Val(TextBuf, PDisplay(DisplayHan)^.YElements[LineNo, LinePos], Code);
        END;

        (* Increment LinePos *)
        INC(LinePos);
      END;
    END;

    INC(LineNo);
    LinePos := 1;

    IF (DoingX) THEN
    BEGIN
      IF (LineNo > PDisplay(DisplayHan)^.XAcross) THEN
      BEGIN
        (* Now "doingY" *)
        DoingX := FALSE;
        LineNo := 1;
      END;
    END
    ELSE
    BEGIN
      IF (LineNo > PDisplay(DisplayHan)^.YAcross) THEN
        Finished := TRUE;
    END;
  END;

  (* Enable menu options *)
  EnableMenuItem(Attr.Menu, CM_SOLVE, MF_ENABLED);
  EnableMenuItem(Attr.Menu, CM_PARSE, MF_ENABLED);
  EnableMenuItem(Attr.Menu, CM_STOPSO, MF_ENABLED);

  (* Enable toolbar items *)
  IF (ToolbarExist) THEN
  BEGIN
    ToolbarHan^.EnableButton(5, TRUE);
    ToolbarHan^.EnableButton(6, TRUE);
  END;

  (* Update status bar *)
  IF (StatbarExist) THEN
    PStatbar(StatbarHan)^.SetText(0, PDisplay(DisplayHan)^.FilTitle);

  (* Copy the filename to the main display window field *)
  StrCopy(PDisplay(DisplayHan)^.FileName, FileName);

  (* Update main screen *)
  Close(File1);
  StrCopy(TextString, 'Nonogram Solver - [');
  StrCat(TextString, FileName);
  StrCat(TextString, ']');
  SetWindowText(HWindow, TextString);
  IF (LoadConfirmation) THEN
    MessageBox (HWindow, PDisplay(DisplayHan)^.FilTitle, 'Selection:', MB_ICONINFORMATION);

  (* Check that the new Nonogram still fits on the screen (ie are Scrollbars required) *)
  PostMessage(PDisplay(DisplayHan)^.HWindow, WM_SIZE, 0, 0);
END;

               
FUNCTION TMainWindow.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'Nonogram Window';
END;


FUNCTION TMainWindow.CanClose: BOOLEAN;
VAR
  TextString: ARRAY [0..80] OF CHAR;
BEGIN
  (* Check to see if we should exit *)
  CanClose := TWindow.CanClose;

  IF (SolveInProgress) THEN
  BEGIN
    Strcopy(TextString, 'Solve in progress!');
    Strcat(TextString, CHR(13));
    Strcat(TextString, CHR(13));
    Strcat(TextString, 'Please confirm exit');
    IF (MessageBox(HWindow, TextString, 'Nonogram Solver:',
                   MB_OKCANCEL OR MB_ICONEXCLAMATION) = ID_OK) THEN
    BEGIN
      PostMessage(HWindow, WM_COMMAND, CM_STOPSO, 0);
      StopSolAndExit := TRUE;
    END;
    CanClose := FALSE;
    EXIT;
  END; 

  (* Save data into initialisation file *)
  IF (SaveOnExit) THEN
  BEGIN
    (* Main window attributes *)
    Str(Attr.W, TextString);
    WritePrivateProfileString('Main Window', 'Width', TextString,
                              'NONOGRAM.INI');
    Str(Attr.H, TextString);
    WritePrivateProfileString('Main Window', 'Height', TextString,
                              'NONOGRAM.INI');
    Str(Attr.X, TextString);
    WritePrivateProfileString('Main Window', 'X position', TextString,
                              'NONOGRAM.INI');
    Str(Attr.Y, TextString);
    WritePrivateProfileString('Main Window', 'Y position', TextString,
                              'NONOGRAM.INI');

    (* Solve confirmation *)
    IF (SolveConfirmation) THEN
      StrCopy(TextString, '1')
    ELSE
      StrCopy(TextString, '0');
    WritePrivateProfileString('Main Window', 'Solve confirmation', TextString,
                              'NONOGRAM.INI');

    (* Load confirmation *)
    IF (LoadConfirmation) THEN
      StrCopy(TextString, '1')
    ELSE
      StrCopy(TextString, '0');
    WritePrivateProfileString('Main Window', 'Load confirmation', TextString,
                              'NONOGRAM.INI');

    (* Solution options *)
    (* Quick start *)
    Str(ORD(QuickStrtOn), TextString);
    WritePrivateProfileString('Solution Options', 'Quick start on', TextString,
                              'NONOGRAM.INI');

    (* Edge checking *)
    Str(ORD(EdgeCheckOn), TextString);
    WritePrivateProfileString('Solution Options', 'Edge checking on', TextString,
                              'NONOGRAM.INI');

    (* Full row testing *)
    Str(ORD(FullRwTstOn), TextString);
    WritePrivateProfileString('Solution Options', 'Full row testing on', TextString,
                              'NONOGRAM.INI');

    (* Row following *)
    Str(ORD(RowFollowOn), TextString);
    WritePrivateProfileString('Solution Options', 'Row following on', TextString,
                              'NONOGRAM.INI');

    (* Combination algorithm *)
    Str(ORD(CombinatnOn), TextString);
    WritePrivateProfileString('Solution Options', 'Combination on', TextString,
                              'NONOGRAM.INI');

    Str(VARSSize, TextString);
    WritePrivateProfileString('Solution Options', 'VARS size', TextString,
                              'NONOGRAM.INI');

    (* Display options *)
    (* Display rotation *)
    Str(ORD(DisplayRotate), TextString);
    WritePrivateProfileString('Display Options', 'Display rotation', TextString,
                              'NONOGRAM.INI');

    (* Display flip *)
    Str(ORD(DisplayFlip), TextString);
    WritePrivateProfileString('Display Options', 'Display flip', TextString,
                              'NONOGRAM.INI');

    (* Yes, we saved on exit *)
    WritePrivateProfileString('Main Window', 'Save on exit', '1', 'NONOGRAM.INI');
  END
  ELSE
  BEGIN
    (* No, we didn't save on exit *)
    WritePrivateProfileString('Main Window', 'Save on exit', '0', 'NONOGRAM.INI');
  END;
END;


(************************************************************************)
(* Methods of TAboutBox follow... *)


CONSTRUCTOR TAboutBox.Init(AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancesor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)                              
  Text1 := New(PStatic, InitResource(@self, ID_ABOTTITLE, 15));
  Text2 := New(PStatic, InitResource(@self, ID_COPYRIGHT, 15));
  Text3 := New(PStatic, InitResource(@self, ID_REGISTER, 15));
  Text4 := New(PStatic, InitResource(@self, ID_VERSIONNO, 15));
  Text5 := New(PStatic, InitResource(@self, ID_RELSEDATE, 15));
END;


PROCEDURE TAboutBox.SetupWindow;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Set controls appropriately *)
  Text1^.SetText('Nonogram Solver');
  Text2^.SetText('Copyright © M G Davidson - 1993');
  Text3^.SetText('Registered to: M G Davidson');
  Text4^.SetText('Version 2.0');
  Text5^.SetText('Released: 20/12/1993');
END;


(**********************************************************************)
(* Methods of TPreferences follow *) 


CONSTRUCTOR TPreferences.Init(AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Obtain handles to controls *)
  Check1 := New(PCheckBox, InitResource(@self, ID_PREFSOLVE));
  Check2 := New(PCheckBox, InitResource(@self, ID_PREFLOADC));
  Check3 := New(PCheckBox, InitResource(@self, ID_PREFTOOLB));
  Check4 := New(PCheckBox, InitResource(@self, ID_PREFSTATU));
  Check5 := New(PCheckBox, InitResource(@self, ID_PREFSAVEO));
END;


PROCEDURE TPreferences.SetupWindow;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Set check boxes appropriately *)
  IF (PMainWindow(Parent)^.SolveConfirmation) THEN
    Check1^.SetCheck(BF_CHECKED)
  ELSE
    Check1^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.LoadConfirmation) THEN
    Check2^.SetCheck(BF_CHECKED)
  ELSE
    Check2^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.ToolbarExist) THEN
    Check3^.SetCheck(BF_CHECKED)
  ELSE
    Check3^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.StatbarExist) THEN
    Check4^.SetCheck(BF_CHECKED)
  ELSE
    Check4^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.SaveOnExit) THEN
    Check5^.SetCheck(BF_CHECKED)
  ELSE
    Check5^.SetCheck(BF_UNCHECKED);
END;


PROCEDURE TPreferences.OK(VAR Msg: TMessage);
VAR
  WinRect: TRECT;
BEGIN
  (* Update parent fields *)
  IF (Check1^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.SolveConfirmation := TRUE
  ELSE
    PMainWindow(Parent)^.SolveConfirmation := FALSE;

  IF (Check2^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.LoadConfirmation := TRUE
  ELSE
    PMainWindow(Parent)^.LoadConfirmation := FALSE;

  IF (Check3^.GetCheck = BF_CHECKED) THEN
  BEGIN
    IF NOT(PMainWindow(Parent)^.ToolbarExist) THEN
    BEGIN
      (* Create new toolbar *)
      GetClientRect(PMainWindow(Parent)^.HWindow, WinRect);
      PMainWindow(Parent)^.ToolbarHan := New(PToolbar, Init(PMainWindow(Parent), 0, 0,
                                             (WinRect.Right - WinRect.Left), 30));
      Application^.MakeWindow(PMainWindow(Parent)^.ToolbarHan);
      PMainWindow(Parent)^.ToolbarExist := TRUE;
      PMainWindow(Parent)^.RedoChildren;
    END;
  END
  ELSE
  BEGIN
    IF (PMainWindow(Parent)^.ToolbarExist) THEN
    BEGIN
      (* Destroy current toolbar *)
      DestroyWindow(PMainWindow(Parent)^.ToolbarHan^.HWindow);
      PMainWindow(Parent)^.ToolbarExist := FALSE;
      PMainWindow(Parent)^.RedoChildren;
    END;
  END;

  IF (Check4^.GetCheck = BF_CHECKED) THEN
  BEGIN
    IF NOT(PMainWindow(Parent)^.StatbarExist) THEN
    BEGIN
      (* Create new status bar *)
      GetClientRect(PMainWindow(Parent)^.HWindow, WinRect);
      PMainWindow(Parent)^.StatbarHan := New(PStatbar, Init(PMainWindow(Parent), 0,
                                             (WinRect.Bottom - 22), 
                                             (WinRect.Right - WinRect.Left), 22));
      Application^.MakeWindow(PMainWindow(Parent)^.StatbarHan);
      PMainWindow(Parent)^.StatbarExist := TRUE;
      PMainWindow(Parent)^.RedoChildren;
    END;
  END
  ELSE
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
    BEGIN
      (* Destroy current status bar *)
      DestroyWindow(PMainWindow(Parent)^.StatbarHan^.HWindow);
      PMainWindow(Parent)^.StatbarExist := FALSE;
      PMainWindow(Parent)^.RedoChildren;
    END;
  END;

  IF (Check5^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.SaveOnExit := TRUE
  ELSE
    PMainWindow(Parent)^.SaveOnExit := FALSE;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


PROCEDURE TPreferences.DialogHelp(VAR Msg: TMessage);
BEGIN
  (* Display relevant help page *)
  WinHelp (HWindow, 'NONOGRAM.HLP', HELP_CONTEXT, HC_PREFER);
END;


(**********************************************************************)
(* Methods of TConfigWin follow *)


CONSTRUCTOR TConfigWin.Init(AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Obtain handles to controls *)
  Check1 := New(PCheckBox, InitResource(@self, ID_QStart));
  Check2 := New(PCheckBox, InitResource(@self, ID_ECheck));
  Check3 := New(PCheckBox, InitResource(@self, ID_FRowTs));
  Check4 := New(PCheckBox, InitResource(@self, ID_RowFol));
  Check5 := New(PCheckBox, InitResource(@self, ID_Combin));
  Field  := New(PEdit, InitResource(@self, ID_Vars, 4));
END;


PROCEDURE TConfigWin.SetupWindow;
VAR
  Line: ARRAY [0..4] OF CHAR;
  TextItem: PChar;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Set up check boxes *)
  IF (PMainWindow(Parent)^.QuickStrtOn) THEN
   Check1^.SetCheck(BF_CHECKED)
  ELSE
   Check1^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.EdgeCheckOn) THEN
   Check2^.SetCheck(BF_CHECKED)
  ELSE
   Check2^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.FullRwTstOn) THEN
   Check3^.SetCheck(BF_CHECKED)
  ELSE
   Check3^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.RowFollowOn) THEN
   Check4^.SetCheck(BF_CHECKED)
  ELSE
   Check4^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.CombinatnOn) THEN
   Check5^.SetCheck(BF_CHECKED)
  ELSE
   Check5^.SetCheck(BF_UNCHECKED);

  (* Set up text control *)
  Str(PMainWindow(Parent)^.VARSSize, Line);
  Field^.Insert(@Line);
END;


PROCEDURE TConfigWin.OK(VAR Msg: TMessage);
VAR
  Code: INTEGER;
  Line: ARRAY [0..4] OF CHAR;
  S: String;
BEGIN
  (* Get value of 'VARS' array *)
  GetDlgItemText (HWindow, ID_VARS, @Line, 4);
  S := StrPas(Line);
  Val(S, PMainWindow(Parent)^.VARSSize, Code);

  IF (PMainWindow(Parent)^.VARSSize > 600) THEN PMainWindow(Parent)^.VARSSize := 600;
  IF (PMainWindow(Parent)^.VARSSize < 0) THEN PMainWindow(Parent)^.VARSSize := 0;

  (* Reset parent fields based on window changes *)
  IF (Check1^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.QuickStrtOn := TRUE
  ELSE
    PMainWindow(Parent)^.QuickStrtOn := FALSE;

  IF (Check2^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.EdgeCheckOn := TRUE
  ELSE
    PMainWindow(Parent)^.EdgeCheckOn := FALSE;

  IF (Check3^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.FullRwTstOn := TRUE
  ELSE
    PMainWindow(Parent)^.FullRwTstOn := FALSE;

  IF (Check4^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.RowFollowOn := TRUE
  ELSE
    PMainWindow(Parent)^.RowFollowOn := FALSE;

  IF (Check5^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.CombinatnOn := TRUE
  ELSE
    PMainWindow(Parent)^.CombinatnOn := FALSE;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


PROCEDURE TConfigWin.DialogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up relevant help page *)
  WinHelp(HWindow, 'NONOGRAM.HLP', HELP_CONTEXT, HC_SOLUTION);
END;


(**********************************************************************)
(* Methods of TDisplayOptions follow *)


CONSTRUCTOR TDisplayOptions.Init (AParent: PWindowsObject; AName: PChar);
BEGIN
  (* CAll ancestor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)
  Rad1 := New(PRadioButton, InitResource(@self, ID_ZERODG));
  Rad2 := New(PRadioButton, InitResource(@self, ID_NINEDG));
  Rad3 := New(PRadioButton, InitResource(@self, ID_ONEEDG));
  Rad4 := New(PRadioButton, InitResource(@self, ID_TWOSDG));
  Chk1 := New(PCheckBox, InitResource(@self, ID_Flip));
END;


PROCEDURE TDisplayOptions.SetupWindow;
BEGIN
  (* CAll ancestor method *)
  TDialog.SetupWindow;

  (* Uncheck all the radio buttons *)
  Rad1^.SetCheck(BF_UNCHECKED);
  Rad2^.SetCheck(BF_UNCHECKED);
  Rad3^.SetCheck(BF_UNCHECKED);
  Rad4^.SetCheck(BF_UNCHECKED);

  (* Set radio buttons appropriately *)
  CASE ORD(PMainWindow(Parent)^.DisplayRotate) OF
    0 : Rad1^.SetCheck(BF_CHECKED);
    1 : Rad2^.SetCheck(BF_CHECKED);
    2 : Rad3^.SetCheck(BF_CHECKED);
    3 : Rad4^.SetCheck(BF_CHECKED);
  END;

  (* Should we flip the data set *)
  IF (PMainWindow(Parent)^.DisplayFlip) THEN
    Chk1^.Check
  ELSE
    Chk1^.UnCheck;
END;


PROCEDURE TDisplayOptions.DialogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up appropriate help page *)
  WinHelp(HWindow, 'NONOGRAM.HLP', HELP_CONTEXT, HC_DISPLAY);
END;


PROCEDURE TDisplayOptions.OK(VAR Msg: TMessage);
VAR
  A: INTEGER;
BEGIN                                                             
  (* Copy radio buttons positions to parent fields *)
  IF (Rad1^.GetCheck = BF_CHECKED) THEN A := 0;
  IF (Rad2^.GetCheck = BF_CHECKED) THEN A := 1;
  IF (Rad3^.GetCheck = BF_CHECKED) THEN A := 2;
  IF (Rad4^.GetCheck = BF_CHECKED) THEN A := 3;
  PMainWindow(Parent)^.DisplayRotate := DisplayRotation(A);

  IF (Chk1^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.DisplayFlip := TRUE
  ELSE
    PMainWindow(Parent)^.DisplayFlip := FALSE;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


(**********************************************************************)
(* Main program method declarations follow *)


CONSTRUCTOR TNonogram.Init(AName: PChar);
BEGIN
  (* Main application initialisation *)
  TApplication.Init(AName);
  HAccTable := LoadAccelerators(HInstance, 'Accelerators_1');
END;


PROCEDURE TNonogram.InitMainWindow;
BEGIN
  MainWindow := New(PMainWindow, Init(NIL, 'Nonogram Solver - [none]'));
END;


(**********************************************************************)
(* This is the main program *)


VAR MenuApp: TNonogram;

BEGIN
  MenuApp.Init ('Nonogram');
  MenuApp.Run;
  MenuApp.Done;
END.



