"""Inbound Policy Decision use-case port."""

from __future__ import annotations

from typing import Protocol

from application.policy_decision import (
    PolicyDecisionRequest,
    PolicyDecisionResult,
)
from application.result import ApplicationResult


class EvaluatePolicyDecisionPort(Protocol):
    """Drive the canonical Policy Decision capability."""

    def execute(
        self,
        request: PolicyDecisionRequest,
    ) -> ApplicationResult[PolicyDecisionResult]:
        """Evaluate one proposed action."""
        ...
