"""
Pydantic schemas for request/response shapes.

Purpose:
- Define the "API contract" for courses endpoints.
- Validate inputs and structure outputs consistently.

Rule of thumb:
- CourseCreate = what the client sends to create a course.
- CourseOut    = what our API returns back to the client.
"""

from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID


class CourseCreate(BaseModel):
    """
    Request body for creating a course.

    Example:
    { "title": "Travel phrases for restaurants" }

    Field constraints:
    - min_length prevents empty/whitespace titles
    - max_length prevents unbounded strings
    """
    title: str = Field(min_length=1, max_length=200)


class CourseOut(BaseModel):
    """
    Response shape for a course returned from the DB.

    Fields match the columns we select from Supabase.
    Supabase returns JSON, and Pydantic converts types:
    - id/user_id -> UUID
    - created_at -> datetime
    """
    id: UUID
    user_id: UUID
    title: str
    created_at: datetime