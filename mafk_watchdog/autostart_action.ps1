param([string]$LogFile)
$ErrorActionPreference = 'Continue'

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W6 {
  public delegate bool CB(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(CB c, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int m);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  public struct RECT { public int L,T,R,B; }
}
"@

# mouse_event flags
$MOUSEEVENTF_LEFTDOWN = 0x0002
$MOUSEEVENTF_LEFTUP   = 0x0004

$SCRIPT_CENTER_FOCUS = $true

function Write-Log([string]$m){
  $line = '{0} {1}' -f (Get-Date -Format 'HH:mm:ss.fff'), $m
  Write-Output $line
  try { Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 } catch {}
}

function Get-HwndByTitle([string]$contains){
  $hits = New-Object System.Collections.ArrayList
  $cb = {
    param($h, $l)
    if([W6]::IsWindowVisible($h)){
      $sb = New-Object System.Text.StringBuilder 256
      [W6]::GetWindowText($h, $sb, 256) | Out-Null
      if($sb.Length -gt 0){
        $t = $sb.ToString()
        if($t.IndexOf($contains, [System.StringComparison]::OrdinalIgnoreCase) -ge 0){
          [void]$hits.Add([int64]$h)
        }
      }
    }
    return $true
  }
  [W6]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
  if($hits.Count -gt 0){ return [int64]$hits[0] }
  return 0
}

function Get-WindowCenter([int64]$hwnd){
  if($hwnd -eq 0){ return @(0,0) }
  $r = New-Object W6+RECT
  [W6]::GetWindowRect([IntPtr]$hwnd, [ref]$r) | Out-Null
  $cx = [int](($r.L + $r.R) / 2)
  $cy = [int](($r.T + $r.B) / 2)
  return @($cx, $cy)
}

function Click-Screen([int]$x, [int]$y){
  [W6]::SetCursorPos($x, $y) | Out-Null
  Start-Sleep -Milliseconds 80
  [W6]::mouse_event($MOUSEEVENTF_LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 60
  [W6]::mouse_event($MOUSEEVENTF_LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 120
}

# focus a window by clicking it (works from background, unlike SetForegroundWindow)
# $point: 'center' or 'title' (click title bar to avoid hitting controls)
function Focus-WindowClick([int64]$hwnd, [string]$point){
  if($hwnd -eq 0){ return $false }
  [W6]::ShowWindow([IntPtr]$hwnd, 9) | Out-Null
  [W6]::ShowWindow([IntPtr]$hwnd, 5) | Out-Null
  Start-Sleep -Milliseconds 200
  if($point -eq 'title'){
    $r = New-Object W6+RECT
    [W6]::GetWindowRect([IntPtr]$hwnd, [ref]$r) | Out-Null
    $cx = [int](($r.L + $r.R) / 2)
    $cy = [int]($r.T + 15)
    Write-Log ("  click focus(title) at $cx,$cy")
    Click-Screen $cx $cy
  } else {
    $c = Get-WindowCenter $hwnd
    Write-Log ("  click focus at $($c[0]),$($c[1])")
    Click-Screen $c[0] $c[1]
  }
  Start-Sleep -Milliseconds 300
  return $true
}

function Send-Keys([string]$keys){
  try {
    $ws = New-Object -ComObject wscript.shell
    $ws.SendKeys($keys)
  } catch { Write-Log ("SendKeys error: " + $_.Exception.Message) }
}

function Activate-And-Enter([int64]$hwnd, [string]$point){
  # bring window to focus by clicking it, then press Enter
  Focus-WindowClick $hwnd $point | Out-Null
  Start-Sleep -Milliseconds 250
  Write-Log 'Send ENTER'
  Send-Keys '{ENTER}'
  Start-Sleep -Milliseconds 1200
}

# forcefully restart the launcher so its window is guaranteed to be in focus
function Restart-Launcher(){
  if(Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue){
    Write-Log 'Refusing to restart launcher: game is running'
    return $false
  }
  Write-Log 'Restarting launcher'
  Get-Process -Name 'RADMIR Launcher' -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  try {
    Start-Process -FilePath (Join-Path (Split-Path $PSScriptRoot -Parent) 'Launcher\RADMIR Launcher.exe')
  } catch { Write-Log ('Reload launch error: ' + $_.Exception.Message) }
  # wait for window
  for($i=0; $i -lt 60; $i++){
    if(Get-HwndByTitle 'RADMIR Launcher' -ne 0){ break }
    Start-Sleep -Milliseconds 500
  }
  Start-Sleep -Milliseconds 2000
  return $true
}

Write-Log 'AUTOSTART session begin'

# --- 1) ensure launcher window & press Play ---
$lap = Get-HwndByTitle 'RADMIR Launcher'
if($lap -eq 0){
  Write-Log 'Launcher not open - launching'
  try {
    Start-Process -FilePath (Join-Path (Split-Path $PSScriptRoot -Parent) 'Launcher\RADMIR Launcher.exe')
  } catch { Write-Log ('Launch error: ' + $_.Exception.Message) }
  for($i=0; $i -lt 60; $i++){
    $lap = Get-HwndByTitle 'RADMIR Launcher'
    if($lap -ne 0){ break }
    Start-Sleep -Milliseconds 500
  }
  if($lap -eq 0){ Write-Log 'FAIL: launcher window did not appear'; exit 1 }
  Start-Sleep -Milliseconds 2500
}
Write-Log ("Launcher hwnd=" + $lap)
Activate-And-Enter $lap 'center'

# --- 2) wait for Device Selection, with reset guard ---
$t0 = Get-Date
$lastGuard = Get-Date
$lastRestart = Get-Date
$started = $false
while($true){
  $dev = Get-HwndByTitle 'Device Selection'
  if($dev -ne 0){
    Write-Log ("Device Selection found hwnd=" + $dev)
    Activate-And-Enter $dev 'title'
    $started = $true
    break
  }
  if(((Get-Date) - $lastGuard).TotalSeconds -ge 6){
    $lastGuard = Get-Date
    if(-not (Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue)){
      Write-Log 'No Device Selection and no game yet - ESC guard (dismiss reset)'
      $lap = Get-HwndByTitle 'RADMIR Launcher'
      if($lap -ne 0){ Focus-WindowClick $lap | Out-Null; Start-Sleep -Milliseconds 150; Send-Keys '{ESC}' }
    }
  }
  # if no progress and game not running for ~20s, launcher may be minimized/stuck -> restart it
  if(((Get-Date) - $lastRestart).TotalSeconds -ge 20){
    $lastRestart = Get-Date
    if(-not (Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue)){
      Write-Log 'No Device Selection / no game for ~20s - restarting launcher'
      Restart-Launcher | Out-Null
      $lr = Get-HwndByTitle 'RADMIR Launcher'
      if($lr -ne 0){ Activate-And-Enter $lr 'center' }
      else { Write-Log 'Launcher window missing after restart, will retry' }
    }
  }
  if(((Get-Date) - $t0).TotalSeconds -gt 90){
    Write-Log 'FAIL: timed out waiting for Device Selection (90s)'
    exit 2
  }
  Start-Sleep -Milliseconds 400
}

# --- 3) wait for game process ---
$ok = $false
for($i=0; $i -lt 60; $i++){
  if(Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue){ $ok = $true; break }
  Start-Sleep -Milliseconds 500
}
if($ok){ Write-Log 'SUCCESS: game process started' }
else { Write-Log 'Device Selection handled but game process not detected within 30s' }

exit 0
