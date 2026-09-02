# Bumps the pubspec.yaml build number and builds a release Android App Bundle.
# Usage: powershell -File scripts\release_appbundle.ps1 [-SkipBump]
param(
    [switch]$SkipBump
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not $SkipBump) {
    Write-Host "Bumping build number in pubspec.yaml..."
    dart run tool/bump_build_number.dart
}

Write-Host "Building release App Bundle..."
flutter build appbundle --release

Write-Host "Done: build\app\outputs\bundle\release\app-release.aab"
