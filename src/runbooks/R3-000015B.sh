#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000015B-policy-decision-publication.sh"

sandra_begin \
    "R3-000015B" \
    "Validate and publish Policy Decision Use Case Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"
ROADMAP_STATE="${ROOT}/ROADMAP_STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
APPLICATION_TEST_ROOT="${ROOT}/tests/contract/application"
DOMAIN_ROOT="${ROOT}/src/sandra/domain"
DOMAIN_TEST_ROOT="${ROOT}/tests/unit/domain"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

FOUNDATION_CONTRACT="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
FOUNDATION_VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"

POLICY_CONTRACT="${ROOT}/docs/contracts/application/POLICY-DECISION-USE-CASE-V1.json"
POLICY_VALIDATOR="${ROOT}/src/knowledge/validate_policy_decision_use_case.py"
POLICY_ADR="${ROOT}/docs/adr/ADR-0015-POLICY-DECISION-USE-CASE.md"
POLICY_TYPES="${APPLICATION_ROOT}/policy_decision.py"

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

DESIRED_STATE_CONTRACT="${ROOT}/docs/contracts/application/DESIRED-STATE-USE-CASE-V1.json"
DESIRED_STATE_VALIDATOR="${ROOT}/src/knowledge/validate_desired_state_use_case.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"
MANIFEST="${SANDRA_RUN_DIR}/candidate-manifest.json"

for required_file in \
    "${STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${POLICY_CONTRACT}" \
    "${POLICY_VALIDATOR}" \
    "${POLICY_ADR}" \
    "${POLICY_TYPES}" \
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
    "${RESOURCE_GRAPH_VALIDATOR}" \
    "${DESIRED_STATE_CONTRACT}" \
    "${DESIRED_STATE_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

