VERSION 2.00
Begin Form Setup1 
   BackColor       =   &H00400000&
   Caption         =   "Test App Setup"
   ControlBox      =   0   'False
   FillStyle       =   0  'Solid
   FontBold        =   -1  'True
   FontItalic      =   -1  'True
   FontName        =   "MS Sans Serif"
   FontSize        =   24
   FontStrikethru  =   0   'False
   FontUnderline   =   0   'False
   ForeColor       =   &H00000000&
   Height          =   2535
   Icon            =   SETUP1.FRX:0000
   Left            =   1080
   LinkMode        =   1  'Source
   LinkTopic       =   "Form3"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   142
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   376
   Top             =   2235
   Width           =   5760
   Begin Label Label2 
      BorderStyle     =   1  'Fixed Single
      Caption         =   "To customize this setup program, modify the FORM_LOAD event procedure in this form."
      Height          =   435
      Left            =   15
      TabIndex        =   1
      Top             =   15
      Visible         =   0   'False
      Width           =   5625
   End
   Begin Label Label1 
      BorderStyle     =   1  'Fixed Single
      Caption         =   "This label used for DDE connection to the Program Manager"
      Height          =   390
      Left            =   15
      TabIndex        =   0
      Top             =   525
      Visible         =   0   'False
      Width           =   5610
   End
End

Const APPNAME = "Nonogram Solver"
Const APPDIR = "C:\NONOGRAM"    ' The default install directory

' Set the total uncompressed file sizes
' by adding the sizes of the files
Const WINSYSNEEDED = 22000  ' Files that go into WINDOWS and SYSTEM directory
Const OTHERNEEDED = 320000  ' Files that don't go into the WINDOWS or SYSTEM directory

Sub DrawBackground ()
    Setup1.CurrentY = 5
    Setup1.CurrentX = 5
    Setup1.ForeColor = QBColor(15)
    Print APPNAME + " Setup"
End Sub

Sub Form_Load ()

   
   'hw% = GetModuleHandle("SETUP1.EXE")
   'm = Ctl3DRegister(hw%)
   'm = Ctl3dAutoSubclass(hw%)


    '----------
    ' Initialize
    '----------
    dialogCaption$ = APPNAME + " Setup"
    ShowMainForm dialogCaption$
    
    '----------------------------------------------------
    ' SETUP.EXE passes the source drive in a command
    ' argument.  If it is empty,  that means the user
    ' executed this .exe directly.  In that case, show
    ' a dialog to get the desired source directory.
    '----------------------------------------------------
    SourcePath$ = Command$
    If SourcePath$ = "" Then
	title$ = dialogCaption$
	caption1$ = "Please enter the drive or path containing the " + APPNAME + " source files."
	caption2$ = "Install From:"
	defaultDrive$ = "A:"
	defaultText$ = "A:\"

	ShowPathDialog title$, caption1$, caption2$, defaultDrive$, defaultText$, SourcePath$, outButton$

	If outButton$ = "exit" Then GoTo ErrorSetup
    Else
	If Right$(SourcePath$, 1) <> "\" Then
	    SourcePath$ = SourcePath$ + "\"
	End If
    End If



    '--------------------
    ' Get Destination Path
    '--------------------
    title$ = dialogCaption$
    caption1$ = "If you want to install the Nonogram Solver in a different directory and/or drive, type the name of the directory."
    caption2$ = "Install To:"
    defaultDrive$ = "C:"
    defaultText$ = APPDIR

    ShowPathDialog title$, caption1$, caption2$, defaultDrive$, defaultText$, destPath$, outButton$

    If (outButton$ = "exit") Then GoTo ErrorSetup
    
    ShowLicenceDialog title$, UserName$, CompanyName$, LicNum$, outButton$, SourcePath$
    If (outButton$ = "exit") Then GoTo ErrorSetup

    If Not (GenerateLicence(UserName$, CompanyName$, LicNum$, SourcePath$)) Then GoTo ErrorSetup


    '---------------------
    ' Sample Option Dialog
    '---------------------
    ReDim Caption(1 To 4) As String
    ReDim choice(1 To 4) As Integer
