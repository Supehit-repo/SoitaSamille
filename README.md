# Soita Samille

Paikallinen puheohjattu vittuilupuhelin. Selain kuuntelee käyttäjän puheen,
palvelin tekee vastauksen ja HH-TTSservice lukee sen ääneen.

Demo käyttää puheen muodostukseen HH-TTSserviceä eikä selaimen
`speechSynthesis`-ääntä.

## Käynnistys paikallisesti

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

Jos tunnelityökalua ei ole:

```powershell
winget install Cloudflare.cloudflared
```

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
