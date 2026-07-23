#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

SANDRA_CORE_VERSION="1.2.0"
SANDRA_CORE_CONFIG="/opt/sandra/config/habitat.conf"

SANDRA_FINALIZED="${SANDRA_FINALIZED:-NO}"
SANDRA_STATUS="${SANDRA_STATUS:-FAIL}"
SANDRA_PHASE="${SANDRA_PHASE:-NOT_STARTED}"
SANDRA_START_EPOCH="${SANDRA_START_EPOCH:-0}"

sandra_log() {
    local level="$1"
    shift
    printf '%s [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${level}" "$*"
}

sandra_require_command() {
    command -v "$1" >/dev/null || {
        sandra_log ERROR "Comando richiesto assente: $1"
        return 1
    }
}

sandra_require_file() {
    [[ -s "$1" ]] || {
        sandra_log ERROR "File richiesto assente o vuoto: $1"
        return 1
    }
}

sandra_assert() {
    "$@" || {
        local rc=$?
        sandra_log ERROR "Asserzione fallita, rc=${rc}: $*"
        return "${rc}"
    }
}

sandra_capture() {
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
        sandra_log ERROR             "Nome evidenza non valido: ${evidence_name}"
        return 1
    }

    [[ "${expected_rc}" == "ANY" ||
       "${expected_rc}" =~ ^[1-9][0-9]*$ ]] || {
        sandra_log ERROR             "Exit code atteso non valido: ${expected_rc}"
        return 1
    }

    [[ "$#" -gt 0 ]] || {
        sandra_log ERROR             "Comando assente per sandra_expect_failure"
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
        printf 'EXPECTED_RC=%s\n' "${expected_rc}"
        printf 'ACTUAL_RC=%s\n' "${actual_rc}"
    } > "${result_file}"

    if [[ "${actual_rc}" -eq 0 ]]; then
        printf 'RESULT=UNEXPECTED_SUCCESS\n'             >> "${result_file}"

        sandra_log ERROR             "Il comando doveva fallire ma ha restituito rc=0"
        return 1
    fi

    if [[ "${expected_rc}" != "ANY" &&
          "${actual_rc}" -ne "${expected_rc}" ]]; then
        printf 'RESULT=UNEXPECTED_EXIT_CODE\n'             >> "${result_file}"

        sandra_log ERROR             "Exit code inatteso: atteso=${expected_rc} reale=${actual_rc}"
        return 1
    fi

    printf 'RESULT=EXPECTED_FAILURE\n'         >> "${result_file}"

    sandra_log INFO         "EXPECTED_FAILURE=${evidence_name} rc=${actual_rc}"

    return 0
}

