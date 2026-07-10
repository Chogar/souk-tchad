param(
  [string]$EnvFile = "mobile/.env",
  [string]$OutFile = "mobile/dart_defines.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root $EnvFile
$outPath = Join-Path $root $OutFile

$values = @{}
if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $parts = $line.Split("=", 2)
    if ($parts.Length -eq 2) {
      $values[$parts[0].Trim()] = $parts[1].Trim().Trim('"')
    }
  }
}

if (-not $values.ContainsKey("API_BASE_URL") -or [string]::IsNullOrWhiteSpace($values["API_BASE_URL"])) {
  $values["API_BASE_URL"] = "http://127.0.0.1:3000/api"
}

$json = $values | ConvertTo-Json -Compress
Set-Content -Path $outPath -Value $json -Encoding UTF8
Write-Host "dart_defines.json -> $($values['API_BASE_URL'])"
