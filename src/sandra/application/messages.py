"""Application messages shared by inbound ports and use cases."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass(frozen=True, slots=True)
class ApplicationMessage:
    """Base immutable message crossing an inbound Application port."""

    message_id: str
    correlation_id: str
    created_at: datetime

    def __post_init__(self) -> None:
        if not self.message_id:
            raise ValueError("message_id must not be empty")

        if not self.correlation_id:
            raise ValueError("correlation_id must not be empty")

        if self.created_at.tzinfo is None:
            raise ValueError("created_at must be timezone-aware")

    @classmethod
    def timestamp_now(cls) -> datetime:
        """Return an aware UTC timestamp for message construction."""

        return datetime.now(timezone.utc)


@dataclass(frozen=True, slots=True)
class Command(ApplicationMessage):
    """Message requesting an authorized state-changing use case."""


@dataclass(frozen=True, slots=True)
class Query(ApplicationMessage):
    """Message requesting a non-mutating use case."""
