# Soita Samille

Paikallinen puheohjattu vittuilupuhelin. Selain kuuntelee käyttäjän puheen,
palvelin tekee vastauksen ja HH-TTSservice lukee sen ääneen.

Demo käyttää puheen muodostukseen HH-TTSserviceä eikä selaimen
`speechSynthesis`-ääntä.

## Käynnistys paikallisesti

### Docker-konttina

Suositeltu paikallinen ajo:

```powershell
cd "E:\SoitaSamille"
.\start-container.ps1
```

Tämä rakentaa ja käynnistää `soita-samille`-kontin. Kontti palvelee HTML:n ja
API:n osoitteessa. Skripti yrittaa kaynnistaa HH-TTSservicen ensin oletuspolusta
`E:\AgentX\HH-TTSservice`, jotta aani ei jaa tilaan `TTS poikki`:

```text
http://localhost:5177/
```

Pysäytys:

```powershell
.\stop-container.ps1
```

Jos haluat samalla pysayttaa myos HH-TTSservicen:

```powershell
.\stop-container.ps1 -StopTts
```

Tila:

```powershell
.\status-container.ps1
```

Kontti tarvitsee HH-TTSservicen käyntiin hostilla portissa `5620`. Kontin
oletus-TTS-osoite on. Jos HH-TTS on muualla, anna `-TtsPort` tai aseta
`HH_TTS_URL` ennen kaynnistysta:

```text
http://host.docker.internal:5620/speak
```

Jos ajat TTS:n muualla:

```powershell
$env:HH_TTS_URL = "http://host.docker.internal:5620/speak"
.\start-container.ps1
```

### Suoraan Pythonilla

```powershell
cd "E:\SoitaSamille"
.\start-soita-samille.ps1
```

Avaa selaimessa:

```text
http://localhost:5177/
```

Sama palvelin näyttää käynnistyessä myös lähiverkon osoitteen.

Pysäytys:

```powershell
.\stop-soita-samille.ps1
```

Tila ja jaettava linkki:

```powershell
.\status-soita-samille.ps1
```

## Mobiili ja mikki

Mobiiliselaimet eivät näytä mikki-popuppia tavalliselle
`http://192.168...`-lähiverkkolinkille. Mobiilikäyttöön tarvitaan HTTPS-linkki.

Jos koneella on `cloudflared` tai `ngrok`, käynnistä HTTPS-tunneli:

```powershell
cd "E:\SoitaSamille"
.\start-public-link.ps1
```

Jaa komennon tulostama `https://...`-linkki. Sen kautta mobiiliselaimen pitäisi
voida näyttää mikrofoniluvan pop-up.

Pysäytä tunneli:

```powershell
.\stop-public-link.ps1
```

Jos tunnelityökalua ei ole:

```powershell
.\install-cloudflared-local.ps1
.\start-public-link.ps1
```

`install-cloudflared-local.ps1` lataa Cloudflaren `cloudflared.exe`-tiedoston
paikalliseen `tools`-kansioon. Sitä ei commitata repoon.

## Toiminta

- Puhelimen painallus pyytää mikrofoniluvan.
- Puhelu alkaa repliikillä: "Sami.. mitä nyt?"
- Selain kuuntelee vuoron, Sami vastaa, ja keskustelu jatkuu kunnes painetaan
  `Lopeta`.
- Vastaus muodostetaan WAV-ääneksi HH-TTSservicen kautta:
  `POST http://127.0.0.1:5620/speak`.
- Tekstisyöttöä tai puhelulokia ei ole.
- Ääntä tai transkriptiota ei tallenneta levylle tässä demossa.
- Sama vastaus pidetään poissa saman keskustelun aikana selaimen muistissa.
- Jos `OPENAI_API_KEY` on asetettu, `/api/roast` käyttää OpenAI-vastausta.
  Muuten se käyttää paikallista demogeneraattoria.

## HH-TTSservice

Oletusasetukset:

```powershell
$env:HH_TTS_URL = "http://127.0.0.1:5620/speak"
$env:HH_TTS_VOICE = "fi_FI-harri-medium"
```

Palvelun voi tarkistaa:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5620/readyz
```

Valinnainen malli:

```powershell
$env:OPENAI_MODEL = "gpt-4o-mini"
```
