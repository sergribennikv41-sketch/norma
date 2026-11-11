$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$versionLine = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$version = if ($versionLine) {
    ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]
} else {
    '0.0.0'
}

flutter build windows --release

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$zip = Join-Path $dist "norma-$version-windows-x64-portable.zip"
if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $root 'build\windows\x64\runner\Release\*') -DestinationPath $zip -Force
Write-Output $zip
