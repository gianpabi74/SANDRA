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
    python3 - \
        "${SANDRA_KNOWLEDGE_MANIFEST}" \
        "${SANDRA_KNOWLEDGE_ROOT}" <<'PY_MANIFEST'
import json
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])

try:
    manifest = json.loads(
        manifest_path.read_text(encoding="utf-8")
    )
except FileNotFoundError:
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_MISSING"
    )
except json.JSONDecodeError as exc:
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_JSON_INVALID:"
        f"{exc.lineno}:{exc.colno}"
    )

if not isinstance(manifest, dict):
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_TYPE_INVALID"
    )

required_fields = {
    "schema_version",
    "knowledge_root",
    "generated_index",
    "root_documents",
    "sections",
    "source_roots",
}

missing_fields = required_fields - set(manifest)

if missing_fields:
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_FIELDS_MISSING:"
        + ",".join(sorted(missing_fields))
    )

if manifest["schema_version"] != 2:
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_SCHEMA_INVALID"
    )

if pathlib.Path(
    manifest["knowledge_root"]
) != root:
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_ROOT_INVALID"
    )

if manifest["generated_index"] != "START-HERE.md":
    raise SystemExit(
        "KNOWLEDGE_MANIFEST_INDEX_INVALID"
    )


def require_nonempty_list(
    key: str,
) -> list:
    value = manifest.get(key)

    if not isinstance(value, list) or not value:
        raise SystemExit(
            f"KNOWLEDGE_MANIFEST_{key.upper()}_INVALID"
        )

    return value


def validate_records(
    values: list,
    category: str,
    string_fields: tuple[str, ...],
    require_order: bool,
) -> None:
    for index, record in enumerate(values):
        if not isinstance(record, dict):
            raise SystemExit(
                f"KNOWLEDGE_MANIFEST_{category}_"
                f"RECORD_INVALID:{index}"
            )

        for field in string_fields:
            value = record.get(field)

            if not isinstance(value, str) or not value:
                raise SystemExit(
                    f"KNOWLEDGE_MANIFEST_{category}_"
                    f"{field.upper()}_INVALID:{index}"
                )

        if require_order and not isinstance(
            record.get("order"),
            int,
        ):
            raise SystemExit(
                f"KNOWLEDGE_MANIFEST_{category}_"
                f"ORDER_INVALID:{index}"
            )


validate_records(
    require_nonempty_list("root_documents"),
    "ROOT_DOCUMENT",
    (
        "path",
        "title",
        "owner",
    ),
    True,
)

validate_records(
    require_nonempty_list("sections"),
    "SECTION",
    (
        "id",
        "title",
        "root",
        "owner",
    ),
    True,
)

validate_records(
    require_nonempty_list("source_roots"),
    "SOURCE_ROOT",
    (
        "id",
        "root",
        "owner",
    ),
    False,
)

print("KNOWLEDGE_MANIFEST=PASS")
PY_MANIFEST
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
