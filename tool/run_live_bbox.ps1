# Live bbox localization check using GEMINI_API_KEY from an active flutter terminal.
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
  Write-Error 'GEMINI_API_KEY not found in terminals'
  exit 2
}
Set-Location (Split-Path $PSScriptRoot -Parent)

if (-not $env:LIVE_IMAGE) {
  $env:LIVE_IMAGE = Join-Path $env:USERPROFILE '.cursor\projects\c-Users-Rutuja-Dugaje-Desktop-Shravani-thermal\assets\c__Users_Rutuja.Dugaje_AppData_Roaming_Cursor_User_workspaceStorage_704dd315a353d33d7d3404406ef76784_images_image-b23cd265-a491-4f5d-bad5-be42aedc9c6e.png'
}
if (-not $env:LIVE_TARGET) {
  $env:LIVE_TARGET = 'crack'
}

flutter run -d windows -t tool/live_bbox_main.dart --dart-define=GEMINI_API_KEY=$key
