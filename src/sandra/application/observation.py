"""Technology-independent Observation application contracts."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from types import MappingProxyType
from typing import Mapping

from .messages import Query


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


@dataclass(frozen=True, slots=True)
class ObservationRequest(Query):
    """Request collection of one capability for one subject."""

    subject_ref: str
    capability_id: str

    def __post_init__(self) -> None:
        Query.__post_init__(self)

        _require_text(
            self.subject_ref,
            "subject_ref",
        )
        _require_text(
            self.capability_id,
            "capability_id",
        )


@dataclass(frozen=True, slots=True)
class ObservedFact:
    """One raw fact returned by an Observation source."""

    subject_ref: str
    capability_id: str
    source_ref: str
    observed_at: datetime
    captured_at: datetime
    values: Mapping[str, object]

    def __post_init__(self) -> None:
        _require_text(
            self.subject_ref,
            "subject_ref",
        )
        _require_text(
            self.capability_id,
            "capability_id",
        )
        _require_text(
            self.source_ref,
            "source_ref",
        )
        _require_aware_timestamp(
            self.observed_at,
            "observed_at",
        )
        _require_aware_timestamp(
            self.captured_at,
            "captured_at",
        )

        if self.captured_at < self.observed_at:
            raise ValueError(
                "captured_at cannot precede observed_at"
            )

        object.__setattr__(
            self,
            "values",
            MappingProxyType(
                dict(self.values)
            ),
        )


@dataclass(frozen=True, slots=True)
class ObservationBatch:
    """Immutable collection result from one Observation request."""

    request_id: str
    subject_ref: str
    capability_id: str
    facts: tuple[ObservedFact, ...]

    def __post_init__(self) -> None:
        _require_text(
            self.request_id,
            "request_id",
        )
        _require_text(
            self.subject_ref,
            "subject_ref",
        )
        _require_text(
            self.capability_id,
            "capability_id",
        )

        for fact in self.facts:
            if fact.subject_ref != self.subject_ref:
                raise ValueError(
                    "fact subject_ref differs from batch"
                )

            if fact.capability_id != self.capability_id:
                raise ValueError(
                    "fact capability_id differs from batch"
                )
