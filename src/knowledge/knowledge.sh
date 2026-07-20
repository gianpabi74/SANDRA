#!/usr/bin/env bash

readonly SANDRA_KNOWLEDGE_VERSION="1.0.0"
readonly SANDRA_KNOWLEDGE_ROOT="/opt/sandra/knowledge"
readonly SANDRA_KNOWLEDGE_MANIFEST="${SANDRA_KNOWLEDGE_ROOT}/manifest/KNOWLEDGE_MANIFEST.json"

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

assert manifest["schema_version"] == 1
assert pathlib.Path(manifest["knowledge_root"]) == root
assert manifest["generated_index"] == "START_HERE.md"

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
    knowledge_validate_manifest

    python3 - "${SANDRA_KNOWLEDGE_MANIFEST}" "${SANDRA_KNOWLEDGE_ROOT}" <<'PYTHON'
import json
import pathlib
import sys
from datetime import datetime, timezone

manifest_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

def document_title(path):
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
    except OSError:
        pass
    return path.stem.replace("_", " ").replace("-", " ").title()

lines = [
    "# Start Here",
    "",
    "Indice generato automaticamente dal modulo Knowledge.",
    "",
    f"Generato UTC: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
    "",
    "## Ordine di lettura",
    "",
]

for item in sorted(manifest["root_documents"], key=lambda x: x["order"]):
    path = root / item["path"]
    if path.is_file():
        lines.append(f"{item['order']}. [{item['title']}]({item['path']})")

lines.extend(["", "## Documentazione canonica", ""])

for section in sorted(manifest["sections"], key=lambda x: x["order"]):
    section_root = root / section["root"]
    lines.extend([
        f"### {section['title']}",
        "",
        f"Owner: `{section['owner']}`  ",
        f"Path: `{section['root']}`",
        "",
    ])

    documents = sorted(section_root.rglob("*.md"))

    if not documents:
        lines.append("_Nessun documento pubblicato._")
    else:
        for document in documents:
            relative = document.relative_to(root).as_posix()
            lines.append(f"- [{document_title(document)}]({relative})")

    lines.append("")

lines.extend([
    "## Regola di pubblicazione",
    "",
    "1. Inserire il documento nella directory canonica.",
    "2. Eseguire `knowledge_generate_index`.",
    "3. Eseguire `knowledge_validate`.",
    "4. Eseguire `knowledge_sync \"messaggio commit\"`.",
    "",
    "Non modificare manualmente questo indice.",
    "",
])

target = root / manifest["generated_index"]
temporary = target.with_suffix(".tmp")
temporary.write_text("\n".join(lines), encoding="utf-8")
temporary.replace(target)

print(f"KNOWLEDGE_INDEX={target}")
PYTHON
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

knowledge_sync() {
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
