"""Inbound Execution use-case port."""

from __future__ import annotations

from typing import Protocol

from application.execution import (
    ExecutionRequest,
    ExecutionResult,
)
from application.result import ApplicationResult


class ExecutePlanPort(Protocol):
    """Drive the canonical Execution capability."""

    def execute(
        self,
        request: ExecutionRequest,
    ) -> ApplicationResult[ExecutionResult]:
        """Execute one existing canonical ExecutionPlan."""
        ...
