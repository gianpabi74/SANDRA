#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000006A-core-expected-failure-contract.sh"

sandra_begin \
    "R3-000006A" \
    "Add expected-failure contract to CORE"

for command_name in \
    python3 git install cp cmp sha256sum bash grep
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

CANONICAL_CORE="${ROOT}/src/core/core.sh"
CANONICAL_VERSION="${ROOT}/src/core/VERSION"

RUNTIME_CORE="/opt/sandra/core/core.sh"
RUNTIME_VERSION="/opt/sandra/core/VERSION"

WORK_ROOT="${SANDRA_RUN_DIR}/core-candidate"
CANDIDATE_CORE="${WORK_ROOT}/core.sh"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${CANONICAL_CORE}"
sandra_require_file "${RUNTIME_CORE}"

install -d -m 0700 \
    "${WORK_ROOT}" \
    "${BACKUP_ROOT}"

cp -a -- \
    "${CANONICAL_CORE}" \
    "${BACKUP_ROOT}/canonical-core.sh.before"

cp -a -- \
    "${RUNTIME_CORE}" \
    "${BACKUP_ROOT}/runtime-core.sh.before"

if [[ -f "${CANONICAL_VERSION}" ]]; then
    cp -a -- \
        "${CANONICAL_VERSION}" \
        "${BACKUP_ROOT}/canonical-VERSION.before"
fi

if [[ -f "${RUNTIME_VERSION}" ]]; then
    cp -a -- \
        "${RUNTIME_VERSION}" \
        "${BACKUP_ROOT}/runtime-VERSION.before"
fi

cp -a -- "${CANONICAL_CORE}" "${CANDIDATE_CORE}"

python3 - "${CANDIDATE_CORE}" <<'PYTHON'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

replacements = (
    (
        'SANDRA_CORE_VERSION="1.1.1"',
        'SANDRA_CORE_VERSION="1.2.0"',
        "core-version",
    ),
    (
        '''sandra_capture() {
    local name="$1"
    shift

    [[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]] || {
        sandra_log ERROR "Nome evidenza non valido: ${name}"
        return 1
    }

    "$@" > "${SANDRA_EVIDENCE_DIR}/${name}" 2>&1
}

sandra_error_handler() {
''',
        '''sandra_capture() {
    local name="$1"
    shift

    [[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]] || {
        sandra_log ERROR "Nome evidenza non valido: ${name}"
        return 1
    }

    "$@" > "${SANDRA_EVIDENCE_DIR}/${name}" 2>&1
}

sandra_expect_failure() {
    local evidence_name="$1"
    local expected_rc="$2"
    shift 2

    [[ "${evidence_name}" =~ ^[A-Za-z0-9._-]+$ ]] || {
        sandra_log ERROR \
            "Nome evidenza non valido: ${evidence_name}"
        return 1
    }

    [[ "${expected_rc}" == "ANY" ||
       "${expected_rc}" =~ ^[1-9][0-9]*$ ]] || {
        sandra_log ERROR \
            "Exit code atteso non valido: ${expected_rc}"
        return 1
    }

    [[ "$#" -gt 0 ]] || {
        sandra_log ERROR \
            "Comando assente per sandra_expect_failure"
        return 1
    }

    local output_file
    local result_file
    local actual_rc

    output_file="${SANDRA_EVIDENCE_DIR}/${evidence_name}"
    result_file="${output_file}.result.env"

    # Il comando è deliberatamente eseguito come condizione di un if.
    # Bash non attiva ERR per comandi usati come test condizionali.
    if "$@" > "${output_file}" 2>&1; then
        actual_rc=0
    else
        actual_rc=$?
    fi

    {
        printf 'EXPECTED_RC=%s\\n' "${expected_rc}"
        printf 'ACTUAL_RC=%s\\n' "${actual_rc}"
    } > "${result_file}"

    if [[ "${actual_rc}" -eq 0 ]]; then
        printf 'RESULT=UNEXPECTED_SUCCESS\\n' \
            >> "${result_file}"

        sandra_log ERROR \
            "Il comando doveva fallire ma ha restituito rc=0"
        return 1
    fi

    if [[ "${expected_rc}" != "ANY" &&
          "${actual_rc}" -ne "${expected_rc}" ]]; then
        printf 'RESULT=UNEXPECTED_EXIT_CODE\\n' \
            >> "${result_file}"

        sandra_log ERROR \
            "Exit code inatteso: atteso=${expected_rc} reale=${actual_rc}"
        return 1
    fi

    printf 'RESULT=EXPECTED_FAILURE\\n' \
        >> "${result_file}"

    sandra_log INFO \
        "EXPECTED_FAILURE=${evidence_name} rc=${actual_rc}"

    return 0
}

sandra_error_handler() {
''',
        "expected-failure-api",
    ),
    (
        '''    if [[ "${rc}" -eq 0 && "${SANDRA_STATUS}" == "PASS" ]]; then
        SANDRA_PHASE="COMPLETE"
    else
        SANDRA_STATUS="FAIL"
    fi

    cat > "${SANDRA_RUN_DIR}/certification.txt" <<EOF
''',
        '''    local unhandled_error="NO"

    if [[ -s "${SANDRA_RUN_DIR}/error.txt" ]]; then
        unhandled_error="YES"
    fi

    if [[ "${rc}" -eq 0 &&
          "${SANDRA_STATUS}" == "PASS" &&
          "${unhandled_error}" == "NO" ]]; then
        SANDRA_PHASE="COMPLETE"
    else
        SANDRA_STATUS="FAIL"

        if [[ "${unhandled_error}" == "YES" ]]; then
            SANDRA_PHASE="ERROR"
        fi
    fi

    cat > "${SANDRA_RUN_DIR}/certification.txt" <<EOF
''',
        "finalization-guard",
    ),
    (
        '''STATUS=${SANDRA_STATUS}
FINAL_PHASE=${SANDRA_PHASE}
EXIT_CODE=${rc}
''',
        '''STATUS=${SANDRA_STATUS}
FINAL_PHASE=${SANDRA_PHASE}
UNHANDLED_ERROR=${unhandled_error}
EXIT_CODE=${rc}
''',
        "certification-field",
    ),
)

