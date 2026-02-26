$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$PidsPath = Join-Path $Root ".dev\pids.json"

if (!(Test-Path $PidsPath)) {
    Write-Host "Нет .dev\pids.json — нечего останавливать."
    exit 0
}

$pids = Get-Content $PidsPath -Raw | ConvertFrom-Json

foreach ($name in @("rojoServe", "sourcemap")) {
    $procId = $pids.$name
    if ($procId -and (Get-Process -Id $procId -ErrorAction SilentlyContinue)) {
        Write-Host "Stopping $name (PID=$procId)..."
        Stop-Process -Id $procId -Force
    } else {
        Write-Host "$name уже не запущен."
    }
}

Remove-Item $PidsPath -Force
Write-Host "OK."