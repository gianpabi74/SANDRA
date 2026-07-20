#!/usr/bin/env bash

set -Eeuo pipefail
umask 077

readonly SANDRA_CORE_VERSION="1.0.0"
readonly SANDRA_CORE_CONFIG="/opt/sandra/config/habitat.conf"

SANDRA_FINALIZED="NO"
SANDRA_STATUS="FAIL"
SANDRA_PHASE="NOT_STARTED"

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
        sandra_log ERROR "Asserzione fallita, exit code ${rc}: $*"
        return "${rc}"
    }
}

sandra_capture() {
    local evidence_name="$1"
    shift

    [[ "${evidence_name}" =~ ^[A-Za-z0-9._-]+$ ]] || {
        sandra_log ERROR "Nome evidenza non valido: ${evidence_name}"
        return 1
    }

    "$@" > "${SANDRA_EVIDENCE_DIR}/${evidence_name}" 2>&1
}

sandra_begin() {
    local runbook_id="$1"
    local title="$2"

    [[ "$(id -u)" -eq 0 ]] || {
        echo "FATAL: il runbook deve essere eseguito come root." >&2
        return 10
    }

    source "${SANDRA_CORE_CONFIG}"

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

    SANDRA_PHASE="RUNNING"

    trap 'SANDRA_PHASE="ERROR_LINE_${LINENO}"' ERR
    trap 'sandra_finalize "$?"' EXIT

    sandra_log INFO "RUNBOOK_START=${SANDRA_RUNBOOK_ID}"
    sandra_log INFO "TITLE=${SANDRA_RUNBOOK_TITLE}"
    sandra_log INFO "RUN_ID=${SANDRA_RUN_ID}"
}

sandra_finalize() {
    local rc="$1"

    [[ "${SANDRA_FINALIZED}" == "NO" ]] || return 0
    SANDRA_FINALIZED="YES"

    trap - ERR EXIT
    set +e

    if [[ "${rc}" -eq 0 && "${SANDRA_STATUS}" == "PASS" ]]; then
        SANDRA_PHASE="COMPLETE"
    else
        SANDRA_STATUS="FAIL"
    fi

    cat > "${SANDRA_RUN_DIR}/certification.txt" <<EOF
RUNBOOK_ID=${SANDRA_RUNBOOK_ID}
RUNBOOK_TITLE=${SANDRA_RUNBOOK_TITLE}
RUN_ID=${SANDRA_RUN_ID}
CORE_VERSION=${SANDRA_CORE_VERSION}
STATUS=${SANDRA_STATUS}
FINAL_PHASE=${SANDRA_PHASE}
EXIT_CODE=${rc}
HOSTNAME=$(hostname)
OPERATING_SYSTEM=$(source /etc/os-release; printf '%s' "${PRETTY_NAME}")
KERNEL=$(uname -r)
TIMESTAMP_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

    chmod 0600 "${SANDRA_RUN_DIR}/certification.txt"

    rm -f "${SANDRA_ARTIFACT}"
    tar --owner=0 --group=0 --numeric-owner -C "${SANDRA_RUN_DIR}" -czf "${SANDRA_ARTIFACT}" .

    local name
    local local_size
    local local_sha
    local remote_size
    local remote_sha
    local export_status

    name="$(basename "${SANDRA_ARTIFACT}")"
    local_size="$(stat -c '%s' "${SANDRA_ARTIFACT}")"
    local_sha="$(sha256sum "${SANDRA_ARTIFACT}" | awk '{print $1}')"
    export_status="FAIL"

    local ssh_options
    ssh_options=(-i "${SANDRA_EXPORT_KEY}" -o BatchMode=yes -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o ConnectTimeout=10)

    if ssh "${ssh_options[@]}" "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" "test -d '${SANDRA_EXPORT_PATH}' && test -w '${SANDRA_EXPORT_PATH}'"; then
        if scp -q "${ssh_options[@]}" "${SANDRA_ARTIFACT}" "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}:${SANDRA_EXPORT_PATH}/${name}"; then
            remote_size="$(ssh "${ssh_options[@]}" "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" "stat -f '%z' '${SANDRA_EXPORT_PATH}/${name}'")"
            remote_sha="$(ssh "${ssh_options[@]}" "${SANDRA_EXPORT_USER}@${SANDRA_EXPORT_HOST}" "shasum -a 256 '${SANDRA_EXPORT_PATH}/${name}' | awk '{print \$1}'")"

            if [[ "${local_size}" == "${remote_size}" && "${local_sha}" == "${remote_sha}" ]]; then
                export_status="PASS"
            fi
        fi
    fi

    printf '\nSTATUS=%s\n' "${SANDRA_STATUS}"
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
    return 0
}

sandra_fail() {
    sandra_log ERROR "$*"
    return 1
}
