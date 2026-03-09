$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $true

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$SourceRoots = @(
	(Join-Path $Root "common"),
	(Join-Path $Root "places")
)
$DirectRequirePattern = 'require\(script\.[A-Za-z_][A-Za-z0-9_]*\)'
$ScriptWaitPattern = 'script:WaitForChild\('
$BadFlattenPattern = 'flattenArrays\(\s*\{\s*$'
$Violations = @()

Get-ChildItem -Path $SourceRoots -Recurse -Filter *.luau |
	Where-Object { $_.Name -ne "init.luau" } |
	ForEach-Object {
		$Lines = Get-Content $_.FullName
		for ($Index = 0; $Index -lt $Lines.Count; $Index += 1) {
			$LineNumber = $Index + 1
			$Line = $Lines[$Index]
			if ($Line -match $DirectRequirePattern) {
				$Violations += [PSCustomObject]@{
					Kind = "DirectSiblingRequire"
					Path = $_.FullName
					Line = $LineNumber
					Source = $Line.Trim()
				}
			}
			if ($Line -match $ScriptWaitPattern) {
				$Violations += [PSCustomObject]@{
					Kind = "ScriptWaitForChild"
					Path = $_.FullName
					Line = $LineNumber
					Source = $Line.Trim()
				}
			}
			if ($Line -match $BadFlattenPattern) {
				$Window = ($Lines[$Index..([Math]::Min($Index + 3, $Lines.Count - 1))] -join " ")
				if ($Window -match 'ContentLoader\.(requireModuleChildren|requireRegionChildModules)') {
					$Violations += [PSCustomObject]@{
						Kind = "NestedFlattenLoader"
						Path = $_.FullName
						Line = $LineNumber
						Source = $Line.Trim()
					}
				}
			}
		}
	}

if ($Violations.Count -gt 0) {
	Write-Host "RUNTIME SMOKE FAILED. Invalid module-loading patterns were found:"
	foreach ($Violation in $Violations) {
		Write-Host ("  [{0}] {1}:{2} {3}" -f $Violation.Kind, $Violation.Path, $Violation.Line, $Violation.Source)
	}
	throw "Non-init modules must use script.Parent for sibling access, and ContentLoader arrays must not be wrapped into an extra table before flattening."
}

Write-Host "RUNTIME SMOKE OK."
