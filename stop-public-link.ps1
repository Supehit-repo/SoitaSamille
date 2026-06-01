$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root "cloudflared.pid"
$localCloudflared = Join-Path $root "tools\cloudflared.exe"
$stopped = $false

if (Test-Path -LiteralPath $pidFile) {
    $pidValue = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pidValue) {
        $process = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $process.Id -Force
            Write-Host "Pysaytetty HTTPS-tunneli PID $($process.Id)."
            $stopped = $true
        }
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -eq $localCloudflared -or $_.ProcessName -eq "cloudflared"
} | ForEach-Object {
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    Write-Host "Pysaytetty cloudflared PID $($_.Id)."
    $script:stopped = $true
}

if (-not $stopped) {
    Write-Host "HTTPS-tunnelia ei ollut kaynnissa."
}
