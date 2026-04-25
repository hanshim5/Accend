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
    "healthcare": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/healthcare-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/healthcare-2.jpeg",
    ],
    "restaurant_dining": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/restaurant-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/restaurant-2.jpeg",
    ],
    "shopping": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/shopping-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/shopping-2.jpeg",
    ],
    "customer_service": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/customer-service-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/customer-service-2.jpeg",
    ],
    "phone_calls": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/phone-call-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/phone-call-2.jpeg",
    ],
    "social_small_talk": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/small-talk-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/small-talk-2.jpeg",
    ],
    "dating_relationships": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/dating-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/dating-2.jpeg",
    ],
    "family_parenting": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/family-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/family-2.jpeg",
    ],
    "housing_daily_life": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/daily-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/daily-2.jpeg",
    ],
    "transportation": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/transportation-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/transportation-2.jpeg",
    ],
    "emergencies": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/emergency-1.jpg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/emergency-2.jpg",
    ],
    "technology": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/technology-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/technology-2.jpeg",
    ],
    "sports_fitness": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/sports-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/sports-2.jpeg",
    ],
    "entertainment_media": [
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/entertainment-1.jpeg",
        "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/entertainment-2.jpeg",
    ],
}

GENERAL_IMAGE_POOL: list[str] = [
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/abstract-learning-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/study-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/speaking-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/global-1.jpg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/classroom-1.jpeg",
    "https://ielsxciakbkhekjbdskt.supabase.co/storage/v1/object/public/course-images/communication-1.jpeg",
]


# -----------------------------------
# Topic Keywords
# -----------------------------------

TOPIC_KEYWORDS: dict[str, list[str]] = {
    "business": [
        "business",
        "professional",
        "corporate",
        "office",
        "career",
        "work",
        "workplace english",
        "business english",
        "professional communication",
        "email etiquette",
        "office communication",
        "executive",
        "manager",
        "team communication",
    ],
    "travel": [
        "travel",
        "trip",
        "vacation",
        "tourism",
        "tourist",
        "airport",
        "hotel",
        "check in",
        "boarding",
        "passport",
        "customs",
        "immigration",
        "directions",
        "sightseeing",
    ],
    "grammar": [
        "grammar",
        "tense",
        "tenses",
        "sentence",
        "sentences",
        "syntax",
        "structure",
        "verb forms",
        "articles",
        "prepositions",
        "sentence structure",
    ],
    "pronunciation": [
        "pronunciation",
        "accent",
        "phoneme",
        "phonemes",
        "phonetic",
        "phonetics",
        "speech sounds",
        "stress",
        "word stress",
        "intonation",
        "enunciation",
        "articulation",
        "minimal pairs",
    ],
    "conversation": [
        "conversation",
        "dialogue",
        "speaking",
        "chat",
        "communicating",
        "daily conversation",
        "conversation practice",
        "speaking practice",
        "interactive speaking",
    ],
    "vocabulary": [
        "vocabulary",
        "words",
        "phrases",
        "terms",
        "lexicon",
        "word bank",
        "expressions",
        "useful phrases",
        "topic vocabulary",
    ],
    "reading": [
        "reading",
        "read",
        "comprehension",
        "passage",
        "text analysis",
        "reading skills",
        "reading practice",
        "understanding texts",
    ],
    "writing": [
        "writing",
        "essay",
        "compose",
        "written",
        "paragraph",
        "journal",
        "composition",
        "email writing",
        "write clearly",
    ],
    "listening": [
        "listening",
        "listen",
        "audio",
        "hearing",
        "listening practice",
        "understanding spoken english",
        "comprehend speech",
    ],
    "interview_workplace": [
        "interview",
        "job interview",
        "mock interview",
        "resume interview",
        "workplace",
        "meeting",
        "meetings",
        "coworker",
        "colleague",
        "client",
        "manager",
        "supervisor",
        "office conversation",
        "team meeting",
    ],
    "academic": [
        "academic",
        "school",
        "classroom",
        "student",
        "students",
        "university",
        "college",
        "exam",
        "study skills",
        "lecture",
        "seminar",
        "campus",
        "assignment",
    ],
    "presentation": [
        "presentation",
        "public speaking",
        "speech",
        "talk",
        "pitch",
        "presenting",
        "presentations",
        "conference talk",
        "demo",
        "persuasive speaking",
    ],
    "healthcare": [
        "doctor",
        "hospital",
        "clinic",
        "medical",
        "health",
        "healthcare",
        "pharmacy",
        "dentist",
        "appointment",
        "symptoms",
        "patient",
        "nurse",
        "prescription",
    ],
    "restaurant_dining": [
        "restaurant",
        "dining",
        "food",
        "menu",
        "order food",
        "ordering food",
        "cafe",
        "coffee shop",
        "waiter",
        "server",
        "bill",
        "reservation",
        "takeout",
    ],
    "shopping": [
        "shopping",
        "store",
        "mall",
        "buying",
        "retail",
        "cashier",
        "checkout",
        "price",
        "sizes",
        "fitting room",
        "return item",
        "exchange item",
    ],
    "customer_service": [
        "customer service",
        "support",
        "help desk",
        "complaint",
        "refund",
        "return policy",
        "service desk",
        "call center",
        "assistance",
        "resolve an issue",
    ],
    "phone_calls": [
        "phone call",
        "phone calls",
        "telephone",
        "calling",
        "call someone",
        "leave a voicemail",
        "voicemail",
        "answer the phone",
        "speak on the phone",
        "booking by phone",
    ],
    "social_small_talk": [
        "small talk",
        "make friends",
        "meeting people",
        "introductions",
        "introduce yourself",
        "networking",
        "socializing",
        "casual conversation",
        "ice breaker",
        "party conversation",
    ],
    "dating_relationships": [
        "dating",
        "relationship",
        "romantic",
        "go on a date",
        "dating app",
        "flirting",
        "asking someone out",
        "couples communication",
    ],
    "family_parenting": [
        "family",
        "parenting",
        "parents",
        "kids",
        "children",
        "childcare",
        "school pickup",
        "talking to teachers",
        "home life",
    ],
    "housing_daily_life": [
        "housing",
        "apartment",
        "rent",
        "lease",
        "landlord",
        "roommate",
        "utilities",
        "chores",
        "daily life",
        "living situation",
        "neighborhood",
    ],
    "transportation": [
        "transportation",
        "bus",
        "train",
        "subway",
        "taxi",
        "uber",
        "rideshare",
        "driving",
        "traffic",
        "commute",
        "parking",
        "directions to station",
    ],
    "emergencies": [
        "emergency",
        "urgent",
        "911",
        "police",
        "fire",
        "ambulance",
        "accident",
        "report a problem",
        "ask for help",
        "safety",
    ],
    "technology": [
        "technology",
        "computer",
        "software",
        "app",
        "apps",
        "technical support",
        "it support",
        "device",
        "internet",
        "wifi",
        "password reset",
        "online meeting",
    ],
    "sports_fitness": [
        "sports",
        "fitness",
        "gym",
        "workout",
        "exercise",
        "training",
        "coach",
        "team sports",
        "yoga",
        "running",
    ],
    "entertainment_media": [
        "movies",
        "movie",
        "tv",
        "television",
        "music",
        "podcast",
        "books",
        "gaming",
        "video games",
        "entertainment",
        "media",
        "pop culture",
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
    return text.strip()


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
    normalized = f" {_normalize_title(title)} "

    for topic, keywords in TOPIC_KEYWORDS.items():
        for keyword in keywords:
            normalized_keyword = f" {_normalize_title(keyword)} "
            if normalized_keyword in normalized:
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