'
'    title$ = dialogCaption$
'    numOptions = 4
'    Caption(1) = "Sample Option 1"
'    Caption(2) = "Sample Option 2"
'    Caption(3) = "Sample Option 3"
'    Caption(4) = "Sample Option 4"
'    helpTxt$ = "Choose your options!   These options are not actually used by this setup program, but by looking in the SETUP1.FRM code you can see how to implement your own option dialogs."

'    ShowOptionDialog title$, numOptions, Caption$(), helpTxt$, choice(), outButton$

'    If outButton$ = "exit" Then
'        GoTo ErrorSetup
'    Else
'        If choice(1) Then MsgBox "Option #1 Selected", 48, "SETUP"
'        If choice(2) Then MsgBox "Option #2 Selected", 48, "SETUP"
'        If choice(3) Then MsgBox "Option #3 Selected", 48, "SETUP"
'        If choice(4) Then MsgBox "Option #4 Selected", 48, "SETUP"
'    End If


    '-----------------------------------------
    ' Dim disk space variables as Long Integers
    '-----------------------------------------
    Dim winSpaceFree As Long
    Dim sourceSpaceFree As Long
    Dim destSpaceFree As Long
    Dim totalNeeded As Long

    winDir$ = GetWindowsDir$()
    winSysDir$ = GetWindowsSysDir$()

    '---------------------------------------------------------
    ' If the Windows \SYSTEM directory is a subdirectory
    ' of the Windows directory, the proper place for
    ' installation of .VBXs and shared .DLLs is the
    ' Windows \SYSTEM directory.
    '
    ' If the Windows \SYSTEM directory is *not* a subdirectory
    ' of the Windows directory, then the user is running a
    ' shared version of Windows, and the proper place for
    ' installation of .VBXs and shared .DLLs is the
    ' Windows directory.
    '---------------------------------------------------------
    If InStr(winSysDir$, winDir$) = 0 Then
	winSysDir$ = winDir$
    End If

    
    '---------------------------------
    ' Get Drive Letters of directories
    '---------------------------------
    winDrive$ = UCase$(Left$(winDir$, 1))
    destDrive$ = UCase$(Left$(destPath$, 1))
    sourceDrive$ = UCase$(Left$(SourcePath$, 1))

    '---------------------------------
    ' Compute free disk space variables
    '---------------------------------
    winSpaceFree = GetDiskSpaceFree(winDrive$)
    destSpaceFree = GetDiskSpaceFree(destDrive$)
    
    '-----------------------------------------
    ' Check for enough disk space.
    '
    ' Some components are being installed into the
    ' Windows\SYSTEM directory.
    '
    ' So if the main destination path is on a
    ' different drive than the drive with
    ' the Windows \SYSTEM directory, we have to
    ' check both drives.
    '
    ' An example of this is when the user is installing
    ' the main product to drive D:, but the Windows
    ' directory is on drive c:
    ' -----------------------------------------
    totalNeeded = WINSYSNEEDED + OTHERNEEDED
    
    If winDrive$ = destDrive$ Then
	If destSpaceFree < totalNeeded Then
	    MsgBox "There is not enough disk space on drive " + destDrive$ + ":   An estimated" + Str$(totalNeeded - destSpaceFree) + " additional bytes are needed.", 16, dialogCaption$
	    GoTo ErrorSetup
	End If
    Else
	If winSpaceFree < WINSYSNEEDED Then
	    MsgBox "There is not enough disk space on drive " + winDrive$ + ":  An estimated" + Str$(WINSYSNEEDED - winSpaceFree) + " additional bytes are needed.", 16, dialogCaption$
	    GoTo ErrorSetup
	End If
	If destSpaceFree < OTHERNEEDED Then
	    MsgBox "There is not enough disk space on drive " + destDrive$ + ":  An estimated" + Str$(OTHERNEEDED - destSpaceFree) + " additional bytes are needed.", 16, dialogCaption$
	    GoTo ErrorSetup
	End If
	
    End If



    '----------------------------
    ' Create destination directory
    '----------------------------
    If Not CreatePath(destPath$) Then GoTo ErrorSetup
    


    '-----------------------------------------------------------
    ' Show Status Dialog -- This stays up while copying files
    ' It is required by the CopyFile routine
    '-----------------------------------------------------------
    ShowStatusDialog dialogCaption$, totalNeeded
    
    
    '-----------
    ' Copy Files
    '-----------

    ' Test to see if loan.exe is on the disk, if not then you know the user
    ' did not insert the first disk
    If Not PromptForNextDisk(1, SourcePath$ + "nonogram.ex_") Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "nonogram.ex_", "nonogram.exe", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "mdgen.dl_", "mdgen.dll", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "nonogram.lic", "nonogram.lic", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "anteater.ng_", "anteater.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "bear.ng_", "bear.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "camel.ng_", "camel.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "carpflag.ng_", "carpflag.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "cat.ng_", "cat.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "downhill.ng_", "downhill.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "flysquir.ng_", "flysquir.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "football.ng_", "football.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "freesia.ng_", "freesia.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "gemini.ng_", "gemini.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "gianttor.ng_", "gianttor.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "giraffe.ng_", "giraffe.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "golf.ng_", "golf.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "gorilla.ng_", "gorilla.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "handglid.ng_", "handglid.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "hawk.ng_", "hawk.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "hercrab.ng_", "hercrab.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "hotair.ng_", "hotair.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "hydro.ng_", "hydro.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "jackbean.ng_", "jackbean.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "japan.ng_", "japan.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "liontoo.ng_", "liontoo.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "lotus.ng_", "lotus.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "mudmud.ng_", "mudmud.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "narcissu.ng_", "narcissu.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "partone.ng_", "partone.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "parttwo.ng_", "parttwo.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "pig.ng_", "pig.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "pumpkin.ng_", "pumpkin.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "rabbit.ng_", "rabbit.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "reynard.ng_", "reynard.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "ribbon.ng_", "ribbon.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "rose.ng_", "rose.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "rudolph.ng_", "rudolph.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "saggit.ng_", "saggit.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "santa.ng_", "santa.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "scottie.ng_", "scottie.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "seal.ng_", "seal.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "shrimps.ng_", "shrimps.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "snowman.ng_", "snowman.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "soccer.ng_", "soccer.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "swan.ng_", "swan.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "swan2.ng_", "swan2.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "tennis.ng_", "tennis.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "theram.ng_", "theram.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "train.ng_", "train.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "tropfish.ng_", "tropfish.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "ufo.ng_", "ufo.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "ursamajo.ng_", "ursamajo.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "waterbuf.ng_", "waterbuf.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "white.ng_", "white.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "wildhors.ng_", "wildhors.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "witchapp.ng_", "witchapp.ngm", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, destPath$, "nonogram.hl_", "nonogram.hlp", True) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, winSysDir$, "ctl3d.dl_", "ctl3d.dll", False) Then GoTo ErrorSetup
    If Not CopyFile(SourcePath$, winSysDir$, "commdlg.dl_", "commdlg.dll", False) Then GoTo ErrorSetup

    ' If you have more than one distribution disk, call PromptForNextDisk after
    ' you have installed all the files from the previous disk. This line tests to
    ' see if foo.da_ is on disk 2. If not, you know the user has not inserted disk 2.
    ' The call to PromptForNextDisk is commented out, since loan.exe can be installed
    ' from a single distribution disk.
    
    ' If Not PromptForNextDisk(2, SourcePath$ + "foo.da_") Then GoTo ErrorSetup
    ' If Not CopyFile(SourcePath$, destPath$, "foo.da_", "foo.dat", 0) Then GoTo ErrorSetup


    '--------------------------------------------------
    ' File Copying is over, so unload the status dialog
    '--------------------------------------------------
    Unload StatusDlg


    '-----------------------------------------------------------
    ' Show static message while working on DDE to Program Manager
    '-----------------------------------------------------------
    ShowStaticMessageDialog dialogCaption$, "Creating Program Manager Icon..."


    '--------------------------------------
    ' Create program manager group and icon
    '--------------------------------------
    CreateProgManGroup Setup1, "MD Soft", "MDSOFT.GRP"
    CreateProgManItem Setup1, destPath$ + "NONOGRAM.EXE", "The Nonogram Solver v2.3"


    '-------------------------------------------------
    ' Since SETUP.EXE copies your setup program to the Windows
    ' directory, it is possible for your user to
    ' execute this program directly.
    '
    ' As a usability feature, you may wish to insert code
    ' here to install a program manager icon that executes
    ' your setup program in the windows drive.  This
    ' allows th user to re-run setup at a later time to
    ' install options that were not installed the first
    ' time.
    '-------------------------------------------------

    '-------------------
    ' Hide Static Message
    '-------------------
    MessageDlg.Hide
    

    '------------------
    ' Show Final message
    '------------------
    MsgBox APPNAME + " Installation is Complete!", 48, dialogCaption$

