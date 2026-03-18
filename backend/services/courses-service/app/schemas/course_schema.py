"""
course_schema.py

Course Schemas (Data Models)

Purpose:
- Define request and response shapes for course-related endpoints.
- Enforce input validation and ensure consistent API responses.
- Serve as the contract between frontend (Flutter) and backend.

Architecture:
- Routers use these schemas for request parsing and response serialization.
- Services and repositories use them for typed data handling.
- Closely mirror the 'courses' table but are API-focused.

Schema Types:
- CourseCreate → input from client (create operations)
- CourseOut    → output returned to client (read operations)
"""

from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID


class CourseCreate(BaseModel):
    """
    Input schema for creating a course.

    Example:
    { "title": "Travel phrases for restaurants" }

    Validation:
    - title must be non-empty (min_length=1)
    - title length is capped to prevent excessively large inputs
    """
    title: str = Field(min_length=1, max_length=200)


class CourseOut(BaseModel):
    """
    Output schema for a course.

    Represents a course record returned from the database.

    Fields:
    - id: Unique course identifier
    - user_id: Owner of the course
    - title: Course title
    - created_at: Timestamp of creation
    - progress_percent: Cached completion percentage (0–100)
    - status: Course state ("not_started", "in_progress", "completed")

    Notes:
    - Pydantic automatically converts:
        - UUID fields from strings
        - created_at from ISO string → datetime
    - progress_percent and status are included for fast UI rendering
      without recomputing progress on every request.
    """
    id: UUID
    user_id: UUID
    title: str
    created_at: datetime

    # Cached progress fields (derived from lesson completion)
    progress_percent: int = 0
    status: str = "not_started"