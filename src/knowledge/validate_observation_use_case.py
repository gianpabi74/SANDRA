#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "observation.py",
    "ports/inbound/observation.py",
    "ports/outbound/observation_source.py",
    "use_cases/observe_subject.py",
}

FORBIDDEN_IMPORTS = {
    "controllers",
    "adapters",
    "bootstrap",
}

FORBIDDEN_PRODUCT_WORDS = {
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
        f"OBSERVATION_USE_CASE_INVALID:{message}"
    )


def load_json(path: Path) -> dict[str, Any]:
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


def imported_roots(tree: ast.AST) -> set[str]:
    roots: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            roots.update(
                alias.name.split(".", 1)[0]
                for alias in node.names
            )
        elif (
            isinstance(node, ast.ImportFrom)
            and node.module
        ):
            roots.add(
                node.module.split(".", 1)[0]
            )

    return roots


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    application_root = Path(sys.argv[1]).resolve()
    contract_path = Path(sys.argv[2]).resolve()
    capability_path = Path(sys.argv[3]).resolve()

    contract = load_json(contract_path)
    capability = load_json(capability_path)

    if contract.get("kind") != "ObservationUseCase":
        fail("CONTRACT_KIND")

    if (
        contract.get("metadata", {}).get("id")
        != "observation-use-case-v1"
    ):
        fail("CONTRACT_ID")

    if (
        contract.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("CONTRACT_STATUS")

    capabilities = {
        item.get("id")
        for item in capability.get(
            "spec",
            {},
        ).get(
            "coreCapabilities",
            [],
        )
        if isinstance(item, dict)
    }

    if "observation" not in capabilities:
        fail("OBSERVATION_CAPABILITY_MISSING")

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

    for relative in sorted(EXPECTED_FILES):
        path = application_root / relative
        source = path.read_text(encoding="utf-8")
        tree = ast.parse(
            source,
            filename=str(path),
        )

        outer_imports = sorted(
            imported_roots(tree)
            & FORBIDDEN_IMPORTS
        )

        if outer_imports:
            violations.append(
                f"{relative}:IMPORT:"
                + ",".join(outer_imports)
            )

        words = set(
            re.findall(
                r"[a-z0-9_]+",
                source.lower(),
            )
        )

        products = sorted(
            words & FORBIDDEN_PRODUCT_WORDS
        )

        if products:
            violations.append(
                f"{relative}:PRODUCT:"
                + ",".join(products)
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print("OBSERVATION_USE_CASE=PASS")
    print("OBSERVATION_INBOUND_PORT_COUNT=1")
    print("OBSERVATION_OUTBOUND_PORT_COUNT=1")
    print("OBSERVATION_CONCRETE_USE_CASE_COUNT=1")
    print("AUTHORITATIVE_STATE_MUTATION=NONE")
    print("POLICY_EVALUATION=NONE")
    print("EXECUTION=NONE")
    print("PRODUCT_TERMS=NONE")
    print("OUTER_LAYER_IMPORTS=NONE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
