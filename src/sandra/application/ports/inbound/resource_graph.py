"""Inbound Resource Graph use-case port."""

from __future__ import annotations

from typing import Protocol

from application.resource_graph import (
    ResourceGraphRequest,
    ResourceGraphSnapshot,
)
from application.result import ApplicationResult


class QueryResourceGraphPort(Protocol):
    """Drive bounded Resource Graph retrieval and impact traversal."""

    def execute(
        self,
        request: ResourceGraphRequest,
    ) -> ApplicationResult[ResourceGraphSnapshot]:
        """Return a bounded immutable graph snapshot."""
        ...
