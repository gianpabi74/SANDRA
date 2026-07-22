#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

SANDRA_WINDOWS_PROVIDER_VERSION="1.5.0"
SANDRA_WINDOWS_PROVIDER_ROOT="/opt/sandra/provider/windows"
SANDRA_WINDOWS_PYTHON="${SANDRA_WINDOWS_PROVIDER_ROOT}/.venv/bin/python"
SANDRA_WINDOWS_GET="${SANDRA_WINDOWS_PROVIDER_ROOT}/get.py"
SANDRA_WINDOWS_TEST="${SANDRA_WINDOWS_PROVIDER_ROOT}/test.py"
SANDRA_WINDOWS_SET="${SANDRA_WINDOWS_PROVIDER_ROOT}/set.py"
SANDRA_WINDOWS_USER="${SANDRA_WINDOWS_USER:-BIONDRA\\administrator}"
SANDRA_WINDOWS_PROFILE_ROOT="/opt/sandra/knowledge/docs/providers/windows"

_provider_windows_profile_paths() {
    local profile="${1:?Profilo Windows obbligatorio}"

    case "$profile" in
        DOMAIN_CONTROLLER)
            printf '%s|%s\n' \
                "${SANDRA_WINDOWS_PROFILE_ROOT}/PROFILE-COMMON.md" \
                "${SANDRA_WINDOWS_PROFILE_ROOT}/PROFILE-DOMAIN-CONTROLLER.md"
            ;;
        SERVICES_SERVER)
            printf '%s|%s\n' \
                "${SANDRA_WINDOWS_PROFILE_ROOT}/PROFILE-COMMON.md" \
                "${SANDRA_WINDOWS_PROFILE_ROOT}/PROFILE-SERVICES-SERVER.md"
            ;;
        *)
            printf 'Profilo Windows non valido: %s\n' "$profile" >&2
            return 40
            ;;
    esac
}

provider_get() {
    local target_name="${1:?Nome Windows obbligatorio}"
    local target_ip="${2:?IP Windows obbligatorio}"
    local profile="${3:?Profilo Windows obbligatorio}"
    local paths
    local common_profile
    local role_profile

    paths="$(_provider_windows_profile_paths "$profile")"
    common_profile="${paths%%|*}"
    role_profile="${paths##*|}"

    "$SANDRA_WINDOWS_PYTHON" \
        "$SANDRA_WINDOWS_GET" \
        "$target_name" \
        "$target_ip" \
        "$profile" \
        "$SANDRA_WINDOWS_USER" \
        "$common_profile" \
        "$role_profile"
}

provider_test() {
    local current_state_file="${1:?File Current State obbligatorio}"
    local profile="${2:?Profilo Windows obbligatorio}"
    local paths
    local common_profile
    local role_profile

    paths="$(_provider_windows_profile_paths "$profile")"
    common_profile="${paths%%|*}"
    role_profile="${paths##*|}"

    "$SANDRA_WINDOWS_PYTHON" \
        "$SANDRA_WINDOWS_TEST" \
        "$current_state_file" \
        "$profile" \
        "$common_profile" \
        "$role_profile"
}

provider_set() {
    local test_result_file="${1:?File Test obbligatorio}"
    local approved_delta_file="${2:?File approvazione obbligatorio}"

    "$SANDRA_WINDOWS_PYTHON"         "$SANDRA_WINDOWS_SET"         "$test_result_file"         "$approved_delta_file"
}
