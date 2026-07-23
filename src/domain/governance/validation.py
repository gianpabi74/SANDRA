"""Deterministic validation of canonical governance resources."""

from __future__ import annotations

import json
import re
from datetime import datetime
from pathlib import Path
from typing import Any, Mapping

from .errors import (
    ResourceValidationError,
    UnsupportedResourceError,
)
from .types import (
    ResourceEnvelope,
    ResourceKind,
    ResourceMetadata,
)

API_VERSION = "governance.sandra.io/v1"

IDENTIFIER_PATTERNS: dict[ResourceKind, re.Pattern[str]] = {
    ResourceKind.MANAGED_OBJECT: re.compile(
        r"^obj_[a-z0-9]{16,64}$"
    ),
    ResourceKind.OBSERVATION: re.compile(
        r"^obs_[a-z0-9]{16,64}$"
    ),
    ResourceKind.EVIDENCE: re.compile(
        r"^evd_[a-z0-9]{16,64}$"
    ),
    ResourceKind.RELATIONSHIP: re.compile(
        r"^rel_[a-z0-9]{16,64}$"
    ),
    ResourceKind.POLICY_DECISION: re.compile(
        r"^dec_[a-z0-9]{16,64}$"
    ),
    ResourceKind.EXECUTION_PLAN: re.compile(
        r"^plan_[a-z0-9]{16,64}$"
    ),
    ResourceKind.CAPABILITY: re.compile(
        r"^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)+$"
    ),
    ResourceKind.GOVERNANCE_POLICY: re.compile(
        r"^policy\.[a-z][a-z0-9_.]*$"
    ),
}

RESOURCE_REQUIRED_FIELDS: dict[ResourceKind, frozenset[str]] = {
    ResourceKind.MANAGED_OBJECT: frozenset(
        {"apiVersion", "kind", "metadata", "spec", "status"}
    ),
    ResourceKind.OBSERVATION: frozenset(
        {
            "apiVersion",
            "kind",
            "metadata",
            "subjectRef",
            "source",
            "observedAt",
            "attribute",
            "value",
            "unit",
            "quality",
            "rawArtifactRef",
        }
    ),
    ResourceKind.EVIDENCE: frozenset(
        {
            "apiVersion",
            "kind",
            "metadata",
            "subjectRef",
            "observationRefs",
            "authority",
            "provenance",
            "integrity",
            "capturedAt",
        }
    ),
    ResourceKind.RELATIONSHIP: frozenset(
        {
            "apiVersion",
            "kind",
            "metadata",
            "sourceRef",
            "type",
            "targetRef",
            "evidenceRefs",
            "validFrom",
            "validUntil",
        }
    ),
    ResourceKind.CAPABILITY: frozenset(
        {"apiVersion", "kind", "metadata", "spec"}
    ),
    ResourceKind.GOVERNANCE_POLICY: frozenset(
        {"apiVersion", "kind", "metadata", "spec"}
    ),
    ResourceKind.POLICY_DECISION: frozenset(
        {
            "apiVersion",
            "kind",
            "metadata",
            "subjectRef",
            "capabilityRef",
            "policyRefs",
            "evidenceRefs",
            "outcome",
            "conditions",
            "limits",
            "reasons",
            "decidedAt",
            "expiresAt",
        }
    ),
    ResourceKind.EXECUTION_PLAN: frozenset(
        {
            "apiVersion",
            "kind",
            "metadata",
            "decisionRef",
            "subjectRef",
            "capabilityRef",
            "adapter",
            "prechecks",
            "actions",
            "postchecks",
            "recovery",
            "limits",
            "createdAt",
            "expiresAt",
            "digest",
        }
    ),
}


def _require_mapping(
    value: Any,
    field_name: str,
) -> Mapping[str, Any]:
    if not isinstance(value, dict):
        raise ResourceValidationError(
            f"{field_name} must be an object"
        )

    return value


def _require_string(
    value: Any,
    field_name: str,
) -> str:
    if not isinstance(value, str) or not value:
        raise ResourceValidationError(
            f"{field_name} must be a non-empty string"
        )

    return value


def _parse_datetime(
    value: Any,
    field_name: str,
) -> datetime | None:
    if value is None:
        return None

    text = _require_string(value, field_name)

    try:
        return datetime.fromisoformat(
            text.replace("Z", "+00:00")
        )
    except ValueError as exc:
        raise ResourceValidationError(
            f"{field_name} must be an RFC 3339 timestamp"
        ) from exc


