"""Technology-independent Resource Graph application contracts."""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from governance.types import (
    ResourceEnvelope,
    ResourceKind,
)

from .messages import Query


class GraphDirection(StrEnum):
    """Traversal direction relative to the requested root resource."""

    OUTBOUND = "outbound"
    INBOUND = "inbound"
    BOTH = "both"


def _require_text(
    value: str,
    field: str,
) -> None:
    if not value:
        raise ValueError(
            f"{field} must not be empty"
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


@dataclass(frozen=True, slots=True)
class ResourceGraphRequest(Query):
    """Request a bounded graph view rooted at one managed resource."""

    root_ref: str
    direction: GraphDirection = GraphDirection.BOTH
    relationship_types: tuple[str, ...] = ()
    max_depth: int = 1

    def __post_init__(self) -> None:
        Query.__post_init__(self)

        _require_text(
            self.root_ref,
            "root_ref",
        )

        _require_unique_texts(
            self.relationship_types,
            "relationship_types",
        )

        if not 0 <= self.max_depth <= 32:
            raise ValueError(
                "max_depth must be between 0 and 32"
            )


@dataclass(frozen=True, slots=True)
class ResourceGraphSnapshot:
    """Immutable bounded view of managed resources and relationships."""

    request_id: str
    root_ref: str
    resources: tuple[ResourceEnvelope, ...]
    relationships: tuple[ResourceEnvelope, ...]
    impacted_refs: tuple[str, ...]

    def __post_init__(self) -> None:
        _require_text(
            self.request_id,
            "request_id",
        )

        _require_text(
            self.root_ref,
            "root_ref",
        )

        _require_unique_texts(
            self.impacted_refs,
            "impacted_refs",
        )

        resource_ids = [
            resource.metadata.identifier
            for resource in self.resources
        ]

        relationship_ids = [
            relationship.metadata.identifier
            for relationship in self.relationships
        ]

        if len(resource_ids) != len(
            set(resource_ids)
        ):
            raise ValueError(
                "resources cannot contain duplicate identifiers"
            )

        if len(relationship_ids) != len(
            set(relationship_ids)
        ):
            raise ValueError(
                "relationships cannot contain duplicate identifiers"
            )

        if self.root_ref not in resource_ids:
            raise ValueError(
                "root_ref must identify one returned resource"
            )

        for resource in self.resources:
            if resource.kind is not (
                ResourceKind.MANAGED_OBJECT
            ):
                raise ValueError(
                    "resources must contain only ManagedObject envelopes"
                )

        for relationship in self.relationships:
            if relationship.kind is not (
                ResourceKind.RELATIONSHIP
            ):
                raise ValueError(
                    "relationships must contain only Relationship envelopes"
                )

        resource_id_set = set(resource_ids)

        if not set(
            self.impacted_refs
        ).issubset(resource_id_set):
            raise ValueError(
                "impacted_refs must identify returned resources"
            )
