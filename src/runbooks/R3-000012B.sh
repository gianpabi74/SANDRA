#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000012B-evidence-qualification-publication.sh"

sandra_begin \
    "R3-000012B" \
    "Validate and publish Evidence Qualification Use Case Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
TEST_ROOT="${ROOT}/tests/contract/application"
DOMAIN_TEST_ROOT="${ROOT}/tests/unit/domain"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

FOUNDATION_CONTRACT="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
FOUNDATION_VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"

QUALIFICATION_CONTRACT="${ROOT}/docs/contracts/application/EVIDENCE-QUALIFICATION-USE-CASE-V1.json"
QUALIFICATION_VALIDATOR="${ROOT}/src/knowledge/validate_evidence_qualification.py"
QUALIFICATION_ADR="${ROOT}/docs/adr/ADR-0012-EVIDENCE-QUALIFICATION-USE-CASE.md"

EVIDENCE_CONTRACT="${ROOT}/docs/contracts/constitutional/EVIDENCE-AUTHORITY-CONTRACT-V1.json"
CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

OBSERVATION_CONTRACT="${ROOT}/docs/contracts/application/OBSERVATION-USE-CASE-V1.json"
OBSERVATION_VALIDATOR="${ROOT}/src/knowledge/validate_observation_use_case.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"
MANIFEST="${SANDRA_RUN_DIR}/candidate-manifest.json"

for required_file in \
    "${STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${QUALIFICATION_CONTRACT}" \
    "${QUALIFICATION_VALIDATOR}" \
    "${QUALIFICATION_ADR}" \
    "${EVIDENCE_CONTRACT}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${OBSERVATION_CONTRACT}" \
    "${OBSERVATION_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

cat > "${MANIFEST}" <<'JSON'
{
  "sourceGate": "R3-000012A",
  "baseHead": "6318ad3a1a6f5a66a5ed14e2565298f43a687d72",
  "files": [
    {
      "category": "modified",
      "path": "src/domain/governance/types.py",
      "sha256": "22c40c98ac630820b3d3bc9a6bc2c9564d28d25a4bc8b05e46665b6b32b82c7f"
    },
    {
      "category": "modified",
      "path": "src/runtime/governance/types.py",
      "sha256": "22c40c98ac630820b3d3bc9a6bc2c9564d28d25a4bc8b05e46665b6b32b82c7f"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/__init__.py",
      "sha256": "2820fca17b4d469b44437c1f62b34ab1c0ee76f46fcf2e98a02af3b5f1222108"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/inbound/__init__.py",
      "sha256": "787cc4d1a4a474d44ce21b9a704176b965337cdcaf4ed527cfecf47431f6ee18"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/outbound/__init__.py",
      "sha256": "20414e73d21a694cbdc271371128f937a2e08a607e385eb0ae7fe169d13a11e8"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/use_cases/__init__.py",
      "sha256": "3fd0ee08aedd6b2096c8d18f0d0710dcbe3e7b6205da0178d15c97d456ef809f"
    },
    {
      "category": "modified",
      "path": "src/sandra/domain/governance/types.py",
      "sha256": "22c40c98ac630820b3d3bc9a6bc2c9564d28d25a4bc8b05e46665b6b32b82c7f"
    },
    {
      "category": "untracked",
      "path": "docs/adr/ADR-0012-EVIDENCE-QUALIFICATION-USE-CASE.md",
      "sha256": "993d1c740825dc5df8c21bc214117b3fe1d6e5b0d946b556b064a6dad6329969"
    },
    {
      "category": "untracked",
      "path": "docs/contracts/application/EVIDENCE-QUALIFICATION-USE-CASE-V1.json",
      "sha256": "2b8fb788c0b835fda13a2428c2616a2f2134793e1d44e0a1bfd1225f9c2c8cd2"
    },
    {
      "category": "untracked",
      "path": "src/knowledge/validate_evidence_qualification.py",
      "sha256": "bafbf6577aeb4d773f0d3fe0af13bce3551a66308d58befad2e48eda07532b57"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/evidence.py",
      "sha256": "6675a7b8a598c2c0b562205a024a0fb9917d6d2e564ee417e46c33802b3e8e33"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/inbound/evidence_qualification.py",
      "sha256": "8b31fb00862a3c13f3c4e3c8b90703b5b92aacd6bc06eb758b27d9285522f4a1"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/outbound/evidence_qualifier.py",
      "sha256": "cf740252f1fa6d5e94ad2c0724b45d4cef100cea32c1e4f582425af58b9ffd4f"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/use_cases/qualify_evidence.py",
      "sha256": "49256d8bab9c4dea497ae4ee4b5baf2c401b6a8a55680bfc888a252297bde90a"
    },
    {
      "category": "untracked",
      "path": "tests/contract/application/test_evidence_qualification.py",
      "sha256": "002c927d0209b7915ca0c0d20f52d4ae95c32b7283d86dc4df074767b920277e"
    }
  ]
}
JSON

