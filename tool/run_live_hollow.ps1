# Extracts GEMINI_API_KEY from Cursor terminal metadata (if present) and runs live hollow check.
$ErrorActionPreference = 'Stop'
$termDir = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal\terminals'
$key = $null
Get-ChildItem $termDir -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
  $hit = Select-String -Path $_.FullName -Pattern 'GEMINI_API_KEY=([^\s]+)' | Select-Object -First 1
  if ($hit -and $hit.Matches.Count -gt 0) {
    $key = $hit.Matches[0].Groups[1].Value
  }
}
if (-not $key) {
  # Fall back: scan recent agent transcript for dart-define (same local machine session).
  $transcripts = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal\agent-transcripts'
  $hit = Get-ChildItem $transcripts -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 3 |
    ForEach-Object { Select-String -Path $_.FullName -Pattern 'GEMINI_API_KEY=([^\s\\"]+)' | Select-Object -First 1 } |
    Select-Object -First 1
  if ($hit -and $hit.Matches.Count -gt 0) {
    $key = $hit.Matches[0].Groups[1].Value
  }
}
if (-not $key) {
  Write-Error 'GEMINI_API_KEY not found in terminals/transcripts'
  exit 2
}
Set-Location (Split-Path $PSScriptRoot -Parent)
flutter run -d windows -t tool/live_hollow_main.dart --dart-define=GEMINI_API_KEY=$key
