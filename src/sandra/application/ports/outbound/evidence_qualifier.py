"""Outbound port for Evidence Qualification decisions."""

from __future__ import annotations

from typing import Protocol

from application.evidence import (
    QualificationRequest,
    QualifiedEvidence,
)


class EvidenceQualifierError(Exception):
    """Qualification source could not produce a valid decision."""


class EvidenceQualifier(Protocol):
    """Qualify evidence without persisting or executing actions."""

    def qualify(
        self,
        request: QualificationRequest,
    ) -> QualifiedEvidence:
        """Return one explicit immutable qualification decision."""
        ...