cat > "${MANIFEST}" <<'JSON'
{
  "sourceGate": "R3-000015A",
  "baseHead": "82452d128be1b9a88e98f0f6659dd6a0fd90b5c4",
  "files": [
    {
      "category": "modified",
      "path": "src/sandra/application/__init__.py",
      "sha256": "ffd010abb7d603e3c1233509071d6581d4d93d6c65f4aa00fbce300a30a87a2e"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/inbound/__init__.py",
      "sha256": "95be1764ec7feeb870d80e7de653fb3c43dfd0d202a63dff7c8c674f52700321"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/outbound/__init__.py",
      "sha256": "36e8171d0c40d20612baa7ed4bfde6d7e15de842c2f8a5c63a14f197e878cc8f"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/use_cases/__init__.py",
      "sha256": "026854b8fba54da2a4ea2cb507b64e1069f1a3e5650175cb872960eb922527ef"
    },
    {
      "category": "untracked",
      "path": "docs/adr/ADR-0015-POLICY-DECISION-USE-CASE.md",
      "sha256": "1d69dc7a7daec162ee5ca0f27ba27862fcbbe3bc8411e9198bd9121a0487338e"
    },
    {
      "category": "untracked",
      "path": "docs/contracts/application/POLICY-DECISION-USE-CASE-V1.json",
      "sha256": "f8563c25e426a1bc956212c638f9c050d637fbd264f21f559e65ad33fd568e5a"
    },
    {
      "category": "untracked",
      "path": "src/knowledge/validate_policy_decision_use_case.py",
      "sha256": "29e5f8fad22ca6a8051ecae401a90c95a8b90a3b8e3b3d68413543cc8297d09e"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/policy_decision.py",
      "sha256": "173570861375900d89452543be86c63cf09d6772d281b87430e6b45c9f2b07c8"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/inbound/policy_decision.py",
      "sha256": "9acd854695d3ce0364d69722e8365f0861d1c7c5594873e91e994880498c263c"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/outbound/policy_decision_evaluator.py",
      "sha256": "c9bd1db6b38af21eb65fbac50fddf500eb29ccf9a6e09e57944ea0d89e1e4e56"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/use_cases/evaluate_policy_decision.py",
      "sha256": "63f0a3290b6205072eefb4fc347cd7f4afbd328a0ea27c9f498bfe4b1e101c57"
    },
    {
      "category": "untracked",
      "path": "tests/contract/application/test_policy_decision_use_case.py",
      "sha256": "a6cd8b736d1697b3b11e906bc06d90f50cd42f8896c8f1b696dca3f6685f023f"
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
    Path(sys.argv[2]).read_text(encoding="utf-8")
)
evidence = Path(sys.argv[3])


def git_output(*arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout


def git_paths(*arguments: str) -> set[str]:
    return {
        line.strip()
        for line in git_output(*arguments).splitlines()
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
        actual_modified == expected_modified
    ),
    "untracked_set_matches_manifest": (
        actual_untracked == expected_untracked
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
    for name, passed in sorted(checks.items())
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
        "POLICY_DECISION_CANDIDATE_PREFLIGHT_FAILED:"
        + ",".join(failed)
    )

print("POLICY_DECISION_CANDIDATE_PREFLIGHT=PASS")
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
    Path(sys.argv[2]).read_text(encoding="utf-8")
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

if (root / "ROADMAP_STATE.json").is_file():
    additional.add(
        "ROADMAP_STATE.json"
    )

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

print("POLICY_DECISION_BACKUP=PASS")
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
    > "${SANDRA_EVIDENCE_DIR}/desired-state-precheck.txt"

grep -q \
    '^DESIRED_STATE_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/desired-state-precheck.txt"

python3 \
    "${POLICY_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${POLICY_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/policy-candidate-validation.txt"

grep -q \
    '^POLICY_DECISION_USE_CASE_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/policy-candidate-validation.txt"

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

if count < 47:
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
    "${POLICY_CONTRACT}" \
    "${POLICY_ADR}" \
    "${POLICY_VALIDATOR}" <<'PYTHON'
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
        "POLICY_CONTRACT_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "POLICY_CONTRACT_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000015B"

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

Candidate generated by R3-000015A.

Publication and immutable certification are reserved for R3-000015B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by R3-000015A, verified against its exact exported
manifest and published by R3-000015B.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "POLICY_ADR_STATUS_MARKER_INVALID"
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
        '        "POLICY_DECISION_USE_CASE_CANDIDATE=PASS"\n'
        '    )',
        'print(\n'
        '        "POLICY_DECISION_USE_CASE=PASS"\n'
        '    )',
    ),
)

for old, new in replacements:
    count = validator.count(old)

    if count != 1:
        raise SystemExit(
            "POLICY_VALIDATOR_MARKER_INVALID:"
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

print("POLICY_DECISION_PUBLICATION_PATCH=PASS")
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
    "EvaluatePolicyDecisionPort",
    "inboundPorts",
)

append_once(
    outbound,
    "PolicyDecisionEvaluator",
    "outboundPorts",
)

append_once(
    use_cases,
    "EvaluatePolicyDecision",
    "concreteUseCases",
)

metadata["revision"] = 6

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
    '    "policy_decision.py",\n'
    '    "ports/inbound/policy_decision.py",\n'
    '    "ports/outbound/policy_decision_evaluator.py",\n'
    '    "use_cases/evaluate_policy_decision.py",\n'
)

if '"policy_decision.py"' not in validator:
    marker = (
        '    "use_cases/declare_desired_state.py",\n'
        '}'
    )

    replacement = (
        '    "use_cases/declare_desired_state.py",\n'
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
    "APPLICATION_PYTHON_FILE_COUNT": 34,
    "INBOUND_PORT_COUNT": 7,
    "OUTBOUND_PORT_COUNT": 8,
    "CONCRETE_USE_CASE_COUNT": 5,
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
    "${POLICY_VALIDATOR}"

python3 \
    "${POLICY_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${POLICY_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/published-policy-validation.txt"

grep -q \
    '^POLICY_DECISION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-policy-validation.txt"

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
    "${ROADMAP_STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
from __future__ import annotations

import datetime
import json
from pathlib import Path
import sys


state_path = Path(sys.argv[1])
roadmap_state_path = Path(sys.argv[2])
runbook_id = sys.argv[3]
run_id = sys.argv[4]
journal = sys.argv[5]

state = json.loads(
    state_path.read_text(
        encoding="utf-8"
    )
)

foundation = state["spec"].get(
    "application_foundation"
)

desired_state = state["spec"].get(
    "desired_state_use_case"
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

if not isinstance(desired_state, dict):
    raise SystemExit(
        "DESIRED_STATE_USE_CASE_STATE_MISSING"
    )

if desired_state.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "DESIRED_STATE_USE_CASE_NOT_CERTIFIED"
    )

timestamp = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["metadata"]["state_version"] = "5.5.0"
state["metadata"]["updated_utc"] = timestamp

foundation["revision"] = 6
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
    "QueryResourceGraphPort",
    "DeclareDesiredStatePort",
    "EvaluatePolicyDecisionPort",
]
foundation["outbound_ports"] = [
    "Repository",
    "EventBus",
    "UnitOfWork",
    "ObservationSource",
    "EvidenceQualifier",
    "ResourceGraphReader",
    "DesiredStateRepository",
    "PolicyDecisionEvaluator",
]
foundation["concrete_use_cases"] = 5

