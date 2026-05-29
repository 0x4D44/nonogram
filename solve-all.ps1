# solve-all.ps1 — batch-solve nonogram puzzles headlessly and VERIFY each with a
# clue-check (geometry from the empty grid + per-cell classify + run-length check).
# Saves a solved screenshot per puzzle. Reports PASS / FAIL / REJECTED(by app).
param(
  [string[]]$Puzzles,                       # explicit list; else all .NGM in root + _puzzles
  [int]$Max = 0,                            # 0 = no limit
  [string]$Exe = "C:\language\nonogram\nonogram_mdtpw.exe",
  [string]$Dir = "C:\language\nonogram",
  [string]$ShotDir = "C:\language\nonogram\shots\solved",
  [int]$Wait = 0
)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public class SA {
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
function Tops { [SA]::Acc.Clear(); [SA]::EnumWindows([SA+EnumProc]{param($h,$l)[SA]::Cb($h,$l)},[IntPtr]::Zero)|Out-Null; ,([SA]::Acc.ToArray()) }
function Kids($p){ [SA]::Acc.Clear(); [SA]::EnumChildWindows($p,[SA+EnumProc]{param($h,$l)[SA]::All($h,$l)},[IntPtr]::Zero)|Out-Null; ,([SA]::Acc.ToArray()) }
function Parse-NGM($path){ $L=Get-Content $path; $d=($L[1].Trim() -split '[\s,]+'); $c=[int]$d[0]; $r=[int]$d[1]
  $col=@(); for($i=2;$i -lt 2+$c;$i++){ $t=@($L[$i].Trim() -split '[\s,]+' | ?{$_ -match '^\d+$' -and [int]$_ -gt 0} | %{[int]$_}); $col+=,$t }
  $row=@(); for($i=2+$c;$i -lt 2+$c+$r;$i++){ $t=@($L[$i].Trim() -split '[\s,]+' | ?{$_ -match '^\d+$' -and [int]$_ -gt 0} | %{[int]$_}); $row+=,$t }
  @{Cols=$c;Rows=$r;Col=$col;Row=$row} }
function Snap($h){ $r=New-Object SA+RECT;[SA]::GetWindowRect($h,[ref]$r)|Out-Null;$w=$r.R-$r.L;$ht=$r.B-$r.T; if($w-lt 10){return $null}
  $bmp=New-Object Drawing.Bitmap($w,$ht);$g=[Drawing.Graphics]::FromImage($bmp);$dc=$g.GetHdc();[SA]::PrintWindow($h,$dc,2)|Out-Null;$g.ReleaseHdc($dc);$g.Dispose();$bmp }
function Geom($bmp,$cols){ $W=$bmp.Width;$H=$bmp.Height
  $cc=@(0)*$W; for($x=0;$x -lt $W;$x++){ $n=0; for($y=0;$y -lt $H;$y+=2){ $p=$bmp.GetPixel($x,$y);$b=($p.R+$p.G+$p.B)/3; if($b -ge 180 -and $b -le 205){$n++} }; $cc[$x]=$n }
  $rc=@(0)*$H; for($y=0;$y -lt $H;$y++){ $n=0; for($x=0;$x -lt $W;$x+=2){ $p=$bmp.GetPixel($x,$y);$b=($p.R+$p.G+$p.B)/3; if($b -ge 180 -and $b -le 205){$n++} }; $rc[$y]=$n }
  $mc=($cc|measure -Max).Maximum; $mr=($rc|measure -Max).Maximum
  $xs=@(0..($W-1)|?{$cc[$_] -gt 0.4*$mc}); $ys=@(0..($H-1)|?{$rc[$_] -gt 0.4*$mr})
  if($xs.Count -lt 2 -or $ys.Count -lt 2){return $null}
  @{X0=$xs[0];Y0=$ys[0];Pitch=($xs[-1]-$xs[0])/$cols} }
function Classify($bmp,$g,$cols,$rows){ $grid=@(); for($r=0;$r -lt $rows;$r++){ $line=@(); for($c=0;$c -lt $cols;$c++){
   $cx=[int]($g.X0+($c+0.5)*$g.Pitch); $cy=[int]($g.Y0+($r+0.5)*$g.Pitch); $sum=0;$tot=0
   for($dy=-2;$dy -le 2;$dy++){for($dx=-2;$dx -le 2;$dx++){ if($cx+$dx -ge 0 -and $cx+$dx -lt $bmp.Width -and $cy+$dy -ge 0 -and $cy+$dy -lt $bmp.Height){ $p=$bmp.GetPixel($cx+$dx,$cy+$dy);$sum+=($p.R+$p.G+$p.B)/3;$tot++ }}}
   $b=if($tot){$sum/$tot}else{255}; if($b -ge 215){$line+='F'} elseif($b -ge 170){$line+='U'} else {$line+='E'} }; $grid+=,$line }; $grid }
function Runs($cells){ $out=@();$run=0; foreach($x in $cells){ if($x -eq 'F'){$run++} else { if($run-gt 0){$out+=$run};$run=0 } }; if($run-gt 0){$out+=$run}; ,$out }
function ArrEq($a,$b){ if($a.Count -ne $b.Count){return $false}; for($i=0;$i -lt $a.Count;$i++){ if($a[$i]-ne$b[$i]){return $false} }; $true }
function DismissBoxes($frame){ $hit=$null; foreach($h in (Tops)){ if([SA]::IsWindowVisible($h) -and $h -ne $frame -and [SA]::Cls($h)-eq '#32770'){ $hit=[SA]::Txt($h); [SA]::PostMessage($h,0x0010,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null } }; $hit }

New-Item -ItemType Directory -Force $ShotDir | Out-Null
if(-not $Puzzles){ $Puzzles = @(Get-ChildItem "$Dir\*.NGM") + @(Get-ChildItem "$Dir\_puzzles\*.NGM") | Select-Object -Expand FullName }
$seen=@{}; $list=@(); foreach($p in $Puzzles){ $k=(Split-Path $p -Leaf).ToUpper(); if(-not $seen[$k]){$seen[$k]=$true;$list+=$p} }
if($Max -gt 0){ $list=$list[0..([math]::Min($Max,$list.Count)-1)] }
$results=@()
foreach($pp in $list){
  $name=Split-Path $pp -Leaf
  $ngm=Parse-NGM $pp; $expected=0; foreach($cl in $ngm.Col){foreach($v in $cl){$expected+=$v}}
  $wait=if($Wait -gt 0){$Wait}else{[math]::Min(20,[math]::Max(4,[int](($ngm.Cols*$ngm.Rows)/120)))}
  $proc=Start-Process $Exe -WorkingDirectory $Dir -PassThru; Start-Sleep -Seconds 3
  [SA]::Target=$proc.Id
  $frame=$null;foreach($h in (Tops)){if([SA]::IsWindowVisible($h)-and [SA]::Txt($h)-eq 'Nonogram Solver'){$frame=$h}}
  $status='?';$F=-1;$U=-1;$fails=-1
  try{
    $child=$null;foreach($k in (Kids $frame)){if([SA]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
    [SA]::PostMessage($child,0x111,[IntPtr]102,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds 2
    $dlg=$null;foreach($h in (Tops)){if([SA]::IsWindowVisible($h)-and $h-ne $frame-and [SA]::Cls($h)-eq '#32770'){$dlg=$h}}
    $edit=$null;$ok=$null;foreach($k in (Kids $dlg)){$id=[SA]::GetDlgCtrlID($k);if($id-eq 1152){$edit=$k};if($id-eq 1-and [SA]::Cls($k)-eq 'Button'){$ok=$k}}
    [SA]::SendMessageA($edit,0x000C,[IntPtr]::Zero,$pp)|Out-Null;[SA]::SendMessage($ok,0x00F5,[IntPtr]::Zero,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds 2
    $box=DismissBoxes $frame   # 'cannot be solved' on inconsistent data
    if($box -and $box -match 'Solver'){ Start-Sleep -Milliseconds 300 }
    $child=$null;foreach($k in (Kids $frame)){if([SA]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
    $loaded=Snap $child
    [SA]::PostMessage($child,0x111,[IntPtr]201,[IntPtr]::Zero)|Out-Null;Start-Sleep -Seconds $wait
    DismissBoxes $frame | Out-Null; Start-Sleep -Milliseconds 300
    $child=$null;foreach($k in (Kids $frame)){if([SA]::Cls($k)-eq 'NONOGRAM_DISPLAY'){$child=$k}}
    $solved=Snap $child
    if($solved){ $solved.Save((Join-Path $ShotDir ($name+'.png')),[Drawing.Imaging.ImageFormat]::Png) }
    $g=if($loaded){Geom $loaded $ngm.Cols}else{$null}
    if($g -and $solved){
      $grid=Classify $solved $g $ngm.Cols $ngm.Rows
      $F=0;$U=0; foreach($ln in $grid){foreach($ch in $ln){if($ch-eq'F'){$F++}elseif($ch-eq'U'){$U++}}}
      $fails=0
      for($c=0;$c -lt $ngm.Cols;$c++){ $col=@(); for($r=0;$r -lt $ngm.Rows;$r++){$col+=$grid[$r][$c]}; if(-not(ArrEq (Runs $col) $ngm.Col[$c])){$fails++} }
      for($r=0;$r -lt $ngm.Rows;$r++){ if(-not(ArrEq (Runs $grid[$r]) $ngm.Row[$r])){$fails++} }
      $cells=$ngm.Cols*$ngm.Rows; $upct=if($cells){$U/$cells}else{0}
      $status = if($fails -eq 0 -and $U -eq 0 -and $F -eq $expected){'PASS'} elseif($F -le 3 -and $upct -gt 0.9){'REJECTED'} else {'FAIL'}
    } else { $status='NOGEOM' }
    if($loaded){$loaded.Dispose()}; if($solved){$solved.Dispose()}
  } catch { $status='ERR:'+$_.Exception.Message }
  if(-not $proc.HasExited){ $proc.Kill() | Out-Null }; Start-Sleep -Milliseconds 300
  $results += [pscustomobject]@{Name=$name;Dim="$($ngm.Cols)x$($ngm.Rows)";Exp=$expected;Filled=$F;Unk=$U;Fails=$fails;Status=$status}
  "{0,-14} {1,-6} exp={2,-4} filled={3,-4} unk={4,-4} fails={5,-4} {6}" -f $name,"$($ngm.Cols)x$($ngm.Rows)",$expected,$F,$U,$fails,$status
}
"";"==== SUMMARY ===="
$results | Group-Object Status | %{ "{0}: {1}" -f $_.Name,$_.Count }
"PASS: $(($results|?{$_.Status -eq 'PASS'}).Count) / $($results.Count)"
