"""Execution use-case implementation."""

from __future__ import annotations

from application.execution import (
    ExecutionRequest,
    ExecutionResult,
)
from application.ports.outbound.execution_engine import (
    ExecutionEngine,
    ExecutionEngineError,
)
from application.result import ApplicationResult


class ExecutePlan:
    """Execute an existing plan without planning or verification."""

    def __init__(
        self,
        engine: ExecutionEngine,
    ) -> None:
        self._engine = engine

    def execute(
        self,
        request: ExecutionRequest,
    ) -> ApplicationResult[ExecutionResult]:
        """Return one correlated bounded execution result."""

        try:
            result = self._engine.execute(
                request
            )
        except ExecutionEngineError as exc:
            return ApplicationResult.fail(
                code="EXECUTION_ENGINE_FAILED",
                error=str(exc),
            )

        expected_plan_ref = (
            request.execution_plan
            .metadata
            .identifier
        )

        if result.request_id != request.message_id:
            return ApplicationResult.fail(
                code="EXECUTION_REQUEST_MISMATCH",
                error=(
                    "execution result request_id does not "
                    "match the Execution request"
                ),
            )

        if (
            result.execution_plan_ref
            != expected_plan_ref
        ):
            return ApplicationResult.fail(
                code="EXECUTION_PLAN_MISMATCH",
                error=(
                    "execution result plan reference does "
                    "not match the requested ExecutionPlan"
                ),
            )

        if (
            result.policy_decision_ref
            != request.policy_decision_ref
        ):
            return ApplicationResult.fail(
                code="EXECUTION_POLICY_DECISION_MISMATCH",
                error=(
                    "execution result policy decision does "
                    "not match the request"
                ),
            )

        if (
            result.idempotency_key
            != request.idempotency_key
        ):
            return ApplicationResult.fail(
                code="EXECUTION_IDEMPOTENCY_MISMATCH",
                error=(
                    "execution result idempotency key does "
                    "not match the request"
                ),
            )

        if any(
            outcome.attempt
            > request.maximum_attempts
            for outcome in result.step_outcomes
        ):
            return ApplicationResult.fail(
                code="EXECUTION_RETRY_BOUND_EXCEEDED",
                error=(
                    "execution result contains a step attempt "
                    "above the bounded retry limit"
                ),
            )

        return ApplicationResult.ok(
            code="EXECUTION_COMPLETED",
            value=result,
        )
