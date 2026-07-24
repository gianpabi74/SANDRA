"""Outbound port for Resource Graph retrieval and traversal."""

from __future__ import annotations

from typing import Protocol

from application.resource_graph import (
    ResourceGraphRequest,
    ResourceGraphSnapshot,
)


class ResourceGraphReaderError(Exception):
    """Resource Graph reader failed before returning a valid snapshot."""


class ResourceGraphReader(Protocol):
    """Read a bounded graph without mutating authoritative state."""

    def read(
        self,
        request: ResourceGraphRequest,
    ) -> ResourceGraphSnapshot:
        """Return one immutable graph snapshot."""
        ...
