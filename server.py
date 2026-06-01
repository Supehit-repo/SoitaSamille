#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import random
import socket
import sys
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parent
PORT = int(os.environ.get("PORT", "5177"))
HOST = os.environ.get("HOST", "0.0.0.0")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
HH_TTS_URL = os.environ.get("HH_TTS_URL", "http://127.0.0.1:5620/speak")
HH_TTS_VOICE = os.environ.get("HH_TTS_VOICE", "fi_FI-harri-medium")


SYSTEM_PROMPT = """
Olet Sami, perinteinen suomalainen vittuilupuhelin.
Vastaa yhdellä lyhyellä puhekielisellä lauseella, 3-9 sanaa.
Tyyli: todella tyly, kuiva, eleetön, nopea, arkinen ja suoraan naamaan.
Perusviesti: käyttäjän pitäisi itse vähän miettiä ennen kuin soittelee.
Reagoi käyttäjän sanoihin, älä heitä irrallista fraasia.
Käytä välillä sanaleikkiä, vähättelyä, väärinymmärrystä tai tylyä arkivertausta.
Älä ole akateeminen. Älä selitä. Älä pehmennä. Älä toista aiempia vastauksia.
Älä hauku suojattuja ominaisuuksia, uhkaile, toivo vahinkoa tai mene seksuaaliseksi.
""".strip()


FALLBACKS = [
    "No nyt oli taas suoritus.",
    "Älä rasita linjaa tuolla.",
    "Tuo ajatus jäi eteiseen.",
    "Mieti ensin, soittele sitten.",
    "Tämä olisi ratkennut ajattelulla.",
    "Älä ulkoista päättelyäsi minulle.",
    "Soititko ennen vai jälkeen ajattelun?",
    "Palaa asiaan kun ajatus palaa.",
    "Kysyit ja silti hävisit.",
    "On siinäkin murheenkryyni.",
    "Nyt meni kuppi nurin jo alussa.",
    "Tuohonkin sait sotkun aikaan.",
    "Sinulta puuttuu käyttöohjeet.",
    "Hyvä yritys, huono osuma.",
    "Tuo oli väsyneempi kuin maanantai.",
    "Pääsit lähelle, eli et.",
    "Nyt puhutaan vahvasta alisuoriutumisesta.",
    "Ei tuosta saa ehjää edes teipillä.",
    "Siinä meni järki kahvitauolle.",
    "Tuo kuulosti jo reklamaatiolta sinusta.",
    "Voi helvetti, mikä viritys.",
    "Tuosta ei parane kuin hiljenemällä.",
    "Nyt jäi järki narikkaan.",
    "Ei jatkoon, eikä edes jonoon.",
    "Olipa kysymys, ihan omalla vastuulla.",
    "Tuo oli puheluvirhe, ei kysymys.",
    "Seuraavaksi kokeile omaa päätä.",
    "Nyt teit yksinkertaisesta vaikeaa.",
    "Soitto oli rohkea, sisältö ei.",
    "Tuossa hävisi sekä aika että arvokkuus.",
]


