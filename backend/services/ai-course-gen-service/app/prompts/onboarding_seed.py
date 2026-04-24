"""
Onboarding seed prompts — hardcoded course-generation instructions per learning goal.

Maps profile learning_goal values (from the mobile app) to full prompts passed to
generate_course_from_prompt. Optional focus_areas tailor emphasis without exposing
raw templates to the client.
"""

from __future__ import annotations

# Keys must match learning_goal.dart backendValue strings.
ONBOARDING_GOAL_PROMPTS: dict[str, str] = {
    "travel": """
Create a practical English pronunciation and speaking course for someone preparing to travel.
Cover airport and transit, hotels and lodging, asking directions, ordering food and drinks,
handling problems politely, and small talk with locals. Use scenarios a traveler actually faces.
Emphasize clear, natural spoken English and phrases that work in real conversations abroad.
""".strip(),
    "career": """
Create an English pronunciation and speaking course focused on professional and workplace contexts.
Cover interviews and self-introductions, meetings and updates, email and chat style spoken aloud,
networking small talk, and presenting ideas clearly. Gear vocabulary and drills toward office
and business communication while keeping exercises speakable and concise.
""".strip(),
    "culture": """
Create an English pronunciation and speaking course for someone motivated by culture and connection.
Cover discussing customs and traditions, media and entertainment, art and history in plain language,
making friends across backgrounds, and expressing opinions respectfully. Blend social fluency with
clear pronunciation practice.
""".strip(),
    "brain_training": """
Create an English pronunciation and speaking course framed as cognitive and articulation training.
Use varied drills: tongue-twisters, minimal pairs, rhythm and stress patterns, short memory-challenge
recall phrases, and quick listen-and-repeat progressions. Keep it engaging like a mental workout while
still teaching usable spoken English.
""".strip(),
}

ALLOWED_LEARNING_GOALS = frozenset(ONBOARDING_GOAL_PROMPTS.keys())


def normalize_focus_areas(raw: list[str] | None) -> list[str]:
    """Trim, lowercase, drop empties; preserve order."""
    if not raw:
        return []
    out: list[str] = []
    for s in raw:
        t = (s or "").strip().lower().replace(" ", "_")
        if t:
            out.append(t)
    return out


def build_onboarding_seed_prompt(
    learning_goal: str,
    focus_areas: list[str] | None = None,
) -> str:
    """
    Combine the template for learning_goal with optional focus-area instructions.

    Raises:
        ValueError: if learning_goal is not one of the four known keys.
    """
    key = (learning_goal or "").strip().lower()
    if key not in ONBOARDING_GOAL_PROMPTS:
        raise ValueError(
            f"Invalid learning_goal: {learning_goal!r}. "
            f"Expected one of: {', '.join(sorted(ALLOWED_LEARNING_GOALS))}"
        )

    base = ONBOARDING_GOAL_PROMPTS[key]
    areas = normalize_focus_areas(focus_areas)
    if not areas:
        return base

    # Human-readable labels for the model (underscores → spaces).
    pretty = ", ".join(a.replace("_", " ") for a in areas)
    suffix = (
        f"\n\nThe learner asked to prioritize these skill areas in the course design "
        f"and practice items: {pretty}. Weave these priorities through lesson titles and items "
        f"where it fits naturally."
    )
    return base + suffix
