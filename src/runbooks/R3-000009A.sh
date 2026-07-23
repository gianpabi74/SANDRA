#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000009A-canonical-domain-migration.sh"

sandra_begin \
    "R3-000009A" \
    "Migrate certified domain to canonical Architecture GRANITA path"

for command_name in \
    python3 git install cp find diff sha256sum
do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
STATE="${ROOT}/STATE.json"

SOURCE_DOMAIN="${ROOT}/src/domain/governance"
SOURCE_TESTS="${ROOT}/src/domain/tests"

CANONICAL_DOMAIN="${ROOT}/src/sandra/domain/governance"
CANONICAL_TESTS="${ROOT}/tests/unit/domain"

EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"
FREEZE_CONTRACT="${ROOT}/docs/architecture/ARCHITECTURE-FREEZE-V1.json"
FREEZE_VALIDATOR="${ROOT}/src/knowledge/validate_architecture_freeze.py"

STAGING_ROOT="${SANDRA_RUN_DIR}/canonical-domain-staging"
STAGING_DOMAIN="${STAGING_ROOT}/governance"
STAGING_TESTS="${STAGING_ROOT}/tests"

BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"
JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${STATE}"
sandra_require_file "${SOURCE_DOMAIN}/__init__.py"
sandra_require_file "${SOURCE_DOMAIN}/errors.py"
sandra_require_file "${SOURCE_DOMAIN}/types.py"
sandra_require_file "${SOURCE_DOMAIN}/validation.py"
sandra_require_file "${SOURCE_DOMAIN}/cli.py"
sandra_require_file "${SOURCE_DOMAIN}/__main__.py"
sandra_require_file "${SOURCE_TESTS}/test_validation.py"
sandra_require_file "${EXAMPLE_ROOT}/managed-object.example.json"
sandra_require_file "${FREEZE_CONTRACT}"
sandra_require_file "${FREEZE_VALIDATOR}"

if [[ -e "${CANONICAL_DOMAIN}" ]]; then
    sandra_fail \
        "Canonical domain target already exists: ${CANONICAL_DOMAIN}"
fi

if [[ -e "${CANONICAL_TESTS}" ]]; then
    sandra_fail \
        "Canonical test target already exists: ${CANONICAL_TESTS}"
fi

install -d -m 0700 \
    "${BACKUP_ROOT}" \
    "${STAGING_ROOT}"

cp -a -- \
    "${STATE}" \
    "${BACKUP_ROOT}/STATE.json.before"

cp -a -- \
    "${SOURCE_DOMAIN}" \
    "${STAGING_DOMAIN}"

cp -a -- \
    "${SOURCE_TESTS}" \
    "${STAGING_TESTS}"

find "${STAGING_DOMAIN}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${STAGING_TESTS}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${STAGING_ROOT}" \
    -type f \
    -name '*.pyc' \
    -delete

python3 -m compileall \
    -q \
    "${STAGING_DOMAIN}" \
    "${STAGING_TESTS}"

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${STAGING_ROOT}" \
python3 -m unittest discover \
    -s "${STAGING_TESTS}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/staging-unit-tests.txt" \
    2>&1

mapfile -t EXAMPLE_FILES < <(
    find "${EXAMPLE_ROOT}" \
        -maxdepth 1 \
        -type f \
        -name '*.json' \
        -print \
        | sort
)

if [[ "${#EXAMPLE_FILES[@]}" -eq 0 ]]; then
    sandra_fail "No canonical example documents found"
fi

