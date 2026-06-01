param(
    [int]$Port = 5177
)

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $listener) {
    Write-Host "Soita Samille ei ole kaynnissa portissa $Port."
    exit 0
}

$lanIp = Get-NetIPConfiguration |
    Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.IPv4Address -ne $null } |
    Select-Object -First 1 -ExpandProperty IPv4Address |
    Select-Object -First 1 -ExpandProperty IPAddress

if (-not $lanIp) {
    $lanIp = "127.0.0.1"
}

Write-Host "Soita Samille on kaynnissa. PID: $($listener.OwningProcess)"
Write-Host "Paikallinen: http://localhost:$Port/"
Write-Host "Lahiverkko:   http://$lanIp`:$Port/"

try {
    Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:5620/readyz" -TimeoutSec 3 | Out-Null
    Write-Host "HH-TTSservice: paalla"
} catch {
    Write-Host "HH-TTSservice: ei vastaa"
}
