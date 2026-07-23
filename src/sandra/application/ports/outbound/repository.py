"""Technology-independent persistence port."""

from __future__ import annotations

from typing import Protocol, TypeVar


Entity = TypeVar("Entity")
Identity = TypeVar("Identity")


class Repository(
    Protocol[Identity, Entity]
):
    """Load and persist one category of application entity."""

    def get(
        self,
        identifier: Identity,
    ) -> Entity | None:
        """Return the entity or None when it does not exist."""
        ...

    def save(
        self,
        entity: Entity,
    ) -> None:
        """Persist the supplied entity."""
        ...
