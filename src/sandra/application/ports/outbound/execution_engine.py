"""Outbound port for technology-independent execution orchestration."""

from __future__ import annotations

from typing import Protocol

from application.execution import (
    ExecutionRequest,
    ExecutionResult,
)


class ExecutionEngineError(Exception):
    """Execution engine failed before returning a valid result."""


class ExecutionEngine(Protocol):
    """Execute an existing plan behind a technology-neutral boundary."""

    def execute(
        self,
        request: ExecutionRequest,
    ) -> ExecutionResult:
        """Execute one bounded request and return its immutable result."""
        ...
