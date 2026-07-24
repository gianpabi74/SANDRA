"""Outbound port for Desired State persistence."""

from __future__ import annotations

from typing import Protocol

from application.desired_state import (
    DesiredStateRecord,
)


class DesiredStateRepositoryError(Exception):
    """Desired State repository operation failed."""


class DesiredStateConflictError(
    DesiredStateRepositoryError
):
    """Desired State generation changed concurrently."""


class DesiredStateRepository(Protocol):
    """Store approved intent independently from observed state."""

    def get_current(
        self,
        subject_ref: str,
    ) -> DesiredStateRecord | None:
        """Return the current Desired State record for a subject."""
        ...

    def save(
        self,
        record: DesiredStateRecord,
        expected_generation: int,
    ) -> None:
        """Persist a new generation using optimistic concurrency."""
        ...
