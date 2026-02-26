$ErrorActionPreference = "Stop"
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

& mise install | Out-Host
& mise x -- stylua src | Out-Host
Write-Host "Formatted."