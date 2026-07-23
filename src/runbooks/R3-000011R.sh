#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000011R-observation-use-case-recovery.sh"

sandra_begin \
    "R3-000011R" \
    "Recover and certify Observation Use Case Foundation"

for command_name in \
    python3 git install cp grep find sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

APPLICATION_ROOT="${ROOT}/src/sandra/application"
INBOUND_ROOT="${APPLICATION_ROOT}/ports/inbound"
OUTBOUND_ROOT="${APPLICATION_ROOT}/ports/outbound"
USE_CASES_ROOT="${APPLICATION_ROOT}/use_cases"

OBSERVATION_TYPES="${APPLICATION_ROOT}/observation.py"
INBOUND_PORT="${INBOUND_ROOT}/observation.py"
OUTBOUND_PORT="${OUTBOUND_ROOT}/observation_source.py"
USE_CASE="${USE_CASES_ROOT}/observe_subject.py"

APPLICATION_INIT="${APPLICATION_ROOT}/__init__.py"
INBOUND_INIT="${INBOUND_ROOT}/__init__.py"
OUTBOUND_INIT="${OUTBOUND_ROOT}/__init__.py"
USE_CASES_INIT="${USE_CASES_ROOT}/__init__.py"

FOUNDATION_CONTRACT="${ROOT}/docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json"
FOUNDATION_VALIDATOR="${ROOT}/src/knowledge/validate_application_foundation.py"

OBSERVATION_CONTRACT="${ROOT}/docs/contracts/application/OBSERVATION-USE-CASE-V1.json"
OBSERVATION_ADR="${ROOT}/docs/adr/ADR-0011-OBSERVATION-USE-CASE-FOUNDATION.md"
OBSERVATION_VALIDATOR="${ROOT}/src/knowledge/validate_observation_use_case.py"

TEST_ROOT="${ROOT}/tests/contract/application"
TEST_FILE="${TEST_ROOT}/test_observation_use_case.py"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

CONSTITUTIONAL_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONSTITUTIONAL_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

for required_file in \
    "${STATE}" \
    "${OBSERVATION_TYPES}" \
    "${INBOUND_PORT}" \
    "${OUTBOUND_PORT}" \
    "${USE_CASE}" \
    "${APPLICATION_INIT}" \
    "${INBOUND_INIT}" \
    "${OUTBOUND_INIT}" \
    "${USE_CASES_INIT}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${OBSERVATION_CONTRACT}" \
    "${OBSERVATION_ADR}" \
    "${OBSERVATION_VALIDATOR}" \
    "${TEST_FILE}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_VALIDATOR}" \
    "${CONSTITUTIONAL_INDEX}" \
    "${CONSTITUTIONAL_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

install -d -m 0700 "${BACKUP_ROOT}"

for file in \
    "${STATE}" \
    "${OBSERVATION_TYPES}" \
    "${INBOUND_PORT}" \
    "${OUTBOUND_PORT}" \
    "${USE_CASE}" \
    "${APPLICATION_INIT}" \
    "${INBOUND_INIT}" \
    "${OUTBOUND_INIT}" \
    "${USE_CASES_INIT}" \
    "${FOUNDATION_CONTRACT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${OBSERVATION_CONTRACT}" \
    "${OBSERVATION_ADR}" \
    "${OBSERVATION_VALIDATOR}" \
    "${TEST_FILE}"
do
    relative="${file#${ROOT}/}"
    backup="${BACKUP_ROOT}/${relative}"

    install -d -m 0700 "$(dirname "${backup}")"
    cp -a -- "${file}" "${backup}"
done

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/partial-state-scope.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
evidence = Path(sys.argv[2])

expected_modified = {
    "docs/contracts/application/APPLICATION-PORTS-FOUNDATION-V1.json",
    "src/knowledge/validate_application_foundation.py",
    "src/sandra/application/__init__.py",
    "src/sandra/application/ports/inbound/__init__.py",
    "src/sandra/application/ports/outbound/__init__.py",
    "src/sandra/application/use_cases/__init__.py",
}

expected_untracked = {
    "docs/adr/ADR-0011-OBSERVATION-USE-CASE-FOUNDATION.md",
    "docs/contracts/application/OBSERVATION-USE-CASE-V1.json",
    "src/knowledge/validate_observation_use_case.py",
    "src/sandra/application/observation.py",
    "src/sandra/application/ports/inbound/observation.py",
    "src/sandra/application/ports/outbound/observation_source.py",
    "src/sandra/application/use_cases/observe_subject.py",
    "tests/contract/application/test_observation_use_case.py",
}


def paths(*args: str) -> set[str]:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    return {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    }


modified = paths("diff", "--name-only")
staged = paths("diff", "--cached", "--name-only")
untracked = paths(
    "ls-files",
    "--others",
    "--exclude-standard",
)

