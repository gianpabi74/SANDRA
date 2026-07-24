#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000016B-planning-publication.sh"

sandra_begin \
    "R3-000016B" \
    "Validate and publish Planning Use Case Foundation"

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

PLANNING_CONTRACT="${ROOT}/docs/contracts/application/PLANNING-USE-CASE-V1.json"
PLANNING_VALIDATOR="${ROOT}/src/knowledge/validate_planning_use_case.py"
PLANNING_ADR="${ROOT}/docs/adr/ADR-0016-PLANNING-USE-CASE.md"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

POLICY_CONTRACT="${ROOT}/docs/contracts/application/POLICY-DECISION-USE-CASE-V1.json"
POLICY_VALIDATOR="${ROOT}/src/knowledge/validate_policy_decision_use_case.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"
MANIFEST="${SANDRA_RUN_DIR}/candidate-manifest.json"

for required_file in \
    "${STATE}" \
    "${ROADMAP_STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${PLANNING_CONTRACT}" \
    "${PLANNING_VALIDATOR}" \
    "${PLANNING_ADR}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${POLICY_CONTRACT}" \
    "${POLICY_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

cat > "${MANIFEST}" <<'JSON'
{
  "sourceGate": "R3-000016A",
  "baseHead": "39f6e0f9ee752f50552c96019b71bd87bbaa24da",
  "files": [
    {
      "category": "modified",
      "path": "src/sandra/application/__init__.py",
      "sha256": "1b741e9d98d12bb73cdcf804e84da3f499640dc896ea61f6fb7ec5ef19c35aae"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/inbound/__init__.py",
      "sha256": "2c029c289ff9aa8030dba7d284a1f2d8d8391c13a354c871a9a2fc9b1cb87b5f"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/ports/outbound/__init__.py",
      "sha256": "0c52873806b61e9d5dc42d6559dd1ca1ac32121a5b7a7feef3120532b0b1b248"
    },
    {
      "category": "modified",
      "path": "src/sandra/application/use_cases/__init__.py",
      "sha256": "0008c16b7abc57a03d21e7deaae7356bfaa9edaba0f7c893db902932bfe6d412"
    },
    {
      "category": "untracked",
      "path": "docs/adr/ADR-0016-PLANNING-USE-CASE.md",
      "sha256": "7bf0fd6925864540022b0e6cc6170f1700d9b53271e9163863a1c409936e1090"
    },
    {
      "category": "untracked",
      "path": "docs/contracts/application/PLANNING-USE-CASE-V1.json",
      "sha256": "e3cb028356ee9c8c23ac42c78bb893a303e22e5eb21f8c2d8f6ff8438c3e6580"
    },
    {
      "category": "untracked",
      "path": "src/knowledge/validate_planning_use_case.py",
      "sha256": "ff26ba20b95b53d29b6b2e7b5839c21c23dc72deee6ab68d2fcb2404b6f56a58"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/planning.py",
      "sha256": "dded34b8ae4c15ce957564bd58b2997e56209876a5224e9c62ed828fe9881e23"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/inbound/planning.py",
      "sha256": "3995812868bcbd92f6e1dc52184b22b551593b12d796c3e7bf15b5432fe1c79b"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/ports/outbound/plan_composer.py",
      "sha256": "8b68c4a64283cedbb0194a04c54bc8d20fae0345c6988b903f32ff07df9ee2a2"
    },
    {
      "category": "untracked",
      "path": "src/sandra/application/use_cases/build_execution_plan.py",
      "sha256": "9b9d9cf602af9444018b8240cc09387844456bc681863e1ecbf569f3f80c652a"
    },
    {
      "category": "untracked",
      "path": "tests/contract/application/test_planning_use_case.py",
      "sha256": "ca25ec7cdf0430a4200db28e91857bebb5ee106f94b00c31c5d7e35c139b32ee"
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


def git_output(
    *arguments: str,
) -> str:
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


def git_paths(
    *arguments: str,
) -> set[str]:
    return {
        line.strip()
        for line in git_output(
            *arguments
        ).splitlines()
        if line.strip()
    }


def sha256(
    path: Path,
) -> str:
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

for item in manifest["files"]:
    relative = item["path"]
    path = root / relative

    if not path.is_file():
        hash_errors.append(
            f"MISSING:{relative}"
        )
        continue

    actual_hash = sha256(path)

    if actual_hash != item["sha256"]:
        hash_errors.append(
            f"HASH:{relative}:{actual_hash}"
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
        "PLANNING_CANDIDATE_PREFLIGHT_FAILED:"
        + ",".join(failed)
    )

print("PLANNING_CANDIDATE_PREFLIGHT=PASS")
print("CANDIDATE_FILE_COUNT=12")
PYTHON

install -d -m 0700 \
    "${BACKUP_ROOT}"

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
    "ROADMAP_STATE.json",
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

print("PLANNING_BACKUP=PASS")
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
    "${POLICY_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${POLICY_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/policy-precheck.txt"

grep -q \
    '^POLICY_DECISION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/policy-precheck.txt"

python3 \
    "${PLANNING_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${PLANNING_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/planning-candidate-validation.txt"

grep -q \
    '^PLANNING_USE_CASE_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/planning-candidate-validation.txt"

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

if count < 56:
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
    "${PLANNING_CONTRACT}" \
    "${PLANNING_ADR}" \
    "${PLANNING_VALIDATOR}" <<'PYTHON'
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
        "PLANNING_CONTRACT_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "PLANNING_CONTRACT_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000016B"

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

Candidate generated by R3-000016A.

Publication and immutable certification are reserved for R3-000016B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by R3-000016A, verified against its exact exported
manifest and published by R3-000016B.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "PLANNING_ADR_STATUS_MARKER_INVALID"
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
        '        "PLANNING_USE_CASE_CANDIDATE=PASS"\n'
        '    )',
        'print(\n'
        '        "PLANNING_USE_CASE=PASS"\n'
        '    )',
    ),
)

for old, new in replacements:
    count = validator.count(old)

    if count != 1:
        raise SystemExit(
            "PLANNING_VALIDATOR_MARKER_INVALID:"
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

print("PLANNING_PUBLICATION_PATCH=PASS")
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
    "BuildExecutionPlanPort",
    "inboundPorts",
)

append_once(
    outbound,
    "PlanComposer",
    "outboundPorts",
)

append_once(
    use_cases,
    "BuildExecutionPlan",
    "concreteUseCases",
)

metadata["revision"] = 7

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
    '    "planning.py",\n'
    '    "ports/inbound/planning.py",\n'
    '    "ports/outbound/plan_composer.py",\n'
    '    "use_cases/build_execution_plan.py",\n'
)

