#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000007A-stage-domain-source.sh"

sandra_begin \
    "R3-000007A" \
    "Stage verified domain source"

for command_name in \
    python3 git install cp mv find grep sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
SOURCE_ROOT="${ROOT}/src/runtime"
SOURCE_PACKAGE="${SOURCE_ROOT}/governance"
SOURCE_TESTS="${SOURCE_ROOT}/tests"

DOMAIN_ROOT="${ROOT}/src/domain"
STAGING_ROOT="${SANDRA_RUN_DIR}/domain"

EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${SOURCE_PACKAGE}/__init__.py"
sandra_require_file "${SOURCE_PACKAGE}/validation.py"
sandra_require_file "${SOURCE_TESTS}/test_validation.py"
sandra_require_file \
    "${EXAMPLE_ROOT}/managed-object.example.json"

if [[ -e "${DOMAIN_ROOT}" ]]; then
    sandra_fail "Target già esistente: ${DOMAIN_ROOT}"
fi

install -d -m 0700 "${STAGING_ROOT}"

cp -a -- \
    "${SOURCE_PACKAGE}" \
    "${STAGING_ROOT}/governance"

cp -a -- \
    "${SOURCE_TESTS}" \
    "${STAGING_ROOT}/tests"

cat > "${STAGING_ROOT}/README.md" <<'EOF'
# Domain

Modello di dominio indipendente da runtime, interfacce e tecnologie concrete.

Il dominio contiene tipi, contratti, errori e validazione deterministica.

Sono vietate dipendenze verso:

- provider e adapter concreti;
- API di prodotti;
- configurazioni dell'Habitat;
- credenziali;
- servizi runtime;
- interfacce utente.
EOF

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${STAGING_ROOT}" \
python3 -m unittest discover \
    -s "${STAGING_ROOT}/tests" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-unit-tests.txt" \
    2>&1

mapfile -t EXAMPLE_FILES < <(
    find "${EXAMPLE_ROOT}" \
        -maxdepth 1 \
        -type f \
        -name '*.json' \
        | sort
)

[[ "${#EXAMPLE_FILES[@]}" -gt 0 ]] \
    || sandra_fail "Nessun esempio canonico trovato"

PYTHONPATH="${STAGING_ROOT}" \
python3 -m governance \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/domain-resource-validation.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/domain-resource-validation.json" \
    "${#EXAMPLE_FILES[@]}" <<'PYTHON'
import json
from pathlib import Path
import sys

path = Path(sys.argv[1])
expected_count = int(sys.argv[2])

results = json.loads(path.read_text(encoding="utf-8"))

if len(results) != expected_count:
    raise SystemExit(
        f"RESULT_COUNT_INVALID:{len(results)}:{expected_count}"
    )

failed = [
    result
    for result in results
    if result.get("status") != "PASS"
]

if failed:
    raise SystemExit(
        "RESOURCE_VALIDATION_FAILED:"
        + json.dumps(failed, ensure_ascii=False)
    )

print("DOMAIN_RESOURCE_VALIDATION=PASS")
PYTHON

if grep -RInE \
    --include='*.py' \
    '\b(proxmox|pve|pbs|vmware|vsphere|windows|linux|ansible|nmap)\b' \
    "${STAGING_ROOT}/governance" \
    > "${SANDRA_EVIDENCE_DIR}/forbidden-domain-references.txt"
then
    cat "${SANDRA_EVIDENCE_DIR}/forbidden-domain-references.txt"
    sandra_fail "Dipendenze tecnologiche trovate nel dominio"
fi

mv -- "${STAGING_ROOT}" "${DOMAIN_ROOT}"

sandra_assert test -d "${DOMAIN_ROOT}/governance"
sandra_assert test -d "${DOMAIN_ROOT}/tests"
sandra_assert test -d "${SOURCE_ROOT}/governance"

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${DOMAIN_ROOT}" \
python3 -m unittest discover \
    -s "${DOMAIN_ROOT}/tests" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/domain-unit-tests-published.txt" \
    2>&1

install -d -m 0755 \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Stage domain source

- Run ID: \`${SANDRA_RUN_ID}\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- created \`src/domain\`;
- copied and certified the governance package;
- copied and certified portable tests;
- preserved \`src/runtime\` unchanged;
- no manifest or STATE modification performed.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: stage verified domain source"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'DOMAIN_STAGING=PASS\n'
    printf 'DOMAIN_PATH=src/domain\n'
    printf 'SOURCE_RUNTIME_PRESERVED=YES\n'
    printf 'UNIT_TESTS=PASS\n'
    printf 'RESOURCE_VALIDATION=PASS\n'
    printf 'MANIFEST_MODIFIED=NO\n'
    printf 'STATE_MODIFIED=NO\n'
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
