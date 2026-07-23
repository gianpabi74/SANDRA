"""Outbound port for technology-independent Observation collection."""

from __future__ import annotations

from typing import Protocol

from application.observation import (
    ObservationBatch,
    ObservationRequest,
)


class ObservationSourceError(Exception):
    """Observation source failed before producing a valid batch."""


class ObservationSource(Protocol):
    """Collect raw observed facts without qualification or mutation."""

    def collect(
        self,
        request: ObservationRequest,
    ) -> ObservationBatch:
        """Collect one immutable batch of raw observed facts."""
        ...
