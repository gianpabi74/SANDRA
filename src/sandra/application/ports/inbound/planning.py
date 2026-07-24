"""Inbound Planning use-case port."""

from __future__ import annotations

from typing import Protocol

from application.planning import (
    PlanningRequest,
    PlanningResult,
)
from application.result import ApplicationResult


class BuildExecutionPlanPort(Protocol):
    """Drive the canonical Planning capability."""

    def execute(
        self,
        request: PlanningRequest,
    ) -> ApplicationResult[PlanningResult]:
        """Build one bounded execution plan."""
        ...
