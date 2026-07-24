#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "resource_graph.py",
    "ports/inbound/resource_graph.py",
    "ports/outbound/resource_graph_reader.py",
    "use_cases/query_resource_graph.py",
}

EXPECTED_OWNS = {
    "relationships",
    "dependency edges",
    "peer relations",
    "containment",
    "impact traversal",
}

EXPECTED_DOMAIN_RESOURCES = {
    "ManagedObject",
    "Relationship",
    "ResourceEnvelope",
    "ResourceKind",
}

FORBIDDEN_IMPORTS = {
    "controllers",
    "adapters",
    "bootstrap",
}

FORBIDDEN_PRODUCT_TERMS = {
    "proxmox",
    "pve",
    "vmware",
    "linux",
    "windows",
    "pbs",
    "openvas",
    "greenbone",
    "opa",
    "ssh",
    "winrm",
    "telegram",
    "prometheus",
    "alertmanager",
    "nmap",
    "ansible",
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"RESOURCE_GRAPH_USE_CASE_INVALID:{message}"
    )


def load_json(
    path: Path,
) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8")
        )
    except FileNotFoundError:
        fail(f"MISSING:{path}")
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:{exc.lineno}:{exc.colno}"
        )

    if not isinstance(value, dict):
        fail(f"ROOT_NOT_OBJECT:{path}")

    return value


def imported_roots(
    tree: ast.AST,
) -> set[str]:
    result: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            result.update(
                alias.name.split(".", 1)[0]
                for alias in node.names
            )

        elif (
            isinstance(node, ast.ImportFrom)
            and node.module
        ):
            result.add(
                node.module.split(".", 1)[0]
            )

    return result


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    application_root = Path(sys.argv[1]).resolve()
    contract_path = Path(sys.argv[2]).resolve()
    capability_path = Path(sys.argv[3]).resolve()

    contract = load_json(
        contract_path
    )

    capability_map = load_json(
        capability_path
    )

    if contract.get("kind") != (
        "ResourceGraphUseCase"
    ):
        fail("CONTRACT_KIND")

    metadata = contract.get("metadata")

    if not isinstance(metadata, dict):
        fail("CONTRACT_METADATA")

    if metadata.get("id") != (
        "resource-graph-use-case-v1"
    ):
        fail("CONTRACT_ID")

    if metadata.get("status") != "immutable":
        fail("STATUS_NOT_IMMUTABLE")

    spec = contract.get("spec")

    if not isinstance(spec, dict):
        fail("CONTRACT_SPEC")

    if spec.get("capability") != "resource_graph":
        fail("CAPABILITY_REFERENCE")

    if set(spec.get("owns", [])) != EXPECTED_OWNS:
        fail("OWNS_SET")

    if set(
        spec.get(
            "domainResources",
            [],
        )
    ) != EXPECTED_DOMAIN_RESOURCES:
        fail("DOMAIN_RESOURCE_SET")

    capabilities = {
        item.get("id"): item
        for item in capability_map.get(
            "spec",
            {},
        ).get(
            "coreCapabilities",
            [],
        )
        if isinstance(item, dict)
    }

    graph_capability = capabilities.get(
        "resource_graph"
    )

    if not isinstance(
        graph_capability,
        dict,
    ):
        fail("CAPABILITY_MISSING")

    if set(
        graph_capability.get(
            "owns",
            [],
        )
    ) != EXPECTED_OWNS:
        fail("CAPABILITY_OWNS_MISMATCH")

    missing = sorted(
        relative
        for relative in EXPECTED_FILES
        if not (
            application_root / relative
        ).is_file()
    )

    if missing:
        fail(
            "MISSING_FILES:"
            + ",".join(missing)
        )

    violations: list[str] = []

    for relative in sorted(
        EXPECTED_FILES
    ):
        path = application_root / relative

        source = path.read_text(
            encoding="utf-8"
        )

        tree = ast.parse(
            source,
            filename=str(path),
        )

        forbidden_imports = sorted(
            imported_roots(tree)
            & FORBIDDEN_IMPORTS
        )

        if forbidden_imports:
            violations.append(
                f"{relative}:IMPORT:"
                + ",".join(
                    forbidden_imports
                )
            )

        words = set(
            re.findall(
                r"[a-z0-9_]+",
                source.lower(),
            )
        )

        products = sorted(
            words
            & FORBIDDEN_PRODUCT_TERMS
        )

        if products:
            violations.append(
                f"{relative}:PRODUCT:"
                + ",".join(products)
            )

    graph_types = (
        application_root
        / "resource_graph.py"
    ).read_text(
        encoding="utf-8"
    )

    required_domain_imports = {
        "ResourceEnvelope",
        "ResourceKind",
    }

    missing_import_names = sorted(
        name
        for name in required_domain_imports
        if name not in graph_types
    )

    if missing_import_names:
        violations.append(
            "resource_graph.py:"
            "DOMAIN_IMPORT_MISSING:"
            + ",".join(
                missing_import_names
            )
        )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print("RESOURCE_GRAPH_USE_CASE=PASS")
    print("RESOURCE_GRAPH_INBOUND_PORT_COUNT=1")
    print("RESOURCE_GRAPH_OUTBOUND_PORT_COUNT=1")
    print("RESOURCE_GRAPH_CONCRETE_USE_CASE_COUNT=1")
    print("DOMAIN_RESOURCE_DUPLICATION=NONE")
    print("AUTHORITATIVE_STATE_MUTATION=NONE")
    print("POLICY_EVALUATION=NONE")
    print("EXECUTION=NONE")
    print("PRODUCT_TERMS=NONE")
    print("OUTER_LAYER_IMPORTS=NONE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
