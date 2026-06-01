param(
    [int]$Port = 5177,
    [string]$HostAddress = "0.0.0.0",
    [string]$TtsUrl = "http://127.0.0.1:5620/speak",
    [string]$TtsVoice = "fi_FI-harri-medium"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = "C:\Users\SamiO\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
$pidFile = Join-Path $root "soita-samille.pid"
$outLog = Join-Path $root "soita-samille.out.log"
$errLog = Join-Path $root "soita-samille.err.log"

function Get-LanIp {
    $ip = Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.IPv4Address -ne $null } |
        Select-Object -First 1 -ExpandProperty IPv4Address |
        Select-Object -First 1 -ExpandProperty IPAddress

    if ($ip) { return $ip }
    return "127.0.0.1"
}

$existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    $existingPid = $existing | Select-Object -First 1 -ExpandProperty OwningProcess
    Write-Host "Soita Samille on jo paalla portissa $Port. PID: $existingPid"
    Write-Host "Paikallinen: http://localhost:$Port/"
    Write-Host "Lahiverkko:   http://$(Get-LanIp):$Port/"
    exit 0
}

try {
    Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:5620/readyz" -TimeoutSec 3 | Out-Null
} catch {
    Write-Warning "HH-TTSservice ei vastaa portissa 5620. Aani ei toimi ennen kuin se on kaynnissa."
}

$env:PORT = "$Port"
$env:HOST = $HostAddress
$env:HH_TTS_URL = $TtsUrl
$env:HH_TTS_VOICE = $TtsVoice

Remove-Item -LiteralPath $outLog, $errLog -Force -ErrorAction SilentlyContinue

$process = Start-Process -FilePath $python -ArgumentList "server.py" -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ASCII
Start-Sleep -Milliseconds 900

try {
    Invoke-WebRequest -UseBasicParsing -Uri "http://localhost:$Port/healthz" -TimeoutSec 5 | Out-Null
} catch {
    Write-Error "Demo ei kaynnistynyt. Katso loki: $errLog"
    exit 1
}

Write-Host "Soita Samille kaynnissa. PID: $($process.Id)"
Write-Host "Paikallinen: http://localhost:$Port/"
Write-Host "Lahiverkko:   http://$(Get-LanIp):$Port/"
Write-Host ""
Write-Host "Saman Wi-Fi/lahiverkon kayttajille anna lahiverkkolinkki."
Write-Host "Pysaytys: .\stop-soita-samille.ps1"
