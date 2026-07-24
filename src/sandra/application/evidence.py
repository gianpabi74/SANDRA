"""Technology-independent Evidence Qualification contracts."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from types import MappingProxyType
from typing import Mapping

from governance.types import AuthorityLevel

from .messages import Command
from .observation import ObservationBatch


class QualificationOutcome(StrEnum):
    """Constitutional Evidence Qualification outcomes."""

    ACCEPT = "accept"
    REJECT = "reject"
    CORROBORATE = "corroborate"
    CONFLICT = "conflict"
    EXPIRE = "expire"
    REQUEST_MORE_EVIDENCE = "request_more_evidence"


def _require_text(value: str, field: str) -> None:
    if not value:
        raise ValueError(
            f"{field} must not be empty"
        )


def _require_aware(value: datetime, field: str) -> None:
    if value.tzinfo is None:
        raise ValueError(
            f"{field} must be timezone-aware"
        )


@dataclass(frozen=True, slots=True)
class QualificationRequest(Command):
    """Request qualification of one immutable Observation batch."""

    observation: ObservationBatch
    source_type: str
    raw_artifact_ref: str
    provenance: Mapping[str, str]
    integrity: str
    valid_until: datetime

    def __post_init__(self) -> None:
        Command.__post_init__(self)

        _require_text(
            self.source_type,
            "source_type",
        )
        _require_text(
            self.raw_artifact_ref,
            "raw_artifact_ref",
        )
        _require_text(
            self.integrity,
            "integrity",
        )
        _require_aware(
            self.valid_until,
            "valid_until",
        )

        if self.valid_until <= self.created_at:
            raise ValueError(
                "valid_until must follow created_at"
            )

        if (
            self.observation.request_id
            != self.correlation_id
        ):
            raise ValueError(
                "observation request_id must equal correlation_id"
            )

        object.__setattr__(
            self,
            "provenance",
            MappingProxyType(
                dict(self.provenance)
            ),
        )


@dataclass(frozen=True, slots=True)
class QualifiedEvidence:
    """Immutable result of an explicit qualification decision."""

    qualification_id: str
    request_id: str
    subject_ref: str
    capability_id: str
    source_ref: str
    source_type: str
    observed_at: datetime
    captured_at: datetime
    qualified_at: datetime
    valid_until: datetime
    authority: AuthorityLevel
    confidence: float
    integrity: str
    provenance: Mapping[str, str]
    raw_artifact_ref: str
    outcome: QualificationOutcome
    reason: str
    evidence_refs: tuple[str, ...]

    def __post_init__(self) -> None:
        for field, value in (
            ("qualification_id", self.qualification_id),
            ("request_id", self.request_id),
            ("subject_ref", self.subject_ref),
            ("capability_id", self.capability_id),
            ("source_ref", self.source_ref),
            ("source_type", self.source_type),
            ("integrity", self.integrity),
            ("raw_artifact_ref", self.raw_artifact_ref),
            ("reason", self.reason),
        ):
            _require_text(value, field)

        for field, value in (
            ("observed_at", self.observed_at),
            ("captured_at", self.captured_at),
            ("qualified_at", self.qualified_at),
            ("valid_until", self.valid_until),
        ):
            _require_aware(value, field)

        if not 0.0 <= self.confidence <= 1.0:
            raise ValueError(
                "confidence must be between 0.0 and 1.0"
            )

        if self.captured_at < self.observed_at:
            raise ValueError(
                "captured_at cannot precede observed_at"
            )

        if self.qualified_at < self.captured_at:
            raise ValueError(
                "qualified_at cannot precede captured_at"
            )

        allowed_authority = {
            QualificationOutcome.ACCEPT: {
                AuthorityLevel.OBSERVATIONAL,
                AuthorityLevel.AUTHORITATIVE,
            },
            QualificationOutcome.CORROBORATE: {
                AuthorityLevel.CORROBORATED,
            },
            QualificationOutcome.REJECT: {
                AuthorityLevel.UNKNOWN,
            },
            QualificationOutcome.CONFLICT: {
                AuthorityLevel.UNKNOWN,
            },
            QualificationOutcome.EXPIRE: {
                AuthorityLevel.UNKNOWN,
            },
            QualificationOutcome.REQUEST_MORE_EVIDENCE: {
                AuthorityLevel.UNKNOWN,
            },
        }

        if self.authority not in allowed_authority[
            self.outcome
        ]:
            raise ValueError(
                "authority is incompatible with qualification outcome"
            )

        if (
            self.authority
            is AuthorityLevel.CORROBORATED
            and len(self.evidence_refs) < 2
        ):
            raise ValueError(
                "corroborated evidence requires at least two references"
            )

        if (
            self.authority
            is AuthorityLevel.AUTHORITATIVE
            and not self.evidence_refs
        ):
            raise ValueError(
                "authoritative evidence requires an authority reference"
            )

        object.__setattr__(
            self,
            "provenance",
            MappingProxyType(
                dict(self.provenance)
            ),
        )
