# progress-service

Purpose:
- Own all learner progress data in Supabase.
- Track course and lesson completion per user.
- Record daily study minutes for goal and streak calculation.
- Expose streak data (current + longest) for the home screen.

Architecture:
- routers -> services -> repositories -> supabase client
- Flutter never calls this service directly.
- The API Gateway validates JWT and forwards X-User-Id.

Owned tables:
- course_progress
- daily_minutes
- streaks

Port:
- Host: 8087
- Container: 8000
- Gateway env var: PROGRESS_SERVICE_URL=http://progress-service:8000

Routes (to be implemented):
- GET  /progress/{course_id}       — completion state for a course
- POST /progress/{course_id}       — upsert course/lesson completion
- GET  /streak                     — current and longest streak for user
- POST /daily-minutes              — log study minutes for today
- GET  /health
