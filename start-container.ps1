param(
    [int]$Port = 5177,
    [switch]$NoOpen
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    $env:SOITA_SAMILLE_PORT = "$Port"

    $runningContainer = docker compose ps -q soita-samille
    if ($runningContainer) {
        Write-Host "Soita Samille -kontti on jo kaynnissa."
        Write-Host "HTML: http://localhost:$Port/"
        if (-not $NoOpen) {
            Start-Process "http://localhost:$Port/"
        }
        exit 0
    }

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($listener) {
        Write-Error "Portti $Port on jo kaytossa prosessilla PID $($listener.OwningProcess). Pysayta vanha palvelu ensin: .\stop-soita-samille.ps1"
        exit 1
    }

    try {
        Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:5620/readyz" -TimeoutSec 3 | Out-Null
        Write-Host "HH-TTSservice: paalla"
    } catch {
        Write-Warning "HH-TTSservice ei vastaa portissa 5620. Kontti kaynnistyy, mutta aani ei toimi ennen TTS-palvelua."
    }

    docker compose up -d --build

    for ($i = 0; $i -lt 30; $i++) {
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$Port/healthz" -TimeoutSec 2 | Out-Null
            break
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    Write-Host "Soita Samille -kontti kaynnissa."
    Write-Host "HTML: http://localhost:$Port/"
    Write-Host "Pysaytys: .\stop-container.ps1"

    if (-not $NoOpen) {
        Start-Process "http://localhost:$Port/"
    }
} finally {
    Pop-Location
}
