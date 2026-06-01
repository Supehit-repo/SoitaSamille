param(
    [int]$Port = 5177,
    [switch]$NoOpen,
    [switch]$SkipTts,
    [int]$TtsPort = 5620,
    [string]$TtsServicePath = "",
    [string]$TtsModelsPath = "",
    [string]$TtsVoice = ""
)

$ErrorActionPreference = "Stop"

function Test-HhTtsReady {
    param([int]$Port)

    try {
        Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$Port/readyz" -TimeoutSec 3 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Start-HhTtsIfNeeded {
    param(
        [int]$Port,
        [string]$ServicePath,
        [string]$ModelsPath,
        [string]$Voice,
        [switch]$Skip
    )

    if ($Skip) {
        Write-Host "HH-TTSservice: ohitettu"
        return
    }

    if (Test-HhTtsReady -Port $Port) {
        Write-Host "HH-TTSservice: paalla"
        return
    }

    if ([string]::IsNullOrWhiteSpace($ServicePath)) {
        if ($env:HH_TTSSERVICE_PATH) {
            $ServicePath = $env:HH_TTSSERVICE_PATH
        } else {
            $ServicePath = "E:\AgentX\HH-TTSservice"
        }
    }

    if ([string]::IsNullOrWhiteSpace($ModelsPath)) {
        if ($env:PIPER_MODELS_HOST_PATH) {
            $ModelsPath = $env:PIPER_MODELS_HOST_PATH
        } else {
            $ModelsPath = "E:\AgentX\models\piper"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Voice)) {
        if ($env:HH_TTS_VOICE) {
            $Voice = $env:HH_TTS_VOICE
        } else {
            $Voice = "fi_FI-harri-medium"
        }
    }

    $startScript = Join-Path $ServicePath "scripts\start-tts.ps1"
    if (-not (Test-Path -LiteralPath $startScript -PathType Leaf)) {
        Write-Warning "HH-TTSservice ei vastaa portissa $Port, eika starttiskriptia loydy: $startScript"
        Write-Warning "Aani toimii vasta kun HH-TTSservice kuuntelee osoitteessa http://127.0.0.1:$Port/speak"
        return
    }

    Write-Host "HH-TTSservice: kaynnistetaan porttiin $Port"
    & $startScript -Port $Port -ModelsPath $ModelsPath -Voice $Voice

    if (Test-HhTtsReady -Port $Port) {
        Write-Host "HH-TTSservice: valmis"
    } else {
        Write-Warning "HH-TTSservice kaynnistyi, mutta /readyz ei ole valmis. Tarkista Piper-malli: $ModelsPath"
    }
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    $env:SOITA_SAMILLE_PORT = "$Port"
    if ([string]::IsNullOrWhiteSpace($env:HH_TTS_URL)) {
        $env:HH_TTS_URL = "http://host.docker.internal:$TtsPort/speak"
    }
    if (-not [string]::IsNullOrWhiteSpace($TtsVoice)) {
        $env:HH_TTS_VOICE = $TtsVoice
    }
    Start-HhTtsIfNeeded -Port $TtsPort -ServicePath $TtsServicePath -ModelsPath $TtsModelsPath -Voice $TtsVoice -Skip:$SkipTts

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