QUESTION_ROASTS = {
    "why": [
        "Koska joku päästi sinut kysymään.",
        "Siksi, että järki loppui kesken.",
        "Koska näin siinä käy sinulla.",
        "Miksi sinä tämänkin rikoit?",
        "Koska et miettinyt ennen soittoa.",
        "Siksi, että oikaisit ajattelun ohi.",
    ],
    "how": [
        "Aloita vaikka ajattelemalla ensin.",
        "Varovasti, ettet sotke enempää.",
        "Sinulta se alkaa vaikeimman kautta.",
        "Ei noin, mutta arvasin jo.",
        "Kokeile ensin itse, radikaali ajatus.",
        "Aloita olemalla vähemmän hukassa.",
    ],
    "can": [
        "Voit, mutta älä ylpeile sillä.",
        "Voit, jos kukaan ei valvo.",
        "Kyllä, mutta jälki näkyy.",
        "Voit, vahinko on jo alkanut.",
        "Voit, jos ensin ajattelet.",
        "Voit, mutta älä soita siitä.",
    ],
    "what": [
        "Se on asia, jota et ymmärrä.",
        "No nyt ollaan perusasioissa hukassa.",
        "Tuo selittäisi paljon, valitettavasti.",
        "Mikä vaan, kunhan et koske.",
        "Se on se kohta missä mietitään.",
        "Tuo vaatii sinulta liikaa jo lähtöön.",
    ],
    "where": [
        "Varmaan siellä, mihin järkikin jäi.",
        "Ei ainakaan sinun suunnitelmassasi.",
        "Katso taskusta, jos siellä olisi ajatus.",
        "Siellä missä homma ei ole sinun vastuulla.",
        "Siellä minne järki lähti pakoon.",
        "Ei siinä suunnassa mihin sä osoitat.",
    ],
    "when": [
        "Sitten kun ajatus ehtii mukaan.",
        "Ei ainakaan tällä vauhdilla.",
        "Heti kun lopetat säätämisen.",
        "Kun joku aikuinen ehtii paikalle.",
        "Kun mietit ennen soittoa.",
        "Sitten kun tämä ei ole minun ongelma.",
    ],
    "who": [
        "Joku, joka ei kysy noin.",
        "Ei ainakaan sinä, rauhoitu.",
        "Kuka vaan, jolla on toivoa.",
        "Joku muu, onneksi.",
        "Se joka ajatteli ensin.",
        "Ei tämä kuulosta sinun hommalta.",
    ],
}


DOMAIN_ROASTS = [
    (
        {"koodi", "kood", "api", "server", "palvelin", "nappi", "sivu", "bugi", "toimii"},
        [
            "Bugi löytyi näppäimistön takaa.",
            "Palvelin toimii, sinä vielä lataat.",
            "Koodi selviää, käyttäjästä en lupaa.",
            "Tuo oli bugiraportti itsestäsi.",
            "Koodi ei korjaa käyttäjää.",
            "Nappi toimii, painaja horjuu.",
        ],
    ),
    (
        {"raha", "hinta", "myynti", "bisnes", "asiakas", "firma", "tuote"},
        [
            "Tuo ei myy edes vahingossa.",
            "Asiakas lähti jo henkisesti.",
            "Hinnoittele tuo anteeksipyynnöksi.",
            "Bisnes kaipaa vähemmän sinua.",
            "Tuo pitch tarvitsee hautajaiset.",
            "Asiakasymmärrys ei asu sinulla.",
        ],
    ),
    (
        {"tekoäly", "ai", "malli", "prompt", "openai", "agentti"},
        [
            "Tekoälykin kaipaa nyt kahvitaukoa.",
            "Prompti kärsii käyttäjästä.",
            "Malli yrittää, sinä vastustat.",
            "Agentti pyysi helpompaa ihmistä.",
            "Tekoäly ei ole lastenvahti.",
            "Prompti oli parempi ennen sinua.",
        ],
    ),
    (
        {"mikki", "ääni", "audio", "puhe", "tts", "kuuluu", "kuuntele"},
        [
            "Ääni kuuluu, asia ei.",
            "Puhe toimii, sisältö nilkuttaa.",
            "TTS lausuu paremmin kuin ajattelet.",
            "Kuuntelin, se oli virhe.",
            "Mikki kuuli, minä valitettavasti myös.",
            "Ääniraita kunnossa, päättely rikki.",
        ],
    ),
]


