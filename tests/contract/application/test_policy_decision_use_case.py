from __future__ import annotations

from datetime import (
    datetime,
    timedelta,
    timezone,
)
from typing import cast
import unittest

from application.policy_decision import (
    PolicyDecisionEffect,
    PolicyDecisionRequest,
    PolicyDecisionResult,
)
from application.ports.outbound.policy_decision_evaluator import (
    PolicyDecisionEvaluator,
    PolicyDecisionEvaluatorError,
)
from application.use_cases.evaluate_policy_decision import (
    EvaluatePolicyDecision,
)


def now() -> datetime:
    return datetime.now(
        timezone.utc
    )


def request() -> PolicyDecisionRequest:
    return PolicyDecisionRequest(
        message_id="policy-request-1",
        correlation_id="correlation-1",
        created_at=now(),
        subject_ref="managed-object-1",
        proposed_action_ref="action-1",
        desired_state_ref="desired-state-1",
        evidence_refs=(
            "evidence-1",
            "evidence-2",
        ),
        resource_graph_ref="resource-graph-1",
        requested_limits={
            "retry": {
                "maximum": 2,
            },
        },
        context={
            "risk": "low",
            "reversible": True,
        },
    )


def decision(
    value: PolicyDecisionRequest,
    *,
    effect: PolicyDecisionEffect = (
        PolicyDecisionEffect.ALLOW
    ),
    approval_required: bool = False,
    limits: dict[str, object] | None = None,
    request_id: str | None = None,
    subject_ref: str | None = None,
    proposed_action_ref: str | None = None,
    expires_at: datetime | None = None,
) -> PolicyDecisionResult:
    decided_at = now()

    return PolicyDecisionResult(
        decision_id="decision-1",
        request_id=(
            request_id
            if request_id is not None
            else value.message_id
        ),
        subject_ref=(
            subject_ref
            if subject_ref is not None
            else value.subject_ref
        ),
        proposed_action_ref=(
            proposed_action_ref
            if proposed_action_ref is not None
            else value.proposed_action_ref
        ),
        effect=effect,
        approval_required=(
            approval_required
        ),
        limits=(
            limits
            if limits is not None
            else {}
        ),
        reasons=(
            "policy conditions satisfied",
        ),
        decided_at=decided_at,
        expires_at=(
            expires_at
            if expires_at is not None
            else decided_at
            + timedelta(hours=1)
        ),
    )


