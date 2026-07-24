"""Evidence Qualification use-case implementation."""

from __future__ import annotations

from datetime import datetime, timezone

from application.evidence import (
    QualificationRequest,
    QualifiedEvidence,
)
from application.ports.outbound.evidence_qualifier import (
    EvidenceQualifier,
    EvidenceQualifierError,
)
from application.result import ApplicationResult


class QualifyEvidence:
    """Qualify observed facts without authoritative-state mutation."""

    def __init__(
        self,
        qualifier: EvidenceQualifier,
    ) -> None:
        self._qualifier = qualifier

    def execute(
        self,
        request: QualificationRequest,
    ) -> ApplicationResult[QualifiedEvidence]:
        """Obtain and validate one qualification decision."""

        now = datetime.now(timezone.utc)

        if request.valid_until <= now:
            return ApplicationResult.fail(
                code="EVIDENCE_REQUEST_EXPIRED",
                error="qualification request has expired",
            )

        try:
            evidence = self._qualifier.qualify(
                request
            )
        except EvidenceQualifierError as exc:
            return ApplicationResult.fail(
                code="EVIDENCE_QUALIFIER_FAILED",
                error=str(exc),
            )

        if evidence.request_id != request.message_id:
            return ApplicationResult.fail(
                code="EVIDENCE_REQUEST_MISMATCH",
                error=(
                    "qualified evidence request_id does not "
                    "match the qualification request"
                ),
            )

        if (
            evidence.subject_ref
            != request.observation.subject_ref
        ):
            return ApplicationResult.fail(
                code="EVIDENCE_SUBJECT_MISMATCH",
                error=(
                    "qualified evidence subject_ref does not "
                    "match the Observation batch"
                ),
            )

        if (
            evidence.capability_id
            != request.observation.capability_id
        ):
            return ApplicationResult.fail(
                code="EVIDENCE_CAPABILITY_MISMATCH",
                error=(
                    "qualified evidence capability_id does not "
                    "match the Observation batch"
                ),
            )

        if (
            evidence.raw_artifact_ref
            != request.raw_artifact_ref
        ):
            return ApplicationResult.fail(
                code="EVIDENCE_ARTIFACT_MISMATCH",
                error=(
                    "qualified evidence raw_artifact_ref does "
                    "not match the qualification request"
                ),
            )

        return ApplicationResult.ok(
            code="EVIDENCE_QUALIFIED",
            value=evidence,
        )