TRADITIONAL_FRAMES = [
    "No kysyitpä taas.",
    "Jaahas, sama sirkus jatkuu.",
    "Tuo meni metsään ilman karttaa.",
    "Tähän olisi auttanut oma ajatus.",
    "Soitto tuli ennen järkeä.",
    "Oma mietintä jäi näköjään välistä.",
    "Älä käytä puhelinta ajattelun korvikkeena.",
    "Tuo olisi pitänyt palauttaa lähettäjälle.",
    "Ei tuosta tule kuin sanomista.",
    "Nyt on kyllä työkalu hukassa.",
    "Olisit aloittanut hiljaisuudesta.",
    "Tuo on jo oma lajinsa.",
    "Kyllä elämä sinua koettelee.",
    "Älä tee tästä vaikeampaa itsellesi.",
    "Nyt ollaan tukevasti pihalla.",
    "Siinä oli asiaa vain nimeksi.",
    "Tuo kaatui jo lähtötelineisiin.",
    "Vähemmälläkin voi nolata itsensä.",
    "Ei muuta kuin takaisin arkeen.",
    "Tuo oli ajattelun sivuosuma.",
    "Oletko kokeillut olla säätämättä?",
    "Tämä ei parane soittamalla.",
    "Älä tee minusta hakukonettasi.",
    "Mieti edes symbolisesti ennen soittoa.",
    "Tuo oli hätähuuto logiikalta.",
]


def normalize_reply(text):
    return "".join(ch.lower() for ch in text if ch.isalnum() or ch.isspace()).strip()


def pick_unique(candidates, recent_replies=None):
    recent = {normalize_reply(reply) for reply in (recent_replies or [])}
    fresh = [candidate for candidate in candidates if normalize_reply(candidate) not in recent]
    if fresh:
        return random.choice(fresh)

    fallback = [
        "Nyt jopa toisto kyllästyi sinuun.",
        "Sama sotku, eri puhelu.",
        "Mieti itse, tämä on uusinta.",
        "Tämäkin meni jo kerran ohi.",
        "Uusi kysymys, sama alisuoritus.",
    ]
    fresh_fallback = [candidate for candidate in fallback if normalize_reply(candidate) not in recent]
    if fresh_fallback:
        return random.choice(fresh_fallback)

    return f"Mieti itse ennen soittoa, osa {len(recent) + 1}."


def local_roast(transcript, recent_replies=None):
    clean = " ".join((transcript or "").split())
    lower = clean.lower()
    candidates = []

    if not clean:
        return pick_unique(
            ["Hiljaisuuskin pärjäsi sinua paremmin.", "No nyt tuli paras osuutesi.", "Tuokin oli jo liikaa sisältöä."],
            recent_replies,
        )
    if any(word in lower for word in ["miksi", "minkä takia", "mistä johtuu"]):
        candidates.extend(QUESTION_ROASTS["why"])
    if any(word in lower for word in ["miten", "kuinka"]):
        candidates.extend(QUESTION_ROASTS["how"])
    if any(word in lower for word in ["voinko", "pitäisikö", "kannattaako"]):
        candidates.extend(QUESTION_ROASTS["can"])
    if any(word in lower for word in ["mikä", "mitä", "minkä"]):
        candidates.extend(QUESTION_ROASTS["what"])
    if any(word in lower for word in ["missä", "mihin", "mistä"]):
        candidates.extend(QUESTION_ROASTS["where"])
    if any(word in lower for word in ["milloin", "koska"]):
        candidates.extend(QUESTION_ROASTS["when"])
    if any(word in lower for word in ["kuka", "kenen", "ketkä"]):
        candidates.extend(QUESTION_ROASTS["who"])

    words = set(lower.replace("?", " ").replace(".", " ").replace(",", " ").split())
    for keywords, roasts in DOMAIN_ROASTS:
        if words & keywords:
            candidates.extend(roasts)

    specific_candidates = list(candidates)
    candidates.extend(TRADITIONAL_FRAMES if random.random() < 0.55 else FALLBACKS)
    if specific_candidates and random.random() < 0.82:
        return pick_unique(specific_candidates, recent_replies)
    return pick_unique(candidates, recent_replies)


