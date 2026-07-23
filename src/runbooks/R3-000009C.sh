#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000009C-architecture-constitution-terminology.sh"

sandra_begin \
    "R3-000009C" \
    "Correct architecture terminology without structural changes"

for command_name in \
    python3 git install cp mv grep sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

OLD_DOC="${ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.md"
OLD_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.json"
OLD_ADR="${ROOT}/docs/adr/ADR-0007-ARCHITECTURE-GRANITA-FREEZE.md"
OLD_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_freeze.py"

NEW_DOC="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.md"
NEW_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-CONSTITUTION-V1.json"
NEW_ADR="${ROOT}/docs/adr/ADR-0007-ARCHITECTURE-CONSTITUTION-V1.md"
NEW_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_constitution.py"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${OLD_DOC}"
sandra_require_file "${OLD_CONTRACT}"
sandra_require_file "${OLD_ADR}"
sandra_require_file "${OLD_VALIDATOR}"

git -C "${ROOT}" diff --quiet
git -C "${ROOT}" diff --cached --quiet

for target in \
    "${NEW_DOC}" \
    "${NEW_CONTRACT}" \
    "${NEW_ADR}" \
    "${NEW_VALIDATOR}"
do
    if [[ -e "${target}" || -L "${target}" ]]; then
        sandra_fail "New terminology target already exists: ${target}"
    fi
done

install -d -m 0700 \
    "${BACKUP_ROOT}/docs/architecture" \
    "${BACKUP_ROOT}/docs/adr" \
    "${BACKUP_ROOT}/src/knowledge"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/STATE.json.before"

cp -a -- \
    "${OLD_DOC}" \
    "${BACKUP_ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.md"

cp -a -- \
    "${OLD_CONTRACT}" \
    "${BACKUP_ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.json"

cp -a -- \
    "${OLD_ADR}" \
    "${BACKUP_ROOT}/docs/adr/ADR-0007-ARCHITECTURE-GRANITA-FREEZE.md"

cp -a -- \
    "${OLD_VALIDATOR}" \
    "${BACKUP_ROOT}/src/knowledge/validate_architecture_freeze.py"

python3 - \
    "${OLD_CONTRACT}" \
    "${SANDRA_EVIDENCE_DIR}/contract-precheck.txt" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

contract_path = Path(sys.argv[1])
evidence_path = Path(sys.argv[2])

contract = json.loads(
    contract_path.read_text(encoding="utf-8")
)

checks = {
    "apiVersion": (
        contract.get("apiVersion")
        == "architecture.sandra.io/v1"
    ),
    "kind": (
        contract.get("kind")
        == "ArchitectureFreeze"
    ),
    "id": (
        contract.get("metadata", {}).get("id")
        == "architecture-granita-v1"
    ),
    "status": (
        contract.get("metadata", {}).get("status")
        == "immutable"
    ),
    "sourceRoot": (
        contract.get("spec", {}).get("sourceRoot")
        == "src/sandra"
    ),
}

evidence_path.write_text(
    "\n".join(
        f"{key}={'PASS' if value else 'FAIL'}"
        for key, value in checks.items()
    )
    + "\n",
    encoding="utf-8",
)

failed = [
    key
    for key, value in checks.items()
    if not value
]

if failed:
    raise SystemExit(
        "CONTRACT_PRECHECK_FAILED:"
        + ",".join(failed)
    )

print("CONTRACT_PRECHECK=PASS")
PYTHON

mv -- "${OLD_DOC}" "${NEW_DOC}"
mv -- "${OLD_CONTRACT}" "${NEW_CONTRACT}"
mv -- "${OLD_ADR}" "${NEW_ADR}"
mv -- "${OLD_VALIDATOR}" "${NEW_VALIDATOR}"

python3 - "${NEW_CONTRACT}" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

path = Path(sys.argv[1])

contract = json.loads(
    path.read_text(encoding="utf-8")
)

if contract.get("kind") != "ArchitectureFreeze":
    raise SystemExit("OLD_CONTRACT_KIND_UNEXPECTED")

metadata = contract.get("metadata")

if not isinstance(metadata, dict):
    raise SystemExit("CONTRACT_METADATA_INVALID")

if metadata.get("id") != "architecture-granita-v1":
    raise SystemExit("OLD_CONTRACT_ID_UNEXPECTED")

