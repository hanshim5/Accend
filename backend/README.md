# microservices directory
please containerize ur service using Docker :3

# Accend Backend Architecture

## Overview

Accend uses a microservices architecture with a required API Gateway
(BFF) and a shared Supabase backend (Postgres + Auth + Storage).

Architecture Flow:

Flutter App\
→ (JWT)\
API Gateway (validates JWT)\
→ (X-User-Id header)\
Microservices\
→\
Supabase (Postgres + Auth + Storage)

The mobile app only calls the Gateway. Services are never called
directly by Flutter.

------------------------------------------------------------------------

## JWT Strategy (Gateway-Validated)

1.  Flutter authenticates with Supabase Auth.
2.  Flutter sends: Authorization: Bearer `<JWT>`{=html}
3.  Gateway:
    -   Verifies the JWT using Supabase’s JWKS endpoint (https://<project>.supabase.co/auth/v1/.well-known/jwks.json)
    -   Validates issuer and algorithm (ES256)
    -   Extracts user_id from the sub claim
    -   Forwards request internally with header: X-User-Id:
        `<uuid>`{=html}

Downstream services trust this internal header.

------------------------------------------------------------------------

## Data Ownership Model

We use one shared Supabase database, but:

Each table has exactly one "owner service."

Only the owning service may WRITE to its tables.

Other services should: - Not write to those tables - Prefer calling the
owning service's API instead of querying directly

Example ownership:

Profile Service → profiles, onboarding data\
Courses Service → courses, lessons, lesson_items\
Progress Service → course_progress, daily_minutes, streaks\
Social Service → follows, avoid_list, thanks\
Group Service → lobbies, sessions, turns, votes

Note: All services use SUPABASE_SERVICE_ROLE_KEY, so ownership is
enforced by team discipline (not DB permissions in Sprint 1).

------------------------------------------------------------------------

## Required Service Structure

Each service follows this pattern:

routers → services → repositories → supabase client

Responsibilities:

routers/\
- Handle HTTP request/response only\
- No database logic

services/\
- Business logic

repositories/\
- The only layer allowed to call Supabase

clients/supabase.py\
- Creates Supabase client using environment variables

Routes must NEVER call Supabase directly.

------------------------------------------------------------------------

## API Gateway Responsibilities

-   Validate JWT
-   Route requests to services
-   Shape payloads for mobile
-   Provide one-request-per-screen preload endpoints

Example endpoints:

GET /profile/username-available\
GET /courses\
POST /ai/generate-course

Future preload endpoints:

GET /home\
GET /courses-page\
GET /profile-page

------------------------------------------------------------------------

## Supabase Usage

Flutter uses: - SUPABASE_URL - SUPABASE_ANON_KEY

Backend services use: - SUPABASE_URL - SUPABASE_SERVICE_ROLE_KEY -
SUPABASE_JWT_SECRET

The service role key must never be exposed to Flutter.

------------------------------------------------------------------------

## Screen Preloading Rule (BFF Pattern)

Each major mobile screen must load with one Gateway request.

Examples:

/home → username, streak, today's goal\
/courses-page → course summaries + progress\
/profile-page → stats + social counts

Gateway aggregates data from multiple services and returns a single DTO.

------------------------------------------------------------------------

## Backend Folder Structure

backend/ services/ api-gateway/ courses-service/ app/ routers/ services/
repositories/ clients/ schemas/ ai-service/ sessions-service/

shared/ auth/ http/ logging.py

------------------------------------------------------------------------

## Where to put credentials

Put all secrets in **one file**: `backend/.env`.

1. Copy the example:  
   `cp .env.example .env`
2. Edit `backend/.env` and set your real values (Supabase and Azure Speech).
3. Never commit `.env` (it is in `.gitignore`).

When you run `docker compose up` from `backend/`, Compose passes this `.env` to every service (api-gateway, pronunciation-feedback, etc.), so one file is enough.

------------------------------------------------------------------------

## Pronunciation Feedback microservice

### What it does

`pronunciation-feedback` accepts a WAV upload (max 10 seconds) + `reference_text`, calls Azure Speech Pronunciation Assessment (`en-US`, scripted), and returns a compact JSON payload with:

- `summary`: overall scores
- `words[]`: per-word accuracy + per-phoneme accuracy

### How the mobile app should call it (through the Gateway)

The Flutter app should call the Gateway endpoint (not the service directly):

- **POST** `http://localhost:8080/pronunciation/assess`
  - Multipart form fields:
    - `audio`: WAV file (filename must end with `.wav`)
    - `reference_text`: the ground truth text the learner should say

The gateway proxies this to `pronunciation-feedback`’s internal `POST /assess`.

### Auth behavior (dev vs prod)

The Gateway route validates the Supabase JWT by default *unless* `ALLOW_ANON_PRONUNCIATION_ASSESS` is enabled (intended for local/dev).

- **ALLOW_ANON_PRONUNCIATION_ASSESS**: set to `true` to allow calling `POST /pronunciation/assess` without a JWT (local/dev only)

### Required environment variables (Azure Speech)

Add these to `backend/.env`:

- `AZURE_SPEECH_KEY`
- `AZURE_SPEECH_REGION` (e.g. `eastus`)

### Quick test (end-to-end through Gateway)

With the backend stack running (`docker compose up --build` from `backend/`):

```bash
curl -X POST "http://localhost:8080/pronunciation/assess" \
  -F "audio=@path/to/audio.wav" \
  -F "reference_text=Hello world"
```

## Environment Rules

-   .env files are local only
-   Never commit secrets
-   Service role key is backend-only

------------------------------------------------------------------------

## Why This Architecture

-   Clear service boundaries
-   Scalable heavy services (AI, Speech)
-   Prevents cross-service DB corruption
-   Supports one-call-per-screen preload pattern
-   Easy migration to multi-DB later

