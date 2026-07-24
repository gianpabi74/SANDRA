from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import cast
import unittest

from governance.types import AuthorityLevel

from application.evidence import (
    QualificationOutcome,
    QualificationRequest,
    QualifiedEvidence,
)
from application.observation import (
    ObservationBatch,
    ObservedFact,
)
from application.ports.outbound.evidence_qualifier import (
    EvidenceQualifier,
    EvidenceQualifierError,
)
from application.use_cases.qualify_evidence import (
    QualifyEvidence,
)


def now() -> datetime:
    return datetime.now(timezone.utc)


def observation() -> ObservationBatch:
    timestamp = now()

    fact = ObservedFact(
        subject_ref="subject-1",
        capability_id="service-state",
        source_ref="source-1",
        observed_at=timestamp,
        captured_at=timestamp,
        values={"state": "running"},
    )

    return ObservationBatch(
        request_id="observation-request-1",
        subject_ref="subject-1",
        capability_id="service-state",
        facts=(fact,),
    )


def request() -> QualificationRequest:
    created = now()

    return QualificationRequest(
        message_id="qualification-request-1",
        correlation_id="observation-request-1",
        created_at=created,
        observation=observation(),
        source_type="telemetry",
        raw_artifact_ref="artifact-1",
        provenance={"collector": "adapter-1"},
        integrity="sha256:example",
        valid_until=created + timedelta(hours=1),
    )


class SuccessfulQualifier:
    def qualify(
        self,
        value: QualificationRequest,
    ) -> QualifiedEvidence:
        timestamp = now()
        fact = value.observation.facts[0]

        return QualifiedEvidence(
            qualification_id="qualification-1",
            request_id=value.message_id,
            subject_ref=value.observation.subject_ref,
            capability_id=value.observation.capability_id,
            source_ref=fact.source_ref,
            source_type=value.source_type,
            observed_at=fact.observed_at,
            captured_at=fact.captured_at,
            qualified_at=timestamp,
            valid_until=value.valid_until,
            authority=AuthorityLevel.OBSERVATIONAL,
            confidence=0.8,
            integrity=value.integrity,
            provenance=value.provenance,
            raw_artifact_ref=value.raw_artifact_ref,
            outcome=QualificationOutcome.ACCEPT,
            reason="source is valid for observational authority",
            evidence_refs=(value.raw_artifact_ref,),
        )


class FailedQualifier:
    def qualify(
        self,
        value: QualificationRequest,
    ) -> QualifiedEvidence:
        raise EvidenceQualifierError(
            "qualification unavailable"
        )


class EvidenceQualificationTests(unittest.TestCase):
    def test_authority_vocabulary(self) -> None:
        self.assertEqual(
            {
                item.value
                for item in AuthorityLevel
            },
            {
                "unknown",
                "observational",
                "corroborated",
                "authoritative",
            },
        )

    def test_successful_qualification(self) -> None:
        use_case = QualifyEvidence(
            cast(
                EvidenceQualifier,
                SuccessfulQualifier(),
            )
        )

        result = use_case.execute(request())

        self.assertTrue(result.success)
        self.assertEqual(
            result.code,
            "EVIDENCE_QUALIFIED",
        )
        self.assertEqual(
            result.value.authority,
            AuthorityLevel.OBSERVATIONAL,
        )

    def test_qualifier_failure_is_explicit(self) -> None:
        use_case = QualifyEvidence(
            cast(
                EvidenceQualifier,
                FailedQualifier(),
            )
        )

        result = use_case.execute(request())

        self.assertFalse(result.success)
        self.assertEqual(
            result.code,
            "EVIDENCE_QUALIFIER_FAILED",
        )

    def test_conflict_is_outcome_not_authority(self) -> None:
        self.assertEqual(
            QualificationOutcome.CONFLICT.value,
            "conflict",
        )

        self.assertFalse(
            hasattr(
                AuthorityLevel,
                "CONFLICTING",
            )
        )

    def test_candidate_is_not_authority(self) -> None:
        self.assertFalse(
            hasattr(
                AuthorityLevel,
                "CANDIDATE",
            )
        )

    def test_corroborated_requires_two_refs(self) -> None:
        timestamp = now()

        with self.assertRaises(ValueError):
            QualifiedEvidence(
                qualification_id="qualification-1",
                request_id="request-1",
                subject_ref="subject-1",
                capability_id="capability-1",
                source_ref="source-1",
                source_type="telemetry",
                observed_at=timestamp,
                captured_at=timestamp,
                qualified_at=timestamp,
                valid_until=timestamp + timedelta(hours=1),
                authority=AuthorityLevel.CORROBORATED,
                confidence=0.9,
                integrity="sha256:example",
                provenance={},
                raw_artifact_ref="artifact-1",
                outcome=QualificationOutcome.CORROBORATE,
                reason="corroborated",
                evidence_refs=("artifact-1",),
            )


if __name__ == "__main__":
    unittest.main()
