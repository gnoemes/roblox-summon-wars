param(
    [ValidateSet("start","stop","restart","status")]
    [string]$Command = "start",

# какой place поднимать
    [ValidateSet("hub","raid")]
    [string]$Place = "hub",

# Если захочешь поднимать два плейса параллельно — запусти второй раз с другим портом
    [int]$Port = 34872
)

Write-Host "RUNNING Dev.ps1 from: $PSCommandPath"

$ErrorActionPreference = "Stop"

$Root    = Resolve-Path (Join-Path $PSScriptRoot "..")
$DevDir  = Join-Path $Root ".dev"
$LogDir  = Join-Path $DevDir "logs"

# ВАЖНО: state per-place, иначе hub и raid будут перетирать друг друга.
$State   = Join-Path $DevDir ("state.{0}.json" -f $Place)

New-Item -ItemType Directory -Force $LogDir | Out-Null

function Quote-Arg([string]$s) {
    if ($null -eq $s) { return '""' }
    # Для CreateProcess: путь с пробелами должен быть в кавычках.
    # Внутренние кавычки (если вдруг есть) экранируем.
    return '"' + ($s -replace '"', '\"') + '"'
}

function Get-RunningState {
    if (!(Test-Path $State)) { return $null }
    try { return (Get-Content $State -Raw | ConvertFrom-Json) } catch { return $null }
}

function Save-State($obj) {
    $obj | ConvertTo-Json -Depth 6 | Set-Content $State -Encoding UTF8
}

