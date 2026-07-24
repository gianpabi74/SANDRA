"""Technology-independent Planning application contracts."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
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


def _require_text(
    value: str,
    field: str,
) -> None:
    if not value:
        raise ValueError(
            f"{field} must not be empty"
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
class PlanningRequest(Command):
    """Request one bounded plan from an existing Policy Decision."""

    subject_ref: str
    policy_decision_ref: str
    desired_state_ref: str
    resource_graph_ref: str
    requested_action_refs: tuple[str, ...]
    execution_limits: Mapping[str, object]
    context: Mapping[str, object]

    def __post_init__(self) -> None:
        Command.__post_init__(self)

        for field, value in (
            (
                "subject_ref",
                self.subject_ref,
            ),
            (
                "policy_decision_ref",
                self.policy_decision_ref,
            ),
            (
                "desired_state_ref",
                self.desired_state_ref,
            ),
            (
                "resource_graph_ref",
                self.resource_graph_ref,
            ),
        ):
            _require_text(
                value,
                field,
            )

        _require_unique_texts(
            self.requested_action_refs,
            "requested_action_refs",
        )

        if not self.requested_action_refs:
            raise ValueError(
                "requested_action_refs must contain "
                "at least one action"
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
class PlanStep:
    """One declarative and ordered plan step."""

    step_id: str
    action_ref: str
    order: int
    depends_on: tuple[str, ...]
    preconditions: tuple[str, ...]
    postconditions: tuple[str, ...]
    recovery_ref: str | None
    limits: Mapping[str, object]

    def __post_init__(self) -> None:
        _require_text(
            self.step_id,
            "step_id",
        )

        _require_text(
            self.action_ref,
            "action_ref",
        )

        if self.order < 1:
            raise ValueError(
                "order must be at least 1"
            )

        _require_unique_texts(
            self.depends_on,
            "depends_on",
        )

        _require_unique_texts(
            self.preconditions,
            "preconditions",
        )

        _require_unique_texts(
            self.postconditions,
            "postconditions",
        )

        if self.step_id in self.depends_on:
            raise ValueError(
                "step cannot depend on itself"
            )

        if self.recovery_ref is not None:
            _require_text(
                self.recovery_ref,
                "recovery_ref",
            )

        object.__setattr__(
            self,
            "limits",
            _freeze_mapping(
                self.limits,
                "limits",
            ),
        )


@dataclass(frozen=True, slots=True)
class PlanningResult:
    """Immutable ordered plan using the canonical ExecutionPlan resource."""

    request_id: str
    subject_ref: str
    policy_decision_ref: str
    execution_plan: ResourceEnvelope
    steps: tuple[PlanStep, ...]

    def __post_init__(self) -> None:
        for field, value in (
            (
                "request_id",
                self.request_id,
            ),
            (
                "subject_ref",
                self.subject_ref,
            ),
            (
                "policy_decision_ref",
                self.policy_decision_ref,
            ),
        ):
            _require_text(
                value,
                field,
            )

        if self.execution_plan.kind is not (
            ResourceKind.EXECUTION_PLAN
        ):
            raise ValueError(
                "execution_plan must have kind ExecutionPlan"
            )

        if not self.steps:
            raise ValueError(
                "steps must not be empty"
            )

        identifiers = [
            step.step_id
            for step in self.steps
        ]

        orders = [
            step.order
            for step in self.steps
        ]

        if len(identifiers) != len(
            set(identifiers)
        ):
            raise ValueError(
                "step identifiers must be unique"
            )

        if orders != list(
            range(
                1,
                len(self.steps) + 1,
            )
        ):
            raise ValueError(
                "step order must be contiguous "
                "and start at 1"
            )

        known_steps: set[str] = set()

        for step in self.steps:
            if not set(
                step.depends_on
            ).issubset(known_steps):
                raise ValueError(
                    "step dependencies must reference "
                    "earlier steps"
                )

            known_steps.add(
                step.step_id
            )
