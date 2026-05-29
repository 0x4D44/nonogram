PROGRAM Nonogram;

(* PROGRAM DESCRIPTION
*  ===================
*
*  This program solves NONOGRAM puzzles.
*
*  Version 2.1. New Nonogram solve option added - SINGLE. This allows the program
*  to solve 'Hermit Crab' which it could not previously do. This version was
*  released on 20/02/94.
*
*
*  Version 2.2. This version improves upon the previous versions
*  considerably. It now offers full MDI functionality enabling multiple 
*  Nonogram display windows to be open at the same time. The screen 
*  design has been improved with a 3D look and Borland's custom controls 
*  have been replaced by MicroSoft's 3D controls. A new interactive editing 
*  feature has been added allowing data to be edited insitu and then saved 
*  to disk. An improved data parser calculates the data complexity as well 
*  as checking whether the data set is consistent. A new solution option - 
*  'Greedy' - allows solve times to be reduced at the cost of less processor 
*  time for other Windows applications. File handling has been improved 
*  and a new automatic installation program simplifies program setup. This 
*  version was released on 10/04/94.
*
*
*  Version 2.21 (Minor update). This revison makes minor changes to the scroll bar
*  handling methods. The main change is that is now no longer possible to use the
*  cursor keys to move the in place editing window off the screen as was previously
*  possible. In the previous version it was also possible to click on a cell marked
*  say 18 when the scrollbars were in a non-zero position and the this would bring
*  up an incorrect editing window. This bug has been corrected. Another bug which
*  prevented the scroll bars being redrawn when a new file of a different size was
*  opened into an existing window has been corrected as well. No changes have been
*  made to the fundmental Nonogram solving routines. This version was released on
*  02/05/1994.
*
*
*  Version 2.3. This version tidies up the dialog box display and updates the help
*  file as well. Slight changes have been made to the fundamental Nonogram solving
*  routines. These have been made so that the program can be compiled in the {$R+}
*  state without getting run-time errors due to sloppy array handling. A bug in
*  setting the viewport origin correctly when <DrawPoint> obtained its own DC has
*  also been corrected. The aim of the changes has been to get the program into a
*  state where it can be released commercially. This version was released on
*  15/11/1994.
*
*
*
*  PROGRAM INFORMATION
*  ===================
*  Author   : M G Davidson
*  Date     : 15/11/1994
*  Version  : 2.3
*  Language : PASCAL
*)

