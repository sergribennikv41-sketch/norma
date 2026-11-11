$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$versionLine = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$version = if ($versionLine) {
    ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]
} else {
    '1.0.0'
}

powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build_windows.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "Build failed with exit code $LASTEXITCODE"
}

$isccCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 7\ISCC.exe'),
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
)
$iscc = $isccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $iscc) {
    throw 'ISCC.exe not found. Install Inno Setup 6: winget install --id JRSoftware.InnoSetup -e'
}

& $iscc "/DMyAppVersion=$version" (Join-Path $root 'installer\norma.iss')
if ($LASTEXITCODE -ne 0) {
    throw "ISCC failed with exit code $LASTEXITCODE"
}

Get-Item (Join-Path $root "dist\norma-$version-windows-x64-setup.exe") | Select-Object FullName, Length
