#!/usr/bin/env bash

SANDRA_LINUX_PROVIDER_VERSION="1.1.1"

SANDRA_LINUX_PROVIDER_ROOT="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

SANDRA_LINUX_PYTHON="${SANDRA_LINUX_PYTHON:-/usr/bin/python3}"
SANDRA_LINUX_GET="${SANDRA_LINUX_PROVIDER_ROOT}/get.py"
SANDRA_LINUX_TEST="${SANDRA_LINUX_PROVIDER_ROOT}/test.py"
SANDRA_LINUX_SERVICE_INVENTORY="${SANDRA_LINUX_PROVIDER_ROOT}/service_inventory.py"
SANDRA_LINUX_USER="${SANDRA_LINUX_USER:-root}"
SANDRA_LINUX_PROFILES="${SANDRA_LINUX_PROVIDER_ROOT}/profiles"

_provider_linux_profile_paths() {
    local profile="${1:?Profilo Linux obbligatorio}"
    local common_profile
    local role_profile

    common_profile="${SANDRA_LINUX_PROFILES}/COMMON.md"
    role_profile="${SANDRA_LINUX_PROFILES}/${profile}.md"

    test -f "$common_profile" || {
        printf 'Profilo Linux comune assente: %s\n' \
            "$common_profile" >&2
        return 1
    }

    test -f "$role_profile" || {
        printf 'Profilo Linux assente: %s\n' \
            "$role_profile" >&2
        return 1
    }

    printf '%s|%s\n' \
        "$common_profile" \
        "$role_profile"
}

provider_get() {
    local target_name="${1:?Nome Linux obbligatorio}"
    local target_ip="${2:?IP Linux obbligatorio}"
    local profile="${3:?Profilo Linux obbligatorio}"
    local target_user="${4:-$SANDRA_LINUX_USER}"

    "$SANDRA_LINUX_PYTHON" \
        "$SANDRA_LINUX_GET" \
        "$target_name" \
        "$target_ip" \
        "$profile" \
        "$target_user"
}

provider_test() {
    local current_state_file="${1:?File Current State obbligatorio}"
    local profile="${2:?Profilo Linux obbligatorio}"
    local paths
    local common_profile
    local role_profile

    paths="$(_provider_linux_profile_paths "$profile")"
    common_profile="${paths%%|*}"
    role_profile="${paths##*|}"

    "$SANDRA_LINUX_PYTHON" \
        "$SANDRA_LINUX_TEST" \
        "$current_state_file" \
        "$profile" \
        "$common_profile" \
        "$role_profile"
}

provider_service_inventory() {
    local target_name="${1:?Nome Linux obbligatorio}"
    local target_ip="${2:?IP Linux obbligatorio}"
    local output_file="${3:?File output obbligatorio}"
    local target_user="${4:-$SANDRA_LINUX_USER}"

    "$SANDRA_LINUX_PYTHON" \
        "$SANDRA_LINUX_SERVICE_INVENTORY" \
        host \
        "$target_name" \
        "$target_ip" \
        "$target_user" \
        "$output_file"
}

provider_service_inventory_summary() {
    local inventory_root="${1:?Directory inventari obbligatoria}"
    local output_json="${2:?File riepilogo JSON obbligatorio}"
    local output_text="${3:?File riepilogo testo obbligatorio}"
    local runbook="${4:?RunBook obbligatoria}"
    local run_id="${5:?Run ID obbligatorio}"

    "$SANDRA_LINUX_PYTHON" \
        "$SANDRA_LINUX_SERVICE_INVENTORY" \
        summary \
        "$inventory_root" \
        "$output_json" \
        "$output_text" \
        "$runbook" \
        "$run_id"
}
