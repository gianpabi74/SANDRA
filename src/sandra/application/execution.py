"""Technology-independent Execution application contracts."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from types import MappingProxyType
from typing import TypeAlias

from governance.types import (
    ResourceEnvelope,
    ResourceKind,
)

from .messages import Command


ImmutableScalar: TypeAlias = (
    str
    | int
    | float
    | bool
    | None
)

ImmutableValue: TypeAlias = (
    ImmutableScalar
    | tuple["ImmutableValue", ...]
    | Mapping[str, "ImmutableValue"]
)


class ExecutionLifecycle(StrEnum):
    """Canonical lifecycle of one bounded execution."""

    ACCEPTED = "accepted"
    RUNNING = "running"
    PARTIAL = "partial"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    CANCELLED = "cancelled"
    RECOVERY_REQUIRED = "recovery_required"


class ExecutionStepLifecycle(StrEnum):
    """Canonical lifecycle outcome for one executed plan step."""

    SUCCEEDED = "succeeded"
    FAILED = "failed"
    SKIPPED = "skipped"
    CANCELLED = "cancelled"
    RECOVERED = "recovered"


def _require_text(
    value: str,
    field: str,
) -> None:
    if not value:
        raise ValueError(
            f"{field} must not be empty"
        )


def _require_aware_timestamp(
    value: datetime,
    field: str,
) -> None:
    if value.tzinfo is None:
        raise ValueError(
            f"{field} must be timezone-aware"
        )


def _require_unique_texts(
    values: tuple[str, ...],
    field: str,
) -> None:
    if any(
        not value
        for value in values
    ):
        raise ValueError(
            f"{field} cannot contain empty values"
        )

    if len(values) != len(set(values)):
        raise ValueError(
            f"{field} cannot contain duplicates"
        )


def _freeze_value(
    value: object,
    path: str,
) -> ImmutableValue:
    if (
        value is None
        or isinstance(
            value,
            (
                str,
                int,
                float,
                bool,
            ),
        )
    ):
        return value

    if isinstance(value, Mapping):
        frozen: dict[str, ImmutableValue] = {}

        for key, child in value.items():
            if not isinstance(key, str):
                raise ValueError(
                    f"{path} keys must be strings"
                )

            _require_text(
                key,
                f"{path} key",
            )

            frozen[key] = _freeze_value(
                child,
                f"{path}.{key}",
            )

        return MappingProxyType(frozen)

    if isinstance(
        value,
        (
            list,
            tuple,
        ),
    ):
        return tuple(
            _freeze_value(
                child,
                f"{path}[{index}]",
            )
            for index, child in enumerate(
                value
            )
        )

    raise ValueError(
        f"{path} contains unsupported type "
        f"{type(value).__name__}"
    )


def _freeze_mapping(
    value: Mapping[str, object],
    field: str,
) -> Mapping[str, ImmutableValue]:
    frozen = _freeze_value(
        value,
        field,
    )

    if not isinstance(frozen, Mapping):
        raise ValueError(
            f"{field} must be a mapping"
        )

    return frozen


@dataclass(frozen=True, slots=True)
class ExecutionRequest(Command):
    """Request execution of one existing canonical ExecutionPlan."""

    execution_plan: ResourceEnvelope
    policy_decision_ref: str
    idempotency_key: str
    maximum_attempts: int
    execution_limits: Mapping[str, object]
    context: Mapping[str, object]

    def __post_init__(self) -> None:
        Command.__post_init__(self)

        if self.execution_plan.kind is not (
            ResourceKind.EXECUTION_PLAN
        ):
            raise ValueError(
                "execution_plan must have kind ExecutionPlan"
            )

        _require_text(
            self.policy_decision_ref,
            "policy_decision_ref",
        )

        _require_text(
            self.idempotency_key,
            "idempotency_key",
        )

        if self.maximum_attempts < 1:
            raise ValueError(
                "maximum_attempts must be at least 1"
            )

        if self.maximum_attempts > 32:
            raise ValueError(
                "maximum_attempts must not exceed 32"
            )

        object.__setattr__(
            self,
            "execution_limits",
            _freeze_mapping(
                self.execution_limits,
                "execution_limits",
            ),
        )

        object.__setattr__(
            self,
            "context",
            _freeze_mapping(
                self.context,
                "context",
            ),
        )


@dataclass(frozen=True, slots=True)
class ExecutionStepOutcome:
    """Immutable partial result for one attempted plan step."""

    step_id: str
    action_ref: str
    lifecycle: ExecutionStepLifecycle
    attempt: int
    started_at: datetime
    completed_at: datetime
    output: Mapping[str, object]
    error_code: str | None
    recovery_ref: str | None

    def __post_init__(self) -> None:
        _require_text(
            self.step_id,
            "step_id",
        )

        _require_text(
            self.action_ref,
            "action_ref",
        )

        if self.attempt < 1:
            raise ValueError(
                "attempt must be at least 1"
            )

        _require_aware_timestamp(
            self.started_at,
            "started_at",
        )

        _require_aware_timestamp(
            self.completed_at,
            "completed_at",
        )

        if self.completed_at < self.started_at:
            raise ValueError(
                "completed_at cannot precede started_at"
            )

        if self.error_code is not None:
            _require_text(
                self.error_code,
                "error_code",
            )

        if self.recovery_ref is not None:
            _require_text(
                self.recovery_ref,
                "recovery_ref",
            )

        if (
            self.lifecycle
            is ExecutionStepLifecycle.SUCCEEDED
            and self.error_code is not None
        ):
            raise ValueError(
                "successful step cannot contain error_code"
            )

        if (
            self.lifecycle
            is ExecutionStepLifecycle.FAILED
            and self.error_code is None
        ):
            raise ValueError(
                "failed step requires error_code"
            )

        object.__setattr__(
            self,
            "output",
            _freeze_mapping(
                self.output,
                "output",
            ),
        )


@dataclass(frozen=True, slots=True)
class ExecutionResult:
    """Immutable bounded result with partial outcomes and recovery state."""

    execution_id: str
    request_id: str
    execution_plan_ref: str
    policy_decision_ref: str
    idempotency_key: str
    lifecycle: ExecutionLifecycle
    started_at: datetime
    completed_at: datetime
    step_outcomes: tuple[ExecutionStepOutcome, ...]
    recovery_invocations: tuple[str, ...]
    partial_result: Mapping[str, object]

    def __post_init__(self) -> None:
        for field, value in (
            (
                "execution_id",
                self.execution_id,
            ),
            (
                "request_id",
                self.request_id,
            ),
            (
                "execution_plan_ref",
                self.execution_plan_ref,
            ),
            (
                "policy_decision_ref",
                self.policy_decision_ref,
            ),
            (
                "idempotency_key",
                self.idempotency_key,
            ),
        ):
            _require_text(
                value,
                field,
            )

        _require_aware_timestamp(
            self.started_at,
            "started_at",
        )

        _require_aware_timestamp(
            self.completed_at,
            "completed_at",
        )

        if self.completed_at < self.started_at:
            raise ValueError(
                "completed_at cannot precede started_at"
            )

        step_ids = tuple(
            outcome.step_id
            for outcome in self.step_outcomes
        )

        _require_unique_texts(
            step_ids,
            "step_outcomes step identifiers",
        )

        _require_unique_texts(
            self.recovery_invocations,
            "recovery_invocations",
        )

        if (
            self.lifecycle
            is ExecutionLifecycle.SUCCEEDED
            and any(
                outcome.lifecycle
                is not ExecutionStepLifecycle.SUCCEEDED
                for outcome in self.step_outcomes
            )
        ):
            raise ValueError(
                "successful execution requires all steps succeeded"
            )

        if (
            self.lifecycle
            is ExecutionLifecycle.PARTIAL
            and not self.step_outcomes
        ):
            raise ValueError(
                "partial execution requires step outcomes"
            )

        if (
            self.lifecycle
            is ExecutionLifecycle.RECOVERY_REQUIRED
            and not self.recovery_invocations
        ):
            raise ValueError(
                "recovery-required execution requires "
                "at least one recovery invocation"
            )

        object.__setattr__(
            self,
            "partial_result",
            _freeze_mapping(
                self.partial_result,
                "partial_result",
            ),
        )
