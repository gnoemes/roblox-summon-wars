$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

$DevDir = Join-Path $Root ".dev"
$LogDir = Join-Path $DevDir "logs"
New-Item -ItemType Directory -Force $LogDir | Out-Null

$ProjectFile = Join-Path $Root "default.project.json"
if (!(Test-Path $ProjectFile)) {
    throw "Не найден default.project.json в корне проекта: $Root"
}

# ---- Resolve pwsh path (PowerShell 7) ----
$Pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $Pwsh) {
    $candidates = @(
        "C:\Program Files\PowerShell\7\pwsh.exe",
        "C:\Program Files\PowerShell\7-preview\pwsh.exe"
    )
    $Pwsh = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Pwsh) {
    throw "Не найден pwsh.exe. Проверь установку PowerShell 7 или PATH."
}

# ---- Resolve mise path ----
$Mise = (Get-Command mise -ErrorAction SilentlyContinue).Source
if (-not $Mise) {
    throw "Не найден mise в PATH для текущего shell. Запусти скрипт из pwsh или добавь mise в PATH."
}

# Если нет Packages — зависимости не установлены
if (!(Test-Path (Join-Path $Root "Packages"))) {
    Write-Host "Packages/ не найден. Запускаю wally install..."
    & $Mise install | Out-Host
    & $Mise x -- wally install | Out-Host
}

$RojoOut = Join-Path $LogDir "rojo-serve.out.log"
$RojoErr = Join-Path $LogDir "rojo-serve.err.log"
$SmOut   = Join-Path $LogDir "sourcemap-watch.out.log"
$SmErr   = Join-Path $LogDir "sourcemap-watch.err.log"

# Rojo serve
$RojoProc = Start-Process -PassThru -WindowStyle Minimized `
    -FilePath $Pwsh `
    -ArgumentList @(
    "-NoLogo", "-NoProfile",
    "-Command",
    "Set-Location -LiteralPath `"$Root`"; & `"$Mise`" x -- rojo serve default.project.json"
) `
    -RedirectStandardOutput $RojoOut `
    -RedirectStandardError  $RojoErr

# Sourcemap watch
$SmProc = Start-Process -PassThru -WindowStyle Minimized `
    -FilePath $Pwsh `
    -ArgumentList @(
    "-NoLogo", "-NoProfile",
    "-Command",
    "Set-Location -LiteralPath `"$Root`"; & `"$Mise`" x -- rojo sourcemap --watch default.project.json --output sourcemap.json"
) `
    -RedirectStandardOutput $SmOut `
    -RedirectStandardError  $SmErr

@{
    started   = (Get-Date).ToString("o")
    rojoServe = $RojoProc.Id
    sourcemap = $SmProc.Id
    logs      = @{
        rojoServeOut = $RojoOut
        rojoServeErr = $RojoErr
        sourcemapOut = $SmOut
        sourcemapErr = $SmErr
    }
} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $DevDir "pids.json") -Encoding UTF8

Write-Host "OK. Rojo serve PID=$($RojoProc.Id), Sourcemap PID=$($SmProc.Id)"
Write-Host "Логи: $LogDir"
Write-Host "Дальше: Roblox Studio -> Rojo plugin -> Connect."