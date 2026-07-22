import json
import pathlib
import sys

from transport import invoke_dsc_resource


PROVIDER_VERSION = "1.7.0"
SUPPORTED_RESOURCES: set[str] = {"WindowsFeature", "WindowsService"}
DEFAULT_LOCALE = "it-IT"
PROTECTED_SERVICES = {"winrm"}


def fail(message: str, exit_code: int = 1) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(exit_code)


def read_json(path_value: str, label: str) -> dict:
    path = pathlib.Path(path_value)

    try:
        document = json.loads(
            path.read_text(encoding="utf-8")
        )
    except Exception as exc:
        fail(
            label
            + "_READ_ERROR:"
            + type(exc).__name__
        )

    if not isinstance(document, dict):
        fail(label + "_DOCUMENT_INVALID")

    return document


def validate_windows_service(item: dict) -> dict:
    if item.get("Resource") != "WindowsService":
        fail("WINDOWS_SERVICE_RESOURCE_INVALID")

    name = item.get("Name")
    actual = item.get("Actual")
    desired = item.get("Desired")

    if not isinstance(name, str) or not name.strip():
        fail("WINDOWS_SERVICE_NAME_INVALID")

    name = name.strip()

    if name.lower() in PROTECTED_SERVICES:
        fail("WINDOWS_SERVICE_PROTECTED:" + name)

    if desired != "Running":
        fail("WINDOWS_SERVICE_DESIRED_INVALID")

    if actual not in {
        "Stopped",
        "Stop Pending",
        "Paused",
        "Pause Pending",
        "Continue Pending",
        "Start Pending",
    }:
        fail("WINDOWS_SERVICE_ACTUAL_INVALID")

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


def validate_windows_feature(item: dict) -> dict:
    if item.get("Resource") != "WindowsFeature":
        fail("WINDOWS_FEATURE_RESOURCE_INVALID")

    name = item.get("Name")
    actual = item.get("Actual")
    desired = item.get("Desired")

    if not isinstance(name, str) or not name.strip():
        fail("WINDOWS_FEATURE_NAME_INVALID")

    name = name.strip()

    if actual != "Absent":
        fail("WINDOWS_FEATURE_ACTUAL_INVALID")

    if desired != "Present":
        fail("WINDOWS_FEATURE_DESIRED_INVALID")

    return {
        "Resource": "WindowsFeature",
        "Name": name,
        "Actual": actual,
        "Desired": desired,
        "DscResource": "WindowsFeature",
        "DscModule": "PSDesiredStateConfiguration",
        "DscProperties": {
            "Name": name,
            "Ensure": "Present",
        },
    }


if len(sys.argv) not in {3, 5}:
    fail(
        "USAGE: set.py "
        "<test-result.json> "
        "<approved-delta.json> "
        "[target-ip username]"
    )

test_document = read_json(
    sys.argv[1],
    "TEST",
)

approval_document = read_json(
    sys.argv[2],
    "APPROVAL",
)

if test_document.get("Provider") != "Windows":
    fail("TEST_PROVIDER_INVALID")

if test_document.get("Operation") != "Test":
    fail("TEST_OPERATION_INVALID")

if test_document.get("ProviderVersion") != PROVIDER_VERSION:
    fail("TEST_PROVIDER_VERSION_MISMATCH")

target = test_document.get("Target")
profile = test_document.get("Profile")
test_delta = test_document.get("Delta")

if not isinstance(target, str) or not target:
    fail("TEST_TARGET_INVALID")

if not isinstance(profile, str) or not profile:
    fail("TEST_PROFILE_INVALID")

if not isinstance(test_delta, list):
    fail("TEST_DELTA_INVALID")

if approval_document.get("Provider") != "Windows":
    fail("APPROVAL_PROVIDER_INVALID")

if approval_document.get("Operation") != "SetApproval":
    fail("APPROVAL_OPERATION_INVALID")

if approval_document.get("Target") != target:
    fail("APPROVAL_TARGET_MISMATCH")

if approval_document.get("Profile") != profile:
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

if unsupported_resources:
    result = {
        "Provider": "Windows",
        "ProviderVersion": PROVIDER_VERSION,
        "Operation": "Set",
        "Target": target,
        "Profile": profile,
        "Applied": False,
        "Changed": False,
        "Status": "NOT_IMPLEMENTED",
        "SupportedResources": sorted(SUPPORTED_RESOURCES),
        "UnsupportedResources": unsupported_resources,
        "Evidence": [],
        "Delta": approved_delta,
    }

    print(
        json.dumps(
            result,
            indent=2,
            ensure_ascii=False,
        )
    )

    raise SystemExit(3)

