# pronunciation-feedback

Pronunciation assessment microservice using Azure Speech (scripted assessment, en-US). Client sends WAV audio and reference text; service returns the full Azure pronunciation assessment JSON.

## Config

Copy `env.example` to `.env` and set:

- `AZURE_SPEECH_KEY` – Azure Speech resource key
- `AZURE_SPEECH_REGION` – e.g. `eastus`

## API

- **POST /assess** – Form: `audio` (WAV file, max 10s), `reference_text` (ground truth). Returns full Azure pronunciation assessment JSON.
- **GET /health** – Health check
- **GET /docs** – OpenAPI docs

## Run locally

```bash
pip install -r requirements.txt
uvicorn main:app --reload
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
