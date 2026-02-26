param(
    [ValidateSet("start","stop","restart","status")]
    [string]$Command = "start"
)

$ErrorActionPreference = "Stop"

$Root    = Resolve-Path (Join-Path $PSScriptRoot "..")
$DevDir  = Join-Path $Root ".dev"
$LogDir  = Join-Path $DevDir "logs"
$State   = Join-Path $DevDir "state.json"

New-Item -ItemType Directory -Force $LogDir | Out-Null

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
    $port = 34872
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

    if (!(Test-Path (Join-Path $Root "default.project.json"))) {
        throw "Не найден default.project.json в корне проекта: $Root"
    }

    $mise = (Get-Command mise -ErrorAction SilentlyContinue).Source
    if (-not $mise) { throw "Не найден mise в PATH. Запусти из pwsh или поправь PATH." }

    # deps only if Packages missing
    if (!(Test-Path (Join-Path $Root "Packages"))) {
        Write-Host "Packages/ не найден. Запускаю wally install..."
        & $mise install | Out-Host
        & $mise x -- wally install | Out-Host
    }

    $RojoOut = Join-Path $LogDir "rojo-serve.out.log"
    $RojoErr = Join-Path $LogDir "rojo-serve.err.log"
    $SmOut   = Join-Path $LogDir "sourcemap-watch.out.log"
    $SmErr   = Join-Path $LogDir "sourcemap-watch.err.log"

    # ВАЖНО: запускаем детей через powershell.exe (тот же движок), чтобы проще было с окружением IDE.
    # Не важно 5.1 или 7 — нам нужен один "родитель", который их держит.
    $Shell = (Get-Command powershell -ErrorAction SilentlyContinue).Source
    if (-not $Shell) { throw "Не найден powershell.exe" }

    $RojoProc = Start-Process -PassThru -WindowStyle Minimized `
        -FilePath $Shell `
        -ArgumentList @(
        "-NoLogo", "-NoProfile",
        "-Command",
        "Set-Location -LiteralPath `"$Root`"; & `"$mise`" x -- rojo serve default.project.json"
    ) `
        -RedirectStandardOutput $RojoOut `
        -RedirectStandardError  $RojoErr

    $SmProc = Start-Process -PassThru -WindowStyle Minimized `
        -FilePath $Shell `
        -ArgumentList @(
        "-NoLogo", "-NoProfile",
        "-Command",
        "Set-Location -LiteralPath `"$Root`"; & `"$mise`" x -- rojo sourcemap --watch default.project.json --output sourcemap.json"
    ) `
        -RedirectStandardOutput $SmOut `
        -RedirectStandardError  $SmErr

    Save-State @{
        started   = (Get-Date).ToString("o")
        rojoServe = $RojoProc.Id
        sourcemap = $SmProc.Id
        logs      = @{
            rojoServeOut = $RojoOut
            rojoServeErr = $RojoErr
            sourcemapOut = $SmOut
            sourcemapErr = $SmErr
        }
    }

    Write-Host "Dev started:"
    Write-Host "  rojoServe PID=$($RojoProc.Id)"
    Write-Host "  sourcemap PID=$($SmProc.Id)"
    Write-Host "Logs: $LogDir"
    Write-Host ""
    Write-Host "Открой Roblox Studio -> Rojo plugin -> Connect."
    Write-Host "Чтобы остановить: нажми Stop в IDE или Ctrl+C в терминале."

    # Родительский процесс висит и ждёт, пока ты нажмёшь Stop/Ctrl+C
    try {
        while ($true) {
            Start-Sleep -Seconds 1

            # если один из детей умер — подсказать
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
        # если уже бежит — делаем restart (чтобы не плодить висяки)
        $st = Get-RunningState
        if ($st) {
            Write-Host "Already running -> restarting..."
            Stop-Pids $st
            if (Test-Path $State) { Remove-Item $State -Force -ErrorAction SilentlyContinue }
        }
        Start-Dev
    }
}