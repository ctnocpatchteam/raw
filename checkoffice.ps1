#CT Script
#Check Office Version

cls
$x32 = ${env:ProgramFiles(x86)} + "\Microsoft Office"
$x64 = $env:ProgramFiles + "\Microsoft Office"
$OK = $true

if (Test-Path -Path $x32) {$Excel32 = Get-ChildItem -Recurse -Path $x32 -Filter "EXCEL.EXE"}
if (Test-Path -Path $x64) {$Excel64 = Get-ChildItem -Recurse -Path $x64 -Filter "EXCEL.EXE"}
if ($Excel32) {$Excel = $Excel32}
if ($Excel64) {$Excel = $Excel64}
if ($Excel32 -and $Excel64) {"Error: x32 and x64 installation found." ; $Excel32.Fullname ; $Excel64.Fullname ; $OK = $false}
if ($Excel.Count -gt 1) {"Error: More than one Excel.exe found." ; $Excel.Fullname ; $OK = $false}
if ($Excel.Count -eq 0) {"Error: Excel.exe not found." ; $OK = $false}


if ($OK) {
   $DisplayVersion = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -Name "DisplayVersion" -ErrorAction SilentlyContinue | Where-Object {$_.DisplayVersion -eq $Excel.VersionInfo.ProductVersion -and $_.PSChildName -notlike "{*}"}
   $Office = Get-ItemProperty -Path $DisplayVersion.PSPath
   $Office | ForEach-Object {"Product: " + $_.DisplayName + $(if ($_.InstallLocation -eq $x32) {", 32 Bit"} else {", 64 Bit"})  + ", Productversion: " + $_.PSChildName + ", Build: " + $_.DisplayVersion}
}