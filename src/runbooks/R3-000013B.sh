#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000013B-resource-graph-publication.sh"

sandra_begin \
    "R3-000013B" \
    "Validate and publish Resource Graph Use Case Foundation"

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

GRAPH_CONTRACT="${ROOT}/docs/contracts/application/RESOURCE-GRAPH-USE-CASE-V1.json"
GRAPH_VALIDATOR="${ROOT}/src/knowledge/validate_resource_graph_use_case.py"
GRAPH_ADR="${ROOT}/docs/adr/ADR-0013-RESOURCE-GRAPH-USE-CASE.md"
GRAPH_TYPES="${APPLICATION_ROOT}/resource_graph.py"

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

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"
MANIFEST="${SANDRA_RUN_DIR}/candidate-manifest.json"

for required_file in \
    "${STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${GRAPH_CONTRACT}" \
    "${GRAPH_VALIDATOR}" \
    "${GRAPH_ADR}" \
    "${GRAPH_TYPES}" \
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
    "${EVIDENCE_AUTHORITY_CONTRACT}"
do
    sandra_require_file "${required_file}"
done

cat > "${MANIFEST}" <<'JSON'
{
  "sourceGate": "R3-000013A",
  "baseHead": "11131f157f63e28a6cd3dbdaf8217275a13c8123",
  "files": [
    {
      "category": "modified",
      "path": "src/sandra/application/__init__.py",
      "sha256": "19cce4c45b6915dcbf303a4cbad4e71cc46ce13c951a3393ff2ac98ddbd0d845"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/inbound/__init__.py",
      "sha256": "724d96e1943c24dc86a4e38cf4c934834090747d2324f5edf094775115e74524"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/outbound/__init__.py",
      "sha256": "8903d3c3bc5056fe81730932018fb99bd0527a56db71c4e001de08f4f98925b6"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/use_cases/__init__.py",
      "sha256": "fcd24824f2182a696371f4d83e2a801c520072dbcb71fdcb2132464fd78c3a2c"
    },
    {
      "category": "untracked",
      "path": "docs/adr/ADR-0013-RESOURCE-GRAPH-USE-CASE.md",
      "sha256": "716c4d0cf9f334da68afe40a298ad4e73ef4d34f3bab7958eef2fb340d81f5cc"
    },
    {
      "category": "untracked",
      "path": "docs/contracts/application/RESOURCE-GRAPH-USE-CASE-V1.json",
      "sha256": "714e4f74c487de09fe0ae7cea46894ac5309f96a174559cc069017c473c4d5d5"
    },
    {
      "category": "untracked",
      "path": "src/knowledge/validate_resource_graph_use_case.py",
      "sha256": "c63fe40f3c6032256844c89ffc53ac942e8564afc27c0d7b7c8ab15a6d4fea4a"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/inbound/resource_graph.py",
      "sha256": "a4010f1488481b61e4351ad0bcf12fdbc8e27957c62872dc32892c6a960c8d65"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/outbound/resource_graph_reader.py",
      "sha256": "d3ad1f3f07decdff2476cbcdbee9178fc3b9a1138c3b9f96398f7a8626c93d27"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/resource_graph.py",
      "sha256": "66491c22ae5ca1cd7ea65994f4291f694a4725b264d6e816d53349fff43495e7"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/use_cases/query_resource_graph.py",
      "sha256": "0754b016684c819a076cb6958b119dd6e3ad502dba9936e785b57691630d9cd9"
    },
    {
      "category": "untracked",
      "path": "tests/contract/application/test_resource_graph_use_case.py",
      "sha256": "796fb152ec25fd4ee70f9851ed13ceb3c7dfae4026f36d38e3ee9585f0ba1b43"
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
        "RESOURCE_GRAPH_CANDIDATE_PREFLIGHT_FAILED:"
        + ",".join(failed)
    )

print("RESOURCE_GRAPH_CANDIDATE_PREFLIGHT=PASS")
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

print("RESOURCE_GRAPH_BACKUP=PASS")
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
    "${GRAPH_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${GRAPH_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/graph-candidate-validation.txt"

grep -q \
    '^RESOURCE_GRAPH_USE_CASE_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/graph-candidate-validation.txt"

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

count = int(match.group(1))

if count < 24:
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
    "${GRAPH_CONTRACT}" \
    "${GRAPH_ADR}" \
    "${GRAPH_VALIDATOR}" <<'PYTHON'
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
        "GRAPH_CONTRACT_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "GRAPH_CONTRACT_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000013B"

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

Candidate generated by R3-000013A.

Publication and immutable certification are reserved for R3-000013B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by R3-000013A, verified against its exact exported
manifest and published by R3-000013B.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "GRAPH_ADR_STATUS_MARKER_INVALID"
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
        'if metadata.get("status") != "candidate":\n'
        '        fail("STATUS_NOT_CANDIDATE")',
        'if metadata.get("status") != "immutable":\n'
        '        fail("STATUS_NOT_IMMUTABLE")',
    ),
    (
        'print("RESOURCE_GRAPH_USE_CASE_CANDIDATE=PASS")',
        'print("RESOURCE_GRAPH_USE_CASE=PASS")',
    ),
)

