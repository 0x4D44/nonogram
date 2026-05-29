# capture-gui.ps1 — launch a GUI exe, dump its menu + window hierarchy, and
# PrintWindow-capture each visible top-level window to PNG. PrintWindow renders
# the window into a DC directly, so it works in a HEADLESS session where a
# desktop screen-grab (mdscreensnap) comes back blank.
#
# Usage:
#   pwsh -File capture-gui.ps1 -Exe C:\language\nonogram\nonogram_mdtpw.exe `
#        -Delay 3 -Name run1 -OutDir C:\language\nonogram\shots
# Optional: -PostCmd 101   (PostMessage WM_COMMAND <id> to the frame before capture,
#           e.g. 101=CM_NEW, 102=CM_LOAD, 201=CM_SOLVE — to drive menu actions headlessly)
param(
  [Parameter(Mandatory=$true)][string]$Exe,
  [int]$Delay = 3,
  [string]$Name = "cap",
  [string]$OutDir = "C:\language\nonogram\shots",
  [int]$PostCmd = 0,
  [int]$PostDelay = 2
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public class Cap {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr m);
  [DllImport("user32.dll")] public static extern bool GetMenuString(IntPtr m, uint pos, StringBuilder s, int n, uint flags);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
  [DllImport("user32.dll")] public static extern IntPtr SendMessageTimeout(IntPtr h, uint msg, IntPtr wp, IntPtr lp, uint fl, uint to, out IntPtr res);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr wp, IntPtr lp);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static uint Target; public static List<IntPtr> Top=new List<IntPtr>(); public static List<IntPtr> Kids=new List<IntPtr>();
  public static bool TopCb(IntPtr h, IntPtr l){ uint p; GetWindowThreadProcessId(h,out p); if(p==Target && IsWindowVisible(h)){ var t=new StringBuilder(64); GetWindowText(h,t,64); if(t.Length>0) Top.Add(h);} return true; }
  public static bool KidCb(IntPtr h, IntPtr l){ Kids.Add(h); return true; }
  public static string Info(IntPtr h){ var t=new StringBuilder(256); GetWindowText(h,t,256); var c=new StringBuilder(256); GetClassName(h,c,256); RECT r; GetWindowRect(h,out r); return "cls='"+c+"' txt='"+t+"' vis="+IsWindowVisible(h)+" ("+r.L+","+r.T+" "+(r.R-r.L)+"x"+(r.B-r.T)+")"; }
}
"@
New-Item -ItemType Directory -Force $OutDir | Out-Null
$proc = Start-Process $Exe -PassThru
Start-Sleep -Seconds $Delay
[Cap]::Target = $proc.Id; [Cap]::Top.Clear()
[Cap]::EnumWindows([Cap+EnumProc]{param($h,$l)[Cap]::TopCb($h,$l)},[IntPtr]::Zero) | Out-Null
"process alive: $(-not $proc.HasExited)  top-level windows: $([Cap]::Top.Count)"
foreach($f in [Cap]::Top){
  "FRAME $f  $([Cap]::Info($f))"
  $m=[Cap]::GetMenu($f); $mc = if($m -ne [IntPtr]::Zero){[Cap]::GetMenuItemCount($m)} else {-1}
  "   GetMenu=$m itemCount=$mc"
  if($mc -gt 0){ for($i=0;$i -lt $mc;$i++){ $s=New-Object Text.StringBuilder 64; [Cap]::GetMenuString($m,$i,$s,64,0x400)|Out-Null; "     menu[$i]='$($s.ToString())'" } }
  [Cap]::Kids.Clear(); [Cap]::EnumChildWindows($f,[Cap+EnumProc]{param($h,$l)[Cap]::KidCb($h,$l)},[IntPtr]::Zero)|Out-Null
  foreach($k in [Cap]::Kids){ "   child $k  $([Cap]::Info($k))" }
  if($PostCmd -ne 0){
    "   PostMessage WM_COMMAND $PostCmd to frame"; [Cap]::PostMessage($f,0x111,[IntPtr]$PostCmd,[IntPtr]::Zero)|Out-Null; Start-Sleep -Seconds $PostDelay
  }
  $r=New-Object Cap+RECT; [Cap]::GetWindowRect($f,[ref]$r)|Out-Null; $w=$r.R-$r.L; $ht=$r.B-$r.T
  if($w -gt 10 -and $ht -gt 10){
    $bmp=New-Object Drawing.Bitmap($w,$ht); $g=[Drawing.Graphics]::FromImage($bmp); $dc=$g.GetHdc(); [Cap]::PrintWindow($f,$dc,2)|Out-Null; $g.ReleaseHdc($dc); $g.Dispose()
    $out=Join-Path $OutDir ("{0}_{1}.png" -f $Name,$f); $bmp.Save($out,[Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose(); "   saved $out"
  }
}
if(-not $proc.HasExited){ $proc.Kill() }