contract["kind"] = "ArchitectureConstitution"

metadata["id"] = "architecture-constitution-v1"
metadata["name"] = "SANDRA Architecture Constitution V1"
metadata["status"] = "immutable"
metadata["scope"] = "until-project-completion"
metadata["principle"] = "granitic-architecture"

spec = contract.get("spec")

if not isinstance(spec, dict):
    raise SystemExit("CONTRACT_SPEC_INVALID")

spec["architecturePrinciple"] = {
    "name": "Architettura Granitica",
    "meaning": (
        "confini architetturali stabili, "
        "immutabili per preferenza o intuizione"
    ),
    "structuralChange": "none"
}

path.write_text(
    json.dumps(
        contract,
        indent=2,
        ensure_ascii=False,
    )
    + "\n",
    encoding="utf-8",
)
PYTHON

python3 - "${NEW_VALIDATOR}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

replacements = (
    (
        "ARCHITECTURE_FREEZE_INVALID",
        "ARCHITECTURE_CONSTITUTION_INVALID",
    ),
    (
        '"ArchitectureFreeze"',
        '"ArchitectureConstitution"',
    ),
    (
        '"architecture-granita-v1"',
        '"architecture-constitution-v1"',
    ),
    (
        'print("ARCHITECTURE_GRANITA_FREEZE=PASS")',
        'print("ARCHITECTURE_CONSTITUTION=PASS")',
    ),
    (
        'print("FREEZE_ID=architecture-granita-v1")',
        'print("CONSTITUTION_ID=architecture-constitution-v1")',
    ),
    (
        'print("FREEZE_STATUS=IMMUTABLE")',
        'print("CONSTITUTION_STATUS=IMMUTABLE")',
    ),
)

for old, new in replacements:
    count = text.count(old)

    if count != 1:
        raise SystemExit(
            f"VALIDATOR_PATCH_TARGET_INVALID:"
            f"{old}:{count}"
        )

    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
PYTHON

python3 - "${NEW_DOC}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

replacements = (
    (
        "# SANDRA Architecture GRANITA Freeze V1",
        "# SANDRA Architecture Constitution V1",
    ),
    (
        "**IMMUTABILE FINO ALLA FINE DEL PROGETTO**",
        (
            "**PRINCIPIO DI ARCHITETTURA GRANITICA — "
            "IMMUTABILE FINO ALLA FINE DEL PROGETTO**"
        ),
    ),
)

for old, new in replacements:
    count = text.count(old)

    if count != 1:
        raise SystemExit(
            f"DOCUMENT_PATCH_TARGET_INVALID:"
            f"{old}:{count}"
        )

    text = text.replace(old, new, 1)

text = text.replace(
    "Architecture GRANITA",
    "Architecture Constitution",
)

path.write_text(text, encoding="utf-8")
PYTHON

python3 - "${NEW_ADR}" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_title = (
    "# ADR-0007 — Architecture GRANITA Freeze V1"
)
new_title = (
    "# ADR-0007 — Architecture Constitution V1"
)

if text.count(old_title) != 1:
    raise SystemExit(
        "ADR_TITLE_PATCH_TARGET_INVALID"
    )

text = text.replace(old_title, new_title, 1)

text = text.replace(
    "Architecture GRANITA",
    "Architecture Constitution",
)

insertion_marker = "## Decisione\n"

if text.count(insertion_marker) != 1:
    raise SystemExit(
        "ADR_DECISION_MARKER_INVALID"
    )

text = text.replace(
    insertion_marker,
    (
        "## Principio\n\n"
        "La costituzione applica il principio di "
        "**Architettura Granitica**: i confini dei layer "
        "restano stabili e non possono cambiare per "
        "preferenza, moda o intuizione.\n\n"
        "## Decisione\n"
    ),
    1,
)

path.write_text(text, encoding="utf-8")
PYTHON

python3 - \
    "${ROOT}/src/sandra" \
    "${ROOT}/tests" <<'PYTHON'
from __future__ import annotations

from pathlib import Path
import sys

roots = [
    Path(value)
    for value in sys.argv[1:]
]

replacements = (
    (
        "Architecture GRANITA Freeze V1",
        (
            "Architecture Constitution V1 — "
            "principio di Architettura Granitica"
        ),
    ),
    (
        "Architecture GRANITA",
        "Architecture Constitution",
    ),
)

