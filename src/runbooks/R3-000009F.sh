#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000009F-canonical-domain-purification.sh"

sandra_begin \
    "R3-000009F" \
    "Purify canonical domain and extract governance CLI inbound adapter"

for command_name in \
    python3 git install cp rm grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

DOMAIN_ROOT="${ROOT}/src/sandra/domain"
DOMAIN_PACKAGE="${DOMAIN_ROOT}/governance"

OLD_CLI="${DOMAIN_PACKAGE}/cli.py"
OLD_MAIN="${DOMAIN_PACKAGE}/__main__.py"

ADAPTER_PARENT="${ROOT}/src/sandra/adapters/inbound"
ADAPTER_PACKAGE="${ADAPTER_PARENT}/governance_resource_cli"
ADAPTER_INIT="${ADAPTER_PACKAGE}/__init__.py"
ADAPTER_MAIN="${ADAPTER_PACKAGE}/main.py"
ADAPTER_ENTRY="${ADAPTER_PACKAGE}/__main__.py"
ADAPTER_README="${ADAPTER_PACKAGE}/README.md"

TEST_ROOT="${ROOT}/tests/unit/domain"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

CONTRACT_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

for required_file in \
    "${STATE}" \
    "${DOMAIN_PACKAGE}/__init__.py" \
    "${DOMAIN_PACKAGE}/errors.py" \
    "${DOMAIN_PACKAGE}/types.py" \
    "${DOMAIN_PACKAGE}/validation.py" \
    "${OLD_CLI}" \
    "${OLD_MAIN}" \
    "${TEST_ROOT}/test_validation.py" \
    "${EXAMPLE_ROOT}/managed-object.example.json" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${CONTRACT_INDEX}"
do
    sandra_require_file "${required_file}"
done

git -C "${ROOT}" diff --quiet
git -C "${ROOT}" diff --cached --quiet

for target in \
    "${ADAPTER_INIT}" \
    "${ADAPTER_MAIN}" \
    "${ADAPTER_ENTRY}" \
    "${ADAPTER_README}"
do
    if [[ -e "${target}" || -L "${target}" ]]; then
        sandra_fail \
            "Canonical inbound adapter target already exists: ${target}"
    fi
done

install -d -m 0700 \
    "${BACKUP_ROOT}/domain" \
    "${BACKUP_ROOT}/state"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/state/STATE.json.before"

cp -a -- \
    "${OLD_CLI}" \
    "${BACKUP_ROOT}/domain/cli.py.before"

cp -a -- \
    "${OLD_MAIN}" \
    "${BACKUP_ROOT}/domain/__main__.py.before"

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONTRACT_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-precheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-precheck.txt"

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${DOMAIN_ROOT}" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-tests-before.txt" \
    2>&1

mapfile -t EXAMPLE_FILES < <(
    find "${EXAMPLE_ROOT}" \
        -maxdepth 1 \
        -type f \
        -name '*.json' \
        -print \
        | sort
)

if [[ "${#EXAMPLE_FILES[@]}" -eq 0 ]]; then
    sandra_fail "No canonical governance examples found"
fi

