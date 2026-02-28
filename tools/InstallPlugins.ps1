param()

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$Src  = Join-Path $Root "plugins"
$Dst  = Join-Path $env:LOCALAPPDATA "Roblox\Plugins\IncubatorZero"

New-Item -ItemType Directory -Force $Dst | Out-Null

Get-ChildItem $Src -Filter "*.plugin.lua" -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $Dst $_.Name) -Force
}

Write-Host "Installed plugins to: $Dst"
Write-Host "Restart Roblox Studio to load them."