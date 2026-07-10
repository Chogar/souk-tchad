# Builds release Souk Tchad (Windows)
# Prealables :
#   1. Copier mobile/.env.production.example -> mobile/.env.production et renseigner
#   2. powershell -File scripts/write-dart-defines.ps1 -EnvFile mobile/.env.production
#   3. (Android) powershell -File scripts/generate-android-keystore.ps1
#   4. Backend prod accessible en HTTPS

param(
  [ValidateSet("android", "web", "all")]
  [string]$Target = "all"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "mobile"
$defines = Join-Path $mobile "dart_defines.json"

if (-not (Test-Path $defines)) {
  Write-Host "Generation dart_defines.json..."
  & (Join-Path $PSScriptRoot "write-dart-defines.ps1") -EnvFile "mobile/.env.production"
}

Set-Location $mobile
$env:Path = "C:\Users\admin\flutter\bin;" + $env:Path

if ($Target -eq "android" -or $Target -eq "all") {
  Write-Host "==> App Bundle Android"
  flutter build appbundle --release --dart-define-from-file=dart_defines.json
}

if ($Target -eq "web" -or $Target -eq "all") {
  Write-Host "==> Web release"
  flutter build web --release --dart-define-from-file=dart_defines.json
}

Write-Host "Termine. Artefacts dans mobile/build/"
