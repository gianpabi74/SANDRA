#!/usr/bin/env bash

SANDRA_PVE_PROVIDER_VERSION="1.7.0"
SANDRA_PVE_HOST="${SANDRA_PVE_HOST:-192.168.1.191}"
SANDRA_PVE_KEY="${SANDRA_PVE_KEY:-/root/.ssh/sandra_hypervisor_ed25519}"

provider_connect() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" '
            set -eu
            test "$(id -un)" = root
            test "$(hostname)" = pve
            command -v pvesh >/dev/null
            command -v qm >/dev/null
            command -v pct >/dev/null
            command -v pvesm >/dev/null
            printf "PVE_CONNECTION=PASS\n"
            printf "PVE_HOST=%s\n" "$(hostname)"
        '
}


provider_version() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'pvesh get /version --output-format json'
}


provider_nodes() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'pvesh get /nodes --output-format json'
}


provider_resources() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'pvesh get /cluster/resources --output-format json'
}


provider_vms() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'qm list'
}


provider_containers() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'pct list'
}


provider_storage() {
    ssh \
        -i "${SANDRA_PVE_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PVE_HOST}" \
        'pvesm status'
}


provider_start() {
    local object_id="${1:?Object ID obbligatorio: qemu/VMID o lxc/VMID}"
    local object_type
    local vmid
    local status
    local attempt

    if [[ ! "${object_id}" =~ ^(qemu|lxc)/([0-9]+)$ ]]; then
        printf 'Object ID non valido: %s\n' "${object_id}" >&2
        return 40
    fi

    object_type="${BASH_REMATCH[1]}"
    vmid="${BASH_REMATCH[2]}"

    provider_start_status() {
        if [[ "${object_type}" == "qemu" ]]; then
            ssh \
                -i "${SANDRA_PVE_KEY}" \
                -o BatchMode=yes \
                -o PasswordAuthentication=no \
                -o KbdInteractiveAuthentication=no \
                -o IdentitiesOnly=yes \
                -o StrictHostKeyChecking=yes \
                -o ConnectTimeout=10 \
                "root@${SANDRA_PVE_HOST}" \
                "qm status ${vmid}"
        else
            ssh \
                -i "${SANDRA_PVE_KEY}" \
                -o BatchMode=yes \
                -o PasswordAuthentication=no \
                -o KbdInteractiveAuthentication=no \
                -o IdentitiesOnly=yes \
                -o StrictHostKeyChecking=yes \
                -o ConnectTimeout=10 \
                "root@${SANDRA_PVE_HOST}" \
                "pct status ${vmid}"
        fi
    }

    status="$(provider_start_status)"

    case "${status}" in
        "status: running")
            printf '%s\n' \
                "{\"schema\":\"sandra.proxmox.action.v1\",\"action\":\"start\",\"object_id\":\"${object_id}\",\"result\":\"ALREADY_RUNNING\",\"attempts\":0,\"status\":\"running\"}"
            return 0
            ;;
        "status: stopped")
            ;;
        *)
            printf 'Stato inatteso per %s: %s\n' \
                "${object_id}" "${status}" >&2
            return 41
            ;;
    esac

    for attempt in 1 2 3; do
        if [[ "${object_type}" == "qemu" ]]; then
            ssh \
                -i "${SANDRA_PVE_KEY}" \
                -o BatchMode=yes \
                -o PasswordAuthentication=no \
                -o KbdInteractiveAuthentication=no \
                -o IdentitiesOnly=yes \
                -o StrictHostKeyChecking=yes \
                -o ConnectTimeout=10 \
                "root@${SANDRA_PVE_HOST}" \
                "qm start ${vmid}"
        else
            ssh \
                -i "${SANDRA_PVE_KEY}" \
                -o BatchMode=yes \
                -o PasswordAuthentication=no \
                -o KbdInteractiveAuthentication=no \
                -o IdentitiesOnly=yes \
                -o StrictHostKeyChecking=yes \
                -o ConnectTimeout=10 \
                "root@${SANDRA_PVE_HOST}" \
                "pct start ${vmid}"
        fi

        sleep 5
        status="$(provider_start_status)"

        if [[ "${status}" == "status: running" ]]; then
            printf '%s\n' \
                "{\"schema\":\"sandra.proxmox.action.v1\",\"action\":\"start\",\"object_id\":\"${object_id}\",\"result\":\"STARTED\",\"attempts\":${attempt},\"status\":\"running\"}"
            return 0
        fi
    done

    printf '%s\n' \
        "{\"schema\":\"sandra.proxmox.action.v1\",\"action\":\"start\",\"object_id\":\"${object_id}\",\"result\":\"CRITICAL\",\"attempts\":3,\"status\":\"stopped\"}"

    return 50
}
