#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000004A-governance-runtime-foundation.sh"

sandra_begin \
    "R3-000004A" \
    "Create governance runtime foundation"

for command_name in python3 git install cp sha256sum; do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
MANIFEST="${ROOT}/manifest/KNOWLEDGE_MANIFEST.json"
SOURCE_ROOT="${ROOT}/src/runtime"
PACKAGE_ROOT="${SOURCE_ROOT}/governance"
TEST_ROOT="${SOURCE_ROOT}/tests"
BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${MANIFEST}"
sandra_require_file \
    "${ROOT}/docs/specs/governance-model/schemas/managed-object.schema.json"

install -d -m 0700 "${BACKUP_ROOT}"

for target_file in "${STATE}" "${MANIFEST}"; do
    relative="${target_file#${ROOT}/}"
    backup_path="${BACKUP_ROOT}/${relative}"

    install -d -m 0700 "$(dirname "${backup_path}")"
    cp -a -- "${target_file}" "${backup_path}"
done

if [[ -d "${SOURCE_ROOT}" ]]; then
    cp -a -- "${SOURCE_ROOT}" "${BACKUP_ROOT}/runtime.before"
fi

install -d -m 0755 \
    "${PACKAGE_ROOT}" \
    "${TEST_ROOT}" \
    "$(dirname "${JOURNAL}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${PACKAGE_ROOT}/errors.py" <<'PYTHON'
"""Domain errors raised by the governance runtime."""


class GovernanceError(Exception):
    """Base class for deterministic governance runtime errors."""


class ResourceValidationError(GovernanceError):
    """Raised when a canonical resource violates its contract."""


class UnsupportedResourceError(GovernanceError):
    """Raised when a resource kind or API version is unsupported."""
PYTHON

cat > "${PACKAGE_ROOT}/types.py" <<'PYTHON'
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
    AUTHORITATIVE = "authoritative"
    CORROBORATED = "corroborated"
    CANDIDATE = "candidate"
    CONFLICTING = "conflicting"


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
PYTHON

cat > "${PACKAGE_ROOT}/validation.py" <<'PYTHON'
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
PYTHON