for old, new, label in replacements:
    count = text.count(old)

    if count != 1:
        raise SystemExit(
            f"PATCH_TARGET_INVALID:{label}:{count}"
        )

    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
PYTHON

chmod 0600 "${CANDIDATE_CORE}"
bash -n "${CANDIDATE_CORE}"

grep -nE \
    'SANDRA_CORE_VERSION|sandra_expect_failure|UNHANDLED_ERROR' \
    "${CANDIDATE_CORE}" \
    > "${SANDRA_EVIDENCE_DIR}/candidate-contract.txt"

# Test 1: il fallimento atteso non deve attivare error.txt.
TEST_ROOT="${SANDRA_RUN_DIR}/core-unit-tests"
install -d -m 0700 "${TEST_ROOT}/evidence"

CANDIDATE_CORE="${CANDIDATE_CORE}" \
TEST_ROOT="${TEST_ROOT}" \
bash <<'TEST_BASH'
set -Eeuo pipefail

source "${CANDIDATE_CORE}"

export SANDRA_RUN_DIR="${TEST_ROOT}"
export SANDRA_EVIDENCE_DIR="${TEST_ROOT}/evidence"

trap 'sandra_error_handler' ERR

sandra_expect_failure \
    "expected-rc-5.txt" \
    "5" \
    bash -c 'printf "EXPECTED NEGATIVE TEST\n"; exit 5'

test ! -e "${SANDRA_RUN_DIR}/error.txt"

grep -q \
    '^ACTUAL_RC=5$' \
    "${SANDRA_EVIDENCE_DIR}/expected-rc-5.txt.result.env"

grep -q \
    '^RESULT=EXPECTED_FAILURE$' \
    "${SANDRA_EVIDENCE_DIR}/expected-rc-5.txt.result.env"
TEST_BASH

# Test 2: ANY accetta qualsiasi rc non zero.
CANDIDATE_CORE="${CANDIDATE_CORE}" \
TEST_ROOT="${TEST_ROOT}" \
bash <<'TEST_BASH'
set -Eeuo pipefail

source "${CANDIDATE_CORE}"

export SANDRA_RUN_DIR="${TEST_ROOT}"
export SANDRA_EVIDENCE_DIR="${TEST_ROOT}/evidence"

trap 'sandra_error_handler' ERR

sandra_expect_failure \
    "expected-any.txt" \
    "ANY" \
    bash -c 'exit 17'

test ! -e "${SANDRA_RUN_DIR}/error.txt"

grep -q \
    '^ACTUAL_RC=17$' \
    "${SANDRA_EVIDENCE_DIR}/expected-any.txt.result.env"

grep -q \
    '^RESULT=EXPECTED_FAILURE$' \
    "${SANDRA_EVIDENCE_DIR}/expected-any.txt.result.env"
TEST_BASH

