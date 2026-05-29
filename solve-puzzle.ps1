# solve-puzzle.ps1 — drive nonogram_mdtpw.exe headlessly to LOAD a .NGM and SOLVE it,
# capturing the result via PrintWindow. Uses File|Open dialog automation (the
# filename Edit id=1148 + Open button id=1, validated against tgof1.exe).
# REQUIRES the Win32 callback-ABI fix (else nonogram's OFN_ENABLEHOOK File|Open AVs).
#
# Usage: pwsh -File solve-puzzle.ps1 -Puzzle C:\language\nonogram\MARYMARY.NGM -Name marymary
param(
  [Parameter(Mandatory=$true)][string]$Puzzle,
  [string]$Name = "solve",
  [string]$Exe = "C:\language\nonogram\nonogram_mdtpw.exe",
  [string]$OutDir = "C:\language\nonogram\shots",
  [int]$LoadWait = 3,
  [int]$SolveWait = 6
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public class S {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll", CharSet=CharSet.Ansi)] public static extern IntPtr SendMessageA(IntPtr h, uint m, IntPtr w, string l);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static uint Target; public static List<IntPtr> Acc=new List<IntPtr>();
  public static bool Cb(IntPtr h,IntPtr l){ uint p; GetWindowThreadProcessId(h,out p); if(p==Target){Acc.Add(h);} return true; }
  public static bool All(IntPtr h,IntPtr l){ Acc.Add(h); return true; }
  public static string Cls(IntPtr h){ var c=new StringBuilder(64); GetClassName(h,c,64); return c.ToString(); }
  public static string Txt(IntPtr h){ var t=new StringBuilder(256); GetWindowText(h,t,256); return t.ToString(); }
}
"@
function TopWins { [S]::Acc.Clear(); [S]::EnumWindows([S+EnumProc]{param($h,$l)[S]::Cb($h,$l)},[IntPtr]::Zero)|Out-Null; ,([S]::Acc.ToArray()) }
function Kids($p){ [S]::Acc.Clear(); [S]::EnumChildWindows($p,[S+EnumProc]{param($h,$l)[S]::All($h,$l)},[IntPtr]::Zero)|Out-Null; ,([S]::Acc.ToArray()) }
function Cap($h,$tag){ $r=New-Object S+RECT; [S]::GetWindowRect($h,[ref]$r)|Out-Null; $w=$r.R-$r.L; $ht=$r.B-$r.T; if($w -gt 10 -and $ht -gt 10){ $bmp=New-Object Drawing.Bitmap($w,$ht); $g=[Drawing.Graphics]::FromImage($bmp); $dc=$g.GetHdc(); [S]::PrintWindow($h,$dc,2)|Out-Null; $g.ReleaseHdc($dc); $g.Dispose(); $out=Join-Path $OutDir ("{0}_{1}.png" -f $Name,$tag); $bmp.Save($out,[Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); "saved $out" } }
function DismissBoxes($frame){ foreach($h in (TopWins)){ if([S]::IsWindowVisible($h) -and $h -ne $frame -and [S]::Cls($h) -eq '#32770'){ "  dialog '$([S]::Txt($h))' -> dismiss"; [S]::PostMessage($h,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null } } }  # WM_CLOSE

New-Item -ItemType Directory -Force $OutDir | Out-Null
$proc=Start-Process $Exe -WorkingDirectory (Split-Path $Exe) -PassThru; Start-Sleep -Seconds 3
[S]::Target=$proc.Id
$frame=$null; foreach($h in (TopWins)){ if([S]::IsWindowVisible($h) -and [S]::Txt($h) -eq 'Nonogram Solver'){$frame=$h} }
$child=$null; foreach($k in (Kids $frame)){ if([S]::Cls($k) -eq 'NONOGRAM_DISPLAY'){$child=$k} }
"frame=$frame child=$child"
# 1) File|Open on the child
[S]::PostMessage($child,0x111,[IntPtr]102,[IntPtr]::Zero)|Out-Null; Start-Sleep -Seconds $LoadWait
# 2) automate the open dialog
$dlg=$null; foreach($h in (TopWins)){ if([S]::IsWindowVisible($h) -and $h -ne $frame -and [S]::Cls($h) -eq '#32770'){$dlg=$h} }
if($dlg){ $edit=$null;$open=$null; foreach($k in (Kids $dlg)){ $id=[S]::GetDlgCtrlID($k); $c=[S]::Cls($k); if($id -eq 1148 -and $c -eq 'Edit'){$edit=$k}; if($id -eq 1 -and $c -eq 'Button'){$open=$k} }; "  dialog=$dlg edit=$edit open=$open"; [S]::SendMessageA($edit,0x000C,[IntPtr]::Zero,$Puzzle)|Out-Null; [S]::SendMessage($open,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null; Start-Sleep -Seconds 2 } else { "  NO open dialog (callback fix not in?)" }
Cap $frame 'loaded'
# 3) Solve
$child=$null; foreach($k in (Kids $frame)){ if([S]::Cls($k) -eq 'NONOGRAM_DISPLAY'){$child=$k} }
[S]::PostMessage($child,0x111,[IntPtr]201,[IntPtr]::Zero)|Out-Null; Start-Sleep -Seconds $SolveWait
DismissBoxes $frame; Start-Sleep -Seconds 1
Cap $frame 'solved'
if(-not $proc.HasExited){ $proc.Kill() }
