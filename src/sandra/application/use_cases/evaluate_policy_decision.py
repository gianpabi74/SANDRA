"""Policy Decision use-case implementation."""

from __future__ import annotations

from datetime import datetime, timezone

from application.policy_decision import (
    PolicyDecisionRequest,
    PolicyDecisionResult,
)
from application.ports.outbound.policy_decision_evaluator import (
    PolicyDecisionEvaluator,
    PolicyDecisionEvaluatorError,
)
from application.result import ApplicationResult


class EvaluatePolicyDecision:
    """Evaluate authority, risk, limits and conditions without execution."""

    def __init__(
        self,
        evaluator: PolicyDecisionEvaluator,
    ) -> None:
        self._evaluator = evaluator

    def execute(
        self,
        request: PolicyDecisionRequest,
    ) -> ApplicationResult[PolicyDecisionResult]:
        """Return one correlated and non-expired policy decision."""

        try:
            decision = self._evaluator.evaluate(
                request
            )
        except PolicyDecisionEvaluatorError as exc:
            return ApplicationResult.fail(
                code="POLICY_DECISION_EVALUATOR_FAILED",
                error=str(exc),
            )

        if decision.request_id != request.message_id:
            return ApplicationResult.fail(
                code="POLICY_DECISION_REQUEST_MISMATCH",
                error=(
                    "decision request_id does not match "
                    "the Policy Decision request"
                ),
            )

        if decision.subject_ref != request.subject_ref:
            return ApplicationResult.fail(
                code="POLICY_DECISION_SUBJECT_MISMATCH",
                error=(
                    "decision subject_ref does not match "
                    "the Policy Decision request"
                ),
            )

        if (
            decision.proposed_action_ref
            != request.proposed_action_ref
        ):
            return ApplicationResult.fail(
                code="POLICY_DECISION_ACTION_MISMATCH",
                error=(
                    "decision proposed_action_ref does not match "
                    "the Policy Decision request"
                ),
            )

        if decision.expires_at <= datetime.now(
            timezone.utc
        ):
            return ApplicationResult.fail(
                code="POLICY_DECISION_EXPIRED",
                error="policy decision is already expired",
            )

        return ApplicationResult.ok(
            code="POLICY_DECISION_EVALUATED",
            value=decision,
        )
