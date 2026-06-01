param(
    [int]$Port = 5177
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    docker compose ps
    try {
        Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$Port/healthz" -TimeoutSec 3 | Out-Null
        Write-Host "HTML: http://localhost:$Port/"
    } catch {
        Write-Host "HTTP health ei vastaa portissa $Port."
    }
} finally {
    Pop-Location
}
