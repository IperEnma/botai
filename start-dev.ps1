# Levanta Docker (Postgres), backend Spring Boot y frontend Flutter como web-server (Windows).
# El front NO abre Chrome: sirve en http://127.0.0.1:<WebPort> y abris el navegador a mano.
# Uso: .\start-dev.ps1 [-SkipDocker] [-BackendOnly] [-FrontendOnly] [-WebPort 5173]

param(
    [switch]$SkipDocker,
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [int]$WebPort = 5173,
    [string]$WebHost = "127.0.0.1"
)

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

# Docker escribe avisos en stderr; con Stop eso no debe abortar el script (solo el exit code).
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Invoke-Docker {
    param([Parameter(Mandatory)][string[]]$ArgumentList)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & docker @ArgumentList
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Invoke-DockerQuiet {
    param([Parameter(Mandatory)][string[]]$ArgumentList)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & docker @ArgumentList 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-DockerDaemon {
    if (-not (Test-Command "docker")) {
        throw "No se encontro 'docker' en PATH. Instala Docker Desktop o usa -SkipDocker."
    }
    $code = Invoke-DockerQuiet -ArgumentList @("info")
    if ($code -ne 0) {
        throw "Docker no responde. Abre Docker Desktop y vuelve a ejecutar: .\start-dev.ps1"
    }
}

function Invoke-DockerComposeUp {
    Push-Location $RepoRoot
    try {
        Write-Host "  docker compose up -d" -ForegroundColor DarkGray
        $code = Invoke-Docker -ArgumentList @("compose", "up", "-d")
        if ($code -ne 0 -and (Test-Command "docker-compose")) {
            Write-Host "  Reintentando con docker-compose (v1)..." -ForegroundColor DarkGray
            $prevEap = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            try {
                & docker-compose up -d
                $code = $LASTEXITCODE
            } finally {
                $ErrorActionPreference = $prevEap
            }
        }
        if ($code -ne 0) {
            throw "docker compose up -d fallo (exit $code)."
        }
    } finally {
        Pop-Location
    }
}

function Wait-PostgresReady {
    param([int]$MaxSeconds = 90)
    $deadline = (Get-Date).AddSeconds($MaxSeconds)
    while ((Get-Date) -lt $deadline) {
        $healthy = & {
            $ErrorActionPreference = "Continue"
            docker inspect --format='{{.State.Health.Status}}' chatbot-postgres 2>$null
        }
        if ($healthy -eq "healthy") {
            return $true
        }
        $running = & {
            $ErrorActionPreference = "Continue"
            docker inspect --format='{{.State.Running}}' chatbot-postgres 2>$null
        }
        if ($running -eq "true") {
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $tcp.Connect("127.0.0.1", 5444)
                $tcp.Close()
                return $true
            } catch { }
        }
        Write-Host "  Esperando Postgres (chatbot-postgres)..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 3
    }
    return $false
}

function Get-FlutterWebServerCommand {
    param([int]$Port, [string]$HostName)
    # -d web-server: servidor HTTP embebido (no flutter run -d chrome).
    return "flutter pub get; flutter run -d web-server --web-port=$Port --web-hostname=$HostName"
}

function Ensure-FrontendEnv {
    $envFile = Join-Path $RepoRoot "frontend\.env"
    $example = Join-Path $RepoRoot "frontend\.env.example"
    if (-not (Test-Path $envFile) -and (Test-Path $example)) {
        Copy-Item $example $envFile
        Write-Host "  Creado frontend\.env desde .env.example" -ForegroundColor Yellow
    }
}

function Start-InNewWindow {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command
    )
    $wd = (Resolve-Path $WorkingDirectory).Path
    $escaped = $Command -replace "'", "''"
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "`$Host.UI.RawUI.WindowTitle = '$Title'; Set-Location '$wd'; $escaped"
    ) | Out-Null
}

Write-Host ""
Write-Host "  BotAI - entorno de desarrollo" -ForegroundColor Green
Write-Host "  Repo: $RepoRoot" -ForegroundColor Green
Write-Host ""

if (-not $FrontendOnly) {
    if (-not (Test-Command "java")) { throw "No se encontro 'java' en PATH (Java 17+)." }
    if (-not (Test-Command "mvn")) { throw "No se encontro 'mvn' en PATH (Maven)." }
}

if (-not $BackendOnly) {
    if (-not (Test-Command "flutter")) { throw "No se encontro 'flutter' en PATH." }
}

if (-not $SkipDocker) {
    Write-Step "Docker Compose - Postgres (chatbot-postgres)"
    Ensure-DockerDaemon
    Invoke-DockerComposeUp
    if (-not (Wait-PostgresReady)) {
        throw "Postgres no quedo listo. Revisa: docker logs chatbot-postgres"
    }
    Write-Host "  Postgres OK en localhost:5444 (user/pass/db: chatbot)" -ForegroundColor Green
} elseif (-not $FrontendOnly) {
    Write-Host ""
    Write-Host "==> Docker omitido (-SkipDocker). Backend asume Postgres en localhost:5444." -ForegroundColor Yellow
}

if (-not $FrontendOnly) {
    $backendEnv = Join-Path $RepoRoot "backend\.env"
    if (-not (Test-Path $backendEnv)) {
        $backendExample = Join-Path $RepoRoot "backend\.env.example"
        if (Test-Path $backendExample) {
            Copy-Item $backendExample $backendEnv
            Write-Host "  Creado backend\.env desde .env.example" -ForegroundColor Yellow
        }
    }
    Write-Step "Backend (nueva ventana) - http://localhost:8080"
    Start-InNewWindow -Title "BotAI Backend" -WorkingDirectory (Join-Path $RepoRoot "backend") -Command "mvn spring-boot:run"
}

if (-not $BackendOnly) {
    Ensure-FrontendEnv
    $webUrl = "http://${WebHost}:${WebPort}/"
    Write-Step "Frontend Flutter web-server (nueva ventana) - $webUrl"
    Write-Host "  Modo: web-server (servidor local, sin lanzar Chrome automaticamente)" -ForegroundColor DarkGray
    $flutterCmd = Get-FlutterWebServerCommand -Port $WebPort -HostName $WebHost
    Start-InNewWindow -Title "BotAI Frontend (web-server)" -WorkingDirectory (Join-Path $RepoRoot "frontend") -Command $flutterCmd
}

Write-Host ""
Write-Host "Listo. Ventanas nuevas para backend y frontend (si aplican)." -ForegroundColor Green
Write-Host "  API:      http://localhost:8080/api"
Write-Host "  Swagger:  http://localhost:8080/swagger-ui.html"
Write-Host "  Web:      http://${WebHost}:${WebPort}/  (flutter web-server; abri esta URL en el navegador)"
Write-Host "  DB:       localhost:5444 (chatbot/chatbot)"
Write-Host ""
Write-Host "Solo DB:     docker compose up -d"
Write-Host "Parar DB:    docker compose down"
Write-Host "Sin Docker:  .\start-dev.ps1 -SkipDocker"
Write-Host "En Ubuntu:   ./start-dev.sh"
Write-Host ""