for old, new in replacements:
    count = validator.count(old)

    if count != 1:
        raise SystemExit(
            "GRAPH_VALIDATOR_MARKER_INVALID:"
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

print("RESOURCE_GRAPH_PUBLICATION_PATCH=PASS")
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
    "QueryResourceGraphPort",
    "inboundPorts",
)

append_once(
    outbound,
    "ResourceGraphReader",
    "outboundPorts",
)

append_once(
    use_cases,
    "QueryResourceGraph",
    "concreteUseCases",
)

metadata["revision"] = 4

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
    '    "resource_graph.py",\n'
    '    "ports/inbound/resource_graph.py",\n'
    '    "ports/outbound/resource_graph_reader.py",\n'
    '    "use_cases/query_resource_graph.py",\n'
)

if '"resource_graph.py"' not in validator:
    marker = (
        '    "use_cases/qualify_evidence.py",\n'
        '}'
    )

    replacement = (
        '    "use_cases/qualify_evidence.py",\n'
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
    "APPLICATION_PYTHON_FILE_COUNT": 26,
    "INBOUND_PORT_COUNT": 5,
    "OUTBOUND_PORT_COUNT": 6,
    "CONCRETE_USE_CASE_COUNT": 3,
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
    "${GRAPH_VALIDATOR}"

python3 \
    "${GRAPH_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${GRAPH_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/published-graph-validation.txt"

grep -q \
    '^RESOURCE_GRAPH_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-graph-validation.txt"

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

evidence = state["spec"].get(
    "evidence_qualification_use_case"
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

if not isinstance(evidence, dict):
    raise SystemExit(
        "EVIDENCE_QUALIFICATION_STATE_MISSING"
    )

if evidence.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "EVIDENCE_QUALIFICATION_NOT_CERTIFIED"
    )

state["metadata"]["state_version"] = "5.3.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

foundation["revision"] = 4
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
    "QueryResourceGraphPort",
]
foundation["outbound_ports"] = [
    "Repository",
    "EventBus",
    "UnitOfWork",
    "ObservationSource",
    "EvidenceQualifier",
    "ResourceGraphReader",
]
foundation["concrete_use_cases"] = 3