if '"planning.py"' not in validator:
    marker = (
        '    "use_cases/evaluate_policy_decision.py",\n'
        '}'
    )

    replacement = (
        '    "use_cases/evaluate_policy_decision.py",\n'
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
    "APPLICATION_PYTHON_FILE_COUNT": 38,
    "INBOUND_PORT_COUNT": 8,
    "OUTBOUND_PORT_COUNT": 9,
    "CONCRETE_USE_CASE_COUNT": 6,
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
    "${PLANNING_VALIDATOR}"

python3 \
    "${PLANNING_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${PLANNING_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/published-planning-validation.txt"

grep -q \
    '^PLANNING_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-planning-validation.txt"

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

roadmap_state = json.loads(
    roadmap_state_path.read_text(
        encoding="utf-8"
    )
)

foundation = state.get(
    "spec",
    {},
).get(
    "application_foundation"
)

policy_decision = state.get(
    "spec",
    {},
).get(
    "policy_decision_use_case"
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
    policy_decision,
    dict,
):
    raise SystemExit(
        "POLICY_DECISION_STATE_MISSING"
    )

if policy_decision.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "POLICY_DECISION_NOT_CERTIFIED"
    )

timestamp = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["metadata"]["state_version"] = "5.6.0"
state["metadata"]["updated_utc"] = timestamp