python3 - \
    "${ROOT}" \
    "${MANIFEST}" \
    "${SANDRA_EVIDENCE_DIR}/candidate-preflight.txt" <<'PYTHON'
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
manifest_path = Path(sys.argv[2])
evidence_path = Path(sys.argv[3])

manifest = json.loads(
    manifest_path.read_text(encoding="utf-8")
)


def run_git(*arguments: str) -> str:
    return subprocess.run(
        [
            "git",
            "-C",
            str(root),
            *arguments,
        ],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout


def path_set(*arguments: str) -> set[str]:
    return {
        line.strip()
        for line in run_git(*arguments).splitlines()
        if line.strip()
    }


def sha256(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(
            lambda: handle.read(1024 * 1024),
            b"",
        ):
            digest.update(chunk)

    return digest.hexdigest()


expected_modified = {
    item["path"]
    for item in manifest["files"]
    if item["category"] == "modified"
}

expected_untracked = {
    item["path"]
    for item in manifest["files"]
    if item["category"] == "untracked"
}

actual_modified = path_set(
    "diff",
    "--name-only",
)

actual_untracked = path_set(
    "ls-files",
    "--others",
    "--exclude-standard",
)

actual_staged = path_set(
    "diff",
    "--cached",
    "--name-only",
)

head = run_git(
    "rev-parse",
    "HEAD",
).strip()

origin = run_git(
    "rev-parse",
    "origin/main",
).strip()

checks = {
    "base_head_matches_export": (
        head == manifest["baseHead"]
    ),
    "head_matches_origin": (
        head == origin
    ),
    "modified_set_matches_export": (
        actual_modified == expected_modified
    ),
    "untracked_set_matches_export": (
        actual_untracked == expected_untracked
    ),
    "staged_changes_absent": (
        not actual_staged
    ),
}

hash_failures: list[str] = []

for record in manifest["files"]:
    relative = record["path"]
    path = root / relative

    if not path.is_file():
        hash_failures.append(
            f"MISSING:{relative}"
        )
        continue

    actual_hash = sha256(path)

    if actual_hash != record["sha256"]:
        hash_failures.append(
            f"HASH:{relative}:{actual_hash}"
        )

checks["all_candidate_hashes_match_export"] = (
    not hash_failures
)

lines = [
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(checks.items())
]

lines.extend(
    f"ERROR={value}"
    for value in hash_failures
)

lines.extend(
    [
        f"HEAD={head}",
        f"ORIGIN_MAIN={origin}",
        f"MODIFIED_COUNT={len(actual_modified)}",
        f"UNTRACKED_COUNT={len(actual_untracked)}",
        f"STAGED_COUNT={len(actual_staged)}",
    ]
)

evidence_path.write_text(
    "\n".join(lines) + "\n",
    encoding="utf-8",
)

failed = [
    name
    for name, passed in checks.items()
    if not passed
]

if failed:
    raise SystemExit(
        "CANDIDATE_PREFLIGHT_FAILED:"
        + ",".join(failed)
    )

print("CANDIDATE_PREFLIGHT=PASS")
print("CANDIDATE_FILE_COUNT=15")
PYTHON

install -d -m 0700 "${BACKUP_ROOT}"

python3 - \
    "${ROOT}" \
    "${MANIFEST}" \
    "${BACKUP_ROOT}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import shutil
import sys


root = Path(sys.argv[1]).resolve()
manifest = json.loads(
    Path(sys.argv[2]).read_text(
        encoding="utf-8"
    )
)
backup_root = Path(sys.argv[3])

additional = [
    "STATE.json",
    (
        "docs/contracts/application/"
        "APPLICATION-PORTS-FOUNDATION-V1.json"
    ),
    (
        "src/knowledge/"
        "validate_application_foundation.py"
    ),
]

paths = {
    item["path"]
    for item in manifest["files"]
}

paths.update(additional)

for relative in sorted(paths):
    source = root / relative

    if not source.is_file():
        raise SystemExit(
            f"BACKUP_SOURCE_MISSING:{relative}"
        )

    destination = backup_root / relative

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    shutil.copy2(
        source,
        destination,
    )

print("CANDIDATE_BACKUP=PASS")
PYTHON

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-precheck.txt"

python3 \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${ROOT}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${ARCH_CONTRACT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitutional-precheck.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-precheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONSTITUTIONAL_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-precheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-precheck.txt"

python3 \
    "${OBSERVATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${OBSERVATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/observation-precheck.txt"

grep -q \
    '^OBSERVATION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/observation-precheck.txt"

python3 \
    "${QUALIFICATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${QUALIFICATION_CONTRACT}" \
    "${EVIDENCE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/candidate-validation.txt"

grep -q \
    '^EVIDENCE_QUALIFICATION_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/candidate-validation.txt"

python3 - \
    "${EVIDENCE_CONTRACT}" \
    "${QUALIFICATION_CONTRACT}" \
    "${ROOT}/src/domain/governance/types.py" \
    "${ROOT}/src/runtime/governance/types.py" \
    "${ROOT}/src/sandra/domain/governance/types.py" \
    "${SANDRA_EVIDENCE_DIR}/semantic-alignment.txt" <<'PYTHON'
from __future__ import annotations

import ast
import json
from pathlib import Path
import sys


constitutional_path = Path(sys.argv[1])
candidate_path = Path(sys.argv[2])
domain_paths = [
    Path(sys.argv[3]),
    Path(sys.argv[4]),
    Path(sys.argv[5]),
]
evidence_path = Path(sys.argv[6])

expected_authority = {
    "unknown",
    "observational",
    "corroborated",
    "authoritative",
}

expected_outcomes = {
    "accept",
    "reject",
    "corroborate",
    "conflict",
    "expire",
    "request_more_evidence",
}


def load(path: Path) -> dict:
    value = json.loads(
        path.read_text(encoding="utf-8")
    )

    if not isinstance(value, dict):
        raise SystemExit(
            f"ROOT_NOT_OBJECT:{path}"
        )

    return value


def enum_values(path: Path) -> set[str]:
    tree = ast.parse(
        path.read_text(encoding="utf-8"),
        filename=str(path),
    )

    values: set[str] = set()

    for node in tree.body:
        if not (
            isinstance(node, ast.ClassDef)
            and node.name == "AuthorityLevel"
        ):
            continue

        for statement in node.body:
            if not isinstance(
                statement,
                ast.Assign,
            ):
                continue

            if not (
                len(statement.targets) == 1
                and isinstance(
                    statement.targets[0],
                    ast.Name,
                )
                and isinstance(
                    statement.value,
                    ast.Constant,
                )
                and isinstance(
                    statement.value.value,
                    str,
                )
            ):
                continue

            values.add(
                statement.value.value
            )

    return values


constitutional = load(constitutional_path)
candidate = load(candidate_path)

constitutional_authority = set(
    constitutional["spec"]["authorityLevels"]
)

constitutional_outcomes = set(
    constitutional["spec"][
        "qualificationOutcomes"
    ]
)

candidate_authority = set(
    candidate["spec"]["authorityLevels"]
)

candidate_outcomes = set(
    candidate["spec"][
        "qualificationOutcomes"
    ]
)

domain_sets = [
    enum_values(path)
    for path in domain_paths
]

checks = {
    "constitutional_authority": (
        constitutional_authority
        == expected_authority
    ),
    "constitutional_outcomes": (
        constitutional_outcomes
        == expected_outcomes
    ),
    "candidate_matches_constitution": (
        candidate_authority
        == constitutional_authority
        and candidate_outcomes
        == constitutional_outcomes
    ),
    "all_domain_copies_aligned": all(
        value == expected_authority
        for value in domain_sets
    ),
}

evidence_path.write_text(
    "\n".join(
        f"{name}={'PASS' if passed else 'FAIL'}"
        for name, passed in sorted(
            checks.items()
        )
    )
    + "\n",
    encoding="utf-8",
)

failed = [
    name
    for name, passed in checks.items()
    if not passed
]

if failed:
    raise SystemExit(
        "SEMANTIC_ALIGNMENT_FAILED:"
        + ",".join(failed)
    )

print("SEMANTIC_ALIGNMENT=PASS")
PYTHON

PYTHONPATH="${ROOT}/src/sandra/domain:${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/application-tests-prepublication.txt" \
    2>&1

python3 - \
    "${SANDRA_EVIDENCE_DIR}/application-tests-prepublication.txt" \
    "${SANDRA_EVIDENCE_DIR}/application-test-summary.txt" <<'PYTHON'
from pathlib import Path
import re
import sys

log = Path(sys.argv[1]).read_text(
    encoding="utf-8"
)

match = re.search(
    r"Ran ([0-9]+) tests",
    log,
)

if match is None:
    raise SystemExit(
        "APPLICATION_TEST_COUNT_MISSING"
    )

count = int(match.group(1))

if count < 16:
    raise SystemExit(
        f"APPLICATION_TEST_COUNT_TOO_LOW:{count}"
    )

if "\nOK\n" not in f"\n{log}\n":
    raise SystemExit(
        "APPLICATION_TESTS_NOT_OK"
    )

Path(sys.argv[2]).write_text(
    f"APPLICATION_TEST_COUNT={count}\n"
    "APPLICATION_TESTS=PASS\n",
    encoding="utf-8",
)

print("APPLICATION_TESTS=PASS")
PYTHON

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${ROOT}/src/sandra/domain" \
python3 -m unittest discover \
    -s "${DOMAIN_TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-tests-prepublication.txt" \
    2>&1

grep -q '^OK$' \
    "${SANDRA_EVIDENCE_DIR}/domain-tests-prepublication.txt"

python3 - \
    "${QUALIFICATION_CONTRACT}" \
    "${QUALIFICATION_ADR}" \
    "${QUALIFICATION_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys


contract_path = Path(sys.argv[1])
adr_path = Path(sys.argv[2])
validator_path = Path(sys.argv[3])

contract = json.loads(
    contract_path.read_text(encoding="utf-8")
)

metadata = contract.get("metadata")

if not isinstance(metadata, dict):
    raise SystemExit(
        "QUALIFICATION_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "QUALIFICATION_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000012B"

contract_path.write_text(
    json.dumps(
        contract,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)

adr = adr_path.read_text(encoding="utf-8")

old_status = """## Stato

Candidate generated by R3-000012A.

Publication and immutable certification are reserved for R3-000012B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by R3-000012A, exported and verified from its exact
repository state, then published by R3-000012B.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "ADR_STATUS_MARKER_INVALID"
    )

adr = adr.replace(
    old_status,
    new_status,
    1,
)

adr_path.write_text(
    adr,
    encoding="utf-8",
)

validator = validator_path.read_text(
    encoding="utf-8"
)

replacements = (
    (
        '!= "candidate"\n    ):\n        fail("STATUS_NOT_CANDIDATE")',
        '!= "immutable"\n    ):\n        fail("STATUS_NOT_IMMUTABLE")',
    ),
    (
        'print("EVIDENCE_QUALIFICATION_CANDIDATE=PASS")',
        'print("EVIDENCE_QUALIFICATION=PASS")',
    ),
)

for old, new in replacements:
    if validator.count(old) != 1:
        raise SystemExit(
            "QUALIFICATION_VALIDATOR_MARKER_INVALID:"
            + repr(old)
        )

    validator = validator.replace(
        old,
        new,
        1,
    )

validator_path.write_text(
    validator,
    encoding="utf-8",
)

print("QUALIFICATION_PUBLICATION_PATCH=PASS")
PYTHON

python3 - \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys


contract_path = Path(sys.argv[1])
validator_path = Path(sys.argv[2])

contract = json.loads(
    contract_path.read_text(encoding="utf-8")
)

metadata = contract.get("metadata")
spec = contract.get("spec")

if not isinstance(metadata, dict):
    raise SystemExit(
        "FOUNDATION_METADATA_INVALID"
    )

if not isinstance(spec, dict):
    raise SystemExit(
        "FOUNDATION_SPEC_INVALID"
    )

inbound = spec.get("inboundPorts")
outbound = spec.get("outboundPorts")
use_cases = spec.get("concreteUseCases")

if not isinstance(inbound, list):
    raise SystemExit(
        "FOUNDATION_INBOUND_INVALID"
    )

if not isinstance(outbound, list):
    raise SystemExit(
        "FOUNDATION_OUTBOUND_INVALID"
    )

if use_cases is None:
    use_cases = []
    spec["concreteUseCases"] = use_cases

if not isinstance(use_cases, list):
    raise SystemExit(
        "FOUNDATION_USE_CASES_INVALID"
    )


def append_once(
    values: list,
    value: str,
    field: str,
) -> None:
    count = values.count(value)

    if count > 1:
        raise SystemExit(
            f"FOUNDATION_DUPLICATE:{field}:{value}"
        )

    if count == 0:
        values.append(value)


append_once(
    inbound,
    "QualifyEvidencePort",
    "inboundPorts",
)

append_once(
    outbound,
    "EvidenceQualifier",
    "outboundPorts",
)

append_once(
    use_cases,
    "QualifyEvidence",
    "concreteUseCases",
)

metadata["revision"] = 3

contract_path.write_text(
    json.dumps(
        contract,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)

validator = validator_path.read_text(
    encoding="utf-8"
)

old_files = '''    "use_cases/observe_subject.py",
}'''

new_files = '''    "use_cases/observe_subject.py",
    "evidence.py",
    "ports/inbound/evidence_qualification.py",
    "ports/outbound/evidence_qualifier.py",
    "use_cases/qualify_evidence.py",
}'''

if validator.count(old_files) != 1:
    raise SystemExit(
        "FOUNDATION_FILE_SET_MARKER_INVALID"
    )

validator = validator.replace(
    old_files,
    new_files,
    1,
)

replacements = (
    (
        'print("APPLICATION_PYTHON_FILE_COUNT=18")',
        'print("APPLICATION_PYTHON_FILE_COUNT=22")',
    ),
    (
        'print("INBOUND_PORT_COUNT=3")',
        'print("INBOUND_PORT_COUNT=4")',
    ),
    (
        'print("OUTBOUND_PORT_COUNT=4")',
        'print("OUTBOUND_PORT_COUNT=5")',
    ),
    (
        'print("CONCRETE_USE_CASE_COUNT=1")',
        'print("CONCRETE_USE_CASE_COUNT=2")',
    ),
)

for old, new in replacements:
    if validator.count(old) != 1:
        raise SystemExit(
            "FOUNDATION_VALIDATOR_MARKER_INVALID:"
            + old
        )

    validator = validator.replace(
        old,
        new,
        1,
    )

validator_path.write_text(
    validator,
    encoding="utf-8",
)

print("APPLICATION_FOUNDATION_REVISION=PASS")
PYTHON

python3 -m compileall \
    -q \
    "${ROOT}/src/domain" \
    "${ROOT}/src/runtime" \
    "${ROOT}/src/sandra/domain" \
    "${APPLICATION_ROOT}" \
    "${TEST_ROOT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${QUALIFICATION_VALIDATOR}"

python3 \
    "${QUALIFICATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${QUALIFICATION_CONTRACT}" \
    "${EVIDENCE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/published-qualification-validation.txt"

grep -q \
    '^EVIDENCE_QUALIFICATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-qualification-validation.txt"

python3 \
    "${FOUNDATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${FOUNDATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/application-foundation-revision-validation.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/application-foundation-revision-validation.txt"

PYTHONPATH="${ROOT}/src/sandra/domain:${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/application-tests-published.txt" \
    2>&1

grep -q '^OK$' \
    "${SANDRA_EVIDENCE_DIR}/application-tests-published.txt"

find \
    "${ROOT}/src/domain" \
    "${ROOT}/src/runtime" \
    "${ROOT}/src/sandra/domain" \
    "${APPLICATION_ROOT}" \
    "${TEST_ROOT}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find \
    "${ROOT}/src/domain" \
    "${ROOT}/src/runtime" \
    "${ROOT}/src/sandra/domain" \
    "${APPLICATION_ROOT}" \
    "${TEST_ROOT}" \
    -type f \
    -name '*.pyc' \
    -delete

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

foundation = state["spec"].get(
    "application_foundation"
)

observation = state["spec"].get(
    "observation_use_case"
)

if not isinstance(foundation, dict):
    raise SystemExit(
        "APPLICATION_FOUNDATION_STATE_MISSING"
    )

if foundation.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "APPLICATION_FOUNDATION_NOT_CERTIFIED"
    )

if not isinstance(observation, dict):
    raise SystemExit(
        "OBSERVATION_USE_CASE_STATE_MISSING"
    )

if observation.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "OBSERVATION_USE_CASE_NOT_CERTIFIED"
    )

state["metadata"]["state_version"] = "5.2.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

foundation["revision"] = 3
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
]
foundation["outbound_ports"] = [
    "Repository",
    "EventBus",
    "UnitOfWork",
    "ObservationSource",
    "EvidenceQualifier",
]
foundation["concrete_use_cases"] = 2

state["spec"]["evidence_qualification_use_case"] = {
    "version": "1.0.0",
    "id": "evidence-qualification-use-case-v1",
    "status": "certified_immutable",
    "capability": "evidence_qualification",
    "inbound_port": "QualifyEvidencePort",
    "outbound_port": "EvidenceQualifier",
    "use_case": "QualifyEvidence",
    "request": "QualificationRequest",
    "result": "ApplicationResult[QualifiedEvidence]",
    "contract": (
        "docs/contracts/application/"
        "EVIDENCE-QUALIFICATION-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_evidence_qualification.py"
    ),
    "authority_levels": [
        "unknown",
        "observational",
        "corroborated",
        "authoritative",
    ],
    "qualification_outcomes": [
        "accept",
        "reject",
        "corroborate",
        "conflict",
        "expire",
        "request_more_evidence",
    ],
    "candidate_gate": "R3-000012A",
    "candidate_export_gate": (
        "R3-000012B-AUDIT-EXPORT"
    ),
    "publication_gate": "R3-000012B",
    "authoritative_state_mutation": "none",
    "policy_evaluation": "none",
    "planning": "none",
    "execution": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000012B",
    "title": (
        "Evidence Qualification Use Case "
        "Foundation Publication"
    ),
    "type": "application_vertical_contract_publication",
    "targets": [
        "AuthorityLevel constitutional alignment",
        "Evidence Qualification application types",
        "QualifyEvidencePort",
        "EvidenceQualifier",
        "QualifyEvidence",
        "Application Ports Foundation revision 3",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "authoritative persistence",
        "policy evaluation",
        "planning",
        "execution",
        "technology adapters",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact exported candidate state",
        "publish immutable Evidence Qualification contracts",
        "separate authority levels from qualification outcomes",
        "preserve constitutional Evidence Authority semantics",
        "register the use case in canonical STATE",
    ],
    "prohibitions": [
        "no unexported candidate substitution",
        "no authoritative state mutation",
        "no policy decision",
        "no execution",
        "no product-specific application logic",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000013",
    "title": "Resource Graph Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Evidence Qualification Use Case Foundation"
    ),
    "current_gate": "R3-000012B",
    "current_gate_status": "complete",
    "next_gate": "R3-000013",
}

state["status"]["evidence_qualification_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000012A",
    "candidate_export_gate": (
        "R3-000012B-AUDIT-EXPORT"
    ),
    "publication_gate": "R3-000012B",
    "candidate_manifest": "pass",
    "candidate_hash_count": 15,
    "constitutional_alignment": "pass",
    "domain_authority_migration": "pass",
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 3,
    "authoritative_state_mutation": "none",
    "policy_evaluation": "none",
    "execution": "none",
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
# ${SANDRA_RUNBOOK_ID} — Evidence Qualification publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000012A\`
- Candidate export gate: \`R3-000012B-AUDIT-EXPORT\`
- Publication gate: \`R3-000012B\`
- Exported candidate files verified by SHA256: \`15\`
- Authority levels: \`4\`
- Qualification outcomes: \`6\`
- Application Foundation revision: \`3\`
- Authoritative state mutation: \`NONE\`
- Policy evaluation: \`NONE\`
- Execution: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact exported R3-000012A working tree;
- verified SHA256 for every candidate file;
- verified constitutional authority and outcome alignment;
- verified all three Domain AuthorityLevel copies;
- passed Application and Domain tests before publication;
- promoted the Evidence Qualification contract to immutable;
- promoted ADR-0012 to accepted and immutable;
- updated the permanent qualification validator;
- updated Application Ports Foundation to revision 3;
- registered the use case in STATE;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Evidence Qualification Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${QUALIFICATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${QUALIFICATION_CONTRACT}" \
    "${EVIDENCE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/qualification-post-sync.txt"

grep -q \
    '^EVIDENCE_QUALIFICATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/qualification-post-sync.txt"

python3 \
    "${FOUNDATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${FOUNDATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/foundation-post-sync.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/foundation-post-sync.txt"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
evidence_path = Path(sys.argv[2])


def command(*arguments: str) -> str:
    return subprocess.run(
        [
            "git",
            "-C",
            str(root),
            *arguments,
        ],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout


status = command(
    "status",
    "--porcelain",
)

head = command(
    "rev-parse",
    "HEAD",
).strip()

origin = command(
    "rev-parse",
    "origin/main",
).strip()

checks = {
    "working_tree_clean": (
        status.strip() == ""
    ),
    "head_matches_origin": (
        head == origin
    ),
}

evidence_path.write_text(
    "\n".join(
        f"{name}={'PASS' if passed else 'FAIL'}"
        for name, passed in sorted(
            checks.items()
        )
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
    printf 'R3_000012B=PASS\n'
    printf 'EVIDENCE_QUALIFICATION=PASS\n'
    printf 'EVIDENCE_QUALIFICATION_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000012A\n'
    printf 'CANDIDATE_EXPORT_GATE=R3-000012B-AUDIT-EXPORT\n'
    printf 'PUBLICATION_GATE=R3-000012B\n'
    printf 'CANDIDATE_HASH_COUNT=15\n'
    printf 'AUTHORITY_LEVEL_COUNT=4\n'
    printf 'QUALIFICATION_OUTCOME_COUNT=6\n'
    printf 'APPLICATION_FOUNDATION_REVISION=3\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'CONSTITUTIONAL_ALIGNMENT=PASS\n'
    printf 'AUTHORITATIVE_STATE_MUTATION=NONE\n'
    printf 'POLICY_EVALUATION=NONE\n'
    printf 'EXECUTION=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'QUALIFICATION_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${QUALIFICATION_CONTRACT}" | awk '{print $1}')"
    printf 'QUALIFICATION_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${QUALIFICATION_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
