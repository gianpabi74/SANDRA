"""Inbound Desired State use-case port."""

from __future__ import annotations

from typing import Protocol

from application.desired_state import (
    DesiredStateDeclaration,
    DesiredStateRecord,
)
from application.result import ApplicationResult


class DeclareDesiredStatePort(Protocol):
    """Drive declaration of approved desired intent."""

    def execute(
        self,
        declaration: DesiredStateDeclaration,
    ) -> ApplicationResult[DesiredStateRecord]:
        """Declare one new Desired State generation."""
        ...
