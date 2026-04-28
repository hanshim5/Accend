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

        blocked_set = await self._get_blocked_and_blocker_ids(user_id)
        follower_ids = [fid for fid in follower_ids if fid not in blocked_set]
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
        i_block_ids = {bid for bid in blocked_set if bid in set(follower_ids)}
        metrics = await self._get_social_metrics(follower_ids)
        await self._sync_missing_profile_levels(profiles, metrics["level"])

        return [
            self._to_social_user(
                profiles[follower_id],
                i_follow=follower_id in i_follow_ids,
                follows_me=True,
                i_block=follower_id in i_block_ids,
                level=metrics["level"].get(follower_id, 1),
                current_streak=metrics["streak"].get(follower_id, 0),
                overall_accuracy=metrics["accuracy"].get(follower_id, 0.0),
                lessons_completed=metrics["lessons"].get(follower_id, 0),
                meters_climbed=metrics["meters"].get(follower_id, 0),
                reputation=metrics["reputation"].get(follower_id, 0),
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

        blocked_set = await self._get_blocked_and_blocker_ids(user_id)
        followee_ids = [fid for fid in followee_ids if fid not in blocked_set]
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
                i_block=False,
                level=metrics["level"].get(followee_id, 1),
                current_streak=metrics["streak"].get(followee_id, 0),
                overall_accuracy=metrics["accuracy"].get(followee_id, 0.0),
                lessons_completed=metrics["lessons"].get(followee_id, 0),
                meters_climbed=metrics["meters"].get(followee_id, 0),
                reputation=metrics["reputation"].get(followee_id, 0),
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

        # Only hide users who have blocked you — you can still find users you've blocked to unblock them.
        blocker_ids = await self._get_blocker_ids(user_id)
        rows = [row for row in rows if row.get("id") not in blocker_ids]
        candidate_ids = [row["id"] for row in rows if row.get("id")]
        if not candidate_ids:
            return []

        i_block_ids = await self._get_i_block_ids(user_id)

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
                i_block=row["id"] in i_block_ids,
                level=metrics["level"].get(row["id"], 1),
                current_streak=metrics["streak"].get(row["id"], 0),
                overall_accuracy=metrics["accuracy"].get(row["id"], 0.0),
                lessons_completed=metrics["lessons"].get(row["id"], 0),
                meters_climbed=metrics["meters"].get(row["id"], 0),
                reputation=metrics["reputation"].get(row["id"], 0),
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

    async def block(self, blocker_id: UUID, blocked_id: UUID) -> None:
        if blocker_id == blocked_id:
            from app.utils.errors import bad_request
            bad_request("cannot block yourself")

        existing = await supabase.get(
            "user_blocks",
            params={
                "select": "blocker_id",
                "blocker_id": f"eq.{blocker_id}",
                "blocked_id": f"eq.{blocked_id}",
                "limit": "1",
            },
        )
        if existing:
            return

        try:
            await supabase.post(
                "user_blocks",
                json={
                    "blocker_id": str(blocker_id),
                    "blocked_id": str(blocked_id),
                },
            )
        except httpx.HTTPStatusError as e:
            if e.response is not None and e.response.status_code == 409:
                return
            raise

    async def unblock(self, blocker_id: UUID, blocked_id: UUID) -> None:
        await supabase.delete(
            "user_blocks",
            params={
                "blocker_id": f"eq.{blocker_id}",
                "blocked_id": f"eq.{blocked_id}",
            },
        )

    async def list_blocked_ids(self, user_id: UUID) -> list[str]:
        rows = await supabase.get(
            "user_blocks",
            params={
                "select": "blocked_id",
                "blocker_id": f"eq.{user_id}",
            },
        )
        return [row["blocked_id"] for row in rows if row.get("blocked_id")]

    async def list_blocked(self, user_id: UUID) -> list[SocialUserOut]:
        rows = await supabase.get(
            "user_blocks",
            params={"select": "blocked_id", "blocker_id": f"eq.{user_id}"},
        )
        blocked_ids = [row["blocked_id"] for row in rows if row.get("blocked_id")]
        if not blocked_ids:
            return []

        profiles = await self._get_profiles(blocked_ids)
        following_rows = await supabase.get(
            "user_follows",
            params={
                "select": "followee_id",
                "follower_id": f"eq.{user_id}",
                "followee_id": self._in_clause(blocked_ids),
            },
        )
        i_follow_ids = {row["followee_id"] for row in following_rows}
        metrics = await self._get_social_metrics(blocked_ids)
        await self._sync_missing_profile_levels(profiles, metrics["level"])

        return [
            self._to_social_user(
                profiles[bid],
                i_follow=bid in i_follow_ids,
                follows_me=False,
                i_block=True,
                level=metrics["level"].get(bid, 1),
                current_streak=metrics["streak"].get(bid, 0),
                overall_accuracy=metrics["accuracy"].get(bid, 0.0),
                lessons_completed=metrics["lessons"].get(bid, 0),
                meters_climbed=metrics["meters"].get(bid, 0),
                reputation=metrics["reputation"].get(bid, 0),
            )
            for bid in blocked_ids
            if bid in profiles
        ]

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
        # Delete all blocks where user is the blocker or blocked
        await supabase.delete(
            "user_blocks",
            params={"blocker_id": f"eq.{user_id}"},
        )
        await supabase.delete(
            "user_blocks",
            params={"blocked_id": f"eq.{user_id}"},
        )

    async def profiles_by_ids(self, user_ids: list[str]) -> list[SocialUserOut]:
        """Return basic profile + reputation for any list of user IDs."""
        if not user_ids:
            return []
        profiles = await self._get_profiles(user_ids)
        if not profiles:
            return []
        metrics = await self._get_social_metrics(list(profiles.keys()))
        await self._sync_missing_profile_levels(profiles, metrics["level"])
        return [
            self._to_social_user(
                profiles[uid],
                i_follow=False,
                follows_me=False,
                i_block=False,
                level=metrics["level"].get(uid, 1),
                current_streak=metrics["streak"].get(uid, 0),
                overall_accuracy=metrics["accuracy"].get(uid, 0.0),
                lessons_completed=metrics["lessons"].get(uid, 0),
                meters_climbed=metrics["meters"].get(uid, 0),
                reputation=metrics["reputation"].get(uid, 0),
            )
            for uid in user_ids
            if uid in profiles
        ]

    async def apply_vote_delta(self, target_id: UUID, delta: int) -> None:
        """
        Apply a reputation delta (+1 or -1) to a target user's user_stats.reputation.

        Uses read-modify-write. If no stats row exists, inserts one.
        Self-voting is rejected by the router before reaching here.
        """
        rows = await supabase.get(
            "user_stats",
            params={
                "select": "user_id,reputation",
                "user_id": f"eq.{target_id}",
                "limit": "1",
            },
        )
        if rows:
            current = int(rows[0].get("reputation") or 0)
            await supabase.patch(
                "user_stats",
                params={"user_id": f"eq.{target_id}"},
                json={"reputation": current + delta},
            )
        else:
            try:
                await supabase.post(
                    "user_stats",
                    json={"user_id": str(target_id), "reputation": delta},
                )
            except httpx.HTTPStatusError as e:
                if e.response is not None and e.response.status_code == 409:
                    rows2 = await supabase.get(
                        "user_stats",
                        params={"select": "reputation", "user_id": f"eq.{target_id}", "limit": "1"},
                    )
                    current = int(rows2[0].get("reputation") or 0) if rows2 else 0
                    await supabase.patch(
                        "user_stats",
                        params={"user_id": f"eq.{target_id}"},
                        json={"reputation": current + delta},
                    )
                else:
                    raise

    async def get_own_reputation(self, user_id: UUID) -> int:
        rows = await supabase.get(
            "user_stats",
            params={
                "select": "reputation",
                "user_id": f"eq.{user_id}",
                "limit": "1",
            },
        )
        if not rows:
            return 0
        return int(rows[0].get("reputation") or 0)

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

    async def _get_blocked_and_blocker_ids(self, user_id: UUID) -> set[str]:
        """Return all user IDs in a block relationship with user_id (either direction)."""
        blocker_rows = await supabase.get(
            "user_blocks",
            params={"select": "blocked_id", "blocker_id": f"eq.{user_id}"},
        )
        blocked_by_rows = await supabase.get(
            "user_blocks",
            params={"select": "blocker_id", "blocked_id": f"eq.{user_id}"},
        )
        return (
            {row["blocked_id"] for row in blocker_rows if row.get("blocked_id")}
            | {row["blocker_id"] for row in blocked_by_rows if row.get("blocker_id")}
        )

    async def _get_blocker_ids(self, user_id: UUID) -> set[str]:
        """Return user IDs of people who have blocked the current user."""
        rows = await supabase.get(
            "user_blocks",
            params={"select": "blocker_id", "blocked_id": f"eq.{user_id}"},
        )
        return {row["blocker_id"] for row in rows if row.get("blocker_id")}

    async def _get_i_block_ids(self, user_id: UUID) -> set[str]:
        """Return user IDs that the current user has blocked."""
        rows = await supabase.get(
            "user_blocks",
            params={"select": "blocked_id", "blocker_id": f"eq.{user_id}"},
        )
        return {row["blocked_id"] for row in rows if row.get("blocked_id")}

    def _to_social_user(
        self,
        row: dict,
        *,
        i_follow: bool,
        follows_me: bool,
        i_block: bool = False,
        level: int,
        current_streak: int,
        overall_accuracy: float,
        lessons_completed: int,
        meters_climbed: int,
        reputation: int = 0,
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
            reputation=int(reputation),
            i_follow=i_follow,
            follows_me=follows_me,
            i_block=i_block,
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
                    "select": "user_id,lessons_completed,overall_accuracy,meters_climbed,level,reputation",
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
                    "select": "user_id,lessons_completed,overall_accuracy,meters_climbed,reputation",
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
        reputation_map: dict[str, int] = {
            str(row.get("user_id")): int(row.get("reputation", 0) or 0)
            for row in lessons_rows
            if row.get("user_id")
        }

        return {
            "streak": streak_map,
            "accuracy": accuracy_map,
            "lessons": lessons_map,
            "meters": meters_map,
            "level": level_map,
            "reputation": reputation_map,
        }

    @staticmethod
    def _level_from_meters(meters_climbed: int) -> int:
        safe_meters = max(0, int(meters_climbed))
        return (safe_meters // 1000) + 1