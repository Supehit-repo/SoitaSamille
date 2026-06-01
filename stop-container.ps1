param(
    [switch]$StopTts,
    [string]$TtsServicePath = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $root
try {
    docker compose down
    Write-Host "Soita Samille -kontti pysaytetty."

    if ($StopTts) {
        if ([string]::IsNullOrWhiteSpace($TtsServicePath)) {
            if ($env:HH_TTSSERVICE_PATH) {
                $TtsServicePath = $env:HH_TTSSERVICE_PATH
            } else {
                $TtsServicePath = "E:\AgentX\HH-TTSservice"
            }
        }

        $stopScript = Join-Path $TtsServicePath "scripts\stop-tts.ps1"
        if (Test-Path -LiteralPath $stopScript -PathType Leaf) {
            & $stopScript
        } else {
            Write-Warning "HH-TTSservice stop-skriptia ei loydy: $stopScript"
        }
    }
} finally {
    Pop-Location
}
