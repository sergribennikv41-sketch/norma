param(
    [Parameter(Mandatory = $true)][string]$PfxPath,
    [string]$PfxPassword = $env:NORMA_PFX_PASSWORD,
    [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrEmpty($PfxPassword)) {
    throw 'Set -PfxPassword or the NORMA_PFX_PASSWORD environment variable.'
}

$kitsRoot = 'C:\Program Files (x86)\Windows Kits\10\bin'
$signtool = Get-ChildItem -LiteralPath $kitsRoot -Recurse -Filter 'signtool.exe' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if (-not $signtool) {
    throw 'signtool.exe not found. Install the Windows SDK.'
}
if (-not (Test-Path -LiteralPath $PfxPath)) {
    throw "PFX not found: $PfxPath"
}

$versionLine = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$version = if ($versionLine) {
    ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]
} else {
    '1.0.0'
}

$files = @(
    (Join-Path $root 'build\windows\x64\runner\Release\norma.exe'),
    (Join-Path $root "dist\norma-$version-windows-x64-setup.exe")
)

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "File not found: $file"
    }
    & $signtool.FullName sign /fd SHA256 /f $PfxPath /p $PfxPassword /tr $TimestampUrl /td SHA256 $file
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed for $file"
    }
    Write-Output "Signed: $file"
}
