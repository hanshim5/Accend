# pronunciation-feedback

Pronunciation assessment microservice using Azure Speech (scripted assessment, `en-US`). Client sends WAV audio and reference text; service returns a compact JSON payload with overall scores plus per-word and per-phoneme accuracy.

## Config

Copy `env.example` to `.env` and set:

- `AZURE_SPEECH_KEY` – Azure Speech resource key
- `AZURE_SPEECH_REGION` – e.g. `eastus`

## API

- **POST /assess** – Form: `audio` (WAV file, max 10s), `reference_text` (ground truth). Returns:
  - `summary`: overall scores (accuracy/fluency/completeness/pronScore)
  - `words[]`: per-word accuracy + `phonemes[]` accuracy
- **GET /health** – Health check
- **GET /** – Service info
- **GET /docs** – OpenAPI docs

## Gateway integration

In the full backend stack, mobile clients should call the API Gateway (not this service directly):

- **POST (Gateway) /pronunciation/assess** → proxies to **POST /assess**

## Run locally

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

Example request (direct to this service):

```bash
curl -X POST "http://localhost:8000/assess" \
  -F "audio=@path/to/audio.wav" \
  -F "reference_text=Hello world"
```

## Run with Docker

From this directory (so `.env` is found):

```bash
docker build -t pronunciation-feedback .
docker run -p 8000:8000 --env-file .env pronunciation-feedback
```

Or with Docker Compose (loads `.env` automatically):

```bash
docker compose up --build
```
