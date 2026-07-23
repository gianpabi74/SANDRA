#!/usr/bin/env bash

SANDRA_KNOWLEDGE_VERSION="2.0.0"
SANDRA_KNOWLEDGE_ROOT="/opt/sandra/knowledge"
SANDRA_KNOWLEDGE_MANIFEST="${SANDRA_KNOWLEDGE_ROOT}/manifest/KNOWLEDGE_MANIFEST.json"

knowledge_log() {
    local level="$1"
    shift
    printf '%s [KNOWLEDGE:%s] %s\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "${level}" "$*"
}

knowledge_validate_manifest() {
    python3 - "${SANDRA_KNOWLEDGE_MANIFEST}" "${SANDRA_KNOWLEDGE_ROOT}" <<'PYTHON'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

assert manifest["schema_version"] == 2
assert pathlib.Path(manifest["knowledge_root"]) == root
assert manifest["generated_index"] == "START-HERE.md"

for key in ("root_documents", "sections", "source_roots"):
    assert isinstance(manifest[key], list) and manifest[key]

for document in manifest["root_documents"]:
    assert document["path"]
    assert document["title"]
    assert document["owner"]
    assert isinstance(document["order"], int)

for section in manifest["sections"]:
    assert section["id"]
    assert section["root"]
    assert section["owner"]
    assert isinstance(section["order"], int)

print("KNOWLEDGE_MANIFEST=PASS")
PYTHON
}

knowledge_validate() {
    knowledge_validate_manifest

    python3 - "${SANDRA_KNOWLEDGE_MANIFEST}" "${SANDRA_KNOWLEDGE_ROOT}" <<'PYTHON'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

errors = []

for document in manifest["root_documents"]:
    path = root / document["path"]
    if not path.is_file() or path.stat().st_size == 0:
        errors.append(f"Documento root assente o vuoto: {document['path']}")

for section in manifest["sections"]:
    path = root / section["root"]
    if not path.is_dir():
        errors.append(f"Sezione assente: {section['root']}")

for source in manifest["source_roots"]:
    path = root / source["root"]
    if not path.is_dir():
        errors.append(f"Source root assente: {source['root']}")

forbidden_names = set(manifest.get("forbidden_names", []))
forbidden_suffixes = tuple(manifest.get("forbidden_suffixes", []))
private_markers = (
    "-----BEGIN OPENSSH PRIVATE KEY-----",
    "-----BEGIN RSA PRIVATE KEY-----",
    "-----BEGIN PRIVATE KEY-----",
)

for path in root.rglob("*"):
    if ".git" in path.parts or path.is_symlink() or not path.is_file():
        continue

    relative = path.relative_to(root).as_posix()

    if path.name in forbidden_names:
        errors.append(f"Nome vietato: {relative}")

    if forbidden_suffixes and relative.endswith(forbidden_suffixes):
        errors.append(f"Suffisso vietato: {relative}")

    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue

    if text.lstrip().startswith(private_markers):
        errors.append(f"Chiave privata rilevata: {relative}")

if errors:
    print("\n".join(errors))
    raise SystemExit(20)

print("KNOWLEDGE_STRUCTURE=PASS")
PYTHON
}

knowledge_generate_index() {
    knowledge_generate_views
}

knowledge_assert_clean() {
    local status
    status="$(git -C "${SANDRA_KNOWLEDGE_ROOT}" status --porcelain)"

    if [[ -n "${status}" ]]; then
        knowledge_log ERROR "Working tree non pulita"
        printf '%s\n' "${status}" >&2
        return 30
    fi
}

knowledge_commit() {
    local message="$1"

    [[ -n "${message}" ]] || {
        knowledge_log ERROR "Messaggio commit obbligatorio"
        return 40
    }

    git -C "${SANDRA_KNOWLEDGE_ROOT}" add --all

    if git -C "${SANDRA_KNOWLEDGE_ROOT}" diff --cached --quiet; then
        knowledge_log INFO "Nessuna modifica da committare"
        return 0
    fi

    git -C "${SANDRA_KNOWLEDGE_ROOT}" commit -m "${message}"
}

knowledge_push() {
    git -C "${SANDRA_KNOWLEDGE_ROOT}" push origin main
}

knowledge_verify_remote() {
    git -C "${SANDRA_KNOWLEDGE_ROOT}" fetch --quiet origin main

    local local_head
    local remote_head

    local_head="$(git -C "${SANDRA_KNOWLEDGE_ROOT}" rev-parse HEAD)"
    remote_head="$(git -C "${SANDRA_KNOWLEDGE_ROOT}" rev-parse origin/main)"

    [[ "${local_head}" == "${remote_head}" ]] || {
        knowledge_log ERROR "HEAD locale diverso da origin/main"
        return 50
    }

    knowledge_assert_clean
    knowledge_log INFO "Remote verificato: ${local_head}"
}

_knowledge_sync_impl() {
    local message="$1"

    knowledge_validate
    knowledge_generate_index
    knowledge_validate
    knowledge_commit "${message}"
    knowledge_push
    knowledge_verify_remote
}

knowledge_journal_path() {
    printf '%s/journal/%s/%s/%s.md\n' \
        "${SANDRA_KNOWLEDGE_ROOT}" \
        "$(date -u +%Y)" \
        "$(date -u +%m)" \
        "${SANDRA_RUN_ID}"
}

source "${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}/continuity.sh"
