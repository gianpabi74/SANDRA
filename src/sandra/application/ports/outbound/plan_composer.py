"""Outbound port for canonical plan composition."""

from __future__ import annotations

from typing import Protocol

from application.planning import (
    PlanningRequest,
    PlanningResult,
)


class PlanComposerError(Exception):
    """Plan composition failed before producing a valid plan."""


class PlanComposer(Protocol):
    """Compose a plan without execution or technology calls."""

    def compose(
        self,
        request: PlanningRequest,
    ) -> PlanningResult:
        """Compose one immutable execution plan."""
        ...
