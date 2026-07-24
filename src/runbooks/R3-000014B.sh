#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000014B-desired-state-publication.sh"

sandra_begin \
    "R3-000014B" \
    "Validate and publish Desired State Use Case Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
APPLICATION_TEST_ROOT="${ROOT}/tests/contract/application"
DOMAIN_ROOT="${ROOT}/src/sandra/domain"
DOMAIN_TEST_ROOT="${ROOT}/tests/unit/domain"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

FOUNDATION_CONTRACT="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
FOUNDATION_VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"

DESIRED_STATE_CONTRACT="${ROOT}/docs/contracts/application/DESIRED-STATE-USE-CASE-V1.json"
DESIRED_STATE_VALIDATOR="${ROOT}/src/knowledge/validate_desired_state_use_case.py"
DESIRED_STATE_ADR="${ROOT}/docs/adr/ADR-0014-DESIRED-STATE-USE-CASE.md"
DESIRED_STATE_TYPES="${APPLICATION_ROOT}/desired_state.py"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

OBSERVATION_CONTRACT="${ROOT}/docs/contracts/application/OBSERVATION-USE-CASE-V1.json"
OBSERVATION_VALIDATOR="${ROOT}/src/knowledge/validate_observation_use_case.py"

EVIDENCE_CONTRACT="${ROOT}/docs/contracts/application/EVIDENCE-QUALIFICATION-USE-CASE-V1.json"
EVIDENCE_VALIDATOR="${ROOT}/src/knowledge/validate_evidence_qualification.py"
EVIDENCE_AUTHORITY_CONTRACT="${ROOT}/docs/contracts/constitutional/EVIDENCE-AUTHORITY-CONTRACT-V1.json"

RESOURCE_GRAPH_CONTRACT="${ROOT}/docs/contracts/application/RESOURCE-GRAPH-USE-CASE-V1.json"
RESOURCE_GRAPH_VALIDATOR="${ROOT}/src/knowledge/validate_resource_graph_use_case.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"
MANIFEST="${SANDRA_RUN_DIR}/candidate-manifest.json"

for required_file in \
    "${STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${DESIRED_STATE_CONTRACT}" \
    "${DESIRED_STATE_VALIDATOR}" \
    "${DESIRED_STATE_ADR}" \
    "${DESIRED_STATE_TYPES}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${OBSERVATION_CONTRACT}" \
    "${OBSERVATION_VALIDATOR}" \
    "${EVIDENCE_CONTRACT}" \
    "${EVIDENCE_VALIDATOR}" \
    "${EVIDENCE_AUTHORITY_CONTRACT}" \
    "${RESOURCE_GRAPH_CONTRACT}" \
    "${RESOURCE_GRAPH_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