checks = {
    "modified_exact": modified == expected_modified,
    "untracked_exact": untracked == expected_untracked,
    "staged_absent": not staged,
}

lines = [
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(checks.items())
]

for value in sorted(modified):
    lines.append(f"MODIFIED={value}")

for value in sorted(untracked):
    lines.append(f"UNTRACKED={value}")

for value in sorted(staged):
    lines.append(f"STAGED={value}")

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
        "PARTIAL_STATE_SCOPE_INVALID:"
        + ",".join(failed)
    )

print("PARTIAL_STATE_SCOPE=PASS")
PYTHON

python3 - \
    "${OBSERVATION_TYPES}" \
    "${SANDRA_EVIDENCE_DIR}/patch-result.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
evidence = Path(sys.argv[2])

text = path.read_text(encoding="utf-8")

old = "        super().__post_init__()\n"
new = "        Query.__post_init__(self)\n"

count = text.count(old)

if count != 1:
    raise SystemExit(
        f"PATCH_TARGET_COUNT_INVALID:{count}"
    )

text = text.replace(old, new, 1)

path.write_text(
    text,
    encoding="utf-8",
)

evidence.write_text(
    "PATCH_TARGET=ObservationRequest.__post_init__\n"
    "OLD_CALL=super().__post_init__()\n"
    "NEW_CALL=Query.__post_init__(self)\n"
    "PATCH_COUNT=1\n"
    "PATCH_STATUS=PASS\n",
    encoding="utf-8",
)

print("OBSERVATION_REQUEST_PATCH=PASS")
PYTHON

python3 -m compileall \
    -q \
    "${APPLICATION_ROOT}" \
    "${TEST_ROOT}" \
    "${FOUNDATION_VALIDATOR}" \
    "${OBSERVATION_VALIDATOR}"

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
    > "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONSTITUTIONAL_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-map-precheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-precheck.txt"

python3 \
    "${OBSERVATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${OBSERVATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/observation-validation.txt"

grep -q \
    '^OBSERVATION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/observation-validation.txt"

python3 \
    "${FOUNDATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${FOUNDATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/application-foundation-validation.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/application-foundation-validation.txt"

PYTHONPATH="${ROOT}/src/sandra" \
python3 -m unittest discover \
    -s "${TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/application-contract-tests.txt" \
    2>&1

grep -q \
    '^Ran 10 tests' \
    "${SANDRA_EVIDENCE_DIR}/application-contract-tests.txt"

grep -q \
    '^OK$' \
    "${SANDRA_EVIDENCE_DIR}/application-contract-tests.txt"

python3 - \
    "${APPLICATION_ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/runtime-regression.txt" <<'PYTHON'
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import os
import subprocess
import sys

application_root = Path(sys.argv[1]).resolve()
evidence = Path(sys.argv[2])

environment = os.environ.copy()
environment["PYTHONPATH"] = str(
    application_root.parent
)

program = r'''
from datetime import datetime, timezone
from application.observation import ObservationRequest

request = ObservationRequest(
    message_id="runtime-check",
    correlation_id="runtime-correlation",
    created_at=datetime.now(timezone.utc),
    subject_ref="runtime-subject",
    capability_id="runtime-capability",
)

assert request.message_id == "runtime-check"
assert request.subject_ref == "runtime-subject"

print("OBSERVATION_REQUEST_RUNTIME=PASS")
'''

result = subprocess.run(
    [
        sys.executable,
        "-c",
        program,
    ],
    env=environment,
    check=False,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True,
)

evidence.write_text(
    f"EXIT_CODE={result.returncode}\n"
    f"STDOUT={result.stdout.strip()}\n"
    f"STDERR={result.stderr.strip()}\n",
    encoding="utf-8",
)

if result.returncode != 0:
    raise SystemExit(
        "OBSERVATION_REQUEST_RUNTIME_FAILED"
    )

if result.stdout.strip() != (
    "OBSERVATION_REQUEST_RUNTIME=PASS"
):
    raise SystemExit(
        "OBSERVATION_REQUEST_RUNTIME_OUTPUT_INVALID"
    )

print("OBSERVATION_REQUEST_RUNTIME=PASS")
PYTHON

find "${APPLICATION_ROOT}" "${TEST_ROOT}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${APPLICATION_ROOT}" "${TEST_ROOT}" \
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

state["metadata"]["state_version"] = "5.1.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

foundation["revision"] = 2
foundation["inbound_ports"] = [
    "CommandHandler",
    "QueryHandler",
    "ObserveSubjectPort",
]
foundation["outbound_ports"] = [
    "Repository",
    "EventBus",
    "UnitOfWork",
    "ObservationSource",
]
foundation["concrete_use_cases"] = 1

