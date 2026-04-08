from uuid import UUID
import httpx

from app.clients.supabase import supabase
from app.schemas.follow_schema import SocialUserOut
from app.utils.errors import bad_request, not_found


class SupabaseFollowRepo:
    _profile_select = "id,username,full_name,level,skill_assess,native_language,learning_goal,focus_areas"

    async def get_counts(self, user_id: UUID) -> tuple[int, int]:
        followers_rows = await supabase.get(
            "user_follows",
            params={
                "select": "follower_id",
                "followee_id": f"eq.{user_id}",
            },
        )
        following_rows = await supabase.get(
            "user_follows",
            params={
                "select": "followee_id",
                "follower_id": f"eq.{user_id}",
            },
        )
        return len(followers_rows), len(following_rows)

    async def list_followers(self, user_id: UUID) -> list[SocialUserOut]:
        rows = await supabase.get(
            "user_follows",
            params={
                "select": "follower_id",
                "followee_id": f"eq.{user_id}",
                "order": "created_at.desc",
            },
        )
        follower_ids = self._distinct_ids(rows, "follower_id")
        if not follower_ids:
            return []

        profiles = await self._get_profiles(follower_ids)
        following_rows = await supabase.get(
            "user_follows",
            params={
                "select": "followee_id",
                "follower_id": f"eq.{user_id}",
                "followee_id": self._in_clause(follower_ids),
            },
        )
        i_follow_ids = {row["followee_id"] for row in following_rows}

        return [
            self._to_social_user(profiles[follower_id], i_follow=follower_id in i_follow_ids, follows_me=True)
            for follower_id in follower_ids
            if follower_id in profiles
        ]

    async def list_following(self, user_id: UUID) -> list[SocialUserOut]:
        rows = await supabase.get(
            "user_follows",
            params={
                "select": "followee_id",
                "follower_id": f"eq.{user_id}",
                "order": "created_at.desc",
            },
        )
        followee_ids = self._distinct_ids(rows, "followee_id")
        if not followee_ids:
            return []

        profiles = await self._get_profiles(followee_ids)
        follower_rows = await supabase.get(
            "user_follows",
            params={
                "select": "follower_id",
                "followee_id": f"eq.{user_id}",
                "follower_id": self._in_clause(followee_ids),
            },
        )
        follows_me_ids = {row["follower_id"] for row in follower_rows}

        return [
            self._to_social_user(profiles[followee_id], i_follow=True, follows_me=followee_id in follows_me_ids)
            for followee_id in followee_ids
            if followee_id in profiles
        ]

    async def search_profiles(self, user_id: UUID, q: str, limit: int) -> list[SocialUserOut]:
        query = q.strip()
        if not query:
            return []

        rows = await supabase.get(
            "profiles",
            params={
                "select": self._profile_select,
                "username": f"ilike.*{query}*",
                "id": f"neq.{user_id}",
                "order": "username.asc",
                "limit": str(limit),
            },
        )
        if not rows:
            return []

        candidate_ids = [row["id"] for row in rows if row.get("id")]
        if not candidate_ids:
            return []

        following_rows = await supabase.get(
            "user_follows",
            params={
                "select": "followee_id",
                "follower_id": f"eq.{user_id}",
                "followee_id": self._in_clause(candidate_ids),
            },
        )
        i_follow_ids = {row["followee_id"] for row in following_rows}

        follower_rows = await supabase.get(
            "user_follows",
            params={
                "select": "follower_id",
                "followee_id": f"eq.{user_id}",
                "follower_id": self._in_clause(candidate_ids),
            },
        )
        follows_me_ids = {row["follower_id"] for row in follower_rows}

        return [
            self._to_social_user(
                row,
                i_follow=row["id"] in i_follow_ids,
                follows_me=row["id"] in follows_me_ids,
            )
            for row in rows
            if row.get("id")
        ]

    async def follow(self, follower_id: UUID, followee_id: UUID) -> None:
        if follower_id == followee_id:
            bad_request("cannot follow yourself")

        target = await supabase.get(
            "profiles",
            params={
                "select": "id",
                "id": f"eq.{followee_id}",
                "limit": "1",
            },
        )
        if not target:
            not_found("follow target not found")

        existing = await supabase.get(
            "user_follows",
            params={
                "select": "follower_id,followee_id",
                "follower_id": f"eq.{follower_id}",
                "followee_id": f"eq.{followee_id}",
                "limit": "1",
            },
        )
        if existing:
            return

        try:
            await supabase.post(
                "user_follows",
                json={
                    "follower_id": str(follower_id),
                    "followee_id": str(followee_id),
                },
            )
        except httpx.HTTPStatusError as e:
            if e.response is not None and e.response.status_code == 409:
                # Duplicate follow requests are treated as success.
                return
            raise

    async def unfollow(self, follower_id: UUID, followee_id: UUID) -> None:
        await supabase.delete(
            "user_follows",
            params={
                "follower_id": f"eq.{follower_id}",
                "followee_id": f"eq.{followee_id}",
            },
        )

    async def _get_profiles(self, user_ids: list[str]) -> dict[str, dict]:
        rows = await supabase.get(
            "profiles",
            params={
                "select": self._profile_select,
                "id": self._in_clause(user_ids),
            },
        )
        return {row["id"]: row for row in rows}

    def _distinct_ids(self, rows: list[dict], key: str) -> list[str]:
        seen: set[str] = set()
        ordered: list[str] = []
        for row in rows:
            value = row.get(key)
            if not value or value in seen:
                continue
            seen.add(value)
            ordered.append(value)
        return ordered

    def _in_clause(self, values: list[str]) -> str:
        return "in.(" + ",".join(values) + ")"

    def _to_social_user(self, row: dict, *, i_follow: bool, follows_me: bool) -> SocialUserOut:
        level_label = row.get("skill_assess") or row.get("level") or None
        display_name = row.get("full_name") or row.get("username") or "Unknown"

        return SocialUserOut(
            id=row["id"],
            display_name=display_name,
            username=row.get("username") or "unknown",
            level_label=level_label,
            native_language=row.get("native_language"),
            learning_goal=row.get("learning_goal"),
            focus_areas=row.get("focus_areas"),
            i_follow=i_follow,
            follows_me=follows_me,
        )