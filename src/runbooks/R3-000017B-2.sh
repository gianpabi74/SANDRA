#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000017B-2-execution-publication.sh"

sandra_begin \
    "R3-000017B-2" \
    "Publish immutable Execution Use Case Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
EXPECTED_HEAD="3420ae3bf26e14b920e4298dae7c169e2e300ebd"

STATE="${ROOT}/STATE.json"
ROADMAP_STATE="${ROOT}/ROADMAP_STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
APPLICATION_TEST_ROOT="${ROOT}/tests/contract/application"
DOMAIN_ROOT="${ROOT}/src/sandra/domain"
DOMAIN_TEST_ROOT="${ROOT}/tests/unit/domain"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

FOUNDATION_CONTRACT="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
FOUNDATION_VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"

EXECUTION_CONTRACT="${ROOT}/docs/contracts/application/EXECUTION-USE-CASE-V1.json"
EXECUTION_VALIDATOR="${ROOT}/src/knowledge/validate_execution_use_case.py"
EXECUTION_ADR="${ROOT}/docs/adr/ADR-0017-EXECUTION-USE-CASE.md"

PLANNING_CONTRACT="${ROOT}/docs/contracts/application/PLANNING-USE-CASE-V1.json"
PLANNING_VALIDATOR="${ROOT}/src/knowledge/validate_planning_use_case.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

EXECUTION_SAFETY="${ROOT}/docs/contracts/constitutional/EXECUTION-SAFETY-CONTRACT-V1.json"

CONTINUITY_ROOT="/root/.sandra-r3-000017b"
FREEZE_STATE="${CONTINUITY_ROOT}/PART-1.json"
PUBLICATION_STATE="${CONTINUITY_ROOT}/PART-2.json"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

for required_file in \
    "${STATE}" \
    "${ROADMAP_STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${EXECUTION_CONTRACT}" \
    "${EXECUTION_VALIDATOR}" \
    "${EXECUTION_ADR}" \
    "${PLANNING_CONTRACT}" \
    "${PLANNING_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}" \
    "${EXECUTION_SAFETY}" \
    "${FREEZE_STATE}"
do
    sandra_require_file "${required_file}"
done

if [[ -e "${PUBLICATION_STATE}" || -L "${PUBLICATION_STATE}" ]]; then
    sandra_fail \
        "R3-000017B-2 publication state already exists"
fi

CURRENT_HEAD="$(
    git -C "${ROOT}" rev-parse HEAD
)"

CURRENT_ORIGIN="$(
    git -C "${ROOT}" rev-parse origin/main
)"

if [[ "${CURRENT_HEAD}" != "${EXPECTED_HEAD}" ]]; then
    sandra_fail \
        "Unexpected repository HEAD: ${CURRENT_HEAD}"
fi

if [[ "${CURRENT_HEAD}" != "${CURRENT_ORIGIN}" ]]; then
    sandra_fail \
        "Repository HEAD does not match origin/main"
fi

python3 - \
    "${ROOT}" \
    "${FREEZE_STATE}" \
    "${EXPECTED_HEAD}" \
    "${SANDRA_EVIDENCE_DIR}/freeze-precheck.txt" <<'PYTHON'
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
freeze_path = Path(sys.argv[2])
expected_head = sys.argv[3]
evidence_path = Path(sys.argv[4])

freeze = json.loads(
    freeze_path.read_text(
        encoding="utf-8"
    )
)


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


metadata = freeze.get(
    "metadata",
    {},
)

status = freeze.get(
    "status",
    {},
)

files = status.get(
    "files",
    [],
)

expected_modified = {
    record["path"]
    for record in files
    if record.get("category")
    == "modified"
}

