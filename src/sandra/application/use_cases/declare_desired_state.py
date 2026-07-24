"""Desired State declaration use-case implementation."""

from __future__ import annotations

from application.desired_state import (
    DesiredStateDeclaration,
    DesiredStateRecord,
)
from application.ports.outbound.desired_state_repository import (
    DesiredStateConflictError,
    DesiredStateRepository,
    DesiredStateRepositoryError,
)
from application.result import ApplicationResult


class DeclareDesiredState:
    """Declare approved intent without issuing imperative commands."""

    def __init__(
        self,
        repository: DesiredStateRepository,
    ) -> None:
        self._repository = repository

    def execute(
        self,
        declaration: DesiredStateDeclaration,
    ) -> ApplicationResult[DesiredStateRecord]:
        """Persist one monotonic Desired State generation."""

        try:
            current = self._repository.get_current(
                declaration.subject_ref
            )
        except DesiredStateRepositoryError as exc:
            return ApplicationResult.fail(
                code="DESIRED_STATE_READ_FAILED",
                error=str(exc),
            )

        current_generation = (
            current.generation
            if current is not None
            else 0
        )

        if (
            current_generation
            != declaration.expected_generation
        ):
            return ApplicationResult.fail(
                code="DESIRED_STATE_GENERATION_CONFLICT",
                error=(
                    "expected generation does not match "
                    "the current Desired State generation"
                ),
            )

        record = DesiredStateRecord(
            desired_state_id=declaration.message_id,
            subject_ref=declaration.subject_ref,
            generation=current_generation + 1,
            declared_at=declaration.created_at,
            approval_ref=declaration.approval_ref,
            desired_configuration=(
                declaration.desired_configuration
            ),
            desired_service_state=(
                declaration.desired_service_state
            ),
            declared_limits=(
                declaration.declared_limits
            ),
        )

        try:
            self._repository.save(
                record,
                expected_generation=(
                    declaration.expected_generation
                ),
            )
        except DesiredStateConflictError as exc:
            return ApplicationResult.fail(
                code="DESIRED_STATE_GENERATION_CONFLICT",
                error=str(exc),
            )
        except DesiredStateRepositoryError as exc:
            return ApplicationResult.fail(
                code="DESIRED_STATE_WRITE_FAILED",
                error=str(exc),
            )

        return ApplicationResult.ok(
            code="DESIRED_STATE_DECLARED",
            value=record,
        )