for root in roots:
    if not root.is_dir():
        continue

    for path in root.rglob("README.md"):
        text = path.read_text(encoding="utf-8")
        updated = text

        for old, new in replacements:
            updated = updated.replace(old, new)

        if updated != text:
            path.write_text(
                updated,
                encoding="utf-8",
            )
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
freeze = architecture.get("freeze")

if not isinstance(freeze, dict):
    raise SystemExit(
        "OLD_ARCHITECTURE_FREEZE_RECORD_MISSING"
    )

if freeze.get("id") != "architecture-granita-v1":
    raise SystemExit(
        "OLD_ARCHITECTURE_ID_UNEXPECTED"
    )

architecture["version"] = "4.0.1"
architecture["document"] = (
    "docs/architecture/"
    "ARCHITECTURE-CONSTITUTION-V1.md"
)
architecture["contract"] = (
    "docs/architecture/"
    "ARCHITECTURE-CONSTITUTION-V1.json"
)
architecture["validator"] = (
    "src/knowledge/"
    "validate_architecture_constitution.py"
)

architecture.pop("freeze")

architecture["constitution"] = {
    "id": "architecture-constitution-v1",
    "name": "Architecture Constitution V1",
    "status": "immutable",
    "scope": "until_project_completion",
    "principle": "Architettura Granitica",
    "ordinary_change_allowed": False,
    "preference_change_allowed": False,
    "intuition_change_allowed": False,
    "rename_allowed": False,
    "layer_movement_allowed": False,
    "structural_change_performed": False,
}

state["metadata"]["state_version"] = "4.1.1"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

principles = state["spec"].setdefault(
    "principles",
    []
)

old_principle = (
    "Architecture GRANITA Freeze V1 "
    "immutabile fino alla fine del progetto"
)

new_principle = (
    "Architecture Constitution V1 applica il "
    "principio di Architettura Granitica ed è "
    "immutabile fino alla fine del progetto"
)

occurrences = principles.count(old_principle)

if occurrences != 1:
    raise SystemExit(
        "OLD_PRINCIPLE_COUNT_INVALID:"
        + str(occurrences)
    )

principles[
    principles.index(old_principle)
] = new_principle

roadmap = state["spec"]["roadmap"]

current_gate = roadmap["current_gate"]

current_gate["objectives"] = [
    (
        value.replace(
            "Architecture GRANITA Freeze",
            "Architecture Constitution",
        )
    )
    for value in current_gate.get("objectives", [])
]

roadmap["current_gate"] = {
    "runbook": "R3-000009C",
    "title": "Architecture Constitution Terminology",
    "type": "terminology_correction",
    "targets": [
        "architecture document",
        "architecture contract",
        "architecture validator",
        "ADR-0007",
        "STATE.json",
        "canonical README files",
    ],
    "excluded_targets": [
        "architecture structure",
        "domain behavior",
        "application behavior",
        "historical journals",
        "historical runbooks",
        "remote Habitat",
    ],
    "objectives": [
        (
            "rename the official document to "
            "Architecture Constitution V1"
        ),
        (
            "register Architettura Granitica "
            "as the governing principle"
        ),
        "preserve all frozen architectural boundaries",
        "preserve immutable project history",
    ],
    "prohibitions": [
        "no layer changes",
        "no path changes under src/sandra",
        "no domain behavior changes",
        "no historical rewriting",
        "no Habitat modifications",
        "no software installation",
    ],
}

