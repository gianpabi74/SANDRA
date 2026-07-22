#!/usr/bin/env bash

knowledge_generate_views() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"

    python3 \
        "${root}/generate_views.py"
}

knowledge_generated_views_check() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"

    python3 \
        "${root}/generate_views.py" \
        --check
}

knowledge_continuity_validate() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"
    local state="${root}/STATE.json"
    local constitution="${root}/docs/constitution/KNOWLEDGE-CONTINUITY.md"
    local windows_version_file="${root}/src/providers/windows/VERSION"
    local linux_version_file="${root}/src/providers/linux/VERSION"

    for file in \
        "$state" \
        "$constitution" \
        "$windows_version_file" \
        "$linux_version_file" \
        "${root}/generate_views.py"; do

        test -s "$file" || {
            printf 'CONTINUITY_FILE_INVALID=%s\n' \
                "$file" >&2
            return 1
        }
    done

    python3 - \
        "$state" \
        "$root" \
        "$windows_version_file" \
        "$linux_version_file" <<'PY'
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
windows_version_path = pathlib.Path(sys.argv[3])
linux_version_path = pathlib.Path(sys.argv[4])

state = json.loads(
    state_path.read_text(encoding="utf-8")
)

if state.get("schema_version") != 2:
    raise SystemExit(
        "CONTINUITY_SCHEMA_VERSION_INVALID"
    )

project = state.get("project", {})

if project.get("repository") != (
    "https://github.com/gianpabi74/SANDRA"
):
    raise SystemExit(
        "CONTINUITY_REPOSITORY_INVALID"
    )

if project.get("branch") != "main":
    raise SystemExit(
        "CONTINUITY_BRANCH_INVALID"
    )

windows_version = windows_version_path.read_text(
    encoding="utf-8"
).strip()

linux_version = linux_version_path.read_text(
    encoding="utf-8"
).strip()

providers = state.get("providers", {})

if (
    providers.get("windows", {}).get("version")
    != windows_version
):
    raise SystemExit(
        "CONTINUITY_WINDOWS_VERSION_MISMATCH"
    )

if (
    providers.get("linux", {}).get("version")
    != linux_version
):
    raise SystemExit(
        "CONTINUITY_LINUX_VERSION_MISMATCH"
    )

certification = project.get(
    "current_certification",
    {},
)

journal = certification.get("journal")
runbook = certification.get("runbook")

if not journal or not runbook:
    raise SystemExit(
        "CONTINUITY_CERTIFICATION_INVALID"
    )

journal_path = root / journal

if (
    not journal_path.is_file()
    or journal_path.stat().st_size == 0
):
    raise SystemExit(
        "CONTINUITY_JOURNAL_INVALID:"
        + str(journal)
    )

next_task = state.get("next_task", {})

if next_task.get("runbook") != "RB-000062":
    raise SystemExit(
        "CONTINUITY_NEXT_RUNBOOK_INVALID"
    )

if (
    state.get("roadmap", {})
    .get("gates", [{}])[0]
    .get("runbook")
    != next_task.get("runbook")
):
    raise SystemExit(
        "CONTINUITY_ROADMAP_NEXT_MISMATCH"
    )

generated = (
    state.get("knowledge", {})
    .get("generated_views", [])
)

required_views = {
    "START-HERE.md",
    "BASELINE.md",
    "CURRENT_STATE.md",
    "NEXT_TASK.md",
    "docs/roadmap/ROADMAP.md",
    "CHAT-HANDOFF.md",
}

if set(generated) != required_views:
    raise SystemExit(
        "CONTINUITY_GENERATED_VIEWS_INVALID"
    )

print("KNOWLEDGE_STATE_VALIDATION=PASS")
PY

    knowledge_generated_views_check
}

knowledge_sync() {
    knowledge_generate_views
    knowledge_continuity_validate
    _knowledge_sync_impl "$@"
}
