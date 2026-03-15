# Onboarding feature

New users complete a short flow to set up their account and preferences. Answers are stored in the `profiles` table (Supabase) and used to personalize the app.

## Flow

1. **User info** — Sign up (email, password, username, full name, native language). Creates the auth user and a profile row via the API.
2. **Skill assessment** — “What is your current level?” (Beginner / Intermediate / Advanced).
3. **Learning goal** — “Why are you learning?” (Travel, Career, Culture, Brain Training).
4. **Accent selection** — Target accent for pronunciation (e.g. Californian; others coming soon).
5. **Feedback tone** — How feedback should sound (Passionate, Supportive, Neutral, Strict).
6. **Daily goal** — Daily practice time (Hiker / Climber / Summiter / Mountaineer).
7. **Complete** — Summary; finishing calls `saveAll()` and marks onboarding complete.

Progress is saved when the user taps **Back** on any step (`saveProgress()`). Completing the last step calls `saveAll()` and sets `onboarding_complete: true`.

---

## Directory layout

| Folder         | Purpose |
|----------------|--------|
| **controllers/** | State and logic for the flow. Pages call the controller; the controller updates state and talks to Supabase. |
| **models/**      | Data shapes only (no UI, no API). |
| **pages/**       | Full screens. One file per step (or shared pieces like the header). |
| **widgets/**     | Reusable UI used by the pages (e.g. labeled fields, language dropdown). |

---

## `controllers/`

- **`onboarding_controller.dart`** — Holds step answers (`OnboardingData`: skill level, learning goal, accent, feedback tone, daily pace). Methods: `setSkillAssess`, `setLearningGoal`, etc.; `saveProgress()` (persist without marking complete); `handleBack(context)` (save then pop); `saveAll()` (persist and set `onboarding_complete: true`). Used by steps 1–5 and the complete page.
- **`onboarding_user_info_controller.dart`** — Validation and error state for the user-info form (full name, username, email, password, native language). Used only by the user-info page.

---

## `models/`

- **`onboarding_data.dart`** — Plain data class for the step answers: `learningGoal`, `feedbackTone`, `accent`, `dailyPace`, `skillAssess`. Maps to profile columns (`learning_goal`, `feedback_tone`, `accent`, `daily_pace`, `level`).

---

## `pages/`

- **`onboarding_user_info_page.dart`** — Sign-up form and “Continue” that calls auth + `/profile/init`.
- **`skill_assess.dart`** — Step 1: current level (Beginner / Intermediate / Advanced).
- **`learning_goal.dart`** — Step 2: why learning (Travel, Career, Culture, Brain Training).
- **`accent_selection.dart`** — Step 3: target accent.
- **`feedback_tone.dart`** — Step 4: feedback tone.
- **`daily_goal.dart`** — Step 5: daily pace; “Continue” calls `saveAll()` then navigates to complete.
- **`onboarding_complete.dart`** — “All set!” screen after the last step.
- **`onboarding_header.dart`** — Shared top bar and progress (step X of Y, back button, right label). Used by the five step pages.

---

## `widgets/`

- **`onboarding_labeled_field.dart`** — Label + child (e.g. text field) for the user-info form.
- **`onboarding_language_dropdown.dart`** — Native language dropdown used on the user-info page.

---

## Where to put new code

| If you're adding…                         | Put it in…      |
|-------------------------------------------|-----------------|
| A new full screen in the flow             | `pages/`        |
| Reusable UI (card, field, dropdown)       | `widgets/`      |
| Logic for a step or back/save behavior    | `controllers/`  |
| A new field in the step/profile payload   | `models/`       |

Example: “When the user picks a level, save it” → controller (`setSkillAssess` + `saveProgress` / `saveAll`).  
Example: “A new step asking for their goal date” → new page in `pages/`, new field in `OnboardingData` and in the controller’s update map.