roadmap["next_gate"] = {
    "runbook": "R3-000009D",
    "title": "Constitutional Contracts Foundation",
    "status": "blocked",
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["roadmap"] = {
    "phase": "Architecture Constitution Terminology",
    "current_gate": "R3-000009C",
    "current_gate_status": "complete",
    "next_gate": "R3-000009D",
}

old_status = state["status"].pop(
    "architecture_granita_freeze_v1",
    None,
)

if old_status is None:
    raise SystemExit(
        "OLD_ARCHITECTURE_STATUS_MISSING"
    )

state["status"][
    "architecture_constitution_v1"
] = {
    **old_status,
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified_immutable",
    "id": "architecture-constitution-v1",
    "name": "Architecture Constitution V1",
    "principle": "Architettura Granitica",
    "terminology_corrected": True,
    "structural_change": "none",
    "historical_records_rewritten": False,
}

migration = state["status"].get(
    "canonical_domain_migration_v1"
)

if isinstance(migration, dict):
    migration[
        "architecture_constitution_validation"
    ] = migration.pop(
        "architecture_freeze_validation",
        "pass",
    )

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

python3 -m py_compile "${NEW_VALIDATOR}"

python3 \
    "${NEW_VALIDATOR}" \
    "${NEW_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitution-validation.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitution-validation.txt"

for old_path in \
    "${OLD_DOC}" \
    "${OLD_CONTRACT}" \
    "${OLD_ADR}" \
    "${OLD_VALIDATOR}"
do
    if [[ -e "${old_path}" || -L "${old_path}" ]]; then
        sandra_fail \
            "Old terminology path remains: ${old_path}"
    fi
done

for new_path in \
    "${NEW_DOC}" \
    "${NEW_CONTRACT}" \
    "${NEW_ADR}" \
    "${NEW_VALIDATOR}"
do
    sandra_require_file "${new_path}"
done

python3 - \
    "${STATE}" \
    "${NEW_CONTRACT}" \
    "${SANDRA_EVIDENCE_DIR}/terminology-postcheck.txt" <<'PYTHON'
from __future__ import annotations

import json
from pathlib import Path
import sys

state_path = Path(sys.argv[1])
contract_path = Path(sys.argv[2])
evidence_path = Path(sys.argv[3])

state = json.loads(
    state_path.read_text(encoding="utf-8")
)
contract = json.loads(
    contract_path.read_text(encoding="utf-8")
)

architecture = state["spec"]["architecture"]
constitution = architecture["constitution"]

checks = {
    "state_id": (
        constitution.get("id")
        == "architecture-constitution-v1"
    ),
    "state_name": (
        constitution.get("name")
        == "Architecture Constitution V1"
    ),
    "state_principle": (
        constitution.get("principle")
        == "Architettura Granitica"
    ),
    "contract_kind": (
        contract.get("kind")
        == "ArchitectureConstitution"
    ),
    "contract_id": (
        contract.get("metadata", {}).get("id")
        == "architecture-constitution-v1"
    ),
    "contract_principle": (
        contract.get("metadata", {}).get(
            "principle"
        )
        == "granitic-architecture"
    ),
    "structure_unchanged": (
        constitution.get(
            "structural_change_performed"
        )
        is False
    ),
}

evidence_path.write_text(
    "\n".join(
        f"{key}={'PASS' if value else 'FAIL'}"
        for key, value in checks.items()
    )
    + "\n",
    encoding="utf-8",
)

failed = [
    key
    for key, value in checks.items()
    if not value
]

if failed:
    raise SystemExit(
        "TERMINOLOGY_POSTCHECK_FAILED:"
        + ",".join(failed)
    )

print("TERMINOLOGY_POSTCHECK=PASS")
PYTHON

install -d -m 0755 \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Architecture terminology correction

- Run ID: \`${SANDRA_RUN_ID}\`
- Official name: \`Architecture Constitution V1\`
- Governing principle: \`Architettura Granitica\`
- Structural changes: \`NONE\`
- Historical records rewritten: \`NO\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- corrected the mistaken term \`GRANITA\`;
- renamed the canonical document, contract, ADR and validator;
- registered \`Architettura Granitica\` as a principle;
- preserved every frozen layer and dependency boundary;
- preserved historical journals and historical RunBooks.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: correct architecture constitution terminology"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

python3 \
    "${NEW_VALIDATOR}" \
    "${NEW_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/constitution-post-sync.txt"

grep -q \
    '^ARCHITECTURE_CONSTITUTION=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/constitution-post-sync.txt"

{
    printf 'ARCHITECTURE_TERMINOLOGY=PASS\n'
    printf 'OFFICIAL_NAME=Architecture Constitution V1\n'
    printf 'GOVERNING_PRINCIPLE=Architettura Granitica\n'
    printf 'CONSTITUTION_ID=architecture-constitution-v1\n'
    printf 'STRUCTURAL_CHANGE=NONE\n'
    printf 'HISTORICAL_REWRITE=NO\n'
    printf 'CONSTITUTION_VALIDATION=PASS\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'CONTRACT_SHA256=%s\n' \
        "$(sha256sum "${NEW_CONTRACT}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