cat > "${MANIFEST}" <<'JSON'
{
  "sourceGate": "R3-000014A",
  "baseHead": "2198d15f7e74c75c897b9ece99fd608b14ddaffb",
  "files": [
    {
      "category": "modified",
      "path": "src/sandra/application/__init__.py",
      "sha256": "647fbd5a8249e64020de87e941f13933db0b7650193bd9e8f0324b0e00e2540f"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/inbound/__init__.py",
      "sha256": "ae67fb36ab677101c0f194b5d216fb9ef35a53b4a6c90853f30e76b194e2ab30"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/outbound/__init__.py",
      "sha256": "79763e46dbca9e9d50641c78974b21d824685e2b22d47d74707204fff24cdde8"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/use_cases/__init__.py",
      "sha256": "5685027a86b94b660aa13c5bd57aa4cfe668afb9b73b66202a6ccde5a3cd86db"
    },
    {
      "category": "untracked",
      "path": "docs/adr/ADR-0014-DESIRED-STATE-USE-CASE.md",
      "sha256": "52b92419d79207d20ea86cc23b88ed6302f035440456a597d1222eec9c1ac394"
    },
    {
      "category": "untracked",
      "path": "docs/contracts/application/DESIRED-STATE-USE-CASE-V1.json",
      "sha256": "e5ac851711b0d1bd98d814f41692746fa9f8e59bdb9d0876e63cdb21f06cf4c6"
    },
    {
      "category": "untracked",
      "path": "src/knowledge/validate_desired_state_use_case.py",
      "sha256": "44db2a88843c0ebe30e535166e0de175634ea45bc9303c818f02ca6e55ab65c3"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/desired_state.py",
      "sha256": "43c03a98449ddabcfc3be25ef53a85f1021c2568ac468f2e13069b4830a9bcf2"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/inbound/desired_state.py",
      "sha256": "76aaf594b1f50a42de36c5bf3c41b61dd7f312f4543e071b6a53d95817f07b42"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/outbound/desired_state_repository.py",
      "sha256": "c128e1e30511ead5e508e5fd5deff68cf53c26c0ff4693664a64db9374878828"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/use_cases/declare_desired_state.py",
      "sha256": "888c396c4e13b9afca20f38a1826b402037359f8d5efa22665010397fa227939"
    },
    {
      "category": "untracked",
      "path": "tests/contract/application/test_desired_state_use_case.py",
      "sha256": "2b5a8b219629168c4f05e7dda896cf2174630f04a8204edcbc84143e7046c114"
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
manifest = json.loads(
    Path(sys.argv[2]).read_text(
        encoding="utf-8"
    )
)
evidence = Path(sys.argv[3])


def git_output(*arguments: str) -> str:
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


def git_paths(*arguments: str) -> set[str]:
    return {
        line.strip()
        for line in git_output(
            *arguments
        ).splitlines()
        if line.strip()
    }


def sha256(path: Path) -> str:
    digest = hashlib.sha256()

    with path.open("rb") as handle:
        for chunk in iter(
            lambda: handle.read(
                1024 * 1024
            ),
            b"",
        ):
            digest.update(chunk)

    return digest.hexdigest()


expected_modified = {
    record["path"]
    for record in manifest["files"]
    if record["category"] == "modified"
}

expected_untracked = {
    record["path"]
    for record in manifest["files"]
    if record["category"] == "untracked"
}

actual_modified = git_paths(
    "diff",
    "--name-only",
)

actual_untracked = git_paths(
    "ls-files",
    "--others",
    "--exclude-standard",
)

actual_staged = git_paths(
    "diff",
    "--cached",
    "--name-only",
)

head = git_output(
    "rev-parse",
    "HEAD",
).strip()

origin = git_output(
    "rev-parse",
    "origin/main",
).strip()

hash_errors: list[str] = []

for record in manifest["files"]:
    relative = record["path"]
    path = root / relative

    if not path.is_file():
        hash_errors.append(
            f"MISSING:{relative}"
        )
        continue

    actual = sha256(path)

    if actual != record["sha256"]:
        hash_errors.append(
            f"HASH:{relative}:{actual}"
        )

checks = {
    "base_head_matches_manifest": (
        head == manifest["baseHead"]
    ),
    "head_matches_origin": (
        head == origin
    ),
    "modified_set_matches_manifest": (
        actual_modified
        == expected_modified
    ),
    "untracked_set_matches_manifest": (
        actual_untracked
        == expected_untracked
    ),
    "staged_changes_absent": (
        not actual_staged
    ),
    "all_candidate_hashes_match": (
        not hash_errors
    ),
}

lines = [
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(
        checks.items()
    )
]

lines.extend(
    f"ERROR={error}"
    for error in hash_errors
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

evidence.write_text(
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
        "DESIRED_STATE_CANDIDATE_PREFLIGHT_FAILED:"
        + ",".join(failed)
    )

print("DESIRED_STATE_CANDIDATE_PREFLIGHT=PASS")
print("CANDIDATE_FILE_COUNT=12")
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

additional = {
    "STATE.json",
    (
        "docs/contracts/application/"
        "APPLICATION-PORTS-FOUNDATION-V1.json"
    ),
    (
        "src/knowledge/"
        "validate_application_foundation.py"
    ),
}

paths = {
    record["path"]
    for record in manifest["files"]
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

print("DESIRED_STATE_BACKUP=PASS")
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
    "${EVIDENCE_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${EVIDENCE_CONTRACT}" \
    "${EVIDENCE_AUTHORITY_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/evidence-precheck.txt"

grep -q \
    '^EVIDENCE_QUALIFICATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/evidence-precheck.txt"

python3 \
    "${RESOURCE_GRAPH_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${RESOURCE_GRAPH_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/resource-graph-precheck.txt"

grep -q \
    '^RESOURCE_GRAPH_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/resource-graph-precheck.txt"

python3 \
    "${DESIRED_STATE_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${DESIRED_STATE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/desired-state-candidate-validation.txt"

grep -q \
    '^DESIRED_STATE_USE_CASE_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/desired-state-candidate-validation.txt"

PYTHONPATH="${DOMAIN_ROOT}:${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${APPLICATION_TEST_ROOT}" \
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

count = int(
    match.group(1)
)

if count < 35:
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
PYTHONPATH="${DOMAIN_ROOT}" \
python3 -m unittest discover \
    -s "${DOMAIN_TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-tests-prepublication.txt" \
    2>&1

grep -q \
    '^OK$' \
    "${SANDRA_EVIDENCE_DIR}/domain-tests-prepublication.txt"

python3 - \
    "${DESIRED_STATE_CONTRACT}" \
    "${DESIRED_STATE_ADR}" \
    "${DESIRED_STATE_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys


contract_path = Path(sys.argv[1])
adr_path = Path(sys.argv[2])
validator_path = Path(sys.argv[3])

contract = json.loads(
    contract_path.read_text(
        encoding="utf-8"
    )
)

metadata = contract.get("metadata")

if not isinstance(metadata, dict):
    raise SystemExit(
        "DESIRED_STATE_CONTRACT_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "DESIRED_STATE_CONTRACT_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000014B"

contract_path.write_text(
    json.dumps(
        contract,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)

adr = adr_path.read_text(
    encoding="utf-8"
)

old_status = """## Stato

Candidate generated by R3-000014A.

Publication and immutable certification are reserved for R3-000014B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by R3-000014A, verified against its exact exported
manifest and published by R3-000014B.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "DESIRED_STATE_ADR_STATUS_MARKER_INVALID"
    )

adr_path.write_text(
    adr.replace(
        old_status,
        new_status,
        1,
    ),
    encoding="utf-8",
)

validator = validator_path.read_text(
    encoding="utf-8"
)

replacements = (
    (
        'if metadata.get("status") != (\n'
        '        "candidate"\n'
        '    ):\n'
        '        fail("STATUS_NOT_CANDIDATE")',
        'if metadata.get("status") != (\n'
        '        "immutable"\n'
        '    ):\n'
        '        fail("STATUS_NOT_IMMUTABLE")',
    ),
    (
        'print(\n'
        '        "DESIRED_STATE_USE_CASE_CANDIDATE=PASS"\n'
        '    )',
        'print(\n'
        '        "DESIRED_STATE_USE_CASE=PASS"\n'
        '    )',
    ),
)

for old, new in replacements:
    count = validator.count(old)

    if count != 1:
        raise SystemExit(
            "DESIRED_STATE_VALIDATOR_MARKER_INVALID:"
            + repr(old)
            + ":"
            + str(count)
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

print("DESIRED_STATE_PUBLICATION_PATCH=PASS")
PYTHON

python3 - \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import re
import sys


contract_path = Path(sys.argv[1])
validator_path = Path(sys.argv[2])

contract = json.loads(
    contract_path.read_text(
        encoding="utf-8"
    )
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
        "FOUNDATION_INBOUND_PORTS_INVALID"
    )

if not isinstance(outbound, list):
    raise SystemExit(
        "FOUNDATION_OUTBOUND_PORTS_INVALID"
    )

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
    "DeclareDesiredStatePort",
    "inboundPorts",
)

append_once(
    outbound,
    "DesiredStateRepository",
    "outboundPorts",
)

append_once(
    use_cases,
    "DeclareDesiredState",
    "concreteUseCases",
)

metadata["revision"] = 5

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

new_files = (
    '    "desired_state.py",\n'
    '    "ports/inbound/desired_state.py",\n'
    '    "ports/outbound/desired_state_repository.py",\n'
    '    "use_cases/declare_desired_state.py",\n'
)

if '"desired_state.py"' not in validator:
    marker = (
        '    "use_cases/query_resource_graph.py",\n'
        '}'
    )

    replacement = (
        '    "use_cases/query_resource_graph.py",\n'
        + new_files
        + '}'
    )

    if validator.count(marker) != 1:
        raise SystemExit(
            "FOUNDATION_FILE_SET_MARKER_INVALID"
        )

    validator = validator.replace(
        marker,
        replacement,
        1,
    )

count_replacements = {
    "APPLICATION_PYTHON_FILE_COUNT": 30,
    "INBOUND_PORT_COUNT": 6,
    "OUTBOUND_PORT_COUNT": 7,
    "CONCRETE_USE_CASE_COUNT": 4,
}

for label, expected in count_replacements.items():
    pattern = re.compile(
        r'print\("'
        + re.escape(label)
        + r'=[0-9]+"\)'
    )

    matches = pattern.findall(
        validator
    )

    if len(matches) != 1:
        raise SystemExit(
            f"FOUNDATION_COUNT_MARKER_INVALID:"
            f"{label}:{len(matches)}"
        )

    validator = pattern.sub(
        f'print("{label}={expected}")',
        validator,
        count=1,
    )

validator_path.write_text(
    validator,
    encoding="utf-8",
)

print("APPLICATION_FOUNDATION_REVISION=PASS")
PYTHON

python3 -m compileall \
    -q \
    "${APPLICATION_ROOT}" \
    "${APPLICATION_TEST_ROOT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${DESIRED_STATE_VALIDATOR}"

python3 \
    "${DESIRED_STATE_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${DESIRED_STATE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/published-desired-state-validation.txt"

grep -q \
    '^DESIRED_STATE_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-desired-state-validation.txt"

python3 \
    "${FOUNDATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${FOUNDATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/foundation-revision-validation.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/foundation-revision-validation.txt"

PYTHONPATH="${DOMAIN_ROOT}:${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${APPLICATION_TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/application-tests-published.txt" \
    2>&1

grep -q \
    '^OK$' \
    "${SANDRA_EVIDENCE_DIR}/application-tests-published.txt"

find \
    "${APPLICATION_ROOT}" \
    "${APPLICATION_TEST_ROOT}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find \
    "${APPLICATION_ROOT}" \
    "${APPLICATION_TEST_ROOT}" \
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
    state_path.read_text(
        encoding="utf-8"
    )
)

foundation = state["spec"].get(
    "application_foundation"
)

resource_graph = state["spec"].get(
    "resource_graph_use_case"
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

if not isinstance(
    resource_graph,
    dict,
):
    raise SystemExit(
        "RESOURCE_GRAPH_USE_CASE_STATE_MISSING"
    )

if resource_graph.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "RESOURCE_GRAPH_USE_CASE_NOT_CERTIFIED"
    )

state["metadata"]["state_version"] = "5.4.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

foundation["revision"] = 5
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
    "QueryResourceGraphPort",
    "DeclareDesiredStatePort",
]
foundation["outbound_ports"] = [
    "Repository",
    "EventBus",
    "UnitOfWork",
    "ObservationSource",
    "EvidenceQualifier",
    "ResourceGraphReader",
    "DesiredStateRepository",
]
foundation["concrete_use_cases"] = 4

state["spec"]["desired_state_use_case"] = {
    "version": "1.0.0",
    "id": "desired-state-use-case-v1",
    "status": "certified_immutable",
    "capability": "desired_state",
    "inbound_port": "DeclareDesiredStatePort",
    "outbound_port": "DesiredStateRepository",
    "use_case": "DeclareDesiredState",
    "request": "DesiredStateDeclaration",
    "result": "ApplicationResult[DesiredStateRecord]",
    "contract": (
        "docs/contracts/application/"
        "DESIRED-STATE-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_desired_state_use_case.py"
    ),
    "owns": [
        "desired configuration",
        "desired service state",
        "declared limits",
        "intent generation",
    ],
    "excludes": [
        "live telemetry",
        "imperative commands",
        "adapter configuration",
    ],
    "candidate_gate": "R3-000014A",
    "publication_gate": "R3-000014B",
    "candidate_hash_count": 12,
    "generation_control": "optimistic",
    "approval_reference": "required",
    "deep_immutability": "pass",
    "policy_evaluation": "none",
    "planning": "none",
    "execution": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000014B",
    "title": (
        "Desired State Use Case "
        "Foundation Publication"
    ),
    "type": (
        "application_vertical_contract_publication"
    ),
    "targets": [
        "DesiredStateDeclaration",
        "DesiredStateRecord",
        "DeclareDesiredStatePort",
        "DesiredStateRepository",
        "DeclareDesiredState",
        "Application Ports Foundation revision 5",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "live telemetry",
        "imperative commands",
        "adapter configuration",
        "policy evaluation",
        "planning",
        "execution",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact R3-000014A candidate",
        "publish immutable Desired State contracts",
        "preserve approved intent independently from observed state",
        "enforce monotonic optimistic generation control",
        "register the use case in canonical STATE",
    ],
    "prohibitions": [
        "no unapproved desired intent",
        "no live telemetry in Desired State",
        "no imperative command execution",
        "no adapter-specific configuration",
        "no policy decision",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000015",
    "title": "Policy Evaluation Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Desired State Use Case Foundation"
    ),
    "current_gate": "R3-000014B",
    "current_gate_status": "complete",
    "next_gate": "R3-000015",
}

state["status"]["desired_state_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000014A",
    "publication_gate": "R3-000014B",
    "candidate_manifest": "pass",
    "candidate_hash_count": 12,
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 5,
    "generation_control": "optimistic",
    "approval_reference": "required",
    "deep_immutability": "pass",
    "live_telemetry": "none",
    "imperative_commands": "none",
    "adapter_configuration": "none",
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
# ${SANDRA_RUNBOOK_ID} — Desired State publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000014A\`
- Publication gate: \`R3-000014B\`
- Candidate files verified by SHA256: \`12\`
- Application Foundation revision: \`5\`
- Generation control: \`OPTIMISTIC\`
- Approval reference: \`REQUIRED\`
- Deep immutability: \`PASS\`
- Live telemetry: \`NONE\`
- Imperative commands: \`NONE\`
- Adapter configuration: \`NONE\`
- Policy evaluation: \`NONE\`
- Execution: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact R3-000014A candidate working tree;
- verified SHA256 for all twelve candidate files;
- passed Architecture, constitutional and capability validation;
- passed Observation, Evidence Qualification and Resource Graph validation;
- passed Application and Domain tests before publication;
- promoted the Desired State contract to immutable;
- promoted ADR-0014 to accepted and immutable;
- updated the permanent Desired State validator;
- updated Application Ports Foundation to revision 5;
- registered the Desired State use case in STATE;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Desired State Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${DESIRED_STATE_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${DESIRED_STATE_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/desired-state-post-sync.txt"

grep -q \
    '^DESIRED_STATE_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/desired-state-post-sync.txt"

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
evidence = Path(sys.argv[2])


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

evidence.write_text(
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
    printf 'R3_000014B=PASS\n'
    printf 'DESIRED_STATE_USE_CASE=PASS\n'
    printf 'DESIRED_STATE_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000014A\n'
    printf 'PUBLICATION_GATE=R3-000014B\n'
    printf 'CANDIDATE_HASH_COUNT=12\n'
    printf 'APPLICATION_FOUNDATION_REVISION=5\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=30\n'
    printf 'INBOUND_PORT_COUNT=6\n'
    printf 'OUTBOUND_PORT_COUNT=7\n'
    printf 'CONCRETE_USE_CASE_COUNT=4\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'GENERATION_CONTROL=OPTIMISTIC\n'
    printf 'APPROVAL_REFERENCE=REQUIRED\n'
    printf 'DEEP_IMMUTABILITY=PASS\n'
    printf 'LIVE_TELEMETRY=NONE\n'
    printf 'IMPERATIVE_COMMANDS=NONE\n'
    printf 'ADAPTER_CONFIGURATION=NONE\n'
    printf 'POLICY_EVALUATION=NONE\n'
    printf 'EXECUTION=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'DESIRED_STATE_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${DESIRED_STATE_CONTRACT}" | awk '{print $1}')"
    printf 'DESIRED_STATE_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${DESIRED_STATE_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
