from __future__ import annotations

from datetime import datetime, timezone
from typing import cast
import unittest

from application.desired_state import (
    DesiredStateDeclaration,
    DesiredStateRecord,
)
from application.ports.outbound.desired_state_repository import (
    DesiredStateConflictError,
    DesiredStateRepository,
    DesiredStateRepositoryError,
)
from application.use_cases.declare_desired_state import (
    DeclareDesiredState,
)


def declaration(
    *,
    expected_generation: int = 0,
) -> DesiredStateDeclaration:
    return DesiredStateDeclaration(
        message_id="desired-state-1",
        correlation_id="correlation-1",
        created_at=datetime.now(
            timezone.utc
        ),
        subject_ref="managed-object-1",
        approval_ref="approval-1",
        expected_generation=(
            expected_generation
        ),
        desired_configuration={
            "service": {
                "enabled": True,
                "ports": [
                    80,
                    443,
                ],
            },
        },
        desired_service_state="running",
        declared_limits={
            "memory": {
                "maximum": 1024,
            },
        },
    )


class InMemoryRepository:
    def __init__(
        self,
        current: DesiredStateRecord | None = None,
    ) -> None:
        self.current = current
        self.saved: DesiredStateRecord | None = None
        self.saved_expected_generation: int | None = None

    def get_current(
        self,
        subject_ref: str,
    ) -> DesiredStateRecord | None:
        return self.current

    def save(
        self,
        record: DesiredStateRecord,
        expected_generation: int,
    ) -> None:
        current_generation = (
            self.current.generation
            if self.current is not None
            else 0
        )

        if (
            current_generation
            != expected_generation
        ):
            raise DesiredStateConflictError(
                "generation changed"
            )

        self.saved = record
        self.saved_expected_generation = (
            expected_generation
        )
        self.current = record


class ReadFailureRepository:
    def get_current(
        self,
        subject_ref: str,
    ) -> DesiredStateRecord | None:
        raise DesiredStateRepositoryError(
            "read unavailable"
        )

    def save(
        self,
        record: DesiredStateRecord,
        expected_generation: int,
    ) -> None:
        raise AssertionError(
            "save must not be called"
        )


class WriteFailureRepository(
    InMemoryRepository
):
    def save(
        self,
        record: DesiredStateRecord,
        expected_generation: int,
    ) -> None:
        raise DesiredStateRepositoryError(
            "write unavailable"
        )


class ConflictRepository(
    InMemoryRepository
):
    def save(
        self,
        record: DesiredStateRecord,
        expected_generation: int,
    ) -> None:
        raise DesiredStateConflictError(
            "concurrent generation"
        )


class DesiredStateUseCaseTests(
    unittest.TestCase
):
    def test_first_generation_is_declared(
        self,
    ) -> None:
        repository = InMemoryRepository()

        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                repository,
            )
        )

        result = use_case.execute(
            declaration()
        )

        self.assertTrue(
            result.success
        )

        self.assertEqual(
            result.code,
            "DESIRED_STATE_DECLARED",
        )

        self.assertIsNotNone(
            result.value
        )

        self.assertEqual(
            result.value.generation,
            1,
        )

        self.assertEqual(
            result.value.approval_ref,
            "approval-1",
        )

        self.assertEqual(
            repository.saved_expected_generation,
            0,
        )

    def test_generation_is_incremented(
        self,
    ) -> None:
        current = DesiredStateRecord(
            desired_state_id="desired-state-0",
            subject_ref="managed-object-1",
            generation=4,
            declared_at=datetime.now(
                timezone.utc
            ),
            approval_ref="approval-0",
            desired_configuration={},
            desired_service_state="running",
            declared_limits={},
        )

        repository = InMemoryRepository(
            current
        )

        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                repository,
            )
        )

        result = use_case.execute(
            declaration(
                expected_generation=4
            )
        )

        self.assertTrue(
            result.success
        )

        self.assertEqual(
            result.value.generation,
            5,
        )

    def test_stale_generation_is_rejected(
        self,
    ) -> None:
        current = DesiredStateRecord(
            desired_state_id="desired-state-0",
            subject_ref="managed-object-1",
            generation=2,
            declared_at=datetime.now(
                timezone.utc
            ),
            approval_ref="approval-0",
            desired_configuration={},
            desired_service_state="running",
            declared_limits={},
        )

        repository = InMemoryRepository(
            current
        )

        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                repository,
            )
        )

        result = use_case.execute(
            declaration(
                expected_generation=1
            )
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "DESIRED_STATE_GENERATION_CONFLICT",
        )

        self.assertIsNone(
            repository.saved
        )

    def test_repository_conflict_is_explicit(
        self,
    ) -> None:
        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                ConflictRepository(),
            )
        )

        result = use_case.execute(
            declaration()
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "DESIRED_STATE_GENERATION_CONFLICT",
        )

    def test_read_failure_is_explicit(
        self,
    ) -> None:
        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                ReadFailureRepository(),
            )
        )

        result = use_case.execute(
            declaration()
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "DESIRED_STATE_READ_FAILED",
        )

    def test_write_failure_is_explicit(
        self,
    ) -> None:
        use_case = DeclareDesiredState(
            cast(
                DesiredStateRepository,
                WriteFailureRepository(),
            )
        )

        result = use_case.execute(
            declaration()
        )

        self.assertFalse(
            result.success
        )

        self.assertEqual(
            result.code,
            "DESIRED_STATE_WRITE_FAILED",
        )

    def test_declaration_requires_approval(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            DesiredStateDeclaration(
                message_id="desired-state-2",
                correlation_id="correlation-2",
                created_at=datetime.now(
                    timezone.utc
                ),
                subject_ref="managed-object-1",
                approval_ref="",
                expected_generation=0,
                desired_configuration={},
                desired_service_state="running",
                declared_limits={},
            )

    def test_expected_generation_cannot_be_negative(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            declaration(
                expected_generation=-1
            )

    def test_configuration_is_deeply_immutable(
        self,
    ) -> None:
        value = declaration()

        service = value.desired_configuration[
            "service"
        ]

        with self.assertRaises(
            TypeError
        ):
            service["enabled"] = False  # type: ignore[index]

        ports = service["ports"]

        self.assertIsInstance(
            ports,
            tuple,
        )

    def test_limits_are_deeply_immutable(
        self,
    ) -> None:
        value = declaration()

        memory = value.declared_limits[
            "memory"
        ]

        with self.assertRaises(
            TypeError
        ):
            memory["maximum"] = 2048  # type: ignore[index]

    def test_unsupported_configuration_type_is_rejected(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            DesiredStateDeclaration(
                message_id="desired-state-3",
                correlation_id="correlation-3",
                created_at=datetime.now(
                    timezone.utc
                ),
                subject_ref="managed-object-1",
                approval_ref="approval-1",
                expected_generation=0,
                desired_configuration={
                    "unsupported": object(),
                },
                desired_service_state="running",
                declared_limits={},
            )


if __name__ == "__main__":
    unittest.main()
