from uuid import UUID
import httpx

from app.clients.supabase import supabase
from app.schemas.follow_schema import SocialUserOut
from app.utils.errors import bad_request, not_found


class SupabaseFollowRepo:
    _profile_select = "id,username,full_name,level,native_language,learning_goal,focus_areas,profile_image_url"

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
        metrics = await self._get_social_metrics(follower_ids)
        await self._sync_missing_profile_levels(profiles, metrics["level"])

        return [
            self._to_social_user(
                profiles[follower_id],
                i_follow=follower_id in i_follow_ids,
                follows_me=True,
                level=metrics["level"].get(follower_id, 1),
                current_streak=metrics["streak"].get(follower_id, 0),
                overall_accuracy=metrics["accuracy"].get(follower_id, 0.0),
                lessons_completed=metrics["lessons"].get(follower_id, 0),
                meters_climbed=metrics["meters"].get(follower_id, 0),
            )
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
        metrics = await self._get_social_metrics(followee_ids)
        await self._sync_missing_profile_levels(profiles, metrics["level"])

        return [
            self._to_social_user(
                profiles[followee_id],
                i_follow=True,
                follows_me=followee_id in follows_me_ids,
                level=metrics["level"].get(followee_id, 1),
                current_streak=metrics["streak"].get(followee_id, 0),
                overall_accuracy=metrics["accuracy"].get(followee_id, 0.0),
                lessons_completed=metrics["lessons"].get(followee_id, 0),
                meters_climbed=metrics["meters"].get(followee_id, 0),
            )
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
        metrics = await self._get_social_metrics(candidate_ids)
        await self._sync_missing_profile_levels({row["id"]: row for row in rows if row.get("id")}, metrics["level"])

        return [
            self._to_social_user(
                row,
                i_follow=row["id"] in i_follow_ids,
                follows_me=row["id"] in follows_me_ids,
                level=metrics["level"].get(row["id"], 1),
                current_streak=metrics["streak"].get(row["id"], 0),
                overall_accuracy=metrics["accuracy"].get(row["id"], 0.0),
                lessons_completed=metrics["lessons"].get(row["id"], 0),
                meters_climbed=metrics["meters"].get(row["id"], 0),
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

    async def delete_account(self, user_id: UUID) -> None:
        """
        Delete all follow relationships for a user.

        This deletes:
        - All rows where user is the follower
        - All rows where user is the followee

        Called during account deletion cascade.
        """
        # Delete all follows where user is the follower
        await supabase.delete(
            "user_follows",
            params={"follower_id": f"eq.{user_id}"},
        )
        # Delete all follows where user is the followee
        await supabase.delete(
            "user_follows",
            params={"followee_id": f"eq.{user_id}"},
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

    def _to_social_user(
        self,
        row: dict,
        *,
        i_follow: bool,
        follows_me: bool,
        level: int,
        current_streak: int,
        overall_accuracy: float,
        lessons_completed: int,
        meters_climbed: int,
    ) -> SocialUserOut:
        display_name = row.get("full_name") or row.get("username") or "Unknown"
        profile_level = row.get("level")
        safe_level = max(1, int(profile_level)) if profile_level is not None else max(1, int(level))

        return SocialUserOut(
            id=row["id"],
            display_name=display_name,
            username=row.get("username") or "unknown",
            level=safe_level,
            level_label=f"Level {safe_level}",
            native_language=row.get("native_language"),
            learning_goal=row.get("learning_goal"),
            focus_areas=row.get("focus_areas"),
            current_streak=max(0, int(current_streak)),
            overall_accuracy=max(0.0, min(100.0, float(overall_accuracy))),
            lessons_completed=max(0, int(lessons_completed)),
            meters_climbed=max(0, int(meters_climbed)),
            i_follow=i_follow,
            follows_me=follows_me,
            profile_image_url=row.get("profile_image_url"),
        )

    async def _sync_missing_profile_levels(
        self,
        profiles: dict[str, dict],
        level_map: dict[str, float | int],
    ) -> None:
        for user_id, profile in profiles.items():
            if profile.get("level") is not None:
                continue

            target_level = max(1, int(level_map.get(user_id, 1) or 1))
            try:
                await supabase.patch(
                    "profiles",
                    params={
                        "id": f"eq.{user_id}",
                        "select": "id,level",
                    },
                    json={"level": target_level},
                )
                profile["level"] = target_level
            except httpx.HTTPStatusError:
                # Do not fail social read if a profile-level repair fails.
                continue

    async def _get_social_metrics(self, user_ids: list[str]) -> dict[str, dict[str, float | int]]:
        if not user_ids:
            return {
                "streak": {},
                "accuracy": {},
                "lessons": {},
                "meters": {},
                "level": {},
            }

        streak_rows = await supabase.get(
            "profiles",
            params={
                "select": "id,current_streak",
                "id": self._in_clause(user_ids),
            },
        )

        try:
            lessons_rows = await supabase.get(
                "user_stats",
                params={
                    "select": "user_id,lessons_completed,overall_accuracy,meters_climbed,level",
                    "user_id": self._in_clause(user_ids),
                },
            )
        except httpx.HTTPStatusError as e:
            # Backward-compatible fallback for environments where user_stats.level
            # has not been deployed yet.
            if e.response is None or e.response.status_code != 400:
                raise
            lessons_rows = await supabase.get(
                "user_stats",
                params={
                    "select": "user_id,lessons_completed,overall_accuracy,meters_climbed",
                    "user_id": self._in_clause(user_ids),
                },
            )

        streak_map: dict[str, int] = {
            str(row.get("id")): int(row.get("current_streak", 0) or 0)
            for row in streak_rows
            if row.get("id")
        }
        lessons_map: dict[str, int] = {
            str(row.get("user_id")): int(row.get("lessons_completed", 0) or 0)
            for row in lessons_rows
            if row.get("user_id")
        }
        accuracy_map: dict[str, float] = {
            str(row.get("user_id")): float(row.get("overall_accuracy", 0.0) or 0.0)
            for row in lessons_rows
            if row.get("user_id")
        }
        meters_map: dict[str, int] = {
            str(row.get("user_id")): (
                max(0, int(row.get("meters_climbed")))
                if row.get("meters_climbed") is not None
                else max(0, int(row.get("lessons_completed", 0) or 0)) * 100
            )
            for row in lessons_rows
            if row.get("user_id")
        }
        level_map: dict[str, int] = {
            str(row.get("user_id")): (
                max(1, int(row.get("level")))
                if row.get("level") is not None
                else self._level_from_meters(
                    max(0, int(row.get("meters_climbed")))
                    if row.get("meters_climbed") is not None
                    else max(0, int(row.get("lessons_completed", 0) or 0)) * 100
                )
            )
            for row in lessons_rows
            if row.get("user_id")
        }

        return {
            "streak": streak_map,
            "accuracy": accuracy_map,
            "lessons": lessons_map,
            "meters": meters_map,
            "level": level_map,
        }

    @staticmethod
    def _level_from_meters(meters_climbed: int) -> int:
        safe_meters = max(0, int(meters_climbed))
        return (safe_meters // 1000) + 1