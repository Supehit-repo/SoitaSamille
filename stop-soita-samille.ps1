param(
    [int]$Port = 5177
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root "soita-samille.pid"
$stopped = $false

if (Test-Path -LiteralPath $pidFile) {
    $pidValue = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pidValue) {
        $process = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $process.Id -Force
            Write-Host "Pysaytetty PID $($process.Id)."
            $stopped = $true
        }
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

$listeners = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listeners) {
    $listeners | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object {
        Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        Write-Host "Pysaytetty portin $Port prosessi PID $_."
        $script:stopped = $true
    }
}

if (-not $stopped) {
    Write-Host "Soita Samille ei ollut kaynnissa portissa $Port."
}
