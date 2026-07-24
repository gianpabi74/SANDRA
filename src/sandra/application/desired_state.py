"""Technology-independent Desired State application contracts."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from types import MappingProxyType
from typing import TypeAlias

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
        f"{path} contains an unsupported value type: "
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
class DesiredStateDeclaration(Command):
    """Declare approved intent for one managed subject."""

    subject_ref: str
    approval_ref: str
    expected_generation: int
    desired_configuration: Mapping[str, object]
    desired_service_state: str
    declared_limits: Mapping[str, object]

    def __post_init__(self) -> None:
        Command.__post_init__(self)

        _require_text(
            self.subject_ref,
            "subject_ref",
        )

        _require_text(
            self.approval_ref,
            "approval_ref",
        )

        _require_text(
            self.desired_service_state,
            "desired_service_state",
        )

        if self.expected_generation < 0:
            raise ValueError(
                "expected_generation cannot be negative"
            )

        object.__setattr__(
            self,
            "desired_configuration",
            _freeze_mapping(
                self.desired_configuration,
                "desired_configuration",
            ),
        )

        object.__setattr__(
            self,
            "declared_limits",
            _freeze_mapping(
                self.declared_limits,
                "declared_limits",
            ),
        )


@dataclass(frozen=True, slots=True)
class DesiredStateRecord:
    """Immutable approved intent at one monotonic generation."""

    desired_state_id: str
    subject_ref: str
    generation: int
    declared_at: datetime
    approval_ref: str
    desired_configuration: Mapping[str, object]
    desired_service_state: str
    declared_limits: Mapping[str, object]

    def __post_init__(self) -> None:
        _require_text(
            self.desired_state_id,
            "desired_state_id",
        )

        _require_text(
            self.subject_ref,
            "subject_ref",
        )

        _require_text(
            self.approval_ref,
            "approval_ref",
        )

        _require_text(
            self.desired_service_state,
            "desired_service_state",
        )

        _require_aware_timestamp(
            self.declared_at,
            "declared_at",
        )

        if self.generation < 1:
            raise ValueError(
                "generation must be at least 1"
            )

        object.__setattr__(
            self,
            "desired_configuration",
            _freeze_mapping(
                self.desired_configuration,
                "desired_configuration",
            ),
        )

        object.__setattr__(
            self,
            "declared_limits",
            _freeze_mapping(
                self.declared_limits,
                "declared_limits",
            ),
        )
