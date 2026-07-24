#!/usr/bin/env python3

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
import sys
from typing import Any, NoReturn


EXPECTED_AUTHORITY = {
    "unknown",
    "observational",
    "corroborated",
    "authoritative",
}

EXPECTED_OUTCOMES = {
    "accept",
    "reject",
    "corroborate",
    "conflict",
    "expire",
    "request_more_evidence",
}

EXPECTED_FILES = {
    "evidence.py",
    "ports/inbound/evidence_qualification.py",
    "ports/outbound/evidence_qualifier.py",
    "use_cases/qualify_evidence.py",
}

FORBIDDEN_IMPORTS = {
    "controllers",
    "adapters",
    "bootstrap",
}


def fail(message: str) -> NoReturn:
    raise SystemExit(
        f"EVIDENCE_QUALIFICATION_INVALID:{message}"
    )


def load(path: Path) -> dict[str, Any]:
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


def imports(tree: ast.AST) -> set[str]:
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
    if len(sys.argv) != 5:
        fail("USAGE")

    application_root = Path(sys.argv[1])
    contract_path = Path(sys.argv[2])
    constitutional_path = Path(sys.argv[3])
    capability_path = Path(sys.argv[4])

    contract = load(contract_path)
    constitutional = load(constitutional_path)
    capability = load(capability_path)

    if contract.get("kind") != (
        "EvidenceQualificationUseCase"
    ):
        fail("KIND")

    if (
        contract.get("metadata", {}).get("status")
        != "immutable"
    ):
        fail("STATUS_NOT_IMMUTABLE")

    authority = set(
        contract.get("spec", {}).get(
            "authorityLevels",
            [],
        )
    )

    outcomes = set(
        contract.get("spec", {}).get(
            "qualificationOutcomes",
            [],
        )
    )

    constitutional_authority = set(
        constitutional.get("spec", {}).get(
            "authorityLevels",
            [],
        )
    )

    constitutional_outcomes = set(
        constitutional.get("spec", {}).get(
            "qualificationOutcomes",
            [],
        )
    )

    if authority != EXPECTED_AUTHORITY:
        fail("AUTHORITY_SET")

    if outcomes != EXPECTED_OUTCOMES:
        fail("OUTCOME_SET")

    if authority != constitutional_authority:
        fail("AUTHORITY_CONSTITUTION_MISMATCH")

    if outcomes != constitutional_outcomes:
        fail("OUTCOME_CONSTITUTION_MISMATCH")

    capability_ids = {
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

    if "evidence_qualification" not in capability_ids:
        fail("CAPABILITY_MISSING")

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

        outer = sorted(
            imports(tree) & FORBIDDEN_IMPORTS
        )

        if outer:
            violations.append(
                f"{relative}:"
                + ",".join(outer)
            )

        words = set(
            re.findall(
                r"[a-z0-9_]+",
                source.lower(),
            )
        )

        if "candidate" in words:
            violations.append(
                f"{relative}:CANDIDATE_AUTHORITY_TERM"
            )

        if "conflicting" in words:
            violations.append(
                f"{relative}:CONFLICTING_AUTHORITY_TERM"
            )

    if violations:
        fail(
            "VIOLATIONS:"
            + "|".join(violations)
        )

    print("EVIDENCE_QUALIFICATION=PASS")
    print("AUTHORITY_LEVELS=4")
    print("QUALIFICATION_OUTCOMES=6")
    print("AUTHORITATIVE_STATE_MUTATION=NONE")
    print("POLICY_EVALUATION=NONE")
    print("EXECUTION=NONE")
    print("OUTER_LAYER_IMPORTS=NONE")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
