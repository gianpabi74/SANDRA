import json
import pathlib
import sys

PROVIDER_VERSION = "1.3.0"
SUPPORTED_RESOURCES: set[str] = set()


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
    "Delta": approved_delta,
}

print(json.dumps(result, indent=2, ensure_ascii=False))

if unsupported_resources:
    raise SystemExit(3)
