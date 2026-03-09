param(
	[string]$Place = "hub"
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$Here = $PSScriptRoot

$Fmt = Join-Path $Here "Fmt.ps1"
$Lint = Join-Path $Here "Lint.ps1"

if (!(Test-Path $Fmt)) {
	throw "Ne naiden skript: $Fmt"
}

if (!(Test-Path $Lint)) {
	throw "Ne naiden skript: $Lint"
}

& $Fmt
& $Lint

$Root = Resolve-Path (Join-Path $Here "..")
Set-Location $Root

$ProjectFile = Join-Path $Root ("places/{0}/default.project.json" -f $Place)
if (!(Test-Path $ProjectFile)) {
	throw "Ne naiden project json dlia place '$Place': $ProjectFile"
}

$DevRoot = Join-Path $Root ".dev"
New-Item -ItemType Directory -Force $DevRoot | Out-Null

$BuildOutput = Join-Path $DevRoot ("build.{0}.rbxm" -f $Place)
& mise x -- rojo build $ProjectFile --output $BuildOutput | Out-Host

Write-Host "CHECK OK."
