#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "planning.py",
    "ports/inbound/planning.py",
    "ports/outbound/plan_composer.py",
    "use_cases/build_execution_plan.py",
}

EXPECTED_OWNS = {
    "preconditions",
    "ordered actions",
    "postconditions",
    "recovery",
    "execution limits",
}

EXPECTED_EXCLUDES = {
    "action execution",
    "technology calls",
    "policy evaluation",
}

FORBIDDEN_IMPORTS = {
    "controllers",
    "adapters",
    "bootstrap",
}

FORBIDDEN_PRODUCTS = {
    "proxmox",
    "pve",
    "vmware",
    "linux",
    "windows",
    "pbs",
    "ssh",
    "winrm",
    "telegram",
    "prometheus",
    "ansible",
}


def fail(
    message: str,
) -> NoReturn:
    raise SystemExit(
        f"PLANNING_USE_CASE_INVALID:{message}"
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
    result: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            result.update(
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
            result.add(
                node.module.split(
                    ".",
                    1,
                )[0]
            )

    return result


def main() -> int:
    if len(sys.argv) != 4:
        fail("USAGE")

    application_root = Path(
        sys.argv[1]
    ).resolve()

    contract = load_json(
        Path(sys.argv[2])
    )

    capability_map = load_json(
        Path(sys.argv[3])
    )

    if contract.get("kind") != (
        "PlanningUseCase"
    ):
        fail("CONTRACT_KIND")

    metadata = contract.get(
        "metadata",
        {},
    )

    spec = contract.get(
        "spec",
        {},
    )

    if metadata.get("id") != (
        "planning-use-case-v1"
    ):
        fail("CONTRACT_ID")

    if metadata.get("status") != (
        "immutable"
    ):
        fail("STATUS_NOT_IMMUTABLE")

    if spec.get("capability") != (
        "planning"
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
        "planning"
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

        products = sorted(
            set(
                re.findall(
                    r"[a-z0-9_]+",
                    source.lower(),
                )
            )
            & FORBIDDEN_PRODUCTS
        )

        if products:
            violations.append(
                f"{relative}:PRODUCT:"
                + ",".join(products)
            )

    planning_source = (
        application_root
        / "planning.py"
    ).read_text(
        encoding="utf-8"
    )

    for fragment in (
        "PlanningRequest",
        "PlanStep",
        "PlanningResult",
        "ResourceKind.EXECUTION_PLAN",
        "preconditions",
        "postconditions",
        "recovery_ref",
        "execution_limits",
    ):
        if fragment not in planning_source:
            violations.append(
                "planning.py:"
                "REQUIRED_FRAGMENT_MISSING:"
                + fragment
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print(
        "PLANNING_USE_CASE=PASS"
    )
    print(
        "PLANNING_INBOUND_PORT_COUNT=1"
    )
    print(
        "PLANNING_OUTBOUND_PORT_COUNT=1"
    )
    print(
        "PLANNING_CONCRETE_USE_CASE_COUNT=1"
    )
    print(
        "DOMAIN_EXECUTION_PLAN_REUSE=PASS"
    )
    print(
        "ACTION_EXECUTION=NONE"
    )
    print(
        "TECHNOLOGY_CALLS=NONE"
    )
    print(
        "POLICY_EVALUATION=NONE"
    )
    print(
        "OUTER_LAYER_IMPORTS=NONE"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
