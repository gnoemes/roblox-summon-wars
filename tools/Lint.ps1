$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

& mise install | Out-Host
& mise x -- selene src | Out-Host
Write-Host "Lint OK."