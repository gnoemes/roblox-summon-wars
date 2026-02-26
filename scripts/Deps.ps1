$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

& mise install | Out-Host
& wally install | Out-Host
Write-Host "OK."