def openai_roast(transcript, recent_replies=None):
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        return None

    recent = "\n".join(f"- {reply}" for reply in (recent_replies or [])[-80:])

    payload = {
        "model": OPENAI_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": (
                    f"Käyttäjä sanoi: {transcript}\n\n"
                    f"Älä toista näitä viime vastauksia:\n{recent or '- ei aiempia'}"
                ),
            },
        ],
        "temperature": 0.95,
        "max_tokens": 35,
    }

    request = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=18) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (TimeoutError, urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError):
        return None

    try:
        text = data["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError):
        return None

    return text or None


class Handler(SimpleHTTPRequestHandler):
    server_version = "SoitaSamilleDemo/0.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.log_date_time_string(), fmt % args))

    def send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def send_audio(self, status, body, content_type, voice):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-TTS-Backend", "HH-TTSservice")
        self.send_header("X-TTS-Voice", voice)
        self.end_headers()
        self.wfile.write(body)

    def read_json_payload(self, max_bytes=64 * 1024):
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            return None, (400, {"error": "bad_length"})

        if length > max_bytes:
            return None, (413, {"error": "payload_too_large"})

        try:
            return json.loads(self.rfile.read(length).decode("utf-8")), None
        except (UnicodeDecodeError, json.JSONDecodeError):
            return None, (400, {"error": "bad_json"})

    def synthesize_hh_tts(self, text, voice):
        payload = json.dumps({"text": text, "voice": voice}, ensure_ascii=False).encode("utf-8")
        request = urllib.request.Request(
            HH_TTS_URL,
            data=payload,
            headers={"Content-Type": "application/json; charset=utf-8"},
            method="POST",
        )

        with urllib.request.urlopen(request, timeout=30) as response:
            return response.read(), response.headers.get("Content-Type", "audio/wav")

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "ok", "service": "Soita Samille"})
            return
        if self.path == "/readyz":
            self.send_json(200, {"status": "ready", "checks": {"storage": "not-used", "queue": "not-used"}})
            return
        return super().do_GET()

    def do_POST(self):
        if self.path == "/api/speech":
            payload, error = self.read_json_payload(max_bytes=16 * 1024)
            if error:
                self.send_json(*error)
                return

            text = " ".join(str(payload.get("text", "")).split())[:1800]
            voice = str(payload.get("voice", HH_TTS_VOICE)).strip() or HH_TTS_VOICE
            if not text:
                self.send_json(400, {"error": "missing_text"})
                return

            try:
                audio, content_type = self.synthesize_hh_tts(text, voice)
            except (TimeoutError, urllib.error.URLError, urllib.error.HTTPError, OSError):
                self.send_json(
                    502,
                    {
                        "error": "tts_unavailable",
                        "service": "HH-TTSservice",
                        "url": HH_TTS_URL,
                    },
                )
                return

            self.send_audio(200, audio, content_type, voice)
            return

        if self.path != "/api/roast":
            self.send_json(404, {"error": "not_found"})
            return

        payload, error = self.read_json_payload()
        if error:
            self.send_json(*error)
            return

        transcript = str(payload.get("transcript", ""))[:1000]
        recent_replies = payload.get("recentReplies", [])
        if not isinstance(recent_replies, list):
            recent_replies = []
        recent_replies = [str(reply)[:200] for reply in recent_replies[-80:]]
        reply = openai_roast(transcript, recent_replies)
        source = "openai" if reply else "local"
        reply = reply or local_roast(transcript, recent_replies)
        if normalize_reply(reply) in {normalize_reply(item) for item in recent_replies}:
            reply = local_roast(transcript, recent_replies)

        self.send_json(
            200,
            {
                "reply": reply,
                "source": source,
                "noStorage": True,
            },
        )


def local_ip():
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("8.8.8.8", 80))
            return sock.getsockname()[0]
    except OSError:
        return "127.0.0.1"


def main():
    os.chdir(ROOT)
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print("Soita Samille demo käynnissä")
    print(f"Paikallinen: http://localhost:{PORT}/")
    print(f"Lähiverkko:   http://{local_ip()}:{PORT}/")
    print("Sulje Ctrl+C:llä.")
    server.serve_forever()


if __name__ == "__main__":
    main()
