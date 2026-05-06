# Accend

Accend is a speaking-first English pronunciation app built for anyone who wants to sound more natural, confident, and clear — whether you're a non-native speaker navigating a new country, a student preparing for academic or professional environments, or someone who has always wanted to work on their accent.

Most language apps focus on reading and writing. Accend puts speaking first. Every session — whether solo or with other people — is built around opening your mouth, getting AI-graded feedback at the word and phoneme level, and building the kind of confidence that only comes from actual practice.

## What Makes Accend Different

- **Phoneme-level AI coaching.** Not just "that word was wrong" — Accend breaks down exactly which sound in which word missed, and why, then gives you actionable coaching tips to fix it.
- **Group practice with real people.** Private lobbies and public matchmaking let you practice with others in a structured turn-based format. Real social pressure, without the embarrassment of real stakes.
- **Courses built around your goals and weak spots.** AI generates personalized learning content from what users want to learn (onboarding goals and custom prompts) and adapts over time using phoneme performance data.
- **Speaking-first practice formats.** The app includes repeat-after-me style flashcard exercises, but every format is designed around producing speech and receiving pronunciation feedback.

## Target Users

- Non-native English speakers (immigrants, international students, professionals)
- Learners who have tried Duolingo or similar apps and found them too passive

## Product Features

- Guided onboarding that captures native language, learning goals, target accent, and practice preferences.
- AI-generated custom courses and lessons — seeded from onboarding goals, generated from custom prompts, or built around your phoneme weak spots.
- Solo pronunciation practice with per-word and per-phoneme scoring, session playback, and AI coaching feedback.
- Group session flows: private lobby codes, public matchmaking, turn-based mic control, in-session scoring, and post-session actions.
- Social graph: follow, block/avoid, reputation voting, and public profile discovery.
- Progress tracking: daily goals, streaks, and persistent phoneme accuracy metrics over time.

## How It Works

### Onboarding

User signs in, completes a short onboarding (native language, goal, focus areas, pace, tone, accent choice), and lands in the main app. Starter courses are seeded automatically in the background based on the selected learning goal.

### Solo Practice

User picks a lesson item, records a short audio clip, and receives a scored breakdown — overall accuracy, word-level scores, and phoneme-level detail. AI coaching tips can be requested for concise, targeted guidance. Results feed into long-term phoneme progress metrics that influence future course generation.

### Group Practice

User joins via private lobby code or public matchmaking. A generated item set is loaded for all participants. Turn state controls who can speak and when the mic is active. Each turn is scored and reflected in session visuals. Post-session flow includes follow, avoid/block, and reputation voting on other participants.

### Social and Profiles

Search users, follow/unfollow, inspect public profiles with learning stats and reputation context. Blocked users are filtered from relevant surfaces.

## Architecture Overview

```
Flutter App
  → API Gateway  (single public entrypoint, JWT verification)
  → Internal Microservices  (domain logic, each owns its data)
  → Supabase  (database + auth)
```

The Flutter app authenticates with Supabase Auth, then communicates exclusively with the API Gateway. The gateway verifies the JWT and forwards identity to internal services. No internal service is exposed to the client directly.

For full architecture and local backend setup, see `backend/README.md`.

## Quick Start

### Mobile app

```bash
cd apps/mobile_interface
flutter pub get
flutter run
```

### Backend

```bash
cd backend
cp .env.example .env
# Fill in secrets (see backend/README.md)
docker compose up --build
```

Point the mobile app to the gateway base URL — typically `http://localhost:8080` for local development.

If you are completely new to this repo, start here:

1. Launch backend (`backend/` + Docker Compose).
2. Launch mobile app (`apps/mobile_interface` + Flutter run).
3. Create/sign in account and complete onboarding.
4. Test one solo lesson and one group flow to understand end-to-end behavior.

## Repository Layout

```text
Accend/
├── apps/
│   └── mobile_interface/     # Flutter client
├── backend/
│   ├── docker-compose.yml
│   └── services/
│       ├── api-gateway/
│       ├── ai-course-gen-service/
│       ├── courses-service/
│       ├── follow-service/
│       ├── group-service/
│       ├── progress-service/
│       ├── pronunciation-feedback/
│       └── user-profile-service/
└── scripts/
```

## Documentation


| Doc                               | What it covers                                              |
| --------------------------------- | ----------------------------------------------------------- |
| `README.md` (this file)           | Product overview and repo orientation                       |
| `backend/README.md`               | Architecture, service descriptions, local dev runbook       |
| `apps/mobile_interface/README.md` | Flutter app structure, environment setup, contributor guide |


