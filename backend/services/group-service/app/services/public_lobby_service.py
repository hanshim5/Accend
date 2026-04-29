from app.repositories.supabase_public_lobby_repo import SupabasePublicLobbyRepo
from app.schemas.private_lobby_schema import (
    LobbyTurnStateOut,
    PrivateLobbyCreate,
    PrivateLobbyJoin,
    PrivateLobbyMemberOut,
)
from app.services.lobby_turn_state_store import turn_state_store
from app.services.pronunciation_assessment_service import PronunciationAssessmentService


class PublicLobbyService:
    def __init__(self, repo: SupabasePublicLobbyRepo):
        self.repo = repo

    def get_lobby(self, lobby_id: int) -> list[PrivateLobbyMemberOut]:
        return self.repo.get_lobby(lobby_id)

    def get_my_lobbies(self, user_id: str) -> list[PrivateLobbyMemberOut]:
        return self.repo.get_my_lobbies(user_id)

    def create_lobby(self, data: PrivateLobbyCreate) -> PrivateLobbyMemberOut:
        return self.repo.create_lobby(data)

    def join_lobby(self, data: PrivateLobbyJoin) -> PrivateLobbyMemberOut:
        return self.repo.join_lobby(data)

    def leave_lobby(self, user_id: str) -> bool:
        turn_state_store.clear_user(user_id=user_id)
        return self.repo.leave_lobby(user_id)

    def matchmake(self, data: PrivateLobbyCreate) -> PrivateLobbyMemberOut:
        """
        Join the oldest joinable public lobby (<5 members, session_start false,
        no blocked/blocking members), or create a new lobby if none exists.
        Retries briefly on race conditions.
        """
        for _ in range(5):
            lobby_id = self.repo.find_oldest_joinable_lobby_id(str(data.user_id))
            if lobby_id is None:
                break
            try:
                return self.repo.join_lobby(
                    PrivateLobbyJoin(
                        lobby_id=lobby_id,
                        username=data.username,
                        user_id=str(data.user_id),
                    )
                )
            except RuntimeError:
                continue
        return self.repo.create_lobby(data)

    def get_turn_state(self, lobby_id: int) -> LobbyTurnStateOut:
        members = self.repo.get_lobby(lobby_id)
        return turn_state_store.get_state(
            lobby_kind="public",
            lobby_id=lobby_id,
            members=members,
        )

    def submit_turn_score(
        self,
        *,
        lobby_id: int,
        actor_user_id: str,
        score: float,
    ) -> LobbyTurnStateOut:
        members = self.repo.get_lobby(lobby_id)
        return turn_state_store.submit_score(
            lobby_kind="public",
            lobby_id=lobby_id,
            members=members,
            actor_user_id=actor_user_id,
            score=score,
        )

    def vote_next_round(
        self,
        *,
        lobby_id: int,
        actor_user_id: str,
    ) -> LobbyTurnStateOut:
        members = self.repo.get_lobby(lobby_id)
        return turn_state_store.vote_next_round(
            lobby_kind="public",
            lobby_id=lobby_id,
            members=members,
            actor_user_id=actor_user_id,
        )

    async def assess_turn_pronunciation(
        self,
        *,
        lobby_id: int,
        actor_user_id: str,
        audio_bytes: bytes,
        filename: str,
        reference_text: str,
    ) -> dict:
        members = self.repo.get_lobby(lobby_id)
        current = turn_state_store.current_speaker_user_id(
            lobby_kind="public",
            lobby_id=lobby_id,
            members=members,
        )
        if current is None:
            raise RuntimeError("Round complete")
        if current != actor_user_id:
            raise RuntimeError("Not your turn")

        svc = PronunciationAssessmentService()
        return await svc.assess(
            audio_bytes=audio_bytes,
            filename=filename,
            reference_text=reference_text,
        )
