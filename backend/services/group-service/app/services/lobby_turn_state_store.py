from __future__ import annotations

from app.schemas.private_lobby_schema import (
    LobbyTurnParticipantOut,
    LobbyTurnStateOut,
    PrivateLobbyMemberOut,
)
from app.repositories.supabase_lobby_turn_state_repo import (
    LobbyTurnStateRecord,
    SupabaseLobbyTurnStateRepo,
)


class LobbyTurnStateStore:
    """
    Supabase-backed synchronized turn/score state keyed by (lobby_kind, lobby_id).
    """

    def __init__(self, repo: SupabaseLobbyTurnStateRepo) -> None:
        self._repo = repo

    def get_state(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        members: list[PrivateLobbyMemberOut],
    ) -> LobbyTurnStateOut:
        state = self._repo.get_or_create_state(lobby_kind=lobby_kind, lobby_id=lobby_id)
        ordered = self._ordered_members(members)
        self._prune_scores(state, ordered)
        state = self._repo.save_state(lobby_kind=lobby_kind, lobby_id=lobby_id, state=state)
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
        state = self._repo.get_or_create_state(lobby_kind=lobby_kind, lobby_id=lobby_id)
        ordered = self._ordered_members(members)
        self._prune_scores(state, ordered)
        current_idx = self._first_unscored_index(ordered, state)
        if current_idx is None:
            raise RuntimeError("Round already complete")

        current_user_id = ordered[current_idx].user_id
        if current_user_id != actor_user_id:
            raise RuntimeError("Not your turn")

        state.scores_by_user[actor_user_id] = float(score)
        # Any score change invalidates prior "next round" voting.
        state.next_round_votes_by_user.clear()
        state.event_seq += 1
        state.latest_scored_user_id = actor_user_id
        state = self._repo.save_state(lobby_kind=lobby_kind, lobby_id=lobby_id, state=state)
        return self._to_output(
            lobby_kind=lobby_kind,
            lobby_id=lobby_id,
            ordered_members=ordered,
            state=state,
        )

    def vote_next_round(
        self,
        *,
        lobby_kind: str,
        lobby_id: int,
        members: list[PrivateLobbyMemberOut],
        actor_user_id: str,
    ) -> LobbyTurnStateOut:
        state = self._repo.get_or_create_state(lobby_kind=lobby_kind, lobby_id=lobby_id)
        ordered = self._ordered_members(members)
        self._prune_scores(state, ordered)

        # Only allow voting once the round is complete.
        if self._first_unscored_index(ordered, state) is not None:
            raise RuntimeError("Round not complete")

        allowed = {m.user_id for m in ordered}
        if actor_user_id not in allowed:
            raise RuntimeError("Not a lobby member")

        state.next_round_votes_by_user.add(actor_user_id)
        state.event_seq += 1

        # Unanimous vote resets the round.
        if allowed and state.next_round_votes_by_user.issuperset(allowed):
            state.scores_by_user.clear()
            state.next_round_votes_by_user.clear()
            state.latest_scored_user_id = None
            state.event_seq += 1

        state = self._repo.save_state(lobby_kind=lobby_kind, lobby_id=lobby_id, state=state)
        return self._to_output(
            lobby_kind=lobby_kind,
            lobby_id=lobby_id,
            ordered_members=ordered,
            state=state,
        )

    def clear_user(self, *, user_id: str) -> None:
        # State is pruned against live members on every read/write.
        # Keep as no-op for call-site compatibility.
        _ = user_id

    @staticmethod
    def _ordered_members(members: list[PrivateLobbyMemberOut]) -> list[PrivateLobbyMemberOut]:
        return sorted(members, key=lambda m: m.joined_at)

    @staticmethod
    def _prune_scores(state: LobbyTurnStateRecord, ordered_members: list[PrivateLobbyMemberOut]) -> None:
        allowed = {m.user_id for m in ordered_members}
        for user_id in list(state.scores_by_user.keys()):
            if user_id not in allowed:
                del state.scores_by_user[user_id]
        for user_id in list(state.next_round_votes_by_user):
            if user_id not in allowed:
                state.next_round_votes_by_user.discard(user_id)
        if state.latest_scored_user_id not in allowed:
            state.latest_scored_user_id = None

    @staticmethod
    def _first_unscored_index(
        ordered_members: list[PrivateLobbyMemberOut],
        state: LobbyTurnStateRecord,
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
        state: LobbyTurnStateRecord,
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
            next_round_votes=sorted(state.next_round_votes_by_user),
            next_round_vote_count=len(state.next_round_votes_by_user),
        )


turn_state_store = LobbyTurnStateStore(repo=SupabaseLobbyTurnStateRepo())
