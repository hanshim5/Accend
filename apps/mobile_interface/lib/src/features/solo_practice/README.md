# Solo Practice feature

This feature is the “read aloud and get pronunciation feedback” flow. Here’s what each folder does.

---

## `controllers/`

**What it is:** The brain for the screen.

Holds the **state** (which card you’re on, mic state, current feedback) and the **logic** (submit, next card, retry, reset). The page doesn’t decide “what happens when you tap Submit” — the controller does. The page just calls the controller and then redraws.

- **`solo_practice_controller.dart`** — Tracks card index, mic state (idle / recording / playback), feedback result. Methods like `submit()`, `advanceToNextCard()`, `retry()`, `resetSession()`.

---

## `models/`

**What it is:** The shapes of the data.

Plain Dart classes that describe what something *is* (e.g. “feedback has an accuracy score and a list of words”). No UI, no API calls — just data structures.

- **`pronunciation_feedback.dart`** — Types for the pronunciation result: `PhonemeFeedback`, `WordFeedback`, `PronunciationFeedbackMock` (scores and word-level breakdown).

---

## `pages/`

**What it is:** The actual screen the user sees.

One file per full screen. The page builds the layout (buttons, progress bar, cards) and wires taps to the controller. It does **not** contain the business logic — that lives in the controller.

- **`solo_practice_page.dart`** — The solo practice screen: prompt card, mic button, Retry/Submit, feedback card, Next. Uses `SoloPracticeController` and `FeedbackCard` widget.

---

## `services/`

**What it is:** Talking to the outside world.

Calls the API (or anything that isn’t UI or local state). The controller uses the service to get pronunciation feedback; the page never calls the API directly.

- **`pronunciation_feedback_service.dart`** — Sends audio + reference text to the backend, parses the response, and has a fallback that returns mock feedback if the API fails.

---

## `widgets/`

**What it is:** Reusable pieces of UI used by the page.

Smaller, self-contained components. The page composes them instead of putting hundreds of lines of UI in one file.

- **`feedback_card.dart`** — The card that shows after Submit: word chips, score chips (Accuracy / Fluency / Complete), and the Next button. Includes the phoneme drill-down dialog when you tap a word.

---

## Summary

| Folder       | In one sentence |
|-------------|------------------|
| **controllers/** | State and logic for the flow (card index, mic, submit, next). |
| **models/**      | Data shapes (feedback, words, phonemes). |
| **pages/**       | The screen layout and wiring to the controller. |
| **services/**    | API calls and mock feedback. |
| **widgets/**     | Reusable UI bits (e.g. the feedback card). |

You’ll usually: **page** uses **controller** and **widgets**; **controller** uses **models** and **services**.

---

## Where does X go?

Use this when adding something new (or when AI/tools need to decide where code belongs):

| If you're adding… | Put it in… |
|-------------------|------------|
| A new full screen | `pages/` |
| A reusable UI component (card, list item, button group) | `widgets/` |
| State or logic for the flow (e.g. “when user taps Y, do Z”) | `controllers/` |
| A call to an API or external service | `services/` |
| A data class / type (no UI, no API, just fields) | `models/` |

**Examples:** “Where does the logic for loading the next prompt go?” → **controllers/**  
“Where does the type for a practice session go?” → **models/**  
“Where does the widget that shows one exercise card go?” → **widgets/**
