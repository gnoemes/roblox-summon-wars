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

# Если нет Packages — зависимости не установлены (или ты их удалил)
if (!(Test-Path (Join-Path $Root "Packages"))) {
    Write-Host "Packages/ не найден. Запускаю wally install..."
    & mise install | Out-Host
    & mise x -- wally install | Out-Host
}

$RojoLog = Join-Path $LogDir "rojo-serve.log"
$SourcemapLog = Join-Path $LogDir "sourcemap-watch.log"

# Rojo serve
$RojoProc = Start-Process -PassThru -WindowStyle Minimized `
    -FilePath "pwsh" `
    -ArgumentList @(
        "-NoLogo", "-NoProfile",
        "-Command",
        "Set-Location -LiteralPath `"$Root`"; mise x -- rojo serve default.project.json"
    ) `
    -RedirectStandardOutput $RojoLog `
    -RedirectStandardError $RojoLog

# Sourcemap watch (для Luau LSP / IntelliJ Luau plugin)
$SmProc = Start-Process -PassThru -WindowStyle Minimized `
    -FilePath "pwsh" `
    -ArgumentList @(
        "-NoLogo", "-NoProfile",
        "-Command",
        "Set-Location -LiteralPath `"$Root`"; mise x -- rojo sourcemap --watch default.project.json --output sourcemap.json"
    ) `
    -RedirectStandardOutput $SourcemapLog `
    -RedirectStandardError $SourcemapLog

@{
    started   = (Get-Date).ToString("o")
    rojoServe = $RojoProc.Id
    sourcemap = $SmProc.Id
    logs      = @{
        rojoServe = $RojoLog
        sourcemap = $SourcemapLog
    }
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $DevDir "pids.json") -Encoding UTF8

Write-Host "OK. Rojo serve PID=$($RojoProc.Id), Sourcemap PID=$($SmProc.Id)"
Write-Host "Логи: $LogDir"
Write-Host "Дальше: открой Roblox Studio -> Rojo plugin -> Connect."