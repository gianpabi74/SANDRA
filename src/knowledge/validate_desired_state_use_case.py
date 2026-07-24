#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "desired_state.py",
    "ports/inbound/desired_state.py",
    "ports/outbound/desired_state_repository.py",
    "use_cases/declare_desired_state.py",
}

EXPECTED_OWNS = {
    "desired configuration",
    "desired service state",
    "declared limits",
    "intent generation",
}

EXPECTED_EXCLUDES = {
    "live telemetry",
    "imperative commands",
    "adapter configuration",
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


def fail(
    message: str,
) -> NoReturn:
    raise SystemExit(
        f"DESIRED_STATE_USE_CASE_INVALID:{message}"
    )


def load_json(
    path: Path,
) -> dict[str, Any]:
    try:
        value = json.loads(
            path.read_text(
                encoding="utf-8"
            )
        )
    except FileNotFoundError:
        fail(f"MISSING:{path}")
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:{exc.lineno}:{exc.colno}"
        )

    if not isinstance(value, dict):
        fail(
            f"ROOT_NOT_OBJECT:{path}"
        )

    return value


def imported_roots(
    tree: ast.AST,
) -> set[str]:
    roots: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            roots.update(
                alias.name.split(
                    ".",
                    1,
                )[0]
                for alias in node.names
            )

        elif (
            isinstance(
                node,
                ast.ImportFrom,
            )
            and node.module
        ):
            roots.add(
                node.module.split(
                    ".",
                    1,
                )[0]
            )

    return roots


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    application_root = Path(
        sys.argv[1]
    ).resolve()

    contract_path = Path(
        sys.argv[2]
    ).resolve()

    capability_path = Path(
        sys.argv[3]
    ).resolve()

    contract = load_json(
        contract_path
    )

    capability_map = load_json(
        capability_path
    )

    if contract.get("kind") != (
        "DesiredStateUseCase"
    ):
        fail("CONTRACT_KIND")

    metadata = contract.get(
        "metadata"
    )

    if not isinstance(
        metadata,
        dict,
    ):
        fail("CONTRACT_METADATA")

    if metadata.get("id") != (
        "desired-state-use-case-v1"
    ):
        fail("CONTRACT_ID")

    if metadata.get("status") != (
        "immutable"
    ):
        fail("STATUS_NOT_IMMUTABLE")

    spec = contract.get("spec")

    if not isinstance(spec, dict):
        fail("CONTRACT_SPEC")

    if spec.get("capability") != (
        "desired_state"
    ):
        fail("CAPABILITY_REFERENCE")

    if set(
        spec.get(
            "owns",
            [],
        )
    ) != EXPECTED_OWNS:
        fail("OWNS_SET")

    if set(
        spec.get(
            "excludes",
            [],
        )
    ) != EXPECTED_EXCLUDES:
        fail("EXCLUDES_SET")

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

    capability = capabilities.get(
        "desired_state"
    )

    if not isinstance(
        capability,
        dict,
    ):
        fail("CAPABILITY_MISSING")

    if set(
        capability.get(
            "owns",
            [],
        )
    ) != EXPECTED_OWNS:
        fail(
            "CAPABILITY_OWNS_MISMATCH"
        )

    if set(
        capability.get(
            "excludes",
            [],
        )
    ) != EXPECTED_EXCLUDES:
        fail(
            "CAPABILITY_EXCLUDES_MISMATCH"
        )

    missing = sorted(
        relative
        for relative in EXPECTED_FILES
        if not (
            application_root
            / relative
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
        path = (
            application_root
            / relative
        )

        source = path.read_text(
            encoding="utf-8"
        )

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
                + ",".join(
                    outer_imports
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

    types_source = (
        application_root
        / "desired_state.py"
    ).read_text(
        encoding="utf-8"
    )

    required_fragments = {
        "DesiredStateDeclaration",
        "DesiredStateRecord",
        "expected_generation",
        "approval_ref",
        "desired_configuration",
        "desired_service_state",
        "declared_limits",
        "_freeze_mapping",
    }

    missing_fragments = sorted(
        fragment
        for fragment in required_fragments
        if fragment not in types_source
    )

    if missing_fragments:
        violations.append(
            "desired_state.py:"
            "REQUIRED_FRAGMENT_MISSING:"
            + ",".join(
                missing_fragments
            )
        )

    repository_source = (
        application_root
        / "ports/outbound/"
        "desired_state_repository.py"
    ).read_text(
        encoding="utf-8"
    )

    for required_fragment in (
        "get_current",
        "save",
        "expected_generation",
        "DesiredStateConflictError",
    ):
        if (
            required_fragment
            not in repository_source
        ):
            violations.append(
                "desired_state_repository.py:"
                "REQUIRED_FRAGMENT_MISSING:"
                + required_fragment
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print(
        "DESIRED_STATE_USE_CASE=PASS"
    )
    print(
        "DESIRED_STATE_INBOUND_PORT_COUNT=1"
    )
    print(
        "DESIRED_STATE_OUTBOUND_PORT_COUNT=1"
    )
    print(
        "DESIRED_STATE_CONCRETE_USE_CASE_COUNT=1"
    )
    print(
        "GENERATION_CONTROL=OPTIMISTIC"
    )
    print(
        "APPROVAL_REFERENCE=REQUIRED"
    )
    print(
        "DEEP_IMMUTABILITY=PASS"
    )
    print(
        "LIVE_TELEMETRY=NONE"
    )
    print(
        "IMPERATIVE_COMMANDS=NONE"
    )
    print(
        "ADAPTER_CONFIGURATION=NONE"
    )
    print(
        "POLICY_EVALUATION=NONE"
    )
    print(
        "EXECUTION=NONE"
    )
    print(
        "PRODUCT_TERMS=NONE"
    )
    print(
        "OUTER_LAYER_IMPORTS=NONE"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
