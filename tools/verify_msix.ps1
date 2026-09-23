<#
Installs an MSIX, launches it, and checks the game actually came up. For CI
(windows-latest runs as admin); on a desktop it needs an elevated shell.

  powershell -File tools/verify_msix.ps1 -Msix build/msix/PathOfLeashResistance-1.55.0.0.msix

The Store upload stays unsigned. This signs a COPY with a throwaway
self-signed certificate whose subject is the manifest's Publisher, trusts it
machine-wide, installs, launches through the package's app entry (so the exe
runs packaged, with MSIX file-system virtualization), then reads Godot's own
log from the package's private AppData. The log existing there proves the
game started and that user:// writes land in the virtualized location.

Exits non-zero on: install failure, the process dying early, no log, or a
script/parse error in the log.
#>
param(
  [Parameter(Mandatory = $true)][string]$Msix,
  [int]$RunSeconds = 25,
  [string]$OutDir = "build/msix-verify"
)
$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

function Find-SdkTool([string]$name) {
  $kits = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
  $t = Get-ChildItem -Path $kits -Recurse -Filter $name -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\' } |
    Sort-Object { [version]($_.FullName -replace '.*\\bin\\([\d.]+)\\.*', '$1') } -Descending |
    Select-Object -First 1
  if ($null -eq $t) { throw "$name not found under $kits" }
  return $t.FullName
}

# read Publisher and Name from the package itself, so this can never test a
# different identity than the one being shipped
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Msix).Path)
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq "AppxManifest.xml" }
  $reader = New-Object System.IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8)
  [xml]$manifest = $reader.ReadToEnd()
  $reader.Close()
} finally { $zip.Dispose() }
$publisher = $manifest.Package.Identity.Publisher
$name = $manifest.Package.Identity.Name
$appId = $manifest.Package.Applications.Application.Id
Write-Host "Package $name $($manifest.Package.Identity.Version), publisher $publisher"

# sign a copy for the local install
$signed = Join-Path $OutDir "signed-test.msix"
Copy-Item $Msix $signed -Force
$cert = New-SelfSignedCertificate -Type Custom -Subject $publisher -KeyUsage DigitalSignature `
  -FriendlyName "leash msix test" -CertStoreLocation "Cert:\CurrentUser\My" `
  -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
$pw = ConvertTo-SecureString -String ([guid]::NewGuid().ToString()) -Force -AsPlainText
$pfx = Join-Path $OutDir "test.pfx"
Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $pw | Out-Null
$cer = Join-Path $OutDir "test.cer"
Export-Certificate -Cert $cert -FilePath $cer | Out-Null
Import-Certificate -FilePath $cer -CertStoreLocation "Cert:\LocalMachine\TrustedPeople" | Out-Null
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw))
& (Find-SdkTool "signtool.exe") sign /fd SHA256 /f $pfx /p $plain $signed
if ($LASTEXITCODE -ne 0) { throw "signtool failed ($LASTEXITCODE)" }
Remove-Item $pfx

Add-AppxPackage -Path $signed
$pkg = Get-AppxPackage -Name $name
if ($null -eq $pkg) { throw "Package $name did not install" }
Write-Host "Installed $($pkg.PackageFullName) at $($pkg.InstallLocation)"

$failed = $false
try {
  Start-Process "explorer.exe" "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
  $proc = $null
  for ($i = 0; $i -lt 30 -and $null -eq $proc; $i++) {
    Start-Sleep -Seconds 1
    $proc = Get-Process -Name "PathOfLeashResistance" -ErrorAction SilentlyContinue | Select-Object -First 1
  }
  if ($null -eq $proc) { throw "The game process never started" }
  Write-Host "Running from $($proc.Path)"
  if ($proc.Path -notlike "*WindowsApps*") { throw "The game is not running from the package ($($proc.Path))" }
  Start-Sleep -Seconds $RunSeconds
  if ($proc.HasExited) {
    Write-Host "The game exited early with code $($proc.ExitCode)"
    $failed = $true
  } else {
    Stop-Process -Id $proc.Id -Force
  }

  # Godot's file log, redirected by MSIX into the package's private AppData
  $log = Get-ChildItem -Path (Join-Path $env:LOCALAPPDATA "Packages\$($pkg.PackageFamilyName)") `
    -Recurse -Filter "godot*.log" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($null -eq $log) {
    Write-Host "No Godot log under the package's AppData: the game did not start, or user:// is not virtualized"
    $failed = $true
  } else {
    Write-Host "Log: $($log.FullName)"
    Copy-Item $log.FullName (Join-Path $OutDir "godot.log")
    Get-Content $log.FullName | Select-Object -First 40
    if (Select-String -Path $log.FullName -Pattern "SCRIPT ERROR|Parse Error|Failed to load script" -Quiet) {
      Write-Host "Script errors in the packaged run"
      $failed = $true
    }
  }
} finally {
  Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
  Get-ChildItem "Cert:\LocalMachine\TrustedPeople" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Remove-Item
  Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"
}
if ($failed) { exit 1 }
Write-Host "MSIX VERIFY OK"
