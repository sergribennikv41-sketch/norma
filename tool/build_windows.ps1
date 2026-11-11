$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$versionLine = Select-String -Path (Join-Path $root 'pubspec.yaml') -Pattern '^version:\s*(\S+)' | Select-Object -First 1
$version = if ($versionLine) {
    ($versionLine.Matches[0].Groups[1].Value -split '\+')[0]
} else {
    '0.0.0'
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    $flutterPath = Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat'
    if (Test-Path -LiteralPath $flutterPath) {
        $flutter = $flutterPath
    } else {
        throw 'flutter not found. Add Flutter bin to PATH.'
    }
}

& $flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    throw "flutter build failed with exit code $LASTEXITCODE"
}

$release = Join-Path $root 'build\windows\x64\runner\Release'
Copy-Item -LiteralPath (Join-Path $root 'tool\price_lookup.py') -Destination (Join-Path $release 'price_lookup.py') -Force

$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$zip = Join-Path $dist "norma-$version-windows-x64-portable.zip"
if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $root 'build\windows\x64\runner\Release\*') -DestinationPath $zip -Force
Write-Output $zip