PYTHONPATH="${STAGING_ROOT}" \
python3 -m governance \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/staging-resource-validation.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/staging-resource-validation.json" \
    "${#EXAMPLE_FILES[@]}" <<'PYTHON'
import json
from pathlib import Path
import sys

result_path = Path(sys.argv[1])
expected_count = int(sys.argv[2])

results = json.loads(
    result_path.read_text(encoding="utf-8")
)

if len(results) != expected_count:
    raise SystemExit(
        f"VALIDATION_COUNT_MISMATCH:"
        f"{len(results)}:{expected_count}"
    )

failed = [
    result
    for result in results
    if result.get("status") != "PASS"
]

if failed:
    raise SystemExit(
        "RESOURCE_VALIDATION_FAILED:"
        + json.dumps(
            failed,
            ensure_ascii=False,
            sort_keys=True,
        )
    )

print("STAGING_RESOURCE_VALIDATION=PASS")
PYTHON

find "${STAGING_DOMAIN}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${STAGING_TESTS}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${STAGING_ROOT}" \
    -type f \
    -name '*.pyc' \
    -delete

diff -ruN \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    "${SOURCE_DOMAIN}" \
    "${STAGING_DOMAIN}" \
    > "${SANDRA_EVIDENCE_DIR}/domain-source-diff.txt" \
    || sandra_fail "Staged domain differs from certified source"

diff -ruN \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    "${SOURCE_TESTS}" \
    "${STAGING_TESTS}" \
    > "${SANDRA_EVIDENCE_DIR}/domain-test-diff.txt" \
    || sandra_fail "Staged tests differ from certified source"

install -d -m 0755 \
    "$(dirname "${CANONICAL_DOMAIN}")" \
    "$(dirname "${CANONICAL_TESTS}")" \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

cp -a -- \
    "${STAGING_DOMAIN}" \
    "${CANONICAL_DOMAIN}"

cp -a -- \
    "${STAGING_TESTS}" \
    "${CANONICAL_TESTS}"

cat > "${ROOT}/src/sandra/domain/README.md" <<'EOF'
# Domain

Canonical SANDRA domain governed by Architecture GRANITA Freeze V1.

This layer contains technology-independent:

- resource types;
- evidence types;
- policy and capability concepts;
- validation rules;
- domain errors and invariants.

This layer must not depend on adapters, controllers, products, credentials,
Habitat configuration or infrastructure APIs.
EOF

cat > "${ROOT}/tests/unit/domain/README.md" <<'EOF'
# Domain unit tests

Canonical unit tests for the SANDRA domain.

External canonical examples are supplied explicitly through:

    SANDRA_TEST_EXAMPLE_ROOT

Tests must not infer repository paths from their own filesystem position.
EOF

find "${CANONICAL_DOMAIN}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${CANONICAL_TESTS}" \
    -type d \
    -name '__pycache__' \
    -prune \
    -exec rm -rf -- {} +

find "${CANONICAL_DOMAIN}" "${CANONICAL_TESTS}" \
    -type f \
    -name '*.pyc' \
    -delete

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${ROOT}/src/sandra/domain" \
python3 -m unittest discover \
    -s "${CANONICAL_TESTS}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/canonical-unit-tests.txt" \
    2>&1

PYTHONPATH="${ROOT}/src/sandra/domain" \
python3 -m governance \
    "${EXAMPLE_FILES[@]}" \
    > "${SANDRA_EVIDENCE_DIR}/canonical-resource-validation.json"

python3 - \
    "${SANDRA_EVIDENCE_DIR}/canonical-resource-validation.json" \
    "${#EXAMPLE_FILES[@]}" <<'PYTHON'
import json
from pathlib import Path
import sys

result_path = Path(sys.argv[1])
expected_count = int(sys.argv[2])

results = json.loads(
    result_path.read_text(encoding="utf-8")
)

if len(results) != expected_count:
    raise SystemExit(
        f"CANONICAL_VALIDATION_COUNT_MISMATCH:"
        f"{len(results)}:{expected_count}"
    )

failed = [
    result
    for result in results
    if result.get("status") != "PASS"
]

if failed:
    raise SystemExit(
        "CANONICAL_RESOURCE_VALIDATION_FAILED:"
        + json.dumps(
            failed,
            ensure_ascii=False,
            sort_keys=True,
        )
    )

print("CANONICAL_RESOURCE_VALIDATION=PASS")
PYTHON

python3 \
    "${FREEZE_VALIDATOR}" \
    "${FREEZE_CONTRACT}" \
    "${ROOT}" \
    > "${SANDRA_EVIDENCE_DIR}/architecture-freeze-validation.txt"

grep -q \
    '^ARCHITECTURE_GRANITA_FREEZE=PASS$' \
    "${SANDRA_EVIDENCE_DIR}/architecture-freeze-validation.txt"

python3 - \
    "${SOURCE_DOMAIN}" \
    "${CANONICAL_DOMAIN}" \
    "${SOURCE_TESTS}" \
    "${CANONICAL_TESTS}" \
    "${SANDRA_EVIDENCE_DIR}/migration-manifest.tsv" <<'PYTHON'
import hashlib
from pathlib import Path
import sys

source_domain = Path(sys.argv[1])
canonical_domain = Path(sys.argv[2])
source_tests = Path(sys.argv[3])
canonical_tests = Path(sys.argv[4])
output_path = Path(sys.argv[5])


def digest(path: Path) -> str:
    hasher = hashlib.sha256()

    with path.open("rb") as stream:
        for chunk in iter(
            lambda: stream.read(1024 * 1024),
            b"",
        ):
            hasher.update(chunk)

    return hasher.hexdigest()


def files(root: Path) -> dict[str, Path]:
    return {
        path.relative_to(root).as_posix(): path
        for path in root.rglob("*")
        if (
            path.is_file()
            and "__pycache__" not in path.parts
            and path.suffix != ".pyc"
            and path.name != "README.md"
        )
    }


rows = [
    (
        "domain",
        source_domain,
        canonical_domain,
    ),
    (
        "tests",
        source_tests,
        canonical_tests,
    ),
]

lines = [
    "AREA\tRELATIVE_PATH\tSOURCE_SHA256\tCANONICAL_SHA256\tSTATUS"
]

for area, source_root, canonical_root in rows:
    source_files = files(source_root)
    canonical_files = files(canonical_root)

    all_paths = sorted(
        set(source_files) | set(canonical_files)
    )

    for relative in all_paths:
        source = source_files.get(relative)
        canonical = canonical_files.get(relative)

        if source is None:
            lines.append(
                f"{area}\t{relative}\t\t"
                f"{digest(canonical)}\tCANONICAL_ONLY"
            )
            continue

        if canonical is None:
            lines.append(
                f"{area}\t{relative}\t"
                f"{digest(source)}\t\tSOURCE_ONLY"
            )
            continue

        source_digest = digest(source)
        canonical_digest = digest(canonical)

        status = (
            "BYTE_IDENTICAL"
            if source_digest == canonical_digest
            else "DIFFERENT"
        )

        lines.append(
            f"{area}\t{relative}\t"
            f"{source_digest}\t"
            f"{canonical_digest}\t"
            f"{status}"
        )

output_path.write_text(
    "\n".join(lines) + "\n",
    encoding="utf-8",
)

invalid = [
    line
    for line in lines[1:]
    if not line.endswith("\tBYTE_IDENTICAL")
]

if invalid:
    raise SystemExit(
        "MIGRATION_MANIFEST_INVALID:\n"
        + "\n".join(invalid)
    )

print("MIGRATION_MANIFEST=PASS")
PYTHON

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

architecture = state["spec"]["architecture"]
freeze = architecture["freeze"]

if freeze.get("id") != "architecture-granita-v1":
    raise SystemExit(
        "ARCHITECTURE_FREEZE_ID_INVALID"
    )

if freeze.get("status") != "immutable":
    raise SystemExit(
        "ARCHITECTURE_FREEZE_NOT_IMMUTABLE"
    )

state["metadata"]["state_version"] = "4.1.0"
state["metadata"]["updated_utc"] = (
    datetime.datetime.now(
        datetime.timezone.utc
    )
    .replace(microsecond=0)
    .isoformat()
    .replace("+00:00", "Z")
)

state["spec"]["roadmap"]["current_gate"] = {
    "runbook": "R3-000009",
    "title": "Canonical Domain Migration",
    "type": "canonical_source_migration",
    "targets": [
        "src/sandra/domain/governance",
        "tests/unit/domain",
        "Knowledge canonica"
    ],
    "excluded_targets": [
        "sistemi remoti dell'Habitat",
        "src/domain removal",
        "src/runtime removal",
        "software installation"
    ],
    "objectives": [
        "publish certified domain under canonical source root",
        "publish portable domain unit tests",
        "prove byte identity with certified source",
        "preserve historical migration sources",
        "preserve Architecture GRANITA Freeze"
    ],
    "prohibitions": [
        "no source deletion",
        "no behavior modification",
        "no dependency addition",
        "no Habitat modification",
        "no architecture change",
        "no intuitive correction"
    ]
}

state["spec"]["roadmap"]["next_gate"] = {
    "runbook": "R3-000010",
    "title": "Application Ports Foundation",
    "status": "blocked"
}

state["status"]["current_certification"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "journal": journal
}

state["status"]["roadmap"] = {
    "phase": "Canonical Domain Migration",
    "current_gate": "R3-000009",
    "current_gate_status": "complete",
    "next_gate": "R3-000010"
}

state["status"]["canonical_domain_migration_v1"] = {
    "runbook": runbook_id,
    "run_id": run_id,
    "status": "certified",
    "source": "src/domain/governance",
    "canonical": "src/sandra/domain/governance",
    "source_tests": "src/domain/tests",
    "canonical_tests": "tests/unit/domain",
    "migration_method": "verified_copy",
    "byte_identity": "pass",
    "unit_tests": "pass",
    "resource_validation": "pass",
    "architecture_freeze_validation": "pass",
    "legacy_sources_preserved": True,
    "software_installed": "none",
    "remote_habitat_modifications": "none"
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

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Canonical Domain Migration

- Run ID: \`${SANDRA_RUN_ID}\`
- Architecture Freeze: \`architecture-granita-v1\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- copied the certified governance domain to
  \`src/sandra/domain/governance\`;
- copied portable unit tests to \`tests/unit/domain\`;
- proved byte identity against the certified source;
- passed unit tests and canonical resource validation;
- passed Architecture GRANITA validation;
- preserved \`src/domain\` and \`src/runtime\`;
- made no behavioral change.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: migrate domain to canonical GRANITA path"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

sandra_assert test -d "${SOURCE_DOMAIN}"
sandra_assert test -d "${CANONICAL_DOMAIN}"
sandra_assert test -d "${SOURCE_TESTS}"
sandra_assert test -d "${CANONICAL_TESTS}"

{
    printf 'CANONICAL_DOMAIN_MIGRATION=PASS\n'
    printf 'CANONICAL_DOMAIN=src/sandra/domain/governance\n'
    printf 'CANONICAL_TESTS=tests/unit/domain\n'
    printf 'BYTE_IDENTITY=PASS\n'
    printf 'UNIT_TESTS=PASS\n'
    printf 'RESOURCE_VALIDATION=PASS\n'
    printf 'ARCHITECTURE_FREEZE=PASS\n'
    printf 'LEGACY_SOURCE_DOMAIN_PRESERVED=YES\n'
    printf 'LEGACY_RUNTIME_PRESERVED=YES\n'
    printf 'STATE_SHA256=%s\n' \
        "$(sha256sum "${STATE}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
