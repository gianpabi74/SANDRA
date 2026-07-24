from __future__ import annotations

from datetime import (
    datetime,
    timedelta,
    timezone,
)
from typing import cast
import unittest

from governance.types import (
    ResourceEnvelope,
    ResourceKind,
    ResourceMetadata,
)

from application.execution import (
    ExecutionLifecycle,
    ExecutionRequest,
    ExecutionResult,
    ExecutionStepLifecycle,
    ExecutionStepOutcome,
)
from application.ports.outbound.execution_engine import (
    ExecutionEngine,
    ExecutionEngineError,
)
from application.use_cases.execute_plan import (
    ExecutePlan,
)


def now() -> datetime:
    return datetime.now(
        timezone.utc
    )


def execution_plan(
    identifier: str = "plan-1",
) -> ResourceEnvelope:
    return ResourceEnvelope.create(
        api_version=(
            "governance.sandra.io/v1"
        ),
        kind=(
            ResourceKind.EXECUTION_PLAN
        ),
        metadata=(
            ResourceMetadata.create(
                identifier=identifier
            )
        ),
        spec={},
        status={},
        payload={},
    )


def execution_request(
    maximum_attempts: int = 2,
) -> ExecutionRequest:
    return ExecutionRequest(
        message_id="request-1",
        correlation_id="correlation-1",
        created_at=now(),
        execution_plan=(
            execution_plan()
        ),
        policy_decision_ref=(
            "decision-1"
        ),
        idempotency_key="idem-1",
        maximum_attempts=(
            maximum_attempts
        ),
        execution_limits={},
        context={},
    )


def step_outcome(
    attempt: int = 1,
    lifecycle: ExecutionStepLifecycle = (
        ExecutionStepLifecycle.SUCCEEDED
    ),
    error_code: str | None = None,
) -> ExecutionStepOutcome:
    timestamp = now()

    return ExecutionStepOutcome(
        step_id="step-1",
        action_ref="action-1",
        lifecycle=lifecycle,
        attempt=attempt,
        started_at=timestamp,
        completed_at=(
            timestamp
            + timedelta(seconds=1)
        ),
        output={},
        error_code=error_code,
        recovery_ref=None,
    )


def execution_result(
    request: ExecutionRequest,
    **overrides: object,
) -> ExecutionResult:
    timestamp = now()

    values = {
        "execution_id": "execution-1",
        "request_id": (
            request.message_id
        ),
        "execution_plan_ref": (
            request.execution_plan
            .metadata
            .identifier
        ),
        "policy_decision_ref": (
            request.policy_decision_ref
        ),
        "idempotency_key": (
            request.idempotency_key
        ),
        "lifecycle": (
            ExecutionLifecycle.SUCCEEDED
        ),
        "started_at": timestamp,
        "completed_at": (
            timestamp
            + timedelta(seconds=1)
        ),
        "step_outcomes": (
            step_outcome(),
        ),
        "recovery_invocations": (),
        "partial_result": {},
    }

    values.update(overrides)

    return ExecutionResult(
        **values
    )


class Engine:
    def __init__(
        self,
        value: (
            ExecutionResult
            | Exception
        ),
    ) -> None:
        self.value = value

    def execute(
        self,
        request: ExecutionRequest,
    ) -> ExecutionResult:
        if isinstance(
            self.value,
            Exception,
        ):
            raise self.value

        return self.value


class ExecutionUseCaseTests(
    unittest.TestCase
):
    def test_success(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request
                    )
                ),
            )
        ).execute(request)

        self.assertTrue(
            result.success
        )

        self.assertEqual(
            result.code,
            "EXECUTION_COMPLETED",
        )

    def test_engine_failure(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    ExecutionEngineError(
                        "engine unavailable"
                    )
                ),
            )
        ).execute(request)

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "EXECUTION_ENGINE_FAILED",
        )

    def test_request_mismatch(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request,
                        request_id="other",
                    )
                ),
            )
        ).execute(request)

        self.assertEqual(
            result.code,
            "EXECUTION_REQUEST_MISMATCH",
        )

    def test_plan_mismatch(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request,
                        execution_plan_ref=(
                            "other"
                        ),
                    )
                ),
            )
        ).execute(request)

        self.assertEqual(
            result.code,
            "EXECUTION_PLAN_MISMATCH",
        )

    def test_policy_mismatch(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request,
                        policy_decision_ref=(
                            "other"
                        ),
                    )
                ),
            )
        ).execute(request)

        self.assertEqual(
            result.code,
            (
                "EXECUTION_POLICY_"
                "DECISION_MISMATCH"
            ),
        )

    def test_idempotency_mismatch(
        self,
    ) -> None:
        request = execution_request()

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request,
                        idempotency_key=(
                            "other"
                        ),
                    )
                ),
            )
        ).execute(request)

        self.assertEqual(
            result.code,
            (
                "EXECUTION_IDEMPOTENCY_"
                "MISMATCH"
            ),
        )

    def test_retry_bound(
        self,
    ) -> None:
        request = execution_request(
            maximum_attempts=1
        )

        result = ExecutePlan(
            cast(
                ExecutionEngine,
                Engine(
                    execution_result(
                        request,
                        step_outcomes=(
                            step_outcome(
                                attempt=2
                            ),
                        ),
                    )
                ),
            )
        ).execute(request)

        self.assertEqual(
            result.code,
            (
                "EXECUTION_RETRY_"
                "BOUND_EXCEEDED"
            ),
        )

    def test_failed_step_requires_error(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            step_outcome(
                lifecycle=(
                    ExecutionStepLifecycle
                    .FAILED
                ),
                error_code=None,
            )

    def test_recovery_requires_invocation(
        self,
    ) -> None:
        request = execution_request()
        timestamp = now()

        with self.assertRaises(
            ValueError
        ):
            ExecutionResult(
                execution_id="execution",
                request_id=(
                    request.message_id
                ),
                execution_plan_ref=(
                    "plan-1"
                ),
                policy_decision_ref=(
                    "decision-1"
                ),
                idempotency_key=(
                    "idem-1"
                ),
                lifecycle=(
                    ExecutionLifecycle
                    .RECOVERY_REQUIRED
                ),
                started_at=timestamp,
                completed_at=timestamp,
                step_outcomes=(),
                recovery_invocations=(),
                partial_result={},
            )

    def test_retry_limit_upper_bound(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            execution_request(
                maximum_attempts=33
            )


if __name__ == "__main__":
    unittest.main()
