param()
$ErrorActionPreference = 'Continue'

$FLAG = Join-Path (Split-Path $PSScriptRoot -Parent) 'RADMIR CRMP\mafk_on.flag'
$ACTION = Join-Path $PSScriptRoot 'autostart_action.ps1'
$LOGFILE = Join-Path $PSScriptRoot 'watchdog.log'

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WW {
  public delegate bool CB(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(CB c, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int m);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
  public struct RECT { public int L,T,R,B; }
}
"@
$LD = 0x0002; $LU = 0x0004

function Write-Log([string]$m){
  $line = '{0} {1}' -f (Get-Date -Format 'HH:mm:ss.fff'), $m
  try { Add-Content -LiteralPath $LOGFILE -Value $line -Encoding UTF8 } catch {}
}

# return visible windows (hwnd,pid,title) whose title contains $needle
function Get-WindowsByTitleContains([string]$needle){
  $res = New-Object System.Collections.ArrayList
  $cb = {
    param($h, $l)
    if([WW]::IsWindowVisible($h)){
      $sb = New-Object System.Text.StringBuilder 256
      [WW]::GetWindowText($h, $sb, 256) | Out-Null
      if($sb.Length -gt 0 -and $sb.ToString().IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0){
        [uint32]$p=0; [WW]::GetWindowThreadProcessId($h,[ref]$p)|Out-Null
        [void]$res.Add([pscustomobject]@{ Hwnd=[int64]$h; Pid=[int64]$p; Title=$sb.ToString() })
      }
    }
    return $true
  }
  [WW]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
  return $res
}

function Click-Screen([int]$x,[int]$y){
  [WW]::SetCursorPos($x,$y)|Out-Null
  Start-Sleep -Milliseconds 80
  [WW]::mouse_event($LD,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 60
  [WW]::mouse_event($LU,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 120
}

function Get-WindowTitleBar([int64]$hwnd){
  $r = New-Object WW+RECT
  [WW]::GetWindowRect([IntPtr]$hwnd,[ref]$r)|Out-Null
  return @([int](($r.L+$r.R)/2), [int]($r.T+15))
}

function Send-Key([string]$keys){
  try { (New-Object -ComObject wscript.shell).SendKeys($keys) } catch {}
}

Write-Log 'watchdog loop started'

while($true){
  Start-Sleep -Seconds 5

  if(-not (Test-Path -LiteralPath $FLAG)){
    continue  # mafk not active -> do nothing
  }

  $gta = Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue

  if(-not $gta){
    Write-Log 'TRIGGER: game not running -> autostart'
    & $ACTION -LogFile $LOGFILE
    Start-Sleep -Seconds 5
    continue
  }

  # game process exists. Detect a crash dialog (a window belonging to gta_sa
  # whose title contains the RADMIR error dialog caption "Произошла ошибка").
  $crash = @(Get-WindowsByTitleContains 'Произошла ошибка')

  if($crash.Count -gt 0){
    $w = $crash[0]
    Write-Log ("CRASH DIALOG detected hwnd=" + $w.Hwnd + " title=[" + $w.Title + "]")
    # focus the dialog by clicking its title bar, then press Enter (activates "Close" button)
    $tb = Get-WindowTitleBar $w.Hwnd
    Click-Screen $tb[0] $tb[1]
    Start-Sleep -Milliseconds 300
    Send-Key '{ENTER}'
    Start-Sleep -Milliseconds 3000

    $still = Get-Process -Name 'gta_sa' -ErrorAction SilentlyContinue
    if($still){
      Write-Log 'CRASH dialog not dismissed, killing gta_sa'
      $still | Stop-Process -Force -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 2
    }
    Write-Log 'TRIGGER: after crash -> autostart'
    & $ACTION -LogFile $LOGFILE
    Start-Sleep -Seconds 5
    continue
  }

  # game running normally, no crash dialog -> wait
}
