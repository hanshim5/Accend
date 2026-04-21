from app.repositories.supabase_public_lobby_repo import SupabasePublicLobbyRepo
from app.schemas.private_lobby_schema import PrivateLobbyCreate, PrivateLobbyJoin, PrivateLobbyMemberOut


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
