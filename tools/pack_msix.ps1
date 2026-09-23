<#
Packs the exported Windows build into an unsigned MSIX for the Microsoft Store.

  powershell -File tools/pack_msix.ps1 -Exe build/win/PathOfLeashResistance.exe -Tag v1.55

Stages the exe with store/msix/AppxManifest.xml and store/msix/Assets, writes
the package version from the tag (v1.55 -> 1.55.0.0, v1.5.1 -> 1.5.1.0; the
Store requires the fourth part to be 0), and runs MakeAppx from the newest
Windows SDK. Writes PathOfLeashResistance-<version>.msix into -OutDir.

The package is deliberately unsigned: the Store re-signs every upload. To
install it locally, see docs/MICROSOFT_STORE.md step 4.
#>
param(
  [Parameter(Mandatory = $true)][string]$Exe,
  [Parameter(Mandatory = $true)][string]$Tag,
  [string]$OutDir = "build/msix",
  [string]$MakeAppx = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# vX.Y[.Z] -> X.Y.Z.0; anything else is refused rather than guessed at
if ($Tag -notmatch '^v?(\d+)\.(\d+)(?:\.(\d+))?$') {
  throw "Tag '$Tag' is not vX.Y or vX.Y.Z"
}
$parts = @([int]$Matches[1], [int]$Matches[2], [int]($(if ($Matches[3]) { $Matches[3] } else { 0 })))
if ($parts[0] -lt 1) { throw "The Store refuses a package version whose first part is 0" }
foreach ($p in $parts) { if ($p -gt 65535) { throw "Version part $p is over 65535" } }
$version = "{0}.{1}.{2}.0" -f $parts[0], $parts[1], $parts[2]

if (-not (Test-Path $Exe)) { throw "No exe at $Exe" }

if ($MakeAppx -eq "") {
  $kits = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
  $found = Get-ChildItem -Path $kits -Recurse -Filter makeappx.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\' } |
    Sort-Object { [version]($_.FullName -replace '.*\\bin\\([\d.]+)\\.*', '$1') } -Descending |
    Select-Object -First 1
  if ($null -eq $found) { throw "makeappx.exe not found under $kits; install the Windows SDK or pass -MakeAppx" }
  $MakeAppx = $found.FullName
}

$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("leash-msix-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stage | Out-Null
try {
  Copy-Item $Exe (Join-Path $stage "PathOfLeashResistance.exe")
  Copy-Item (Join-Path $root "store/msix/Assets") (Join-Path $stage "Assets") -Recurse

  # XmlDocument keeps the UTF-8 publisher name intact, which Get-Content and
  # Set-Content on Windows PowerShell 5.1 would not
  $xml = New-Object System.Xml.XmlDocument
  $xml.PreserveWhitespace = $true
  $xml.Load((Join-Path $root "store/msix/AppxManifest.xml"))
  $xml.Package.Identity.Version = $version
  $xml.Save((Join-Path $stage "AppxManifest.xml"))

  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
  $out = Join-Path (Resolve-Path $OutDir) "PathOfLeashResistance-$version.msix"
  & $MakeAppx pack /o /h SHA256 /d $stage /p $out
  if ($LASTEXITCODE -ne 0) { throw "MakeAppx failed with exit code $LASTEXITCODE" }
  Write-Host "MSIX $version -> $out"
} finally {
  Remove-Item -Recurse -Force $stage
}