state["spec"]["policy_decision_use_case"] = {
    "version": "1.0.0",
    "id": "policy-decision-use-case-v1",
    "status": "certified_immutable",
    "capability": "policy_decision",
    "inbound_port": "EvaluatePolicyDecisionPort",
    "outbound_port": "PolicyDecisionEvaluator",
    "use_case": "EvaluatePolicyDecision",
    "request": "PolicyDecisionRequest",
    "result": "ApplicationResult[PolicyDecisionResult]",
    "contract": (
        "docs/contracts/application/"
        "POLICY-DECISION-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_policy_decision_use_case.py"
    ),
    "effects": [
        "allow",
        "deny",
        "conditional",
    ],
    "candidate_gate": "R3-000015A",
    "publication_gate": "R3-000015B",
    "candidate_hash_count": 12,
    "approval_requirement": "explicit",
    "decision_expiry": "required",
    "deep_immutability": "pass",
    "execution": "none",
    "transport": "none",
    "verification": "none",
    "planning": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000015B",
    "title": (
        "Policy Decision Use Case "
        "Foundation Publication"
    ),
    "type": (
        "application_vertical_contract_publication"
    ),
    "targets": [
        "PolicyDecisionEffect",
        "PolicyDecisionRequest",
        "PolicyDecisionResult",
        "EvaluatePolicyDecisionPort",
        "PolicyDecisionEvaluator",
        "EvaluatePolicyDecision",
        "Application Ports Foundation revision 6",
        "ROADMAP_STATE.json",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "execution",
        "transport",
        "verification",
        "planning",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact R3-000015A candidate",
        "publish immutable Policy Decision contracts",
        "preserve canonical capability policy_decision",
        "register explicit allow deny and conditional outcomes",
        "create persistent cross-chat roadmap handover",
    ],
    "prohibitions": [
        "no execution",
        "no transport",
        "no postcondition verification",
        "no execution-plan creation",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000016",
    "title": "Planning Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Policy Decision Use Case Foundation"
    ),
    "current_gate": "R3-000015B",
    "current_gate_status": "complete",
    "next_gate": "R3-000016",
}

