"""Outbound port for Policy Decision evaluation."""

from __future__ import annotations

from typing import Protocol

from application.policy_decision import (
    PolicyDecisionRequest,
    PolicyDecisionResult,
)


class PolicyDecisionEvaluatorError(Exception):
    """Policy evaluation failed before producing a valid decision."""


class PolicyDecisionEvaluator(Protocol):
    """Evaluate policy without execution, transport or verification."""

    def evaluate(
        self,
        request: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        """Return one immutable bounded policy decision."""
        ...
