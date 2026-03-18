# follow-service

Purpose:
- Own the follow graph in Supabase.
- Read followers/following for the authenticated user.
- Handle follow and unfollow mutations.

Architecture:
- routers -> services -> repositories -> supabase client
- Flutter never calls this service directly.
- The API Gateway validates JWT and forwards X-User-Id.

Owned table:
- user_follows

Read-only joined table:
- profiles

Routes:
- GET /followers
- GET /following
- POST /follow/{followee_id}
- DELETE /follow/{followee_id}
- GET /health