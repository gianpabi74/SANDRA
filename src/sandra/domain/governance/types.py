"""Canonical immutable value types used by the governance runtime."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from types import MappingProxyType
from typing import Any, Mapping


class ResourceKind(StrEnum):
    MANAGED_OBJECT = "ManagedObject"
    OBSERVATION = "Observation"
    EVIDENCE = "Evidence"
    RELATIONSHIP = "Relationship"
    CAPABILITY = "Capability"
    GOVERNANCE_POLICY = "GovernancePolicy"
    POLICY_DECISION = "PolicyDecision"
    EXECUTION_PLAN = "ExecutionPlan"


class ProtectionProfile(StrEnum):
    PROTECTED = "protected"
    CRITICAL = "critical"
    STANDARD = "standard"
    DISPOSABLE = "disposable"


class AuthorityLevel(StrEnum):
    UNKNOWN = "unknown"
    OBSERVATIONAL = "observational"
    CORROBORATED = "corroborated"
    AUTHORITATIVE = "authoritative"


class PolicyOutcome(StrEnum):
    AUTONOMOUS = "autonomous"
    CONDITIONAL_AUTONOMOUS = "conditional_autonomous"
    ESCALATE = "escalate"
    DENIED = "denied"


@dataclass(frozen=True, slots=True)
class ResourceMetadata:
    """Metadata shared by canonical governance resources."""

    identifier: str
    name: str | None
    labels: Mapping[str, str]
    annotations: Mapping[str, str]
    created_at: datetime | None
    updated_at: datetime | None

    @classmethod
    def create(
        cls,
        *,
        identifier: str,
        name: str | None = None,
        labels: Mapping[str, str] | None = None,
        annotations: Mapping[str, str] | None = None,
        created_at: datetime | None = None,
        updated_at: datetime | None = None,
    ) -> ResourceMetadata:
        return cls(
            identifier=identifier,
            name=name,
            labels=MappingProxyType(dict(labels or {})),
            annotations=MappingProxyType(dict(annotations or {})),
            created_at=created_at,
            updated_at=updated_at,
        )


@dataclass(frozen=True, slots=True)
class ResourceEnvelope:
    """Validated immutable canonical resource envelope."""

    api_version: str
    kind: ResourceKind
    metadata: ResourceMetadata
    spec: Mapping[str, Any] | None
    status: Mapping[str, Any] | None
    payload: Mapping[str, Any]

    @classmethod
    def create(
        cls,
        *,
        api_version: str,
        kind: ResourceKind,
        metadata: ResourceMetadata,
        spec: Mapping[str, Any] | None,
        status: Mapping[str, Any] | None,
        payload: Mapping[str, Any],
    ) -> ResourceEnvelope:
        return cls(
            api_version=api_version,
            kind=kind,
            metadata=metadata,
            spec=(
                MappingProxyType(dict(spec))
                if spec is not None
                else None
            ),
            status=(
                MappingProxyType(dict(status))
                if status is not None
                else None
            ),
            payload=MappingProxyType(dict(payload)),
        )
