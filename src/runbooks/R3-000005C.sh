#!/usr/bin/env bash

source /opt/sandra/core/core.sh
source /opt/sandra/knowledge/knowledge.sh

set -Eeuo pipefail
umask 077

export SANDRA_RUNBOOK_SOURCE="/root/R3-000005C-portable-test-fixtures.sh"

sandra_begin \
    "R3-000005C" \
    "Make governance tests independent from package location"

for command_name in python3 git install cp grep sha256sum; do
    sandra_require_command "${command_name}"
done

ROOT="${SANDRA_KNOWLEDGE_ROOT}"
SOURCE_ROOT="${ROOT}/src/runtime"
SOURCE_TEST="${SOURCE_ROOT}/tests/test_validation.py"
EXAMPLE_ROOT="${ROOT}/docs/specs/governance-model/examples"

WORK_ROOT="${SANDRA_RUN_DIR}/portable-test-fixtures"
TEMP_TEST_ROOT="${WORK_ROOT}/tests"
PATCHED_TEST="${TEMP_TEST_ROOT}/test_validation.py"
BACKUP_ROOT="${SANDRA_RUN_DIR}/backups"

JOURNAL="$(knowledge_journal_path)"
RUNBOOK_DEST="${ROOT}/src/runbooks/${SANDRA_RUNBOOK_ID}.sh"

sandra_require_file "${SOURCE_TEST}"
sandra_require_file \
    "${EXAMPLE_ROOT}/managed-object.example.json"

install -d -m 0700 \
    "${TEMP_TEST_ROOT}" \
    "${BACKUP_ROOT}"

cp -a -- \
    "${SOURCE_TEST}" \
    "${BACKUP_ROOT}/test_validation.py.before"

cp -a -- \
    "${SOURCE_TEST}" \
    "${PATCHED_TEST}"

python3 - "${PATCHED_TEST}" <<'PYTHON'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_imports = '''import copy
import json
import unittest
from pathlib import Path
'''

new_imports = '''import copy
import json
import os
import unittest
from pathlib import Path
'''

old_setup = '''    @classmethod
    def setUpClass(cls) -> None:
        knowledge_root = (
            Path(__file__).resolve().parents[3]
        )
        cls.example_root = (
            knowledge_root
            / "docs"
            / "specs"
            / "governance-model"
            / "examples"
        )
'''

new_setup = '''    @classmethod
    def setUpClass(cls) -> None:
        configured_root = os.environ.get(
            "SANDRA_TEST_EXAMPLE_ROOT"
        )

        if not configured_root:
            raise RuntimeError(
                "SANDRA_TEST_EXAMPLE_ROOT is required"
            )

        cls.example_root = Path(
            configured_root
        ).resolve()

        if not cls.example_root.is_dir():
            raise RuntimeError(
                "SANDRA_TEST_EXAMPLE_ROOT is not a directory: "
                f"{cls.example_root}"
            )
'''

replacements = (
    (old_imports, new_imports, "imports"),
    (old_setup, new_setup, "setUpClass"),
)

for old, new, label in replacements:
    count = text.count(old)

    if count != 1:
        raise SystemExit(
            f"PATCH_TARGET_INVALID:{label}:{count}"
        )

    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
PYTHON

python3 -m py_compile "${PATCHED_TEST}"

if grep -nE \
    'Path\(__file__\).*parents|parents\[[0-9]+\]' \
    "${PATCHED_TEST}" \
    > "${SANDRA_EVIDENCE_DIR}/forbidden-path-inference.txt"
then
    cat "${SANDRA_EVIDENCE_DIR}/forbidden-path-inference.txt"
    sandra_fail "Path inference remains in patched tests"
fi

grep -n \
    'SANDRA_TEST_EXAMPLE_ROOT' \
    "${PATCHED_TEST}" \
    > "${SANDRA_EVIDENCE_DIR}/fixture-contract.txt"

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${SOURCE_ROOT}" \
python3 -m unittest discover \
    -s "${TEMP_TEST_ROOT}" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/unit-tests.txt" \
    2>&1

# Verifica anche il comportamento obbligatorio in assenza della fixture.
set +e
PYTHONPATH="${SOURCE_ROOT}" \
python3 -m unittest discover \
    -s "${TEMP_TEST_ROOT}" \
    -p 'test_*.py' \
    > "${SANDRA_EVIDENCE_DIR}/missing-fixture-test.txt" \
    2>&1
missing_fixture_rc=$?
set -e

if [[ "${missing_fixture_rc}" -eq 0 ]]; then
    sandra_fail \
        "Tests unexpectedly passed without SANDRA_TEST_EXAMPLE_ROOT"
fi

grep -q \
    'SANDRA_TEST_EXAMPLE_ROOT is required' \
    "${SANDRA_EVIDENCE_DIR}/missing-fixture-test.txt" \
    || sandra_fail \
        "Missing fixture failure was not explicit"

# Solo dopo aver superato tutti i test viene pubblicato il file.
install -m 0644 \
    "${PATCHED_TEST}" \
    "${SOURCE_TEST}"

python3 -m py_compile "${SOURCE_TEST}"

SANDRA_TEST_EXAMPLE_ROOT="${EXAMPLE_ROOT}" \
PYTHONPATH="${SOURCE_ROOT}" \
python3 -m unittest discover \
    -s "${SOURCE_ROOT}/tests" \
    -p 'test_*.py' \
    -v \
    > "${SANDRA_EVIDENCE_DIR}/unit-tests-published.txt" \
    2>&1

install -d -m 0755 \
    "$(dirname "${JOURNAL}")" \
    "$(dirname "${RUNBOOK_DEST}")"

install -m 0600 \
    "${SANDRA_RUNBOOK_SOURCE}" \
    "${RUNBOOK_DEST}"

cat > "${JOURNAL}" <<EOF
# ${SANDRA_RUNBOOK_ID} — Portable test fixtures

- Run ID: \`${SANDRA_RUN_ID}\`
- Remote Habitat modifications: \`NONE\`
- Software installed: \`NONE\`

## Result

- removed filesystem-position inference from governance tests;
- introduced explicit \`SANDRA_TEST_EXAMPLE_ROOT\` fixture contract;
- verified tests from an independent staging directory;
- verified explicit failure when the fixture is absent;
- verified the published canonical test suite.
EOF

knowledge_validate
knowledge_generate_views
knowledge_continuity_validate

knowledge_sync \
    "${SANDRA_RUNBOOK_ID}: make governance tests portable"

sandra_assert knowledge_verify_remote
sandra_assert knowledge_validate
sandra_assert knowledge_continuity_validate

{
    printf 'PORTABLE_TEST_FIXTURES=PASS\n'
    printf 'UNIT_TESTS_STAGING=PASS\n'
    printf 'UNIT_TESTS_PUBLISHED=PASS\n'
    printf 'PATH_INFERENCE_REMOVED=YES\n'
    printf 'FIXTURE_VARIABLE=SANDRA_TEST_EXAMPLE_ROOT\n'
    printf 'SOURCE_TEST_SHA256=%s\n' \
        "$(sha256sum "${SOURCE_TEST}" | awk '{print $1}')"
    printf 'GIT_HEAD=%s\n' \
        "$(git -C "${ROOT}" rev-parse HEAD)"
    printf 'GIT_ORIGIN_MAIN=%s\n' \
        "$(git -C "${ROOT}" rev-parse origin/main)"
    printf 'REMOTE_HABITAT_MODIFICATIONS=NONE\n'
    printf 'SOFTWARE_INSTALLED=NONE\n'
} > "${SANDRA_EVIDENCE_DIR}/result.env"

sandra_end PASS
