from __future__ import annotations

from datetime import datetime, timezone
from typing import cast
import unittest

from application.observation import (
    ObservationBatch,
    ObservationRequest,
    ObservedFact,
)
from application.ports.outbound.observation_source import (
    ObservationSource,
    ObservationSourceError,
)
from application.use_cases.observe_subject import (
    ObserveSubject,
)


class SuccessfulSource:
    def collect(
        self,
        request: ObservationRequest,
    ) -> ObservationBatch:
        observed_at = datetime.now(
            timezone.utc
        )

        fact = ObservedFact(
            subject_ref=request.subject_ref,
            capability_id=request.capability_id,
            source_ref="source-1",
            observed_at=observed_at,
            captured_at=observed_at,
            values={
                "state": "running",
            },
        )

        return ObservationBatch(
            request_id=request.message_id,
            subject_ref=request.subject_ref,
            capability_id=request.capability_id,
            facts=(fact,),
        )


class FailedSource:
    def collect(
        self,
        request: ObservationRequest,
    ) -> ObservationBatch:
        raise ObservationSourceError(
            "collection unavailable"
        )


class MismatchedSource:
    def collect(
        self,
        request: ObservationRequest,
    ) -> ObservationBatch:
        return ObservationBatch(
            request_id="different-request",
            subject_ref=request.subject_ref,
            capability_id=request.capability_id,
            facts=(),
        )


class ObservationUseCaseTests(
    unittest.TestCase
):
    def request(self) -> ObservationRequest:
        return ObservationRequest(
            message_id="request-1",
            correlation_id="correlation-1",
            created_at=datetime.now(
                timezone.utc
            ),
            subject_ref="managed-object-1",
            capability_id="service-state",
        )

    def test_collects_matching_batch(self) -> None:
        use_case = ObserveSubject(
            cast(
                ObservationSource,
                SuccessfulSource(),
            )
        )

        result = use_case.execute(
            self.request()
        )

        self.assertTrue(result.success)
        self.assertEqual(
            result.code,
            "OBSERVATION_COLLECTED",
        )
        self.assertIsNotNone(result.value)
        self.assertEqual(
            len(result.value.facts),
            1,
        )

    def test_source_failure_is_explicit(self) -> None:
        use_case = ObserveSubject(
            cast(
                ObservationSource,
                FailedSource(),
            )
        )

        result = use_case.execute(
            self.request()
        )

        self.assertFalse(result.success)
        self.assertEqual(
            result.code,
            "OBSERVATION_SOURCE_FAILED",
        )

    def test_mismatched_batch_is_rejected(self) -> None:
        use_case = ObserveSubject(
            cast(
                ObservationSource,
                MismatchedSource(),
            )
        )

        result = use_case.execute(
            self.request()
        )

        self.assertFalse(result.success)
        self.assertEqual(
            result.code,
            "OBSERVATION_REQUEST_MISMATCH",
        )

    def test_fact_values_are_immutable(self) -> None:
        observed_at = datetime.now(
            timezone.utc
        )

        fact = ObservedFact(
            subject_ref="subject-1",
            capability_id="capability-1",
            source_ref="source-1",
            observed_at=observed_at,
            captured_at=observed_at,
            values={"state": "running"},
        )

        with self.assertRaises(
            TypeError
        ):
            fact.values["state"] = "stopped"  # type: ignore[index]

    def test_fact_rejects_timestamp_inversion(self) -> None:
        later = datetime.now(
            timezone.utc
        )
        earlier = datetime(
            2020,
            1,
            1,
            tzinfo=timezone.utc,
        )

        with self.assertRaises(
            ValueError
        ):
            ObservedFact(
                subject_ref="subject-1",
                capability_id="capability-1",
                source_ref="source-1",
                observed_at=later,
                captured_at=earlier,
                values={},
            )


if __name__ == "__main__":
    unittest.main()
