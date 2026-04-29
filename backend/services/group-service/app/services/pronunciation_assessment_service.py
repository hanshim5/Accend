from __future__ import annotations

import httpx

from app.config import settings


class PronunciationAssessmentService:
    """
    Thin client for the internal pronunciation-feedback service.

    Group-service uses this to assess turn audio without exposing the
    pronunciation-feedback service directly to the mobile client.
    """

    def __init__(self, base_url: str | None = None) -> None:
        self._base_url = (base_url or settings.PRONUNCIATION_FEEDBACK_SERVICE_URL).rstrip("/")

    async def assess(self, *, audio_bytes: bytes, filename: str, reference_text: str) -> dict:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(
                f"{self._base_url}/assess",
                files={"audio": (filename or "audio.wav", audio_bytes, "audio/wav")},
                data={"reference_text": reference_text},
            )

        if r.status_code >= 400:
            # Preserve upstream error payload (JSON or text).
            try:
                detail: object = r.json()
            except Exception:
                detail = r.text
            raise RuntimeError(detail)

        data = r.json()
        if not isinstance(data, dict):
            raise RuntimeError("pronunciation service returned non-object JSON")
        return data

