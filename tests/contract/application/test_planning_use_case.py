from __future__ import annotations

from datetime import (
    datetime,
    timezone,
)
from typing import cast
import unittest

from governance.types import (
    ResourceEnvelope,
    ResourceKind,
    ResourceMetadata,
)

from application.planning import (
    PlanningRequest,
    PlanningResult,
    PlanStep,
)
from application.ports.outbound.plan_composer import (
    PlanComposer,
    PlanComposerError,
)
from application.use_cases.build_execution_plan import (
    BuildExecutionPlan,
)


def request() -> PlanningRequest:
    return PlanningRequest(
        message_id="planning-1",
        correlation_id="correlation-1",
        created_at=datetime.now(
            timezone.utc
        ),
        subject_ref="subject-1",
        policy_decision_ref="decision-1",
        desired_state_ref="desired-state-1",
        resource_graph_ref="resource-graph-1",
        requested_action_refs=(
            "action-1",
            "action-2",
        ),
        execution_limits={
            "max_parallel": 1,
        },
        context={
            "risk": "low",
        },
    )


def execution_plan() -> ResourceEnvelope:
    return ResourceEnvelope.create(
        api_version="governance.sandra.io/v1",
        kind=ResourceKind.EXECUTION_PLAN,
        metadata=ResourceMetadata.create(
            identifier="execution-plan-1"
        ),
        spec={},
        status={},
        payload={},
    )


def planning_result(
    value: PlanningRequest,
) -> PlanningResult:
    return PlanningResult(
        request_id=value.message_id,
        subject_ref=value.subject_ref,
        policy_decision_ref=(
            value.policy_decision_ref
        ),
        execution_plan=execution_plan(),
        steps=(
            PlanStep(
                step_id="step-1",
                action_ref="action-1",
                order=1,
                depends_on=(),
                preconditions=(
                    "subject-ready",
                ),
                postconditions=(
                    "action-one-complete",
                ),
                recovery_ref="recovery-1",
                limits={},
            ),
            PlanStep(
                step_id="step-2",
                action_ref="action-2",
                order=2,
                depends_on=(
                    "step-1",
                ),
                preconditions=(
                    "action-one-complete",
                ),
                postconditions=(
                    "plan-complete",
                ),
                recovery_ref=None,
                limits={},
            ),
        ),
    )


class SuccessfulComposer:
    def compose(
        self,
        value: PlanningRequest,
    ) -> PlanningResult:
        return planning_result(
            value
        )


class FailedComposer:
    def compose(
        self,
        value: PlanningRequest,
    ) -> PlanningResult:
        raise PlanComposerError(
            "composer unavailable"
        )


class MismatchedComposer:
    def compose(
        self,
        value: PlanningRequest,
    ) -> PlanningResult:
        result = planning_result(
            value
        )

        return PlanningResult(
            request_id="different-request",
            subject_ref=result.subject_ref,
            policy_decision_ref=(
                result.policy_decision_ref
            ),
            execution_plan=(
                result.execution_plan
            ),
            steps=result.steps,
        )


class PlanningUseCaseTests(
    unittest.TestCase
):
    def test_successful_plan(self) -> None:
        use_case = BuildExecutionPlan(
            cast(
                PlanComposer,
                SuccessfulComposer(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertTrue(
            result.success
        )

        self.assertEqual(
            result.code,
            "EXECUTION_PLAN_BUILT",
        )

    def test_composer_failure(self) -> None:
        use_case = BuildExecutionPlan(
            cast(
                PlanComposer,
                FailedComposer(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "PLANNING_COMPOSER_FAILED",
        )

    def test_request_mismatch(self) -> None:
        use_case = BuildExecutionPlan(
            cast(
                PlanComposer,
                MismatchedComposer(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "PLANNING_REQUEST_MISMATCH",
        )

    def test_request_requires_actions(
        self,
    ) -> None:
        value = request()

        with self.assertRaises(
            ValueError
        ):
            PlanningRequest(
                message_id=value.message_id,
                correlation_id=(
                    value.correlation_id
                ),
                created_at=value.created_at,
                subject_ref=value.subject_ref,
                policy_decision_ref=(
                    value.policy_decision_ref
                ),
                desired_state_ref=(
                    value.desired_state_ref
                ),
                resource_graph_ref=(
                    value.resource_graph_ref
                ),
                requested_action_refs=(),
                execution_limits={},
                context={},
            )

    def test_step_cannot_depend_on_itself(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            PlanStep(
                step_id="step-1",
                action_ref="action-1",
                order=1,
                depends_on=(
                    "step-1",
                ),
                preconditions=(),
                postconditions=(),
                recovery_ref=None,
                limits={},
            )

    def test_plan_requires_execution_plan_kind(
        self,
    ) -> None:
        wrong_kind = ResourceEnvelope.create(
            api_version="governance.sandra.io/v1",
            kind=ResourceKind.MANAGED_OBJECT,
            metadata=ResourceMetadata.create(
                identifier="wrong-kind"
            ),
            spec={},
            status={},
            payload={},
        )

        with self.assertRaises(
            ValueError
        ):
            PlanningResult(
                request_id="request-1",
                subject_ref="subject-1",
                policy_decision_ref="decision-1",
                execution_plan=wrong_kind,
                steps=(
                    PlanStep(
                        step_id="step-1",
                        action_ref="action-1",
                        order=1,
                        depends_on=(),
                        preconditions=(),
                        postconditions=(),
                        recovery_ref=None,
                        limits={},
                    ),
                ),
            )

    def test_dependencies_reference_earlier_steps(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            PlanningResult(
                request_id="request-1",
                subject_ref="subject-1",
                policy_decision_ref="decision-1",
                execution_plan=execution_plan(),
                steps=(
                    PlanStep(
                        step_id="step-1",
                        action_ref="action-1",
                        order=1,
                        depends_on=(
                            "step-2",
                        ),
                        preconditions=(),
                        postconditions=(),
                        recovery_ref=None,
                        limits={},
                    ),
                    PlanStep(
                        step_id="step-2",
                        action_ref="action-2",
                        order=2,
                        depends_on=(),
                        preconditions=(),
                        postconditions=(),
                        recovery_ref=None,
                        limits={},
                    ),
                ),
            )

    def test_orders_are_contiguous(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            PlanningResult(
                request_id="request-1",
                subject_ref="subject-1",
                policy_decision_ref="decision-1",
                execution_plan=execution_plan(),
                steps=(
                    PlanStep(
                        step_id="step-1",
                        action_ref="action-1",
                        order=2,
                        depends_on=(),
                        preconditions=(),
                        postconditions=(),
                        recovery_ref=None,
                        limits={},
                    ),
                ),
            )

    def test_limits_are_immutable(
        self,
    ) -> None:
        value = request()

        with self.assertRaises(
            TypeError
        ):
            value.execution_limits[
                "max_parallel"
            ] = 2


if __name__ == "__main__":
    unittest.main()
