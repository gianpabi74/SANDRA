import json
import pathlib
import sys


PROVIDER_VERSION = "1.1.0"


if len(sys.argv) != 5:
    raise SystemExit(
        "USAGE: test.py "
        "<current-state.json> <profile> "
        "<common-profile> <role-profile>"
    )


current_path = pathlib.Path(sys.argv[1])
profile_name = sys.argv[2]
common_path = pathlib.Path(sys.argv[3])
role_path = pathlib.Path(sys.argv[4])


def parse_invariants(path: pathlib.Path) -> dict[str, str]:
    result = {}
    section = None

    for raw_line in path.read_text(
        encoding="utf-8"
    ).splitlines():
        line = raw_line.strip()

        if line == "## Linux Invariants":
            section = "invariants"
            continue

        if line.startswith("## "):
            section = None
            continue

        if section != "invariants":
            continue

        if not line.startswith("- "):
            continue

        value = line[2:].strip()

        if "=" not in value:
            raise SystemExit(
                "PROFILE_INVARIANT_INVALID:"
                + str(path)
                + ":"
                + value
            )

        key, expected = value.split("=", 1)
        key = key.strip()
        expected = expected.strip()

        if not key:
            raise SystemExit(
                "PROFILE_INVARIANT_KEY_EMPTY:"
                + str(path)
            )

        result[key] = expected

    return result


desired = {}

for profile_path in (common_path, role_path):
    desired.update(
        parse_invariants(profile_path)
    )


document = json.loads(
    current_path.read_text(encoding="utf-8")
)

if document.get("Provider") != "Linux":
    raise SystemExit("CURRENT_STATE_PROVIDER_INVALID")

if document.get("ProviderVersion") != PROVIDER_VERSION:
    raise SystemExit("CURRENT_STATE_VERSION_MISMATCH")

if document.get("Operation") != "Get":
    raise SystemExit("CURRENT_STATE_OPERATION_INVALID")

if document.get("Profile") != profile_name:
    raise SystemExit("CURRENT_STATE_PROFILE_MISMATCH")

current = document.get("CurrentState")

if not isinstance(current, dict):
    raise SystemExit("CURRENT_STATE_DOCUMENT_INVALID")


actual_values = {
    "PID1": current.get("PID1"),
    "PackageManager": current.get("PackageManager"),
    "SystemdPresent": str(
        current.get("Systemd", {}).get("Present")
    ).lower(),
}


delta = []

for key, expected in desired.items():
    if key not in actual_values:
        delta.append(
            {
                "Resource": "LinuxInvariant",
                "Name": key,
                "Actual": None,
                "Desired": expected,
                "Reason": "UNSUPPORTED_INVARIANT",
            }
        )
        continue

    actual = actual_values[key]

    if str(actual) != expected:
        delta.append(
            {
                "Resource": "LinuxInvariant",
                "Name": key,
                "Actual": actual,
                "Desired": expected,
            }
        )


result = {
    "Provider": "Linux",
    "ProviderVersion": PROVIDER_VERSION,
    "Operation": "Test",
    "Target": document.get("Target"),
    "Profile": profile_name,
    "InDesiredState": len(delta) == 0,
    "Delta": delta,
}

print(
    json.dumps(
        result,
        indent=2,
        ensure_ascii=False,
    )
)
