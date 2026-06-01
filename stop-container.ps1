$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    docker compose down
    Write-Host "Soita Samille -kontti pysaytetty."
} finally {
    Pop-Location
}