def _parse_string_map(
    value: Any,
    field_name: str,
) -> dict[str, str]:
    mapping = _require_mapping(value, field_name)
    result: dict[str, str] = {}

    for key, item in mapping.items():
        if not isinstance(key, str):
            raise ResourceValidationError(
                f"{field_name} keys must be strings"
            )

        if not isinstance(item, str):
            raise ResourceValidationError(
                f"{field_name}.{key} must be a string"
            )

        result[key] = item

    return result


def _parse_kind(value: Any) -> ResourceKind:
    text = _require_string(value, "kind")

    try:
        return ResourceKind(text)
    except ValueError as exc:
        raise UnsupportedResourceError(
            f"unsupported resource kind: {text}"
        ) from exc


def _validate_required_fields(
    document: Mapping[str, Any],
    kind: ResourceKind,
) -> None:
    expected = RESOURCE_REQUIRED_FIELDS[kind]
    actual = frozenset(document)

    missing = expected - actual
    unexpected = actual - expected

    if missing:
        raise ResourceValidationError(
            "missing fields: " + ", ".join(sorted(missing))
        )

    if unexpected:
        raise ResourceValidationError(
            "unexpected fields: "
            + ", ".join(sorted(unexpected))
        )


def _parse_metadata(
    value: Any,
    kind: ResourceKind,
) -> ResourceMetadata:
    metadata = _require_mapping(value, "metadata")

    identifier = _require_string(
        metadata.get("id"),
        "metadata.id",
    )

    pattern = IDENTIFIER_PATTERNS[kind]

    if not pattern.fullmatch(identifier):
        raise ResourceValidationError(
            f"metadata.id invalid for {kind.value}: "
            f"{identifier}"
        )

    name = metadata.get("name")

    if name is not None:
        name = _require_string(name, "metadata.name")

    labels = _parse_string_map(
        metadata.get("labels", {}),
        "metadata.labels",
    )
    annotations = _parse_string_map(
        metadata.get("annotations", {}),
        "metadata.annotations",
    )

    created_at = _parse_datetime(
        metadata.get("createdAt"),
        "metadata.createdAt",
    )
    updated_at = _parse_datetime(
        metadata.get("updatedAt"),
        "metadata.updatedAt",
    )

    return ResourceMetadata.create(
        identifier=identifier,
        name=name,
        labels=labels,
        annotations=annotations,
        created_at=created_at,
        updated_at=updated_at,
    )


def validate_document(
    document: Mapping[str, Any],
) -> ResourceEnvelope:
    """Validate and normalize one canonical resource document."""

    if not isinstance(document, dict):
        raise ResourceValidationError(
            "resource root must be an object"
        )

    api_version = _require_string(
        document.get("apiVersion"),
        "apiVersion",
    )

    if api_version != API_VERSION:
        raise UnsupportedResourceError(
            f"unsupported apiVersion: {api_version}"
        )

    kind = _parse_kind(document.get("kind"))
    _validate_required_fields(document, kind)

    metadata = _parse_metadata(
        document.get("metadata"),
        kind,
    )

    spec_value = document.get("spec")
    status_value = document.get("status")

    spec = (
        _require_mapping(spec_value, "spec")
        if "spec" in document
        else None
    )
    status = (
        _require_mapping(status_value, "status")
        if "status" in document
        else None
    )

    return ResourceEnvelope.create(
        api_version=api_version,
        kind=kind,
        metadata=metadata,
        spec=spec,
        status=status,
        payload=document,
    )


def load_resource(path: str | Path) -> ResourceEnvelope:
    """Load, parse and validate one UTF-8 JSON resource."""

    resource_path = Path(path)

    try:
        document = json.loads(
            resource_path.read_text(encoding="utf-8")
        )
    except FileNotFoundError as exc:
        raise ResourceValidationError(
            f"resource file not found: {resource_path}"
        ) from exc
    except json.JSONDecodeError as exc:
        raise ResourceValidationError(
            f"invalid JSON at "
            f"{exc.lineno}:{exc.colno}: {resource_path}"
        ) from exc
    except OSError as exc:
        raise ResourceValidationError(
            f"cannot read resource: {resource_path}"
        ) from exc

    return validate_document(document)