(* The original {$R NONOGRAM.RES} directive is disabled for the mdtpw 32-bit
   build: the 16-bit NONOGRAM.RES is the Win16 record format, which lld-link
   rejects. The Win32 resource is bound via mdtpw.toml (generated/nonogram.rc,
   reconstructed from NONOGRAM.RES by mdtpw's nonores tool). *)
{$M 40000, 8192}


USES Win31, ShellAPI, WinTypes, WinProcs, WObjects, StdDlgs,
     WinDos, Strings, CommDlg, Ctl3d, MDGentpu;

VAR
  (* Global variables *)
  UserName, CompanyName, LicenceNumber: ARRAY [0..50] OF CHAR;

CONST
  (* Menu/resource ID constants *)
  CM_NEW       = 101;    (* File|New menu resource ID *)
  CM_LOAD      = 102;    (* File|Load menu resource ID *)
  CM_SAVE      = 103;    (* File|Save menu resource ID *)
  CM_SAVEAS    = 104;    (* File|Save as menu resource ID *)
  CM_PRINT     = 105;    (* File|Print menu resource ID *)
  CM_SETUP     = 106;    (* File|Print setup menu resource ID *)
  CM_FILEEXIT  = 107;    (* File|Exit menu resource ID *)
  CM_FILE1     = 150;    (* Old file number 1 *)
  CM_FILE2     = 151;    (* Old file number 2 *)
  CM_FILE3     = 152;    (* Old file number 3 *)
  CM_FILE4     = 153;    (* Old file number 4 *)
  CM_SOLVE     = 201;    (* Options|Solve Nonogram menu resource ID *)
  CM_INFO      = 202;    (* Options|Information menu resource ID *)
  CM_HEADDATA  = 203;    (* Options|Header data menu resource ID *)
  CM_CONFDISPL = 204;    (* Options|Configure display menu resource ID *)
  CM_CONFSOLUT = 205;    (* Options|Configure solution menu resource ID *)
  CM_PREFER    = 206;    (* Options|Preferences menu resource ID *)
  CM_RECOVER   = 207;    (* Options|Bad data recovery menu resource ID *)
  CM_STOPSO    = 223;    (* Options|Stop solve menu resource ID - XOR with CM_SOLVE *)
  ID_QSTART    = 501;    (* Solution configure dialog - Quick start check box *)
  ID_ECHECK    = 502;    (* Solution configure dialog - Edge checking check box *)
  ID_FROWTS    = 503;    (* Solution configure dialog - Full row testing check box *)
  ID_ROWFOL    = 504;    (* Solution configure dialog - row following check box *)
  ID_SINGLE    = 505;    (* Solution configure dialog - single items only *)
  ID_COMBIN    = 506;    (* Solution configure dialog - combinational check box *)
  ID_GREEDY    = 507;    (* Solution configure dialog - greedy mode check box *)
  ID_VARS      = 508;    (* Solution configure dialog - VARS edit text *)
  ID_ZERODG    = 530;    (* Display configure dialog - 0 degrees radio button *)
  ID_NINEDG    = 531;    (* Display configure dialog - 90 degrees radio button *)
  ID_ONEEDG    = 532;    (* Display configure dialog - 180 degrees radio button *)
  ID_TWOSDG    = 533;    (* Display confgiure dialog - 270 degrees radio button *)
  ID_FLIP      = 534;    (* Display configure dialog - flip display check box *)
  ID_DILOGDEFA = 535;    (* Display configure dialog - set as default button *)
  ID_RESTODEFA = 536;    (* Display configure dialog - restore defaults *)
  ID_BLKCOLOUR = 537;    (* Display configure dialog - set block colour *)
  ID_DOTCOLOUR = 538;    (* Display configure dialog - set dot colour *)
  ID_ABOTTITLE = 550;    (* About dialog program title box *)
  ID_COPYRIGHT = 551;    (* About dialog CopyRight static text control *)
  ID_REGNAME   = 552;    (* About dialog licensed to name box *)
  ID_REGCOMP   = 553;    (* About dialog licensed to company box *)
  ID_VERSIONNO = 554;    (* About dialog version number *)                       
  ID_RELSEDATE = 555;    (* About dialog release date *)
  ID_INFOTITLE = 570;    (* Information dialog data title *)
  ID_INFOXGRID = 571;    (* Information dialog data X grid size *)
  ID_INFOYGRID = 572;    (* Informtaion dialog data Y grid size *)
  ID_INFOXPRSE = 573;    (* Information dialog data X parse result *)           
  ID_INFOYPRSE = 574;    (* Information dialog data Y parse result *)
  ID_INFOFILES = 575;    (* Information dialog data file size *)
  ID_INFOFILED = 576;    (* Information dialog data file date *)
  ID_INFOCOMME = 577;    (* Information dialog data parse comment *)
  ID_INFOCOMBI = 578;    (* Information dialog average combinations *)
  ID_INFOCOMPL = 579;    (* Information dialog complexity level *)
  ID_EDITDATA  = 580;    (* Edit data message *)
  ID_EDITEREDT = 590;    (* Editer window - edit control *)
  ID_EDITERSTA = 591;    (* Editer window - static control *)
  ID_HEADDESCR = 600;    (* Header info window - description *)
  ID_HEADXACRO = 601;    (* Header info window - X across *)
  ID_HEADYACRO = 602;    (* Header info window - Y across *)
  ID_PREFSOLVE = 650;    (* Preferences dialog box - solve confirmation *)
  ID_PREFLOADC = 651;    (* Preferences dialog box - load confirmation *)
  ID_PREFTOOLB = 652;    (* Preferences dialog box - tool bar *)
  ID_PREFSTATU = 653;    (* Preferences dialog box - status bar *)
  ID_PREFSAVEO = 654;    (* Preferences dialog box - save on exit *)
  ID_DILOGHELP = 998;    (* Dialog help button resource ID *)
  CM_CONTENTS  = 901;    (* Menu Help|Contents resource ID *)
  CM_HELPONHLP = 902;    (* Menu Help|Help on help resource ID *)
  CM_HELPABOUT = 999;    (* Menu Help|About resource ID *)

  (* Help Constants *)
  HC_INTRO     = 1;     
  HC_PREFER    = 2;      (* Preferences dialog help context ID *)
  HC_SOLUTION  = 3;      (* Solution options dialog help context ID *) 
  HC_DISPLAY   = 4;      (* Display options dialog help context ID *)
  HC_INFOBOX   = 5;      (* Information dialog belp context ID *)
  HC_HEADBOX   = 6;      (* Header information dialog belp context ID *)
  HELPFILENAME = 'NONOGRAM.HLP';
  INIFILENAME  = 'NONOGRAM.INI';
                
  (* User messages *)
  WM_MENUCHANGE = WM_USER + 1;

  (* Other Constants *)
  NoToolButtons = 13;                        (* Number of tool bar buttons *)
  MaxXAcross = 100;                          (* Maximum number of X rows (bumped 64->100 to fit MILLENNI 75x55 + the app's own <=100 load limit) *)
  MaxYAcross = 100;                          (* Maximum number of Y rows *)
  MaxNoElements = 40;                        (* Maximum number of elements per row (bumped 15->40 to fit PUMPKIN/MILLENNI 15-16 run lines) *)

TYPE
  (* Display enumerated type *)
  DisplayRotation = (DR_ZERO, DR_NINE, DR_ONEE, DR_TWOS);

  (* Solution VARS array type *)
  PPotVal = ^TPotVal;
  TPotVal = RECORD
    Data: ARRAY [1..MaxYAcross, 1..300] OF SHORTINT;
  END;

  (* Custom colours storage array *)
  TLongAry = ARRAY [0..15] OF LONGINT;


  (*************************************************************************************)
  (* Window class prototypes from here on... *)

  (* Predefine for <TToolbar> class *)
  PToolButton = ^TToolbutton;

  (* Toolbar window prototype *)
  PToolbar = ^TToolbar;
  TToolbar = OBJECT(TWindow)
    ToolbuttonPntr: ARRAY[1..NoToolButtons] OF PToolButton;
    HButUp, HButDown, HEnabledBitmap, HDisabledBitmap: HBitmap;

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


  (* Toolbutton window prototype *)
  TToolbutton = OBJECT(TWindow)
    UpPosition: BOOLEAN;                         (* Is the button up or down? *)
    LMseButton: BOOLEAN;                         (* Is the left button down? *)
    Enabled: BOOLEAN;                            (* Is the button enabled? *)
    BitmapX, BitmapY: INTEGER;                   (* Bitmap X and Y positions *)
    WPAR, LPAR: INTEGER;                         (* Message to be sent values *)
    DownText,                                    (* Text to be displayed: button is down *)
    UpText: ARRAY [0..100] OF CHAR;              (* Text to be displayed: button is up *)

    CONSTRUCTOR Init(AParent: PWindowsObject; XPos, YPos: INTEGER;
                     BitmX, BitmY, WPR, LPR: INTEGER; En: BOOLEAN);
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


  (* Status bar window prototypes *)
  PStatbar = ^TStatbar;
  TStatbar = OBJECT(TWindow)
    Text: ARRAY [0..100] OF CHAR;              (* The main text string *)
    TimeText: ARRAY [0..20] OF CHAR;           (* The time taken text string *)
    PointText: ARRAY [0..10] OF CHAR;          (* The number of points found so far *)
    HStatbarFont: HFONT;                       (* Handle to vertical axes font *)
    StatbarFont: TLOGFONT;                     (* Font record for the status bar font *)

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


  (* Display window prototypes  - this is the actual window in which the Nonogram
     is displayed *)
  PDisplay = ^TDisplay;
  TDisplay = OBJECT(TWindow)
    Sum1, Sum2: INTEGER;                       (* Sums of the across/down array elements *)
    CombinX: LONGINT;                          (* Number of data X combinations *)
    CombinY: LONGINT;                          (* Number of data Y combinations *)
    Filename: ARRAY [0..FSPATHNAME] OF CHAR;   (* Nonogram filename *)
    FilTitle: ARRAY [0..200] OF CHAR;          (* Nonogram datafile title *)
    SentMessage: TMsg;                         (* General message handle *)
    SolveTime: LONGINT;                        (* Solve time variable *)
    CloseAfterSolve: BOOLEAN;                  (* Should we close the window after the solve? *)
    SolveInProgress: BOOLEAN;                  (* Is a solution currently taking place? *)
    XAcross, YAcross: INTEGER;                 (* Nonogram size attributes *)
    XFilled: ARRAY [1..MaxXAcross] OF INTEGER; (* Main input puzzle data storage in X *)
    YFilled: ARRAY [1..MaxYAcross] OF INTEGER; (* Main input puzzle data storage in Y *)
    PlotTotal: INTEGER;                        (* Total number of points found so far *)
    VScrollbarPresent,                         (* Vertical scrollbar visible on screen *)
    HScrollbarPresent: BOOLEAN;                (* Horizontal scrollbar visible on screen *)
    DisplayRotate: DisplayRotation;            (* Which way round do we display the data *)
    DisplayFlip: BOOLEAN;                      (* Should we flip the data around *)
    CustColours: TLongAry;                     (* Custom colours *)
    BlkBrush,                                  (* Block brush handle *)
    DotBrush: HBRUSH;                          (* Filled block brush handle *)
    DotColour,
    BlkColour: LONGINT;                        (* Colours of dot and block brushes *)
    ValidMouseDown: BOOLEAN;                   (* Mouse has been left clicked validly *)
    XAxisSelected: BOOLEAN;                    (* The X-axis has been selected *) 
    NumberSelected: INTEGER;                   (* The X-axis position which has been selected *)
    LowestPos: INTEGER;

    (* The following are used by the main program *)
    XElements: ARRAY [1..MaxXAcross, 1..MaxNoElements] OF INTEGER;   (* Obvious *)   
    YElements: ARRAY [1..MaxYAcross, 1..MaxNoElements] OF INTEGER;   (* Obvious *)
    ScreenGrid: ARRAY [1..MaxXAcross, 1..MaxYAcross] OF INTEGER;     (* Obvious *)
    RecoverData: ARRAY [1..MaxXAcross, 1..MaxNoElements] OF INTEGER;

    (* The following are used by the combinational algorithm *)
    PossiblePos: ARRAY [1..MaxYAcross] OF INTEGER;
    Start: ARRAY [1..MaxNoElements] OF INTEGER;

    CONSTRUCTOR Init(AParent: PWindowsObject; ATitle: PChar);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    FUNCTION    GetClassName: PChar; virtual;
    FUNCTION    CanClose: BOOLEAN; virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   WMSize(VAR Msg: TMessage);
                virtual WM_FIRST + WM_SIZE;
    PROCEDURE   WMMenuSelect(VAR Msg: TMessage);
                virtual WM_FIRST + WM_MENUSELECT;
    PROCEDURE   WMMDIActivate(VAR Msg: TMessage);
                virtual WM_FIRST + WM_MDIACTIVATE;
    PROCEDURE   WMLButtonDown(VAR Msg: TMessage);
                virtual WM_FIRST + WM_LBUTTONDOWN;
    PROCEDURE   WMLButtonUp(VAR Msg: TMessage);
                virtual WM_FIRST + WM_LBUTTONUP;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct); virtual;
    PROCEDURE   DrawAxes(TheDC: HDC);
    PROCEDURE   DrawPoint(TheDC: HDC; XPos, YPos, BlockDot: INTEGER; Allways: BOOLEAN);
    PROCEDURE   CMLoad(VAR Msg: TMessage);
                virtual CM_FIRST + CM_LOAD;
    PROCEDURE   FileLoadImplement;
    PROCEDURE   CMSave(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SAVE;
    PROCEDURE   CMSaveAs(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SAVEAS;
    PROCEDURE   CMPrint(VAR Msg: TMessage);
                virtual CM_FIRST + CM_PRINT;
    FUNCTION    GetPrinterDC: HDC;
    PROCEDURE   CMConfDispl(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONFDISPL;
    PROCEDURE   CMHeadData(VAR Msg: TMessage);
                virtual CM_FIRST + CM_HEADDATA;
    PROCEDURE   CMSolve(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SOLVE;
    PROCEDURE   CMInfo(VAR Msg: TMessage);
                virtual CM_FIRST + CM_INFO;
    PROCEDURE   CMRecover(VAR Msg: TMessage);
                virtual CM_FIRST + CM_RECOVER;
    FUNCTION    CheckGroup(Group: INTEGER; GroupMax: INTEGER; PosMax: INTEGER; Target: INTEGER): BOOLEAN;
    PROCEDURE   IDEditData(VAR Msg: TMessage);
                virtual CM_FIRST + ID_EDITDATA;
    PROCEDURE   DoScrollbars;
    PROCEDURE   MakeText(NumSel: INTEGER; XAxisData: BOOLEAN; HText: PChar);
    PROCEDURE   Yielder;
    PROCEDURE   QuickData;
    PROCEDURE   CheckEdge;
    PROCEDURE   TestRowFull;
    PROCEDURE   FollowRow;
    PROCEDURE   SingleTst;
    PROCEDURE   Combination;
    PROCEDURE   EasyFill(I, K: INTEGER);
    PROCEDURE   FillDot(Iin, Kin, STot: INTEGER);
    PROCEDURE   ResetData;
    PROCEDURE   ParseData;
    PROCEDURE   CalComplexity;
  END;


  (* Main window - This is the main window. *)
  PMainWindow = ^TMainWindow;
  TMainWindow = OBJECT(TMDIWindow)
    SolveConfirmation,                         (* Preferences solve confirmation *)
    LoadConfirmation,                          (* Preferenced load confirmation *) 
    SaveOnExit: BOOLEAN;                       (* Preferences save on exit *)
    SentMessage: TMsg;                         (* General message handle *)
    DkGrayPen: HPEN;                           (* Handle to a dark gray pen *)
    LtGrayPen: HPEN;                           (* Handle to a light gray pen *)
    HAxesVFont,                                (* Handle to vertical axes font *)
    HAxesHFont: HFONT;                         (* Handle to horizontal axes font *)
    AxesVFont,                                 (* Vertical axes font record *)
    AxesHFont: TLOGFONT;                       (* Horizontal axes font *)
    ToolBarHan: PToolbar;                      (* Pointer to toolbar *)
    DisplayHan: PDisplay;                      (* Pointer to display window *)
    PotentData: PPotVal;                       (* Pointer to the potential data array *)
    StatbarHan: PStatbar;                      (* Pointer to status bar *)
    ToolbarExist,                              (* Do toolbar and main window exist *)
    StatbarExist: BOOLEAN;                     (* Does status bar exist *)
    GreedyModeOn,                              (* Greedy processor mode is on *)
    QuickStrtOn,                               (* Flag - Quick Data is on *)
    EdgeCheckOn,                               (* Flag - Edge Checking is on *)
    FullRwTstOn,                               (* Flag - Full Row Testing is on *)
    RowFollowOn,                               (* Flag - Row following is on *)
    SingleTstOn,                               (* Flag - Single Testing is on *)
    CombinatnOn: BOOLEAN;                      (* Flag - Combination algorithm is on *)
    VARSSize: INTEGER;                         (* Size of the VARS array *)
    DisplayRotate: DisplayRotation;            (* Which way round do we display the data *)
    DisplayFlip: BOOLEAN;                      (* Should we flip the data around *)
    CanThink: BOOLEAN;                         (* Indicates that solving is allowed *)
    SolveInProgress: BOOLEAN;                  (* Indicates that solving is in progress *)
    StopSolAndExit: BOOLEAN;                   (* Stop solving and then exit *)
    ChildClosing: BOOLEAN;                     (* Indicates that a child window is closing *)
    PrintStruct: TPRINTDLG;                    (* Printer information structure *)
    DevModePrn: TDEVMODE;                      (* Printer - device mode *)
    DevNamesPrn: TDEVNAMES;                    (* Printer - device names *)
    PDevModePrn: PDEVMODE;
    PDevNamesPrn: PDEVNAMES;
    NoDisplays: INTEGER;                       (* Number of Display windows *)
    NorMenu, DefMenu: HMENU;                   (* Handles to menus *)
    NorMenuWindow, DefMenuWindow: HMENU;       (* Handles to 'Window' menus *)
    DotColour,
    BlkColour: LONGINT;                        (* Colours of dot and block brushes *)
    OldFiles: ARRAY [1..5, 0..100] OF CHAR;    (* Old file names *)


    CONSTRUCTOR Init (ATitle: PChar);
    DESTRUCTOR  Done; virtual;
    PROCEDURE   GetWindowClass(VAR AWndClass: TWndClass);
                virtual;
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   WMSize(VAR Msg: TMessage);
                virtual WM_FIRST + WM_SIZE;
    PROCEDURE   WMMenuSelect(VAR Msg: TMessage);
                virtual WM_FIRST + WM_MENUSELECT;
    PROCEDURE   WMDropFiles(VAR Msg: TMessage);
                virtual WM_FIRST + WM_DROPFILES;
    PROCEDURE   WMMenuChange(VAR Msg: TMessage);
                virtual WM_FIRST + WM_MENUCHANGE;
    PROCEDURE   Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
                virtual;
    PROCEDURE   HandleToolbar(Createit: BOOLEAN);
    PROCEDURE   HandleStatbar(Createit: BOOLEAN);
    PROCEDURE   HandleSizing(Width: INTEGER; Height: INTEGER);
    PROCEDURE   NoDisplayWin(Add: BOOLEAN);
    PROCEDURE   HandleOldFiles(NewFile: PChar);
    PROCEDURE   CMNew(VAR Msg: TMessage);
                virtual CM_FIRST + CM_NEW;
    PROCEDURE   CMLoad(VAR Msg: TMessage);
                virtual CM_FIRST + CM_LOAD;
    PROCEDURE   CMSetup(VAR Msg: TMessage);
                virtual CM_FIRST + CM_SETUP;
    PROCEDURE   CMFileExit(VAR Msg: TMessage);
                virtual CM_FIRST + CM_FILEEXIT;
    PROCEDURE   CMFile1(VAR Msg: TMessage);
                virtual CM_FIRST + CM_FILE1;
    PROCEDURE   CMFile2(VAR Msg: TMessage);
                virtual CM_FIRST + CM_FILE2;
    PROCEDURE   CMFile3(VAR Msg: TMessage);
                virtual CM_FIRST + CM_FILE3;
    PROCEDURE   CMFile4(VAR Msg: TMessage);
                virtual CM_FIRST + CM_FILE4;
    PROCEDURE   CMConfSolut(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONFSOLUT;
    PROCEDURE   CMConfDispl(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONFDISPL;
    PROCEDURE   CMPrefer(VAR Msg: TMessage);
                virtual CM_FIRST + CM_PREFER;
    PROCEDURE   CMContents(VAR Msg: TMessage);
                virtual CM_FIRST + CM_CONTENTS;
    PROCEDURE   CMHelpOnHlp(VAR Msg: TMessage);
                virtual CM_FIRST + CM_HELPONHLP;
    PROCEDURE   CMHelpAbout(VAR Msg: TMessage);
                virtual CM_FIRST + CM_HELPABOUT;              
    PROCEDURE   FileOpener(FileToOpen: PChar);
    FUNCTION    GetClassName: PChar; virtual;
    FUNCTION    CanClose: BOOLEAN; virtual;
    FUNCTION    CreateChild: PWindowsObject; virtual;
  END;


  (* About box dialog prototype *)
  PAboutBox = ^TAboutBox;
  TAboutBox = OBJECT(TDialog)                  
    Text1, Text2, Text3, Text4,                (* Static text control handles *)
    Text5, Text6: PStatic;

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
    Check4, Check5, Check6,
    Check7: PCheckBox;                         (* Check box handles *)
    Edit1: PEdit;                              (* VARS field edit control *)

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
    Radio1, Radio2,
    Radio3, Radio4: PRadioButton;              (* Radio button handles *)   
    Check1: PCheckBox;                         (* Check box handle *)
    TempBlkColour,
    TempDotColour: LONGINT;                    (* Temporary block and dot colours *)

    CONSTRUCTOR Init (AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK (VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
    PROCEDURE   DialogHelp (VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
    PROCEDURE   CMDilogDefa(VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGDEFA;
    PROCEDURE   CMRestoDefa(VAR Msg: TMessage);
                virtual ID_FIRST + ID_RESTODEFA;
    PROCEDURE   CMBlkColour(VAR Msg: TMessage);
                virtual ID_FIRST + ID_BLKCOLOUR;
    PROCEDURE   CMDotColour(VAR Msg: TMessage);
                virtual ID_FIRST + ID_DOTCOLOUR;
  END;


  PEditControl = ^TEditControl;
  TEditControl = OBJECT(TEdit)
    PROCEDURE   WMKeydown(VAR Msg: TMessage);
                virtual WM_FIRST + WM_KEYDOWN;
  END;


  (* Edit control popup dialog box prototype *)
  PEditer = ^TEditer;
  TEditer = OBJECT(TDialog)
    CloseOnDown,                                 (* Window can be closed by the down arrow key *)
    CloseOnUp:  BOOLEAN;                         (* Window can be closed by the up arrow key *)
    XPos,                                        (* Window X position *)   
    YPos: INTEGER;                               (* Window Y position *)
    Edit1: PEditControl;                         (* Edit control handle *)
    Text1: PStatic;                              (* Static control handle *)
    EditText: ARRAY [0..100] OF CHAR;            (* Initial edit control text *)

    CONSTRUCTOR Init(AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK (VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
  END;


  (* Data information dialog box prototypes *)
  PInfoBox = ^TInfoBox;
  TInfoBox = OBJECT(TDialog)
    Text1, Text2, Text3, Text4,
    Text5, Text6, Text7, Text8,
    Text9, Text10: PStatic;                      (* Static text handles *)

    CONSTRUCTOR Init(AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK(VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
    PROCEDURE   CMDilogHelp(VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
  END;


  (* Header information dialog box prototypes *)
  PHeadBox = ^THeadBox;
  THeadBox = OBJECT(TDialog)                    
    Edit1, Edit2, Edit3: PEdit;                  (* Edit controls *)

    CONSTRUCTOR Init(AParent: PWindowsObject; AName: PChar);
    PROCEDURE   SetupWindow; virtual;
    PROCEDURE   OK(VAR Msg: TMessage);
                virtual ID_FIRST + ID_OK; 
    PROCEDURE   CMDilogHelp(VAR Msg: TMessage);
                virtual ID_FIRST + ID_DILOGHELP;
  END;


  (* Main program declarations *)
  PNonogram = ^TNonogram;
  TNonogram = OBJECT(TApplication)
    CONSTRUCTOR Init(AName: PChar);
    PROCEDURE   InitMainWindow; virtual;
  END;


(**********************************************************************)
(* Methods of TToolbar from here onwards *)


CONSTRUCTOR TToolbar.Init(AParent: PWindowsObject; XPos, YPos, Width, Height: INTEGER);
VAR
  ParentRect: TRect;
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, '');

  (* Turn off the MDI flag that parent set *)
  SetFlags(WB_MDICHILD, FALSE);
  Attr.Style := WS_BORDER OR WS_CHILD OR WS_VISIBLE;

  (* Get parent client width *)
  GetClientRect(AParent^.HWindow, ParentRect);

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos;
    Y := YPos;
    W := Width;
    H := Height;
  END;

  (* Load blank toolbar button resource bitmap *)
  HButUp   := LoadBitmap(HInstance, 'UPBUTTON');
  HButDown := LoadBitmap(HInstance, 'DOWNBUTTON');
  HEnabledBitmap := LoadBitmap(HInstance, 'TB_ENABLED');
  HDisabledBitmap := LoadBitmap(HInstance, 'TB_DISABLED');
END;


DESTRUCTOR TToolbar.Done;
BEGIN
  (* Delete objects *)
  DeleteObject(HButUp);
  DeleteObject(HButDown);
  DeleteObject(HEnabledBitmap);
  DeleteObject(HDisabledBitmap);

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
  ToolbuttonPntr[1] := New(PToolbutton, Init(@self, 8, 4, 0, 0, CM_NEW, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[1]);
  ToolbuttonPntr[2] := New(PToolbutton, Init(@self, 32, 4, 16, 0, CM_LOAD, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[2]);
  ToolbuttonPntr[3] := New(PToolbutton, Init(@self, 56, 4, 32, 0, CM_SAVE, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[3]);
  ToolbuttonPntr[4] := New(PToolbutton, Init(@self, 80, 4, 48, 0, CM_PRINT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[4]);

  (* Second group *)
  ToolbuttonPntr[5] := New(PToolbutton, Init(@self, 114, 4, 80, 0, CM_SOLVE, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[5]);
  ToolbuttonPntr[6] := New(PToolbutton, Init(@self, 138, 4, 96, 0, CM_INFO, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[6]);
  ToolbuttonPntr[7] := New(PToolbutton, Init(@self, 162, 4, 64, 0, CM_HEADDATA, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[7]);
  ToolbuttonPntr[8] := New(PToolbutton, Init(@self, 186, 4, 112, 0, CM_CONFDISPL, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[8]);

  (* Third group *)
  ToolbuttonPntr[9] := New(PToolbutton, Init(@self, 220, 4, 128, 0, CM_CONFSOLUT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[9]);
  ToolbuttonPntr[10] := New(PToolbutton, Init(@self, 244, 4, 144, 0, CM_PREFER, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[10]);

  (* Fourth group *)
  ToolbuttonPntr[11] := New(PToolbutton, Init(@self, 278, 4, 160, 0, CM_CONTENTS, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[11]);
  ToolbuttonPntr[12] := New(PToolbutton, Init(@self, 302, 4, 176, 0, CM_HELPABOUT, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[12]);

  (* And finally the hidden stop solving button *)
  ToolbuttonPntr[13] := New(PToolbutton, Init(@self, 114, 4, 192, 0, CM_STOPSO, 0, TRUE));
  Application^.MakeWindow(ToolbuttonPntr[13]);
  ShowButton(13, SW_HIDE);
                                                                     
  (* Set text strings *)
  ToolbuttonPntr[1]^.SetDownText('Open a new Nonogram window');
  ToolbuttonPntr[1]^.SetUpText('');
  ToolbuttonPntr[2]^.SetDownText('Open a Nonogram data file');
  ToolbuttonPntr[2]^.SetUpText('');
  ToolbuttonPntr[3]^.SetDownText('Save current Nonogram data file');
  ToolbuttonPntr[3]^.SetUpText('');
  ToolbuttonPntr[4]^.SetDownText('Print a Nonogram');
  ToolbuttonPntr[4]^.SetUpText('');
  ToolbuttonPntr[5]^.SetDownText('Solve currently selected Nonogram data');
  ToolbuttonPntr[5]^.SetUpText('');
  ToolbuttonPntr[6]^.SetDownText('Get information on currently selected Nonogram data');
  ToolbuttonPntr[6]^.SetUpText('');
  ToolbuttonPntr[7]^.SetDownText('Edit Nonogram header data');
  ToolbuttonPntr[7]^.SetUpText('');
  ToolbuttonPntr[8]^.SetDownText('Configure Nonogram display');
  ToolbuttonPntr[8]^.SetUpText('');
  ToolbuttonPntr[9]^.SetDownText('Configure Nonogram solution');
  ToolbuttonPntr[9]^.SetUpText('');
  ToolbuttonPntr[10]^.SetDownText('Configure Nonogram preferences');
  ToolbuttonPntr[10]^.SetUpText('');
  ToolbuttonPntr[11]^.SetDownText('Help for the Nonogram Solver');
  ToolbuttonPntr[11]^.SetUpText('');
  ToolbuttonPntr[12]^.SetDownText('About the Nonogram Solver');
  ToolbuttonPntr[12]^.SetUpText('Nonogram Solver - Version 2.4');
  ToolbuttonPntr[13]^.SetDownText('Interrupt current Nonogram solve');
  ToolbuttonPntr[13]^.SetUpText('');
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
                             BitmX, BitmY, WPR, LPR: INTEGER; En: BOOLEAN);
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
  BitmapX := BitmX;
  BitmapY := BitmY;
  Enabled := En;
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
  HOldBitmap: HBitmap;
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
    HOldBitmap := SelectObject(MemDC, PToolBar(Parent)^.HButUp)
  ELSE
    HOldBitmap := SelectObject(MemDC, PToolBar(Parent)^.HButDown);

  (* BitBlt it *)
  BitBlt(TheDC, 0, 0, Attr.W, Attr.H, MemDC, 0, 0, SRCCopy);
  SelectObject(MemDC, HOldBitmap);

  (* Draw actual button face *)
  IF (Enabled) THEN
  BEGIN
    IF (PToolbar(Parent)^.HEnabledBitmap <> 0) THEN
    BEGIN
      HOldBitmap := SelectObject(MemDC, PToolBar(Parent)^.HEnabledBitmap);
      IF (UpPosition) THEN
        StretchBlt(TheDC, 3, 3, 16, 15,
                   MemDC, BitmapX, BitmapY, 16, 15, SRCCOPY)
      ELSE
        StretchBlt(TheDC, 4, 4, 16, 15,
                   MemDC, BitmapX, BitmapY, 16, 15, SRCCOPY);
      SelectObject(MemDC, HOldBitmap);
    END;
  END
  ELSE                    
  BEGIN
    IF (PToolbar(Parent)^.HDisabledBitmap <> 0) THEN
    BEGIN
      HOldBitmap := SelectObject(MemDC, PToolBar(Parent)^.HDisabledBitmap);
      StretchBlt(TheDC, 3, 3, 16, 15,
                 MemDC, BitmapX, BitmapY, 16, 15, SRCCOPY);
      SelectObject(MemDC, HOldBitmap);
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

  (* Turn off the MDI flag that parent set *)
  SetFlags(WB_MDICHILD, FALSE);
  Attr.Style := WS_BORDER OR WS_CHILD OR WS_VISIBLE;

  (* Set up window attributes *)
  WITH Attr DO
  BEGIN
    X := XPos -60;
    Y := YPos;
    W := Width;
    H := 80;
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
END;


DESTRUCTOR TStatbar.Done;
BEGIN
  (* Delete objects *)
  DeleteObject(HStatbarFont);

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
  strcopy(Text, 'Nonogram Solver - Version 2.4');
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
  MadeDC:  BOOLEAN;
  TempX:   INTEGER;
  ThePen:  HPen;
  OldPen:  HPen;
  TheRect: TRect;  
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
  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNSHADOW));
  OldPen := SelectObject(TheDC, ThePen);
  MoveTo(TheDC, TempX, 2);
  LineTo(TheDC, 5, 2);
  LineTo(TheDC, 5, 19);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNHIGHLIGHT));
  OldPen := SelectObject(TheDC, ThePen);
  LineTo(TheDC, TempX, 19);
  LineTo(TheDC, TempX, 3);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  (* Select status bar font *)
  SelectObject(TheDC, HStatbarFont);

  (* Set up colours *)
  SetBkColor(TheDC, GetSysColor(COLOR_BTNFACE));
  SetTextColor(TheDC, GetSysColor(COLOR_BTNTEXT));

  (* Clear the old text box *)
  TheRect.left   := 6;
  TheRect.top    := 3;
  TheRect.right  := (TempX-1);
  TheRect.bottom := 19;
  ExtTextOut(TheDC, 0, 0, ETO_OPAQUE, @TheRect, nil, 0, nil);

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
  MadeDC:  BOOLEAN;
  TheRect: TRECT;
  ThePen:  HPen;
  OldPen:  HPen;
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
  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNSHADOW));
  OldPen := SelectObject(TheDC, ThePen);
  MoveTo(TheDC, (Attr.W-40), 2);
  LineTo(TheDC, (Attr.W-95), 2);
  LineTo(TheDC, (Attr.W-95), 19);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNHIGHLIGHT));
  OldPen := SelectObject(TheDC, ThePen);
  LineTo(TheDC, (Attr.W-40), 19);
  LineTo(TheDC, (Attr.W-40), 3);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  (* Draw number of points box *)
  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNSHADOW));
  OldPen := SelectObject(TheDC, ThePen);
  MoveTo(TheDC, (Attr.W-5), 2);
  LineTo(TheDC, (Attr.W-35), 2);
  LineTo(TheDC, (Attr.W-35), 19);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  ThePen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_BTNHIGHLIGHT));
  OldPen := SelectObject(TheDC, ThePen);
  LineTo(TheDC, (Attr.W-5), 19);
  LineTo(TheDC, (Attr.W-5), 3);
  SelectObject(TheDC, OldPen);
  DeleteObject(ThePen);

  (* Select status bar font *)
  SelectObject(TheDC, HStatbarFont);

  (* Set up colours *)
  SetBkColor(TheDC, GetSysColor(COLOR_BTNFACE));
  SetTextColor(TheDC, GetSysColor(COLOR_BTNTEXT));

  (* Clear old boxes *)
  TheRect.left   := (Attr.W-94);
  TheRect.top    := 3;
  TheRect.right  := (Attr.W-40);
  TheRect.bottom := 19;
  ExtTextOut(TheDC, 0, 0, ETO_OPAQUE, @TheRect, nil, 0, nil);

  TheRect.left   := (Attr.W-34);
  TheRect.top    := 3;
  TheRect.right  := (Attr.W-5);
  TheRect.bottom := 19;
  ExtTextOut(TheDC, 0, 0, ETO_OPAQUE, @TheRect, nil, 0, nil);

  (* Set clipping and then draw the text *)
  TextOut(TheDC, (Attr.W-30), 3, PointText, strlen(PointText));
  TextOut(TheDC, (Attr.W-90), 3, TimeText, strlen(TimeText));

  (* Release DC *)
  IF (MadeDC) THEN
    ReleaseDC(HWindow, TheDC);
END;


(**********************************************************************)
(* Methods of TDisplay from here onwards *)


CONSTRUCTOR TDisplay.Init(AParent: PWindowsObject; ATitle: PChar);
VAR
  I: INTEGER;
BEGIN
  (* Call ancestor method *)
  TWindow.Init(AParent, ATitle);

  Attr.Style := Attr.Style OR WS_VSCROLL OR WS_HSCROLL OR WS_CHILD OR WS_CLIPSIBLINGS;
  (* Initialize variables *)
  VScrollBarPresent := FALSE;
  HScrollBarPresent := FALSE;
  CloseAfterSolve := FALSE;
  SolveInProgress := FALSE;
  Sum1 := 0;
  Sum2 := 0;
  CombinX := 0;
  CombinY := 0;

  (* Read initialisation file (NONOGRAM.INI) *)
  XAcross := GetPrivateProfileInt('Main Window', 'XAcross', 20, INIFILENAME);
  YAcross := GetPrivateProfileInt('Main Window', 'YAcross', 25, INIFILENAME);

  (* Initialize scrollbars *)
  Scroller := New(PScroller, Init(@self, 14, 14, (XAcross+3), (YAcross+3)));

  (* Default display values *)
  DisplayRotate := PMainWindow(Parent)^.DisplayRotate;
  DisplayFlip := PMainWindow(Parent)^.DisplayFlip;

  (* Initialise custom colours *)
  FOR I:= 0 TO 15 DO
    CustColours[I] := $FFFFFF;

  (* Create brushes *)
  BlkColour := PMainWindow(Parent)^.BlkColour;
  DotColour := PMainWindow(Parent)^.DotColour;
  BlkBrush := CreateSolidBrush(BlkColour);
  DotBrush := CreateSolidBrush(DotColour);
END;


DESTRUCTOR TDisplay.Done;
BEGIN
  (* Reset data *)
  ResetData;

  (* Delete any resources used up *)
  DeleteObject(BlkBrush);
  DeleteObject(DotBrush);

  (* Call ancestor method *)
  TWindow.Done;
END;


PROCEDURE TDisplay.GetWindowClass(VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TWindow.GetWindowClass (AWndClass);
  AWndClass.Style := CS_HREDRAW OR CS_VREDRAW;
  AWndClass.HIcon := LoadIcon(HInstance, 'ICON_3');
END;


FUNCTION TDisplay.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'NONOGRAM_DISPLAY';
END;


FUNCTION TDisplay.CanClose: BOOLEAN;
VAR
  TextString: ARRAY [0..80] OF CHAR;
BEGIN
  (* Update the main window menu list of previously opened files *)
  IF (StrComp(FileName, '') <> 0) THEN  PMainWindow(Parent)^.HandleOldFiles(FileName);

  (* Decrement number of display windows stored in MDIFrame window *)
  Sum1 := 0;
  Sum2 := 0;
  PMainWindow(Parent)^.NoDisplayWin(FALSE);

  (* Check to see if we should exit *)
  CanClose := TWindow.CanClose;
  PMainWindow(Parent)^.ChildClosing := FALSE;

  IF (SolveInProgress) THEN
  BEGIN
    Strcopy(TextString, 'Solve in progress!'+#13+#13);
    Strcat(TextString, 'Please confirm exit');
    IF (MessageBox(HWindow, TextString, 'Nonogram Solver:',
                   MB_OKCANCEL OR MB_ICONEXCLAMATION) = ID_OK) THEN
    BEGIN
      PostMessage(HWindow, WM_COMMAND, CM_STOPSO, 0);
      CloseAfterSolve := TRUE;
      PMainWindow(Parent)^.ChildClosing := TRUE;
    END;
    CanClose := FALSE;
    EXIT;
  END;
END;


PROCEDURE TDisplay.SetupWindow;
BEGIN
  (* Call ancestor method *)                   
  TWindow.SetupWindow;

  (* Reset file variables *)
  StrCopy(FileName, '');
  StrCopy(FilTitle, '');

  (* Reset all the arrays etc *)
  ResetData;
END;

              
PROCEDURE TDisplay.WMSize(VAR Msg: TMessage);
VAR
  Value: INTEGER;
  TheRect: TRECT;
BEGIN
  (* Call ancestor method *)
  TWindow.WMSize(Msg);

  (* Get window size *)
  GetClientRect(HWindow, TheRect);

  (* Handle horizontal scroll bar *)
  IF ((DisplayRotate = DR_ZERO) OR (DisplayRotate = DR_ONEE)) THEN
    Value := XAcross*14+42
  ELSE
    Value := YAcross*14+42;
  IF (VScrollBarPresent) THEN Value := Value + 20;
  IF ((TheRect.Right-TheRect.Left) < Value) THEN
  BEGIN
    ShowScrollBar(HWindow, SB_HORZ, TRUE);
    HScrollBarPresent := TRUE;
  END
  ELSE
  BEGIN
    ShowScrollBar(HWindow, SB_HORZ, FALSE);
    Scroller^.ScrollTo(0, Scroller^.YPos);
    HScrollBarPresent := FALSE;
  END;

  (* Handle vertical scroll bar *)
  IF ((DisplayRotate = DR_ZERO) OR (DisplayRotate = DR_ONEE)) THEN
    Value := YAcross*14+42
  ELSE
    Value := XAcross*14+42;
  IF (HScrollbarPresent) THEN Value := Value + 20;
  IF ((TheRect.Bottom-TheRect.Top) < Value) THEN
  BEGIN
    ShowScrollBar(HWindow, SB_VERT, TRUE);
    VScrollBarPresent := TRUE;
  END
  ELSE
  BEGIN
    ShowScrollBar(HWindow, SB_VERT, FALSE);
    Scroller^.ScrollTo(Scroller^.XPos, 0);
    VScrollBarPresent := FALSE;
  END;
END;


PROCEDURE TDisplay.WMMenuSelect(VAR Msg: TMessage);
BEGIN
  (* Handle menu selections by describing menu item's function in the status bar
     - if it exists *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
  BEGIN
    CASE (Msg.WParam) OF
      SC_CLOSE          : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Close this window');
      SC_MAXIMIZE       : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Maximize this window');
      SC_MINIMIZE       : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Minimize this window');
      SC_MOVE           : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Move this window');
      SC_RESTORE        : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Restore this window to its previous size');
      SC_SIZE           : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Resize this window');
      SC_TASKLIST       : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Activate the Windows Task Manager application');
      SC_NEXTWINDOW     : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Move to the next window');
      3850              : PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Display a list of more available windows');
    ELSE
      IF ((Msg.WParam >= 3841) AND (Msg.WParam <= 3849)) THEN
        PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Bring this window to the front')
      ELSE
        PMainWindow(Parent)^.StatbarHan^.SetText(0, '');
    END;
  END;
END;


PROCEDURE TDisplay.WMMDIActivate(VAR Msg: TMessage);
BEGIN
  (* We have been activated so set menus appropriately *)
  ParseData;

  (* Call ancestor method *)
  DefMDIChildProc(HWindow, Msg.Message, Msg.WParam, Msg.LParam);

  (* Update the menus *)
  IF (BOOLEAN(Msg.WParam) = TRUE) THEN
    PostMessage(PMainWindow(Parent)^.HWindow, WM_MENUCHANGE, 0,
                MAKELONG(PMainWindow(Parent)^.NorMenu, PMainWindow(Parent)^.NorMenuWindow))
  ELSE
    PostMessage(PMainWindow(Parent)^.HWindow, WM_MENUCHANGE, 0,
                MAKELONG(PMainWindow(Parent)^.DefMenu, PMainWindow(Parent)^.DefMenuWindow));
END;


PROCEDURE TDisplay.WMLButtonDown(VAR Msg: TMessage);
VAR
  MouseX, MouseY: INTEGER;
  XAct, YAct, A: INTEGER;
BEGIN
  (* Get current position of mouse *)
  MouseX := LOWORD(Msg.LParam);
  MouseY := HIWORD(Msg.LParam);
  ValidMouseDown := FALSE;

  (* Check to see if we should rotate the axes *)
  IF ((DisplayRotate = DR_NINE) OR (DisplayRotate = DR_TWOS)) THEN
  BEGIN
    YAct := XAcross;
    XAct := YAcross;
  END
  ELSE
  BEGIN
    YAct := YAcross;
    XAct := XAcross;
  END;  

  (* Now correct values for scroll bars *)
  MouseX := MouseX + 14*Scroller^.XPos;
  MouseY := MouseY + 14*Scroller^.YPos;

  (* Check to see if an XAxis label has been selected *)
  FOR A := 1 TO XAct DO
  BEGIN
    IF ((MouseX >= (23+14*A)) AND (MouseX <= (23+14*(A+1))) AND
        (MouseY >= (20+14*YAct)) AND (MouseY <= (34+14*YAct))) THEN
    BEGIN
      ValidMouseDown := TRUE;
      XAxisSelected := TRUE;
      NumberSelected := A;
    END;
  END;

  (* Check to see if an YAxis label has been selected *)
  FOR A := 1 TO YAct DO
  BEGIN
    IF ((MouseX >= 11) AND (MouseX <= 25) AND
        (MouseY >= (14*A)) AND (MouseY <= (14*(A+1)))) THEN
    BEGIN
      ValidMouseDown := TRUE;
      XAxisSelected := FALSE;
      NumberSelected := A;
    END;
  END;

  (* Call ancestor method *)
  TWindow.WMLButtonDown(Msg);
END;


PROCEDURE TDisplay.WMLButtonUp(VAR Msg: TMessage);
VAR
  MouseX, MouseY: INTEGER;
  XAct, YAct: INTEGER;
BEGIN
  (* Check to see if the mouse is still over the same position *)
  IF (ValidMouseDown) THEN
  BEGIN
    (* Get current mouse position *)
    MouseX := LOWORD(Msg.LParam);
    MouseY := HIWORD(Msg.LParam);

    (* Check to see if we should rotate the axes *)
    IF ((DisplayRotate = DR_NINE) OR (DisplayRotate = DR_TWOS)) THEN
    BEGIN
      YAct := XAcross;
      XAct := YAcross;
    END
    ELSE
    BEGIN
      YAct := YAcross;
      XAct := XAcross;
    END;  

    (* Now correct values for scroll bars *)
    MouseX := MouseX + 14*Scroller^.XPos;
    MouseY := MouseY + 14*Scroller^.YPos;

    (* Compare the saved position with this *)
    IF (XAxisSelected) THEN
    BEGIN      
      IF ((MouseX >= (23+14*NumberSelected)) AND (MouseX <= (23+14*(NumberSelected+1))) AND
          (MouseY >= (20+14*YAct)) AND (MouseY <= (34+14*YAct))) THEN
      BEGIN
        PostMessage(HWindow, WM_COMMAND, ID_EDITDATA, 0);
      END;
    END
    ELSE
    BEGIN
      IF ((MouseX >= 11) AND (MouseX <= 25) AND
          (MouseY >= (14*NumberSelected)) AND (MouseY <= (14*(NumberSelected+1)))) THEN
      BEGIN
        PostMessage(HWindow, WM_COMMAND, ID_EDITDATA, 0);
      END;
    END;

  END;
END;


PROCEDURE TDisplay.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
VAR
  XAct, YAct, XMax, YMax, I, J: INTEGER;
  HOldPen: HPEN;
  HOldBrush: HBRUSH;
BEGIN
  (* Call ancestor method *)
  TWindow.Paint(PaintDC, PaintInfo);

  (* Draw the grid axes *)
  DrawAxes(PaintDC);

  (* Draw in Nonogram grid data - don't use the slow Drawpoint routine *)
  HOldPen := SelectObject(PaintDC, PMainWindow(Parent)^.LtGrayPen);
  HOldBrush := SelectObject(PaintDC, GetStockObject(LTGRAY_BRUSH));

  IF (Sum1 = 0) THEN
  BEGIN
    (* Firstly draw a large light gray rectangle *)
    CASE (DisplayRotate) OF
      DR_ZERO: BEGIN  XAct := XAcross; YAct := YAcross;  END;
      DR_NINE: BEGIN  YAct := XAcross; XAct := YAcross;  END;
      DR_ONEE: BEGIN  XAct := XAcross; YAct := YAcross;  END;
      DR_TWOS: BEGIN  YAct := XAcross; XAct := YAcross;  END;
    END;

    XMax := 36+14*XAct;
    YMax := 14+14*YAct;

    Rectangle(PaintDC, 35, 13, XMax, YMax);

    (* Now draw the 3D dividing lines *)  
    SelectObject(PaintDC, GetStockObject(WHITE_PEN));
    FOR I := 1 TO XAct DO
    BEGIN
      MoveTo(PaintDC, (36+14*(I-1)), 14);
      LineTo(PaintDC, (36+14*(I-1)), YMax);
    END;

    FOR I := 1 TO YAct DO
    BEGIN
      MoveTo(PaintDC, 36, (14+14*(I-1)));
      LineTo(PaintDC, XMax, (14+14*(I-1)));
    END;

    SelectObject(PaintDC, PMainWindow(Parent)^.DkGrayPen);
    FOR I := 1 TO XAct DO
    BEGIN
      MoveTo(PaintDC, (35+14*I), 14);
      LineTo(PaintDC, (35+14*I), YMax);
    END;

    FOR I := 1 TO YAct DO
    BEGIN
      MoveTo(PaintDC, 36, (13+14*I));
      LineTo(PaintDC, XMax, (13+14*I));
    END;
  END
  ELSE
  BEGIN
    (* Draw the 3D grid first this time *)
    CASE (DisplayRotate) OF
      DR_ZERO: BEGIN  XAct := XAcross; YAct := YAcross;  END;
      DR_NINE: BEGIN  YAct := XAcross; XAct := YAcross;  END;
      DR_ONEE: BEGIN  XAct := XAcross; YAct := YAcross;  END;
      DR_TWOS: BEGIN  YAct := XAcross; XAct := YAcross;  END;
    END;

    XMax := 36+14*XAct;
    YMax := 14+14*YAct;

    Rectangle(PaintDC, 35, 13, XMax, YMax);

    SelectObject(PaintDC, GetStockObject(WHITE_PEN));
    FOR I := 1 TO XAct DO
    BEGIN
      MoveTo(PaintDC, (36+14*(I-1)), 14);
      LineTo(PaintDC, (36+14*(I-1)), YMax);
    END;

    FOR I := 1 TO YAct DO
    BEGIN
      MoveTo(PaintDC, 36, (14+14*(I-1)));
      LineTo(PaintDC, XMax, (14+14*(I-1)));
    END;

    SelectObject(PaintDC, PMainWindow(Parent)^.DkGrayPen);
    FOR I := 1 TO XAct DO
    BEGIN
      MoveTo(PaintDC, (35+14*I), 14);
      LineTo(PaintDC, (35+14*I), YMax);
    END;

    FOR I := 1 TO YAct DO
    BEGIN
      MoveTo(PaintDC, 36, (13+14*I));
      LineTo(PaintDC, XMax, (13+14*I));
    END;

    FOR I := 1 TO XAcross DO
    BEGIN
      FOR J := 1 TO YAcross DO
      BEGIN
        DrawPoint(PaintDC, I, J, ScreenGrid[I, J], TRUE);
      END;
    END;
  END;

  (* Reselect old objects *)
  SelectObject(PaintDC, HOldPen);
  SelectObject(PaintDC, HOldBrush);
END;


PROCEDURE TDisplay.DrawPoint(TheDC: HDC; XPos, YPos, BlockDot: INTEGER; Allways: BOOLEAN);
VAR
  MadeDC: BOOLEAN;
  XPhys, YPhys, XAct, YAct, Temp: INTEGER;
  TempVal: TPaintStruct;
BEGIN
  (* Check to see that this point should be drawn *)
  IF ((XPos > 0) AND (YPos > 0) AND (YPos <= YAcross) AND (XPos <= XAcross)) THEN
  BEGIN
    IF ((ScreenGrid[XPos, YPos] = 0) OR ((ScreenGrid[XPos, YPos] > 0) AND Allways)) THEN
    BEGIN
      (* Check to see that we are given a DC *)
      IF (TheDC = 0) THEN
      BEGIN
        TheDC := GetDC(HWindow);
        MadeDC := TRUE;
      END
      ELSE
        MadeDC := FALSE;

      Scroller^.BeginView(TheDC, TempVal);

      (* Calculate the actual physical device position from OUR logical coordinates *)
      IF (DisplayFlip) THEN
        XPhys := XAcross+1-XPos
      ELSE
        XPhys := XPos;
      YPhys := YPos;

      (* Display rotations *)
      CASE (DisplayRotate) OF
        DR_ZERO: BEGIN  XPhys := XPhys; YPhys := YPhys;  END;
        DR_NINE: BEGIN  Temp := XPhys; XPhys := YPhys; YPhys := XAcross+1-Temp;  END;
        DR_ONEE: BEGIN  XPhys := XAcross+1-XPhys; YPhys := YAcross+1-YPhys;  END;
        DR_TWOS: BEGIN  Temp := XPhys; XPhys := YAcross+1-YPhys; YPhys := Temp;  END;
      END;

      (* Calculate block postions *)
      XAct := 23 + 14 * XPhys;
      YAct := 1 + 14 * YPhys;

      (* Draw actual blocks on the screen *)
      CASE BlockDot OF
        0 :
        BEGIN
          (* Draw an empty square block *)
          SelectObject(TheDC, GetStockObject(LTGRAY_BRUSH));
          SelectObject(TheDC, PMainWindow(Parent)^.LtGrayPen);
          Rectangle(TheDC, XAct, YAct, (XAct + 12), (YAct + 12));
        END;

        1 :
        BEGIN
          (* Draw a filled in block *)
          IF (ScreenGrid[XPos, YPos] = 0) THEN
            INC(PlotTotal);
          SelectObject(TheDC, PMainWindow(Parent)^.LtGrayPen);
          SelectObject(TheDC, BlkBrush);
          Rectangle(TheDC, XAct, YAct, (XAct + 11), (YAct + 11));
          ScreenGrid[XPos, YPos] := 1;
        END;

        2 :
        BEGIN
          (* Draw a space style square block *)
          IF (ScreenGrid[XPos, YPos] = 0) THEN
            INC(PlotTotal);
          SelectObject(TheDC, PMainWindow(Parent)^.LtGrayPen);
          SelectObject(TheDC, DotBrush);
          Rectangle(TheDC, XAct, YAct, (XAct + 11), (YAct + 11));
          ScreenGrid[XPos, YPos] := 2;
        END;
      END;

      (* Release DC if we made one *)
      IF (MadeDC) THEN
        ReleaseDC(HWindow, TheDC);
    END;
  END;
END;


FUNCTION HookProc(HWindow: HWnd; Msg, wParam: WORD; lParam: LONGINT): WORD; FAR;
VAR
  p : TFarProc;
BEGIN
  IF (Msg=wm_InitDialog) THEN
  BEGIN
    Ctl3dSubClassDlg(HWindow, Ctl3d_All);
  END;
  HookProc:=0;
END;


PROCEDURE TDisplay.CMLoad(VAR Msg: TMessage);
VAR
  Ofn: TOpenFileName;
  TempFileName: ARRAY [0..FSPATHNAME] OF CHAR;
BEGIN
  TempFileName[0]:=#0;
  Ofn.lStructSize       := sizeof(TOpenFileName);
  Ofn.hwndOwner         := HWindow;
  Ofn.hInstance         := HInstance;
  Ofn.lpstrFilter       := 'Nonogram Files (*.NGM)'+#0+'*.NGM'+#0+'All Files (*.*)'+#0+'*.*'+#0+#0;
  Ofn.lpstrCustomFilter := NIL;
  Ofn.nMaxCustFilter    := 0;
  Ofn.nFilterIndex      := 1;
  Ofn.lpstrFile         := TempFileName;
  Ofn.nMaxFile          := sizeof(TempFileName);
  Ofn.lpstrFileTitle    := NIL;
  Ofn.nMaxFileTitle     := 0;
  Ofn.lpstrInitialDir   := NIL;
  Ofn.lpstrTitle        := 'Open';
  Ofn.Flags             := OFN_PATHMUSTEXIST OR OFN_FILEMUSTEXIST OR OFN_ENABLEHOOK OR OFN_HIDEREADONLY;
  Ofn.nFileOffset       := 0;
  Ofn.nFileExtension    := 0;
  Ofn.lpstrDefExt       := NIL;
  Ofn.lCustData         := 0;
  Ofn.lpfnHook          := HookProc;

  (* If it is a valid file name then actually load the data *)
  IF (GetOpenFileName(Ofn)) THEN
  BEGIN
    StrCopy(FileName, TempFileName);
    FileLoadImplement;
  END;

END;


PROCEDURE TDisplay.FileLoadImplement;
VAR
  File1: TEXT;
  A, I, J, Code, LineNo, LinePos: INTEGER;
  DoingX, Finished: BOOLEAN;
  TextString, TextStrtwo, TextBuf, FileWarn: ARRAY [0..150] OF CHAR;
  Msg: TMessage;
  ActiveWin: HWND;
BEGIN
  (* This procedure reads in the standard format data file - the order is

     1) Read datafile title
     2) Read datafile size (20x25 etc)
     3) Read datafile data *)

  (* Clear out the old data *)
  ResetData;

  (* Actually load the file *)
  {$I-}
  Assign(File1, Filename);
  Reset(File1);

  (* Read the data title *)
  ReadLn(File1, FilTitle);
  IF (StrComp(FilTitle, '') = 0) THEN
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'WARNING: No data title specified');
    StrCopy(FileWarn, 'File: ');
    StrCat(FileWarn, FileName);
    StrCat(FileWarn, #13+#13);
    StrCat(FileWarn, 'No title specified');
    MessageBox(HWindow,
               FileWarn,
               'Nonogram Solver',
               MB_ICONEXCLAMATION);
  END;

  (* Read in Nonogram size: XAcross by YAcross *)
  ReadLn(File1, I, J);
  IF ((I < 1) OR (I > 100) OR (J < 1) OR (J > 100)) THEN
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'ERROR: Data file is corrupt');
    StrCopy(FileWarn, 'File: ');
    StrCat(FileWarn, FileName);
    StrCat(FileWarn, #13+#13);
    StrCat(FileWarn, 'Data file is corrupt:  Invalid Nonogram size specified');
    MessageBox(HWindow,
               FileWarn,
               'Nonogram Solver',
               MB_ICONSTOP);
    StrCopy(FileName, '');
    I := IOResult;
    Close(File1);
    EXIT;
  END
  ELSE
  BEGIN
    (* Decide whether to completely clear the window when repainting *)
    IF ((XAcross <> I) OR (YAcross <> J)) THEN
    BEGIN
      XAcross := I;
      YAcross := J;
      DoScrollbars;
    END
    ELSE
    BEGIN
      XAcross := I;
      YAcross := J;
      InvalidateRect(HWindow, NIL, FALSE);
    END;
  END;

  (* Set up intial values *)
  J := 0;
  DoingX := TRUE;
  Finished := FALSE;
  LineNo := 1;
  LinePos := 1;

  (* Read in the main body of data *)
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
          Val(TextBuf, XElements[LineNo, LinePos], Code);
        END
        ELSE
        BEGIN
          Val(TextBuf, YElements[LineNo, LinePos], Code);
        END;

        (* Increment LinePos *)
        IF (LinePos+1 < MaxNoElements) THEN
          INC(LinePos)
        ELSE
        BEGIN
          IF (PMainWindow(Parent)^.StatbarExist) THEN
            PMainWindow(Parent)^.StatbarHan^.SetText(0, 'WARNING: Data file is corrupt');
          StrCopy(FileWarn, 'File: ');
          StrCat(FileWarn, FileName);
          StrCat(FileWarn, #13+#13);
          StrCat(FileWarn, 'Data file is corrupt:  Line entry truncated');
          MessageBox(HWindow,
                     FileWarn,
                     'Nonogram Solver',
                     MB_ICONEXCLAMATION);
          I := A;
        END;
      END;
    END;

    INC(LineNo);
    LinePos := 1;

    IF (DoingX) THEN
    BEGIN
      IF (LineNo > XAcross) THEN
      BEGIN
        (* Now "doingY" *)
        DoingX := FALSE;
        LineNo := 1;
      END;
    END
    ELSE
    BEGIN
      IF (LineNo > YAcross) THEN
        Finished := TRUE;
    END;
  END;

  (* Final error condition - not enough data *)
  IF (LineNo < YAcross) THEN
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'WARNING: Data file is corrupt');
    StrCopy(FileWarn, 'File: ');
    StrCat(FileWarn, FileName);
    StrCat(FileWarn, #13+#13);
    StrCat(FileWarn, 'Data file is corrupt:  Data missing');
    MessageBox(HWindow,
               FileWarn,
               'Nonogram Solver',
               MB_ICONEXCLAMATION);
  END;

  (* Parse the data *)
  ParseData;

  (* Display message box if any errors *)
  IF ((Sum1 <> Sum2) OR (Sum1 = 0) OR (Sum2 = 0)) THEN
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'WARNING: Data failed parse test');
    StrCopy(FileWarn, 'File: ');
    StrCat(FileWarn, FileName);
    StrCat(FileWarn, #13+#13);
    StrCat(FileWarn, 'Data cannot be solved: use the Information menu option for more help');
    MessageBox(HWindow,
               FileWarn,
               'Nonogram Solver',
               MB_OK OR MB_ICONEXCLAMATION);
  END;

  (* Update status bar *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
  BEGIN
    StrCopy(TextString, 'Data title: ');
    StrCat(TextString, FilTitle);
    PStatbar(PMainWindow(Parent)^.StatbarHan)^.SetText(0, TextString);
  END;

  (* Copy the filename to the main display window field *)
  StrCopy(FileName, FileName);

  (* Update display window *)
  I := IOResult;
  Close(File1);
  {$I+}
  FileSplit(Filename, TextString, TextStrtwo, TextBuf);
  StrCat(TextStrtwo, TextBuf);
  SetWindowText(HWindow, TextStrtwo);
  IF (PMainWindow(Parent)^.LoadConfirmation) THEN
  BEGIN
    StrCopy(TextString, 'Data title:'+#13);
    StrCat(TextString, FilTitle);
    MessageBox (HWindow, TextString, 'Nonogram Solver', MB_ICONINFORMATION);
  END;
END;

               
PROCEDURE TDisplay.CMSave(VAR Msg: TMessage);
VAR
  TextString: ARRAY [0..100] OF CHAR;
  File1: TEXT;
  I: INTEGER;
BEGIN
  (* Check to see that we have a filename *)
  IF (StrComp(FileName, '') = 0) THEN
  BEGIN
    PostMessage(HWindow, WM_COMMAND, CM_SAVEAS, 0);
  END
  ELSE
  BEGIN 
    (* Save the data to the specified file *)
    Assign(File1, Filename);
    ReWrite(File1);

    (* Read the data title *)
    WriteLn(File1, FilTitle);

    (* Write out Nonogram size: XAcross by YAcross *)
    WriteLn(File1, XAcross, ' ', YAcross);

    (* Write out XAxis data *)
    FOR I := 1 TO XAcross DO
    BEGIN
      MakeText(I, TRUE, TextString);
      WriteLn(File1, TextString);
    END;

    (* Write out YAxis data *)
    FOR I := 1 TO YAcross DO
    BEGIN
      MakeText(I, FALSE, TextString);
      WriteLn(File1, TextString);
    END;

    (* Close the file *)
    Close(File1);
  END;
END;


PROCEDURE TDisplay.CMSaveAs(VAR Msg: TMessage);
VAR
  Ofn: TOpenFileName;
  TempFileName, TextString, TextStrtwo, TextBuf: ARRAY [0..FSPATHNAME] OF CHAR;
BEGIN
  (* Get a filename to save the data with *)
  TempFileName[0]:=#0;
  Ofn.lStructSize       := sizeof(TOpenFileName);
  Ofn.hwndOwner         := HWindow;
  Ofn.hInstance         := HInstance;
  Ofn.lpstrFilter       := 'Nonogram Files (*.NGM)'+#0+'*.NGM'+#0+'All Files (*.*)'+#0+'*.*'+#0+#0;
  Ofn.lpstrCustomFilter := NIL;
  Ofn.nMaxCustFilter    := 0;
  Ofn.nFilterIndex      := 1;
  Ofn.lpstrFile         := TempFileName;
  Ofn.nMaxFile          := sizeof(TempFileName);
  Ofn.lpstrFileTitle    := NIL;
  Ofn.nMaxFileTitle     := 0;
  Ofn.lpstrInitialDir   := NIL;
  Ofn.lpstrTitle        := 'Save As';
  Ofn.Flags             := OFN_ENABLEHOOK OR OFN_HIDEREADONLY OR OFN_PATHMUSTEXIST OR OFN_OVERWRITEPROMPT;
  Ofn.nFileOffset       := 0;
  Ofn.nFileExtension    := 0;
  Ofn.lpstrDefExt       := NIL;
  Ofn.lCustData         := 0;
  Ofn.lpfnHook          := HookProc;

  (* If it is a valid file name then actually save the data *)
  IF (GetSaveFileName(Ofn)) THEN
  BEGIN
    StrCopy(FileName, TempFileName);

    (* Set window text to new filename *)
    FileSplit(Filename, TextString, TextStrtwo, TextBuf);
    StrCat(TextStrtwo, TextBuf);
    SetWindowText(HWindow, TextStrtwo);

    (* Call main solving routine *)
    CMSave(Msg);
  END;
END;


PROCEDURE TDisplay.CMPrint(VAR Msg: TMessage);
VAR
  hPr: HDC;
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  TextStrPtr: PChar;

  FontRecord: TLOGFONT;
  HFontRecord: HFONT;
  XRes, YRes, TextSp, BlkPoint, Temp: INTEGER;
  LeftMargin, TopMargin, I, J, X, Y: INTEGER;
  Year, Month, Day, DOW, Hour, Min, Sec, Hund: WORD;
  TimeRecord: TDateTime;
  TimeInt: LONGINT;
BEGIN
  (* Handle Nonogram printing *)
  hPr := GetPrinterDC;

  (* OK - we didn't get a valid DC so we'd better just give up *)
  IF (hPr = 0) THEN EXIT;

  (* Start print job off *)
  StrCopy(TextString, 'Nonogram - ');
  IF (StrComp(FileName, '') <> 0) THEN
    StrCat(TextString, FileName)
  ELSE
    StrCat(TextString, 'Untitled');
  TextStrPtr := @TextString;
  Escape(hPr, STARTDOC, (StrLen(TextString)+1), TextStrPtr, nil);

  (* Get display resolution *)
  XRes := GetDeviceCaps(hPr, HORZRES);
  YRes := GetDeviceCaps(hPr, VERTRES);
  TextSp := YRes DIV 64;

  SetMapMode(hPr, MM_TEXT);

  (* If status bar exists then update it *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
    PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Printing...');

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

  StrCopy(TextString, 'Nonogram Solver - Version 2.4');
  TextOut(hPr, 10, (TextSp), TextString, StrLen(TextString));

  (* Modify the font *)
  SelectObject(hPr, PMainWindow(Parent)^.HAxesVFont);
  DeleteObject(HFontRecord);
  FontRecord.lfHeight := XRes DIV 48;
  FontRecord.lfUnderline := 0;
  FontRecord.lfWeight := FW_NORMAL;
  HFontRecord := CreateFontIndirect(FontRecord);
  SelectObject(hPr, HFontRecord);

  (* Output the Nonogram data *)
  StrCopy(TextString, 'File name: ');
  StrCat(TextString, FileName);
  TextOut(hPr, 30, 4*TextSp, TextString, StrLen(TextString));
  StrCopy(TextString, 'File title: ');
  StrCat(TextString, FilTitle);
  TextOut(hPr, 30, 5*TextSp, TextString, StrLen(TextString));
  StrCopy(TextString, 'Solution time: ');
  IF (SolveTime = 0) THEN
  BEGIN
    StrCat(TextString, 'Not solved ');
  END
  ELSE
  BEGIN
    Str(SolveTime, TextStrtwo);
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

  (* Convert time and date to a time record *)
  TimeRecord.Year := Year;
  TimeRecord.Month := Month;                              
  TimeRecord.Day := Day;
  TimeRecord.Hour := Hour;
  TimeRecord.Min := Min;
  TimeRecord.Sec := Sec;
  PackTime(TimeRecord, TimeInt);

  (* Convert the date *)
  ConvertDate(TimeInt, TextStrtwo);
  StrCat(TextString, ',  ');
  StrCat(TextString, TextStrtwo);

  TextOut(hPr, 30, 7*TextSp, TextString, StrLen(TextString));

  (* Now draw the actual datafile *)
  BlkPoint := ((9*XRes) DIV 10) DIV XAcross;
  Temp := ((8*YRes) DIV 10) DIV YAcross;
  IF (Temp < BlkPoint) THEN BlkPoint := Temp;
  LeftMargin := (XRes - BlkPoint*XAcross) DIV 2;
  TopMargin := (3*(YRes - BlkPoint*YAcross)) DIV 4;

  FOR I := 1 TO YAcross DO
  BEGIN
    FOR J := 1 TO XAcross DO
    BEGIN
      IF (ScreenGrid[J, I] = 1) THEN
      BEGIN
        (* Select filled brush and draw point *)
        SelectObject(hPr, BlkBrush);
        X := LeftMargin+(J-1)*BlkPoint;
        Y := TopMargin+(I-1)*BlkPoint;
        Rectangle(hPr, X , Y, (X+BlkPoint), (Y+BlkPoint));
      END
      ELSE
      BEGIN
        SelectObject(hPr, DotBrush);
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
  IF (PMainWindow(Parent)^.StatbarExist) THEN
    PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Printing complete');

  (* Delete the DC *)
  DeleteDC (hPr);
END;


FUNCTION TDisplay.GetPrinterDC: HDC;
VAR
  lpDevMode: ^TDEVMODE;
  lpDevNames: ^TDEVNAMES;
  lpszDriverName: PChar;
  lpszDeviceName: PChar;
  lpszPortName: PChar;
  Locked: BOOLEAN;
BEGIN

  IF NOT(PrintDlg(PMainWindow(Parent)^.PrintStruct)) THEN
  BEGIN
    GetPrinterDC := 0;
    EXIT;
  END;

  IF (PMainWindow(Parent)^.PrintStruct.hDC <> 0) THEN
  BEGIN
    (* Use the already created DC *)
    GetPrinterDC := PMainWindow(Parent)^.PrintStruct.hDC;
    EXIT;
  END
  ELSE
  BEGIN
    (* Check to see that *)
    IF (PMainWindow(Parent)^.PrintStruct.hDC <> 0) THEN
    BEGIN
      GetPrinterDC := 0;
      EXIT;
    END
    ELSE
    BEGIN
      (* Apply global lock and get driver/device/port names *)
      lpDevNames := GlobalLock(PMainWindow(Parent)^.PrintStruct.hDevNames);
      lpszDriverName := PChar(lpDevNames) + lpDevNames^.wDriverOffset;
      lpszDeviceName := PChar(lpDevNames) + lpDevNames^.wDeviceOffset;
      lpszPortName := PChar(lpDevNames) + lpDevNames^.wOutputOffset;
      GlobalUnlock(PMainWindow(Parent)^.PrintStruct.hDevNames);

      IF (PMainWindow(Parent)^.PrintStruct.hDevMode <> 0) THEN
      BEGIN
        lpDevMode := GlobalLock(PMainWindow(Parent)^.PrintStruct.hDevNames);
        Locked := TRUE;
      END
      ELSE
        Locked := FALSE;

      (* Now with DevMode locked try to create a DC *)
      GetPrinterDC := CreateDC(lpszDriverName, lpszDeviceName, lpszPortName, PChar(lpDevMode));

      IF (Locked) THEN
        GlobalUnlock(PMainWindow(Parent)^.PrintStruct.hDevNames);
    END;
  END;

  IF (GetPrinterDC = 0) THEN
    MessageBox(HWindow, 'Cannot print!', 'Nonogram Solver', MB_ICONEXCLAMATION);
END;

                                                          
PROCEDURE TDisplay.CMConfDispl(VAR Msg: TMessage);
BEGIN
  (* Bring up the display dialog box *)
  IF (Application^.ExecDialog(New(PDisplayOptions, Init(@self, 'DisplayBox'))) = ID_OK) THEN
    DoScrollbars;
END;


PROCEDURE TDisplay.CMHeadData(VAR Msg: TMessage);
VAR
  OldXAcross, OldYAcross: INTEGER;
BEGIN
  (* Store the current values of XAcross and YAcross *)
  OldXAcross := XAcross;
  OldYAcross := YAcross;

  (* Bring up the header data dialog box *)
  Application^.ExecDialog(New(PHeadBox, Init(@self, 'HeadData')));

  (* Decide if we need to redraw the screen *)
  IF ((XAcross <> OldXAcross) OR (YAcross <> OldYAcross)) THEN
    DoScrollbars;

END;


PROCEDURE TDisplay.CMSolve(VAR Msg: TMessage);
VAR
  I, J, OldTotal: INTEGER;
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  TextStrthr, TextStrfou: ARRAY [0..10] OF CHAR;
  Strt, Fin: LONGINT;
  MainMenu: HMenu;
  TheDC: HDC;
  HOldCursor: HCURSOR;
BEGIN
  (* Parse the data *)
  ParseData;

  (* Check that the data is OK - ie no errors *)
  IF ((Sum1 <> Sum2) OR (Sum1 = 0) OR (Sum2 = 0)) THEN
  BEGIN
    IF (PMainWindow(Parent)^.StatbarExist) THEN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'WARNING: Data failed parse test');
      MessageBox(HWindow, 'Data cannot be solved!'+#13+#13+
                          'Use the Information menu'+#13+
                          'option for more help',
                          'Nonogram Solver', MB_OK OR MB_ICONEXCLAMATION);
    EXIT;
  END;

  (* Solving has now started *)
  PMainWindow(Parent)^.SolveInProgress := TRUE;
  SolveInProgress := TRUE;

  (* Clear the current screen data *)
  FOR I := 1 TO MaxXAcross DO
  BEGIN
    FOR J := 1 TO MaxYAcross DO
      ScreenGrid[I, J] := 0;
  END;

  (* Clear the current puzzle data *)
  FOR I := 1 TO XAcross DO
    XFilled[I] := 0;

  FOR I := 1 TO YAcross DO
    YFilled[I] := 0;

  (* Redraw the screen *)
  FOR I := 1 TO XAcross DO
    FOR J := 1 TO YAcross DO
      DrawPoint(0, I, J, 0, TRUE); 

  SolveTime := 0;
  Strt := GetTickCount;
  OldTotal := -1;
  PlotTotal := 0;

  (* Set the menu appropriately *)
  StrCopy(TextString, '&Stop solving');
  MainMenu := GetMenu(PMainWindow(Parent)^.HWindow);
  ModifyMenu(MainMenu, CM_SOLVE, MF_BYCOMMAND, CM_STOPSO, TextString);
  DrawMenuBar(PMainWindow(Parent)^.HWindow);

  (* Set status bar up *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
  BEGIN
    PMainWindow(Parent)^.StatbarHan^.SetTime(0, '0.000', '0');
    PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Solving...');
  END;

  (* Disable the solve toolbar icon *)
  PMainWindow(Parent)^.ToolbarHan^.ShowButton(5, SW_HIDE);
  PMainWindow(Parent)^.ToolbarHan^.ShowButton(13, SW_SHOW);

  (* Set the window title appropriately *)
  GetWindowText(HWindow, TextString, 70);
  StrCopy(TextStrtwo, TextString);
  StrCat(TextStrtwo, ' - [solving]');
  SetWindowText(HWindow, TextStrtwo);
  Yielder;

  (* Check to see if we should use the 'QuickData' routine *)
  IF (PMainWindow(Parent)^.QuickStrtOn) THEN QuickData;

  (* This is the actual crunching solve routine *)
  PMainWindow(Parent)^.CanThink := TRUE;
  WHILE ((OldTotal <> PlotTotal) AND PMainWindow(Parent)^.CanThink) DO
  BEGIN
    OldTotal := PlotTotal;
    IF (PMainWindow(Parent)^.EdgeCheckOn) THEN CheckEdge;
    IF (PMainWindow(Parent)^.FullRwTstOn) THEN TestRowFull;
    IF (PMainWindow(Parent)^.RowFollowOn) THEN FollowRow;
    IF (PMainWindow(Parent)^.SingleTstOn) THEN SingleTst;
    IF (PMainWindow(Parent)^.CombinatnOn) THEN Combination;

    (* Update time/number of points display on status bar *)
    IF (PMainWindow(Parent)^.StatbarExist) THEN
    BEGIN
      Str(PlotTotal, TextStrthr);
      Fin := GetTickCount;
      Str(((Fin-Strt)/ 1000):5:3, TextStrfou);
      PMainWindow(Parent)^.StatbarHan^.SetTime(0, TextStrfou, TextStrthr);
    END;
                 
    (* Check to see if there are any messages waiting in the
       applications message queue *)
    Yielder;
  END;

  (* Note the rounding trick *)
  Fin := GetTickCount;
  SolveTime := (Fin - Strt + 500) DIV 1000;

  (* Solving is now finished *)
  PMainWindow(Parent)^.SolveInProgress := FALSE;
  SolveInProgress := FALSE;

  (* Reset window title *)
  SetWindowText(HWindow, TextString);

  (* Reset the menu to its previous state *)
  StrCopy(TextString, '&Solve');
  MainMenu := GetMenu(PMainWindow(Parent)^.HWindow);
  ModifyMenu(MainMenu, CM_STOPSO, MF_BYCOMMAND, CM_SOLVE, TextString);
  DrawMenuBar(PMainWindow(Parent)^.HWindow);

  (* Refresh status bar *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
  BEGIN
    IF (PMainWindow(Parent)^.CanThink) THEN
    BEGIN
      IF (PlotTotal = (XAcross * YAcross)) THEN
      BEGIN
        PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Successfully solved');
      END
      ELSE
      BEGIN
        PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Cannot obtain a solution!');
      END;
    END
    ELSE
    BEGIN
      PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Solution interrupted');
    END;
  END;

  (* Re-enable the solve toolbar button *)
  PMainWindow(Parent)^.ToolbarHan^.ShowButton(13, SW_HIDE);
  PMainWindow(Parent)^.ToolbarHan^.ShowButton(5, SW_SHOW);

  (* Display a finished message - but only if needed/wanted *)
  IF (PMainWindow(Parent)^.SolveConfirmation) THEN
  BEGIN
    IF (PlotTotal = (XAcross * YAcross)) THEN
    BEGIN
      MessageBox(HWindow, 'Solve successfully finished',
                          'Nonogram Solver', MB_ICONINFORMATION);
    END
    ELSE
    BEGIN
      IF (PMainWindow(Parent)^.CanThink) THEN
      BEGIN
        MessageBox(HWindow, 'Could not find a solution!',
                            'Nonogram Solver', MB_ICONINFORMATION);
      END
      ELSE
      BEGIN
        MessageBox(HWindow, 'Solution process interupted',
                            'Nonogram Solver', MB_ICONEXCLAMATION);
      END;
    END;
  END;

  IF (PMainWindow(Parent)^.StopSolAndExit) THEN
    PostMessage(PMainWindow(Parent)^.HWindow, WM_COMMAND, CM_EXIT, 0);
  IF (CloseAfterSolve) THEN
    PostMessage(HWindow, WM_CLOSE, 0, 0);
END;


PROCEDURE TDisplay.Yielder;
BEGIN
  (* Yield control to other applications/tasks *)
  WHILE (PeekMessage(SentMessage, 0, 0, 0, PM_REMOVE)) DO
  BEGIN
    IF ((SentMessage.Message = WM_COMMAND) AND (SentMessage.wParam = CM_STOPSO)) THEN
    BEGIN
      PMainWindow(Parent)^.SolveInProgress := FALSE;
      PMainWindow(Parent)^.CanThink := FALSE;

      (* Update the status bar *)
      IF (PMainWindow(Parent)^.StatbarExist) THEN
        PMainWindow(Parent)^.Statbarhan^.SetText(0, 'Aborting...');
    END;
    TranslateMessage(SentMessage);
    DispatchMessage(SentMessage);
  END;
END;


PROCEDURE TDisplay.CMRecover(VAR Msg: TMessage);
VAR
  I:      INTEGER;
  J:      INTEGER;
  K:      INTEGER;
  Target: INTEGER;
BEGIN

  (* Copy the current X array into the work array *)
  FOR I := 1 TO MaxXAcross DO
  BEGIN
    FOR J := 1 TO MaxNoElements DO
    BEGIN
      RecoverData[I, J] := XElements[I, J];
    END;
  END;

  (* Calculate the target value *)
  Target := 0;
  FOR I := 1 TO YAcross DO
  BEGIN
    J := 1;
    WHILE (YElements[I, J] > 0) DO
    BEGIN
      Target := Target + YElements[I, J];
      J := J + 1;
    END;
  END;

  LowestPos := XAcross;
  IF (CheckGroup(1, XAcross, YAcross, Target)) THEN
  BEGIN
  END
  ELSE
  BEGIN
    MessageBox(HWindow,
               'Wib',
               'Ouch!',
               MB_OK);
  END;
END;


FUNCTION TDisplay.CheckGroup(Group: INTEGER; GroupMax: INTEGER; PosMax: INTEGER; Target: INTEGER): BOOLEAN;
VAR
  ElPos:   INTEGER;
  I, J, K: INTEGER;
  TmpCnt:  INTEGER;
  PosVal:  INTEGER;
  KeepOn:  BOOLEAN;
  TryThis: BOOLEAN;
  T1:      ARRAY [0..64] OF CHAR;
  T2:      ARRAY [0..10] OF CHAR;
  Data:    ARRAY [1..20] OF INTEGER;
  Diff:    BOOLEAN;
  Msg:     TMessage;
BEGIN
  ElPos      := 1;
  CheckGroup := FALSE;
  KeepOn     := TRUE;
  TryThis    := TRUE;

  WHILE ((KeepOn) AND (ElPos+1 <= MaxNoElements)) DO
  BEGIN
    IF (TryThis) THEN
    BEGIN
      (* Have we reached the target yet? *)
      TmpCnt := 0;
      FOR I := 1 TO XAcross DO
      BEGIN
        J := 1;
        WHILE (XElements[I, J] > 0) DO
        BEGIN
          TmpCnt := TmpCnt + XElements[I, J];
          J := J + 1;
        END;
      END;

      (* Check to determine if we have hit the target yet *)
      IF (TmpCnt = Target) THEN
      BEGIN
        IF (MessageBox(HWindow,
                       'Possible solution found. Display changes?',
                       'Nonogram Solver',
                       MB_YESNO OR MB_ICONQUESTION) = IDYES) THEN
        BEGIN
          FOR I := 1 TO XAcross DO
          BEGIN
            Diff := FALSE;
            FOR J := 1 TO MaxNoElements DO
            BEGIN
              IF (RecoverData[I, J] <> XElements[I, J]) THEN
              BEGIN
                Diff := TRUE;
                FOR K := 1 TO 10 DO
                BEGIN
                  Data[K]    := RecoverData[I, K];
                  Data[K+10] := XElements[I, K];
                END;
              END;
            END;
   
            IF (Diff) THEN
            BEGIN
              wvsprintf(@T1,
                        '%u,%u,%u,%u,%u,%u,%u,%u,%u,%u to '+
                        '%u,%u,%u,%u,%u,%u,%u,%u,%u,%u',
                        Data);
              MessageBox(HWindow, @T1, 'Nonogram Solver', MB_OK);
            END;
          END;
        END;

        IF (MessageBox(HWindow,
                       'Try to solve possible solution?',
                       'Nonogram Solver',
                       MB_YESNO OR MB_ICONQUESTION) = IDYES) THEN
        BEGIN
          CMSolve(Msg);
        END;

        IF (MessageBox(HWindow,
                       'Look for next solution?',
                       'Nonogram Solver',
                       MB_YESNO OR MB_ICONQUESTION) = IDNO) THEN
        BEGIN
          CheckGroup := TRUE;
          EXIT;
        END;
      END;

      IF (Group < GroupMax) THEN
      BEGIN
        IF (CheckGroup(Group+1, GroupMax, PosMax, Target)) THEN
        BEGIN
          CheckGroup := TRUE;
          EXIT;
        END;
      END;
    END;

    IF (RecoverData[Group, ElPos+1] = 0) THEN
    BEGIN
      I := 1;
      WHILE (RecoverData[Group, I] > 0) DO
      BEGIN
        XElements[Group, I] := RecoverData[Group, I];
        I := I + 1;
      END;
      KeepOn := FALSE;
    END
    ELSE
    BEGIN
      IF (Group < LowestPos) THEN
      BEGIN
        LowestPos := Group;
        StrCopy(T1, 'Current lowest position:');
        Str(LowestPos, T2);
        StrCat(T1, T2); 
        PMainWindow(Parent)^.StatbarHan^.SetText(0, @T1);
      END;

      PosVal := (RecoverData[Group, ElPos] * 10) + RecoverData[Group, ElPos+1];
      TryThis := FALSE;
      IF (PosVal <= PosMax) THEN
      BEGIN
        XElements[Group, ElPos] := PosVal;
        TmpCnt := PosVal + 1;

        FOR I := 1 TO (ElPos-1) DO
        BEGIN
          XElements[Group, I] := RecoverData[Group, I];
          TmpCnt := TmpCnt + XElements[Group, I] + 1;
        END;

        I := ElPos+2;
        WHILE (RecoverData[Group, I] > 0) DO
        BEGIN
          XElements[Group, I-1] := RecoverData[Group, I];
          TmpCnt := TmpCnt + XElements[Group, I-1] + 1;
          I := I + 1;
        END;
        XElements[Group, I-1] := 0;

        TmpCnt := TmpCnt - 1;

        IF (TmpCnt <= PosMax) THEN
        BEGIN
          TryThis := TRUE;
        END;
      END;
    END;

    ElPos := ElPos + 1;
  END;
END;


FUNCTION TDisplay.CheckSolution(): BOOLEAN;
BEGIN
  FOR I := 1 TO XAcross DO
  BEGIN
    
  END;

END;


PROCEDURE TDisplay.CMInfo(VAR Msg: TMessage);
VAR
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
BEGIN
  (* Check to see if status bar exists *)
  IF (PMainWindow(Parent)^.StatbarExist) THEN
    PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Getting information...');

  (* Get the required information *)
  ParseData;
  CalComplexity;

  IF (PMainWindow(Parent)^.StatbarExist) THEN
    PMainWindow(Parent)^.StatbarHan^.SetText(0, 'Getting information...done');


  Application^.ExecDialog(New(PInfoBox, Init(@self, 'InfoBox')));

  IF (PMainWindow(Parent)^.StatbarExist) THEN
    PMainWindow(Parent)^.StatbarHan^.SetText(0, '');
END;


PROCEDURE TDisplay.IDEditData(VAR Msg: TMessage);
VAR
  HEditer: PEditer;
  XAct, YAct: INTEGER;
  TheRect: TRECT;
  DoneOK: BOOLEAN;
BEGIN
  (* This procedure is called when a user clicks on an axis number in the display
     window. It brings up an edit control which can then be used to edit the currently
     selected data *)

  (* Get handle to new editer window *)
  HEditer := New(PEditer, Init(@self, 'Editer'));

  (* Check to see if we should rotate the axes and create the edit text as well *)
  IF ((DisplayRotate = DR_NINE) OR (DisplayRotate = DR_TWOS)) THEN
  BEGIN
    YAct := XAcross;
    XAct := YAcross;
  END
  ELSE
  BEGIN
    YAct := YAcross;
    XAct := XAcross;
  END;

  (* Create the editer text *)
  MakeText(NumberSelected, XAxisSelected, HEditer^.EditText);

  (* Default editer states *)
  HEditer^.CloseOnDown  := FALSE;
  HEditer^.CloseOnUp    := FALSE;

  (* Determine the position of the main window *)
  GetWindowRect(HWindow, TheRect);

  (* Determine where to position the new editer window *)
  IF (XAxisSelected) THEN
  BEGIN
    HEditer^.XPos := 17+14*NumberSelected + TheRect.left;
    HEditer^.YPos := 5+14*YAct + TheRect.top;

    IF (NumberSelected < XAct) THEN HEditer^.CloseOnDown := TRUE;
    IF (NumberSelected > 1) THEN HEditer^.CloseOnUp := TRUE;
  END
  ELSE
  BEGIN
    HEditer^.XPos := 36 + TheRect.left;
    HEditer^.YPos := 14*NumberSelected + TheRect.top + 14;

    IF (NumberSelected < YAct) THEN HEditer^.CloseOnDown := TRUE;
    IF (NumberSelected > 1) THEN HEditer^.CloseOnUp := TRUE;
  END;

  (* Now correct values for scroll bars *)
  HEditer^.XPos := HEditer^.XPos - 14*Scroller^.XPos;
  HEditer^.YPos := HEditer^.YPos - 14*Scroller^.YPos;

  (* And should we scroll the main window? *)
  DoneOK := FALSE;
  WHILE ((HEditer^.YPos + 30) > TheRect.bottom) DO
  BEGIN
    (* Scroll the window down one unit *)
    Scroller^.Scrollby(0, 1);
    HEditer^.YPos := HEditer^.YPos - 14;
    DoneOK := TRUE;
  END; 

  WHILE (((HEditer^.YPos - 20) < TheRect.top) AND (NOT(DoneOK))) DO
  BEGIN
    (* Scroll the window up one unit *)
    Scroller^.Scrollby(0, -1);
    HEditer^.YPos := HEditer^.YPos + 14;
  END;

  DoneOK := FALSE;
  WHILE ((HEditer^.XPos + 100) > TheRect.right) DO
  BEGIN
    (* Scroll the window right one unit *)
    Scroller^.Scrollby(1, 0);
    HEditer^.XPos := HEditer^.XPos - 14;
    DoneOK := TRUE;
  END;

  WHILE ((HEditer^.XPos < TheRect.left + 20) AND (NOT(DoneOK))) DO
  BEGIN
    (* Scroll the window left one unit *)
    Scroller^.Scrollby(-1, 0);
    HEditer^.XPos := HEditer^.XPos + 14;
  END;




  (* Now check to ensure that this window is not outside the main window *)
  IF (XAxisSelected) THEN
  BEGIN
    IF (HEditer^.YPos > TheRect.bottom) THEN
    BEGIN
    END;
  END;

  (* Now make the new editer window *)
  Application^.ExecDialog(HEditer);
END;


PROCEDURE TDisplay.DoScrollbars;
BEGIN
  (* This procedure updates the scdrollbars *)
  IF ((DisplayRotate = DR_ZERO) OR (DisplayRotate = DR_ONEE)) THEN
  BEGIN
    IF ((Scroller^.XRange <> XAcross+3) OR
        (Scroller^.YRange <> YAcross+3)) THEN
      Scroller^.SetRange(XAcross+3, YAcross+3);
  END
  ELSE
  BEGIN
    IF ((Scroller^.XRange <> YAcross+3) OR
        (Scroller^.YRange <> XAcross+3)) THEN
      Scroller^.SetRange(YAcross+3, XAcross+3);
  END;

  (* Resize the window - resets scroll bars *)
  InvalidateRect(HWindow, NIL, TRUE);
END;


PROCEDURE TDisplay.MakeText(NumSel: INTEGER; XAxisData: BOOLEAN; HText: PChar);
VAR
  UsingX: BOOLEAN;
  Spare: ARRAY[0..100] OF CHAR;
  I: INTEGER;
BEGIN
  (* Using the currently selected values of <NumSel> and
     <XAxisData> to create a text string of either <XElements>
     or <YElements> data *)

  IF ((DisplayRotate = DR_NINE) OR (DisplayRotate = DR_TWOS)) THEN
    IF (XAxisData) THEN  UsingX := FALSE  ELSE  UsingX := TRUE
  ELSE
    IF (XAxisData) THEN  UsingX := TRUE  ELSE  UsingX := FALSE;

  (* Default text value *)
  StrCopy(HText, '');
  StrCopy(Spare, '');

  IF (UsingX) THEN
  BEGIN
    (* Clearly we are using X... *)
    I := 1;
    WHILE (XElements[NumSel, I] > 0) DO
    BEGIN
      Str(XElements[NumSel, I], Spare);
      IF (I = 1) THEN
      BEGIN
        StrCopy(HText, Spare);
      END
      ELSE
      BEGIN
        StrCat(HText, ',');
        StrCat(HText, Spare);
      END;

      (* Increment <I> *)
      INC(I);
    END;
  END
  ELSE
  BEGIN
    (* We must be using Y instead... *)
    I := 1;
    WHILE (YElements[NumSel, I] > 0) DO
    BEGIN
      Str(YElements[NumSel, I], Spare);
      IF (I = 1) THEN
      BEGIN
        StrCopy(HText, Spare);
      END
      ELSE
      BEGIN
        StrCat(HText, ',');
        StrCat(HText, Spare);
      END;

      (* Increment <I> *)
      INC(I);
    END;
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
  IF ((DisplayRotate = DR_NINE) OR (DisplayRotate = DR_TWOS)) THEN
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

        IF (J <= YAcross) THEN
        BEGIN
          IF (ScreenGrid[I, J] = 2) THEN
          BEGIN
            (* Well the previous one was a dot *)
            PreviousDot := TRUE;
            INC(J);
            IF (J > YAcross) THEN KeepGoing := FALSE;
          END;
        END;

        IF (J <= YAcross) THEN
        BEGIN
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

        IF (J >= 1) THEN
        BEGIN
          IF (ScreenGrid[I, J] = 2) THEN
          BEGIN
            (* Well the previous one was a dot *)
            PreviousDot := TRUE;
            DEC(J);
            IF (J < 1) THEN KeepGoing := FALSE;
          END;
        END;

        IF (J >= 1) THEN
        BEGIN
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

        IF (J <= XAcross) THEN
        BEGIN
          IF (ScreenGrid[J, I] = 2) THEN
          BEGIN
            (* Well the previous one was a dot *)
            PreviousDot := TRUE;
            INC(J);
            IF (J > XAcross) THEN KeepGoing := FALSE;
          END;
        END;

        IF (J <= XAcross) THEN
        BEGIN
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

        IF (J >= 1) THEN
        BEGIN
          IF (ScreenGrid[J, I] = 2) THEN
          BEGIN
            (* Well the previous one was a dot *)
            PreviousDot := TRUE;
            DEC(J);
            IF (J < 1) THEN KeepGoing := FALSE;
          END;
        END;

        IF (J >= 1) THEN
        BEGIN
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

END;


PROCEDURE TDisplay.SingleTst;
VAR
  A, I, J, K: INTEGER;
  FirstVal, NextVal: INTEGER;
  KeepGoing: BOOLEAN;
BEGIN
  (* Check to see if all the elements in a row are the same - in the X direction*)
  FOR I := 1 TO XAcross DO
  BEGIN
    FirstVal := XElements[I, 1];

    NextVal := 2;
    KeepGoing := TRUE;
    WHILE ((KeepGoing) AND (XElements[I, NextVal] > 0) AND (FirstVal > 0)) DO
    BEGIN
      IF (FirstVal <> XElements[I, NextVal]) THEN
      BEGIN
        FirstVal := 0;
      END;
      IF (NextVal < MaxNoElements) THEN
      BEGIN
        INC(NextVal);
      END
      ELSE
      BEGIN
        KeepGoing := FALSE;
      END;
    END;

    IF (FirstVal > 0) THEN
    BEGIN
      FOR J := 1 TO (YAcross-1) DO
      BEGIN
        IF (ScreenGrid[I, J] = 1) THEN
        BEGIN
          K := J+1;
          KeepGoing := TRUE;
          WHILE ((KeepGoing) AND (ScreenGrid[I, K] = 1)) DO
          BEGIN
            (* Do nothing *)
            IF (K < YAcross) THEN
            BEGIN
              INC(K);
            END
            ELSE
            BEGIN
              KeepGoing := FALSE;
            END;
          END;
          A := K-J;

          (* We now have a block marked *)
          IF ((K-J) = FirstVal) THEN
          BEGIN
            DrawPoint(0, I, (J-1), 2, FALSE);
            DrawPoint(0, I, K, 2, FALSE);
          END;
        END;
      END;
    END;
  END;

  (* Check to see if all the elements in a row are the same - in the Y direction*)
  FOR I := 1 TO YAcross DO
  BEGIN
    FirstVal := YElements[I, 1];

    NextVal := 2;
    KeepGoing := TRUE;
    WHILE ((KeepGoing) AND (YElements[I, NextVal] > 0) AND (FirstVal > 0)) DO
    BEGIN
      IF (FirstVal <> YElements[I, NextVal]) THEN
      BEGIN
        FirstVal := 0;
      END;
      IF (NextVal < MaxNoElements) THEN
      BEGIN
        INC(NextVal);
      END
      ELSE
      BEGIN
        KeepGoing := FALSE;
      END;
    END;

    IF (FirstVal > 0) THEN
    BEGIN
      FOR J := 1 TO (XAcross-1) DO
      BEGIN
        IF (ScreenGrid[J, I] = 1) THEN
        BEGIN
          K := J+1;
          KeepGoing := TRUE;
          WHILE ((KeepGoing) AND (ScreenGrid[K, I] = 1)) DO
          BEGIN
            (* Do nothing *)
            IF (K < XAcross) THEN
            BEGIN
              INC(K);
            END
            ELSE
            BEGIN
              KeepGoing := FALSE;
            END;
          END;
          A := K-J;

          (* We now have a block marked *)
          IF ((K-J) = FirstVal) THEN
          BEGIN
            DrawPoint(0, (J-1), I, 2, FALSE);
            DrawPoint(0, K, I, 2, FALSE);
          END;
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
    Yielder;

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
        IF NOT(PMainWindow(Parent)^.GreedyModeOn) THEN Yielder;

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
    Yielder;

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
        IF NOT(PMainWindow(Parent)^.GreedyModeOn) THEN Yielder;

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

  (* Reset parse data sum totals *)
  Sum1 := 0;
  Sum2 := 0;
  CombinX := 0;
  CombinY := 0;
  ParseData;
END;


PROCEDURE TDisplay.ParseData;
VAR
  I, K: INTEGER;
  Chk:  INTEGER;
BEGIN
  (* Parse the data set for errors *)
  Sum1 := 0;
  Sum2 := 0;

  (* Calculate sum of data sets *)
  FOR I := 1 TO XAcross DO
  BEGIN
    Chk := 0;

    FOR K := 1 TO MaxNoElements DO
    BEGIN
      IF (XElements[I, K] > 0) THEN
      BEGIN
        Sum1 := Sum1 + XElements[I, K];
        Chk  := Chk  + XElements[I, K] + 1;
      END;
    END;

    Chk := Chk - 1;
    IF (Chk > YAcross) THEN
    BEGIN
      Sum1 := 0;
    END;
  END;

  FOR I := 1 TO YAcross DO
  BEGIN
    Chk := 0;

    FOR K := 1 TO MaxNoElements DO
    BEGIN
      IF (YElements[I, K] > 0) THEN
      BEGIN
        Sum2 := Sum2 + YElements[I, K];
        Chk  := Chk  + YElements[I, K] + 1;
      END;
    END;

    Chk := Chk - 1;
    IF (Chk > XAcross) THEN
    BEGIN
      Sum2 := 0;
    END;
  END;

  (* Enable/disable toolbar/menu items *)
  IF ((Sum1 > 0) OR (Sum2 > 0)) THEN
  BEGIN
    (* Enable toolbar items *)
    IF (PMainWindow(Parent)^.ToolbarExist) THEN
    BEGIN
      PMainWindow(Parent)^.ToolbarHan^.EnableButton(5, TRUE);
      PMainWindow(Parent)^.ToolbarHan^.EnableButton(6, TRUE);
    END;

    (* Enable menu options *)
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_SOLVE, MF_ENABLED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_INFO, MF_ENABLED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_STOPSO, MF_ENABLED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_RECOVER, MF_ENABLED);
  END
  ELSE
  BEGIN
    (* Disable toolbar items *)
    IF (PMainWindow(Parent)^.ToolbarExist) THEN
    BEGIN
      PMainWindow(Parent)^.ToolbarHan^.EnableButton(5, FALSE);
      PMainWindow(Parent)^.ToolbarHan^.EnableButton(6, FALSE);
    END;

    (* Disable menu options *)
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_SOLVE, MF_GRAYED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_INFO, MF_GRAYED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_STOPSO, MF_GRAYED);
    EnableMenuItem(PMainWindow(Parent)^.Attr.Menu, CM_RECOVER, MF_GRAYED);
  END;
END;


PROCEDURE TDisplay.CalComplexity;
VAR
  A: ARRAY [1..1000] OF INTEGER;
  I, II, J, K, M: INTEGER;
  BlockTot, Basenum, Numblk, Totpos, TotComb: INTEGER;
  Continue: BOOLEAN;
BEGIN
  (* This program calculates the number of possible ways that Nonogram
     data can be arranged. The routinue only uses single blocks: however this
     is all that is required to produce a general solution. To convert a row
     which has blocks with lengths greater than unity simply subtract the
     number of EXCESS blocks from the total number of positions available: ie
     if we have a row of 25 with blocks of 2,3,10 then this reduces to a row
     of 25-(2-1)-(3-1)-(10-1) = 15 with blocks of 1,1,1 in it. It is easy to
     show that the number of blocks is the same.
  
     The method used to calculate the number of blocks is quite straightforward:
     if we consider the case of 3 blocks with a total number of positions of 8
     then we have the following where 1 represents a block and 2 represents a
     space (a la the Nonogram Solver internal representation):
 
     1) 1 1 1 1 | 1 1 1 1 1 1 | 2 2 2 2 2 2 2 2 2 2
     2) 2 2 2 2 | 2 2 2 2 2 2 | 1 1 1 1 1 1 2 2 2 2
     ----------------------------------------------
     3) 1 1 1 1 | 2 2 2 2 2 2 | 2 2 2 2 2 2 1 1 1 2
     4) 2 2 2 2 | 1 1 1 2 2 2 | 1 1 1 2 2 2 2 2 2 1
     ----------------------------------------------
     5) 1 2 2 2 | 2 2 2 1 1 2 | 2 2 2 1 1 2 1 1 2 2
     6) 2 1 2 2 | 1 2 2 2 2 1 | 1 2 2 2 2 1 2 2 1 1
     7) 2 2 1 2 | 2 1 2 1 2 2 | 2 1 2 1 2 2 1 2 2 2
     8) 2 2 2 1 | 2 2 1 2 1 1 | 2 2 1 2 1 1 2 1 1 1
       |_______| |_____|___|_| |_____|___|_|___|_|_|
           4        3    2  1     3    2  1  2  1 1
           |        |_______|     |_______|  |__| |
           A            B             C       D   E

     The key to understanding what is happening is to follow the above diagram
     closely. The bottom left section, 'A', which is marked underneath with a
     '4' is the 'BASIC' block refered to in the program. It is simply the
     number of ways in which the final block can be arranged if all the
     other blocks are compressed as much as possible (ie they are only
     seperated by a single space and follow the 1 2 1 2 1 etc style of
     arrangement). Group B is then obtained by allowing the block directly above
     this to move - in effect we are adding an additional two rows. Note that
     the number of combinations obtained this way is the sum of BASIC-1+BASIC-2+
     BASIC-3 (ie 3+2+1). We can then define a vector, say 'a', to store these
     components ie a(1)=BASIC-1=3, a(2)=BASIC-2=2, a(3)=BASIC-3=1. The purpose
     of this will be seen shortly.
 
     If we now introduce a further row along the top of the grid we get
     combinations C, D and E arising. Note the grouping: it is significant for
     the number of extra combinations arising from this is now the sum of
     a(1)+a(2)+a(3)=b(1) plus the sum of a(2)+a(3)=b(2) plus a(3)=b(3). Note
     the similarity between this and the previous row addition.
 
     The next row addition will be the sum of b(1)+b(2)+b(3) plus the sum of
     b(2)+b(3) plus b(3). Hence we obtain a recurance relationship which we
     can use to calculate the total number of combinations for arbritary
     numbers of blocks in arbritary grid sizes. This results in the following
     program.
  *)

  (* Use the XAcross data firstly *)
  CombinX := 0;
  FOR II := 1 TO XAcross DO
  BEGIN
    J := 1;
    Continue := TRUE;
    BlockTot := 0;
    WHILE ((Continue) AND (XElements[II, J] > 0)) DO
    BEGIN
      BlockTot := BlockTot + XElements[II, J];
      IF (J < MaxNoElements) THEN
        INC(J)
      ELSE
        Continue := FALSE;
    END;

    Numblk := J;
    IF (Continue) THEN DEC(Numblk);
    Totpos := YAcross - BlockTot + Numblk;

    (* Set total number of combinations to zero *)
    TotComb := 0;

    (* Calculate base number and update total *)
    IF (Numblk > 0) THEN
      Basenum := Totpos-(2*(Numblk-1))
    ELSE
      Basenum := 0;
    TotComb := Basenum;

    (* Update total *)
    IF (Numblk > 1) THEN
    BEGIN
      FOR I := 1 TO (Basenum-1) DO
        A[I] := Basenum-I;

      (* Sum up the block totals *)
      FOR I := 1 TO (Basenum-1) DO
        TotComb := TotComb + A[I];

      (* This is the main loop *)
      FOR M := 2 TO (Numblk-1) DO
      BEGIN

        FOR J := 1 TO (Basenum-1) DO
        BEGIN
          FOR K := J TO (Basenum-1) DO
          BEGIN
            IF (K = J) THEN
              A[J] := A[K]
            ELSE
              A[J] := A[J]+A[K];
          END;
        END;

        (* Sum up block totals *)
        FOR I := 1 TO (Basenum-1) DO
          TotComb := TotComb+A[I];

      END;
    END;

    (* Update total number of combinations *)
    CombinX := CombinX+TotComb;
  END;

  (* Now work in the YAcross direction *)
  CombinY := 0;
  FOR II := 1 TO YAcross DO
  BEGIN
    J := 1;
    Continue := TRUE;
    BlockTot := 0;
    WHILE ((Continue) AND (YElements[II, J] > 0)) DO
    BEGIN
      BlockTot := BlockTot + YElements[II, J];
      IF (J < MaxNoElements) THEN
        INC(J)
      ELSE
        Continue := FALSE;
    END;

    Numblk := J;
    IF (Continue) THEN DEC(Numblk);
    Totpos := XAcross - BlockTot + Numblk;

    (* Set total number of combinations to zero *)
    TotComb := 0;

    (* Calculate base number and update total *)
    IF (Numblk > 0) THEN
      Basenum := Totpos-(2*(Numblk-1))
    ELSE
      Basenum := 0;
    TotComb := Basenum;

    (* Update total *)
    IF (Numblk > 1) THEN
    BEGIN
      FOR I := 1 TO (Basenum-1) DO
        A[I] := Basenum-I;

      (* Sum up the block totals *)
      FOR I := 1 TO (Basenum-1) DO
        TotComb := TotComb + A[I];

      (* This is the main loop *)
      FOR M := 2 TO (Numblk-1) DO
      BEGIN

        FOR J := 1 TO (Basenum-1) DO
        BEGIN
          FOR K := J TO (Basenum-1) DO                  
          BEGIN
            IF (K = J) THEN
              A[J] := A[K]
            ELSE
              A[J] := A[J]+A[K];                    
          END;
        END;

        (* Sum up block totals *)
        FOR I := 1 TO (Basenum-1) DO
          TotComb := TotComb+A[I];

      END;
    END;

    (* Update total number of combinations *)
    CombinY := CombinY+TotComb;
  END;

  (* Prevent values going negative *)
  IF (CombinX < 0) THEN CombinX := 0;
  IF (CombinY < 0) THEN CombinY := 0;
END;


(**********************************************************************)
(* Methods of TMainWindow from here onwards *)


CONSTRUCTOR TMainWindow.Init (ATitle: PChar);
VAR
  I: INTEGER;
BEGIN
  NorMenu := LoadMenu(HInstance, 'NORMENU');
  DefMenu := LoadMenu(HInstance, 'DEFMENU');
  NorMenuWindow := GetSubMenu(NorMenu, 2);
  DefMenuWindow := GetSubMenu(DefMenu, 0);

  (* Call ancestor method *)
  TMDIWindow.Init (ATitle, NorMenu);

  (* Initialise program *)
  Attr.W := GetPrivateProfileInt('Main Window', 'Width', 600, INIFILENAME);
  Attr.H := GetPrivateProfileInt('Main Window', 'Height', 450, INIFILENAME);
  Attr.X := GetPrivateProfileInt('Main Window', 'X position', 0, INIFILENAME);
  Attr.Y := GetPrivateProfileInt('Main Window', 'Y position', 0, INIFILENAME);
  Attr.Style := Attr.Style;

  (* Enable auto scrolling of the client window *)
  ClientWnd^.Attr.Style := ClientWnd^.Attr.Style OR WS_HSCROLL OR WS_VSCROLL;
  ChildMenuPos := 2;

  (* Reset pointers *)
  ToolbarHan := NIL;
  DisplayHan := NIL;
  StatbarHan := NIL;

  (* Initialise variables *)
  ToolbarExist := FALSE;
  StatbarExist := FALSE;
  SolveInProgress := FALSE;
  StopSolAndExit := FALSE;
  ChildClosing := TRUE;
  NoDisplays := 0;

  (* Create pens *)
  DkGrayPen := CreatePen(PS_SOLID, 1, RGB(128, 128, 128));
  LtGrayPen := CreatePen(PS_SOLID, 1, RGB(192, 192, 192));

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
  WinHelp (HWindow, HELPFILENAME, Help_Quit, 0);
  DeleteObject(DkGrayPen);
  DeleteObject(LtGrayPen);
  DeleteObject(HAxesVFont);
  DeleteObject(HAxesHFont);

  (* Delete the two loaded menus *)
  DestroyMenu(DefMenu);
  DestroyMenu(NorMenu);

  (* Call ancestor method *)
  TMDIWindow.Done;
END;


PROCEDURE TMainWindow.GetWindowClass (VAR AWndClass: TWndClass);
BEGIN
  (* Register the window class *)
  TMDIWindow.GetWindowClass (AWndClass);
  AWndClass.HIcon := LoadIcon (HInstance, 'ICON_1');
END;


PROCEDURE TMainWindow.SetupWindow;
VAR
  A, YPos, Height, Width: INTEGER;
  TextString, TextStrtwo: ARRAY [0..100] OF CHAR;
  Msg: TMessage;
  WinRect: TRECT;
BEGIN
  (* Call ancestor method *)
  TMDIWindow.SetupWindow;

  SaveOnExit := BOOLEAN(GetPrivateProfileInt('Main Window', 'Save on exit', 0, INIFILENAME));
  SolveConfirmation := BOOLEAN(GetPrivateProfileInt('Main Window', 'Solve Confirmation',
                                                    0, INIFILENAME));
  LoadConfirmation := BOOLEAN(GetPrivateProfileInt('Main Window', 'Load Confirmation',
                                                    0, INIFILENAME));

  (* Solution options *)
  QuickStrtOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Quick start on',
                                              1, INIFILENAME));
  EdgeCheckOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Edge checking on',
                                              1, INIFILENAME));
  FullRwTstOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Full row testing on',
                                              1, INIFILENAME));
  RowFollowOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Row following on',
                                              1, INIFILENAME));
  SingleTstOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Single testing on',
                                              1, INIFILENAME));
  CombinatnOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Combination on',
                                              1, INIFILENAME));
  GreedyModeOn := BOOLEAN(GetPrivateProfileInt('Solution Options', 'Greedy mode on',
                                               0, INIFILENAME));
  VARSSize := GetPrivateProfileInt('Solution Options', 'VARS size', 300, INIFILENAME);

  (* Old file names *)
  FOR A := 1 TO 4 DO
  BEGIN
    StrCopy(TextString, 'Old file ');
    Str(A, TextStrtwo);
    StrCat(TextString, TextStrtwo);
    GetPrivateProfileString('Main Window', TextString, '', OldFiles[A], 100, INIFILENAME);
    IF (StrComp(OldFiles[A], '') <> 0) THEN
    BEGIN
      IF (A = 1) THEN  AppendMenu(GetSubMenu(GetMenu(HWindow), 0), MF_SEPARATOR, 0, NIL);
      IF (A = 1) THEN  AppendMenu(GetSubMenu(GetMenu(HWindow), 0), MF_STRING, CM_FILE1, OldFiles[1]);
      IF (A = 2) THEN  AppendMenu(GetSubMenu(GetMenu(HWindow), 0), MF_STRING, CM_FILE2, OldFiles[2]);
      IF (A = 3) THEN  AppendMenu(GetSubMenu(GetMenu(HWindow), 0), MF_STRING, CM_FILE3, OldFiles[3]);
      IF (A = 4) THEN  AppendMenu(GetSubMenu(GetMenu(HWindow), 0), MF_STRING, CM_FILE4, OldFiles[4]);
      IF (A = 1) THEN  AppendMenu(GetSubMenu(DefMenu, 0), MF_SEPARATOR, 0, NIL);
      IF (A = 1) THEN  AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE1, OldFiles[1]);
      IF (A = 2) THEN  AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE2, OldFiles[2]);
      IF (A = 3) THEN  AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE3, OldFiles[3]);
      IF (A = 4) THEN  AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE4, OldFiles[4]);
    END;
  END;

  (* Display options *)
  DisplayRotate := DisplayRotation(GetPrivateProfileInt('Display Options', 'Display rotation',
                                                        0, INIFILENAME));
  DisplayFlip := BOOLEAN(GetPrivateProfileInt('Display Options', 'Display flip',
                                              0, INIFILENAME));

  (* Get brush colours *)
  GetPrivateProfileString('Display Options', 'Block colour', '$FFFFFF',
                          TextString, 100, INIFILENAME);
  Val(TextString, BlkColour, A); 
  GetPrivateProfileString('Display Options', 'Dot colour', '$808080',
                          TextString, 100, INIFILENAME);
  Val(TextString, DotColour, A);

  (* Register the fact that we accept drag and dropped files *)
  DragAcceptFiles(HWindow, TRUE);

  (* Get client window size *)
  GetClientRect(HWindow, WinRect);

  (* Now create new windows - first of all the tool bar *)
  IF (BOOLEAN(GetPrivateProfileInt('Main Window', 'Tool bar exist', 1, INIFILENAME))) THEN
  BEGIN
    HandleToolbar(TRUE);
  END
  ELSE
    ToolbarExist := FALSE;

  (* Create status bar *)
  IF (BOOLEAN(GetPrivateProfileInt('Main Window', 'Status bar exist', 1, INIFILENAME))) THEN
  BEGIN
    HandleStatbar(TRUE);
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

  NoDisplayWin(TRUE);
  DisplayHan := New(PDisplay, Init(@self, 'Untitled'));
  IF (Application^.MakeWindow(DisplayHan) <> NIL) THEN
  BEGIN
    ShowWindow(DisplayHan^.HWindow, SW_SHOWMAXIMIZED);
  END
  ELSE
  BEGIN
    NoDisplayWin(FALSE);
    StrCopy(TextString, 'Serious error:'+#13+#13);
    StrCat(TextString, 'Cannot create another'+#13);
    StrCat(TextString, 'window');
    MessageBox(HWindow, TextString, 'Nonogram Solver',
               MB_ICONHAND OR MB_OK);
  END;

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

  (* Manipulate menu's appropriately *)
  EnableMenuItem(Attr.Menu, CM_SOLVE, MF_GRAYED);
  EnableMenuItem(Attr.Menu, CM_INFO, MF_GRAYED);
  EnableMenuItem(Attr.Menu, CM_STOPSO, MF_GRAYED);
  EnableMenuItem(Attr.Menu, CM_RECOVER, MF_GRAYED);

  IF (ToolbarExist) THEN
  BEGIN
    (* Disable toolbar buttons *)
    ToolbarHan^.EnableButton(5, FALSE);
    ToolbarHan^.EnableButton(6, FALSE);
  END;
END;


PROCEDURE TMainWindow.WMSize(VAR Msg: TMessage);
VAR
  Height, Top: INTEGER;
BEGIN
  (* Call ancestor method *)
  TMDIWindow.WMSize(Msg);

  (* Handle window resizing *)
  HandleSizing(LOWORD(Msg.LParam), HIWORD(Msg.LParam));
END;

                                                    
PROCEDURE TMainWindow.WMMenuSelect(VAR Msg: TMessage);
VAR
  hMenu1, hMenu2, hMenu3, hMenu4: HMENU;
BEGIN
  (* Handle menu selections by describing menu item's function in the status bar
     - if it exists *)

  (* Test to see if there is a fifth menu position - this indicates that a child is maximised *)
  IF (GetSubMenu(GetMenu(HWindow), 4) = 0) THEN
  BEGIN
    hMenu1 := GetSubMenu(GetMenu(HWindow), 0);
    hMenu2 := GetSubMenu(GetMenu(HWindow), 1);
    hMenu3 := GetSubMenu(GetMenu(HWindow), 2);
    hMenu4 := GetSubMenu(GetMenu(HWindow), 3);
  END;

  IF (GetSubMenu(GetMenu(HWindow), 4) <> 0) THEN
  BEGIN
    hMenu1 := GetSubMenu(GetMenu(HWindow), 1);
    hMenu2 := GetSubMenu(GetMenu(HWindow), 2);
    hMenu3 := GetSubMenu(GetMenu(HWindow), 3);
    hMenu4 := GetSubMenu(GetMenu(HWindow), 4);
  END;

  IF (GetSubMenu(GetMenu(HWindow), 2) = 0) THEN
  BEGIN
    hMenu1 := GetSubMenu(GetMenu(HWindow), 0);
    hMenu2 := 0;
    hMenu3 := 0;
    hMenu4 := GetSubMenu(GetMenu(HWindow), 1);
  END;

  IF (StatbarExist) THEN
  BEGIN
    CASE (Msg.WParam) OF
      CM_NEW            : StatbarHan^.SetText(0, 'Open a new Nonogram window');
      CM_LOAD           : StatbarHan^.SetText(0, 'Open a Nonogram data file');
      CM_PRINT          : StatbarHan^.SetText(0, 'Print a Nonogram');
      CM_SETUP          : StatbarHan^.SetText(0, 'Setup the printer');
      CM_SAVE           : StatbarHan^.SetText(0, 'Save current Nonogram data file');
      CM_SAVEAS         : StatbarHan^.SetText(0, 'Save current Nonogram data with a specified name');
      CM_FILEEXIT       : StatbarHan^.SetText(0, 'Exit from the Nonogram Solver');
      CM_FILE1          : StatbarHan^.SetText(0, 'Reopen this closed file');
      CM_FILE2          : StatbarHan^.SetText(0, 'Reopen this closed file');
      CM_FILE3          : StatbarHan^.SetText(0, 'Reopen this closed file');
      CM_FILE4          : StatbarHan^.SetText(0, 'Reopen this closed file');
      CM_SOLVE          : StatbarHan^.SetText(0, 'Solve currently selected Nonogram data');
      CM_RECOVER        : StatbarHan^.SetText(0, 'Attempt to recover from bad Nonogram data');
      CM_INFO           : StatbarHan^.SetText(0, 'Get information on currently selected Nonogram data');
      CM_HEADDATA       : StatbarHan^.SetText(0, 'Edit Nonogram header information');
      CM_CONFDISPL      : StatbarHan^.SetText(0, 'Configure Nonogram display');
      CM_CONFSOLUT      : StatbarHan^.SetText(0, 'Configure Nonogram solution');
      CM_PREFER         : StatbarHan^.SetText(0, 'Configure Nonogram preferences');
      CM_STOPSO         : StatbarHan^.SetText(0, 'Interrupt current Nonogram solve');
      CM_CONTENTS       : StatbarHan^.SetText(0, 'Help for the Nonogram Solver');
      CM_HELPONHLP      : StatbarHan^.SetText(0, 'Help on using Windows Help');
      CM_HELPABOUT      : StatbarHan^.SetText(0, 'About the Nonogram Solver');
      CM_ARRANGEICONS   : StatbarHan^.SetText(0, 'Arrange Nonogram data window icons');
      CM_TILECHILDREN   : StatbarHan^.SetText(0, 'Display windows with no overlapping');
      CM_CASCADECHILDREN: StatbarHan^.SetText(0, 'Display windows in overlapping cascade');
      CM_CLOSECHILDREN  : StatbarHan^.SetText(0, 'Close all Nonogram data windows');
      SC_CLOSE          : StatbarHan^.SetText(0, 'Close this window');
      SC_MAXIMIZE       : StatbarHan^.SetText(0, 'Maximize this window');
      SC_MINIMIZE       : StatbarHan^.SetText(0, 'Minimize this window');
      SC_MOVE           : StatbarHan^.SetText(0, 'Move this window');
      SC_RESTORE        : StatbarHan^.SetText(0, 'Restore this window to its previous size');
      SC_SIZE           : StatbarHan^.SetText(0, 'Resize this window');
      SC_TASKLIST       : StatbarHan^.SetText(0, 'Activate the Windows Task Manager application');
      SC_NEXTWINDOW     : StatbarHan^.SetText(0, 'Move to the next window');
      3850              : StatbarHan^.SetText(0, 'Display a list of more available windows');
    ELSE
      IF ((Msg.WParam >= 3841) AND (Msg.WParam <= 3849)) THEN
        StatbarHan^.SetText(0, 'Bring this window to the front')
      ELSE
        StatbarHan^.SetText(0, '');
    END;

    (* Check for main menu selections *)
    IF ((Msg.WParam = hMenu1) AND (hMenu1 <> 0)) THEN StatbarHan^.SetText(0, 'File menu');
    IF ((Msg.WParam = hMenu2) AND (hMenu2 <> 0)) THEN StatbarHan^.SetText(0, 'Options menu');
    IF ((Msg.WParam = hMenu3) AND (hMenu3 <> 0)) THEN StatbarHan^.SetText(0, 'Window menu');
    IF ((Msg.WParam = hMenu4) AND (hMenu4 <> 0)) THEN StatbarHan^.SetText(0, 'Help menu');
  END;
END;


PROCEDURE TMainWindow.WMDropFiles(VAR Msg: TMessage);
VAR
 NumFiles, I: WORD;
 FileName: ARRAY [0..130] OF CHAR;
BEGIN
 (* Firstly find out how many files were dropped *)
 NumFiles := DragQueryFile(Msg.WParam, $FFFF, NIL, 0);

 IF (IsIconic(HWindow)) THEN OpenIcon(HWindow);

 (* Now we can retrieve the dropped files and open them *)
 FOR I := 0 TO (NumFiles-1) DO
 BEGIN
   DragQueryFile(Msg.WParam, I, FileName, Pred(Sizeof(FileName)));
   FileOpener(FileName);
 END;

 (* Cleanup - tell Windows that we're done with the "drop info" *)
 DragFinish(Msg.wParam);
END;


PROCEDURE TMainWindow.WMMenuChange(VAR Msg: TMessage);
BEGIN
  (* Update the MDI Menu bar *)
  SendMessage(ClientWnd^.HWindow, WM_MDISETMENU, 0, Msg.LParam);
  DrawMenuBar(HWindow);
END;


PROCEDURE TMainWindow.Paint(PaintDC: HDC; VAR PaintInfo: TPaintStruct);
BEGIN
  (* Call ancestor method *)
  TMDIWindow.Paint(PaintDC, PaintInfo);
END;


PROCEDURE TMainWindow.HandleToolbar(Createit: BOOLEAN);
VAR
  WinRect: TRECT;
  SizInfo: LONGINT;
BEGIN
  (* This procedure either creates or destroys the Toolbar depending
     on the value of the parameter <Createit> *)

  (* Get client window size *)
  GetClientRect(HWindow, WinRect);

  IF (Createit) THEN
  BEGIN
    (* Create a toolbar *)
    IF ((ToolbarHan = NIL) AND (ToolbarExist = FALSE)) THEN
    BEGIN
      ToolbarHan := New(PToolbar, Init(@self, 0, 0, (WinRect.Right - WinRect.Left), 30));
      Application^.MakeWindow(ToolbarHan);
      ToolbarExist := TRUE;
    END;
  END
  ELSE
  BEGIN
    (* Destroy the toolbar *)
    IF ((ToolbarHan <> NIL) AND (ToolbarExist = TRUE)) THEN
    BEGIN
      DestroyWindow(ToolbarHan^.HWindow);
      ToolbarHan := NIL;
      ToolbarExist := FALSE;
    END;
  END;

  HandleSizing((WinRect.Right-WinRect.Left), (WinRect.Bottom-WinRect.Top));
END;


PROCEDURE TMainWindow.HandleStatbar(Createit: BOOLEAN);
VAR
  WinRect: TRECT;
BEGIN
  (* This procedure either creates or destroys the Status bar depending
     on the value of the parameter <Create> *)

  (* Get client window size *)
  GetClientRect(HWindow, WinRect);

  IF (Createit) THEN
  BEGIN
    (* Create a status bar *)
    IF ((StatbarHan = NIL) AND (StatbarExist = FALSE)) THEN
    BEGIN
      StatbarHan := New(PStatbar, Init(@self, 0, (WinRect.Bottom - 22),
                        (WinRect.Right - WinRect.Left), 22));
      Application^.MakeWindow(StatbarHan);
      StatbarExist := TRUE;
    END;
  END
  ELSE
  BEGIN
    (* Destroy the status bar *)
    IF ((StatbarHan <> NIL) AND (StatbarExist = TRUE)) THEN
    BEGIN
      DestroyWindow(StatbarHan^.HWindow);
      StatbarHan := NIL;
      StatbarExist := FALSE;
    END;
  END;

  HandleSizing((WinRect.Right-WinRect.Left), (WinRect.Bottom-WinRect.Top));
END;


PROCEDURE TMainWindow.HandleSizing(Width: INTEGER; Height: INTEGER);
VAR
  ThisHeight, ThisTop: INTEGER;
BEGIN
  (* Given the width and height of the client area of the main window
     this function checks to see if the status bar and tool bar exist
     and then fills the space appropriately *)

  ThisHeight := Height;
  ThisTop := 0;
  IF (ToolbarExist) THEN ThisHeight := ThisHeight - 30;
  IF (StatbarExist) THEN ThisHeight := ThisHeight - 23;
  IF (ToolbarExist) THEN ThisTop := 30;

  (* Handle child window movements *)
  IF ((ClientWnd <> NIL) AND (ClientWnd^.HWindow <> 0)) THEN
    MoveWindow(ClientWnd^.HWindow, 0, ThisTop, Width, ThisHeight, TRUE);

  IF ((ToolbarHan <> NIL) AND (ToolbarExist)) THEN
  BEGIN
    IF (ToolbarHan^.HWindow <> 0) THEN
      MoveWindow(ToolbarHan^.HWindow, -1, -1, Width+2, 31, TRUE);
  END;

  IF ((StatbarHan <> NIL) AND (StatbarExist)) THEN
  BEGIN
    IF (StatbarHan^.HWindow <> 0) THEN
      MoveWindow(StatbarHan^.HWindow, -1, Height-23, Width+2, 31, TRUE);
  END;
END;


PROCEDURE TMainWindow.NoDisplayWin(Add: BOOLEAN);
BEGIN
  (* If <Add> is TRUE then <NoDisplays> is incremented otherwise it is
     decremented. If <NoDisplays> is zero then the default menu is
     used otherwise the full menus are used *)
  IF (Add) THEN INC(NoDisplays) ELSE DEC(NoDisplays);

  IF ((NoDisplays = 0) AND (GetMenu(HWindow) <> DefMenu)) THEN
  BEGIN
    (* Disable various toolbar buttons *)
    IF (ToolbarExist) THEN
    BEGIN
      ToolbarHan^.EnableButton(3, FALSE);                  
      ToolbarHan^.EnableButton(4, FALSE);
      ToolbarHan^.EnableButton(5, FALSE);
      ToolbarHan^.EnableButton(6, FALSE);
      ToolbarHan^.EnableButton(7, FALSE);
      ToolbarHan^.EnableButton(8, FALSE);
    END;
  END;
END;


PROCEDURE TMainWindow.HandleOldFiles(NewFile: PChar);
VAR
  A, B: INTEGER;
  hMenu1: HMENU;
  Continue: BOOLEAN;
BEGIN
  (* Check to see if this file is already in the list of old files *)
  A := 1;
  Continue := TRUE;
  WHILE ((Continue) AND (A <= 4)) DO
  BEGIN
    IF (StrComp(OldFiles[A], NewFile) = 0) THEN
    BEGIN
      FOR B := A DOWNTO 2 DO  StrCopy(OldFiles[B], OldFiles[B-1]);
      StrCopy(OldFiles[1], NewFile);
      Continue := FALSE;
    END;
    INC(A);
  END;

  (* This routine handles the old files *)
  IF (Continue) THEN
  BEGIN 
    StrCopy(OldFiles[4], OldFiles[3]);
    StrCopy(OldFiles[3], OldFiles[2]);
    StrCopy(OldFiles[2], OldFiles[1]);
    StrCopy(OldFiles[1], NewFile);
  END;

  (* Update the actual menu *)
  IF NOT(ModifyMenu(NorMenu, CM_FILE1, MF_BYCOMMAND, CM_FILE1, OldFiles[1])) THEN
  BEGIN
    (* Previous method was unsuccessful so menu cannot exist - we should only ever
       be in here when the menu is <Normenu> *)

    (* No maximized MDI window *)
    IF (GetSubMenu(GetMenu(HWindow), 4) = 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 0);

    (* Maximized MDI window exists *)
    IF (GetSubMenu(GetMenu(HWindow), 4) <> 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 1);

    AppendMenu(hMenu1, MF_SEPARATOR, 0, NIL);
    AppendMenu(hMenu1, MF_STRING, CM_FILE1, OldFiles[1]);
    AppendMenu(GetSubMenu(DefMenu, 0), MF_SEPARATOR, 0, NIL);
    AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE1, OldFiles[1]);
  END
  ELSE
    ModifyMenu(DefMenu, CM_FILE1, MF_BYCOMMAND, CM_FILE1, OldFiles[1]);

  (* Second ... *)
  IF (StrComp(OldFiles[2], '') = 0) THEN EXIT;
  IF NOT(ModifyMenu(NorMenu, CM_FILE2, MF_BYCOMMAND, CM_FILE2, OldFiles[2])) THEN
  BEGIN
    IF (GetSubMenu(GetMenu(HWindow), 4) = 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 0);
    IF (GetSubMenu(GetMenu(HWindow), 4) <> 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 1);
    AppendMenu(hMenu1, MF_STRING, CM_FILE2, OldFiles[2]);
    AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE2, OldFiles[2]);
  END
  ELSE
    ModifyMenu(DefMenu, CM_FILE2, MF_BYCOMMAND, CM_FILE2, OldFiles[2]);

  (* Third ... *)
  IF (StrComp(OldFiles[3], '') = 0) THEN EXIT;
  IF NOT(ModifyMenu(NorMenu, CM_FILE3, MF_BYCOMMAND, CM_FILE3, OldFiles[3])) THEN
  BEGIN
    IF (GetSubMenu(GetMenu(HWindow), 4) = 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 0);
    IF (GetSubMenu(GetMenu(HWindow), 4) <> 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 1);
    AppendMenu(hMenu1, MF_STRING, CM_FILE3, OldFiles[3]);
    AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE3, OldFiles[3]);
  END
  ELSE
    ModifyMenu(DefMenu, CM_FILE3, MF_BYCOMMAND, CM_FILE3, OldFiles[3]);

  (* Fourth ... *)
  IF (StrComp(OldFiles[4], '') = 0) THEN EXIT;
  IF NOT(ModifyMenu(NorMenu, CM_FILE4, MF_BYCOMMAND, CM_FILE4, OldFiles[4])) THEN
  BEGIN
    IF (GetSubMenu(GetMenu(HWindow), 4) = 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 0);
    IF (GetSubMenu(GetMenu(HWindow), 4) <> 0) THEN hMenu1 := GetSubMenu(GetMenu(HWindow), 1);
    AppendMenu(hMenu1, MF_STRING, CM_FILE4, OldFiles[4]);
    AppendMenu(GetSubMenu(DefMenu, 0), MF_STRING, CM_FILE4, OldFiles[4]);
  END
  ELSE
    ModifyMenu(DefMenu, CM_FILE4, MF_BYCOMMAND, CM_FILE4, OldFiles[4]);

  (* Redraw the menu bar *)
  DrawMenuBar(HWindow);
END;


PROCEDURE TMainWindow.CMNew(VAR Msg: TMessage);
VAR
  I, J: INTEGER;
  TextString: ARRAY [0..100] OF CHAR;
BEGIN
  (* Clear child window data *)
  NoDisplayWin(TRUE);
  DisplayHan := New(PDisplay, Init(@self, 'Untitled'));
  IF (Application^.MakeWindow(DisplayHan) = NIL) THEN
  BEGIN
    NoDisplayWin(FALSE);
    StrCopy(TextString, 'Serious error:'+#13+#13);
    StrCat(TextString, 'Cannot create another'+#13+'window');
    MessageBox(HWindow, TextString, 'Nonogram Solver',
               MB_ICONHAND OR MB_OK);
  END;
                                            
  (* Manipulate menu's appropriately *)
  EnableMenuItem(NorMenu, CM_SOLVE, MF_GRAYED);
  EnableMenuItem(NorMenu, CM_INFO, MF_GRAYED);
  EnableMenuItem(NorMenu, CM_STOPSO, MF_GRAYED);
  EnableMenuItem(NorMenu, CM_RECOVER, MF_GRAYED);

  IF (ToolbarExist) THEN
  BEGIN
    (* Disable toolbar buttons *)
    ToolbarHan^.EnableButton(5, FALSE);
    ToolbarHan^.EnableButton(6, FALSE);

    (* Enable other ones as well *)
    ToolbarHan^.EnableButton(3, TRUE);
    ToolbarHan^.EnableButton(4, TRUE);
    ToolbarHan^.EnableButton(7, TRUE);
    ToolbarHan^.EnableButton(8, TRUE);
  END;
END;


PROCEDURE TMainWindow.CMLoad(VAR Msg: TMessage);
BEGIN
  (* Bring up a new window and then a fileload dialog box *)
  SendMessage(HWindow, WM_COMMAND, CM_NEW, 0);
  PostMessage(HWindow, WM_COMMAND, CM_LOAD, 0);
END;


PROCEDURE TMainWindow.CMSetup(VAR Msg: TMessage);
VAR
  FlagSave: WORD;
BEGIN
  FlagSave := PrintStruct.Flags;
  PrintStruct.Flags := PrintStruct.Flags OR PD_PRINTSETUP;

  (* Setup the printer etc *)
  PrintDlg(PrintStruct);
  PrintStruct.Flags := FlagSave;
END;


PROCEDURE TMainWindow.CMFileExit(VAR Msg: TMessage);
BEGIN
  (* We are finsihed so close the window *)
  TMainWindow.CloseWindow;
END;


PROCEDURE TMainWindow.CMFile1(VAR Msg: TMessage);
BEGIN
  (* Open the file *)
  FileOpener(OldFiles[1]);
END;


PROCEDURE TMainWindow.CMFile2(VAR Msg: TMessage);
BEGIN
  (* Open the file *)
  FileOpener(OldFiles[2]);
END;


PROCEDURE TMainWindow.CMFile3(VAR Msg: TMessage);
BEGIN
  (* Open the file *)
  FileOpener(OldFiles[3]);
END;


PROCEDURE TMainWindow.CMFile4(VAR Msg: TMessage);
BEGIN
  (* Open the file *)
  FileOpener(OldFiles[4]);
END;


PROCEDURE TMainWindow.CMConfSolut(VAR Msg: TMessage);
BEGIN
  (* Bring up the solution options dialog box *)
  Application^.ExecDialog(New(PConfigWin, Init(@self, 'SolveBox')));
END;


PROCEDURE TMainWindow.CMConfDispl(VAR Msg: TMessage);
BEGIN
  (* Bring up the display dialog box *)
  IF (Application^.ExecDialog(New(PDisplayOptions, Init(@self, 'DisplayBox'))) = ID_OK) THEN
    InvalidateRect(HWindow, NIL, TRUE);
END;


PROCEDURE TMainWindow.CMPrefer(VAR Msg: TMessage);
BEGIN
  (* Bring up the preferences dialog box *)
  Application^.ExecDialog(New(PPreferences, Init(@self, 'Preferences')));
END;


PROCEDURE TMainWindow.CMContents(VAR Msg: TMessage);
BEGIN
  (* Bring up the main Windows help file - Contents page *)
  WinHelp(HWindow, HELPFILENAME , HELP_INDEX, 0);
END;


PROCEDURE TMainWindow.CMHelpOnHlp(VAR Msg: TMessage);
BEGIN
  (* Bring up the standard Windows help on help datafile *)
  WinHelp (HWindow, HELPFILENAME, HELP_HELPONHELP, 0);
END;


PROCEDURE TMainWindow.CMHelpAbout(VAR Msg: TMessage);            
BEGIN
  (* Bring up the 'About' dialog box *)
  Application^.ExecDialog(New(PAboutBox, Init(@self, 'AboutBox')));
END;


PROCEDURE TMainWindow.FileOpener(FileToOpen: PChar);
VAR
  TextString: ARRAY [0..100] OF CHAR;
BEGIN
  IF (FileExists(FileToOpen)) THEN
  BEGIN
    (* Open this file in a new window *)
    DisplayHan := New(PDisplay, Init(@self, 'Untitled'));
    IF (Application^.MakeWindow(DisplayHan) <> NIL) THEN
    BEGIN
      NoDisplayWin(TRUE);
    END
    ELSE
    BEGIN
      StrCopy(TextString, 'Serious error:'+#13+#13);
      StrCat(TextString, 'Cannot create another'+#13+'window');
      MessageBox(HWindow, TextString, 'Nonogram Solver',
                 MB_ICONHAND OR MB_OK);
    END;

    (* Manipulate menu's appropriately *)
    EnableMenuItem(Attr.Menu, CM_SOLVE, MF_GRAYED);
    EnableMenuItem(Attr.Menu, CM_INFO, MF_GRAYED);
    EnableMenuItem(Attr.Menu, CM_STOPSO, MF_GRAYED);
    EnableMenuItem(Attr.Menu, CM_RECOVER, MF_GRAYED);

    IF (ToolbarExist) THEN
    BEGIN
      (* Disable toolbar buttons *)
      ToolbarHan^.EnableButton(5, FALSE);
      ToolbarHan^.EnableButton(6, FALSE);
   
      (* Enable other ones as well *)
      ToolbarHan^.EnableButton(3, TRUE);
      ToolbarHan^.EnableButton(4, TRUE);
      ToolbarHan^.EnableButton(7, TRUE);
      ToolbarHan^.EnableButton(8, TRUE);
    END;

    StrCopy(DisplayHan^.FileName, FileToOpen);
    DisplayHan^.FileLoadImplement;
  END
  ELSE
    MessageBox(HWindow,
               'Error: This file cannot be located',
               'Nonogram Solver',
               MB_ICONEXCLAMATION);
END;


FUNCTION TMainWindow.GetClassName: PChar;
BEGIN
  (* Obtain the window class name *)
  GetClassName := 'Nonogram Window';
END;


FUNCTION TMainWindow.CanClose: BOOLEAN;
VAR
  TextString, TextStrtwo: ARRAY [0..80] OF CHAR;
  A: INTEGER;
BEGIN
  (* Check to see if we should exit *)
  CanClose := TMDIWindow.CanClose;

  IF (SolveInProgress AND ChildClosing) THEN
  BEGIN
    StopSolAndExit := TRUE;
    CanClose := FALSE;
    EXIT;
  END; 

  (* Save data into initialisation file *)
  IF (SaveOnExit) THEN
  BEGIN
    (* Main window attributes *)
    Str(Attr.W, TextString);
    WritePrivateProfileString('Main Window', 'Width', TextString,
                              INIFILENAME);
    Str(Attr.H, TextString);
    WritePrivateProfileString('Main Window', 'Height', TextString,
                              INIFILENAME);
    Str(Attr.X, TextString);
    WritePrivateProfileString('Main Window', 'X position', TextString,
                              INIFILENAME);
    Str(Attr.Y, TextString);
    WritePrivateProfileString('Main Window', 'Y position', TextString,
                              INIFILENAME);

    (* Solve confirmation *)
    IF (SolveConfirmation) THEN
      StrCopy(TextString, '1')
    ELSE
      StrCopy(TextString, '0');
    WritePrivateProfileString('Main Window', 'Solve confirmation', TextString,
                              INIFILENAME);

    (* Load confirmation *)
    IF (LoadConfirmation) THEN
      StrCopy(TextString, '1')
    ELSE
      StrCopy(TextString, '0');
    WritePrivateProfileString('Main Window', 'Load confirmation', TextString,
                              INIFILENAME);

    (* Solution options *)
    (* Greedy mode *)
    Str(ORD(GreedyModeOn), TextString);
    WritePrivateProfileString('Solution Options', 'Greedy mode on', TextString,
                              INIFILENAME);

    (* Quick start *)
    Str(ORD(QuickStrtOn), TextString);
    WritePrivateProfileString('Solution Options', 'Quick start on', TextString,
                              INIFILENAME);

    (* Edge checking *)
    Str(ORD(EdgeCheckOn), TextString);
    WritePrivateProfileString('Solution Options', 'Edge checking on', TextString,
                              INIFILENAME);

    (* Full row testing *)
    Str(ORD(FullRwTstOn), TextString);
    WritePrivateProfileString('Solution Options', 'Full row testing on', TextString,
                              INIFILENAME);

    (* Row following *)
    Str(ORD(RowFollowOn), TextString);
    WritePrivateProfileString('Solution Options', 'Row following on', TextString,
                              INIFILENAME);

    (* Single testing algorithm *)
    Str(ORD(SingleTstOn), TextString);
    WritePrivateProfileString('Solution Options', 'Single testing on', TextString,
                              INIFILENAME);

    (* Combination algorithm *)
    Str(ORD(CombinatnOn), TextString);
    WritePrivateProfileString('Solution Options', 'Combination on', TextString,
                              INIFILENAME);

    Str(VARSSize, TextString);
    WritePrivateProfileString('Solution Options', 'VARS size', TextString,
                              INIFILENAME);

    (* Display options *)
    (* Display rotation *)
    Str(ORD(DisplayRotate), TextString);
    WritePrivateProfileString('Display Options', 'Display rotation', TextString,
                              INIFILENAME);

    (* Display flip *)
    Str(ORD(DisplayFlip), TextString);
    WritePrivateProfileString('Display Options', 'Display flip', TextString,
                              INIFILENAME);
    (* Brush colours *)
    Str(BlkColour, TextString);
    WritePrivateProfileString('Display Options', 'Block colour', TextString, INIFILENAME);
    Str(DotColour, TextString);
    WritePrivateProfileString('Display Options', 'Dot colour', TextString, INIFILENAME);

    (* Yes, we saved on exit *)
    WritePrivateProfileString('Main Window', 'Save on exit', '1', INIFILENAME);
  END
  ELSE
  BEGIN
    (* No, we didn't save on exit *)
    WritePrivateProfileString('Main Window', 'Save on exit', '0', INIFILENAME);
  END;


  (* We always save the old file names *)
  FOR A := 1 TO 4 DO
  BEGIN
    StrCopy(TextString, 'Old file ');
    Str(A, TextStrtwo);
    StrCat(TextString, TextStrtwo);    
    WritePrivateProfileString('Main Window', TextString, OldFiles[A], INIFILENAME);
  END;
END;


FUNCTION  TMainWindow.CreateChild: PWindowsObject;
BEGIN
  CreateChild := New(PDisplay, Init(@self, 'Untitled'));
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
  Text3 := New(PStatic, InitResource(@self, ID_REGNAME, 15));
  Text4 := New(PStatic, InitResource(@self, ID_REGCOMP, 15));
  Text5 := New(PStatic, InitResource(@self, ID_VERSIONNO, 15));
  Text6 := New(PStatic, InitResource(@self, ID_RELSEDATE, 15));
END;
                                          

PROCEDURE TAboutBox.SetupWindow;
VAR
  TextString: ARRAY [0..100] OF CHAR;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;                                       
                               
  (* Set controls appropriately *)
  Text1^.SetText('Nonogram Solver');
  Text2^.SetText('Copyright � MD Soft 1993-1997');
  Text3^.SetText(UserName);
  Text4^.SetText(CompanyName);
  Text5^.SetText('Version 2.4');
  Text6^.SetText('Released: 28/12/1997');
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
    (* Create new toolbar *)
    PMainWindow(Parent)^.HandleToolbar(TRUE);
  END
  ELSE
  BEGIN
    (* Destroy current toolbar *)
    PMainWindow(Parent)^.HandleToolbar(FALSE);
  END;

  IF (Check4^.GetCheck = BF_CHECKED) THEN
  BEGIN
    (* Create new status bar *)
    PMainWindow(Parent)^.HandleStatbar(TRUE);
  END
  ELSE
  BEGIN
    (* Destroy current status bar *)
    PMainWindow(Parent)^.HandleStatbar(FALSE);
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
  WinHelp (HWindow, HELPFILENAME, HELP_CONTEXT, HC_PREFER);
END;


(**********************************************************************)
(* Methods of TConfigWin follow *)


CONSTRUCTOR TConfigWin.Init(AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Obtain handles to controls *)
  Check1 := New(PCheckBox, InitResource(@self, ID_QSTART));
  Check2 := New(PCheckBox, InitResource(@self, ID_ECHECK));
  Check3 := New(PCheckBox, InitResource(@self, ID_FROWTS));
  Check4 := New(PCheckBox, InitResource(@self, ID_ROWFOL));
  Check5 := New(PCheckBox, InitResource(@self, ID_SINGLE));
  Check6 := New(PCheckBox, InitResource(@self, ID_COMBIN));
  Check7 := New(PCheckBox, InitResource(@self, ID_GREEDY));
  Edit1  := New(PEdit, InitResource(@self, ID_VARS, 4));
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

  IF (PMainWindow(Parent)^.SingleTstOn) THEN
   Check5^.SetCheck(BF_CHECKED)
  ELSE
   Check5^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.CombinatnOn) THEN
   Check6^.SetCheck(BF_CHECKED)
  ELSE
   Check6^.SetCheck(BF_UNCHECKED);

  IF (PMainWindow(Parent)^.GreedyModeOn) THEN
   Check7^.SetCheck(BF_CHECKED)
  ELSE
   Check7^.SetCheck(BF_UNCHECKED);

  (* Set up text control *)
  Str(PMainWindow(Parent)^.VARSSize, Line);
  Edit1^.Insert(@Line);
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
    PMainWindow(Parent)^.SingleTstOn := TRUE
  ELSE
    PMainWindow(Parent)^.SingleTstOn := FALSE;

  IF (Check6^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.CombinatnOn := TRUE
  ELSE
    PMainWindow(Parent)^.CombinatnOn := FALSE;

  IF (Check7^.GetCheck = BF_CHECKED) THEN
    PMainWindow(Parent)^.GreedyModeOn := TRUE
  ELSE
    PMainWindow(Parent)^.GreedyModeOn := FALSE;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


PROCEDURE TConfigWin.DialogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up relevant help page *)
  WinHelp(HWindow, HELPFILENAME, HELP_CONTEXT, HC_SOLUTION);
END;


(**********************************************************************)
(* Methods of TDisplayOptions follow *)


CONSTRUCTOR TDisplayOptions.Init (AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)
  Radio1 := New(PRadioButton, InitResource(@self, ID_ZERODG));
  Radio2 := New(PRadioButton, InitResource(@self, ID_NINEDG));
  Radio3 := New(PRadioButton, InitResource(@self, ID_ONEEDG));
  Radio4 := New(PRadioButton, InitResource(@self, ID_TWOSDG));
  Check1 := New(PCheckBox, InitResource(@self, ID_Flip));
END;


PROCEDURE TDisplayOptions.SetupWindow;
BEGIN
  (* CAll ancestor method *)
  TDialog.SetupWindow;

  (* Uncheck all the radio buttons *)
  Radio1^.SetCheck(BF_UNCHECKED);
  Radio2^.SetCheck(BF_UNCHECKED);
  Radio3^.SetCheck(BF_UNCHECKED);
  Radio4^.SetCheck(BF_UNCHECKED);

  (* Set radio buttons appropriately *)
  CASE ORD(PDisplay(Parent)^.DisplayRotate) OF
    0 : Radio1^.SetCheck(BF_CHECKED);
    1 : Radio2^.SetCheck(BF_CHECKED);
    2 : Radio3^.SetCheck(BF_CHECKED);
    3 : Radio4^.SetCheck(BF_CHECKED);
  END;

  (* Should we flip the data set *)
  IF (PDisplay(Parent)^.DisplayFlip) THEN
    Check1^.Check
  ELSE
    Check1^.UnCheck;

  (* Store current block and dot brush colours *)
  TempBlkColour := PDisplay(Parent)^.BlkColour;
  TempDotColour := PDisplay(Parent)^.DotColour;
END;


PROCEDURE TDisplayOptions.DialogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up appropriate help page *)
  WinHelp(HWindow, HELPFILENAME, HELP_CONTEXT, HC_DISPLAY);
END;


PROCEDURE TDisplayOptions.OK(VAR Msg: TMessage);
VAR
  A: INTEGER;
BEGIN                                                             
  (* Copy radio buttons positions to parent fields *)
  IF (Radio1^.GetCheck = BF_CHECKED) THEN A := 0;
  IF (Radio2^.GetCheck = BF_CHECKED) THEN A := 1;
  IF (Radio3^.GetCheck = BF_CHECKED) THEN A := 2;
  IF (Radio4^.GetCheck = BF_CHECKED) THEN A := 3;
  PDisplay(Parent)^.DisplayRotate := DisplayRotation(A);

  IF (Check1^.GetCheck = BF_CHECKED) THEN
    PDisplay(Parent)^.DisplayFlip := TRUE
  ELSE
    PDisplay(Parent)^.DisplayFlip := FALSE;

  (* Check to see if colours have changed *)
  IF (TempBlkColour <> PDisplay(Parent)^.BlkColour) THEN
  BEGIN
    PDisplay(Parent)^.BlkColour := TempBlkColour;
    DeleteObject(PDisplay(Parent)^.BlkBrush);
    PDisplay(Parent)^.BlkBrush := CreateSolidBrush(TempBlkColour);
  END;

  IF (TempDotColour <> PDisplay(Parent)^.DotColour) THEN
  BEGIN
    PDisplay(Parent)^.DotColour := TempDotColour;
    DeleteObject(PDisplay(Parent)^.DotBrush);
    PDisplay(Parent)^.DotBrush := CreateSolidBrush(TempDotColour);
  END;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


PROCEDURE TDisplayOptions.CMDilogDefa(VAR Msg: TMessage);
VAR
  A: INTEGER;
BEGIN
  (* Set the currently selected options to be the default *)

  (* Copy radio buttons positions to parent fields... *)
  IF (Radio1^.GetCheck = BF_CHECKED) THEN A := 0;
  IF (Radio2^.GetCheck = BF_CHECKED) THEN A := 1;
  IF (Radio3^.GetCheck = BF_CHECKED) THEN A := 2;
  IF (Radio4^.GetCheck = BF_CHECKED) THEN A := 3;
  PMainWindow(PDisplay(Parent)^.Parent)^.DisplayRotate := DisplayRotation(A);

  (* ...and do the same for the check box... *)
  IF (Check1^.GetCheck = BF_CHECKED) THEN
    PMainWindow(PDisplay(Parent)^.Parent)^.DisplayFlip := TRUE
  ELSE
    PMainWindow(PDisplay(Parent)^.Parent)^.DisplayFlip := FALSE;

  (* ...and finally the chosen colours *)
  PMainWindow(PDisplay(Parent)^.Parent)^.BlkColour := TempBlkColour; 
  PMainWindow(PDisplay(Parent)^.Parent)^.DotColour := TempDotColour;

  (* If the status bar exists update it *)
  IF (PMainWindow(PDisplay(Parent)^.Parent)^.StatbarExist) THEN
    PMainWindow(PDisplay(Parent)^.Parent)^.StatbarHan^.SetText(0,
    'Default options updated');
END;


PROCEDURE TDisplayOptions.CMRestoDefa(VAR Msg: TMessage);
BEGIN
  (* Restore the display options to the original defaults *)
  PMainWindow(PDisplay(Parent)^.Parent)^.DisplayFlip := FALSE;
  PMainWindow(PDisplay(Parent)^.Parent)^.DisplayRotate := DR_ZERO;
  PMainWindow(PDisplay(Parent)^.Parent)^.BlkColour := $FFFFFF;
  PMainWindow(PDisplay(Parent)^.Parent)^.DotColour := $808080;
  TempBlkColour := $FFFFFF;
  TempDotColour := $808080;

  (* Update radio buttons *)
  Radio1^.SetCheck(BF_CHECKED);                                     
  Radio2^.SetCheck(BF_UNCHECKED);
  Radio3^.SetCheck(BF_UNCHECKED);
  Radio4^.SetCheck(BF_UNCHECKED);
  Check1^.SetCheck(BF_UNCHECKED);

  (* If the status bar exists update it *)
  IF (PMainWindow(PDisplay(Parent)^.Parent)^.StatbarExist) THEN
    PMainWindow(PDisplay(Parent)^.Parent)^.StatbarHan^.SetText(0,
    'Default options restored');
END;


PROCEDURE TDisplayOptions.CMBlkColour(VAR Msg: TMessage);
VAR
  Clr: TChooseColor;
BEGIN
  (* Change the block colour - fill in colour structure *)
  Clr.lStructSize  := Sizeof(TChooseColor);
  Clr.hwndOwner    := HWindow;
  Clr.hInstance    := HInstance;
  Clr.RGBresult    := TempBlkColour;
  Clr.lpCustColors := @PDisplay(Parent)^.CustColours;
  Clr.Flags        := CC_FULLOPEN OR CC_RGBINIT OR CC_ENABLEHOOK;
  Clr.lCustData    := 0;
  Clr.lpfnHook     := HookProc;

  IF (ChooseColor(Clr)) THEN
    TempBlkColour := Clr.RGBresult;

END;


PROCEDURE TDisplayOptions.CMDotColour(VAR Msg: TMessage);
VAR
  Clr: TChooseColor;
BEGIN
  (* Change the block colour - fill in colour structure *)
  Clr.lStructSize  := Sizeof(TChooseColor);
  Clr.hwndOwner    := HWindow;
  Clr.hInstance    := HInstance;
  Clr.RGBresult    := TempDotColour;
  Clr.lpCustColors := @PDisplay(Parent)^.CustColours;
  Clr.Flags        := CC_FULLOPEN OR CC_RGBINIT OR CC_ENABLEHOOK;
  Clr.lCustData    := 0;
  Clr.lpfnHook     := HookProc;                   

  IF (ChooseColor(Clr)) THEN
    TempDotColour := Clr.RGBresult;

END;


(**********************************************************************)
(* Methods of TEditControl follow *)


PROCEDURE TEditControl.WMKeydown(VAR Msg: TMessage);
BEGIN
  (* Respond to the user pressing the down arrow key *)
  IF (Msg.WParam = VK_DOWN) THEN
  BEGIN
    IF (PEditer(Parent)^.CloseOnDown) THEN
    BEGIN
      (* Increment <NumberSelected>, close parent dialog and create a new one *)
      SendMessage(PEditer(Parent)^.HWindow, WM_COMMAND, ID_OK, 0);
      INC(PDisplay(PEditer(Parent)^.Parent)^.NumberSelected);
      PostMessage(PDisplay(PEditer(Parent)^.Parent)^.HWindow, WM_COMMAND, ID_EDITDATA, 0);
    END;              
  END;

  (* Respond to the user pressing the up arrow key *)
  IF (Msg.WParam = VK_UP) THEN
  BEGIN
    IF (PEditer(Parent)^.CloseOnUp) THEN
    BEGIN
      (* Decrement <NumberSelected>, close parent dialog and create a new one *)
      SendMessage(PEditer(Parent)^.HWindow, WM_COMMAND, ID_OK, 0);
      DEC(PDisplay(PEditer(Parent)^.Parent)^.NumberSelected);
      PostMessage(PDisplay(PEditer(Parent)^.Parent)^.HWindow, WM_COMMAND, ID_EDITDATA, 0);
    END;
  END;

  (* Call default window processor *)
  DefWndProc(Msg);
END;


(**********************************************************************)
(* Methods of TEditer follow *)


CONSTRUCTOR TEditer.Init(AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)
  Edit1 := New(PEditControl, InitResource(@self, ID_EDITEREDT, 90));
  Text1 := New(PStatic, InitResource(@self, ID_EDITERSTA, 0));
END;


PROCEDURE TEditer.SetupWindow;
VAR
  TheRect: TRECT;
  TextString: ARRAY [0..10] OF CHAR;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Position edit window *)
  GetWindowRect(HWindow, TheRect);
  MoveWindow(HWindow, XPos, YPos, (TheRect.right-TheRect.left), (TheRect.bottom-TheRect.top), TRUE);

  (* Set up static control text *)
  Str(PDisplay(Parent)^.NumberSelected, TextString);
  Text1^.SetText(TextString);

  (* Set up edit control control *)
  Edit1^.SetText(EditText);
END;


PROCEDURE TEditer.Ok(VAR Msg: TMessage);
VAR
  I, J, K, Code, Value: INTEGER;
  Spare, Spareb: ARRAY [0..100] OF CHAR;
  UsingX: BOOLEAN;
BEGIN
  (* Transfer editer data to parent window *)
  Edit1^.GetLine(EditText, 100, 0);
  StrCat(EditText, ',');

  (* Determine whether we are using <XElements> or <YElements> *)
  IF ((PDisplay(Parent)^.DisplayRotate = DR_NINE) OR
      (PDisplay(Parent)^.DisplayRotate = DR_TWOS)) THEN
    IF (PDisplay(Parent)^.XAxisSelected) THEN  UsingX := FALSE  ELSE  UsingX := TRUE
  ELSE
    IF (PDisplay(Parent)^.XAxisSelected) THEN  UsingX := TRUE  ELSE  UsingX := FALSE;

  (* Firstly clear out any old data that may be stored in <XElements> or <YElements> *)
  FOR I := 1 TO MaxNoElements DO
  BEGIN
    IF (UsingX) THEN
      PDisplay(Parent)^.XElements[PDisplay(Parent)^.NumberSelected, I] := 0
    ELSE
      PDisplay(Parent)^.YElements[PDisplay(Parent)^.NumberSelected, I] := 0;
  END;

  I := 0;
  J := 0;
  K := 1;
  WHILE ((EditText[I] <> #0) AND (I < StrLen(EditText))) DO
  BEGIN
    IF ((ORD(EditText[I]) >= 48) AND (ORD(EditText[I]) <= 57)) THEN
    BEGIN
      Spare[J] := EditText[I];
      INC(J);
    END
    ELSE
    BEGIN
      IF (J > 0) THEN
      BEGIN
        (* Terminate string *)
        Spare[J] := #0;

        (* Convert string to a number and then copy it to parent field *)
        IF (UsingX) THEN
          Val(Spare, PDisplay(Parent)^.XElements[PDisplay(Parent)^.NumberSelected, K], Code)
        ELSE
          Val(Spare, PDisplay(Parent)^.YElements[PDisplay(Parent)^.NumberSelected, K], Code);

        (* Increment K and reset J *)
        INC(K);
        J := 0;
      END;
    END;  

    (* Increment counter *)
    INC(I);
  END;

  (* Parse the data *)
  PDisplay(Parent)^.ParseData;

  (* Call ancestor method *)
  TDialog.Ok(Msg);
END;


(**********************************************************************)
(* Methods of TInfoBox follow *)


CONSTRUCTOR TInfoBox.Init (AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)
  Text1 := New(PStatic, InitResource(@self, ID_INFOTITLE, 0));
  Text2 := New(PStatic, InitResource(@self, ID_INFOXGRID, 0));
  Text3 := New(PStatic, InitResource(@self, ID_INFOYGRID, 0));
  Text4 := New(PStatic, InitResource(@self, ID_INFOXPRSE, 0));
  Text5 := New(PStatic, InitResource(@self, ID_INFOYPRSE, 0));
  Text6 := New(PStatic, InitResource(@self, ID_INFOFILES, 0));
  Text7 := New(PStatic, InitResource(@self, ID_INFOFILED, 0));
  Text8 := New(PStatic, InitResource(@self, ID_INFOCOMME, 0));
  Text9 := New(PStatic, InitResource(@self, ID_INFOCOMBI, 0));
  Text10 := New(PStatic, InitResource(@self, ID_INFOCOMPL, 0));
END;


PROCEDURE TInfoBox.SetupWindow;
VAR
  TextString, Spare: ARRAY [0..80] OF CHAR;
  FileInfo: TSearchRec;
  I, J, K: LONGINT;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Set up static text controls *)
  Text1^.SetText(PDisplay(Parent)^.FilTitle);
  Str(PDisplay(Parent)^.XAcross, TextString);
  Text2^.SetText(TextString);
  Str(PDisplay(Parent)^.YAcross, TextString);
  Text3^.SetText(TextString);
  Str(PDisplay(Parent)^.Sum1, TextString);
  Text4^.SetText(TextString);
  Str(PDisplay(Parent)^.Sum2, TextString);
  Text5^.SetText(TextString);

  (* Get file information *)
  IF (FileExists(PDisplay(Parent)^.Filename)) THEN
  BEGIN
    FindFirst(PDisplay(Parent)^.FileName, faArchive, FileInfo);
    Str(FileInfo.Size, TextString);
    StrCat(TextString, ' bytes');
    Text6^.SetText(TextString);

    (* Convert the date and set the time *)
    ConvertDate(FileInfo.Time, TextString);
    Text7^.SetText(TextString);
  END
  ELSE
  BEGIN
    Text6^.SetText('Unknown');
    Text7^.SetText('Unknown');
  END;

  (* Check parse data *)
  IF (PDisplay(Parent)^.Sum1 = PDisplay(Parent)^.Sum2) THEN
    Text8^.SetText('Data passed parse test')
  ELSE
    Text8^.SetText('WARNING - Data failed parse test');

  K := PDisplay(Parent)^.XAcross*PDisplay(Parent)^.YAcross;
  I := LONGINT(PDisplay(Parent)^.CombinX DIV K);
  J := LONGINT(PDisplay(Parent)^.CombinY DIV K);
  K := (I+J) DIV 2;
  Str(K, TextString);
  StrCat(TextString, '  (Total of ');
  Str((PDisplay(Parent)^.CombinX+PDisplay(Parent)^.CombinY), Spare);
  StrCat(TextString, Spare);
  StrCat(TextString, ')');
  Text9^.SetText(TextString);        

  (* Calculate data complexity level *)
  CASE K OF
      0..3  : StrCopy(TextString, 'Trivial (1)');
      4..10 : StrCopy(TextString, 'Very low (2)');
     11..20 : StrCopy(TextString, 'Low (3)');
     21..30 : StrCopy(TextString, 'Moderate (4)');
     31..40 : StrCopy(TextString, 'Medium (5)');
     41..50 : StrCopy(TextString, 'Difficult (6)');
     51..60 : StrCopy(TextString, 'Hard (7)');
     61..70 : StrCopy(TextString, 'Very hard (8)');
     71..100: StrCopy(TextString, 'Extremely hard (9)');
    101..300: StrCopy(TextString, 'Almost impossible (10)');
  ELSE
    StrCopy(TextString, 'Does not register on scale (11)');
  END;
  Text10^.SetText(TextString);

END;


PROCEDURE TInfoBox.OK(VAR Msg: TMessage);
BEGIN
  (* Call ancestor method *)
  TDialog.OK(Msg);                  
END;


PROCEDURE TInfoBox.CMDilogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up appropriate help page *)
  WinHelp(HWindow, HELPFILENAME, HELP_CONTEXT, HC_INFOBOX);
END;


(**********************************************************************)
(* Methods of THeadBox follow *)


CONSTRUCTOR THeadBox.Init (AParent: PWindowsObject; AName: PChar);
BEGIN
  (* Call ancestor method *)
  TDialog.Init(AParent, AName);

  (* Get handles to controls *)
  Edit1 := New(PEdit, InitResource(@self, ID_HEADDESCR, 100));
  Edit2 := New(PEdit, InitResource(@self, ID_HEADXACRO, 4));
  Edit3 := New(PEdit, InitResource(@self, ID_HEADYACRO, 4));
END;


PROCEDURE THeadBox.SetupWindow;
VAR
  TextString: ARRAY [0..80] OF CHAR;
BEGIN
  (* Call ancestor method *)
  TDialog.SetupWindow;

  (* Set up edit controls *)
  Edit1^.SetText(PDisplay(Parent)^.FilTitle);
  Str(PDisplay(Parent)^.XAcross, TextString);
  Edit2^.SetText(TextString);
  Str(PDisplay(Parent)^.YAcross, TextString);
  Edit3^.SetText(TextString);
END;


PROCEDURE THeadBox.OK(VAR Msg: TMessage);
VAR
  TextString: ARRAY [0..10] OF CHAR;
  I, J, Code: INTEGER;
  Changed: BOOLEAN;
BEGIN
  Changed := FALSE;

  (* Copy edited data back to the main window *)
  Edit1^.GetText(PDisplay(Parent)^.FilTitle, 100);

  Edit2^.GetText(TextString, 10);
  Val(TextString, I, Code);
  IF (I < 1) THEN I := 1;
  IF (I > 100) THEN I := 100;
  IF  (I <> PDisplay(Parent)^.XAcross) THEN Changed := TRUE;

  Edit3^.GetText(TextString, 10);
  Val(TextString, J, Code);
  IF (J < 1) THEN J := 1;
  IF (J > 100) THEN J := 100;
  IF  (J <> PDisplay(Parent)^.YAcross) THEN Changed := TRUE;

  (* Check to see if resetting the size will invalidate the data *)
  PDisplay(Parent)^.ParseData;
  IF ((Changed) AND
      ((PDisplay(Parent)^.Sum1 <> 0) OR (PDisplay(Parent)^.Sum2 <> 0))) THEN
  BEGIN
     IF (MessageBox(HWindow, 'Changing the Nonogram size will reset all data!  Continue?',
                             'Nonogram Solver',
                             MB_YESNO OR MB_ICONQUESTION) = IDYES) THEN
     BEGIN
       PDisplay(Parent)^.XAcross := I;
       PDisplay(Parent)^.YAcross := J;
       PDisplay(Parent)^.ResetData;
     END;
  END
  ELSE
  BEGIN
    IF (Changed) THEN
    BEGIN
      PDisplay(Parent)^.XAcross := I;
      PDisplay(Parent)^.YAcross := J;
      PDisplay(Parent)^.ResetData;
    END;
  END;

  (* Call ancestor method *)
  TDialog.OK(Msg);
END;


PROCEDURE THeadBox.CMDilogHelp(VAR Msg: TMessage);
BEGIN
  (* Bring up appropriate help page *)
  WinHelp(HWindow, HELPFILENAME, HELP_CONTEXT, HC_HEADBOX);
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
  (* Get main window handle *)
  MainWindow := New(PMainWindow, Init('Nonogram Solver'));
END;




(**********************************************************************)
(* This is the main program *)


VAR
  NonogramApp: TNonogram;
  File1: TEXT;
  NChar: Char;
  I: INTEGER;

BEGIN
  (* Handle 3D controls *)
  Ctl3dRegister(HInstance);
  Ctl3dAutoSubclass(HInstance);

  (* Run Nonogram program *)
  NonogramApp.Init ('Nonogram');
  NonogramApp.Run;
  NonogramApp.Done;

  (* Unregister 3D controls *)
  Ctl3dUnRegister(HInstance);
END.



