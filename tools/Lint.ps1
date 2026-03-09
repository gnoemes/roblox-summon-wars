$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true
$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

& mise install | Out-Host

$Targets = @()
$CommonSource = Join-Path $Root "common/src"

if (Test-Path $CommonSource) {
	$Targets += $CommonSource
}

$PlacesRoot = Join-Path $Root "places"
if (Test-Path $PlacesRoot) {
	Get-ChildItem $PlacesRoot -Directory | ForEach-Object {
		$PlaceSource = Join-Path $_.FullName "src"
		if (Test-Path $PlaceSource) {
			$Targets += $PlaceSource
		}
	}
}

if ($Targets.Count -eq 0) {
	throw "No Luau source roots found."
}

& mise x -- selene @Targets | Out-Host
Write-Host "Lint OK."