foundation["revision"] = 7
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
    "QueryResourceGraphPort",
    "DeclareDesiredStatePort",
    "EvaluatePolicyDecisionPort",
    "BuildExecutionPlanPort",
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
    "PlanComposer",
]
foundation["concrete_use_cases"] = 6

state["spec"]["planning_use_case"] = {
    "version": "1.0.0",
    "id": "planning-use-case-v1",
    "status": "certified_immutable",
    "capability": "planning",
    "inbound_port": "BuildExecutionPlanPort",
    "outbound_port": "PlanComposer",
    "use_case": "BuildExecutionPlan",
    "request": "PlanningRequest",
    "result": "ApplicationResult[PlanningResult]",
    "domain_resource": "ExecutionPlan",
    "contract": (
        "docs/contracts/application/"
        "PLANNING-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_planning_use_case.py"
    ),
    "owns": [
        "preconditions",
        "ordered actions",
        "postconditions",
        "recovery",
        "execution limits",
    ],
    "excludes": [
        "action execution",
        "technology calls",
        "policy evaluation",
    ],
    "candidate_gate": "R3-000016A",
    "publication_gate": "R3-000016B",
    "candidate_hash_count": 12,
    "domain_execution_plan_reuse": "pass",
    "action_execution": "none",
    "technology_calls": "none",
    "policy_evaluation": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000016B",
    "title": (
        "Planning Use Case "
        "Foundation Publication"
    ),
    "type": (
        "application_vertical_contract_publication"
    ),
    "targets": [
        "PlanningRequest",
        "PlanStep",
        "PlanningResult",
        "BuildExecutionPlanPort",
        "PlanComposer",
        "BuildExecutionPlan",
        "Application Ports Foundation revision 7",
        "ROADMAP_STATE.json",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "action execution",
        "technology calls",
        "policy evaluation",
        "verification",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact R3-000016A candidate",
        "publish immutable Planning contracts",
        "reuse the canonical ExecutionPlan Domain resource",
        "preserve ordered actions and dependency constraints",
        "advance the autonomy roadmap to Execution",
    ],
    "prohibitions": [
        "no action execution",
        "no technology adapter calls",
        "no policy reevaluation",
        "no postcondition verification",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000017",
    "title": "Execution Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Planning Use Case Foundation"
    ),
    "current_gate": "R3-000016B",
    "current_gate_status": "complete",
    "next_gate": "R3-000017",
}

