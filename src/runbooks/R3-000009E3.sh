#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000009E3-capability-map-publication.sh"

sandra_begin \
    "R3-000009E3" \
    "Publish Canonical Capability Map V1"

for command_name in \
    python3 git install cp grep sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

CAPABILITY_MAP="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json"
CAPABILITY_DOC="${ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.md"
CAPABILITY_ADR="${ROOT}/docs/adr/ADR-0009-CANONICAL-CAPABILITY-MAP-V1.md"
CAPABILITY_VALIDATOR="${ROOT}/src/knowledge/validate_capability_map.py"

ARCH_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
ARCH_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

CONTRACT_INDEX="${ROOT}/docs/contracts/constitutional/CONSTITUTIONAL-CONTRACTS-V1.json"
CONTRACT_VALIDATOR="${ROOT}/src/knowledge/validate_constitutional_contracts.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

for required_file in \
    "${STATE}" \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_DOC}" \
    "${CAPABILITY_ADR}" \
    "${CAPABILITY_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ARCH_VALIDATOR}" \
    "${CONTRACT_INDEX}" \
    "${CONTRACT_VALIDATOR}"
do
    sandra_require_file "${required_file}"
done

install -d -m 0700 \
    "${BACKUP_ROOT}/docs/capabilities" \
    "${BACKUP_ROOT}/docs/adr" \
    "${BACKUP_ROOT}/src/knowledge"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/STATE.json.before"

cp -a -- \
    "${CAPABILITY_MAP}" \
    "${BACKUP_ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json.before"

cp -a -- \
    "${CAPABILITY_DOC}" \
    "${BACKUP_ROOT}/docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.md.before"

cp -a -- \
    "${CAPABILITY_ADR}" \
    "${BACKUP_ROOT}/docs/adr/ADR-0009-CANONICAL-CAPABILITY-MAP-V1.md.before"

cp -a -- \
    "${CAPABILITY_VALIDATOR}" \
    "${BACKUP_ROOT}/src/knowledge/validate_capability_map.py.before"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/prepublication-working-tree.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
evidence_path = Path(sys.argv[2])

expected_untracked = {
    "docs/adr/ADR-0009-CANONICAL-CAPABILITY-MAP-V1.md",
    "docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.json",
    "docs/capabilities/CANONICAL-CAPABILITY-MAP-V1.md",
    "src/knowledge/validate_capability_map.py",
}


def git_paths(*arguments: str) -> set[str]:
    result = subprocess.run(
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
    )

    return {
        line.strip()
        for line in result.stdout.splitlines()
        if line.strip()
    }


untracked = git_paths(
    "ls-files",
    "--others",
    "--exclude-standard",
)

modified = git_paths(
    "diff",
    "--name-only",
)

staged = git_paths(
    "diff",
    "--cached",
    "--name-only",
)

checks = {
    "untracked_candidate_set": (
        untracked == expected_untracked
    ),
    "tracked_modifications_absent": (
        not modified
    ),
    "staged_modifications_absent": (
        not staged
    ),
}

lines = [
    f"{name}={'PASS' if passed else 'FAIL'}"
    for name, passed in sorted(checks.items())
]

for path in sorted(untracked):
    lines.append(f"UNTRACKED={path}")

for path in sorted(modified):
    lines.append(f"MODIFIED={path}")

for path in sorted(staged):
    lines.append(f"STAGED={path}")

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
        "PREPUBLICATION_WORKING_TREE_INVALID:"
        + ",".join(failed)
    )

print("PREPUBLICATION_WORKING_TREE=PASS")
PYTHON

python3 \
    "${ARCH_VALIDATOR}" \
    "${ARCH_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-constitution-precheck.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-constitution-precheck.txt"

python3 \
    "${CONTRACT_VALIDATOR}" \
    "${ROOT}" \
    "${CONTRACT_INDEX}" \
    "${ARCH_CONTRACT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

