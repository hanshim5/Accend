"""
image_selection_service.py

Course Image Selection Service

Purpose:
- Choose a representative image URL for a generated course.
- Prefer topic-relevant images when the course title clearly suggests a topic.
- Fall back to a general language-learning image pool otherwise.

Design:
- Deterministic selection: the same title should map to the same image.
- Topic-aware: simple keyword matching for obvious categories.
- Easy to move later into another service if image handling is separated.

Notes:
- This service does NOT generate images.
- It only selects from a predefined pool of hosted image URLs.
- Replace the placeholder URLs below with real storage URLs.
"""

from __future__ import annotations

import hashlib
import re


# -----------------------------------
# Image Pools
# -----------------------------------

TOPIC_IMAGE_POOLS: dict[str, list[str]] = {
    "business": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/business-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/business-2.jpg",
    ],
    "travel": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/travel-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/travel-2.jpg",
    ],
    "grammar": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/grammar-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/grammar-2.jpg",
    ],
    "pronunciation": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/pronunciation-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/pronunciation-2.jpg",
    ],
    "conversation": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/conversation-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/conversation-2.jpg",
    ],
    "vocabulary": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/vocabulary-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/vocabulary-2.jpg",
    ],
    "reading": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/reading-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/reading-2.jpg",
    ],
    "writing": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/writing-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/writing-2.jpg",
    ],
    "listening": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/listening-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/listening-2.jpg",
    ],
    "interview_workplace": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/interview-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/interview-2.jpg",
    ],
    "academic": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/academic-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/academic-2.jpg",
    ],
    "presentation": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/presentation-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/presentation-2.jpg",
    ],
}

GENERAL_IMAGE_POOL: list[str] = [
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/abstract-learning-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/study-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/speaking-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/global-1.jpg",
]


# -----------------------------------
# Topic Keywords
# -----------------------------------

TOPIC_KEYWORDS: dict[str, list[str]] = {
    "business": [
        "business",
        "professional",
        "office",
        "corporate",
        "career",
        "work",
    ],
    "travel": [
        "travel",
        "trip",
        "airport",
        "hotel",
        "tourism",
        "vacation",
    ],
    "grammar": [
        "grammar",
        "tense",
        "sentence",
        "syntax",
        "structure",
    ],
    "pronunciation": [
        "pronunciation",
        "accent",
        "phoneme",
        "phonetics",
        "speech",
    ],
    "conversation": [
        "conversation",
        "dialogue",
        "small talk",
        "speaking",
        "chat",
    ],
    "vocabulary": [
        "vocabulary",
        "words",
        "phrases",
        "terms",
        "lexicon",
    ],
    "reading": [
        "reading",
        "comprehension",
        "read",
        "passage",
        "text analysis",
    ],
    "writing": [
        "writing",
        "essay",
        "email",
        "compose",
        "written",
    ],
    "listening": [
        "listening",
        "listen",
        "audio",
        "hearing",
    ],
    "interview_workplace": [
        "interview",
        "job interview",
        "workplace",
        "meeting",
        "client",
        "coworker",
    ],
    "academic": [
        "academic",
        "school",
        "classroom",
        "student",
        "university",
        "college",
        "exam",
    ],
    "presentation": [
        "presentation",
        "public speaking",
        "speech",
        "talk",
        "pitch",
        "presenting",
    ],
}


# -----------------------------------
# Helpers
# -----------------------------------

def _normalize_title(title: str) -> str:
    """
    Normalize a course title for keyword matching.

    Behavior:
    - lowercases
    - strips leading/trailing whitespace
    - collapses punctuation into spaces
    - collapses repeated whitespace
    """
    text = title.strip().lower()
    text = re.sub(r"[^a-z0-9\s]+", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text


def _stable_index(key: str, pool_size: int) -> int:
    """
    Deterministically map a string key into a valid pool index.

    Why:
    - Same title should get the same image every time.
    - Avoids random changes across environments or requests.
    """
    if pool_size <= 0:
        raise ValueError("pool_size must be greater than 0")

    digest = hashlib.md5(key.encode("utf-8")).hexdigest()
    return int(digest, 16) % pool_size


def _detect_topic(title: str) -> str | None:
    """
    Return the best-matching topic key for a title, or None if no match is found.

    Matching strategy:
    - simple keyword containment on a normalized title
    - first strong match wins

    This is intentionally lightweight and easy to adjust.
    """
    normalized = _normalize_title(title)

    for topic, keywords in TOPIC_KEYWORDS.items():
        for keyword in keywords:
            if keyword in normalized:
                return topic

    return None


# -----------------------------------
# Public API
# -----------------------------------

def select_course_image(title: str) -> str:
    """
    Choose an image URL for a generated course title.

    Strategy:
    1. Detect whether the title clearly matches a known topic.
    2. If so, choose a stable image from that topic's pool.
    3. Otherwise choose a stable image from the general fallback pool.

    Returns:
    - A non-empty image URL string.

    Fallback behavior:
    - If a topic pool is missing or empty, fall back to the general pool.
    """
    safe_title = (title or "").strip() or "untitled course"
    topic = _detect_topic(safe_title)

    if topic:
        pool = TOPIC_IMAGE_POOLS.get(topic, [])
        if pool:
            idx = _stable_index(safe_title, len(pool))
            return pool[idx]

    idx = _stable_index(safe_title, len(GENERAL_IMAGE_POOL))
    return GENERAL_IMAGE_POOL[idx]