ExitSetup:
    Setup1.Hide
    RestoreProgMan         'Show the program manager
    'hw% = GetModuleHandle("SETUP1.EXE")
    'm = Ctl3DUnRegister(hw%)

    End
    Exit Sub

ErrorSetup:
    MsgBox APPNAME + " is not properly installed.  Please re-run setup at a later time to install it properly.", 48, dialogCaption$
    'hw% = GetModuleHandle("SETUP1.EXE")
    'm = Ctl3DUnRegister(hw%)

    End
    Exit Sub
    
End Sub

Sub Form_Paint ()
    DrawBackground
End Sub

Function GenerateLicence (User$, Company$, LicNum$, FilePath$)

  ' Declare variables
  Dim OutDat As String
  Dim FilePos As Integer
  Dim total As Integer

  '  This sub generates a licence file given the above data

  ' Generate open file path
  FileToOpen$ = FilePath$ & ("NONOGRAM.LIC")
  If (FileExists(FileToOpen$)) Then Kill (FileToOpen$)

  ' Open licence file
  Open FileToOpen$ For Binary As #1

  ' Output initial header information
  OutDat = Chr(&H10): Put #1, 1, OutDat   ' Day
  OutDat = Chr(&H4): Put #1, 2, OutDat    ' Month
  OutDat = Chr(&H19): Put #1, 3, OutDat   ' Year (1st half)
  OutDat = Chr(&H94): Put #1, 4, OutDat   ' Year (2nd half)
  OutDat = Chr(&H0): Put #1, 5, OutDat    ' Program specific 1st byte
  OutDat = Chr(&H0): Put #1, 6, OutDat    ' Program specific 2nd byte
  OutDat = Chr(&H1): Put #1, 7, OutDat    ' Program specific 3rd byte
  OutDat = Chr(&H43): Put #1, 8, OutDat   ' Reserved
  OutDat = Chr(&H2C): Put #1, 9, OutDat   ' Reserved
  OutDat = Chr(&HA5): Put #1, 10, OutDat  ' Reserved
  OutDat = Chr(&H10): Put #1, 11, OutDat  ' Reserved
  OutDat = Chr(&H2B): Put #1, 12, OutDat  ' Reserved
  OutDat = Chr(&H4C): Put #1, 13, OutDat  ' Reserved
  OutDat = Chr(&H2E): Put #1, 14, OutDat  ' Reserved
  OutDat = Chr(&H1A): Put #1, 15, OutDat  ' Reserved
  OutDat = Chr(&H2): Put #1, 16, OutDat   ' Reserved
  
  FilePos = 17
  total = 0

  ' Output user name
  For I = 1 To Len(User$)
    OutDat = Chr(212 - Asc(Mid$(User$, I, 1)))
    total = total + Asc(Mid$(User$, I, 1))
    Put #1, FilePos, OutDat
    FilePos = FilePos + 1
  Next

  ' Mark end of user name data
  OutDat = Chr(&HFF): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&HFF): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&H23): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&H69): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  
  ' Output company name
  For I = 1 To Len(Company$)
    OutDat = Chr(252 - Asc(Mid$(Company$, I, 1)))
    total = total + Asc(Mid$(Company$, I, 1))
    Put #1, FilePos, OutDat
    FilePos = FilePos + 1
  Next

  ' Mark end of company name data
  OutDat = Chr(&HCE): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&HFF): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&HFF): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&H53): Put #1, FilePos, OutDat: FilePos = FilePos + 1

  ' Generate user/company name information check
  TempA = total \ 256
  TempB = total - 256 * TempA
  OutDat = Chr(TempA): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(TempB): Put #1, FilePos, OutDat: FilePos = FilePos + 1

  total = 0

  ' Write out licence number information
  For I = 1 To Len(LicNum$)
    OutDat = Chr(234 - Asc(Mid$(LicNum$, I, 1)))
    total = total + Asc(Mid$(LicNum$, I, 1))
    Put #1, FilePos, OutDat
    FilePos = FilePos + 1
  Next
  
  ' Mark end of licence number data
  OutDat = Chr(&HCE): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&HFE): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&H81): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(&H21): Put #1, FilePos, OutDat: FilePos = FilePos + 1

  ' Generate licence number information check
  TempA = total \ 256
  TempB = total - 256 * TempA
  OutDat = Chr(TempA): Put #1, FilePos, OutDat: FilePos = FilePos + 1
  OutDat = Chr(TempB): Put #1, FilePos, OutDat: FilePos = FilePos + 1


  Close #1

  ' Return success flag
  GenerateLicence = True

