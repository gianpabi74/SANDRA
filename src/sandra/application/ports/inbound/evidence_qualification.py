"""Inbound Evidence Qualification use-case port."""

from __future__ import annotations

from typing import Protocol

from application.evidence import (
    QualificationRequest,
    QualifiedEvidence,
)
from application.result import ApplicationResult


class QualifyEvidencePort(Protocol):
    """Drive Evidence Qualification."""

    def execute(
        self,
        request: QualificationRequest,
    ) -> ApplicationResult[QualifiedEvidence]:
        """Qualify an Observation batch."""
        ...
