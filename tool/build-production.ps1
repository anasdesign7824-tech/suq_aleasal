[CmdletBinding()]
param(
  [string]$Flutter = "D:\DevTools\Flutter\bin\flutter.bat",
  [switch]$NoSplit
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repoRoot "apps\mobile_flutter"
$definesPath = Join-Path $repoRoot "assalkom.production.defines.json"

if (-not (Test-Path $Flutter)) {
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if ($null -eq $flutterCommand) { throw "Flutter executable was not found. Pass -Flutter." }
  $Flutter = $flutterCommand.Source
}
if (-not (Test-Path $definesPath)) { throw "Production defines file was not found: $definesPath" }

$defines = Get-Content -Raw -Path $definesPath | ConvertFrom-Json
if ($defines.ASSALKOM_MODE -ne "production") { throw "Defines file is not production mode." }
if ($defines.ASSALKOM_SUPABASE_URL -notmatch '^https://[a-z0-9]+\.supabase\.co$') { throw "Supabase URL is invalid." }
if ($defines.ASSALKOM_SUPABASE_PUBLISHABLE_KEY -notmatch '^sb_publishable_.+') { throw "Supabase publishable key is invalid." }

Push-Location $project
try {
  $args = @(
    "build", "apk", "--release",
    "--target-platform", "android-arm64",
    "--dart-define-from-file=$definesPath"
  )
  if (-not $NoSplit) { $args += "--split-per-abi" }
  Write-Host "Production build gate passed. Mode=production; Supabase URL=$($defines.ASSALKOM_SUPABASE_URL)"
  & $Flutter @args
  if ($LASTEXITCODE -ne 0) { throw "Flutter Production build failed with exit code $LASTEXITCODE." }

  $apk = if ($NoSplit) {
    Join-Path $project "build\app\outputs\flutter-apk\app-release.apk"
  } else {
    Join-Path $project "build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
  }
  if (-not (Test-Path $apk)) { throw "Production APK was not produced at: $apk" }
  $hash = (Get-FileHash -Algorithm SHA256 -Path $apk).Hash.ToLowerInvariant()
  Write-Host "Production APK: $apk"
  Write-Host "SHA256: $hash"
} finally {
  Pop-Location
}
