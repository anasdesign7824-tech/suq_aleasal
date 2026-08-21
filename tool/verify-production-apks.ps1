[CmdletBinding()]
param(
  [string]$Project = "D:\suq_aleasa\apps\mobile_flutter"
)

$ErrorActionPreference = "Stop"
$apkDir = Join-Path $Project "build\app\outputs\flutter-apk"
$expected = @(
  "app-arm64-v8a-release.apk",
  "app-armeabi-v7a-release.apk",
  "app-x86_64-release.apk"
)

if (-not (Test-Path $apkDir)) { throw "APK output directory missing: $apkDir" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$results = @()
foreach ($name in $expected) {
  $path = Join-Path $apkDir $name
  if (-not (Test-Path $path)) { throw "Missing expected ABI artifact: $name" }
  $item = Get-Item $path
  $hash = (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
  $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
  try {
    $entries = @($zip.Entries | ForEach-Object FullName)
    $nativeLibs = @($entries | Where-Object { $_ -like "lib/*/*.so" })
    $raw = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($path))
    $demoMatches = @([regex]::Matches($raw, '(?i)demo-(conversation|store|product|message|notification|merchant|request)|Demo Mode|InMemoryDemoCatalogLoader|sample[_-]?catalog|fake[_-]?catalog') | ForEach-Object Value | Select-Object -Unique)
    $expectedAbi = switch -Regex ($name) {
      "arm64" { "arm64-v8a"; break }
      "armeabi" { "armeabi-v7a"; break }
      "x86_64" { "x86_64"; break }
    }
    $abiMatch = @($nativeLibs | Where-Object { $_ -like "lib/$expectedAbi/*" }).Count -gt 0
    $otherAbiMatch = @($nativeLibs | Where-Object { $_ -match '^lib/(arm64-v8a|armeabi-v7a|x86_64)/' -and $_ -notlike "lib/$expectedAbi/*" }).Count -gt 0
    $results += [pscustomobject]@{
      Artifact = $name
      SizeBytes = $item.Length
      SHA256 = $hash
      ExpectedAbiPresent = $abiMatch
      OtherTargetAbiPresent = $otherAbiMatch
      DemoLikeRawMatches = if ($demoMatches.Count -eq 0) { "NONE" } else { ($demoMatches -join ",") }
      ZipEntries = $entries.Count
    }
  } finally {
    $zip.Dispose()
  }
}
$results | Format-List
if ($results.ExpectedAbiPresent -contains $false) { throw "At least one APK is missing its expected native ABI." }
if ($results.OtherTargetAbiPresent -contains $true) { throw "At least one split APK contains another target ABI." }
if ($results.DemoLikeRawMatches -notcontains "NONE") { throw "Demo-like strings found in APK raw bytes." }
Write-Output "VERIFY_PRODUCTION_APKS=PASS"
