import json
import pathlib
import sys

PROVIDER_VERSION = "1.4.0"
SUPPORTED_RESOURCES: set[str] = {"WindowsService"}


def fail(message: str) -> None:
    raise SystemExit(message)


if len(sys.argv) != 3:
    fail("USAGE: set.py <test-result.json> <approved-delta.json>")

test_path = pathlib.Path(sys.argv[1])
approval_path = pathlib.Path(sys.argv[2])

test_document = json.loads(test_path.read_text(encoding="utf-8"))
approval_document = json.loads(
    approval_path.read_text(encoding="utf-8")
)

if test_document.get("Provider") != "Windows":
    fail("TEST_PROVIDER_INVALID")

if test_document.get("Operation") != "Test":
    fail("TEST_OPERATION_INVALID")

test_delta = test_document.get("Delta")

if not isinstance(test_delta, list):
    fail("TEST_DELTA_INVALID")

if approval_document.get("Provider") != "Windows":
    fail("APPROVAL_PROVIDER_INVALID")

if approval_document.get("Operation") != "SetApproval":
    fail("APPROVAL_OPERATION_INVALID")

if approval_document.get("Target") != test_document.get("Target"):
    fail("APPROVAL_TARGET_MISMATCH")

if approval_document.get("Profile") != test_document.get("Profile"):
    fail("APPROVAL_PROFILE_MISMATCH")

approved_delta = approval_document.get("Delta")

if not isinstance(approved_delta, list):
    fail("APPROVAL_DELTA_INVALID")

if approved_delta != test_delta:
    fail("APPROVAL_DELTA_MISMATCH")

def validate_windows_service(item: dict) -> dict:
    if item.get("Resource") != "WindowsService":
        raise SystemExit("WINDOWS_SERVICE_RESOURCE_INVALID")

    name = item.get("Name")
    actual = item.get("Actual")
    desired = item.get("Desired")

    if not isinstance(name, str) or not name.strip():
        raise SystemExit("WINDOWS_SERVICE_NAME_INVALID")

    if desired != "Running":
        raise SystemExit("WINDOWS_SERVICE_DESIRED_INVALID")

    if actual not in {
        "Stopped",
        "Stop Pending",
        "Paused",
        "Pause Pending",
        "Continue Pending",
        "Start Pending",
    }:
        raise SystemExit("WINDOWS_SERVICE_ACTUAL_INVALID")

    return {
        "Resource": "WindowsService",
        "Name": name,
        "Actual": actual,
        "Desired": desired,
        "DscResource": "Service",
        "DscModule": "PSDesiredStateConfiguration",
        "DscProperties": {
            "Name": name,
            "State": "Running",
        },
    }


validated_operations = []

for item in approved_delta:
    if not isinstance(item, dict):
        raise SystemExit("APPROVAL_DELTA_ITEM_INVALID")

    if item.get("Resource") == "WindowsService":
        validated_operations.append(
            validate_windows_service(item)
        )


unsupported_resources = sorted(
    {
        item.get("Resource")
        for item in approved_delta
        if not isinstance(item, dict)
        or item.get("Resource") not in SUPPORTED_RESOURCES
    },
    key=lambda value: "" if value is None else str(value),
)

status = (
    "NO_CHANGES_REQUIRED"
    if not approved_delta
    else "NOT_IMPLEMENTED"
)

result = {
    "Provider": "Windows",
    "ProviderVersion": PROVIDER_VERSION,
    "Operation": "Set",
    "Target": test_document.get("Target"),
    "Profile": test_document.get("Profile"),
    "Applied": False,
    "Changed": False,
    "Status": status,
    "SupportedResources": sorted(SUPPORTED_RESOURCES),
    "UnsupportedResources": unsupported_resources,
    "ValidatedOperations": validated_operations,
    "Delta": approved_delta,
}

print(json.dumps(result, indent=2, ensure_ascii=False))

if unsupported_resources:
    raise SystemExit(3)
