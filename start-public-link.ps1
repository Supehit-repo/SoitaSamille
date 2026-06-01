param(
    [int]$Port = 5177
)

$ErrorActionPreference = "Stop"

Write-Host "Mobiilin mikki tarvitsee HTTPS-linkin. HTTP-lahiverkkolinkki ei riita."

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cloudflared) {
    Write-Host "Kaynnistetaan Cloudflare quick tunnel..."
    & $cloudflared.Source tunnel --url "http://localhost:$Port"
    exit $LASTEXITCODE
}

$ngrok = Get-Command ngrok -ErrorAction SilentlyContinue
if ($ngrok) {
    Write-Host "Kaynnistetaan ngrok..."
    & $ngrok.Source http $Port
    exit $LASTEXITCODE
}

Write-Host "Tunnelityokalua ei loytynyt."
Write-Host ""
Write-Host "Asenna esimerkiksi Cloudflare tunnel:"
Write-Host "winget install Cloudflare.cloudflared"
Write-Host ""
Write-Host "Sen jalkeen aja:"
Write-Host ".\start-public-link.ps1"
Write-Host ""
Write-Host "Jaa komennon tulostama https://...trycloudflare.com-linkki mobiilikayttajille."