state["status"]["policy_decision_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000015A",
    "publication_gate": "R3-000015B",
    "candidate_manifest": "pass",
    "candidate_hash_count": 12,
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 6,
    "approval_requirement": "explicit",
    "decision_expiry": "required",
    "deep_immutability": "pass",
    "execution": "none",
    "transport": "none",
    "verification": "none",
    "planning": "none",
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

roadmap_state = {
    "apiVersion": "roadmap.sandra.io/v1",
    "kind": "RoadmapState",
    "metadata": {
        "updatedUtc": timestamp,
        "sourceStateVersion": "5.5.0",
        "publishedBy": "R3-000015B",
    },
    "spec": {
        "project": "SANDRA",
        "mode": "FAST_SAFE_MODE",
        "lastPublishedGate": "R3-000015B",
        "currentGate": "R3-000015B",
        "currentGateStatus": "complete",
        "nextGate": "R3-000016",
        "nextGateTitle": "Planning Use Case Foundation",
        "applicationFoundationRevision": 6,
        "workflow": [
            "audit when uncertainty exists",
            "discovery when canonical identity is unknown",
            "candidate",
            "publication",
            "verification",
        ],
        "deliveryRules": [
            "Italian dialogue",
            "single complete ready-paste bash blocks",
            "timestamped backup before repository changes",
            "no manual patch fragments",
            "audit first for architectural uncertainty",
            "no duplicate capability or organ",
            "candidate publication must verify exact SHA256 manifest",
            "automatic Mac export when the configured passwordless export mechanism is available",
        ],
        "publishedVerticals": [
            "application_foundation",
            "observation",
            "evidence_qualification",
            "resource_graph",
            "desired_state",
            "policy_decision",
        ],
        "remainingVerticals": [
            "planning",
            "execution",
            "verification",
        ],
        "completion": {
            "perceptionDecisionBlockPercent": 100.0,
            "extendedAutonomyRoadmapPercent": 62.5,
        },
        "nextChatInstruction": (
            "Read ROADMAP_STATE.json and STATE.json, "
            "verify repository HEAD and continue from nextGate."
        ),
    },
}

roadmap_state_path.write_text(
    json.dumps(
        roadmap_state,
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
# ${SANDRA_RUNBOOK_ID} — Policy Decision publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000015A\`
- Publication gate: \`R3-000015B\`
- Candidate files verified by SHA256: \`12\`
- Application Foundation revision: \`6\`
- Canonical capability: \`policy_decision\`
- Effects: \`allow, deny, conditional\`
- Approval requirement: \`EXPLICIT\`
- Decision expiry: \`REQUIRED\`
- Deep immutability: \`PASS\`
- Execution: \`NONE\`
- Transport: \`NONE\`
- Verification: \`NONE\`
- Planning: \`NONE\`
- ROADMAP_STATE.json: \`CREATED\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact R3-000015A candidate working tree;
- verified SHA256 for all twelve candidate files;
- passed all upstream Application validators;
- passed Application and Domain tests before publication;
- promoted the Policy Decision contract to immutable;
- promoted ADR-0015 to accepted and immutable;
- updated the permanent Policy Decision validator;
- updated Application Ports Foundation to revision 6;
- registered Policy Decision in STATE;
- created persistent ROADMAP_STATE.json for cross-chat continuity;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Policy Decision Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${POLICY_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${POLICY_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/policy-post-sync.txt"

grep -q \
    '^POLICY_DECISION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/policy-post-sync.txt"

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
    "${ROADMAP_STATE}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
roadmap_state_path = Path(sys.argv[2])
evidence = Path(sys.argv[3])


def command(*arguments: str) -> str:
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
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

roadmap = json.loads(
    roadmap_state_path.read_text(
        encoding="utf-8"
    )
)

checks = {
    "working_tree_clean": (
        status.strip() == ""
    ),
    "head_matches_origin": (
        head == origin
    ),
    "roadmap_state_kind": (
        roadmap.get("kind")
        == "RoadmapState"
    ),
    "roadmap_next_gate": (
        roadmap.get(
            "spec",
            {},
        ).get("nextGate")
        == "R3-000016"
    ),
    "roadmap_fast_safe_mode": (
        roadmap.get(
            "spec",
            {},
        ).get("mode")
        == "FAST_SAFE_MODE"
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
    printf 'R3_000015B=PASS\n'
    printf 'POLICY_DECISION_USE_CASE=PASS\n'
    printf 'POLICY_DECISION_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000015A\n'
    printf 'PUBLICATION_GATE=R3-000015B\n'
    printf 'CANDIDATE_HASH_COUNT=12\n'
    printf 'APPLICATION_FOUNDATION_REVISION=6\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=34\n'
    printf 'INBOUND_PORT_COUNT=7\n'
    printf 'OUTBOUND_PORT_COUNT=8\n'
    printf 'CONCRETE_USE_CASE_COUNT=5\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'APPROVAL_REQUIREMENT=EXPLICIT\n'
    printf 'DECISION_EXPIRY=REQUIRED\n'
    printf 'DEEP_IMMUTABILITY=PASS\n'
    printf 'EXECUTION=NONE\n'
    printf 'TRANSPORT=NONE\n'
    printf 'VERIFICATION=NONE\n'
    printf 'PLANNING=NONE\n'
    printf 'ROADMAP_STATE=CREATED\n'
    printf 'NEXT_GATE=R3-000016\n'
    printf 'PERCEPTION_DECISION_BLOCK_PERCENT=100.0\n'
    printf 'EXTENDED_AUTONOMY_ROADMAP_PERCENT=62.5\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'ROADMAP_STATE_SHA256=%s\n' \
        "$(sha256sum "${ROADMAP_STATE}" | awk '{print $1}')"
    printf 'POLICY_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${POLICY_CONTRACT}" | awk '{print $1}')"
    printf 'POLICY_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${POLICY_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
