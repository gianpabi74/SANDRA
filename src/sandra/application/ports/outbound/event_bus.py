"""Technology-independent event publication port."""

from __future__ import annotations

from typing import Protocol, TypeVar


Event = TypeVar("Event", contravariant=True)


class EventBus(Protocol[Event]):
    """Publish immutable application or domain events."""

    def publish(
        self,
        event: Event,
    ) -> None:
        """Publish one event."""
        ...