function Stop-Pids($st) {
    if (-not $st) { return }

    foreach ($n in @("rojoServe","sourcemap")) {
        $procId = $st.$n
        if ($procId -and (Get-Process -Id $procId -ErrorAction SilentlyContinue)) {
            Write-Host "Stopping $n (PID=$procId)..."
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
        }
    }

    # Добиваем всё, что слушает Rojo порт (страховка от "старых" процессов)
    $port = if ($st.port) { [int]$st.port } else { 34872 }
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conns) {
        $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($p in $pids) {
            $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host ("Killing listener on port {0}: {1} (PID={2})" -f $port, $proc.ProcessName, $p)
                Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Start-Dev {
    Set-Location $Root

    $ProjectFile = Join-Path $Root ("places/{0}/default.project.json" -f $Place)
    if (!(Test-Path $ProjectFile)) {
        throw "Не найден project json для place '$Place': $ProjectFile"
    }

    $mise = (Get-Command mise -ErrorAction SilentlyContinue).Source
    if (-not $mise) { throw "Не найден mise в PATH. Запусти из pwsh или поправь PATH." }

    # deps only if Packages missing
    if (!(Test-Path (Join-Path $Root "Packages"))) {
        Write-Host "Packages/ не найден. Запускаю wally install..."
        & $mise install | Out-Host
        & $mise x -- wally install | Out-Host
    }

    $RojoOut = Join-Path $LogDir ("rojo-serve.{0}.out.log" -f $Place)
    $RojoErr = Join-Path $LogDir ("rojo-serve.{0}.err.log" -f $Place)
    $SmOut   = Join-Path $LogDir ("sourcemap-watch.{0}.out.log" -f $Place)
    $SmErr   = Join-Path $LogDir ("sourcemap-watch.{0}.err.log" -f $Place)

    $SourcemapOutFile = Join-Path $Root (".dev/sourcemap.{0}.json" -f $Place)

    # Принудительно квотим пути (из-за пробелов в "Roblox Projects")
    $ProjectArg   = Quote-Arg $ProjectFile
    $SourcemapArg = Quote-Arg $SourcemapOutFile

    Write-Host "Starting dev:"
    Write-Host "  place=$Place port=$Port"
    Write-Host "  project=$ProjectFile"
    Write-Host "  sourcemap=$SourcemapOutFile"
    Write-Host ""
    Write-Host "MISE: $mise"
    Write-Host "PROJECT: [$ProjectFile]"
    Write-Host "ROOT: [$Root]"
    Write-Host ""

    Write-Host "ARGS serve:"
    @("x","--","rojo","serve","--port","$Port",$ProjectArg) | ForEach-Object { Write-Host "  $_" }

    Write-Host "ARGS sourcemap:"
    @("x","--","rojo","sourcemap","--watch","--output",$SourcemapArg,$ProjectArg) | ForEach-Object { Write-Host "  $_" }

    # ✅ Запускаем mise напрямую (без powershell -Command), и даём ему уже квотнутые пути.
    # ВНИМАНИЕ: project аргумент должен быть ПОСЛЕДНИМ, иначе rojo ругается.
    $RojoProc = Start-Process -PassThru -WindowStyle Minimized `
        -WorkingDirectory $Root `
        -FilePath $mise `
        -ArgumentList @(
        "x","--","rojo","serve",
        "--port", "$Port",
        $ProjectArg
    ) `
        -RedirectStandardOutput $RojoOut `
        -RedirectStandardError  $RojoErr

    $SmProc = Start-Process -PassThru -WindowStyle Minimized `
        -WorkingDirectory $Root `
        -FilePath $mise `
        -ArgumentList @(
        "x","--","rojo","sourcemap",
        "--watch",
        "--output", $SourcemapArg,
        $ProjectArg
    ) `
        -RedirectStandardOutput $SmOut `
        -RedirectStandardError  $SmErr

    Save-State @{
        started   = (Get-Date).ToString("o")
        place     = $Place
        port      = $Port
        project   = $ProjectFile
        rojoServe = $RojoProc.Id
        sourcemap = $SmProc.Id
        logs      = @{
            rojoServeOut = $RojoOut
            rojoServeErr = $RojoErr
            sourcemapOut = $SmOut
            sourcemapErr = $SmErr
        }
    }

    Write-Host ""
    Write-Host "Dev started:"
    Write-Host "  rojoServe PID=$($RojoProc.Id)"
    Write-Host "  sourcemap PID=$($SmProc.Id)"
    Write-Host "Logs: $LogDir"
    Write-Host ""
    Write-Host "Открой Roblox Studio -> Rojo plugin -> Connect."

    try {
        while ($true) {
            Start-Sleep -Seconds 1

            $a = Get-Process -Id $RojoProc.Id -ErrorAction SilentlyContinue
            $b = Get-Process -Id $SmProc.Id -ErrorAction SilentlyContinue
            if (-not $a) { Write-Host "WARNING: rojo serve остановился. См. $RojoErr" }
            if (-not $b) { Write-Host "WARNING: sourcemap watch остановился. См. $SmErr" }
        }
    }
    finally {
        Write-Host "Stopping dev processes..."
        $st = Get-RunningState
        Stop-Pids $st
        if (Test-Path $State) { Remove-Item $State -Force -ErrorAction SilentlyContinue }
        Write-Host "Stopped."
    }
}

switch ($Command) {
    "status" {
        $st = Get-RunningState
        if (-not $st) { Write-Host "Not running."; exit 0 }
        Write-Host ("Started: " + $st.started)
        Write-Host ("Place:   " + $st.place)
        Write-Host ("Port:    " + $st.port)
        Write-Host ("Project: " + $st.project)
        foreach ($n in @("rojoServe","sourcemap")) {
            $procId = $st.$n
            $alive = $false
            if ($procId -and (Get-Process -Id $procId -ErrorAction SilentlyContinue)) { $alive = $true }
            Write-Host ("  {0}: PID={1} alive={2}" -f $n, $procId, $alive)
        }
        exit 0
    }

    "stop" {
        $st = Get-RunningState
        Stop-Pids $st
        if (Test-Path $State) { Remove-Item $State -Force -ErrorAction SilentlyContinue }
        Write-Host "Stopped."
        exit 0
    }

    "restart" {
        $st = Get-RunningState
        Stop-Pids $st
        if (Test-Path $State) { Remove-Item $State -Force -ErrorAction SilentlyContinue }
        Start-Dev
    }

    default { # start
        $st = Get-RunningState
        if ($st) {
            Write-Host "Already running -> restarting..."
            Stop-Pids $st
            if (Test-Path $State) { Remove-Item $State -Force -ErrorAction SilentlyContinue }
        }
        Start-Dev
    }
}