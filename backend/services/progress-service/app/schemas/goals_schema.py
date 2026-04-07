from pydantic import BaseModel


class GoalProgressResponse(BaseModel):
    current_streak: int = 0
    longest_streak: int = 0
    current_minutes: int = 0
    goal_minutes: int = 10