# Test 3: un successo inatteso deve essere intercettato dal chiamante,
# senza creare un falso errore del framework.
CANDIDATE_CORE="${CANDIDATE_CORE}" \
TEST_ROOT="${TEST_ROOT}" \
bash <<'TEST_BASH'
set -Eeuo pipefail

source "${CANDIDATE_CORE}"

export SANDRA_RUN_DIR="${TEST_ROOT}"
export SANDRA_EVIDENCE_DIR="${TEST_ROOT}/evidence"

trap 'sandra_error_handler' ERR

if sandra_expect_failure \
    "unexpected-success.txt" \
    "ANY" \
    true
then
    printf 'UNEXPECTED_TEST_RESULT\n' >&2
    exit 91
fi

test ! -e "${SANDRA_RUN_DIR}/error.txt"

grep -q \
    '^ACTUAL_RC=0$' \
    "${SANDRA_EVIDENCE_DIR}/unexpected-success.txt.result.env"

grep -q \
    '^RESULT=UNEXPECTED_SUCCESS$' \
    "${SANDRA_EVIDENCE_DIR}/unexpected-success.txt.result.env"
TEST_BASH

# Verifica pubblicazione solo dopo il superamento dei test.
install -m 0600 \
    "${CANDIDATE_CORE}" \
    "${CANONICAL_CORE}"

printf '1.2.0\n' > "${CANONICAL_VERSION}"
chmod 0600 "${CANONICAL_VERSION}"

install -m 0600 \
    "${CANONICAL_CORE}" \
    "${RUNTIME_CORE}"

printf '1.2.0\n' > "${RUNTIME_VERSION}"
chmod 0600 "${RUNTIME_VERSION}"

bash -n "${CANONICAL_CORE}"
bash -n "${RUNTIME_CORE}"

cmp -s "${CANONICAL_CORE}" "${RUNTIME_CORE}"
cmp -s "${CANONICAL_VERSION}" "${RUNTIME_VERSION}"

grep -q \
    '^SANDRA_CORE_VERSION="1.2.0"$' \
    "${CANONICAL_CORE}"

grep -q \
    '^sandra_expect_failure() {$' \
    "${CANONICAL_CORE}"

python3 - \
    "${STATE}" \
    "${SANDRA_RUNBOOK_ID}" \
    "${SANDRA_RUN_ID}" \
    "${JOURNAL#${ROOT}/}" <<'PYTHON'
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

state["metadata"]["state_version"] = "3.5.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(datetime.timezone.utc)
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["components"]["core"]["version"] = "1.2.0"

state["spec"]["components"]["core"]["contract"] = (
    "runtime_runbook_lifecycle_and_expected_failure_handling"
)

state["status"]["components"]["core"] = {
    "version": "1.2.0",
    "status": "stable",
    "capabilities": [
        "Run Bundle",
        "evidence",
        "journaling",
        "Knowledge",
        "Git synchronization",
        "expected failure isolation",
        "unhandled error certification guard",
    ],
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal,
}

state["status"]["core_expected_failure_contract"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "implemented",
    "core_version": "1.2.0",
    "api": "sandra_expect_failure",
    "unhandled_error_guard": "enabled",
    "runtime_source_alignment": "byte_identical",
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
# ${SANDRA_RUNBOOK_ID} — CORE expected-failure contract

- Run ID: \`${SANDRA_RUN_ID}\`
- Core version: \`1.2.0\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- added \`sandra_expect_failure\`;
- expected negative tests no longer activate the global ERR handler;
- final certification cannot be PASS when \`error.txt\` contains an
  unhandled error;
- canonical and runtime Core are byte-identical;
- positive, expected-failure and unexpected-success tests passed.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: add CORE expected-failure contract"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'CORE_FIX=PASS\n'
    printf 'CORE_VERSION=1.2.0\n'
    printf 'EXPECTED_FAILURE_API=sandra_expect_failure\n'
    printf 'EXPECTED_RC_TEST=PASS\n'
    printf 'EXPECTED_ANY_TEST=PASS\n'
    printf 'UNEXPECTED_SUCCESS_TEST=PASS\n'
    printf 'UNHANDLED_ERROR_GUARD=ENABLED\n'
    printf 'CANONICAL_RUNTIME_ALIGNMENT=BYTE_IDENTICAL\n'
    printf 'CANONICAL_SHA256=%s\n' \
        "$(sha256sum "${CANONICAL_CORE}" | awk '{print $1}')"
    printf 'RUNTIME_SHA256=%s\n' \
        "$(sha256sum "${RUNTIME_CORE}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
