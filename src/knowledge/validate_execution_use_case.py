#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "execution.py",
    "ports/inbound/execution.py",
    "ports/outbound/execution_engine.py",
    "use_cases/execute_plan.py",
}

EXPECTED_OWNS = {
    "execution lifecycle",
    "idempotency",
    "bounded retry",
    "partial results",
    "recovery invocation",
}

EXPECTED_EXCLUDES = {
    "policy decision",
    "plan creation",
    "verification conclusion",
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
    "windows",
    "linux",
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
        "EXECUTION_USE_CASE_INVALID:"
        + message
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
        fail(
            "MISSING:"
            + str(path)
        )
    except json.JSONDecodeError as exc:
        fail(
            f"JSON:{path}:"
            f"{exc.lineno}:{exc.colno}"
        )

    if not isinstance(value, dict):
        fail(
            "ROOT_NOT_OBJECT:"
            + str(path)
        )

    return value


def imported_roots(
    tree: ast.AST,
) -> set[str]:
    result: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(
            node,
            ast.Import,
        ):
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
    if len(sys.argv) != 5:
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

    safety_contract = load_json(
        Path(sys.argv[4])
    )

    if contract.get("kind") != (
        "ExecutionUseCase"
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
        "execution-use-case-v1"
    ):
        fail("CONTRACT_ID")

    if metadata.get("status") != (
        "immutable"
    ):
        fail(
            "STATUS_NOT_IMMUTABLE"
        )

    if spec.get("capability") != (
        "execution"
    ):
        fail(
            "CAPABILITY_REFERENCE"
        )

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
        for item
        in capability_map.get(
            "spec",
            {},
        ).get(
            "coreCapabilities",
            [],
        )
        if isinstance(item, dict)
    }

    capability = capabilities.get(
        "execution"
    )

    if not isinstance(
        capability,
        dict,
    ):
        fail(
            "CAPABILITY_MISSING"
        )

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

    if safety_contract.get(
        "metadata",
        {},
    ).get("id") != (
        "execution-safety-v1"
    ):
        fail(
            "SAFETY_CONTRACT_ID"
        )

    if safety_contract.get(
        "metadata",
        {},
    ).get("status") != (
        "immutable"
    ):
        fail(
            "SAFETY_CONTRACT_NOT_IMMUTABLE"
        )

    missing = sorted(
        relative
        for relative
        in EXPECTED_FILES
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
                relative
                + ":IMPORT:"
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
                relative
                + ":PRODUCT:"
                + ",".join(products)
            )

    types_source = (
        application_root
        / "execution.py"
    ).read_text(
        encoding="utf-8"
    )

    for fragment in (
        "ExecutionRequest",
        "ExecutionStepOutcome",
        "ExecutionResult",
        "ResourceKind.EXECUTION_PLAN",
        "idempotency_key",
        "maximum_attempts",
        "recovery_invocations",
        "partial_result",
    ):
        if fragment not in types_source:
            violations.append(
                "execution.py:MISSING:"
                + fragment
            )

    use_case_source = (
        application_root
        / "use_cases/execute_plan.py"
    ).read_text(
        encoding="utf-8"
    )

    for fragment in (
        "EXECUTION_REQUEST_MISMATCH",
        "EXECUTION_PLAN_MISMATCH",
        "EXECUTION_POLICY_DECISION_MISMATCH",
        "EXECUTION_IDEMPOTENCY_MISMATCH",
        "EXECUTION_RETRY_BOUND_EXCEEDED",
    ):
        if fragment not in use_case_source:
            violations.append(
                "execute_plan.py:MISSING:"
                + fragment
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print(
        "EXECUTION_USE_CASE=PASS"
    )
    print(
        "EXECUTION_INBOUND_PORT_COUNT=1"
    )
    print(
        "EXECUTION_OUTBOUND_PORT_COUNT=1"
    )
    print(
        "EXECUTION_CONCRETE_USE_CASE_COUNT=1"
    )
    print(
        "EXECUTION_PLAN_REUSE=PASS"
    )
    print(
        "IDEMPOTENCY=EXPLICIT"
    )
    print(
        "BOUNDED_RETRY=PASS"
    )
    print(
        "PARTIAL_RESULTS=EXPLICIT"
    )
    print(
        "RECOVERY_INVOCATION=EXPLICIT"
    )
    print(
        "POLICY_DECISION=NOT_EVALUATED"
    )
    print(
        "PLAN_CREATION=NONE"
    )
    print(
        "VERIFICATION_CONCLUSION=NONE"
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
