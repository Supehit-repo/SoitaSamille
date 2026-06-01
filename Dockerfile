FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0
ENV PORT=5177
ENV HH_TTS_URL=http://host.docker.internal:5620/speak
ENV HH_TTS_VOICE=fi_FI-harri-medium

WORKDIR /app

COPY server.py index.html README.md ./
COPY assets ./assets

EXPOSE 5177

HEALTHCHECK --interval=10s --timeout=3s --retries=6 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5177/healthz', timeout=2).read()"

CMD ["python", "server.py"]