cat > "${PACKAGE_ROOT}/cli.py" <<'PYTHON'
"""Command-line interface for canonical resource validation."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Sequence

from .errors import GovernanceError
from .validation import load_resource


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="governance-resource",
        description=(
            "Validate canonical governance resource documents."
        ),
    )

    parser.add_argument(
        "paths",
        nargs="+",
        type=Path,
        help="JSON resource documents to validate",
    )

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)

    results: list[dict[str, str]] = []
    failed = False

    for path in arguments.paths:
        try:
            resource = load_resource(path)
        except GovernanceError as exc:
            failed = True
            results.append(
                {
                    "path": str(path),
                    "status": "FAIL",
                    "error": str(exc),
                }
            )
        else:
            results.append(
                {
                    "path": str(path),
                    "status": "PASS",
                    "apiVersion": resource.api_version,
                    "kind": resource.kind.value,
                    "id": resource.metadata.identifier,
                }
            )

    print(
        json.dumps(
            results,
            indent=2,
            ensure_ascii=False,
        )
    )

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
PYTHON

cat > "${PACKAGE_ROOT}/__init__.py" <<'PYTHON'
"""Deterministic governance runtime."""

from .errors import (
    GovernanceError,
    ResourceValidationError,
    UnsupportedResourceError,
)
from .types import (
    AuthorityLevel,
    PolicyOutcome,
    ProtectionProfile,
    ResourceEnvelope,
    ResourceKind,
    ResourceMetadata,
)
from .validation import (
    API_VERSION,
    load_resource,
    validate_document,
)

__all__ = [
    "API_VERSION",
    "AuthorityLevel",
    "GovernanceError",
    "PolicyOutcome",
    "ProtectionProfile",
    "ResourceEnvelope",
    "ResourceKind",
    "ResourceMetadata",
    "ResourceValidationError",
    "UnsupportedResourceError",
    "load_resource",
    "validate_document",
]
PYTHON

cat > "${PACKAGE_ROOT}/__main__.py" <<'PYTHON'
"""Module entry point."""

from .cli import main

raise SystemExit(main())
PYTHON

cat > "${TEST_ROOT}/test_validation.py" <<'PYTHON'
"""Tests for deterministic canonical resource validation."""

from __future__ import annotations

import copy
import json
import unittest
from pathlib import Path

from governance.errors import (
    ResourceValidationError,
    UnsupportedResourceError,
)
from governance.types import ResourceKind
from governance.validation import (
    load_resource,
    validate_document,
)


class ResourceValidationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        knowledge_root = (
            Path(__file__).resolve().parents[3]
        )
        cls.example_root = (
            knowledge_root
            / "docs"
            / "specs"
            / "governance-model"
            / "examples"
        )

    def load_example(
        self,
        filename: str,
    ) -> dict:
        return json.loads(
            (
                self.example_root
                / filename
            ).read_text(encoding="utf-8")
        )

    def test_managed_object_is_valid(self) -> None:
        resource = load_resource(
            self.example_root
            / "managed-object.example.json"
        )

        self.assertEqual(
            resource.kind,
            ResourceKind.MANAGED_OBJECT,
        )
        self.assertEqual(
            resource.metadata.identifier,
            "obj_01k0example000001",
        )

    def test_all_examples_are_valid(self) -> None:
        for path in sorted(
            self.example_root.glob("*.json")
        ):
            with self.subTest(path=path.name):
                load_resource(path)

    def test_unknown_api_version_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["apiVersion"] = "unknown/v1"

        with self.assertRaises(
            UnsupportedResourceError
        ):
            validate_document(document)

    def test_unknown_kind_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["kind"] = "UnknownResource"

        with self.assertRaises(
            UnsupportedResourceError
        ):
            validate_document(document)

    def test_unexpected_root_field_is_rejected(
        self,
    ) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["unexpected"] = True

        with self.assertRaises(
            ResourceValidationError
        ):
            validate_document(document)

    def test_invalid_identifier_is_rejected(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        document["metadata"]["id"] = "VM120"

        with self.assertRaises(
            ResourceValidationError
        ):
            validate_document(document)

    def test_input_document_is_not_mutated(self) -> None:
        document = self.load_example(
            "managed-object.example.json"
        )
        original = copy.deepcopy(document)

        validate_document(document)

        self.assertEqual(document, original)


if __name__ == "__main__":
    unittest.main()
PYTHON

cat > "${SOURCE_ROOT}/README.md" <<'EOF'
# Runtime source

Questa directory contiene il codice Python indipendente dalle tecnologie
specifiche dell'ambiente gestito.

Il package `governance` implementa esclusivamente contratti del dominio e
del ciclo di governo.

Non deve importare:

- provider o adapter specifici;
- API Proxmox, VMware, Windows o Linux;
- credenziali;
- configurazioni concrete dell'Habitat.
EOF

python3 - "${MANIFEST}" <<'PYTHON'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
manifest = json.loads(path.read_text(encoding="utf-8"))

source_roots = manifest["source_roots"]

if not any(
    record.get("id") == "runtime"
    for record in source_roots
):
    source_roots.append(
        {
            "id": "runtime",
            "root": "src/runtime",
            "owner": "runtime",
        }
    )

path.write_text(
    json.dumps(
        manifest,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

PYTHONPATH="${SOURCE_ROOT}" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/unit-tests.txt" \
    2>&1

EXAMPLE_ROOT="$(
    realpath \
        "${ROOT}/docs/specs/governance-model/examples"
)"

mapfile -t EXAMPLE_FILES < <(
    find "${EXAMPLE_ROOT}" \
        -maxdepth 1 \
        -type f \
        -name '*.json' \
        | sort
)

PYTHONPATH="${SOURCE_ROOT}" \
python3 -m governance \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/resource-validation.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/resource-validation.json" \
    "${#EXAMPLE_FILES[@]}" <<'PYTHON'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
expected_count = int(sys.argv[2])
results = json.loads(path.read_text(encoding="utf-8"))

if len(results) != expected_count:
    raise SystemExit(
        "RESOURCE_VALIDATION_RESULT_COUNT_INVALID"
    )

failed = [
    result
    for result in results
    if result.get("status") != "PASS"
]

if failed:
    raise SystemExit(
        "RESOURCE_VALIDATION_FAILED:"
        + json.dumps(failed)
    )

print("RESOURCE_RUNTIME_VALIDATION=PASS")
PYTHON

install -d -m 0755 "$(dirname "${JOURNAL}")"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Governance runtime foundation

- Run ID: \`${SANDRA_RUN_ID}\`
- Modifiche remote all'Habitat: \`NONE\`
- Nuovi software installati: \`NONE\`

## Risultato

- creato package Python \`governance\`;
- implementati tipi immutabili del dominio;
- implementata validazione deterministica degli envelope canonici;
- implementata CLI headless;
- aggiunti test unitari;
- validati tutti gli esempi canonici;
- aggiunto \`src/runtime\` al Knowledge manifest.
EOF

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
import datetime
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
runbook_id = sys.argv[2]
run_id = sys.argv[3]
journal = sys.argv[4]

state = json.loads(
    state_path.read_text(encoding="utf-8")
)

current_gate = (
    state["spec"]["roadmap"]
    ["current_gate"]["runbook"]
)

if current_gate not in {
    "R3-000003",
    "R3-000004",
}:
    raise SystemExit(
        f"STATE_UNEXPECTED_CURRENT_GATE:{current_gate}"
    )

state["metadata"]["state_version"] = "3.3.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["roadmap"]["current_gate"] = {
    "runbook": "R3-000004",
    "title": "Governance Runtime Foundation",
    "type": "runtime_implementation",
    "targets": [
        "Knowledge canonica",
        "Python runtime source",
        "unit tests",
    ],
    "excluded_targets": [
        "sistemi remoti dell'Habitat",
        "runtime installata",
    ],
    "objectives": [
        "creare package Python governance",
        "implementare envelope canonici",
        "implementare validazione deterministica",
        "implementare CLI headless",
        "aggiungere test automatici",
    ],
    "prohibitions": [
        "nessuna modifica remota",
        "nessuna installazione software",
        "nessuna dipendenza esterna",
        "nessun riferimento tecnologico nel dominio",
        "nessuna correzione ad intuito",
    ],
}

state["spec"]["roadmap"]["next_gate"] = {
    "runbook": "R3-000005",
    "title": "Adapter and Execution Contract",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Governance Runtime Foundation",
    "current_gate": "R3-000004",
    "current_gate_status": "complete",
    "next_gate": "R3-000005",
}

state["status"]["governance_runtime_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "implemented",
    "package": "src/runtime/governance",
    "validation": "deterministic",
    "cli": "implemented",
    "unit_tests": "pass",
    "external_dependencies": "none",
    "remote_habitat_modifications": "none",
    "software_installed": "none",
}

state_path.write_text(
    json.dumps(
        state,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: implement governance runtime foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'RUNTIME_IMPLEMENTATION=PASS\n'
    printf 'UNIT_TESTS=PASS\n'
    printf 'RESOURCE_VALIDATION=PASS\n'
    printf 'PYTHON_PACKAGE=src/runtime/governance\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