state["spec"]["observation_use_case"] = {
    "version": "1.0.0",
    "id": "observation-use-case-v1",
    "status": "certified_immutable",
    "capability": "observation",
    "inbound_port": "ObserveSubjectPort",
    "outbound_port": "ObservationSource",
    "use_case": "ObserveSubject",
    "request": "ObservationRequest",
    "result": "ApplicationResult[ObservationBatch]",
    "contract": (
        "docs/contracts/application/"
        "OBSERVATION-USE-CASE-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_observation_use_case.py"
    ),
    "authoritative_state_mutation": "none",
    "evidence_qualification": "none",
    "policy_evaluation": "none",
    "planning": "none",
    "execution": "none",
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000011R",
    "title": "Observation Use Case Foundation Recovery",
    "type": "application_vertical_contract_recovery",
    "targets": [
        "ObservationRequest runtime correction",
        "Observation application contracts",
        "Observation contract tests",
        "STATE.json",
    ],
    "excluded_targets": [
        "evidence qualification",
        "authoritative persistence",
        "policy evaluation",
        "planning",
        "execution",
        "concrete technology adapters",
        "remote Habitat",
    ],
    "objectives": [
        "recover the failed Observation candidate",
        "correct the dataclass inheritance runtime defect",
        "pass all application contract tests",
        "publish the certified Observation use case",
    ],
    "prohibitions": [
        "no Observation model expansion",
        "no product-specific logic",
        "no authoritative state mutation",
        "no policy decision",
        "no execution",
        "no Habitat modification",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000012",
    "title": "Evidence Qualification Use Case Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Observation Use Case Foundation",
    "current_gate": "R3-000011R",
    "current_gate_status": "complete",
    "next_gate": "R3-000012",
}

state["status"]["observation_use_case_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "recovered_from": "R3-000011",
    "runtime_defect": (
        "zero_argument_super_with_frozen_slots_dataclass"
    ),
    "runtime_correction": (
        "Query.__post_init__(self)"
    ),
    "contract_test_count": 10,
    "contract_tests": "pass",
    "runtime_regression": "pass",
    "application_foundation": "pass",
    "architecture_constitution": "pass",
    "capability_map": "pass",
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
# ${SANDRA_RUNBOOK_ID} — Observation Use Case recovery

- Run ID: \`${SANDRA_RUN_ID}\`
- Recovered gate: \`R3-000011\`
- Defect:
  \`zero-argument super() with inherited frozen slots dataclass\`
- Correction: \`Query.__post_init__(self)\`
- Contract tests: \`10 PASS\`
- Runtime regression: \`PASS\`
- Authoritative state mutation: \`NONE\`
- Policy evaluation: \`NONE\`
- Execution: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- verified the exact partial working-tree state;
- backed up every affected candidate file;
- corrected only ObservationRequest base validation dispatch;
- passed architecture, constitutional and capability validation;
- passed all ten Application contract tests;
- passed an isolated runtime regression;
- published the Observation Use Case Foundation.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: recover Observation Use Case Foundation"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${OBSERVATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${OBSERVATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/observation-post-sync.txt"

grep -q \
    '^OBSERVATION_USE_CASE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/observation-post-sync.txt"

python3 \
    "${FOUNDATION_VALIDATOR}" \
    "${APPLICATION_ROOT}" \
    "${FOUNDATION_CONTRACT}" \
    "${CAPABILITY_MAP}" \
    > "${SANDRA_EVIDENCE_DIR}/application-foundation-post-sync.txt"

grep -q \
    '^APPLICATION_PORTS_FOUNDATION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/application-foundation-post-sync.txt"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
evidence = Path(sys.argv[2])

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

evidence.write_text(
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
    printf 'OBSERVATION_USE_CASE_RECOVERY=PASS\n'
    printf 'OBSERVATION_USE_CASE=PASS\n'
    printf 'OBSERVATION_USE_CASE_ID=observation-use-case-v1\n'
    printf 'OBSERVATION_STATUS=CERTIFIED_IMMUTABLE\n'
    printf 'RECOVERED_FROM=R3-000011\n'
    printf 'PATCH=Query.__post_init__(self)\n'
    printf 'APPLICATION_CONTRACT_TEST_COUNT=10\n'
    printf 'APPLICATION_CONTRACT_TESTS=PASS\n'
    printf 'RUNTIME_REGRESSION=PASS\n'
    printf 'APPLICATION_FOUNDATION=PASS\n'
    printf 'ARCHITECTURE_CONSTITUTION=PASS\n'
    printf 'CAPABILITY_MAP=PASS\n'
    printf 'AUTHORITATIVE_STATE_MUTATION=NONE\n'
    printf 'POLICY_EVALUATION=NONE\n'
    printf 'EXECUTION=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'OBSERVATION_TYPES_SHA256=%s\n' \
        "$(sha256sum "${OBSERVATION_TYPES}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
