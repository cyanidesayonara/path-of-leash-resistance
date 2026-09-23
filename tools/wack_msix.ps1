<#
Runs the Windows App Certification Kit on an MSIX and prints every test.

  powershell -File tools/wack_msix.ps1 -Msix build/msix/PathOfLeashResistance-1.55.0.0.msix

Needs admin (windows-latest runs as admin). Fails only when the overall
result is FAIL; WARNING means only optional tests failed. Two results are
expected on every Godot build and do not block certification:

- "Blocked executables" (optional): the engine binary references
  CreateProcessW/ShellExecuteW and names like cmd and reg, for OS.execute
  and OS.shell_open. Only matters for Windows 10 S mode.
- "DPIAwarenessValidation" (warning): Godot turns on per-monitor DPI
  awareness at runtime, which a static scan of the exe cannot see.
#>
param(
  [Parameter(Mandatory = $true)][string]$Msix,
  [string]$Report = "build/wack/report.xml"
)
$ErrorActionPreference = "Stop"

$appcert = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\App Certification Kit\appcert.exe"
if (-not (Test-Path $appcert)) { throw "appcert.exe not found; install the Windows SDK's App Certification Kit" }

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Report) | Out-Null
$Report = Join-Path (Resolve-Path (Split-Path -Parent $Report)).Path (Split-Path -Leaf $Report)
if (Test-Path $Report) { Remove-Item $Report }

& $appcert reset | Out-Null
& $appcert test -appxpackagepath (Resolve-Path $Msix).Path -reportoutputpath $Report | Out-Null
if (-not (Test-Path $Report)) { throw "WACK wrote no report" }

[xml]$r = Get-Content $Report -Encoding UTF8
$overall = $r.REPORT.OVERALL_RESULT
foreach ($t in $r.SelectNodes("//TEST")) {
  $result = $t.RESULT.'#cdata-section'
  if (-not $result) { $result = $t.RESULT }
  $opt = if ($t.OPTIONAL -eq "TRUE") { " (optional)" } else { "" }
  "{0,-8} {1}{2}" -f $result, $t.NAME, $opt
  if ($result -ne "PASS") {
    foreach ($m in $t.SelectNodes(".//MESSAGE")) { "         " + $m.TEXT }
  }
}
Write-Host "WACK overall: $overall"
if ($overall -eq "FAIL") { exit 1 }
