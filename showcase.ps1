# showcase.ps1 — solve a puzzle in the app, then render a CLEAN black-on-white
# image of the app's actual solution (filled=black, empty=white) by classifying
# the rendered grid. Proves + visualizes correctness clearly.
param([string[]]$Puzzles, [string]$Dir="C:\language\nonogram", [string]$Out="C:\language\nonogram\shots\clean")
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public class SC {
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
  [DllImport("user32.dll",CharSet=CharSet.Ansi)] public static extern IntPtr SendMessageA(IntPtr h, uint m, IntPtr w, string l);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  public static uint Target; public static List<IntPtr> Acc=new List<IntPtr>();
  public static bool Cb(IntPtr h,IntPtr l){ uint p; GetWindowThreadProcessId(h,out p); if(p==Target){Acc.Add(h);} return true; }
  public static bool All(IntPtr h,IntPtr l){ Acc.Add(h); return true; }
  public static string Cls(IntPtr h){ var c=new StringBuilder(64); GetClassName(h,c,64); return c.ToString(); }
  public static string Txt(IntPtr h){ var t=new StringBuilder(256); GetWindowText(h,t,256); return t.ToString(); }
}
"@
function Tops { [SC]::Acc.Clear(); [SC]::EnumWindows([SC+EnumProc]{param($h,$l)[SC]::Cb($h,$l)},[IntPtr]::Zero)|Out-Null; ,([SC]::Acc.ToArray()) }
function Kids($p){ [SC]::Acc.Clear(); [SC]::EnumChildWindows($p,[SC+EnumProc]{param($h,$l)[SC]::All($h,$l)},[IntPtr]::Zero)|Out-Null; ,([SC]::Acc.ToArray()) }
function Snap($h){ $r=New-Object SC+RECT;[SC]::GetWindowRect($h,[ref]$r)|Out-Null;$w=$r.R-$r.L;$ht=$r.B-$r.T;if($w-lt10){return $null};$bmp=New-Object Drawing.Bitmap($w,$ht);$g=[Drawing.Graphics]::FromImage($bmp);$dc=$g.GetHdc();[SC]::PrintWindow($h,$dc,2)|Out-Null;$g.ReleaseHdc($dc);$g.Dispose();$bmp }
New-Item -ItemType Directory -Force $Out | Out-Null
foreach($pp in $Puzzles){
  $name=Split-Path $pp -Leaf
  $L=Get-Content $pp; $d=($L[1].Trim() -split '[\s,]+'); $cols=[int]$d[0]; $rows=[int]$d[1]
  $proc=Start-Process "$Dir\nonogram_mdtpw.exe" -WorkingDirectory $Dir -PassThru; Start-Sleep -Seconds 3
  [SC]::Target=$proc.Id
  $frame=$null;foreach($h in (Tops)){if([SC]::IsWindowVisible($h)-and [SC]::Txt($h)-eq 'Nonogram Solver'){$frame=$h}}
  $child=$null;foreach($k in (Kids $frame)){if([SC]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
  [SC]::PostMessage($child,0x111,[IntPtr]102,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds 2
  $dlg=$null;foreach($h in (Tops)){if([SC]::IsWindowVisible($h)-and $h-ne $frame-and [SC]::Cls($h)-eq '#32770'){$dlg=$h}}
  $edit=$null;$ok=$null;foreach($k in (Kids $dlg)){$id=[SC]::GetDlgCtrlID($k);if($id-eq 1152){$edit=$k};if($id-eq 1-and [SC]::Cls($k)-eq 'Button'){$ok=$k}}
  [SC]::SendMessageA($edit,0x000C,[IntPtr]::Zero,$pp)|Out-Null;[SC]::SendMessage($ok,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds 2
  $child=$null;foreach($k in (Kids $frame)){if([SC]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
  $loaded=Snap $child
  [SC]::PostMessage($child,0x111,[IntPtr]201,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds 30
  $child=$null;foreach($k in (Kids $frame)){if([SC]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
  $solved=Snap $child
  if(-not $proc.HasExited){$proc.Kill()}
  # geometry from loaded (192-gray), square pitch from x-extent/cols
  $W=$loaded.Width;$H=$loaded.Height
  $cc=@(0)*$W; for($x=0;$x -lt $W;$x++){ $n=0; for($y=0;$y -lt $H;$y+=2){ $p=$loaded.GetPixel($x,$y);$b=($p.R+$p.G+$p.B)/3; if($b -ge 180 -and $b -le 205){$n++} }; $cc[$x]=$n }
  $mc=($cc|measure -Max).Maximum; $xs=@(0..($W-1)|?{$cc[$_] -gt 0.4*$mc})
  $rc=@(0)*$H; for($y=0;$y -lt $H;$y++){ $n=0; for($x=0;$x -lt $W;$x+=2){ $p=$loaded.GetPixel($x,$y);$b=($p.R+$p.G+$p.B)/3; if($b -ge 180 -and $b -le 205){$n++} }; $rc[$y]=$n }
  $mr=($rc|measure -Max).Maximum; $ys=@(0..($H-1)|?{$rc[$_] -gt 0.4*$mr})
  $x0=$xs[0];$y0=$ys[0];$pitch=($xs[-1]-$xs[0])/$cols
  # render clean: filled(white>=215)->black, else white. scale 8px/cell.
  $cell=8; $img=New-Object Drawing.Bitmap (($cols*$cell+1),($rows*$cell+1)); $gr=[Drawing.Graphics]::FromImage($img)
  $gr.Clear([Drawing.Color]::White); $blk=[Drawing.Brushes]::Black; $nfill=0
  for($r=0;$r -lt $rows;$r++){ for($c=0;$c -lt $cols;$c++){
    $cx=[int]($x0+($c+0.5)*$pitch);$cy=[int]($y0+($r+0.5)*$pitch);$sum=0;$t=0
    for($dy=-2;$dy -le 2;$dy++){for($dx=-2;$dx -le 2;$dx++){ if($cx+$dx -ge 0 -and $cx+$dx -lt $solved.Width -and $cy+$dy -ge 0 -and $cy+$dy -lt $solved.Height){$p=$solved.GetPixel($cx+$dx,$cy+$dy);$sum+=($p.R+$p.G+$p.B)/3;$t++}}}
    if($t -and ($sum/$t) -ge 215){ $gr.FillRectangle($blk,$c*$cell,$r*$cell,$cell,$cell); $nfill++ } } }
  $gr.Dispose(); $o=Join-Path $Out ($name+'.clean.png'); $img.Save($o,[Drawing.Imaging.ImageFormat]::Png); $img.Dispose()
  $loaded.Dispose();$solved.Dispose()
  "{0,-14} {1}x{2} rendered {3} filled -> {4}" -f $name,$cols,$rows,$nfill,$o
}
