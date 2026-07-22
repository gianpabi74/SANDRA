#!/usr/bin/env bash

knowledge_continuity_validate() {
    local root="${SANDRA_KNOWLEDGE_ROOT:-/opt/sandra/knowledge}"
    local state="${root}/STATE.json"
    local start="${root}/START-HERE.md"
    local baseline="${root}/BASELINE.md"
    local current="${root}/CURRENT_STATE.md"
    local next="${root}/NEXT_TASK.md"
    local roadmap="${root}/docs/roadmap/ROADMAP.md"
    local handoff="${root}/CHAT-HANDOFF.md"
    local constitution="${root}/docs/constitution/KNOWLEDGE-CONTINUITY.md"
    local windows_version_file="${root}/src/providers/windows/VERSION"
    local linux_version_file="${root}/src/providers/linux/VERSION"

    python3 - \
        "$state" \
        "$start" \
        "$baseline" \
        "$current" \
        "$next" \
        "$roadmap" \
        "$handoff" \
        "$constitution" \
        "$windows_version_file" \
        "$linux_version_file" <<'PY'
import json
import pathlib
import sys

(
    state_path,
    start_path,
    baseline_path,
    current_path,
    next_path,
    roadmap_path,
    handoff_path,
    constitution_path,
    windows_version_path,
    linux_version_path,
) = [pathlib.Path(value) for value in sys.argv[1:11]]

required = (
    state_path,
    start_path,
    baseline_path,
    current_path,
    next_path,
    roadmap_path,
    handoff_path,
    constitution_path,
    windows_version_path,
    linux_version_path,
)

for path in required:
    if not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(
            f"CONTINUITY_FILE_INVALID:{path}"
        )

state = json.loads(
    state_path.read_text(encoding="utf-8")
)

windows_version = windows_version_path.read_text(
    encoding="utf-8"
).strip()

linux_version = linux_version_path.read_text(
    encoding="utf-8"
).strip()

if state.get("repository") != (
    "https://github.com/gianpabi74/SANDRA"
):
    raise SystemExit("CONTINUITY_REPOSITORY_INVALID")

if state.get("branch") != "main":
    raise SystemExit("CONTINUITY_BRANCH_INVALID")

if (
    state.get("providers", {})
    .get("windows", {})
    .get("version")
    != windows_version
):
    raise SystemExit(
        "CONTINUITY_WINDOWS_VERSION_INVALID"
    )

if (
    state.get("providers", {})
    .get("linux", {})
    .get("version")
    != linux_version
):
    raise SystemExit(
        "CONTINUITY_LINUX_VERSION_INVALID"
    )

current_rb = (
    state.get("current_certification", {})
    .get("runbook")
)

journal = (
    state.get("current_certification", {})
    .get("journal")
)

next_rb = (
    state.get("next_gate", {})
    .get("runbook")
)

if not current_rb or not journal or not next_rb:
    raise SystemExit(
        "CONTINUITY_STATE_KEYS_MISSING"
    )

root = state_path.parent
journal_path = root / journal

if (
    not journal_path.is_file()
    or journal_path.stat().st_size == 0
):
    raise SystemExit(
        f"CONTINUITY_JOURNAL_INVALID:{journal}"
    )

texts = {
    "start": start_path.read_text(encoding="utf-8"),
    "baseline": baseline_path.read_text(encoding="utf-8"),
    "current": current_path.read_text(encoding="utf-8"),
    "next": next_path.read_text(encoding="utf-8"),
    "roadmap": roadmap_path.read_text(encoding="utf-8"),
    "handoff": handoff_path.read_text(encoding="utf-8"),
}

for name, text in texts.items():
    if (
        name in {"start", "handoff"}
        and "https://github.com/gianpabi74/SANDRA"
        not in text
    ):
        raise SystemExit(
            f"CONTINUITY_REPOSITORY_LINK_MISSING:{name}"
        )

for name in ("baseline", "current"):
    text = texts[name]

    if current_rb not in text or journal not in text:
        raise SystemExit(
            "CONTINUITY_CURRENT_CERTIFICATION_MISSING:"
            + name
        )

    if (
        windows_version not in text
        or linux_version not in text
    ):
        raise SystemExit(
            f"CONTINUITY_VERSION_MISSING:{name}"
        )

if next_rb not in texts["next"]:
    raise SystemExit(
        "CONTINUITY_NEXT_TASK_MISMATCH"
    )

if next_rb not in texts["roadmap"]:
    raise SystemExit(
        "CONTINUITY_ROADMAP_MISMATCH"
    )

stale_patterns = (
    "versione provider `1.0.0`",
    "Set non ancora implementata",
    "provider Windows 1.0.0 installato",
)

for pattern in stale_patterns:
    if pattern in texts["current"]:
        raise SystemExit(
            "CONTINUITY_STALE_CURRENT_STATE:"
            + pattern
        )

print("KNOWLEDGE_CONTINUITY=PASS")
PY
}

knowledge_sync() {
    knowledge_continuity_validate
    _knowledge_sync_impl "$@"
}
