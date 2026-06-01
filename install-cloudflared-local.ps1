$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$tools = Join-Path $root "tools"
$out = Join-Path $tools "cloudflared.exe"
$url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"

New-Item -ItemType Directory -Force -Path $tools | Out-Null

Write-Host "Ladataan cloudflared paikallisesti: $out"
Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $out

Write-Host "Valmis."
Write-Host "Kaynnista HTTPS-linkki:"
Write-Host ".\start-public-link.ps1"
