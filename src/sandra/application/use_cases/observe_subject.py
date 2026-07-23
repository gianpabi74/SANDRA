"""Observation use case implementation."""

from __future__ import annotations

from application.observation import (
    ObservationBatch,
    ObservationRequest,
)
from application.ports.outbound.observation_source import (
    ObservationSource,
    ObservationSourceError,
)
from application.result import ApplicationResult


class ObserveSubject:
    """Collect raw facts for one subject and one capability."""

    def __init__(
        self,
        source: ObservationSource,
    ) -> None:
        self._source = source

    def execute(
        self,
        request: ObservationRequest,
    ) -> ApplicationResult[ObservationBatch]:
        """Collect facts without qualification, persistence or action."""

        try:
            batch = self._source.collect(
                request
            )
        except ObservationSourceError as exc:
            return ApplicationResult.fail(
                code="OBSERVATION_SOURCE_FAILED",
                error=str(exc),
            )

        if batch.request_id != request.message_id:
            return ApplicationResult.fail(
                code="OBSERVATION_REQUEST_MISMATCH",
                error=(
                    "batch request_id does not match "
                    "the Observation request"
                ),
            )

        if batch.subject_ref != request.subject_ref:
            return ApplicationResult.fail(
                code="OBSERVATION_SUBJECT_MISMATCH",
                error=(
                    "batch subject_ref does not match "
                    "the Observation request"
                ),
            )

        if batch.capability_id != request.capability_id:
            return ApplicationResult.fail(
                code="OBSERVATION_CAPABILITY_MISMATCH",
                error=(
                    "batch capability_id does not match "
                    "the Observation request"
                ),
            )

        return ApplicationResult.ok(
            code="OBSERVATION_COLLECTED",
            value=batch,
        )
