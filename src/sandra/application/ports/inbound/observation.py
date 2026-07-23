"""Inbound Observation use-case port."""

from __future__ import annotations

from typing import Protocol

from application.observation import (
    ObservationBatch,
    ObservationRequest,
)
from application.result import ApplicationResult


class ObserveSubjectPort(Protocol):
    """Drive the technology-independent Observation use case."""

    def execute(
        self,
        request: ObservationRequest,
    ) -> ApplicationResult[ObservationBatch]:
        """Collect raw observed facts."""
        ...