state["spec"]["resource_graph_use_case"] = {
    "version": "1.0.0",
    "id": "resource-graph-use-case-v1",
    "status": "certified_immutable",
    "capability": "resource_graph",
    "inbound_port": "QueryResourceGraphPort",
    "outbound_port": "ResourceGraphReader",
    "use_case": "QueryResourceGraph",
    "request": "ResourceGraphRequest",
    "result": "ApplicationResult[ResourceGraphSnapshot]",
    "contract": (
        "docs/contracts/application/"
        "RESOURCE-GRAPH-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_resource_graph_use_case.py"
    ),
    "domain_resources": [
        "ManagedObject",
        "Relationship",
        "ResourceEnvelope",
        "ResourceKind",
    ],
    "candidate_gate": "R3-000013A",
    "publication_gate": "R3-000013B",
    "candidate_hash_count": 12,
    "domain_resource_duplication": "none",
    "authoritative_state_mutation": "none",
    "policy_evaluation": "none",
    "planning": "none",
    "execution": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000013B",
    "title": (
        "Resource Graph Use Case "
        "Foundation Publication"
    ),
    "type": (
        "application_vertical_contract_publication"
    ),
    "targets": [
        "ResourceGraphRequest",
        "ResourceGraphSnapshot",
        "QueryResourceGraphPort",
        "ResourceGraphReader",
        "QueryResourceGraph",
        "Application Ports Foundation revision 4",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "authoritative state mutation",
        "policy evaluation",
        "planning",
        "execution",
        "technology-specific topology adapters",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact R3-000013A candidate",
        "publish the Resource Graph use case",
        "reuse canonical Domain graph resources",
        "support bounded relationship and impact traversal",
        "register the use case in canonical STATE",
    ],
    "prohibitions": [
        "no duplicate ManagedObject model",
        "no duplicate Relationship model",
        "no atomic whole-Habitat aggregate",
        "no policy decision",
        "no execution",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000014",
    "title": "Desired State Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Resource Graph Use Case Foundation"
    ),
    "current_gate": "R3-000013B",
    "current_gate_status": "complete",
    "next_gate": "R3-000014",
}

state["status"]["resource_graph_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000013A",
    "publication_gate": "R3-000013B",
    "candidate_manifest": "pass",
    "candidate_hash_count": 12,
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 4,
    "domain_resource_duplication": "none",
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
# ${SANDRA_RUNBOOK_ID} — Resource Graph publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000013A\`
- Publication gate: \`R3-000013B\`
- Candidate files verified by SHA256: \`12\`
- Application Foundation revision: \`4\`
- Domain resource duplication: \`NONE\`
- Authoritative state mutation: \`NONE\`
- Policy evaluation: \`NONE\`
- Execution: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact R3-000013A candidate working tree;
- verified SHA256 for all twelve candidate files;
- passed Architecture, constitutional and capability validation;
- passed Observation and Evidence Qualification validation;
- passed Application and Domain tests before publication;
- promoted the Resource Graph contract to immutable;
- promoted ADR-0013 to accepted and immutable;
- updated the permanent Resource Graph validator;
- updated Application Ports Foundation to revision 4;
- reused existing ManagedObject and Relationship Domain resources;
- registered the Resource Graph use case in STATE;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Resource Graph Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${GRAPH_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${GRAPH_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/graph-post-sync.txt"

grep -q \
    '^RESOURCE_GRAPH_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/graph-post-sync.txt"

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
    printf 'R3_000013B=PASS\n'
    printf 'RESOURCE_GRAPH_USE_CASE=PASS\n'
    printf 'RESOURCE_GRAPH_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000013A\n'
    printf 'PUBLICATION_GATE=R3-000013B\n'
    printf 'CANDIDATE_HASH_COUNT=12\n'
    printf 'APPLICATION_FOUNDATION_REVISION=4\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=26\n'
    printf 'INBOUND_PORT_COUNT=5\n'
    printf 'OUTBOUND_PORT_COUNT=6\n'
    printf 'CONCRETE_USE_CASE_COUNT=3\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'DOMAIN_RESOURCE_DUPLICATION=NONE\n'
    printf 'AUTHORITATIVE_STATE_MUTATION=NONE\n'
    printf 'POLICY_EVALUATION=NONE\n'
    printf 'EXECUTION=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'GRAPH_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${GRAPH_CONTRACT}" | awk '{print $1}')"
    printf 'GRAPH_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${GRAPH_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
