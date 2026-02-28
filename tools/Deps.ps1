$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

& mise install | Out-Host
& mise x -- wally install | Out-Host
Write-Host "OK."