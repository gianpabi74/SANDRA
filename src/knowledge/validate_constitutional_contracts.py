#!/usr/bin/env python3

from __future__ import annotations

import json
from pathlib import Path
import sys
from typing import Any, NoReturn


EXPECTED = {
    "resource-lifecycle-v1": {
        "kind": "ResourceLifecycleContract",
        "file": "RESOURCE-LIFECYCLE-CONTRACT-V1.json",
    },
    "evidence-authority-v1": {
        "kind": "EvidenceAuthorityContract",
        "file": "EVIDENCE-AUTHORITY-CONTRACT-V1.json",
    },
    "reconciliation-concurrency-v1": {
        "kind": "ReconciliationConcurrencyContract",
        "file": "RECONCILIATION-CONCURRENCY-CONTRACT-V1.json",
    },
    "execution-safety-v1": {
        "kind": "ExecutionSafetyContract",
        "file": "EXECUTION-SAFETY-CONTRACT-V1.json",
    },
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"CONSTITUTIONAL_CONTRACTS_INVALID:{message}"
    )


def load(path: Path) -> dict[str, Any]:
    try:
        document = json.loads(
            path.read_text(encoding="utf-8")
        )
    except FileNotFoundError:
        fail(f"MISSING:{path}")
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:{exc.lineno}:{exc.colno}"
        )

    if not isinstance(document, dict):
        fail(f"ROOT_NOT_OBJECT:{path}")

    return document


def require_unique_strings(
    value: Any,
    field: str,
) -> list[str]:
    if not isinstance(value, list) or not value:
        fail(f"INVALID_LIST:{field}")

    if not all(
        isinstance(item, str) and item
        for item in value
    ):
        fail(f"INVALID_STRING_LIST:{field}")

    if len(value) != len(set(value)):
        fail(f"DUPLICATE_VALUES:{field}")

    return value


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    root = Path(sys.argv[1]).resolve()
    index_path = Path(sys.argv[2]).resolve()
    architecture_path = Path(sys.argv[3]).resolve()

    architecture = load(architecture_path)

    if (
        architecture.get("kind")
        != "ArchitectureConstitution"
    ):
        fail("ARCHITECTURE_KIND")

    if (
        architecture.get("metadata", {}).get("id")
        != "architecture-constitution-v1"
    ):
        fail("ARCHITECTURE_ID")

    index = load(index_path)

    if index.get("kind") != "ConstitutionalContracts":
        fail("INDEX_KIND")

    if (
        index.get("metadata", {}).get("id")
        != "constitutional-operational-contracts-v1"
    ):
        fail("INDEX_ID")

    declared = index.get("spec", {}).get("contracts")

    if not isinstance(declared, list):
        fail("INDEX_CONTRACTS")

    declared_by_id = {
        item.get("id"): item
        for item in declared
        if isinstance(item, dict)
    }

    if set(declared_by_id) != set(EXPECTED):
        fail("INDEX_CONTRACT_SET")

    for identifier, expected in EXPECTED.items():
        item = declared_by_id[identifier]
        relative = item.get("path")

        if not isinstance(relative, str) or not relative:
            fail(f"INDEX_PATH:{identifier}")

        path = root / relative

        if path.name != expected["file"]:
            fail(f"INDEX_FILENAME:{identifier}")

        contract = load(path)

        if contract.get("apiVersion") != (
            "constitution.sandra.io/v1"
        ):
            fail(f"API_VERSION:{identifier}")

        if contract.get("kind") != expected["kind"]:
            fail(f"KIND:{identifier}")

        metadata = contract.get("metadata")

        if not isinstance(metadata, dict):
            fail(f"METADATA:{identifier}")

        if metadata.get("id") != identifier:
            fail(f"IDENTIFIER:{identifier}")

        if metadata.get("status") != "immutable":
            fail(f"STATUS:{identifier}")

        spec = contract.get("spec")

        if not isinstance(spec, dict):
            fail(f"SPEC:{identifier}")

        require_unique_strings(
            spec.get("rules"),
            f"{identifier}.rules",
        )

        require_unique_strings(
            spec.get("forbiddenBehaviors"),
            f"{identifier}.forbiddenBehaviors",
        )

    lifecycle = load(
        root
        / "docs/contracts/constitutional/"
        "RESOURCE-LIFECYCLE-CONTRACT-V1.json"
    )

    states = require_unique_strings(
        lifecycle["spec"].get("states"),
        "lifecycle.states",
    )

    if "discovered" not in states:
        fail("LIFECYCLE_DISCOVERED")

    if "retired" not in states:
        fail("LIFECYCLE_RETIRED")

    evidence = load(
        root
        / "docs/contracts/constitutional/"
        "EVIDENCE-AUTHORITY-CONTRACT-V1.json"
    )

    authority = require_unique_strings(
        evidence["spec"].get("authorityLevels"),
        "evidence.authorityLevels",
    )

    if "authoritative" not in authority:
        fail("EVIDENCE_AUTHORITATIVE")

    concurrency = load(
        root
        / "docs/contracts/constitutional/"
        "RECONCILIATION-CONCURRENCY-CONTRACT-V1.json"
    )

    require_unique_strings(
        concurrency["spec"].get(
            "requiredPreExecutionChecks"
        ),
        "concurrency.requiredPreExecutionChecks",
    )

    execution = load(
        root
        / "docs/contracts/constitutional/"
        "EXECUTION-SAFETY-CONTRACT-V1.json"
    )

    authority_modes = require_unique_strings(
        execution["spec"].get("authorityModes"),
        "execution.authorityModes",
    )

    if "automatic" not in authority_modes:
        fail("EXECUTION_AUTOMATIC")

    if "prohibited" not in authority_modes:
        fail("EXECUTION_PROHIBITED")

    print("CONSTITUTIONAL_CONTRACTS=PASS")
    print("CONSTITUTIONAL_CONTRACT_COUNT=4")
    print("CONSTITUTIONAL_CONTRACT_STATUS=IMMUTABLE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