validated_operations = []

for item in approved_delta:
    resource = item.get("Resource")

    if resource == "WindowsService":
        validated_operations.append(
            validate_windows_service(item)
        )
    elif resource == "WindowsFeature":
        validated_operations.append(
            validate_windows_feature(item)
        )

if not validated_operations:
    result = {
        "Provider": "Windows",
        "ProviderVersion": PROVIDER_VERSION,
        "Operation": "Set",
        "Target": target,
        "Profile": profile,
        "Applied": False,
        "Changed": False,
        "Status": "NO_CHANGES_REQUIRED",
        "SupportedResources": sorted(SUPPORTED_RESOURCES),
        "UnsupportedResources": [],
        "Evidence": [],
        "Delta": [],
    }

    print(
        json.dumps(
            result,
            indent=2,
            ensure_ascii=False,
        )
    )

    raise SystemExit(0)

if len(sys.argv) != 5:
    fail("REMOTE_TARGET_ARGUMENTS_REQUIRED")

target_ip = sys.argv[3]
username = sys.argv[4]
password = sys.stdin.read()

if not target_ip:
    fail("TARGET_IP_EMPTY")

if not username:
    fail("USERNAME_EMPTY")

if not password:
    fail("PASSWORD_EMPTY")

evidence = []
changed = False

try:
    for operation in validated_operations:
        common = {
            "host": target_ip,
            "expected_target": target,
            "username": username,
            "password": password,
            "locale": DEFAULT_LOCALE,
            "resource": operation["DscResource"],
            "module": operation["DscModule"],
            "properties": operation["DscProperties"],
        }

        initial_document = invoke_dsc_resource(
            **common,
            method="Test",
        )

        initial_test = bool(
            initial_document["Result"]["InDesiredState"]
        )

        set_invoked = False
        set_document = None

        if not initial_test:
            set_document = invoke_dsc_resource(
                **common,
                method="Set",
            )

            set_invoked = True
            changed = True

        final_document = invoke_dsc_resource(
            **common,
            method="Test",
        )

        final_test = bool(
            final_document["Result"]["InDesiredState"]
        )

        item_evidence = {
            "Resource": operation["Resource"],
            "Name": operation["Name"],
            "Desired": operation["Desired"],
            "DscResource": operation["DscResource"],
            "DscModule": operation["DscModule"],
            "InitialTest": initial_test,
            "SetInvoked": set_invoked,
            "FinalTest": final_test,
        }

        if set_document is not None:
            item_evidence["SetResult"] = (
                set_document["Result"]
            )

        evidence.append(item_evidence)

        if not final_test:
            raise RuntimeError(
                "DSC_FINAL_TEST_FAILED:"
                + operation["Name"]
            )

except Exception as exc:
    message = str(exc).replace(
        password,
        "<REDACTED>",
    )

    result = {
        "Provider": "Windows",
        "ProviderVersion": PROVIDER_VERSION,
        "Operation": "Set",
        "Target": target,
        "Profile": profile,
        "Applied": changed,
        "Changed": changed,
        "Status": "FAILED",
        "ErrorType": type(exc).__name__,
        "Error": message,
        "SupportedResources": sorted(SUPPORTED_RESOURCES),
        "UnsupportedResources": [],
        "Evidence": evidence,
        "Delta": approved_delta,
    }

    print(
        json.dumps(
            result,
            indent=2,
            ensure_ascii=False,
        )
    )

    raise SystemExit(2)

status = (
    "APPLIED"
    if changed
    else "ALREADY_IN_DESIRED_STATE"
)

result = {
    "Provider": "Windows",
    "ProviderVersion": PROVIDER_VERSION,
    "Operation": "Set",
    "Target": target,
    "Profile": profile,
    "Applied": changed,
    "Changed": changed,
    "Status": status,
    "SupportedResources": sorted(SUPPORTED_RESOURCES),
    "UnsupportedResources": [],
    "Evidence": evidence,
    "Delta": approved_delta,
}

print(
    json.dumps(
        result,
        indent=2,
        ensure_ascii=False,
    )
)