class SuccessfulEvaluator:
    def evaluate(
        self,
        value: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        return decision(value)


class FailedEvaluator:
    def evaluate(
        self,
        value: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        raise PolicyDecisionEvaluatorError(
            "evaluation unavailable"
        )


class ConditionalEvaluator:
    def evaluate(
        self,
        value: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        return decision(
            value,
            effect=(
                PolicyDecisionEffect.CONDITIONAL
            ),
            approval_required=True,
        )


class MismatchedRequestEvaluator:
    def evaluate(
        self,
        value: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        return decision(
            value,
            request_id="different-request",
        )


class ExpiredEvaluator:
    def evaluate(
        self,
        value: PolicyDecisionRequest,
    ) -> PolicyDecisionResult:
        decided_at = now() - timedelta(
            hours=2
        )

        return PolicyDecisionResult(
            decision_id="decision-expired",
            request_id=value.message_id,
            subject_ref=value.subject_ref,
            proposed_action_ref=(
                value.proposed_action_ref
            ),
            effect=PolicyDecisionEffect.ALLOW,
            approval_required=False,
            limits={},
            reasons=(
                "expired decision",
            ),
            decided_at=decided_at,
            expires_at=(
                decided_at
                + timedelta(hours=1)
            ),
        )


class PolicyDecisionUseCaseTests(
    unittest.TestCase
):
    def test_successful_allow_decision(
        self,
    ) -> None:
        use_case = EvaluatePolicyDecision(
            cast(
                PolicyDecisionEvaluator,
                SuccessfulEvaluator(),
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
            "POLICY_DECISION_EVALUATED",
        )

        self.assertEqual(
            result.value.effect,
            PolicyDecisionEffect.ALLOW,
        )

    def test_conditional_decision_can_require_approval(
        self,
    ) -> None:
        use_case = EvaluatePolicyDecision(
            cast(
                PolicyDecisionEvaluator,
                ConditionalEvaluator(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertTrue(
            result.success
        )

        self.assertEqual(
            result.value.effect,
            PolicyDecisionEffect.CONDITIONAL,
        )

        self.assertTrue(
            result.value.approval_required
        )

    def test_evaluator_failure_is_explicit(
        self,
    ) -> None:
        use_case = EvaluatePolicyDecision(
            cast(
                PolicyDecisionEvaluator,
                FailedEvaluator(),
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
            "POLICY_DECISION_EVALUATOR_FAILED",
        )

    def test_request_mismatch_is_rejected(
        self,
    ) -> None:
        use_case = EvaluatePolicyDecision(
            cast(
                PolicyDecisionEvaluator,
                MismatchedRequestEvaluator(),
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
            "POLICY_DECISION_REQUEST_MISMATCH",
        )

    def test_expired_decision_is_rejected(
        self,
    ) -> None:
        use_case = EvaluatePolicyDecision(
            cast(
                PolicyDecisionEvaluator,
                ExpiredEvaluator(),
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
            "POLICY_DECISION_EXPIRED",
        )

    def test_request_requires_evidence(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            PolicyDecisionRequest(
                message_id="policy-request-2",
                correlation_id="correlation-2",
                created_at=now(),
                subject_ref="managed-object-1",
                proposed_action_ref="action-1",
                desired_state_ref="desired-state-1",
                evidence_refs=(),
                resource_graph_ref="resource-graph-1",
                requested_limits={},
                context={},
            )

    def test_evidence_references_are_unique(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            PolicyDecisionRequest(
                message_id="policy-request-3",
                correlation_id="correlation-3",
                created_at=now(),
                subject_ref="managed-object-1",
                proposed_action_ref="action-1",
                desired_state_ref="desired-state-1",
                evidence_refs=(
                    "evidence-1",
                    "evidence-1",
                ),
                resource_graph_ref="resource-graph-1",
                requested_limits={},
                context={},
            )

    def test_conditional_requires_approval_or_limits(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            decision(
                request(),
                effect=(
                    PolicyDecisionEffect.CONDITIONAL
                ),
                approval_required=False,
                limits={},
            )

    def test_deny_cannot_require_approval(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            decision(
                request(),
                effect=(
                    PolicyDecisionEffect.DENY
                ),
                approval_required=True,
            )

    def test_decision_requires_future_expiry(
        self,
    ) -> None:
        decided_at = now()

        with self.assertRaises(
            ValueError
        ):
            PolicyDecisionResult(
                decision_id="decision-2",
                request_id="policy-request-1",
                subject_ref="managed-object-1",
                proposed_action_ref="action-1",
                effect=PolicyDecisionEffect.ALLOW,
                approval_required=False,
                limits={},
                reasons=(
                    "allowed",
                ),
                decided_at=decided_at,
                expires_at=decided_at,
            )

    def test_decision_requires_reasons(
        self,
    ) -> None:
        decided_at = now()

        with self.assertRaises(
            ValueError
        ):
            PolicyDecisionResult(
                decision_id="decision-3",
                request_id="policy-request-1",
                subject_ref="managed-object-1",
                proposed_action_ref="action-1",
                effect=PolicyDecisionEffect.ALLOW,
                approval_required=False,
                limits={},
                reasons=(),
                decided_at=decided_at,
                expires_at=(
                    decided_at
                    + timedelta(hours=1)
                ),
            )

    def test_request_context_is_deeply_immutable(
        self,
    ) -> None:
        value = request()

        with self.assertRaises(
            TypeError
        ):
            value.context["risk"] = "high"  # type: ignore[index]

        retry = value.requested_limits[
            "retry"
        ]

        with self.assertRaises(
            TypeError
        ):
            retry["maximum"] = 3  # type: ignore[index]


if __name__ == "__main__":
    unittest.main()
