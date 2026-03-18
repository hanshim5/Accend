# Solo Practice feature

This feature is the "read aloud and get pronunciation feedback" flow. Here's what each folder does.

---

## Top-level files

- **`solo_practice_debug.dart`** — A standalone `main()` entry point that runs `SoloPracticePage` in isolation. Use this for quick UI iteration without booting the full app shell.

---

## `controllers/`

**What it is:** The brain for the screen.

Holds the **state** (which card you're on, mic state, current feedback) and the **logic** (submit, next card, retry, reset). The page doesn't decide "what happens when you tap Submit" — the controller does. The page just calls the controller and then redraws.

- **`solo_practice_controller.dart`** — Tracks card index, mic state (`0` idle / `1` recording / `2` playback), and current feedback result. Methods: `submit()`, `advanceToNextCard()`, `retry()`, `resetSession()`.

---

## `models/`

**What it is:** The shapes of the data.

Plain Dart classes that describe what something *is*. No UI, no API calls — just data structures.

- **`pronunciation_feedback.dart`** — Types for the pronunciation result:
  - `PhonemeFeedback` — a single phoneme: `symbol`, `accuracy`, `userSaid` (top detected phoneme from Azure's `NBestPhonemes`)
  - `WordFeedback` — a word with its `accuracy`, `errorType` (Azure miscue, e.g. `"Omission"`), and a list of `PhonemeFeedback`
  - `PronunciationFeedbackMock` — top-level result: `accuracyScore`, `fluencyScore`, `completenessScore`, optional `pronScore` and `summary` tip, and `words`
  - `phonemeInstructions` — a top-level `const Map<String, String>` (40+ ARPAbet entries) with human-readable articulation instructions shown in the phoneme detail popup

**External models this feature depends on** (from `features/courses/models/`):
- `LessonItem` — a single practice prompt with `text`, optional `ipa`, optional `hint`, `position`, `id`, `lessonId`
- `Lesson` — a container of `LessonItem`s with `title`, `courseId`, `isCompleted`

---

## `pages/`

**What it is:** The actual screen the user sees.

One file per full screen. The page builds the layout and wires taps to the controller. Business logic lives in the controller, not here.

- **`solo_practice_page.dart`** — The solo practice screen. Accepts an optional `Lesson`; if `null`, falls back to 20 built-in tongue twisters. Layout (top → bottom):
  1. **Header** — back button (resets session + pops), progress counter, lesson title, `LinearProgressIndicator`
  2. **Body** — while submitting: spinner + "Analysing your pronunciation…"; before feedback: prompt card (text, optional IPA, optional hint) + instruction; after feedback: inline `FeedbackCard`
  3. **Footer** — mic controls: single `Microphone` widget (record/stop) in states 0 and 1; Retry + playback + Submit row in state 2; Submit label becomes "Finish" on the last card

---

## `services/`

**What it is:** Talking to the outside world.

Calls the API (or anything that isn't UI or local state). The controller uses the service; the page never calls the API directly.

- **`pronunciation_feedback_service.dart`** — Two public functions:
  - `fetchPronunciationFeedback({audioBytes, referenceText, accessToken?})` — `multipart/form-data POST` to `/pronunciation/assess` on the API gateway (`localhost:8080` on iOS/desktop, `10.0.2.2:8080` on Android emulator). Returns `null` on any error, which triggers the fallback in the controller.
  - `getMockFeedback(String referenceText)` — offline fallback; generates plausible word- and phoneme-level scores from the reference text alone.

---

## `widgets/`

**What it is:** Reusable pieces of UI used by the page.

Smaller, self-contained components. The page composes them instead of putting hundreds of lines of UI in one file.

- **`feedback_card.dart`** — Contains several components:
  - **`FeedbackCard`** — the main result card shown after Submit. Renders all words as tappable `ActionChip`s colored by accuracy (green ≥ 85, orange ≥ 60, red < 60). Tapping a word opens a phoneme breakdown dialog. Also shows three `ScoreChip`s (Accuracy / Fluency / Completeness) and "Try Again" / "Next" buttons.
  - **`ScoreChip`** — small label + rounded score value; used three times in `FeedbackCard`.
  - **`showPhonemeDialog`** (inline function) — `AlertDialog` showing "You said:" and "Should be:" chip rows for each phoneme in a word.
  - **`_PhonemeDetailDialog`** (private `StatefulWidget`) — dialog for a single phoneme: shows the symbol, accuracy score, articulation instruction from `phonemeInstructions`, and a play/stop button that streams reference audio from **Supabase Storage** (`phoneme-audio` bucket, `{symbol}.m4a`).

---

## Summary

| Folder | In one sentence |
|---|---|
| **controllers/** | State and logic for the flow (card index, mic state, submit, next). |
| **models/** | Data shapes (feedback, words, phonemes, articulation instructions). |
| **pages/** | The screen layout and wiring to the controller. |
| **services/** | API calls and mock feedback fallback. |
| **widgets/** | Reusable UI bits (feedback card, score chips, phoneme dialogs). |

You'll usually: **page** uses **controller** and **widgets**; **controller** uses **models** and **services**.

---

## Key integrations

| Integration | Details |
|---|---|
| **API Gateway** | `POST /pronunciation/assess` — multipart WAV + reference text upload |
| **Supabase Storage** | `phoneme-audio` bucket; `{symbol}.m4a` files streamed in `_PhonemeDetailDialog` |
| **Supabase Auth** | JWT from `AuthService` forwarded as `Authorization: Bearer …` to the gateway |
| **Azure Speech SDK** (backend) | Upstream pronunciation assessment — JSON shape mirrors Azure Pronunciation Assessment output |
| `audioplayers` | WAV playback (`DeviceFileSource`) and phoneme audio streaming (`UrlSource`) |
| `record` | Mic input captured as WAV (16 kHz, mono) via the shared `Microphone` widget |

---

## Where does X go?

Use this when adding something new (or when AI/tools need to decide where code belongs):

| If you're adding… | Put it in… |
|---|---|
| A new full screen | `pages/` |
| A reusable UI component (card, list item, button group) | `widgets/` |
| State or logic for the flow (e.g. "when user taps Y, do Z") | `controllers/` |
| A call to an API or external service | `services/` |
| A data class / type (no UI, no API, just fields) | `models/` |
| A standalone debug runner | top-level (next to `README.md`) |

**Examples:** "Where does the logic for loading the next prompt go?" → **controllers/**  
"Where does the type for a practice session go?" → **models/**  
"Where does the widget that shows one exercise card go?" → **widgets/**

---

# Todo
- Fix display when user adds/omits words