grep -q \
    '^CONSTITUTIONAL_CONTRACTS=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitutional-contracts-precheck.txt"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONTRACT_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/candidate-validation-precheck.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/candidate-validation-precheck.txt"

grep -q \
    '^CANDIDATE_CONTENT=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/candidate-validation-precheck.txt"

grep -q \
    '^PRODUCT_TERMS_IN_CORE=NONE$' \
    "${SANDRA_EVIDENCE_DIR}/candidate-validation-precheck.txt"

python3 - "${CAPABILITY_MAP}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

path = Path(sys.argv[1])

document = json.loads(
    path.read_text(encoding="utf-8")
)

metadata = document.get("metadata")

if not isinstance(metadata, dict):
    raise SystemExit(
        "CAPABILITY_MAP_METADATA_INVALID"
    )

if metadata.get("id") != "canonical-capability-map-v1":
    raise SystemExit(
        "CAPABILITY_MAP_ID_INVALID"
    )

if metadata.get("status") != "candidate":
    raise SystemExit(
        "CAPABILITY_MAP_NOT_CANDIDATE"
    )

metadata["status"] = "immutable"
metadata["publishedBy"] = "R3-000009E3"

path.write_text(
    json.dumps(
        document,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

python3 - "${CAPABILITY_DOC}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old = (
    "**CANDIDATE E1 — contenuto validato, "
    "non ancora costituzionalmente pubblicato**"
)

new = (
    "**IMMUTABILE — pubblicata e certificata "
    "da R3-000009E3**"
)

if text.count(old) != 1:
    raise SystemExit(
        "CAPABILITY_DOCUMENT_STATUS_INVALID"
    )

text = text.replace(old, new, 1)

path.write_text(
    text,
    encoding="utf-8",
)
PYTHON

python3 - "${CAPABILITY_ADR}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_status = """## Stato

Proposed by R3-000009E1.

L'accettazione costituzionale avverrà soltanto dopo validazione indipendente
nel gate E2 e pubblicazione dello stato nel gate E3.
"""

new_status = """## Stato

Accepted and immutable.

Contenuto generato da R3-000009E1, validato indipendentemente da
R3-000009E2R e pubblicato costituzionalmente da R3-000009E3.
"""

if text.count(old_status) != 1:
    raise SystemExit(
        "CAPABILITY_ADR_STATUS_INVALID"
    )

text = text.replace(
    old_status,
    new_status,
    1,
)

text = text.replace(
    "## Decisione proposta",
    "## Decisione",
    1,
)

path.write_text(
    text,
    encoding="utf-8",
)
PYTHON

python3 - "${CAPABILITY_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

replacements = (
    (
        'if metadata.get("status") != "candidate":\n'
        '        fail("STATUS_NOT_CANDIDATE")',
        'if metadata.get("status") != "immutable":\n'
        '        fail("STATUS_NOT_IMMUTABLE")',
    ),
    (
        'print("CANDIDATE_CONTENT=PASS")',
        'print("CAPABILITY_MAP_CONTENT=PASS")',
    ),
    (
        'print("PUBLICATION_STATUS=NOT_PUBLISHED")',
        'print("PUBLICATION_STATUS=PUBLISHED")',
    ),
)

for old, new in replacements:
    count = text.count(old)

    if count != 1:
        raise SystemExit(
            "VALIDATOR_PATCH_TARGET_INVALID:"
            + repr(old)
            + ":"
            + str(count)
        )

    text = text.replace(old, new, 1)

path.write_text(
    text,
    encoding="utf-8",
)
PYTHON

python3 -m py_compile \
    "${CAPABILITY_VALIDATOR}"

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONTRACT_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/published-capability-validation.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-capability-validation.txt"

grep -q \
    '^CAPABILITY_MAP_CONTENT=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/published-capability-validation.txt"

grep -q \
    '^PRODUCT_TERMS_IN_CORE=NONE$' \
    "${SANDRA_EVIDENCE_DIR}/published-capability-validation.txt"

grep -q \
    '^PUBLICATION_STATUS=PUBLISHED$' \
    "${SANDRA_EVIDENCE_DIR}/published-capability-validation.txt"

python3 - \
    "${CAPABILITY_MAP}" \
    "${CAPABILITY_DOC}" \
    "${CAPABILITY_ADR}" \
    "${SANDRA_EVIDENCE_DIR}/publication-consistency.txt" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

map_path = Path(sys.argv[1])
document_path = Path(sys.argv[2])
adr_path = Path(sys.argv[3])
evidence_path = Path(sys.argv[4])

capability_map = json.loads(
    map_path.read_text(encoding="utf-8")
)

document = document_path.read_text(
    encoding="utf-8"
)

adr = adr_path.read_text(
    encoding="utf-8"
)

checks = {
    "map_status_immutable": (
        capability_map["metadata"]["status"]
        == "immutable"
    ),
    "map_publisher": (
        capability_map["metadata"].get("publishedBy")
        == "R3-000009E3"
    ),
    "document_status_immutable": (
        "IMMUTABILE" in document
        and "R3-000009E3" in document
    ),
    "adr_status_accepted": (
        "Accepted and immutable." in adr
    ),
    "adr_records_e1": (
        "R3-000009E1" in adr
    ),
    "adr_records_e2r": (
        "R3-000009E2R" in adr
    ),
    "adr_records_e3": (
        "R3-000009E3" in adr
    ),
}

evidence_path.write_text(
    "\n".join(
        f"{name}={'PASS' if passed else 'FAIL'}"
        for name, passed in sorted(checks.items())
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
        "PUBLICATION_CONSISTENCY_FAILED:"
        + ",".join(failed)
    )

print("PUBLICATION_CONSISTENCY=PASS")
PYTHON

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

architecture = state["spec"]["architecture"]
constitution = architecture.get("constitution")

if not isinstance(constitution, dict):
    raise SystemExit(
        "ARCHITECTURE_CONSTITUTION_MISSING"
    )

if constitution.get("id") != (
    "architecture-constitution-v1"
):
    raise SystemExit(
        "ARCHITECTURE_CONSTITUTION_INVALID"
    )

contracts = state["spec"].get(
    "constitutional_contracts"
)

if not isinstance(contracts, dict):
    raise SystemExit(
        "CONSTITUTIONAL_CONTRACTS_MISSING"
    )

if contracts.get("status") != "immutable":
    raise SystemExit(
        "CONSTITUTIONAL_CONTRACTS_NOT_IMMUTABLE"
    )

state["metadata"]["state_version"] = "4.3.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["capability_map"] = {
    "version": "1.0.0",
    "id": "canonical-capability-map-v1",
    "status": "immutable",
    "document": (
        "docs/capabilities/"
        "CANONICAL-CAPABILITY-MAP-V1.md"
    ),
    "contract": (
        "docs/capabilities/"
        "CANONICAL-CAPABILITY-MAP-V1.json"
    ),
    "validator": (
        "src/knowledge/"
        "validate_capability_map.py"
    ),
    "publication": {
        "content_gate": "R3-000009E1",
        "validation_gate": "R3-000009E2R",
        "publication_gate": "R3-000009E3",
    },
    "core_capability_count": 16,
    "operational_family_count": 8,
    "core_capabilities": [
        "identity",
        "resource_lifecycle",
        "observation",
        "evidence_qualification",
        "resource_graph",
        "capability_declaration",
        "desired_state",
        "policy_decision",
        "planning",
        "execution",
        "verification",
        "persistence",
        "audit",
        "notification",
        "security_governance",
        "experience_learning",
    ],
    "operational_families": [
        "compute",
        "operating_system",
        "storage",
        "backup",
        "network",
        "observability",
        "security",
        "policy_engine",
    ],
}

roadmap = state["spec"]["roadmap"]

roadmap["current_gate"] = {
    "runbook": "R3-000009E3",
    "title": "Canonical Capability Map V1 Publication",
    "type": "constitutional_capability_publication",
    "targets": [
        "Canonical Capability Map V1",
        "capability map validator",
        "ADR-0009",
        "STATE.json",
        "Knowledge canonical history",
    ],
    "excluded_targets": [
        "domain implementation",
        "application implementation",
        "controller implementation",
        "adapter implementation",
        "remote Habitat",
        "software installation",
    ],
    "objectives": [
        "publish the independently validated capability map",
        "set immutable constitutional status",
        "register capability taxonomy in STATE",
        "synchronize canonical Knowledge and Git",
    ],
    "prohibitions": [
        "no capability content expansion",
        "no architecture change",
        "no product-specific core capability",
        "no Habitat modification",
        "no software installation",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000009F",
    "title": "Canonical Domain Purification",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Canonical Capability Map V1",
    "current_gate": "R3-000009E3",
    "current_gate_status": "complete",
    "next_gate": "R3-000009F",
}

state["status"]["canonical_capability_map_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "content_gate": "R3-000009E1",
    "validation_gate": "R3-000009E2R",
    "publication_gate": "R3-000009E3",
    "core_capability_count": 16,
    "operational_family_count": 8,
    "architecture_constitution_validation": "pass",
    "constitutional_contracts_validation": "pass",
    "capability_map_validation": "pass",
    "publication_consistency": "pass",
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
# ${SANDRA_RUNBOOK_ID} — Canonical Capability Map V1 publication

- Run ID: \`${SANDRA_RUN_ID}\`
- Content gate: \`R3-000009E1\`
- Independent validation gate: \`R3-000009E2R\`
- Publication gate: \`R3-000009E3\`
- Core capability count: \`16\`
- Operational family count: \`8\`
- Status: \`IMMUTABLE\`
- Architecture changes: \`NONE\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- promoted the validated Capability Map from candidate to immutable;
- promoted ADR-0009 from proposed to accepted;
- updated the permanent validator for published status;
- registered the Capability Map in STATE;
- preserved Architecture Constitution V1;
- preserved all constitutional operational contracts.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: publish Canonical Capability Map V1"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${CAPABILITY_VALIDATOR}" \
    "${CAPABILITY_MAP}" \
    "${ARCH_CONTRACT}" \
    "${CONTRACT_INDEX}" \
    > "${SANDRA_EVIDENCE_DIR}/capability-map-post-sync.txt"

grep -q \
    '^CANONICAL_CAPABILITY_MAP_VALIDATOR=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-post-sync.txt"

grep -q \
    '^CAPABILITY_MAP_CONTENT=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-post-sync.txt"

grep -q \
    '^PUBLICATION_STATUS=PUBLISHED$' \
    "${SANDRA_EVIDENCE_DIR}/capability-map-post-sync.txt"

python3 - \
    "${ROOT}" \
    "${SANDRA_EVIDENCE_DIR}/repository-post-sync.txt" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1]).resolve()
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
    printf 'E3_CAPABILITY_MAP_PUBLICATION=PASS\n'
    printf 'CAPABILITY_MAP_ID=canonical-capability-map-v1\n'
    printf 'CAPABILITY_MAP_STATUS=IMMUTABLE\n'
    printf 'PUBLICATION_STATUS=PUBLISHED\n'
    printf 'CORE_CAPABILITY_COUNT=16\n'
    printf 'OPERATIONAL_FAMILY_COUNT=8\n'
    printf 'CONTENT_GATE=R3-000009E1\n'
    printf 'VALIDATION_GATE=R3-000009E2R\n'
    printf 'PUBLICATION_GATE=R3-000009E3\n'
    printf 'ARCHITECTURE_CHANGE=NONE\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'CAPABILITY_MAP_SHA256=%s\n' \
        "$(sha256sum "${CAPABILITY_MAP}" | awk '{print $1}')"
    printf 'VALIDATOR_SHA256=%s\n' \
        "$(sha256sum "${CAPABILITY_VALIDATOR}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
