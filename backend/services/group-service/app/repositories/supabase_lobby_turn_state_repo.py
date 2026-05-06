from __future__ import annotations

from dataclasses import dataclass, field

from app.clients.supabase import rest_get, rest_patch, rest_post


@dataclass
class LobbyTurnStateRecord:
    scores_by_user: dict[str, float] = field(default_factory=dict)
    next_round_votes_by_user: set[str] = field(default_factory=set)
    event_seq: int = 0
    round_number: int = 0
    latest_scored_user_id: str | None = None


class SupabaseLobbyTurnStateRepo:
    """
    Stores per-lobby turn state in Supabase table `lobby_turn_state`.

    One row per lobby key (private/public + lobby id).
    """

    def _lobby_key(self, lobby_kind: str, lobby_id: int) -> str:
        return f"{lobby_kind}:{lobby_id}"

    def get_or_create_state(self, *, lobby_kind: str, lobby_id: int) -> LobbyTurnStateRecord:
        lobby_key = self._lobby_key(lobby_kind, lobby_id)
        rows = rest_get(
            table="lobby_turn_state",
            params={
                "select": "scores_by_user,next_round_votes,event_seq,round_number,latest_scored_user_id",
                "lobby_key": f"eq.{lobby_key}",
                "limit": "1",
            },
        )
        if rows:
            return self._from_row(rows[0])

        created = rest_post(
            table="lobby_turn_state",
            payload={
                "lobby_key": lobby_key,
                "lobby_kind": lobby_kind,
                "lobby_id": lobby_id,
                "scores_by_user": {},
                "next_round_votes": [],
                "event_seq": 0,
                "round_number": 0,
                "latest_scored_user_id": None,
            },
            select="scores_by_user,next_round_votes,event_seq,round_number,latest_scored_user_id",
        )
        if not created:
            raise RuntimeError("Failed to create lobby turn state row")
        return self._from_row(created[0])

    def save_state(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        state: LobbyTurnStateRecord,
    ) -> LobbyTurnStateRecord:
        lobby_key = self._lobby_key(lobby_kind, lobby_id)
        rows = rest_patch(
            table="lobby_turn_state",
            match={"lobby_key": f"eq.{lobby_key}"},
            payload={
                "scores_by_user": state.scores_by_user,
                "next_round_votes": sorted(state.next_round_votes_by_user),
                "event_seq": state.event_seq,
                "round_number": state.round_number,
                "latest_scored_user_id": state.latest_scored_user_id,
            },
            select="scores_by_user,next_round_votes,event_seq,round_number,latest_scored_user_id",
        )
        if rows:
            return self._from_row(rows[0])

        # Row was missing (cleanup race): recreate then save once.
        self.get_or_create_state(lobby_kind=lobby_kind, lobby_id=lobby_id)
        retry_rows = rest_patch(
            table="lobby_turn_state",
            match={"lobby_key": f"eq.{lobby_key}"},
            payload={
                "scores_by_user": state.scores_by_user,
                "next_round_votes": sorted(state.next_round_votes_by_user),
                "event_seq": state.event_seq,
                "round_number": state.round_number,
                "latest_scored_user_id": state.latest_scored_user_id,
            },
            select="scores_by_user,next_round_votes,event_seq,round_number,latest_scored_user_id",
        )
        if not retry_rows:
            raise RuntimeError("Failed to persist lobby turn state")
        return self._from_row(retry_rows[0])

    @staticmethod
    def _from_row(row: dict) -> LobbyTurnStateRecord:
        raw_scores = row.get("scores_by_user") or {}
        scores_by_user: dict[str, float] = {}
        if isinstance(raw_scores, dict):
            for key, value in raw_scores.items():
                if isinstance(key, str) and isinstance(value, (int, float)):
                    scores_by_user[key] = float(value)

        raw_votes = row.get("next_round_votes") or []
        next_round_votes = {
            vote for vote in raw_votes if isinstance(vote, str) and vote
        }
        return LobbyTurnStateRecord(
            scores_by_user=scores_by_user,
            next_round_votes_by_user=next_round_votes,
            event_seq=int(row.get("event_seq") or 0),
            round_number=int(row.get("round_number") or 0),
            latest_scored_user_id=row.get("latest_scored_user_id"),
        )