End Function

Sub ShowLicenceDialog (title$, UserName$, CompanyName$, LicNumber$, outButton$, DefaultPath$)

  ' Set up licence dialog
  Screen.MousePointer = 11
  Load LicenceDlg
  LicenceDlg.Caption = title$
  LicenceDlg.outButton.Tag = DefaultPath$
  FileTolookfor$ = (DefaultPath$) & ("NONOGRAM.LIC")
   
  CenterForm LicenceDlg
  Screen.MousePointer = 0

  LicenceDlg.Show 1
	
  UserName$ = LicenceDlg.UseNme.Tag
  CompanyName$ = LicenceDlg.ComNme.Tag
  LicNumber$ = LicenceDlg.LicNum.Tag
  outButton$ = LicenceDlg.outButton.Tag
  Unload LicenceDlg

End Sub

'---------------------------------------------------------------
' Sets the form's caption, Paints 3-D Background Text, Shows Form
'---------------------------------------------------------------
Sub ShowMainForm (Caption$)
    Screen.MousePointer = 11
    Setup1.Caption = Caption$
    Setup1.Move 0, 0, Screen.Width, Screen.Height * .85
    Setup1.Show
    Setup1.Refresh

    Setup1.ScaleMode = 2
    Setup1.FontSize = 24
    Setup1.FontBold = True
    Setup1.FontItalic = True
    
    DrawBackground
