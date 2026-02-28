$ErrorActionPreference = "Stop"

$Here = $PSScriptRoot

$Fmt  = Join-Path $Here "Fmt.ps1"
$Lint = Join-Path $Here "Lint.ps1"

if (!(Test-Path $Fmt))  { throw "Не найден скрипт: $Fmt" }
if (!(Test-Path $Lint)) { throw "Не найден скрипт: $Lint" }

& $Fmt
& $Lint

$Root = Resolve-Path (Join-Path $Here "..")
Set-Location $Root

# Быстрая проверка, что Rojo проект валиден и собирается
New-Item -ItemType Directory -Force (Join-Path $Root ".dev") | Out-Null
& mise x -- rojo build default.project.json --output ".dev\build.rbxm" | Out-Host

Write-Host "CHECK OK."