#!/usr/bin/env bash

knowledge_generate_views() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"
    python3 "${root}/generate_views.py"
}

knowledge_generated_views_check() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"
    python3 "${root}/generate_views.py" --check
}

knowledge_continuity_validate() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"
    local state="${root}/STATE.json"
    local windows_version="${root}/src/providers/windows/VERSION"
    local linux_version="${root}/src/providers/linux/VERSION"

    for file in \
        "${state}" \
        "${root}/PROJECT_CHARTER.md" \
        "${root}/ARCHITECTURE.md" \
        "${root}/generate_views.py" \
        "${windows_version}" \
        "${linux_version}"; do
        test -s "${file}" || {
            printf 'CONTINUITY_FILE_INVALID=%s\n' "${file}" >&2
            return 1
        }
    done

    python3 - \
        "${state}" \
        "${root}" \
        "${windows_version}" \
        "${linux_version}" <<'PYTHON'
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
root = pathlib.Path(sys.argv[2])
windows_version = pathlib.Path(sys.argv[3]).read_text(
    encoding="utf-8"
).strip()
linux_version = pathlib.Path(sys.argv[4]).read_text(
    encoding="utf-8"
).strip()

state = json.loads(state_path.read_text(encoding="utf-8"))

if set(state) != {"metadata", "spec", "status"}:
    raise SystemExit("CONTINUITY_TOP_LEVEL_MODEL_INVALID")

metadata = state["metadata"]
spec = state["spec"]
status = state["status"]

if metadata.get("api_version") != "sandra.io/v2":
    raise SystemExit("CONTINUITY_API_VERSION_INVALID")

if metadata.get("repository") != (
    "https://github.com/gianpabi74/SANDRA"
):
    raise SystemExit("CONTINUITY_REPOSITORY_INVALID")

if metadata.get("branch") != "main":
    raise SystemExit("CONTINUITY_BRANCH_INVALID")

providers = status.get("providers", {})

if providers.get("windows", {}).get("version") != windows_version:
    raise SystemExit("CONTINUITY_WINDOWS_VERSION_MISMATCH")

if providers.get("linux", {}).get("version") != linux_version:
    raise SystemExit("CONTINUITY_LINUX_VERSION_MISMATCH")

certification = status.get("current_certification", {})
journal = certification.get("journal")
runbook = certification.get("runbook")

if not journal or not runbook:
    raise SystemExit("CONTINUITY_CERTIFICATION_INVALID")

if not (root / journal).is_file():
    raise SystemExit("CONTINUITY_JOURNAL_INVALID")

knowledge = spec.get("knowledge", {})
required_views = {
    "START-HERE.md",
    "BASELINE.md",
    "CURRENT_STATE.md",
    "NEXT_TASK.md",
    "docs/roadmap/ROADMAP.md",
    "CHAT-HANDOFF.md",
}

declared_views = {
    knowledge["entrypoint"],
    "BASELINE.md",
    knowledge["current_state_view"],
    knowledge["next_task_view"],
    knowledge["roadmap_view"],
    knowledge["handoff"],
}

if declared_views != required_views:
    raise SystemExit("CONTINUITY_GENERATED_VIEWS_INVALID")

if spec["roadmap"]["current_gate"]["runbook"] != (
    status["roadmap"]["current_gate"]
):
    raise SystemExit("CONTINUITY_CURRENT_GATE_MISMATCH")

print("KNOWLEDGE_STATE_VALIDATION=PASS")
PYTHON

    knowledge_generated_views_check
}

knowledge_sync() {
    knowledge_generate_views
    knowledge_continuity_validate
    _knowledge_sync_impl "$@"
}