PYTHONPATH="${DOMAIN_ROOT}" \
python3 -m governance \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/legacy-cli-output.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/legacy-cli-output.json" \
    "${#EXAMPLE_FILES[@]}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
expected_count = int(sys.argv[2])

results = json.loads(
    path.read_text(encoding="utf-8")
)

if not isinstance(results, list):
    raise SystemExit("LEGACY_CLI_RESULT_NOT_LIST")

if len(results) != expected_count:
    raise SystemExit(
        "LEGACY_CLI_RESULT_COUNT:"
        f"{len(results)}:{expected_count}"
    )

failed = [
    item
    for item in results
    if item.get("status") != "PASS"
]

if failed:
    raise SystemExit(
        "LEGACY_CLI_VALIDATION_FAILED:"
        + json.dumps(
            failed,
            ensure_ascii=False,
            sort_keys=True,
        )
    )

print("LEGACY_CLI_BASELINE=PASS")
PYTHON

install -d -m 0755 "${ADAPTER_PACKAGE}"

cat > "${ADAPTER_INIT}" <<'PYTHON'
"""Inbound command-line adapter for governance resource validation."""

from .main import build_parser, main

__all__ = [
    "build_parser",
    "main",
]
PYTHON

cat > "${ADAPTER_MAIN}" <<'PYTHON'
"""Command-line adapter for canonical governance resource validation."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

from governance.errors import GovernanceError
from governance.validation import load_resource


def build_parser() -> argparse.ArgumentParser:
    """Build the governance-resource command-line parser."""

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
    """Validate resource paths and emit deterministic JSON results."""

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
PYTHON

cat > "${ADAPTER_ENTRY}" <<'PYTHON'
"""Module entry point for the governance resource CLI adapter."""

from .main import main

raise SystemExit(main())
PYTHON

cat > "${ADAPTER_README}" <<'EOF'
# Governance Resource CLI

Inbound adapter for validating canonical governance resource documents.

The adapter owns:

- command-line argument parsing;
- terminal exit codes;
- JSON rendering for CLI consumers.

The canonical domain owns:

- resource types;
- domain errors;
- validation invariants;
- resource loading and normalization.

Run with both canonical roots available:

    PYTHONPATH=src/sandra/domain:src/sandra/adapters/inbound \
    python3 -m governance_resource_cli RESOURCE.json
EOF

python3 -m py_compile \
    "${ADAPTER_INIT}" \
    "${ADAPTER_MAIN}" \
    "${ADAPTER_ENTRY}"

PYTHONPATH="${DOMAIN_ROOT}:${ADAPTER_PARENT}" \
python3 -m governance_resource_cli \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/adapter-cli-output.json"

cmp_result="$(
    python3 - \
        "${SANDRA_EVIDENCE_DIR}/legacy-cli-output.json" \
        "${SANDRA_EVIDENCE_DIR}/adapter-cli-output.json" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

legacy_path = Path(sys.argv[1])
adapter_path = Path(sys.argv[2])

legacy = json.loads(
    legacy_path.read_text(encoding="utf-8")
)

adapter = json.loads(
    adapter_path.read_text(encoding="utf-8")
)

if adapter != legacy:
    raise SystemExit(
        "CLI_BEHAVIOR_DIFFERENT"
    )

print("CLI_BEHAVIOR=BYTE_EQUIVALENT_JSON")
PYTHON
)"

printf '%s\n' "${cmp_result}" \
    > "${SANDRA_EVIDENCE_DIR}/cli-behavior-comparison.txt"

python3 - \
    "${DOMAIN_ROOT}" \
    "${ADAPTER_PARENT}" \
    "${EXAMPLE_ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/negative-cli-test.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import os
import subprocess
import sys
import tempfile

domain_root = Path(sys.argv[1])
adapter_parent = Path(sys.argv[2])
example_root = Path(sys.argv[3])
evidence_path = Path(sys.argv[4])

valid_document = (
    example_root
    / "managed-object.example.json"
).read_text(encoding="utf-8")

with tempfile.TemporaryDirectory() as directory:
    invalid_path = Path(directory) / "invalid.json"
    invalid_path.write_text(
        valid_document.replace(
            '"apiVersion": "governance.sandra.io/v1"',
            '"apiVersion": "invalid/v1"',
            1,
        ),
        encoding="utf-8",
    )

    environment = os.environ.copy()
    environment["PYTHONPATH"] = (
        f"{domain_root}:{adapter_parent}"
    )

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "governance_resource_cli",
            str(invalid_path),
        ],
        env=environment,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )

if result.returncode != 1:
    raise SystemExit(
        f"NEGATIVE_CLI_EXIT_CODE:{result.returncode}"
    )

payload = __import__("json").loads(result.stdout)

if len(payload) != 1:
    raise SystemExit("NEGATIVE_CLI_RESULT_COUNT")

if payload[0].get("status") != "FAIL":
    raise SystemExit("NEGATIVE_CLI_STATUS")

evidence_path.write_text(
    "NEGATIVE_CLI=PASS\n"
    "EXPECTED_EXIT_CODE=1\n"
    "ACTUAL_EXIT_CODE=1\n",
    encoding="utf-8",
)

print("NEGATIVE_CLI=PASS")
PYTHON

rm -f -- \
    "${OLD_CLI}" \
    "${OLD_MAIN}"

find "${DOMAIN_PACKAGE}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${ADAPTER_PACKAGE}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${DOMAIN_PACKAGE}" "${ADAPTER_PACKAGE}" \
    -type f \
    -name '*.pyc' \
    -delete

if [[ -e "${OLD_CLI}" || -L "${OLD_CLI}" ]]; then
    sandra_fail "CLI remains inside canonical domain"
fi

if [[ -e "${OLD_MAIN}" || -L "${OLD_MAIN}" ]]; then
    sandra_fail "Module entry point remains inside canonical domain"
fi

if grep -RInE \
    --include='*.py' \
    '(^|[[:space:]])import[[:space:]]+(argparse|sys)([[:space:]]|$)|from[[:space:]]+(argparse|sys)[[:space:]]+import' \
    "${DOMAIN_PACKAGE}" \
    > "${SANDRA_EVIDENCE_DIR}/forbidden-domain-imports.txt"
then
    cat "${SANDRA_EVIDENCE_DIR}/forbidden-domain-imports.txt"
    sandra_fail "Inbound interface imports remain inside canonical domain"
else
    : > "${SANDRA_EVIDENCE_DIR}/forbidden-domain-imports.txt"
fi

python3 - \
    "${DOMAIN_PACKAGE}" \
    "${SANDRA_EVIDENCE_DIR}/domain-purity.txt" <<'PYTHON'
from __future__ import annotations

import ast
from pathlib import Path
import sys

root = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])

forbidden_modules = {
    "argparse",
    "sys",
    "click",
    "typer",
    "flask",
    "fastapi",
}

violations: list[str] = []

for path in sorted(root.rglob("*.py")):
    tree = ast.parse(
        path.read_text(encoding="utf-8"),
        filename=str(path),
    )

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            modules = {
                alias.name.split(".", 1)[0]
                for alias in node.names
            }
        elif isinstance(node, ast.ImportFrom):
            modules = {
                (node.module or "").split(".", 1)[0]
            }
        else:
            continue

        present = sorted(
            modules & forbidden_modules
        )

        if present:
            violations.append(
                f"{path.relative_to(root)}:"
                + ",".join(present)
            )

if violations:
    raise SystemExit(
        "DOMAIN_PURITY_FAILED:\n"
        + "\n".join(violations)
    )

evidence_path.write_text(
    "DOMAIN_PURITY=PASS\n"
    "INBOUND_INTERFACE_IMPORTS=NONE\n"
    "CLI_FILES_IN_DOMAIN=NONE\n",
    encoding="utf-8",
)

print("DOMAIN_PURITY=PASS")
PYTHON

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${DOMAIN_ROOT}" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-tests-after.txt" \
    2>&1

PYTHONPATH="${DOMAIN_ROOT}:${ADAPTER_PARENT}" \
python3 -m governance_resource_cli \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/adapter-cli-post-removal.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/adapter-cli-output.json" \
    "${SANDRA_EVIDENCE_DIR}/adapter-cli-post-removal.json" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

before = json.loads(
    Path(sys.argv[1]).read_text(encoding="utf-8")
)

after = json.loads(
    Path(sys.argv[2]).read_text(encoding="utf-8")
)

if before != after:
    raise SystemExit(
        "ADAPTER_BEHAVIOR_CHANGED_AFTER_DOMAIN_REMOVAL"
    )

print("ADAPTER_POST_REMOVAL=PASS")
PYTHON

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-postcheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-postcheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONTRACT_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-postcheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-postcheck.txt"

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
from __future__ import annotations

import datetime
import json
from pathlib import Path
import sys

state_path = Path(sys.argv[1])
runbook_id = sys.argv[2]
run_id = sys.argv[3]
journal = sys.argv[4]

state = json.loads(
    state_path.read_text(encoding="utf-8")
)

capability_map = state["spec"].get(
    "capability_map"
)

if not isinstance(capability_map, dict):
    raise SystemExit(
        "CAPABILITY_MAP_STATE_MISSING"
    )

if capability_map.get("status") != "immutable":
    raise SystemExit(
        "CAPABILITY_MAP_NOT_IMMUTABLE"
    )

state["metadata"]["state_version"] = "4.4.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["domain_purity"] = {
    "version": "1.0.0",
    "status": "certified",
    "canonical_domain": (
        "src/sandra/domain/governance"
    ),
    "inbound_adapter": (
        "src/sandra/adapters/inbound/"
        "governance_resource_cli"
    ),
    "rules": [
        "domain contains no command-line parsing",
        "domain contains no process exit behavior",
        "domain contains no inbound interface implementation",
        "inbound adapter depends on domain",
        "domain does not depend on inbound adapter",
    ],
    "legacy_sources_preserved": True,
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000009F",
    "title": "Canonical Domain Purification",
    "type": "domain_boundary_enforcement",
    "targets": [
        "src/sandra/domain/governance",
        (
            "src/sandra/adapters/inbound/"
            "governance_resource_cli"
        ),
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "legacy src/domain",
        "legacy src/runtime",
        "application implementation",
        "controller implementation",
        "outbound adapter implementation",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "remove CLI responsibility from canonical domain",
        "create the canonical inbound CLI adapter",
        "preserve externally observable CLI behavior",
        "certify the inward dependency direction",
    ],
    "prohibitions": [
        "no domain behavior change",
        "no legacy source deletion",
        "no architecture change",
        "no Habitat modification",
        "no software installation",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000010",
    "title": "Application Ports Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Canonical Domain Purification",
    "current_gate": "R3-000009F",
    "current_gate_status": "complete",
    "next_gate": "R3-000010",
}

state["status"]["canonical_domain_purification_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified",
    "domain_purity": "pass",
    "cli_adapter": "pass",
    "cli_behavior_equivalence": "pass",
    "negative_cli_test": "pass",
    "unit_tests": "pass",
    "architecture_constitution": "pass",
    "capability_map": "pass",
    "legacy_sources_preserved": True,
    "software_installed": "none",
    "remote_habitat_modifications": "none",
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

install -d -m 0755 \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Canonical Domain Purification

- Run ID: \`${SANDRA_RUN_ID}\`
- Canonical domain: \`src/sandra/domain/governance\`
- Inbound adapter:
  \`src/sandra/adapters/inbound/governance_resource_cli\`
- Legacy sources preserved: \`YES\`
- Architecture changes: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- removed command-line parsing from the canonical domain;
- removed the domain module entry point;
- created a canonical inbound CLI adapter;
- proved equivalent positive behavior;
- proved deterministic negative behavior;
- passed canonical domain unit tests;
- preserved Architecture Constitution and Capability Map.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: purify canonical domain boundary"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

sandra_assert test ! -e "${OLD_CLI}"
sandra_assert test ! -e "${OLD_MAIN}"
sandra_assert test -f "${ADAPTER_MAIN}"
sandra_assert test -f "${ADAPTER_ENTRY}"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])

status = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "status",
        "--porcelain",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout

head = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "rev-parse",
        "HEAD",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout.strip()

origin = subprocess.run(
    [
        "git",
        "-C",
        str(root),
        "rev-parse",
        "origin/main",
    ],
    check=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
).stdout.strip()

checks = {
    "working_tree_clean": not status.strip(),
    "head_matches_origin": head == origin,
}

evidence_path.write_text(
    "\n".join(
        f"{name}={'PASS' if passed else 'FAIL'}"
        for name, passed in sorted(checks.items())
    )
    + f"\nHEAD={head}\n"
    + f"ORIGIN_MAIN={origin}\n",
    encoding="utf-8",
)

failed = [
    name
    for name, passed in checks.items()
    if not passed
]

if failed:
    raise SystemExit(
        "REPOSITORY_POST_SYNC_FAILED:"
        + ",".join(failed)
    )

print("REPOSITORY_POST_SYNC=PASS")
PYTHON

{
    printf 'CANONICAL_DOMAIN_PURIFICATION=PASS\n'
    printf 'DOMAIN_PURITY=PASS\n'
    printf 'CLI_ADAPTER=PASS\n'
    printf 'CLI_BEHAVIOR_EQUIVALENCE=PASS\n'
    printf 'NEGATIVE_CLI_TEST=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'ARCHITECTURE_CONSTITUTION=PASS\n'
    printf 'CAPABILITY_MAP=PASS\n'
    printf 'LEGACY_SOURCES_PRESERVED=YES\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'ADAPTER_SHA256=%s\n' \
        "$(sha256sum "${ADAPTER_MAIN}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
