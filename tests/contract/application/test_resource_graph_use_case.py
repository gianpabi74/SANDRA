from __future__ import annotations

from datetime import datetime, timezone
from typing import cast
import unittest

from governance.types import (
    ResourceEnvelope,
    ResourceKind,
    ResourceMetadata,
)

from application.ports.outbound.resource_graph_reader import (
    ResourceGraphReader,
    ResourceGraphReaderError,
)
from application.resource_graph import (
    GraphDirection,
    ResourceGraphRequest,
    ResourceGraphSnapshot,
)
from application.use_cases.query_resource_graph import (
    QueryResourceGraph,
)


def metadata(
    identifier: str,
) -> ResourceMetadata:
    return ResourceMetadata.create(
        identifier=identifier,
    )


def resource(
    identifier: str,
) -> ResourceEnvelope:
    return ResourceEnvelope.create(
        api_version="governance.sandra.io/v1",
        kind=ResourceKind.MANAGED_OBJECT,
        metadata=metadata(identifier),
        spec={},
        status={},
        payload={},
    )


def relationship(
    identifier: str,
) -> ResourceEnvelope:
    return ResourceEnvelope.create(
        api_version="governance.sandra.io/v1",
        kind=ResourceKind.RELATIONSHIP,
        metadata=metadata(identifier),
        spec={},
        status={},
        payload={},
    )


def request() -> ResourceGraphRequest:
    return ResourceGraphRequest(
        message_id="graph-request-1",
        correlation_id="graph-correlation-1",
        created_at=datetime.now(
            timezone.utc
        ),
        root_ref="resource-1",
        direction=GraphDirection.BOTH,
        relationship_types=(
            "dependency",
            "peer",
        ),
        max_depth=3,
    )


class SuccessfulReader:
    def read(
        self,
        value: ResourceGraphRequest,
    ) -> ResourceGraphSnapshot:
        return ResourceGraphSnapshot(
            request_id=value.message_id,
            root_ref=value.root_ref,
            resources=(
                resource("resource-1"),
                resource("resource-2"),
            ),
            relationships=(
                relationship("relationship-1"),
            ),
            impacted_refs=(
                "resource-2",
            ),
        )


class FailedReader:
    def read(
        self,
        value: ResourceGraphRequest,
    ) -> ResourceGraphSnapshot:
        raise ResourceGraphReaderError(
            "graph unavailable"
        )


class MismatchedReader:
    def read(
        self,
        value: ResourceGraphRequest,
    ) -> ResourceGraphSnapshot:
        return ResourceGraphSnapshot(
            request_id="different-request",
            root_ref=value.root_ref,
            resources=(
                resource("resource-1"),
            ),
            relationships=(),
            impacted_refs=(),
        )


class ResourceGraphUseCaseTests(
    unittest.TestCase
):
    def test_successful_graph_query(self) -> None:
        use_case = QueryResourceGraph(
            cast(
                ResourceGraphReader,
                SuccessfulReader(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertTrue(result.success)

        self.assertEqual(
            result.code,
            "RESOURCE_GRAPH_RETRIEVED",
        )

        self.assertIsNotNone(
            result.value
        )

        self.assertEqual(
            len(result.value.resources),
            2,
        )

        self.assertEqual(
            result.value.impacted_refs,
            ("resource-2",),
        )

    def test_reader_failure_is_explicit(self) -> None:
        use_case = QueryResourceGraph(
            cast(
                ResourceGraphReader,
                FailedReader(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertFalse(result.success)

        self.assertEqual(
            result.code,
            "RESOURCE_GRAPH_READER_FAILED",
        )

    def test_request_mismatch_is_rejected(self) -> None:
        use_case = QueryResourceGraph(
            cast(
                ResourceGraphReader,
                MismatchedReader(),
            )
        )

        result = use_case.execute(
            request()
        )

        self.assertFalse(result.success)

        self.assertEqual(
            result.code,
            "RESOURCE_GRAPH_REQUEST_MISMATCH",
        )

    def test_request_rejects_invalid_depth(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ResourceGraphRequest(
                message_id="graph-request-2",
                correlation_id="graph-correlation-2",
                created_at=datetime.now(
                    timezone.utc
                ),
                root_ref="resource-1",
                max_depth=33,
            )

    def test_snapshot_requires_root_resource(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ResourceGraphSnapshot(
                request_id="graph-request-1",
                root_ref="resource-missing",
                resources=(
                    resource("resource-1"),
                ),
                relationships=(),
                impacted_refs=(),
            )

    def test_snapshot_rejects_wrong_resource_kind(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ResourceGraphSnapshot(
                request_id="graph-request-1",
                root_ref="relationship-1",
                resources=(
                    relationship(
                        "relationship-1"
                    ),
                ),
                relationships=(),
                impacted_refs=(),
            )

    def test_snapshot_rejects_external_impact_reference(
        self,
    ) -> None:
        with self.assertRaises(
            ValueError
        ):
            ResourceGraphSnapshot(
                request_id="graph-request-1",
                root_ref="resource-1",
                resources=(
                    resource("resource-1"),
                ),
                relationships=(),
                impacted_refs=(
                    "resource-missing",
                ),
            )

    def test_relationship_types_are_unique(self) -> None:
        with self.assertRaises(
            ValueError
        ):
            ResourceGraphRequest(
                message_id="graph-request-3",
                correlation_id="graph-correlation-3",
                created_at=datetime.now(
                    timezone.utc
                ),
                root_ref="resource-1",
                relationship_types=(
                    "dependency",
                    "dependency",
                ),
            )


if __name__ == "__main__":
    unittest.main()
