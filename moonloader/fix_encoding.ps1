# PowerShell script to fix AutoLogin_2.0.lua encoding from UTF-8 to CP1251
# This script reads the file as UTF-8, fixes Russian text, and saves as CP1251

$path = "C:\Games\RADMIR Games\RADMIR CRMP\moonloader\AutoLogin_2.0.lua"

# Read as UTF-8
$content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

# The file is now valid UTF-8 with correct Russian text
# Just re-save as CP1251 for MoonLoader
[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::GetEncoding(1251))

Write-Output "Done: file re-saved as CP1251"
Write-Output "Size: $((Get-Item $path).Length) bytes"
