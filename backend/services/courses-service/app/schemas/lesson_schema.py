"""
lesson_schema.py

Lesson Schemas (Data Models)

Purpose:
- Define the request and response shapes for lesson-related data.
- Enforce validation rules for lesson and lesson item creation.
- Provide structured types for communication between API, service, and repository layers.

Architecture:
- Routers use these schemas for request validation and response serialization.
- Services and repositories use them for typed data handling.
- These map closely to database tables (lessons, lesson_items) but are API-focused.

Schema Types:
- *Create*: Used for incoming requests (client → API)
- *Out*: Used for responses (API → client)
- *Composite*: Nested structures (e.g., lessons with items)
"""

from __future__ import annotations

from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID


class LessonItemCreate(BaseModel):
    """
    Input schema for creating a single lesson item.

    Represents one pronunciation prompt inside a lesson.

    Fields:
    - text: The phrase or sentence the user should pronounce.
    - ipa: Optional phonetic representation (shown on demand).
    - hint: Optional helper text for the user.
    """
    text: str = Field(min_length=1, max_length=300)
    ipa: str | None = Field(default=None, max_length=300)
    hint: str | None = Field(default=None, max_length=500)


class LessonCreate(BaseModel):
    """
    Input schema for creating a full lesson with items.

    Used primarily by the AI generation flow to create structured lessons
    in a single request.

    Fields:
    - title: Name of the lesson (e.g., "Ordering Food").
    - items: Ordered list of lesson items (must contain at least one).
    """
    title: str = Field(min_length=1, max_length=200)
    items: list[LessonItemCreate] = Field(min_length=1, max_length=200)


class LessonItemOut(BaseModel):
    """
    Output schema for a lesson item.

    Represents a persisted lesson item returned from the database.

    Fields:
    - id: Unique identifier of the item.
    - lesson_id: Parent lesson reference.
    - position: Order of the item within the lesson.
    - text: Prompt text.
    - ipa: Optional phonetic transcription.
    - hint: Optional helper text.
    - created_at: Timestamp of creation.
    """
    id: UUID
    lesson_id: UUID
    position: int
    text: str
    ipa: str | None = None
    hint: str | None = None
    created_at: datetime


class LessonOut(BaseModel):
    """
    Output schema for a lesson (without items).

    Represents a lesson record from the database.

    Fields:
    - id: Unique identifier of the lesson.
    - course_id: Parent course reference.
    - position: Order of the lesson within the course.
    - title: Lesson title.
    - is_completed: Whether the lesson has been completed by the user.
    - created_at: Timestamp of creation.
    """
    id: UUID
    course_id: UUID
    position: int
    title: str
    is_completed: bool
    created_at: datetime


class LessonWithItemsOut(LessonOut):
    """
    Composite output schema for a lesson with its items.

    Extends LessonOut by including all associated lesson items.

    Used for:
    - Returning full curriculum data to the frontend.
    - Displaying lessons with their prompts in order.
    """
    items: list[LessonItemOut] = []


class CurriculumCreate(BaseModel):
    """
    Input schema for creating an entire curriculum (multiple lessons).

    Notes:
    - Lessons are expected in order.
    - The server assigns positions sequentially (1..N).
    - Each lesson must contain at least one item.

    Used by:
    - AI course generation to bulk-create lessons and items.
    """
    # lessons come in order; server assigns positions 1..N
    lessons: list[LessonCreate] = Field(min_length=1, max_length=100)