from __future__ import annotations

from dataclasses import dataclass, field
from threading import Lock

from app.schemas.private_lobby_schema import (
    LobbyTurnParticipantOut,
    LobbyTurnStateOut,
    PrivateLobbyMemberOut,
)


@dataclass
class _TurnState:
    scores_by_user: dict[str, float] = field(default_factory=dict)
    event_seq: int = 0
    latest_scored_user_id: str | None = None


class LobbyTurnStateStore:
    """
    In-memory synchronized turn/score state keyed by (lobby_kind, lobby_id).
    """

    def __init__(self) -> None:
        self._state_by_lobby: dict[tuple[str, int], _TurnState] = {}
        self._lock = Lock()

    def get_state(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        members: list[PrivateLobbyMemberOut],
    ) -> LobbyTurnStateOut:
        with self._lock:
            state = self._state_by_lobby.setdefault((lobby_kind, lobby_id), _TurnState())
            ordered = self._ordered_members(members)
            self._prune_scores(state, ordered)
            return self._to_output(
                lobby_kind=lobby_kind,
                lobby_id=lobby_id,
                ordered_members=ordered,
                state=state,
            )

    def submit_score(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        members: list[PrivateLobbyMemberOut],
        actor_user_id: str,
        score: float,
    ) -> LobbyTurnStateOut:
        with self._lock:
            state = self._state_by_lobby.setdefault((lobby_kind, lobby_id), _TurnState())
            ordered = self._ordered_members(members)
            self._prune_scores(state, ordered)
            current_idx = self._first_unscored_index(ordered, state)
            if current_idx is None:
                raise RuntimeError("Round already complete")

            current_user_id = ordered[current_idx].user_id
            if current_user_id != actor_user_id:
                raise RuntimeError("Not your turn")

            state.scores_by_user[actor_user_id] = float(score)
            state.event_seq += 1
            state.latest_scored_user_id = actor_user_id
            return self._to_output(
                lobby_kind=lobby_kind,
                lobby_id=lobby_id,
                ordered_members=ordered,
                state=state,
            )

    def clear_user(self, *, user_id: str) -> None:
        with self._lock:
            for lobby_key in list(self._state_by_lobby.keys()):
                state = self._state_by_lobby[lobby_key]
                state.scores_by_user.pop(user_id, None)
                if state.latest_scored_user_id == user_id:
                    state.latest_scored_user_id = None

    @staticmethod
    def _ordered_members(members: list[PrivateLobbyMemberOut]) -> list[PrivateLobbyMemberOut]:
        return sorted(members, key=lambda m: m.joined_at)

    @staticmethod
    def _prune_scores(state: _TurnState, ordered_members: list[PrivateLobbyMemberOut]) -> None:
        allowed = {m.user_id for m in ordered_members}
        for user_id in list(state.scores_by_user.keys()):
            if user_id not in allowed:
                del state.scores_by_user[user_id]
        if state.latest_scored_user_id not in allowed:
            state.latest_scored_user_id = None

    @staticmethod
    def _first_unscored_index(
        ordered_members: list[PrivateLobbyMemberOut],
        state: _TurnState,
    ) -> int | None:
        for i, member in enumerate(ordered_members):
            if member.user_id not in state.scores_by_user:
                return i
        return None

    def _to_output(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        ordered_members: list[PrivateLobbyMemberOut],
        state: _TurnState,
    ) -> LobbyTurnStateOut:
        participants = [
            LobbyTurnParticipantOut(
                user_id=m.user_id,
                username=m.username,
                turn_order=i,
                score=state.scores_by_user.get(m.user_id),
            )
            for i, m in enumerate(ordered_members)
        ]
        current_idx = self._first_unscored_index(ordered_members, state) or 0
        round_complete = (
            len(ordered_members) > 0
            and self._first_unscored_index(ordered_members, state) is None
        )
        if round_complete:
            current_idx = max(0, len(ordered_members) - 1)
        return LobbyTurnStateOut(
            lobby_id=lobby_id,
            lobby_kind=lobby_kind,
            current_turn_index=current_idx,
            participants=participants,
            round_complete=round_complete,
            event_seq=state.event_seq,
            latest_scored_user_id=state.latest_scored_user_id,
        )


turn_state_store = LobbyTurnStateStore()
