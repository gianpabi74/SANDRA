"""Planning use-case implementation."""

from __future__ import annotations

from application.planning import (
    PlanningRequest,
    PlanningResult,
)
from application.ports.outbound.plan_composer import (
    PlanComposer,
    PlanComposerError,
)
from application.result import ApplicationResult


class BuildExecutionPlan:
    """Build a plan without execution or policy reevaluation."""

    def __init__(
        self,
        composer: PlanComposer,
    ) -> None:
        self._composer = composer

    def execute(
        self,
        request: PlanningRequest,
    ) -> ApplicationResult[PlanningResult]:
        """Return one correlated execution plan."""

        try:
            result = self._composer.compose(
                request
            )
        except PlanComposerError as exc:
            return ApplicationResult.fail(
                code="PLANNING_COMPOSER_FAILED",
                error=str(exc),
            )

        if result.request_id != request.message_id:
            return ApplicationResult.fail(
                code="PLANNING_REQUEST_MISMATCH",
                error=(
                    "plan request_id does not match "
                    "the Planning request"
                ),
            )

        if result.subject_ref != request.subject_ref:
            return ApplicationResult.fail(
                code="PLANNING_SUBJECT_MISMATCH",
                error=(
                    "plan subject_ref does not match "
                    "the Planning request"
                ),
            )

        if (
            result.policy_decision_ref
            != request.policy_decision_ref
        ):
            return ApplicationResult.fail(
                code="PLANNING_POLICY_DECISION_MISMATCH",
                error=(
                    "plan policy_decision_ref does not "
                    "match the Planning request"
                ),
            )

        return ApplicationResult.ok(
            code="EXECUTION_PLAN_BUILT",
            value=result,
        )
