"""Technology-independent Policy Decision application contracts."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from types import MappingProxyType
from typing import TypeAlias

from .messages import Query


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


class PolicyDecisionEffect(StrEnum):
    """Canonical outcomes owned by the policy_decision capability."""

    ALLOW = "allow"
    DENY = "deny"
    CONDITIONAL = "conditional"


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
class PolicyDecisionRequest(Query):
    """Request a bounded decision for one proposed action."""

    subject_ref: str
    proposed_action_ref: str
    desired_state_ref: str
    evidence_refs: tuple[str, ...]
    resource_graph_ref: str
    requested_limits: Mapping[str, object]
    context: Mapping[str, object]

    def __post_init__(self) -> None:
        Query.__post_init__(self)

        _require_text(
            self.subject_ref,
            "subject_ref",
        )

        _require_text(
            self.proposed_action_ref,
            "proposed_action_ref",
        )

        _require_text(
            self.desired_state_ref,
            "desired_state_ref",
        )

        _require_text(
            self.resource_graph_ref,
            "resource_graph_ref",
        )

        _require_unique_texts(
            self.evidence_refs,
            "evidence_refs",
        )

        if not self.evidence_refs:
            raise ValueError(
                "evidence_refs must contain at least one reference"
            )

        object.__setattr__(
            self,
            "requested_limits",
            _freeze_mapping(
                self.requested_limits,
                "requested_limits",
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
class PolicyDecisionResult:
    """Immutable policy decision without execution or verification."""

    decision_id: str
    request_id: str
    subject_ref: str
    proposed_action_ref: str
    effect: PolicyDecisionEffect
    approval_required: bool
    limits: Mapping[str, object]
    reasons: tuple[str, ...]
    decided_at: datetime
    expires_at: datetime

    def __post_init__(self) -> None:
        for field, value in (
            (
                "decision_id",
                self.decision_id,
            ),
            (
                "request_id",
                self.request_id,
            ),
            (
                "subject_ref",
                self.subject_ref,
            ),
            (
                "proposed_action_ref",
                self.proposed_action_ref,
            ),
        ):
            _require_text(
                value,
                field,
            )

        _require_unique_texts(
            self.reasons,
            "reasons",
        )

        if not self.reasons:
            raise ValueError(
                "reasons must contain at least one reason"
            )

        _require_aware_timestamp(
            self.decided_at,
            "decided_at",
        )

        _require_aware_timestamp(
            self.expires_at,
            "expires_at",
        )

        if self.expires_at <= self.decided_at:
            raise ValueError(
                "expires_at must follow decided_at"
            )

        if (
            self.effect
            is PolicyDecisionEffect.CONDITIONAL
            and not self.approval_required
            and not self.limits
        ):
            raise ValueError(
                "conditional decisions require approval or limits"
            )

        if (
            self.effect
            is PolicyDecisionEffect.DENY
            and self.approval_required
        ):
            raise ValueError(
                "deny decisions cannot require approval"
            )

        object.__setattr__(
            self,
            "limits",
            _freeze_mapping(
                self.limits,
                "limits",
            ),
        )