state["status"]["planning_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000016A",
    "publication_gate": "R3-000016B",
    "candidate_manifest": "pass",
    "candidate_hash_count": 12,
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 7,
    "domain_execution_plan_reuse": "pass",
    "action_execution": "none",
    "technology_calls": "none",
    "policy_evaluation": "none",
    "verification": "none",
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

roadmap_spec = roadmap_state.get(
    "spec",
    {},
)

roadmap_state["metadata"][
    "updatedUtc"
] = timestamp

roadmap_state["metadata"][
    "sourceStateVersion"
] = "5.6.0"

roadmap_state["metadata"][
    "publishedBy"
] = "R3-000016B"

roadmap_spec[
    "lastPublishedGate"
] = "R3-000016B"

roadmap_spec[
    "currentGate"
] = "R3-000016B"

roadmap_spec[
    "currentGateStatus"
] = "complete"

roadmap_spec[
    "nextGate"
] = "R3-000017"

roadmap_spec[
    "nextGateTitle"
] = "Execution Use Case Foundation"

roadmap_spec[
    "applicationFoundationRevision"
] = 7

published = roadmap_spec.get(
    "publishedVerticals",
    [],
)

if "planning" not in published:
    published.append("planning")

roadmap_spec[
    "publishedVerticals"
] = published

roadmap_spec[
    "remainingVerticals"
] = [
    "execution",
    "verification",
]

roadmap_spec[
    "completion"
] = {
    "perceptionDecisionBlockPercent": 100.0,
    "extendedAutonomyRoadmapPercent": 75.0,
}

roadmap_spec[
    "nextChatInstruction"
] = (
    "Read ROADMAP_STATE.json and STATE.json, "
    "verify repository HEAD and continue from "
    "R3-000017."
)

roadmap_state["spec"] = roadmap_spec

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
# ${SANDRA_RUNBOOK_ID} — Planning publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000016A\`
- Publication gate: \`R3-000016B\`
- Candidate files verified by SHA256: \`12\`
- Application Foundation revision: \`7\`
- Canonical capability: \`planning\`
- Domain ExecutionPlan reuse: \`PASS\`
- Action execution: \`NONE\`
- Technology calls: \`NONE\`
- Policy evaluation: \`NONE\`
- Verification: \`NONE\`
- Extended autonomy roadmap: \`75.0%\`
- Next gate: \`R3-000017\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact R3-000016A candidate working tree;
- verified SHA256 for all twelve candidate files;
- passed Architecture, constitutional, capability and Policy Decision validation;
- passed Application and Domain tests before publication;
- promoted the Planning contract to immutable;
- promoted ADR-0016 to accepted and immutable;
- updated the permanent Planning validator;
- updated Application Ports Foundation to revision 7;
- registered Planning in STATE;
- advanced ROADMAP_STATE to R3-000017;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Planning Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${PLANNING_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${PLANNING_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/planning-post-sync.txt"

grep -q \
    '^PLANNING_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/planning-post-sync.txt"

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
    "${STATE}" \
    "${ROADMAP_STATE}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
state_path = Path(sys.argv[2])
roadmap_path = Path(sys.argv[3])
evidence = Path(sys.argv[4])


def command(
    *arguments: str,
) -> str:
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

state = json.loads(
    state_path.read_text(
        encoding="utf-8"
    )
)

roadmap = json.loads(
    roadmap_path.read_text(
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
    "state_version_is_5_6_0": (
        state.get(
            "metadata",
            {},
        ).get("state_version")
        == "5.6.0"
    ),
    "planning_state_certified": (
        state.get(
            "spec",
            {},
        ).get(
            "planning_use_case",
            {},
        ).get("status")
        == "certified_immutable"
    ),
    "roadmap_fast_safe_mode": (
        roadmap.get(
            "spec",
            {},
        ).get("mode")
        == "FAST_SAFE_MODE"
    ),
    "roadmap_next_gate_is_r3_000017": (
        roadmap.get(
            "spec",
            {},
        ).get("nextGate")
        == "R3-000017"
    ),
    "roadmap_completion_is_75": (
        roadmap.get(
            "spec",
            {},
        ).get(
            "completion",
            {},
        ).get(
            "extendedAutonomyRoadmapPercent"
        )
        == 75.0
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
    printf 'R3_000016B=PASS\n'
    printf 'PLANNING_USE_CASE=PASS\n'
    printf 'PLANNING_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000016A\n'
    printf 'PUBLICATION_GATE=R3-000016B\n'
    printf 'CANDIDATE_HASH_COUNT=12\n'
    printf 'APPLICATION_FOUNDATION_REVISION=7\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=38\n'
    printf 'INBOUND_PORT_COUNT=8\n'
    printf 'OUTBOUND_PORT_COUNT=9\n'
    printf 'CONCRETE_USE_CASE_COUNT=6\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'DOMAIN_EXECUTION_PLAN_REUSE=PASS\n'
    printf 'ACTION_EXECUTION=NONE\n'
    printf 'TECHNOLOGY_CALLS=NONE\n'
    printf 'POLICY_EVALUATION=NONE\n'
    printf 'VERIFICATION=NONE\n'
    printf 'ROADMAP_STATE=UPDATED\n'
    printf 'NEXT_GATE=R3-000017\n'
    printf 'PERCEPTION_DECISION_BLOCK_PERCENT=100.0\n'
    printf 'EXTENDED_AUTONOMY_ROADMAP_PERCENT=75.0\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'ROADMAP_STATE_SHA256=%s\n' \
        "$(sha256sum "${ROADMAP_STATE}" | awk '{print $1}')"
    printf 'PLANNING_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${PLANNING_CONTRACT}" | awk '{print $1}')"
    printf 'PLANNING_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${PLANNING_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