End Sub

Sub ShowPathDialog (title$, caption1$, caption2$, defaultDrive$, defaultText$, SourcePath$, outButton$)
	Screen.MousePointer = 11
	Load Pathdlg
	Pathdlg.Caption = title$
	Pathdlg.Label1.Caption = caption1$
	Pathdlg.Label2.Caption = caption2$
	Pathdlg.inDrive.Tag = defaultDrive$
	Pathdlg.Text1.Text = defaultText$
	Pathdlg.Text1.SelStart = 0
	Pathdlg.Text1.SelLength = Len(defaultText$)
	CenterForm Pathdlg
	Screen.MousePointer = 0

	Pathdlg.Show 1
	
	SourcePath$ = Pathdlg.outPath.Tag
	outButton$ = Pathdlg.outButton.Tag
	Unload Pathdlg
End Sub

Sub ShowStaticMessageDialog (title$, Caption$)

    Load MessageDlg
    CenterForm MessageDlg
    MessageDlg.Caption = title$
    MessageDlg.Label.Caption = Caption$
    MessageDlg.Show
    MessageDlg.Refresh

End Sub

Sub ShowStatusDialog (title$, totalBytes As Long)

    Load StatusDlg
    StatusDlg.Caption = title$
    StatusDlg.total.Tag = Str$(totalBytes)
    CenterForm StatusDlg
    StatusDlg.Show

End Sub

