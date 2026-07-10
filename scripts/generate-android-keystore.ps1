# Genere le keystore Android d'upload (une seule fois).
# Usage (PowerShell) :
#   cd mobile/android
#   powershell -ExecutionPolicy Bypass -File ../../scripts/generate-android-keystore.ps1

$ErrorActionPreference = "Stop"
$androidDir = Join-Path (Split-Path -Parent $PSScriptRoot) "mobile\android"
$keystoreDir = Join-Path $androidDir "keystore"
$jks = Join-Path $keystoreDir "souk-tchad-upload.jks"
$props = Join-Path $androidDir "key.properties"

New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

if (Test-Path $jks) {
  Write-Host "Keystore deja present : $jks"
  exit 0
}

$chars = (48..57) + (65..90) + (97..122)
$pass = -join ($chars | Get-Random -Count 24 | ForEach-Object { [char]$_ })

keytool -genkeypair -v `
  -keystore $jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias souk-tchad `
  -storepass $pass `
  -keypass $pass `
  -dname "CN=Souk Tchad, OU=Mobile, O=Experience Tech, L=Ndjamena, ST=Chad, C=TD"

@"
storePassword=$pass
keyPassword=$pass
keyAlias=souk-tchad
storeFile=keystore/souk-tchad-upload.jks
"@ | Set-Content -Path $props -Encoding UTF8

Write-Host "Keystore cree : $jks"
Write-Host "Secrets ecrits dans key.properties (NE PAS committer)."
Write-Host "Sauvegardez le mot de passe hors du depot."