expected_untracked = {
    record["path"]
    for record in files
    if record.get("category")
    == "untracked"
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

for record in files:
    relative = record.get("path")
    expected_hash = record.get("sha256")

    if not isinstance(relative, str):
        hash_errors.append(
            "INVALID_PATH_RECORD"
        )
        continue

    path = root / relative

    if not path.is_file():
        hash_errors.append(
            f"MISSING:{relative}"
        )
        continue

    actual_hash = sha256(path)

    if actual_hash != expected_hash:
        hash_errors.append(
            f"HASH:{relative}:{actual_hash}"
        )

checks = {
    "freeze_part_is_1": (
        metadata.get("part")
        == "1"
    ),
    "freeze_complete": (
        metadata.get("status")
        == "complete"
    ),
    "freeze_source_gate_is_r3_000017a": (
        status.get("sourceGate")
        == "R3-000017A"
    ),
    "freeze_base_head_matches": (
        status.get("baseHead")
        == expected_head
    ),
    "candidate_file_count_is_12": (
        status.get("candidateFileCount")
        == 12
        and len(files) == 12
    ),
    "application_tests_passed": (
        status.get("applicationTests")
        == "pass"
    ),
    "domain_tests_passed": (
        status.get("domainTests")
        == "pass"
    ),
    "execution_validator_passed": (
        status.get("executionValidator")
        == "pass"
    ),
    "head_matches_expected": (
        head == expected_head
    ),
    "head_matches_origin": (
        head == origin
    ),
    "modified_set_matches_freeze": (
        actual_modified
        == expected_modified
    ),
    "untracked_set_matches_freeze": (
        actual_untracked
        == expected_untracked
    ),
    "staged_changes_absent": (
        not actual_staged
    ),
    "all_frozen_hashes_match": (
        not hash_errors
    ),
}

lines = [
    "EXECUTION_PUBLICATION_FREEZE_PRECHECK="
    + (
        "PASS"
        if all(checks.values())
        else "FAIL"
    )
]

lines.extend(
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(
        checks.items()
    )
)

lines.extend(
    f"ERROR={error}"
    for error in hash_errors
)

lines.extend(
    [
        f"HEAD={head}",
        f"ORIGIN_MAIN={origin}",
        (
            "MODIFIED_FILE_COUNT="
            + str(len(actual_modified))
        ),
        (
            "UNTRACKED_FILE_COUNT="
            + str(len(actual_untracked))
        ),
        (
            "STAGED_FILE_COUNT="
            + str(len(actual_staged))
        ),
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
        "EXECUTION_PUBLICATION_FREEZE_INVALID:"
        + ",".join(failed)
    )

print(
    "EXECUTION_PUBLICATION_FREEZE_PRECHECK=PASS"
)
PYTHON

grep -q \
    '^EXECUTION_PUBLICATION_FREEZE_PRECHECK=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/freeze-precheck.txt"

install -d -m 0700 \
    "${BACKUP_ROOT}"

for file in \
    "${STATE}" \
    "${ROADMAP_STATE}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${EXECUTION_CONTRACT}" \
    "${EXECUTION_VALIDATOR}" \
    "${EXECUTION_ADR}"
do
    relative="${file#${ROOT}/}"
    destination="${BACKUP_ROOT}/${relative}"

    install -d -m 0700 \
        "$(dirname "${destination}")"

    cp -a -- \
        "${file}" \
        "${destination}"
done

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
    "${PLANNING_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${PLANNING_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/planning-precheck.txt"

grep -q \
    '^PLANNING_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/planning-precheck.txt"

python3 \
    "${EXECUTION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${EXECUTION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    "${EXECUTION_SAFETY}" \
    > "${SANDRA_EVIDENCE_DIR}/execution-candidate-validation.txt"

grep -q \
    '^EXECUTION_USE_CASE_CANDIDATE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/execution-candidate-validation.txt"

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

if count < 66:
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
    "${EXECUTION_CONTRACT}" \
    "${EXECUTION_ADR}" \
    "${EXECUTION_VALIDATOR}" <<'PYTHON'
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

metadata = contract.get(
    "metadata"
)

if not isinstance(metadata, dict):
    raise SystemExit(
        "EXECUTION_CONTRACT_METADATA_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "EXECUTION_CONTRACT_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000017B-2"

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

Candidate generated by the staged R3-000017A sequence.

Publication and immutable certification are reserved for R3-000017B.
"""

new_status = """## Stato

Accepted and immutable.

Candidate generated by the staged R3-000017A sequence, independently frozen
by R3-000017B-1 and published by R3-000017B-2.
"""

if adr.count(old_status) != 1:
    raise SystemExit(
        "EXECUTION_ADR_STATUS_MARKER_INVALID"
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
        '        fail(\n'
        '            "STATUS_NOT_CANDIDATE"\n'
        '        )',
        'if metadata.get("status") != (\n'
        '        "immutable"\n'
        '    ):\n'
        '        fail(\n'
        '            "STATUS_NOT_IMMUTABLE"\n'
        '        )',
    ),
    (
        'print(\n'
        '        "EXECUTION_USE_CASE_CANDIDATE=PASS"\n'
        '    )',
        'print(\n'
        '        "EXECUTION_USE_CASE=PASS"\n'
        '    )',
    ),
)

for old, new in replacements:
    count = validator.count(old)

    if count != 1:
        raise SystemExit(
            "EXECUTION_VALIDATOR_MARKER_INVALID:"
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

print(
    "EXECUTION_PUBLICATION_PATCH=PASS"
)
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

metadata = contract.get(
    "metadata"
)

spec = contract.get(
    "spec"
)

if not isinstance(metadata, dict):
    raise SystemExit(
        "FOUNDATION_METADATA_INVALID"
    )

if not isinstance(spec, dict):
    raise SystemExit(
        "FOUNDATION_SPEC_INVALID"
    )

inbound = spec.get(
    "inboundPorts"
)

outbound = spec.get(
    "outboundPorts"
)

use_cases = spec.get(
    "concreteUseCases"
)

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
    "ExecutePlanPort",
    "inboundPorts",
)

append_once(
    outbound,
    "ExecutionEngine",
    "outboundPorts",
)

append_once(
    use_cases,
    "ExecutePlan",
    "concreteUseCases",
)

metadata["revision"] = 8

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
    '    "execution.py",\n'
    '    "ports/inbound/execution.py",\n'
    '    "ports/outbound/execution_engine.py",\n'
    '    "use_cases/execute_plan.py",\n'
)

if '"execution.py"' not in validator:
    marker = (
        '    "use_cases/build_execution_plan.py",\n'
        '}'
    )

    replacement = (
        '    "use_cases/build_execution_plan.py",\n'
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
    "APPLICATION_PYTHON_FILE_COUNT": 42,
    "INBOUND_PORT_COUNT": 9,
    "OUTBOUND_PORT_COUNT": 10,
    "CONCRETE_USE_CASE_COUNT": 7,
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

print(
    "APPLICATION_FOUNDATION_REVISION=PASS"
)
PYTHON

python3 -m compileall \
    -q \
    "${APPLICATION_ROOT}" \
    "${APPLICATION_TEST_ROOT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${EXECUTION_VALIDATOR}"

python3 \
    "${EXECUTION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${EXECUTION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    "${EXECUTION_SAFETY}" \
    > "${SANDRA_EVIDENCE_DIR}/execution-published-validation.txt"

grep -q \
    '^EXECUTION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/execution-published-validation.txt"

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
roadmap_path = Path(sys.argv[2])
runbook_id = sys.argv[3]
run_id = sys.argv[4]
journal = sys.argv[5]

state = json.loads(
    state_path.read_text(
        encoding="utf-8"
    )
)

roadmap_state = json.loads(
    roadmap_path.read_text(
        encoding="utf-8"
    )
)

foundation = state.get(
    "spec",
    {},
).get(
    "application_foundation"
)

planning = state.get(
    "spec",
    {},
).get(
    "planning_use_case"
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

if not isinstance(planning, dict):
    raise SystemExit(
        "PLANNING_USE_CASE_STATE_MISSING"
    )

if planning.get("status") != (
    "certified_immutable"
):
    raise SystemExit(
        "PLANNING_USE_CASE_NOT_CERTIFIED"
    )

timestamp = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["metadata"][
    "state_version"
] = "5.7.0"

state["metadata"][
    "updated_utc"
] = timestamp

foundation["revision"] = 8

foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
    "QualifyEvidencePort",
    "QueryResourceGraphPort",
    "DeclareDesiredStatePort",
    "EvaluatePolicyDecisionPort",
    "BuildExecutionPlanPort",
    "ExecutePlanPort",
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
    "ExecutionEngine",
]

foundation["concrete_use_cases"] = 7

state["spec"]["execution_use_case"] = {
    "version": "1.0.0",
    "id": "execution-use-case-v1",
    "status": "certified_immutable",
    "capability": "execution",
    "inbound_port": "ExecutePlanPort",
    "outbound_port": "ExecutionEngine",
    "use_case": "ExecutePlan",
    "request": "ExecutionRequest",
    "result": (
        "ApplicationResult[ExecutionResult]"
    ),
    "input_resource": "ExecutionPlan",
    "safety_contract": (
        "docs/contracts/constitutional/"
        "EXECUTION-SAFETY-CONTRACT-V1.json"
    ),
    "contract": (
        "docs/contracts/application/"
        "EXECUTION-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_execution_use_case.py"
    ),
    "owns": [
        "execution lifecycle",
        "idempotency",
        "bounded retry",
        "partial results",
        "recovery invocation",
    ],
    "excludes": [
        "policy decision",
        "plan creation",
        "verification conclusion",
    ],
    "candidate_gate": "R3-000017A",
    "freeze_gate": "R3-000017B-1",
    "publication_gate": "R3-000017B-2",
    "candidate_hash_count": 12,
    "execution_plan_reuse": "pass",
    "idempotency": "explicit",
    "bounded_retry": "pass",
    "partial_results": "explicit",
    "recovery_invocation": "explicit",
    "policy_decision": "not_evaluated",
    "plan_creation": "none",
    "verification_conclusion": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000017B-2",
    "title": (
        "Execution Use Case "
        "Foundation Publication"
    ),
    "type": (
        "application_vertical_contract_publication"
    ),
    "targets": [
        "ExecutionLifecycle",
        "ExecutionStepLifecycle",
        "ExecutionRequest",
        "ExecutionStepOutcome",
        "ExecutionResult",
        "ExecutePlanPort",
        "ExecutionEngine",
        "ExecutePlan",
        "Application Ports Foundation revision 8",
        "ROADMAP_STATE.json",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "policy decision",
        "plan creation",
        "verification conclusion",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "verify the exact frozen R3-000017A candidate",
        "publish immutable Execution contracts",
        "preserve bounded retry and idempotency",
        "preserve partial outcomes for Verification",
        "advance the autonomy roadmap to Verification",
    ],
    "prohibitions": [
        "no policy reevaluation",
        "no execution-plan creation",
        "no verification conclusion",
        "no direct technology-specific Application logic",
        "no uncontrolled retry",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000018",
    "title": (
        "Verification Use Case Foundation"
    ),
    "status": "blocked",
}

state["status"][
    "current_certification"
] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": (
        "Execution Use Case Foundation"
    ),
    "current_gate": "R3-000017B-2",
    "current_gate_status": "complete",
    "next_gate": "R3-000018",
}

state["status"][
    "execution_use_case_v1"
] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "candidate_gate": "R3-000017A",
    "freeze_gate": "R3-000017B-1",
    "publication_gate": "R3-000017B-2",
    "candidate_manifest": "pass",
    "candidate_hash_count": 12,
    "application_contract_tests": "pass",
    "domain_unit_tests": "pass",
    "application_foundation_revision": 8,
    "execution_plan_reuse": "pass",
    "idempotency": "explicit",
    "bounded_retry": "pass",
    "partial_results": "explicit",
    "recovery_invocation": "explicit",
    "policy_decision": "not_evaluated",
    "plan_creation": "none",
    "verification_conclusion": "none",
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
] = "5.7.0"

roadmap_state["metadata"][
    "publishedBy"
] = "R3-000017B-2"

roadmap_spec[
    "lastPublishedGate"
] = "R3-000017B-2"

roadmap_spec[
    "currentGate"
] = "R3-000017B-2"

roadmap_spec[
    "currentGateStatus"
] = "complete"

roadmap_spec[
    "nextGate"
] = "R3-000018"

roadmap_spec[
    "nextGateTitle"
] = "Verification Use Case Foundation"

roadmap_spec[
    "applicationFoundationRevision"
] = 8

published = roadmap_spec.get(
    "publishedVerticals",
    [],
)

if "execution" not in published:
    published.append(
        "execution"
    )

roadmap_spec[
    "publishedVerticals"
] = published

roadmap_spec[
    "remainingVerticals"
] = [
    "verification",
]

roadmap_spec[
    "completion"
] = {
    "perceptionDecisionBlockPercent": 100.0,
    "extendedAutonomyRoadmapPercent": 87.5,
}

roadmap_spec[
    "nextChatInstruction"
] = (
    "Read ROADMAP_STATE.json and STATE.json, "
    "verify repository HEAD and continue from "
    "R3-000018."
)

roadmap_state["spec"] = roadmap_spec

roadmap_path.write_text(
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
# ${SANDRA_RUNBOOK_ID} — Execution publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Candidate gate: \`R3-000017A\`
- Freeze gate: \`R3-000017B-1\`
- Publication gate: \`R3-000017B-2\`
- Candidate files verified by SHA256: \`12\`
- Application Foundation revision: \`8\`
- Canonical capability: \`execution\`
- ExecutionPlan reuse: \`PASS\`
- Idempotency: \`EXPLICIT\`
- Bounded retry: \`PASS\`
- Partial results: \`EXPLICIT\`
- Recovery invocation: \`EXPLICIT\`
- Policy Decision evaluation: \`NONE\`
- Plan creation: \`NONE\`
- Verification conclusion: \`NONE\`
- Extended autonomy roadmap: \`87.5%\`
- Next gate: \`R3-000018\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact frozen R3-000017A candidate;
- verified SHA256 for all twelve candidate files;
- passed Architecture, constitutional, capability and Planning validation;
- passed Application and Domain tests before publication;
- promoted the Execution contract to immutable;
- promoted ADR-0017 to accepted and immutable;
- updated the permanent Execution validator;
- updated Application Ports Foundation to revision 8;
- registered Execution in STATE;
- advanced ROADMAP_STATE to R3-000018;
- published and synchronized canonical Knowledge.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Execution Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${EXECUTION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${EXECUTION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    "${EXECUTION_SAFETY}" \
    > "${SANDRA_EVIDENCE_DIR}/execution-post-sync.txt"

grep -q \
    '^EXECUTION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/execution-post-sync.txt"

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
    "${PUBLICATION_STATE}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

import datetime
import json
from pathlib import Path
import subprocess
import sys


root = Path(sys.argv[1]).resolve()
state_path = Path(sys.argv[2])
roadmap_path = Path(sys.argv[3])
publication_path = Path(sys.argv[4])
evidence_path = Path(sys.argv[5])


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
    "state_version_is_5_7_0": (
        state.get(
            "metadata",
            {},
        ).get(
            "state_version"
        )
        == "5.7.0"
    ),
    "execution_state_certified": (
        state.get(
            "spec",
            {},
        ).get(
            "execution_use_case",
            {},
        ).get("status")
        == "certified_immutable"
    ),
    "foundation_revision_is_8": (
        state.get(
            "spec",
            {},
        ).get(
            "application_foundation",
            {},
        ).get("revision")
        == 8
    ),
    "roadmap_fast_safe_mode": (
        roadmap.get(
            "spec",
            {},
        ).get("mode")
        == "FAST_SAFE_MODE"
    ),
    "roadmap_next_gate_is_r3_000018": (
        roadmap.get(
            "spec",
            {},
        ).get("nextGate")
        == "R3-000018"
    ),
    "roadmap_completion_is_87_5": (
        roadmap.get(
            "spec",
            {},
        ).get(
            "completion",
            {},
        ).get(
            "extendedAutonomyRoadmapPercent"
        )
        == 87.5
    ),
}

publication_state = {
    "apiVersion": "audit.sandra.io/v1",
    "kind": "ExecutionPublicationState",
    "metadata": {
        "gate": "R3-000017B",
        "part": "2",
        "status": (
            "complete"
            if all(checks.values())
            else "invalid"
        ),
        "createdUtc": (
            datetime.datetime.now(
                datetime.timezone.utc
            )
            .replace(microsecond=0)
            .isoformat()
            .replace("+00:00", "Z")
        ),
    },
    "status": {
        "head": head,
        "originMain": origin,
        "checks": checks,
        "stateVersion": "5.7.0",
        "applicationFoundationRevision": 8,
        "nextGate": "R3-000018",
        "extendedAutonomyRoadmapPercent": 87.5,
    },
}

publication_path.write_text(
    json.dumps(
        publication_state,
        indent=2,
        ensure_ascii=False,
        sort_keys=True,
    )
    + "\n",
    encoding="utf-8",
)

lines = [
    "EXECUTION_PUBLICATION_POSTCHECK="
    + (
        "PASS"
        if all(checks.values())
        else "FAIL"
    )
]

lines.extend(
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(
        checks.items()
    )
)

lines.extend(
    [
        f"HEAD={head}",
        f"ORIGIN_MAIN={origin}",
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
        "EXECUTION_PUBLICATION_POSTCHECK_FAILED:"
        + ",".join(failed)
    )

print(
    "EXECUTION_PUBLICATION_POSTCHECK=PASS"
)
PYTHON

grep -q \
    '^EXECUTION_PUBLICATION_POSTCHECK=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt"

{
    printf 'R3_000017B=PASS\n'
    printf 'R3_000017B_PART_2=PASS\n'
    printf 'EXECUTION_USE_CASE=PASS\n'
    printf 'EXECUTION_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'CANDIDATE_GATE=R3-000017A\n'
    printf 'FREEZE_GATE=R3-000017B-1\n'
    printf 'PUBLICATION_GATE=R3-000017B-2\n'
    printf 'CANDIDATE_HASH_COUNT=12\n'
    printf 'APPLICATION_FOUNDATION_REVISION=8\n'
    printf 'APPLICATION_PYTHON_FILE_COUNT=42\n'
    printf 'INBOUND_PORT_COUNT=9\n'
    printf 'OUTBOUND_PORT_COUNT=10\n'
    printf 'CONCRETE_USE_CASE_COUNT=7\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'DOMAIN_UNIT_TESTS=PASS\n'
    printf 'EXECUTION_PLAN_REUSE=PASS\n'
    printf 'IDEMPOTENCY=EXPLICIT\n'
    printf 'BOUNDED_RETRY=PASS\n'
    printf 'PARTIAL_RESULTS=EXPLICIT\n'
    printf 'RECOVERY_INVOCATION=EXPLICIT\n'
    printf 'POLICY_DECISION=NOT_EVALUATED\n'
    printf 'PLAN_CREATION=NONE\n'
    printf 'VERIFICATION_CONCLUSION=NONE\n'
    printf 'ROADMAP_STATE=UPDATED\n'
    printf 'NEXT_GATE=R3-000018\n'
    printf 'PERCEPTION_DECISION_BLOCK_PERCENT=100.0\n'
    printf 'EXTENDED_AUTONOMY_ROADMAP_PERCENT=87.5\n'

    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"

    printf 'ROADMAP_STATE_SHA256=%s\n' \
        "$(sha256sum "${ROADMAP_STATE}" | awk '{print $1}')"

    printf 'EXECUTION_CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${EXECUTION_CONTRACT}" | awk '{print $1}')"

    printf 'EXECUTION_VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${EXECUTION_VALIDATOR}" | awk '{print $1}')"

    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"

    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"

    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