sandra_error_handler() {
    local rc=$?
    local source_file="${BASH_SOURCE[1]:-UNKNOWN}"
    local source_line="${BASH_LINENO[0]:-${LINENO}}"
    local source_function="${FUNCNAME[1]:-main}"
    local failed_command="${BASH_COMMAND:-UNKNOWN}"

    SANDRA_PHASE="ERROR"

    if [[ -n "${SANDRA_RUN_DIR:-}" && -d "${SANDRA_RUN_DIR}" ]]; then
        {
            printf 'EXIT_CODE=%s\n' "${rc}"
            printf 'SOURCE_FILE=%s\n' "${source_file}"
            printf 'SOURCE_LINE=%s\n' "${source_line}"
            printf 'FUNCTION=%s\n' "${source_function}"
            printf 'COMMAND=%s\n' "${failed_command}"
            printf 'TIMESTAMP_UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        } > "${SANDRA_RUN_DIR}/error.txt"
    fi

    sandra_log ERROR \
        "rc=${rc} file=${source_file} line=${source_line} function=${source_function} command=${failed_command}"

    return "${rc}"
}

sandra_begin() {
    local runbook_id="$1"
    local title="$2"
    local caller="${BASH_SOURCE[1]:-}"

    [[ "$(id -u)" -eq 0 ]] || {
        printf 'FATAL: eseguire il runbook come root.\n' >&2
        return 10
    }

    source "${SANDRA_CORE_CONFIG}"

    local command_name
    for command_name in bash flock tar ssh scp sha256sum stat; do
        sandra_require_command "${command_name}"
    done

    local utc
    local nonce

    utc="$(date -u +%Y%m%dT%H%M%SZ)"
    nonce="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"

    export SANDRA_RUNBOOK_ID="${runbook_id}"
    export SANDRA_RUNBOOK_TITLE="${title}"
    export SANDRA_RUN_ID="${runbook_id}-${utc}-${nonce}"
    export SANDRA_RUN_DIR="${SANDRA_RUN_ROOT}/${SANDRA_RUN_ID}"
    export SANDRA_EVIDENCE_DIR="${SANDRA_RUN_DIR}/evidence"
    export SANDRA_ARTIFACT="${SANDRA_ARTIFACT_ROOT}/sandra-${SANDRA_RUN_ID}.tar.gz"

    install -d -m 0700 "${SANDRA_RUN_ROOT}"
    install -d -m 0700 "${SANDRA_RUN_DIR}"
    install -d -m 0700 "${SANDRA_EVIDENCE_DIR}"
    install -d -m 0700 "${SANDRA_ARTIFACT_ROOT}"
    install -d -m 0755 "$(dirname "${SANDRA_LOCK_FILE}")"

    exec 9>"${SANDRA_LOCK_FILE}"
    flock -n 9 || {
        sandra_log ERROR "Un altro runbook SANDRA è già attivo."
        return 20
    }

    exec > >(tee -a "${SANDRA_RUN_DIR}/run.log") 2>&1

    SANDRA_START_EPOCH="$(date +%s)"
    SANDRA_PHASE="RUNNING"

    if [[ -n "${SANDRA_RUNBOOK_SOURCE:-}" && -f "${SANDRA_RUNBOOK_SOURCE}" ]]; then
        install -m 0600 "${SANDRA_RUNBOOK_SOURCE}" "${SANDRA_RUN_DIR}/runbook.sh"
    elif [[ -f "${caller}" && "${caller}" != "/dev/stdin" ]]; then
        install -m 0600 "${caller}" "${SANDRA_RUN_DIR}/runbook.sh"
    else
        printf '%s\n' \
            "RUNBOOK_SOURCE=UNAVAILABLE_STDIN" \
            "Per acquisire il Bash esatto, eseguire il runbook da un file." \
            > "${SANDRA_RUN_DIR}/runbook-source.txt"
    fi

    trap 'sandra_error_handler' ERR
    trap 'sandra_finalize "$?"' EXIT

    sandra_log INFO "RUNBOOK_START=${SANDRA_RUNBOOK_ID}"
    sandra_log INFO "TITLE=${SANDRA_RUNBOOK_TITLE}"
    sandra_log INFO "RUN_ID=${SANDRA_RUN_ID}"
    sandra_log INFO "CORE_VERSION=${SANDRA_CORE_VERSION}"
}

sandra_finalize() {
    local rc="$1"

    [[ "${SANDRA_FINALIZED}" == "NO" ]] || return 0
    SANDRA_FINALIZED="YES"

    trap - ERR EXIT
    set +e

    local end_epoch
    local duration
    end_epoch="$(date +%s)"
    duration=$((end_epoch - SANDRA_START_EPOCH))

    local unhandled_error="NO"

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
RUNBOOK_ID=${SANDRA_RUNBOOK_ID}
RUNBOOK_TITLE=${SANDRA_RUNBOOK_TITLE}
RUN_ID=${SANDRA_RUN_ID}
CORE_VERSION=${SANDRA_CORE_VERSION}
STATUS=${SANDRA_STATUS}
FINAL_PHASE=${SANDRA_PHASE}
UNHANDLED_ERROR=${unhandled_error}
EXIT_CODE=${rc}
DURATION_SECONDS=${duration}
HOSTNAME=$(hostname)
OPERATING_SYSTEM=$(source /etc/os-release; printf '%s' "${PRETTY_NAME}")
KERNEL=$(uname -r)
TIMESTAMP_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

    chmod 0600 "${SANDRA_RUN_DIR}/certification.txt"

    rm -f "${SANDRA_ARTIFACT}"
    tar --owner=0 --group=0 --numeric-owner \
        -C "${SANDRA_RUN_DIR}" -czf "${SANDRA_ARTIFACT}" .

    local name
    local local_size
    local local_sha
    local remote_size=""
    local remote_sha=""
    local export_status="FAIL"

    name="$(basename "${SANDRA_ARTIFACT}")"
    local_size="$(stat -c '%s' "${SANDRA_ARTIFACT}")"
    local_sha="$(sha256sum "${SANDRA_ARTIFACT}" | awk '{print $1}')"

    local ssh_options
    ssh_options=(
        -i "${SANDRA_EXPORT_KEY}"
        -o BatchMode=yes
        -o PasswordAuthentication=no
        -o KbdInteractiveAuthentication=no
        -o IdentitiesOnly=yes
        -o StrictHostKeyChecking=yes
        -o ConnectTimeout=10
    )

    if ssh "${ssh_options[@]}" \
        "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" \
        "test -d '${SANDRA_EXPORT_PATH}' && test -w '${SANDRA_EXPORT_PATH}'"; then

        if scp -q "${ssh_options[@]}" \
            "${SANDRA_ARTIFACT}" \
            "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}:${SANDRA_EXPORT_PATH}/${name}"; then

            remote_size="$(
                ssh "${ssh_options[@]}" \
                    "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" \
                    "stat -f '%z' '${SANDRA_EXPORT_PATH}/${name}'"
            )"

            remote_sha="$(
                ssh "${ssh_options[@]}" \
                    "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" \
                    "shasum -a 256 '${SANDRA_EXPORT_PATH}/${name}' | awk '{print \$1}'"
            )"

            if [[ "${local_size}" == "${remote_size}" &&
                  "${local_sha}" == "${remote_sha}" ]]; then
                export_status="PASS"
            fi
        fi
    fi

    printf '\nSTATUS=%s\n' "${SANDRA_STATUS}"
    printf 'CORE_VERSION=%s\n' "${SANDRA_CORE_VERSION}"
    printf 'ARTIFACT_EXPORT=%s\n' "${export_status}"
    printf 'ARTIFACT_PATH=%s\n' "${SANDRA_ARTIFACT}"
    printf 'MAC_PATH=%s/%s\n' "${SANDRA_EXPORT_PATH}" "${name}"
    printf 'LOCAL_SIZE_BYTES=%s\n' "${local_size}"
    printf 'REMOTE_SIZE_BYTES=%s\n' "${remote_size:-UNAVAILABLE}"
    printf 'LOCAL_SHA256=%s\n' "${local_sha}"
    printf 'REMOTE_SHA256=%s\n' "${remote_sha:-UNAVAILABLE}"
    printf 'RUNBOOK_END=%s\n' "${SANDRA_RUNBOOK_ID}"

    if [[ "${export_status}" != "PASS" ]]; then
        exit 80
    fi

    exit "${rc}"
}

sandra_end() {
    local requested_status="${1:-PASS}"

    [[ "${requested_status}" == "PASS" ]] || {
        sandra_log ERROR "Stato finale non valido: ${requested_status}"
        return 30
    }

    SANDRA_STATUS="PASS"
    SANDRA_PHASE="COMPLETE"
}

sandra_fail() {
    sandra_log ERROR "$*"
    return 1
}
