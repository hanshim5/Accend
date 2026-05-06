from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from app.clients.supabase import rest_get, rest_patch, rest_post


@dataclass
class LobbyTurnStateSnapshot:
    scores_by_user: dict[str, float]
    next_round_votes_by_user: set[str]
    event_seq: int
    latest_scored_user_id: str | None


class SupabaseLobbyTurnStateRepo:
    """
    Persistence for turn-state rows in the `lobby_turn_states` table.
    """

    def get_or_create(self, *, lobby_kind: str, lobby_id: int) -> LobbyTurnStateSnapshot:
        row = self._get_row(lobby_kind=lobby_kind, lobby_id=lobby_id)
        if row is None:
            payload = {
                "lobby_kind": lobby_kind,
                "lobby_id": lobby_id,
                "scores_by_user": {},
                "next_round_votes": [],
                "event_seq": 0,
                "latest_scored_user_id": None,
            }
            try:
                rest_post(
                    table="lobby_turn_states",
                    payload=payload,
                    select="lobby_kind,lobby_id,scores_by_user,next_round_votes,event_seq,latest_scored_user_id",
                )
            except RuntimeError:
                # Another request may have inserted first.
                pass
            row = self._get_row(lobby_kind=lobby_kind, lobby_id=lobby_id)
        if row is None:
            raise RuntimeError("Could not load lobby turn state")
        return self._snapshot_from_row(row)

    def save(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        state: LobbyTurnStateSnapshot,
    ) -> LobbyTurnStateSnapshot:
        rows = rest_patch(
            table="lobby_turn_states",
            match={
                "lobby_kind": f"eq.{lobby_kind}",
                "lobby_id": f"eq.{lobby_id}",
            },
            payload={
                "scores_by_user": state.scores_by_user,
                "next_round_votes": sorted(state.next_round_votes_by_user),
                "event_seq": state.event_seq,
                "latest_scored_user_id": state.latest_scored_user_id,
            },
            select="lobby_kind,lobby_id,scores_by_user,next_round_votes,event_seq,latest_scored_user_id",
        )
        if not rows:
            raise RuntimeError("Lobby turn state row not found")
        return self._snapshot_from_row(rows[0])

    @staticmethod
    def _snapshot_from_row(row: dict[str, Any]) -> LobbyTurnStateSnapshot:
        raw_scores = row.get("scores_by_user")
        if not isinstance(raw_scores, dict):
            raw_scores = {}
        scores_by_user = {
            str(user_id): float(score)
            for user_id, score in raw_scores.items()
            if isinstance(score, (int, float))
        }

        raw_votes = row.get("next_round_votes")
        if not isinstance(raw_votes, list):
            raw_votes = []
        next_round_votes = {str(user_id) for user_id in raw_votes if isinstance(user_id, str)}

        latest_scored_user_id = row.get("latest_scored_user_id")
        if not isinstance(latest_scored_user_id, str):
            latest_scored_user_id = None

        return LobbyTurnStateSnapshot(
            scores_by_user=scores_by_user,
            next_round_votes_by_user=next_round_votes,
            event_seq=int(row.get("event_seq") or 0),
            latest_scored_user_id=latest_scored_user_id,
        )

    def _get_row(self, *, lobby_kind: str, lobby_id: int) -> dict[str, Any] | None:
        rows = rest_get(
            table="lobby_turn_states",
            params={
                "select": "lobby_kind,lobby_id,scores_by_user,next_round_votes,event_seq,latest_scored_user_id",
                "lobby_kind": f"eq.{lobby_kind}",
                "lobby_id": f"eq.{lobby_id}",
                "limit": "1",
            },
        )
        return rows[0] if rows else None
