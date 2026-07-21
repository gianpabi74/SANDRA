#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

SANDRA_PBS_PROVIDER_VERSION="1.0.0"
SANDRA_PBS_HOST="${SANDRA_PBS_HOST:-192.168.1.194}"
SANDRA_PBS_KEY="${SANDRA_PBS_KEY:-/root/.ssh/sandra_pbs_ed25519}"

provider_connect() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" '
            set -eu
            test "$(id -un)" = root
            test "$(hostname)" = pbs
            command -v proxmox-backup-manager >/dev/null
            printf "PBS_CONNECTION=PASS\n"
            printf "PBS_HOST=%s\n" "$(hostname)"
        '
}

provider_version() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager version'
}

provider_datastores() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager datastore list --output-format json-pretty'
}

provider_garbage_collections() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager garbage-collection list --output-format json-pretty'
}

provider_verify_jobs() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager verify-job list --output-format json-pretty'
}

provider_prune_jobs() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager prune-job list --output-format json-pretty'
}

provider_sync_jobs() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager sync-job list --output-format json-pretty'
}

provider_remotes() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager remote list --output-format json-pretty'
}

provider_acls() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager acl list --output-format json-pretty'
}

provider_users() {
    ssh \
        -i "${SANDRA_PBS_KEY}" \
        -o BatchMode=yes \
        -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no \
        -o IdentitiesOnly=yes \
        -o StrictHostKeyChecking=yes \
        -o ConnectTimeout=10 \
        "root@${SANDRA_PBS_HOST}" \
        'proxmox-backup-manager user list --output-format json-pretty'
}
