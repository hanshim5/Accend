# Accend

Accend is an AI-powered language learning experience designed to help users improve pronunciation, confidence, and real-world speaking ability through personalized feedback and engaging practice.

Our goal is simple: make speaking practice feel natural, motivating, and effective.

---

## 🌍 What Accend Does

Accend helps learners:

* Practice speaking in realistic scenarios
* Receive intelligent pronunciation feedback
* Personalize their learning goals and pace
* Choose the tone of AI feedback that motivates them
* Track their progress over time

The experience adapts to each learner’s level, goals, and preferences from the moment they onboard.

---

## 📱 App Experience

Users can:

* Create an account or log in
* Complete a guided onboarding experience
* Select:

  * Current speaking level
  * Learning goals
  * Daily practice pace
  * Preferred AI feedback tone
  * Target accent
* Begin personalized speaking practice

The app focuses on confidence-building, clarity, and consistent daily improvement.

---

## 🏗 Project Structure

This repository is organized into two main parts:

### `/apps`

Contains the Flutter mobile application.

* User interface
* Onboarding experience
* Practice sessions
* Progress tracking
* Client-side app logic

### `/services`

Contains backend microservices.

* Authentication
* User profiles
* Speech processing
* Feedback generation
* Data storage and management

This structure allows the mobile app and backend services to evolve independently while working together seamlessly.

---

## 🎯 Vision

Accend aims to combine:

* AI-powered feedback
* Human-like encouragement
* Structured skill progression
* Flexible daily commitment

The long-term goal is to create a speaking-first language platform that feels less like a lesson and more like real conversation practice.

---

## 🚀 Status

Accend is currently under active development.
Features and architecture may evolve as the product grows.

## Repo Structure

```
ACCEND/
├── apps/
│   └── mobile_interface/
│
├── backend/
│   ├── services/
│   │   ├── api-gateway/
│   │   ├── courses-service/
│   │   │   ├── app/
│   │   │   │   ├── main.py
│   │   │   │   ├── config.py
│   │   │   │   ├── dependencies.py
│   │   │   │
│   │   │   │   ├── routers/
│   │   │   │   │   └── courses.py
│   │   │   │
│   │   │   │   ├── schemas/
│   │   │   │   │   ├── course_schema.py
│   │   │   │   │   └── lesson_schema.py
│   │   │   │
│   │   │   │   ├── services/
│   │   │   │   │   └── course_service.py
│   │   │   │
│   │   │   │   ├── repositories/
│   │   │   │   │   ├── course_repo.py              # interface/contract
│   │   │   │   │   └── supabase_course_repo.py     # router → service → repository → supabase
│   │   │   │
│   │   │   │   ├── clients/
│   │   │   │   │   └── supabase.py
│   │   │   │
│   │   │   │   └── utils/
│   │   │   │       └── errors.py
│   │   │   ├── tests/
│   │   │   ├── Dockerfile
│   │   │   └── requirements.txt
│   │   ├── ai-service/
│   │   └── sessions-service/
│   │
│   ├── shared/
│   │   ├── auth/
│   │   │   └── jwt.py
│   │   ├── http/
│   │   │   └── client.py             # shared http helpers
│   │   └── logging.py
│   │
│   └── docker-compose.yml
│
├── contracts/
│   └── openapi/
│
├── infra/
│   ├── supabase/
│   └── scripts/
│
└── README.md
```
