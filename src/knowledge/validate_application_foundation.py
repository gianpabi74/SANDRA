#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_FILES = {
    "__init__.py",
    "errors.py",
    "messages.py",
    "result.py",
    "ports/__init__.py",
    "ports/inbound/__init__.py",
    "ports/inbound/command.py",
    "ports/inbound/query.py",
    "ports/outbound/__init__.py",
    "ports/outbound/repository.py",
    "ports/outbound/event_bus.py",
    "ports/outbound/unit_of_work.py",
    "use_cases/__init__.py",
    "use_cases/contract.py",
    "observation.py",
    "ports/inbound/observation.py",
    "ports/outbound/observation_source.py",
    "use_cases/observe_subject.py",
    "evidence.py",
    "ports/inbound/evidence_qualification.py",
    "ports/outbound/evidence_qualifier.py",
    "use_cases/qualify_evidence.py",
    "resource_graph.py",
    "ports/inbound/resource_graph.py",
    "ports/outbound/resource_graph_reader.py",
    "use_cases/query_resource_graph.py",
    "desired_state.py",
    "ports/inbound/desired_state.py",
    "ports/outbound/desired_state_repository.py",
    "use_cases/declare_desired_state.py",
    "policy_decision.py",
    "ports/inbound/policy_decision.py",
    "ports/outbound/policy_decision_evaluator.py",
    "use_cases/evaluate_policy_decision.py",
    "planning.py",
    "ports/inbound/planning.py",
    "ports/outbound/plan_composer.py",
    "use_cases/build_execution_plan.py",
    "execution.py",
    "ports/inbound/execution.py",
    "ports/outbound/execution_engine.py",
    "use_cases/execute_plan.py",
}

FORBIDDEN_IMPORT_ROOTS = {
    "controllers",
    "adapters",
    "bootstrap",
}

FORBIDDEN_WORDS = {
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
        f"APPLICATION_FOUNDATION_INVALID:{message}"
    )


def load_json(path: Path) -> dict[str, Any]:
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


def imported_roots(tree: ast.AST) -> set[str]:
    roots: set[str] = set()

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            roots.update(
                alias.name.split(".", 1)[0]
                for alias in node.names
            )
        elif isinstance(node, ast.ImportFrom):
            if node.module:
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

    if contract.get("kind") != (
        "ApplicationPortsFoundation"
    ):
        fail("CONTRACT_KIND")

    if (
        contract.get("metadata", {}).get("id")
        != "application-ports-foundation-v1"
    ):
        fail("CONTRACT_ID")

    if (
        contract.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("CONTRACT_STATUS")

    if (
        capability.get("metadata", {}).get("id")
        != "canonical-capability-map-v1"
    ):
        fail("CAPABILITY_MAP_ID")

    if (
        capability.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("CAPABILITY_MAP_STATUS")

    actual_files = {
        path.relative_to(application_root).as_posix()
        for path in application_root.rglob("*.py")
        if "__pycache__" not in path.parts
    }

    if actual_files != EXPECTED_FILES:
        missing = sorted(
            EXPECTED_FILES - actual_files
        )
        unexpected = sorted(
            actual_files - EXPECTED_FILES
        )

        fail(
            "FILE_SET:"
            f"MISSING={missing}:"
            f"UNEXPECTED={unexpected}"
        )

    violations: list[str] = []

    for path in sorted(
        application_root.rglob("*.py")
    ):
        if "__pycache__" in path.parts:
            continue

        source = path.read_text(
            encoding="utf-8"
        )

        tree = ast.parse(
            source,
            filename=str(path),
        )

        forbidden_imports = sorted(
            imported_roots(tree)
            & FORBIDDEN_IMPORT_ROOTS
        )

        if forbidden_imports:
            violations.append(
                f"{path.name}:IMPORT:"
                + ",".join(forbidden_imports)
            )

        words = set(
            re.findall(
                r"[a-z0-9_]+",
                source.lower(),
            )
        )

        forbidden_words = sorted(
            words & FORBIDDEN_WORDS
        )

        if forbidden_words:
            violations.append(
                f"{path.name}:PRODUCT:"
                + ",".join(forbidden_words)
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print("APPLICATION_PORTS_FOUNDATION=PASS")
    print("APPLICATION_PYTHON_FILE_COUNT=42")
    print("INBOUND_PORT_COUNT=9")
    print("OUTBOUND_PORT_COUNT=10")
    print("CONCRETE_USE_CASE_COUNT=7")
    print("PRODUCT_TERMS=NONE")
    print("OUTER_LAYER_IMPORTS=NONE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
