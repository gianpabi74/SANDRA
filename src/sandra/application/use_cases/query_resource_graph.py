"""Resource Graph query use-case implementation."""

from __future__ import annotations

from application.ports.outbound.resource_graph_reader import (
    ResourceGraphReader,
    ResourceGraphReaderError,
)
from application.resource_graph import (
    ResourceGraphRequest,
    ResourceGraphSnapshot,
)
from application.result import ApplicationResult


class QueryResourceGraph:
    """Retrieve a bounded Resource Graph without mutation or policy decisions."""

    def __init__(
        self,
        reader: ResourceGraphReader,
    ) -> None:
        self._reader = reader

    def execute(
        self,
        request: ResourceGraphRequest,
    ) -> ApplicationResult[ResourceGraphSnapshot]:
        """Read and correlate one graph snapshot."""

        try:
            snapshot = self._reader.read(
                request
            )
        except ResourceGraphReaderError as exc:
            return ApplicationResult.fail(
                code="RESOURCE_GRAPH_READER_FAILED",
                error=str(exc),
            )

        if snapshot.request_id != request.message_id:
            return ApplicationResult.fail(
                code="RESOURCE_GRAPH_REQUEST_MISMATCH",
                error=(
                    "snapshot request_id does not match "
                    "the Resource Graph request"
                ),
            )

        if snapshot.root_ref != request.root_ref:
            return ApplicationResult.fail(
                code="RESOURCE_GRAPH_ROOT_MISMATCH",
                error=(
                    "snapshot root_ref does not match "
                    "the Resource Graph request"
                ),
            )

        return ApplicationResult.ok(
            code="RESOURCE_GRAPH_RETRIEVED",
            value=snapshot,
        )
